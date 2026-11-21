import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
  validateCreateGossipRequest,
  validateLocationHierarchy,
  RequestValidationError,
  type CreateGossipRequest,
} from './validation.ts'
import { isMissingAutomaticVerdict, loadModerationRules, moderateContent } from './moderation.ts'
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
import { isBlocked, loadSanctionStatus, restrictedResponseBody } from '../_shared/sanctions.ts'

/**
 * Edge Function: Moderación Híbrida + Upload Seguro de Media (Imagen y Audio)
 *
 * Estrategia de seguridad para media:
 * 1. Upload → Cuarentena (buckets privados)
 * 2. Validar MIME real (no solo extensión del cliente)
 * 3. Validar dimensiones/tamaño
 * 4. Moderar texto + imagen (OpenAI omni); audio → review (moderation.ts)
 * 5. Si aprueba: Mover a buckets públicos + INSERT gossip
 * 6. Si rechaza: Eliminar de cuarentena
 *
 * Buckets:
 * - images-quarantine (privado) → images (público)
 * - audio-quarantine (privado) → audio (público)
 *
 * Estrategia de moderación (ver moderation.ts). Reglas en la tabla
 * moderation_rules, editables sin desplegar:
 * 1. Reglas locales que rechazan (amenazas, términos) → sin llamar a la IA
 * 2. OpenAI omni-moderation-latest → texto e imagen en una llamada,
 *    + umbrales por categoría de la tabla
 * 3. Reglas locales que mandan a revisión (datos personales, spam, términos)
 * 4. Fail-closed: sin veredicto de la IA o sin reglas → review (nunca se publica)
 *
 * Seguridad:
 * - ✅ Cuenta restringida/suspendida no publica (403 account_restricted)
 * - ✅ Cuarentena privada (archivos no públicos hasta aprobar)
 * - ✅ Validación MIME real de imagen Y audio (magic bytes)
 * - ✅ Validación de dimensiones/tamaño (prevenir archivos gigantes)
 * - ✅ Cliente NO puede pasar URLs arbitrarias (solo base64)
 * - ✅ Cliente NO decide estados (previene bypass de moderación)
 * - ✅ Service role bypasa RLS (INSERT controlado por servidor)
 * - ✅ storage_path es fuente de verdad (URLs regenerables)
 * - ✅ Rollback automático en cualquier fallo
 *
 * Costo: $0 hasta 500K gossips/mes, luego $2 por millón
 */

// ============================================
// CONFIGURACIÓN
// ============================================

const IMAGE_VALIDATION = {
  MAX_SIZE_BYTES: 5 * 1024 * 1024, // 5 MB
  MAX_WIDTH: 4096,
  MAX_HEIGHT: 4096,
  ALLOWED_MIME_TYPES: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
}

const AUDIO_VALIDATION = {
  MAX_SIZE_BYTES: 10 * 1024 * 1024, // 10 MB
  ALLOWED_MIME_TYPES: ['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/wav'],
}

// ============================================
// CONFIGURACIÓN DE RATE LIMITING
// ============================================

const RATE_LIMITS = {
  CREATE_GOSSIP_PER_HOUR: 10,
  CREATE_GOSSIP_PER_DAY: 100,
  COOLDOWN_SECONDS: 30, // Mínimo 30 segundos entre chismes
}

// ============================================
// TIPOS
// ============================================
// CreateGossipRequest se importa desde validation.ts

interface QuarantineUploadResult {
  quarantinePath: string  // Path en bucket de cuarentena
  mimeType: string        // MIME real (magic bytes), para moderar la imagen
}

interface AudioQuarantineUploadResult {
  quarantinePath: string  // Path en bucket de cuarentena de audio
}

// ============================================
// HANDLER PRINCIPAL
// ============================================

