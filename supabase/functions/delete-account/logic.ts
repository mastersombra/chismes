/**
 * Lógica pura de delete-account (sin red): validación del request, huella
 * del email (en _shared/email_hash.ts) y limpieza de las rutas de media a borrar. Tests: logic.test.ts
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

// Huella del email: compartida con la detección de reincidentes
export { emailHash, normalizeEmail } from '../_shared/email_hash.ts'

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
