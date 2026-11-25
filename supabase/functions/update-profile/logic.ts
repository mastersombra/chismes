/**
 * update-profile: validación, diferencias y mapeo de errores (sin red ni DB)
 *
 * Probado en logic.test.ts. Los límites coinciden con los CHECK de
 * `profiles` (005_profiles.sql) y con FormValidators de la app.
 */

export const USERNAME_RE = /^[a-z0-9_]{3,30}$/
export const DISPLAY_NAME_MAX = 50
export const BIO_MAX = 160
/** Foto ya comprimida por la app (~50 KB); el bucket admite hasta 2 MB */
export const AVATAR_MAX_BYTES = 2 * 1024 * 1024

/**
 * @usuarios que suplantarían a la app o al equipo. Se comparan sin "_" ni
 * dígitos al final (ej. "soporte_1", "admin99").
 */
export const RESERVED_USERNAMES = new Set([
  'admin', 'administrador', 'administrator', 'root', 'system', 'sistema',
  'chismes', 'chismesapp', 'oficial', 'official', 'staff', 'equipo', 'team',
  'moderador', 'moderator', 'moderacion', 'moderation', 'mod', 'mods',
  'soporte', 'support', 'ayuda', 'help', 'seguridad', 'security',
  'legal', 'privacy', 'privacidad', 'abuse', 'appeals', 'null', 'undefined',
])

export interface UpdateProfileRequest {
  /** Ya en minúsculas y validado */
  username?: string
  /** null = borrar */
  displayName?: string | null
  /** null = borrar */
  bio?: string | null
  /** Bytes de la foto nueva (sin validar el formato: ver detectImageMimeType) */
  avatar?: Uint8Array
  removeAvatar?: boolean
}

export type ParseResult =
  | { ok: true; value: UpdateProfileRequest }
  | { ok: false; error: string; field?: string }

export function isReservedUsername(username: string): boolean {
  const base = username.replace(/_/g, '').replace(/\d+$/, '')
  return RESERVED_USERNAMES.has(base)
}

/** "" o solo espacios → null (borrar el campo) */
function optionalText(value: unknown): string | null | undefined | false {
  if (value === undefined) return undefined
  if (value === null) return null
  if (typeof value !== 'string') return false
  const trimmed = value.trim().replace(/\s+/g, ' ')
  return trimmed === '' ? null : trimmed
}

export function parseUpdateProfileRequest(body: unknown): ParseResult {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'Body must be a JSON object' }
  }
  const b = body as Record<string, unknown>
  const value: UpdateProfileRequest = {}

  if (b.username !== undefined) {
    if (typeof b.username !== 'string') {
      return { ok: false, error: 'username must be a string', field: 'username' }
    }
    const username = b.username.trim().toLowerCase()
    if (!USERNAME_RE.test(username)) {
      return {
        ok: false,
        error: 'username must be 3-30 characters: lowercase letters, numbers or _',
        field: 'username',
      }
    }
    if (isReservedUsername(username)) {
      return { ok: false, error: 'username is reserved', field: 'username' }
    }
    value.username = username
  }

  const displayName = optionalText(b.display_name)
  if (displayName === false) {
    return { ok: false, error: 'display_name must be a string', field: 'display_name' }
  }
  if (displayName !== undefined) {
    if (displayName !== null && displayName.length > DISPLAY_NAME_MAX) {
      return { ok: false, error: `display_name max ${DISPLAY_NAME_MAX} characters`, field: 'display_name' }
    }
    value.displayName = displayName
  }

  // La bio conserva sus saltos de línea: solo se recortan los extremos
  if (b.bio !== undefined) {
    if (b.bio !== null && typeof b.bio !== 'string') {
      return { ok: false, error: 'bio must be a string', field: 'bio' }
    }
    const bio = b.bio === null ? null : (b.bio as string).trim() || null
    if (bio !== null && [...bio].length > BIO_MAX) {
      return { ok: false, error: `bio max ${BIO_MAX} characters`, field: 'bio' }
    }
    value.bio = bio
  }

  if (b.remove_avatar !== undefined && typeof b.remove_avatar !== 'boolean') {
    return { ok: false, error: 'remove_avatar must be a boolean', field: 'remove_avatar' }
  }
  if (b.avatar_base64 !== undefined) {
    if (b.remove_avatar === true) {
      return { ok: false, error: 'Send avatar_base64 or remove_avatar, not both', field: 'avatar_base64' }
    }
    if (typeof b.avatar_base64 !== 'string' || b.avatar_base64.length === 0) {
      return { ok: false, error: 'avatar_base64 must be a non-empty string', field: 'avatar_base64' }
    }
    // Antes de decodificar: no reservar memoria para algo gigante
    if (b.avatar_base64.length > Math.ceil(AVATAR_MAX_BYTES / 3) * 4) {
      return { ok: false, error: 'avatar too large (max 2 MB)', field: 'avatar_base64' }
    }
    try {
      value.avatar = Uint8Array.from(atob(b.avatar_base64), (c) => c.charCodeAt(0))
    } catch {
      return { ok: false, error: 'avatar_base64 is not valid base64', field: 'avatar_base64' }
    }
  }
  if (b.remove_avatar === true) value.removeAvatar = true

  if (Object.keys(value).length === 0) {
    return { ok: false, error: 'Nothing to update' }
  }
  return { ok: true, value }
}

