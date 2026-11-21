/**
 * moderation-review: autorización y validación de pedidos (sin red ni DB)
 *
 * Probado en logic.test.ts.
 */

export const MODERATOR_ROLE = 'moderator'
export const SEVERITIES = ['low', 'medium', 'high', 'critical'] as const
export const QUEUE_STATUSES = ['pending', 'approved', 'rejected'] as const
export const APPEAL_STATUSES = ['pending', 'accepted', 'rejected'] as const
export const LIST_DEFAULT_LIMIT = 20
export const LIST_MAX_LIMIT = 50
export const LIST_MAX_OFFSET = 10_000
export const REASON_MAX_LENGTH = 100
export const NOTE_MAX_LENGTH = 1000

export type Severity = typeof SEVERITIES[number]
export type QueueStatus = typeof QUEUE_STATUSES[number]
export type AppealStatus = typeof APPEAL_STATUSES[number]

export type ReviewRequest =
  | { action: 'list'; status: QueueStatus; limit: number; offset: number }
  | {
    action: 'decide'
    queueId: string
    decision: 'approve' | 'reject'
    severity: Severity | null
    reason: string | null
    note: string | null
  }
  | { action: 'list_appeals'; status: AppealStatus; limit: number; offset: number }
  | { action: 'decide_appeal'; appealId: string; decision: 'accept' | 'reject'; note: string | null }

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

  if (b.action === 'list' || b.action === 'list_appeals') {
    const statuses: readonly string[] = b.action === 'list' ? QUEUE_STATUSES : APPEAL_STATUSES
    const status = b.status ?? 'pending'
    if (typeof status !== 'string' || !statuses.includes(status)) {
      return { ok: false, error: `status must be one of ${statuses.join(', ')}`, field: 'status' }
    }
    const page = parsePage(b)
    if (!page.ok) return page
    return b.action === 'list'
      ? { ok: true, value: { action: 'list', status: status as QueueStatus, ...page.value } }
      : { ok: true, value: { action: 'list_appeals', status: status as AppealStatus, ...page.value } }
  }

  if (b.action === 'decide_appeal') {
    if (typeof b.appeal_id !== 'string' || !UUID_RE.test(b.appeal_id)) {
      return { ok: false, error: 'appeal_id must be a UUID', field: 'appeal_id' }
    }
    if (b.decision !== 'accept' && b.decision !== 'reject') {
      return { ok: false, error: "decision must be 'accept' or 'reject'", field: 'decision' }
    }
    const note = optionalText(b.note, NOTE_MAX_LENGTH)
    if (note === undefined) {
      return { ok: false, error: `note must be a string of at most ${NOTE_MAX_LENGTH} chars`, field: 'note' }
    }
    return { ok: true, value: { action: 'decide_appeal', appealId: b.appeal_id, decision: b.decision, note } }
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

  return {
    ok: false,
    error: "action must be 'list', 'decide', 'list_appeals' or 'decide_appeal'",
    field: 'action',
  }
}

function parsePage(
  b: Record<string, unknown>,
): { ok: true; value: { limit: number; offset: number } } | { ok: false; error: string; field: string } {
  const limit = b.limit ?? LIST_DEFAULT_LIMIT
  if (!Number.isInteger(limit) || (limit as number) < 1 || (limit as number) > LIST_MAX_LIMIT) {
    return { ok: false, error: `limit must be an integer between 1 and ${LIST_MAX_LIMIT}`, field: 'limit' }
  }
  const offset = b.offset ?? 0
  if (!Number.isInteger(offset) || (offset as number) < 0 || (offset as number) > LIST_MAX_OFFSET) {
    return { ok: false, error: `offset must be an integer between 0 and ${LIST_MAX_OFFSET}`, field: 'offset' }
  }
  return { ok: true, value: { limit: limit as number, offset: offset as number } }
}

/** Error de decide_appeal → respuesta HTTP */
export function appealDecisionErrorResponse(message: string): { status: number; error: string; code?: string } {
  if (message.includes('appeal_not_found')) return { status: 404, error: 'Appeal not found' }
  if (message.includes('appeal_already_decided')) return { status: 409, error: 'Appeal already decided' }
  if (message.includes('appeal_same_moderator')) {
    return { status: 409, error: 'Appeal must be decided by another moderator', code: 'same_moderator' }
  }
  return { status: 500, error: 'Failed to decide appeal' }
}

/** null si no viene o viene vacío; undefined si es inválido. */
function optionalText(value: unknown, max: number): string | null | undefined {
  if (value === undefined || value === null) return null
  if (typeof value !== 'string') return undefined
  const trimmed = value.trim()
  if (trimmed.length === 0) return null
  return trimmed.length <= max ? trimmed : undefined
}
