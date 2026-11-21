/**
 * Lógica pura de delete-account (sin red): validación del request, huella
 * del email y limpieza de las rutas de media a borrar. Tests: logic.test.ts
 */

/** Texto que la app debe enviar: evita borrados por llamadas accidentales */
export const DELETE_CONFIRMATION = 'DELETE_MY_ACCOUNT'

export type ParsedRequest =
  | { ok: true; reason: string | null }
  | { ok: false; error: string }

export function parseDeleteRequest(body: unknown): ParsedRequest {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { ok: false, error: 'Body must be a JSON object' }
  }
  const { confirmation, reason } = body as Record<string, unknown>
  if (confirmation !== DELETE_CONFIRMATION) {
    return { ok: false, error: `confirmation must be "${DELETE_CONFIRMATION}"` }
  }
  if (reason !== undefined && reason !== null && typeof reason !== 'string') {
    return { ok: false, error: 'reason must be a string' }
  }
  const trimmed = typeof reason === 'string' ? reason.trim().slice(0, 200) : ''
  return { ok: true, reason: trimmed || null }
}

/** Email normalizado para la huella: sin espacios y en minúsculas */
export function normalizeEmail(email: string | null | undefined): string | null {
  const normalized = (email ?? '').trim().toLowerCase()
  return normalized.length > 0 ? normalized : null
}

/**
 * Huella HMAC-SHA256 (hex) del email normalizado, o null si no hay email.
 * Con HMAC (y no SHA-256 solo) nadie sin el secret puede probar emails
 * conocidos contra la tabla.
 */
export async function emailHash(
  email: string | null | undefined,
  secret: string,
): Promise<string | null> {
  const normalized = normalizeEmail(email)
  if (!normalized) return null
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(normalized))
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

/** Rutas válidas (strings no vacíos, sin '..', sin duplicados) */
export function cleanPaths(paths: unknown[]): string[] {
  const out: string[] = []
  for (const p of paths) {
    if (typeof p === 'string' && p.length > 0 && !p.includes('..') && !out.includes(p)) {
      out.push(p)
    }
  }
  return out
}
