// =====================================================
// EDGE FUNCTION: cleanup-media
// =====================================================
// Borra archivos de media que ya no sirven, usando la Storage API
// (borrar filas de storage.objects con SQL deja el archivo huérfano).
//
// Qué borra (lo decide get_media_cleanup_candidates(), migración 011):
//   - images-quarantine / audio-quarantine: archivos con más de 24 h
//   - images / audio: archivos con más de 7 días sin gossip que los referencie
//
// Quién la llama: el job de pg_cron `media-cleanup` (diario 4:00 UTC).
// Auth: header x-cleanup-secret == secret MEDIA_CLEANUP_SECRET.
// No es para la app: ningún usuario debe poder dispararla.
//
// Fecha: 2026-11-19
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Storage API acepta hasta 1000 paths por remove(); el RPC devuelve como máximo eso.
const BATCH_SIZE = 1000
// Tope por ejecución para no pasar el timeout de la función; lo que quede sale mañana.
const MAX_BATCHES = 10

interface Candidate {
  bucket_id: string
  name: string
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

// Comparación en tiempo constante para no filtrar el secret por timing.
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder()
  const x = enc.encode(a)
  const y = enc.encode(b)
  if (x.length !== y.length) return false
  let diff = 0
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i]
  return diff === 0
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const expected = Deno.env.get('MEDIA_CLEANUP_SECRET')
  if (!expected) {
    console.error('MEDIA_CLEANUP_SECRET no está configurado')
    return json({ error: 'Not configured' }, 500)
  }

  const provided = req.headers.get('x-cleanup-secret') ?? ''
  if (!safeEqual(provided, expected)) {
    return json({ error: 'Unauthorized' }, 401)
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const deleted: Record<string, number> = {}
  const errors: string[] = []
  let batches = 0

  try {
    while (batches < MAX_BATCHES) {
      const { data, error } = await supabaseAdmin.rpc('get_media_cleanup_candidates', {
        p_limit: BATCH_SIZE,
      })

      if (error) throw new Error(`get_media_cleanup_candidates: ${error.message}`)

      const candidates = (data ?? []) as Candidate[]
      if (candidates.length === 0) break
      batches++

      const byBucket = new Map<string, string[]>()
      for (const c of candidates) {
        const paths = byBucket.get(c.bucket_id) ?? []
        paths.push(c.name)
        byBucket.set(c.bucket_id, paths)
      }

      let removedThisBatch = 0
      for (const [bucket, paths] of byBucket) {
        const { data: removed, error: removeError } = await supabaseAdmin.storage
          .from(bucket)
          .remove(paths)

        if (removeError) {
          errors.push(`${bucket}: ${removeError.message}`)
          continue
        }

        const count = removed?.length ?? 0
        deleted[bucket] = (deleted[bucket] ?? 0) + count
        removedThisBatch += count
      }

      // Si nada se pudo borrar, el próximo RPC devolvería lo mismo: cortar.
      if (removedThisBatch === 0) break
      // Menos de un lote completo: ya no queda nada.
      if (candidates.length < BATCH_SIZE) break
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    console.error('cleanup-media falló:', message)
    return json({ success: false, deleted, errors: [...errors, message] }, 500)
  }

  const total = Object.values(deleted).reduce((sum, n) => sum + n, 0)
  console.log(`cleanup-media: ${total} archivos borrados`, deleted, errors)

  return json({ success: errors.length === 0, total, deleted, errors, batches })
})
