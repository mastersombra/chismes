/**
 * moderation-review: autorización y validación de pedidos (sin red ni DB)
 *
 * Probado en logic.test.ts.
 */

export const MODERATOR_ROLE = 'moderator'
export const SEVERITIES = ['low', 'medium', 'high', 'critical'] as const
export const QUEUE_STATUSES = ['pending', 'approved', 'rejected'] as const
export const LIST_DEFAULT_LIMIT = 20
export const LIST_MAX_LIMIT = 50
export const REASON_MAX_LENGTH = 100
export const NOTE_MAX_LENGTH = 1000

export type Severity = typeof SEVERITIES[number]
export type QueueStatus = typeof QUEUE_STATUSES[number]

export type ReviewRequest =
  | { action: 'list'; status: QueueStatus; limit: number }
  | {
    action: 'decide'
    queueId: string
    decision: 'approve' | 'reject'
    severity: Severity | null
    reason: string | null
    note: string | null
  }

export type ParseResult =
  | { ok: true; value: ReviewRequest }
  | { ok: false; error: string; field?: string }

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

/**
 * Moderador = app_metadata.role === 'moderator'.
 * app_metadata solo lo escribe el backend (service_role / dashboard): el
 * usuario no puede asignárselo. Usar el `user` que devuelve auth.getUser()
 * (verificado contra el servidor), no claims decodificados a mano.
 */
export function isModerator(user: { app_metadata?: Record<string, unknown> } | null | undefined): boolean {
  return user?.app_metadata?.role === MODERATOR_ROLE
}

export function parseReviewRequest(body: unknown): ParseResult {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { ok: false, error: 'Body must be a JSON object' }
  }
  const b = body as Record<string, unknown>

  if (b.action === 'list') {
    const status = b.status ?? 'pending'
    if (!QUEUE_STATUSES.includes(status as QueueStatus)) {
      return { ok: false, error: `status must be one of ${QUEUE_STATUSES.join(', ')}`, field: 'status' }
    }
    const limit = b.limit ?? LIST_DEFAULT_LIMIT
    if (!Number.isInteger(limit) || (limit as number) < 1 || (limit as number) > LIST_MAX_LIMIT) {
      return { ok: false, error: `limit must be an integer between 1 and ${LIST_MAX_LIMIT}`, field: 'limit' }
    }
    return { ok: true, value: { action: 'list', status: status as QueueStatus, limit: limit as number } }
  }

  if (b.action === 'decide') {
    if (typeof b.queue_id !== 'string' || !UUID_RE.test(b.queue_id)) {
      return { ok: false, error: 'queue_id must be a UUID', field: 'queue_id' }
    }
    if (b.decision !== 'approve' && b.decision !== 'reject') {
      return { ok: false, error: "decision must be 'approve' or 'reject'", field: 'decision' }
    }

    let severity: Severity | null = null
    if (b.decision === 'reject') {
      if (!SEVERITIES.includes(b.severity as Severity)) {
        return {
          ok: false,
          error: `severity is required to reject (${SEVERITIES.join(', ')})`,
          field: 'severity',
        }
      }
      severity = b.severity as Severity
    } else if (b.severity !== undefined && b.severity !== null) {
      return { ok: false, error: 'severity only applies to reject', field: 'severity' }
    }

    const reason = optionalText(b.reason, REASON_MAX_LENGTH)
    if (reason === undefined) {
      return { ok: false, error: `reason must be a string of at most ${REASON_MAX_LENGTH} chars`, field: 'reason' }
    }
    const note = optionalText(b.note, NOTE_MAX_LENGTH)
    if (note === undefined) {
      return { ok: false, error: `note must be a string of at most ${NOTE_MAX_LENGTH} chars`, field: 'note' }
    }

    return {
      ok: true,
      value: { action: 'decide', queueId: b.queue_id, decision: b.decision, severity, reason, note },
    }
  }

  return { ok: false, error: "action must be 'list' or 'decide'", field: 'action' }
}

/** null si no viene o viene vacío; undefined si es inválido. */
function optionalText(value: unknown, max: number): string | null | undefined {
  if (value === undefined || value === null) return null
  if (typeof value !== 'string') return undefined
  const trimmed = value.trim()
  if (trimmed.length === 0) return null
  return trimmed.length <= max ? trimmed : undefined
}
