// =====================================================
// EDGE FUNCTION: moderation-review
// =====================================================
// Cola de revisión humana: solo moderadores (app_metadata.role = 'moderator').
//
// POST { action: 'list', status?: 'pending'|'approved'|'rejected', limit?: 1-50 }
//   → { items } ordenados: prioridad alta primero, luego los más antiguos.
//     Incluye el autor real (también de anónimos) y una URL firmada (5 min)
//     para ver la media que espera en cuarentena.
//
// POST { action: 'decide', queue_id, decision: 'approve'|'reject',
//        severity? (obligatoria al rechazar: low|medium|high|critical),
//        reason?, note? }
//   approve → copia la media de cuarentena a los buckets públicos, publica el
//             chisme (restaura lo auto-ocultado) y descarta los reportes
//   reject  → oculta el chisme (no se borra: queda para apelación), borra la
//             media de cuarentena y marca los reportes como atendidos
//   La decisión (autor, gravedad, motivo) queda en moderation_queue: base de
//   las sanciones futuras.
//
// Orden seguro al aprobar: copiar a público SIN borrar la cuarentena →
// aplicar la decisión en la base (atómico) → borrar la cuarentena. Si la base
// falla se borran las copias públicas y la cuarentena sigue intacta.
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
  deleteAudioFromPublicBucket,
  deleteAudioFromQuarantine,
  deleteFromPublicBucket,
  deleteFromQuarantine,
  moveAudioToPublicBucket,
  moveToPublicBucket,
  type PublicAudioResult,
  type PublicImageResult,
} from '../_shared/media.ts'
import { isModerator, parseReviewRequest, type ReviewRequest } from './logic.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SIGNED_URL_SECONDS = 300

function json(body: unknown, status = 200): Response {
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
    return json({ error: 'Method not allowed' }, 405)
  }

  try {
    // 1. Autenticación + rol de moderador (verificado contra el servidor)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseUser = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return json({ error: 'Unauthorized' }, 401)
    }
    if (!isModerator(user)) {
      console.warn(`🚫 Non-moderator tried moderation-review: ${user.id}`)
      return json({ error: 'Forbidden' }, 403)
    }

    // 2. Validar pedido
    let rawBody: unknown
    try {
      rawBody = await req.json()
    } catch {
      return json({ error: 'Invalid JSON in request body' }, 400)
    }
    const parsed = parseReviewRequest(rawBody)
    if (!parsed.ok) {
      return json({ error: parsed.error, field: parsed.field }, 400)
    }

    const supabaseAdmin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)

    return parsed.value.action === 'list'
      ? await listQueue(parsed.value, supabaseAdmin)
      : await decide(parsed.value, user.id, supabaseAdmin)
  } catch (error) {
    console.error('❌ Error in moderation-review:', error)
    return json({ error: 'Internal server error' }, 500)
  }
})

// =====================================================
// LISTAR
// =====================================================

async function listQueue(
  request: Extract<ReviewRequest, { action: 'list' }>,
  supabaseAdmin: any
): Promise<Response> {
  const { data, error } = await supabaseAdmin
    .from('moderation_queue_items')
    .select('*')
    .eq('status', request.status)
    .order('priority', { ascending: true }) // 'high' < 'normal'
    .order('created_at', { ascending: true })
    .limit(request.limit)

  if (error) {
    console.error('❌ Failed to list moderation queue:', error)
    return json({ error: 'Failed to list moderation queue' }, 500)
  }

  const items = await Promise.all((data ?? []).map(async (item: any) => ({
    ...item,
    image_preview_url: await signedUrl(supabaseAdmin, 'images-quarantine', item.image_quarantine_path),
    audio_preview_url: await signedUrl(supabaseAdmin, 'audio-quarantine', item.audio_quarantine_path),
  })))

  return json({ items })
}