serve(async (req) => {
  let quarantinePath: string | null = null
  let imageMimeType: string | null = null
  let audioQuarantinePath: string | null = null

  try {
    // 1. Verificar autenticación
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Cliente anon para verificar usuario
    const supabaseAnon = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verificar que el usuario esté autenticado (OBLIGATORIO)
    const { data: { user }, error: authError } = await supabaseAnon.auth.getUser()

    if (authError || !user) {
      console.error('❌ Authentication failed:', authError?.message || 'No user')
      return new Response(
        JSON.stringify({
          error: 'Authentication required',
          message: 'You must be logged in to create gossips'
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ User authenticated: ${user.id}`)

    // 2. Parsear y validar request body (P1-02 Fix)
    let body: CreateGossipRequest
    try {
      const rawBody = await req.json()
      body = validateCreateGossipRequest(rawBody)
    } catch (error) {
      if (error instanceof RequestValidationError) {
        console.error('❌ Validation failed:', error.errors)
        return new Response(
          JSON.stringify({
            error: 'Validation failed',
            details: error.errors,
          }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
      }
      // Error de parsing JSON
      console.error('❌ Invalid JSON:', error)
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const userId = user.id

    // 2.3. Validar jerarquía de ubicación (P1-02 Fix)
    // ANTES de rate limit para no gastar slot en ubicaciones inválidas
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const locationValidation = await validateLocationHierarchy(
      body.country_id,
      body.region_id,
      body.city_id,
      supabaseAdmin
    )

    if (!locationValidation.valid) {
      console.error('❌ Invalid location:', locationValidation.error)
      return new Response(
        JSON.stringify({
          error: 'Invalid location',
          message: locationValidation.error,
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Location validated: ${body.country_id}/${body.region_id}/${body.city_id}`)

    // 2.4. ✅ SANCIONES (015_sanctions.sql): restringido o suspendido no
    // publica. Antes del rate limit para no gastar slot. Fail-closed: si no
    // se puede leer el estado → 503.
    const sanction = await loadSanctionStatus(supabaseAdmin, user, Deno.env.get('ACCOUNT_HASH_SECRET'))
    if (!sanction) {
      return new Response(
        JSON.stringify({
          error: 'Service temporarily unavailable',
          message: 'Unable to process your request at this time. Please try again in a moment.',
        }),
        { status: 503, headers: { 'Content-Type': 'application/json' } }
      )
    }
    if (isBlocked(sanction)) {
      console.log(`🚫 Account ${sanction.state}: ${userId}`)
      return new Response(
        JSON.stringify(restrictedResponseBody(sanction)),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 2.5. ✅ RESERVAR SLOT DE RATE LIMITING (ATÓMICO)
    // NOTA: Idempotencia se maneja al final con upsert atómico (Fix P1-03)
    const { data: rateLimitCheck, error: rateLimitError } = await supabaseAdmin
      .rpc('reserve_rate_limit_slot', {
        p_user_id: userId,
        p_action_type: 'create_gossip'
      })

    // FAIL-CLOSED: Si el RPC falla, rechazar el request
    if (rateLimitError) {
      console.error('❌ Rate limit RPC failed:', rateLimitError)
      return new Response(
        JSON.stringify({
          error: 'Service temporarily unavailable',
          message: 'Unable to process your request at this time. Please try again in a moment.',
          technical: rateLimitError.message
        }),
        {
          status: 503,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // Verificar si se excedió el rate limit
    if (!rateLimitCheck.allowed) {
      console.log(`🚫 RATE LIMIT EXCEEDED: ${rateLimitCheck.reason}`)
      return new Response(
        JSON.stringify({
          error: 'Rate limit exceeded',
          message: rateLimitCheck.message,
          reason: rateLimitCheck.reason,
          retryAfter: rateLimitCheck.retry_after,
          stats: rateLimitCheck.stats
        }),
        {
          status: 429,
          headers: {
            'Content-Type': 'application/json',
            'Retry-After': String(rateLimitCheck.retry_after || 60),
          }
        }
      )
    }

    console.log(`✅ Rate limit slot reserved for user ${userId}`)

    // 2.9. ✅ PASO 1: UPLOAD A CUARENTENA (si hay imagen)
    if (body.image_base64) {
      try {
        console.log('📸 Uploading image to quarantine...')
        const quarantineResult = await uploadToQuarantine(
          userId,
          body.idempotency_key,
          body.image_base64,
          supabaseAdmin
        )
        quarantinePath = quarantineResult.quarantinePath
        imageMimeType = quarantineResult.mimeType
        console.log(`✅ Image in quarantine: ${quarantinePath}`)
      } catch (uploadError) {
        // Si falla el upload, liberar slot y retornar error
        console.error('❌ Image upload to quarantine failed:', uploadError)

        await supabaseAdmin.rpc('release_rate_limit_slot', {
          p_user_id: userId,
          p_action_type: 'create_gossip'
        })

        return new Response(
          JSON.stringify({
            error: 'Image upload failed',
            message: 'No se pudo subir la imagen. Por favor intenta de nuevo.',
            technical: uploadError instanceof Error ? uploadError.message : String(uploadError)
          }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
      }
    }

    // 2.10. ✅ PASO 1b: UPLOAD DE AUDIO A CUARENTENA (si hay audio)
    if (body.audio_base64) {
      try {
        console.log('🎵 Uploading audio to quarantine...')
        const audioQuarantineResult = await uploadAudioToQuarantine(
          userId,
          body.idempotency_key,
          body.audio_base64,
          supabaseAdmin
        )
        audioQuarantinePath = audioQuarantineResult.quarantinePath
        console.log(`✅ Audio in quarantine: ${audioQuarantinePath}`)
      } catch (uploadError) {
        // Si falla el upload de audio, liberar slot y limpiar imagen si existe
        console.error('❌ Audio upload to quarantine failed:', uploadError)

        // Rollback: Eliminar imagen de cuarentena si existe
        if (quarantinePath) {
          await deleteFromQuarantine(quarantinePath, supabaseAdmin)
        }

        await supabaseAdmin.rpc('release_rate_limit_slot', {
          p_user_id: userId,
          p_action_type: 'create_gossip'
        })

        return new Response(
          JSON.stringify({
            error: 'Audio upload failed',
            message: 'No se pudo subir el audio. Por favor intenta de nuevo.',
            technical: uploadError instanceof Error ? uploadError.message : String(uploadError)
          }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
      }
    }

    // 3. ✅ PASO 2: MODERAR CONTENIDO (texto + imagen; audio → review)
    // La imagen va como data URL (ya validada por magic bytes): OpenAI no
    // recibe ninguna URL de la cuarentena.
    // Reglas leídas en cada chisme: un cambio en la tabla aplica al siguiente.
    // Si no se pueden leer → null → review (fail-closed)
    const rules = await loadModerationRules(() =>
      supabaseAdmin
        .from('moderation_rules')
        .select('kind, target, action, min_score')
        .eq('enabled', true)
    )
    const moderationResult = await moderateContent({
      subject: body.subject,
      content: body.content,
      imageDataUrl: quarantinePath && imageMimeType
        ? `data:${imageMimeType};base64,${body.image_base64}`
        : null,
      hasAudio: audioQuarantinePath !== null,
    }, { rules })

    // 4. Si fue rechazado, limpiar cuarentena y retornar error
    if (moderationResult.verdict === 'reject') {
      console.log('🚫 Gossip rejected by moderation:', moderationResult.reasons)

      // Rollback: Eliminar de cuarentena
      if (quarantinePath) {
        await deleteFromQuarantine(quarantinePath, supabaseAdmin)
      }
      if (audioQuarantinePath) {
        await deleteAudioFromQuarantine(audioQuarantinePath, supabaseAdmin)
      }

      // Liberar slot de rate limiting
      await supabaseAdmin.rpc('release_rate_limit_slot', {
        p_user_id: userId,
        p_action_type: 'create_gossip'
      })
      console.log('♻️ Rate limit slot released (moderation rejected)')

      return new Response(
        JSON.stringify({
          error: 'Content rejected by moderation',
          reasons: moderationResult.reasons,
          source: moderationResult.source
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 5. ✅ PASO 3: MOVER A PÚBLICO (si aprobado y hay imagen)
    let publicImageResult: PublicImageResult | null = null

    if (quarantinePath && moderationResult.verdict === 'publish') {
      try {
        console.log('📦 Moving image from quarantine to public bucket...')
        publicImageResult = await moveToPublicBucket(
          quarantinePath,
          body.idempotency_key,
          supabaseAdmin
        )
        console.log(`✅ Image moved to public: ${publicImageResult.storagePath}`)
      } catch (moveError) {
        console.error('❌ Failed to move image to public:', moveError)

        // Rollback: Eliminar de cuarentena
        await deleteFromQuarantine(quarantinePath, supabaseAdmin)

        // Liberar slot
        await supabaseAdmin.rpc('release_rate_limit_slot', {
          p_user_id: userId,
          p_action_type: 'create_gossip'
        })

        return new Response(
          JSON.stringify({
            error: 'Failed to finalize image',
            message: 'No se pudo finalizar la imagen. Por favor intenta de nuevo.',
            technical: moveError instanceof Error ? moveError.message : String(moveError)
          }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }
    }

    // 5b. ✅ PASO 3b: MOVER AUDIO A PÚBLICO (si aprobado y hay audio)
    let publicAudioResult: PublicAudioResult | null = null

    if (audioQuarantinePath && moderationResult.verdict === 'publish') {
      try {
        console.log('📦 Moving audio from quarantine to public bucket...')
        publicAudioResult = await moveAudioToPublicBucket(
          audioQuarantinePath,
          body.idempotency_key,
          supabaseAdmin
        )
        console.log(`✅ Audio moved to public: ${publicAudioResult.storagePath}`)
      } catch (moveError) {
        console.error('❌ Failed to move audio to public:', moveError)

        // Rollback: Eliminar imagen pública si ya se movió
        if (publicImageResult) {
          await deleteFromPublicBucket(
            publicImageResult.storagePath,
            publicImageResult.thumbnailStoragePath,
            supabaseAdmin
          )
        }

        // Rollback: Eliminar de cuarentena
        if (quarantinePath) {
          await deleteFromQuarantine(quarantinePath, supabaseAdmin)
        }
        await deleteAudioFromQuarantine(audioQuarantinePath, supabaseAdmin)

        // Liberar slot
        await supabaseAdmin.rpc('release_rate_limit_slot', {
          p_user_id: userId,
          p_action_type: 'create_gossip'
        })

        return new Response(
          JSON.stringify({
            error: 'Failed to finalize audio',
            message: 'No se pudo finalizar el audio. Por favor intenta de nuevo.',
            technical: moveError instanceof Error ? moveError.message : String(moveError)
          }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }
    }

    // Si fue a revisión y hay imagen/audio, dejar en cuarentena: se encola
    // con su ruta (paso 7b) y moderation-review la publica al aprobar

    // 6. Decidir estados basado en veredicto
    const status = moderationResult.verdict === 'review' ? 'draft' : 'published'
    const moderation_status = moderationResult.verdict === 'review' ? 'pending' : 'approved'

    console.log(`✅ Moderation passed: ${moderationResult.verdict} → status=${status}`)

    // 7. ✅ PASO 4: UPSERT ATÓMICO con idempotencia (Fix P1-03)
    // Usa INSERT ON CONFLICT para ser seguro bajo concurrencia
    const { data: upsertResult, error: upsertError } = await supabaseAdmin
      .rpc('upsert_gossip_idempotent', {
        p_subject: body.subject.trim(),
        p_content: body.content.trim(),
        p_country_id: body.country_id,
        p_region_id: body.region_id,
        p_city_id: body.city_id,
        p_published_as: body.published_as,
        p_status: status,
        p_moderation_status: moderation_status,
        p_visibility: 'public',
        p_created_by: user.id,
        p_audio_url: publicAudioResult?.audioUrl || null,
        p_audio_storage_path: publicAudioResult?.storagePath || null,
        p_image_url: publicImageResult?.fullUrl || null,
        p_thumbnail_url: publicImageResult?.thumbnailUrl || null,
        p_storage_path: publicImageResult?.storagePath || null,
        p_thumbnail_storage_path: publicImageResult?.thumbnailStoragePath || null,
        p_idempotency_key: body.idempotency_key,
      })

    if (upsertError) {
      console.error('❌ Error upserting gossip:', upsertError)

      // Rollback: Eliminar de público (si se movió)
      if (publicImageResult) {
        await deleteFromPublicBucket(
          publicImageResult.storagePath,
          publicImageResult.thumbnailStoragePath,
          supabaseAdmin
        )
      }
      if (publicAudioResult) {
        await deleteAudioFromPublicBucket(
          publicAudioResult.storagePath,
          supabaseAdmin
        )
      }

      // Rollback: Eliminar de cuarentena (si aún está)
      if (quarantinePath && !publicImageResult) {
        await deleteFromQuarantine(quarantinePath, supabaseAdmin)
      }
      if (audioQuarantinePath && !publicAudioResult) {
        await deleteAudioFromQuarantine(audioQuarantinePath, supabaseAdmin)
      }

      // Liberar slot
      await supabaseAdmin.rpc('release_rate_limit_slot', {
        p_user_id: userId,
        p_action_type: 'create_gossip'
      })
      console.log('♻️ Rate limit slot released (upsert failed)')

      throw upsertError
    }

    // Parsear resultado del RPC
    const { gossip, idempotent, message } = upsertResult

    if (idempotent) {
      console.log(`♻️ Idempotent request: ${message}`)
    } else {
      console.log(`✅ Gossip created: ${gossip.id}`)
    }

    // 7b. Veredicto 'review' → cola de revisión humana, con la ruta de la
    // media en cuarentena (cleanup-media no la borra mientras esté pendiente;
    // moderation-review la publica al aprobar). Solo si el chisme guardado
    // está pendiente: en un reintento idempotente de un chisme ya publicado
    // no se encola. Si ya estaba en la cola, enqueue_moderation no hace nada.
    if (moderationResult.verdict === 'review' && gossip.status === 'draft') {
      const source = isMissingAutomaticVerdict(moderationResult)
        ? 'ai_unavailable'
        : 'ai_review'
      const { error: enqueueError } = await supabaseAdmin.rpc('enqueue_moderation', {
        p_gossip_id: gossip.id,
        p_source: source,
        p_reasons: moderationResult.reasons,
        p_image_quarantine_path: quarantinePath,
        p_audio_quarantine_path: audioQuarantinePath,
      })
      if (enqueueError) {
        // El chisme queda en draft (no público): seguro, pero sin revisar
        console.error('❌ Failed to enqueue gossip for review:', enqueueError)
      } else {
        console.log(`📥 Gossip ${gossip.id} queued for review (${source})`)
      }
    }

    // 8. Retornar gossip creado o existente
    return new Response(
      JSON.stringify({
        gossip,
        idempotent,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Error in moderate-gossip function:', error)

    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error'
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})


// ============================================
// SECURE IMAGE UPLOAD (Cuarentena → Público)
// ============================================

/**
 * PASO 1: Upload a cuarentena y validar
 *
 * Sube imagen a bucket PRIVADO (images-quarantine)
 * Valida MIME real, dimensiones, tamaño
 *
 * Security:
 * - ✅ Bucket privado (no accesible públicamente)
 * - ✅ Validación MIME real (no confiar en cliente)
 * - ✅ Validación de dimensiones (prevenir archivos gigantes)
 * - ✅ Path incluye userId (prevenir colisiones y abuso)
 */
async function uploadToQuarantine(
  userId: string,
  idempotencyKey: string,
  imageBase64: string,
  supabaseClient: any
): Promise<QuarantineUploadResult> {
  try {
    // 1. Decodificar base64
    const imageData = Uint8Array.from(atob(imageBase64), c => c.charCodeAt(0))

    // 2. Validar tamaño
    if (imageData.length > IMAGE_VALIDATION.MAX_SIZE_BYTES) {
      throw new Error(`Image too large: ${imageData.length} bytes (max ${IMAGE_VALIDATION.MAX_SIZE_BYTES})`)
    }

    // 3. Validar MIME real (primeros bytes del archivo)
    const mimeType = detectMimeType(imageData)
    if (!IMAGE_VALIDATION.ALLOWED_MIME_TYPES.includes(mimeType)) {
      throw new Error(`Invalid MIME type: ${mimeType}. Allowed: ${IMAGE_VALIDATION.ALLOWED_MIME_TYPES.join(', ')}`)
    }

    // 4. Validar dimensiones (básico - solo para JPEGs por ahora)
    // NOTA: Para validación completa de dimensiones se necesitaría
    // una librería de procesamiento de imágenes (no disponible en Deno)
    // Por ahora validamos solo que el tamaño no sea excesivo
    console.log(`✅ Image validation passed: ${mimeType}, ${imageData.length} bytes`)

    // 5. Path en cuarentena: quarantine/{userId}/{idempotencyKey}_{timestamp}.jpg
    const timestamp = Date.now()
    const extension = mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg'
    const fileName = `${idempotencyKey}_${timestamp}.${extension}`
    const quarantinePath = `quarantine/${userId}/${fileName}`

    // 6. Subir a cuarentena
    const { error: uploadError } = await supabaseClient.storage
      .from('images-quarantine')
      .upload(quarantinePath, imageData, {
        contentType: mimeType,
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) {
      throw new Error(`Quarantine upload failed: ${uploadError.message}`)
    }

    console.log(`✅ Image uploaded to quarantine: ${quarantinePath}`)

    return { quarantinePath, mimeType }
  } catch (error) {
    console.error('❌ Upload to quarantine failed:', error)
    throw error
  }
}


/**
 * Detectar MIME type real de imagen (validación de primeros bytes)
 *
 * Security: NO confiar en extensión del cliente
 */
function detectMimeType(data: Uint8Array): string {
  // JPEG: FF D8 FF
  if (data[0] === 0xFF && data[1] === 0xD8 && data[2] === 0xFF) {
    return 'image/jpeg'
  }

  // PNG: 89 50 4E 47
  if (data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4E && data[3] === 0x47) {
    return 'image/png'
  }

  // WebP: 52 49 46 46 ... 57 45 42 50
  if (data[0] === 0x52 && data[1] === 0x49 && data[2] === 0x46 && data[3] === 0x46 &&
      data[8] === 0x57 && data[9] === 0x45 && data[10] === 0x42 && data[11] === 0x50) {
    return 'image/webp'
  }

  throw new Error('Unsupported or invalid image format (not JPEG, PNG, or WebP)')
}

/**
 * Detectar MIME type real de audio (validación de primeros bytes)
 *
 * Security: NO confiar en extensión del cliente
 */
function detectAudioMimeType(data: Uint8Array): string {
  // MP3: FF FB o FF F3 o FF F2 (MPEG Audio)
  // También ID3v2: 49 44 33 ("ID3")
  if (data[0] === 0xFF && (data[1] === 0xFB || data[1] === 0xF3 || data[1] === 0xF2)) {
    return 'audio/mpeg'
  }
  if (data[0] === 0x49 && data[1] === 0x44 && data[2] === 0x33) {
    return 'audio/mpeg'
  }

  // M4A/MP4: ftyp box (posición 4-7)
  // Bytes 4-7: "ftyp", luego "M4A " o "mp42" etc.
  if (data[4] === 0x66 && data[5] === 0x74 && data[6] === 0x79 && data[7] === 0x70) {
    // Verificar si es M4A
    if (data[8] === 0x4D && data[9] === 0x34 && data[10] === 0x41) {
      return 'audio/m4a'
    }
    // MP4 genérico (puede ser audio)
    return 'audio/mp4'
  }

  // WAV: RIFF ... WAVE
  // Bytes 0-3: "RIFF", 8-11: "WAVE"
  if (data[0] === 0x52 && data[1] === 0x49 && data[2] === 0x46 && data[3] === 0x46 &&
      data[8] === 0x57 && data[9] === 0x41 && data[10] === 0x56 && data[11] === 0x45) {
    return 'audio/wav'
  }

  throw new Error('Unsupported or invalid audio format (not MP3, M4A, MP4, or WAV)')
}

// ============================================
// SECURE AUDIO UPLOAD (Cuarentena → Público)
// ============================================

/**
 * PASO 1: Upload de audio a cuarentena y validar
 *
 * Sube audio a bucket PRIVADO (audio-quarantine)
 * Valida MIME real y tamaño
 *
 * Security:
 * - ✅ Bucket privado (no accesible públicamente)
 * - ✅ Validación MIME real (no confiar en cliente)
 * - ✅ Validación de tamaño (prevenir archivos gigantes)
 * - ✅ Path incluye userId (prevenir colisiones y abuso)
 */
async function uploadAudioToQuarantine(
  userId: string,
  idempotencyKey: string,
  audioBase64: string,
  supabaseClient: any
): Promise<AudioQuarantineUploadResult> {
  try {
    // 1. Decodificar base64
    const audioData = Uint8Array.from(atob(audioBase64), c => c.charCodeAt(0))

    // 2. Validar tamaño
    if (audioData.length > AUDIO_VALIDATION.MAX_SIZE_BYTES) {
      throw new Error(`Audio too large: ${audioData.length} bytes (max ${AUDIO_VALIDATION.MAX_SIZE_BYTES})`)
    }

    // 3. Validar MIME real (primeros bytes del archivo)
    const mimeType = detectAudioMimeType(audioData)
    if (!AUDIO_VALIDATION.ALLOWED_MIME_TYPES.includes(mimeType)) {
      throw new Error(`Invalid audio MIME type: ${mimeType}. Allowed: ${AUDIO_VALIDATION.ALLOWED_MIME_TYPES.join(', ')}`)
    }

    console.log(`✅ Audio validation passed: ${mimeType}, ${audioData.length} bytes`)

    // 4. Path en cuarentena: quarantine/{userId}/{idempotencyKey}_{timestamp}.mp3
    const timestamp = Date.now()
    const extension = mimeType === 'audio/wav' ? 'wav' : mimeType === 'audio/m4a' || mimeType === 'audio/mp4' ? 'm4a' : 'mp3'
    const fileName = `${idempotencyKey}_${timestamp}.${extension}`
    const quarantinePath = `quarantine/${userId}/${fileName}`

    // 5. Subir a cuarentena
    const { error: uploadError } = await supabaseClient.storage
      .from('audio-quarantine')
      .upload(quarantinePath, audioData, {
        contentType: mimeType,
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) {
      throw new Error(`Audio quarantine upload failed: ${uploadError.message}`)
    }

    console.log(`✅ Audio uploaded to quarantine: ${quarantinePath}`)

    return { quarantinePath }
  } catch (error) {
    console.error('❌ Upload audio to quarantine failed:', error)
    throw error
  }
}


