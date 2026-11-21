/**
 * account-status: validación de pedidos y mapeo de errores (sin red ni DB)
 *
 * Probado en logic.test.ts.
 */

export const APPEAL_MIN_LENGTH = 10
export const APPEAL_MAX_LENGTH = 1000

export type AccountStatusRequest =
  | { action: 'status' }
  | { action: 'appeal'; queueId: string; message: string }

export type ParseResult =
  | { ok: true; value: AccountStatusRequest }
  | { ok: false; error: string; field?: string }

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function parseAccountStatusRequest(body: unknown): ParseResult {
  if (body === null || body === undefined) return { ok: true, value: { action: 'status' } }
  if (typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'Body must be a JSON object' }
  }
  const b = body as Record<string, unknown>
  const action = b.action ?? 'status'

  if (action === 'status') return { ok: true, value: { action: 'status' } }

  if (action === 'appeal') {
    if (typeof b.queue_id !== 'string' || !UUID_RE.test(b.queue_id)) {
      return { ok: false, error: 'queue_id must be a UUID', field: 'queue_id' }
    }
    const message = typeof b.message === 'string' ? b.message.trim() : ''
    if (message.length < APPEAL_MIN_LENGTH || message.length > APPEAL_MAX_LENGTH) {
      return {
        ok: false,
        error: `message must be between ${APPEAL_MIN_LENGTH} and ${APPEAL_MAX_LENGTH} chars`,
        field: 'message',
      }
    }
    return { ok: true, value: { action: 'appeal', queueId: b.queue_id, message } }
  }

  return { ok: false, error: "action must be 'status' or 'appeal'", field: 'action' }
}

/** Error de submit_appeal → respuesta HTTP (code lo usa la app) */
export function appealErrorResponse(message: string): { status: number; code: string } {
  if (message.includes('appeal_target_not_found')) return { status: 404, code: 'not_found' }
  if (message.includes('appeal_already_exists')) return { status: 409, code: 'appeal_already_exists' }
  if (message.includes('appeal_window_closed')) return { status: 409, code: 'appeal_window_closed' }
  if (message.includes('invalid_appeal_message')) return { status: 400, code: 'validation_error' }
  return { status: 500, code: 'server_error' }
}
