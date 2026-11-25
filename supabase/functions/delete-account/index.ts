// =====================================================
// EDGE FUNCTION: delete-account
// =====================================================
// Elimina la cuenta del usuario autenticado y todos sus datos, de inmediato
// (requisito de App Store 5.1.1(v) y Google Play; GDPR art. 17).
//
// Flujo:
// 1. Auth + confirmación ("DELETE_MY_ACCOUNT"): la app pide doble confirmación
// 2. get_account_deletion_media(): media de sus chismes (pública + cuarentena)
// 3. Borra esa media con la Storage API, más todo lo que tenga en
//    quarantine/<user_id>/ (subidas que no llegaron a la cola) y su foto de
//    perfil (avatars/<user_id>/). Los errores
//    se loguean y no bloquean: cleanup-media borra lo huérfano (> 7 días)
// 4. delete_user_account() (migración 014), en una transacción: registro
//    anónimo de faltas (solo si tuvo rechazos) + borrar auth.users. Por
//    cascada se van chismes, perfil, reportes e historial de moderación
//
// Qué se conserva: solo account_deletion_records (huella HMAC del email +
// conteo de rechazos por gravedad), si tuvo faltas. Ver assets/legal/privacy_policy.es.md.
//
// Secrets: ACCOUNT_HASH_SECRET (obligatorio: sin él responde 500 y no borra).
// No rotarlo: cambiar el secret invalida las huellas guardadas.
//
// Respuestas: 200 { deleted: true } · 400 confirmación/body · 401 sin usuario
//             · 405 método · 500 error (la cuenta sigue existiendo)
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { cleanPaths, emailHash, parseDeleteRequest } from './logic.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Carpetas propias del usuario que se vacían enteras (además de la media de
// sus chismes): subidas en cuarentena y su foto de perfil (017)
const USER_FOLDERS = [
  { bucket: 'images-quarantine', prefix: (id: string) => `quarantine/${id}` },
  { bucket: 'audio-quarantine', prefix: (id: string) => `quarantine/${id}` },
  { bucket: 'avatars', prefix: (id: string) => id },
] as const

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return json(405, { error: 'Method not allowed' })
  }

  try {
    // ---------- 1. Auth ----------
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json(401, { error: 'Missing Authorization header' })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabaseAnon = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authError } = await supabaseAnon.auth.getUser()
    if (authError || !user) {
      return json(401, { error: 'Unauthorized' })
    }

    // ---------- Confirmación ----------
    let body: unknown
    try {
      body = await req.json()
    } catch {
      return json(400, { error: 'Invalid JSON body' })
    }
    const parsed = parseDeleteRequest(body)
    if (!parsed.ok) {
      return json(400, { error: parsed.error })
    }

    const hashSecret = Deno.env.get('ACCOUNT_HASH_SECRET')
    if (!hashSecret) {
      console.error('ACCOUNT_HASH_SECRET is not configured: account not deleted')
      return json(500, { error: 'Server misconfigured' })
    }

    const admin = createClient(supabaseUrl, supabaseServiceKey)

    // ---------- 2. Media a borrar ----------
    const { data: media, error: mediaError } = await admin.rpc(
      'get_account_deletion_media',
      { p_user_id: user.id },
    )
    if (mediaError) {
      console.error('get_account_deletion_media failed:', mediaError.message)
      return json(500, { error: 'Failed to delete account' })
    }

    // ---------- 3. Borrar media (best effort) ----------
    const toRemove: Record<string, string[]> = {
      'images': cleanPaths(media?.image_paths ?? []),
      'audio': cleanPaths(media?.audio_paths ?? []),
      'images-quarantine': cleanPaths(media?.image_quarantine_paths ?? []),
      'audio-quarantine': cleanPaths(media?.audio_quarantine_paths ?? []),
      'avatars': [],
    }

    for (const folder of USER_FOLDERS) {
      const bucket = folder.bucket
      const prefix = folder.prefix(user.id)
      const { data: files, error } = await admin.storage.from(bucket).list(prefix, { limit: 1000 })
      if (error) {
        console.error(`list ${bucket}/${prefix} failed:`, error.message)
        continue
      }
      for (const file of files ?? []) {
        const path = `${prefix}/${file.name}`
        if (!toRemove[bucket].includes(path)) toRemove[bucket].push(path)
      }
    }

    let removed = 0
    for (const [bucket, paths] of Object.entries(toRemove)) {
      if (paths.length === 0) continue
      const { error } = await admin.storage.from(bucket).remove(paths)
      if (error) {
        // No bloquea: cleanup-media borra lo huérfano
        console.error(`remove from ${bucket} failed:`, error.message)
      } else {
        removed += paths.length
      }
    }

    // ---------- 4. Registro de faltas + borrar cuenta (atómico) ----------
    const hash = await emailHash(user.email, hashSecret)
    const { data: recorded, error: deleteError } = await admin.rpc('delete_user_account', {
      p_user_id: user.id,
      p_email_hash: hash,
    })
    if (deleteError) {
      console.error('delete_user_account failed:', deleteError.message)
      return json(500, { error: 'Failed to delete account' })
    }

    // Sin user_id ni email en los logs
    console.log(
      `Account deleted (media files removed: ${removed}, offense record: ${recorded === true})`,
    )
    if (parsed.reason) {
      console.log('Account deletion reason:', parsed.reason)
    }

    return json(200, { deleted: true })
  } catch (error) {
    console.error('delete-account unexpected error:', error instanceof Error ? error.message : error)
    return json(500, { error: 'Failed to delete account' })
  }
})