export interface CurrentProfile {
  username: string | null
  display_name: string | null
  bio: string | null
  avatar_path: string | null
  username_changed_at: string | null
}

/** Solo lo que cambia de verdad (reenviar el mismo valor no gasta el límite) */
export function diffProfile(current: CurrentProfile, request: UpdateProfileRequest): UpdateProfileRequest {
  const changes: UpdateProfileRequest = {}
  if (request.username !== undefined && request.username !== current.username) {
    changes.username = request.username
  }
  if (request.displayName !== undefined && request.displayName !== current.display_name) {
    changes.displayName = request.displayName
  }
  if (request.bio !== undefined && request.bio !== current.bio) changes.bio = request.bio
  if (request.avatar) changes.avatar = request.avatar
  if (request.removeAvatar && current.avatar_path) changes.removeAvatar = true
  return changes
}

/** Hay texto o foto nuevos que moderar (borrar no se modera) */
export function needsModeration(changes: UpdateProfileRequest): boolean {
  return changes.username !== undefined ||
    typeof changes.displayName === 'string' ||
    typeof changes.bio === 'string' ||
    changes.avatar !== undefined
}

/** Texto a moderar con las reglas de los chismes (solo lo nuevo) */
export function moderationText(changes: UpdateProfileRequest): { subject: string; content: string } {
  const subject = [changes.username, changes.displayName]
    .filter((v): v is string => typeof v === 'string')
    .join('\n')
  return { subject, content: typeof changes.bio === 'string' ? changes.bio : '' }
}

/**
 * Cuándo puede volver a cambiar el @usuario (null = ya puede).
 * Igual que el trigger de 017: la primera elección no cuenta.
 */
export function usernameAvailableAt(
  current: CurrentProfile,
  cooldownDays: number,
  now: Date = new Date(),
): Date | null {
  if (current.username === null || current.username_changed_at === null) return null
  const availableAt = new Date(new Date(current.username_changed_at).getTime() + cooldownDays * 86_400_000)
  return availableAt > now ? availableAt : null
}

/** Columnas a actualizar en `profiles` (sin la foto: la pone index.ts) */
export function profileUpdateRow(changes: UpdateProfileRequest): Record<string, string | null> {
  const row: Record<string, string | null> = {}
  if (changes.username !== undefined) row.username = changes.username
  if (changes.displayName !== undefined) row.display_name = changes.displayName
  if (changes.bio !== undefined) row.bio = changes.bio
  return row
}

/** Ruta de la foto nueva en el bucket avatars */
export function avatarPath(userId: string, extension: string, now: number = Date.now()): string {
  return `${userId}/${now}.${extension}`
}

/** Un error de la base al guardar → respuesta (null = inesperado → 500) */
export function databaseErrorResponse(
  error: { code?: string; message?: string; details?: string } | null,
): { status: number; body: Record<string, unknown> } | null {
  if (!error) return null
  if (error.code === '23505') {
    return { status: 409, body: { error: 'username_taken', field: 'username' } }
  }
  if (error.code === 'P0010' || error.message?.includes('username_cooldown')) {
    return {
      status: 409,
      body: { error: 'username_cooldown', field: 'username', available_at: error.details ?? null },
    }
  }
  if (error.code === '23514') {
    return { status: 400, body: { error: 'Validation failed', details: error.message } }
  }
  return null
}
