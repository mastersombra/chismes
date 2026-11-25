// =====================================================
// EDGE FUNCTION: update-profile
// =====================================================
// Única forma de cambiar el perfil (017_profile_editing.sql: los clientes no
// escriben en `profiles`). La usan el alta del perfil y Editar perfil.
//
// POST { username?, display_name?, bio?, avatar_base64?, remove_avatar? }
//   Solo se envía lo que cambia. "" o null en display_name/bio = borrar.
//   → 200 { profile }
//
// Orden (lo barato primero, la IA al final):
//   1. Auth → 401 · validación → 400 (logic.ts)
//   2. Sin cambios reales → 200 (no gasta límite ni IA)
//   3. Texto o foto nuevos: sanción vigente → 403 account_restricted
//      (fail-closed: sin estado → 503). Borrar campos sí se permite.
//   4. @usuario: límite de días → 409 username_cooldown { available_at };
//      ya usado → 409 username_taken
//   5. Foto: formato real (magic bytes) → 400 invalid_image
//   6. Rate limit 'update_profile' (30 s entre cambios) → 429
//   7. Moderación (mismas reglas e IA que los chismes, _shared/moderation.ts):
//      marcado → 400 content_rejected { reasons }; IA o reglas no
//      disponibles → 503 moderation_unavailable. Nunca queda en revisión:
//      el perfil sigue como estaba.
//   8. Foto aprobada → bucket público avatars/{user_id}/{ts}.{ext} (nunca pasa
//      por cuarentena: se modera en memoria). Se borra la anterior.
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { isBlocked, loadSanctionStatus, restrictedResponseBody } from '../_shared/sanctions.ts'
import { isMissingAutomaticVerdict, loadModerationRules, moderateContent } from '../_shared/moderation.ts'
import { detectImageMimeType, imageExtension, type ImageMimeType } from '../_shared/image.ts'
import {
  avatarPath,
  type CurrentProfile,
  databaseErrorResponse,
  diffProfile,
  moderationText,
  needsModeration,
  parseUpdateProfileRequest,
  profileUpdateRow,
  usernameAvailableAt,
} from './logic.ts'

const AVATARS_BUCKET = 'avatars'
const PROFILE_COLUMNS =
  'id, username, display_name, bio, avatar_url, avatar_path, username_changed_at, profile_completed, created_at, updated_at'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