async function signedUrl(supabaseAdmin: any, bucket: string, path: string | null): Promise<string | null> {
  if (!path) return null
  const { data, error } = await supabaseAdmin.storage.from(bucket).createSignedUrl(path, SIGNED_URL_SECONDS)
  if (error) {
    console.warn(`⚠️ Could not sign ${bucket}/${path}:`, error.message)
    return null
  }
  return data.signedUrl
}

// =====================================================
// DECIDIR
// =====================================================

async function decide(
  request: Extract<ReviewRequest, { action: 'decide' }>,
  moderatorId: string,
  supabaseAdmin: any
): Promise<Response> {
  const { data: item, error: itemError } = await supabaseAdmin
    .from('moderation_queue')
    .select('id, gossip_id, status, image_quarantine_path, audio_quarantine_path')
    .eq('id', request.queueId)
    .maybeSingle()

  if (itemError) {
    console.error('❌ Failed to load queue item:', itemError)
    return json({ error: 'Failed to load queue item' }, 500)
  }
  if (!item) return json({ error: 'Queue item not found' }, 404)
  if (item.status !== 'pending') return json({ error: 'Queue item already decided' }, 409)

  // Aprobar: copiar la media a público (la cuarentena se conserva por ahora)
  let image: PublicImageResult | null = null
  let audio: PublicAudioResult | null = null
  if (request.decision === 'approve') {
    try {
      if (item.image_quarantine_path) {
        image = await moveToPublicBucket(item.image_quarantine_path, item.gossip_id, supabaseAdmin, {
          deleteQuarantine: false,
        })
      }
      if (item.audio_quarantine_path) {
        audio = await moveAudioToPublicBucket(item.audio_quarantine_path, item.gossip_id, supabaseAdmin, {
          deleteQuarantine: false,
        })
      }
    } catch (moveError) {
      console.error('❌ Failed to publish media:', moveError)
      await rollbackPublicCopies(image, audio, supabaseAdmin)
      return json({ error: 'Failed to publish media' }, 500)
    }
  }

  const media: Record<string, string> = {}
  if (image) {
    media.image_url = image.fullUrl
    media.thumbnail_url = image.thumbnailUrl
    media.storage_path = image.storagePath
    media.thumbnail_storage_path = image.thumbnailStoragePath
  }
  if (audio) {
    media.audio_url = audio.audioUrl
    media.audio_storage_path = audio.storagePath
  }

  // Decisión atómica en la base: chisme + reportes + cola
  const { data: decided, error: decideError } = await supabaseAdmin.rpc('apply_moderation_decision', {
    p_queue_id: request.queueId,
    p_decision: request.decision,
    p_moderator_id: moderatorId,
    p_severity: request.severity,
    p_reason: request.reason,
    p_note: request.note,
    p_media: media,
  })

  if (decideError) {
    await rollbackPublicCopies(image, audio, supabaseAdmin)
    const message = decideError.message ?? ''
    if (message.includes('queue_item_already_decided')) {
      return json({ error: 'Queue item already decided' }, 409)
    }
    if (message.includes('queue_item_not_found')) {
      return json({ error: 'Queue item not found' }, 404)
    }
    console.error('❌ apply_moderation_decision failed:', decideError)
    return json({ error: 'Failed to apply decision' }, 500)
  }

  // Ya decidido: la cuarentena sobra (aprobado → copiada; rechazado → descartada)
  if (item.image_quarantine_path) await deleteFromQuarantine(item.image_quarantine_path, supabaseAdmin)
  if (item.audio_quarantine_path) await deleteAudioFromQuarantine(item.audio_quarantine_path, supabaseAdmin)

  console.log(`⚖️ ${request.decision} queue item ${request.queueId} by moderator ${moderatorId}`)
  return json({ item: decided })
}

async function rollbackPublicCopies(
  image: PublicImageResult | null,
  audio: PublicAudioResult | null,
  supabaseAdmin: any
): Promise<void> {
  if (image) await deleteFromPublicBucket(image.storagePath, image.thumbnailStoragePath, supabaseAdmin)
  if (audio) await deleteAudioFromPublicBucket(audio.storagePath, supabaseAdmin)
}