const unavailable = () =>
  json({ error: 'Service temporarily unavailable', message: 'Please try again in a moment.' }, 503)

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  // Foto ya subida en este request (para deshacer si falla el guardado)
  let uploadedAvatarPath: string | null = null
  // deno-lint-ignore no-explicit-any
  let admin: any = null

  try {
    // ---------- 1. Auth ----------
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401)

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) return json({ error: 'Authentication required' }, 401)

    // ---------- 1b. Validación ----------
    let rawBody: unknown
    try {
      rawBody = await req.json()
    } catch {
      return json({ error: 'Invalid JSON in request body' }, 400)
    }
    const parsed = parseUpdateProfileRequest(rawBody)
    if (!parsed.ok) {
      return json({ error: 'Validation failed', details: parsed.error, field: parsed.field }, 400)
    }

    admin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')

    const { data: currentRow, error: currentError } = await admin
      .from('profiles')
      .select(PROFILE_COLUMNS)
      .eq('id', user.id)
      .maybeSingle()
    if (currentError) {
      console.error('load profile failed:', currentError.message)
      return json({ error: 'Failed to update profile' }, 500)
    }
    if (!currentRow) return json({ error: 'Profile not found' }, 404)
    const current = currentRow as CurrentProfile & Record<string, unknown>

    // ---------- 2. Sin cambios reales ----------
    const changes = diffProfile(current, parsed.value)
    if (Object.keys(changes).length === 0) return json({ profile: currentRow })

    // ---------- 3. Sanciones (solo contenido nuevo) ----------
    const moderate = needsModeration(changes)
    if (moderate) {
      const sanction = await loadSanctionStatus(admin, user, Deno.env.get('ACCOUNT_HASH_SECRET'))
      if (!sanction) return unavailable()
      if (isBlocked(sanction)) {
        console.log(`🚫 Profile edit blocked (${sanction.state}): ${user.id}`)
        return json(restrictedResponseBody(sanction), 403)
      }
    }

    // ---------- 4. @usuario ----------
    if (changes.username !== undefined) {
      const { data: days, error: settingError } = await admin.rpc('moderation_setting', {
        p_key: 'username_change_cooldown_days',
        p_default: 30,
      })
      if (settingError) {
        console.error('moderation_setting failed:', settingError.message)
        return unavailable()
      }
      const availableAt = usernameAvailableAt(current, Number(days))
      if (availableAt) {
        return json({ error: 'username_cooldown', field: 'username', available_at: availableAt.toISOString() }, 409)
      }

      const { data: taken, error: takenError } = await admin
        .from('profiles')
        .select('id')
        .eq('username', changes.username)
        .neq('id', user.id)
        .limit(1)
      if (takenError) {
        console.error('username check failed:', takenError.message)
        return unavailable()
      }
      if ((taken ?? []).length > 0) return json({ error: 'username_taken', field: 'username' }, 409)
    }

    // ---------- 5. Formato real de la foto ----------
    let avatarMime: ImageMimeType | null = null
    if (changes.avatar) {
      try {
        avatarMime = detectImageMimeType(changes.avatar)
      } catch {
        return json({ error: 'invalid_image', field: 'avatar_base64' }, 400)
      }
    }

    // ---------- 6. Rate limit ----------
    const { data: slot, error: slotError } = await admin.rpc('reserve_rate_limit_slot', {
      p_user_id: user.id,
      p_action_type: 'update_profile',
    })
    if (slotError) {
      console.error('reserve_rate_limit_slot failed:', slotError.message)
      return unavailable()
    }
    if (!slot?.allowed) {
      return json({ error: 'Rate limit exceeded', reason: slot?.reason, retry_after: slot?.retry_after }, 429)
    }
    const releaseSlot = () =>
      admin.rpc('release_rate_limit_slot', { p_user_id: user.id, p_action_type: 'update_profile' })

    // ---------- 7. Moderación ----------
    if (moderate) {
      const rules = await loadModerationRules(() =>
        admin.from('moderation_rules').select('kind, target, action, min_score').eq('enabled', true)
      )
      const result = await moderateContent({
        ...moderationText(changes),
        imageDataUrl: changes.avatar && avatarMime
          ? `data:${avatarMime};base64,${(rawBody as Record<string, string>).avatar_base64}`
          : null,
      }, { rules })

      if (result.verdict !== 'publish') {
        await releaseSlot()
        if (result.verdict === 'review' && isMissingAutomaticVerdict(result)) {
          console.warn(`⚠️ Profile moderation unavailable: ${user.id}`)
          return json({ error: 'moderation_unavailable' }, 503)
        }
        console.log(`🚫 Profile change rejected (${result.verdict}): ${result.reasons.join(', ')}`)
        return json({ error: 'content_rejected', reasons: result.reasons }, 400)
      }
    }

    // ---------- 8. Foto y guardado ----------
    const row: Record<string, string | null> = profileUpdateRow(changes)
    if (changes.avatar && avatarMime) {
      uploadedAvatarPath = avatarPath(user.id, imageExtension(avatarMime))
      const { error: uploadError } = await admin.storage
        .from(AVATARS_BUCKET)
        .upload(uploadedAvatarPath, changes.avatar, {
          contentType: avatarMime,
          cacheControl: '31536000',
          upsert: false,
        })
      if (uploadError) {
        console.error('avatar upload failed:', uploadError.message)
        uploadedAvatarPath = null
        return json({ error: 'Failed to update profile' }, 500)
      }
      row.avatar_path = uploadedAvatarPath
      row.avatar_url = admin.storage.from(AVATARS_BUCKET).getPublicUrl(uploadedAvatarPath).data.publicUrl
    } else if (changes.removeAvatar) {
      row.avatar_path = null
      row.avatar_url = null
    }

    const { data: updated, error: updateError } = await admin
      .from('profiles')
      .update(row)
      .eq('id', user.id)
      .select(PROFILE_COLUMNS)
      .single()

    if (updateError) {
      await removeAvatar(admin, uploadedAvatarPath)
      uploadedAvatarPath = null
      const mapped = databaseErrorResponse(updateError)
      if (mapped) {
        await releaseSlot()
        return json(mapped.body, mapped.status)
      }
      console.error('profile update failed:', updateError.message)
      return json({ error: 'Failed to update profile' }, 500)
    }

    // La foto anterior ya no se usa (best effort: no falla el pedido)
    if (row.avatar_path !== undefined && current.avatar_path && current.avatar_path !== row.avatar_path) {
      await removeAvatar(admin, current.avatar_path)
    }

    console.log(`✅ Profile updated: ${user.id} (${Object.keys(row).join(', ')})`)
    return json({ profile: updated })
  } catch (error) {
    console.error('update-profile failed:', error)
    if (admin) await removeAvatar(admin, uploadedAvatarPath)
    return json({ error: 'Internal server error' }, 500)
  }
})

// deno-lint-ignore no-explicit-any
async function removeAvatar(admin: any, path: string | null) {
  if (!path) return
  const { error } = await admin.storage.from(AVATARS_BUCKET).remove([path])
  if (error) console.error(`remove avatar ${path} failed:`, error.message)
}
