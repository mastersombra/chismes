/**
 * Tests de moderation-review/logic.ts
 *
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     deno test moderation-review/logic.test.ts
 */
import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  appealDecisionErrorResponse,
  isModerator,
  LIST_DEFAULT_LIMIT,
  parseReviewRequest,
} from './logic.ts'

const QUEUE_ID = '3f2b9c1e-8d4a-4b6e-9f00-123456789abc'

// ---------- isModerator ----------

Deno.test('isModerator: solo app_metadata.role = moderator', () => {
  assert(isModerator({ app_metadata: { role: 'moderator' } }))
  assert(!isModerator({ app_metadata: { role: 'admin' } }))
  assert(!isModerator({ app_metadata: {} }))
  assert(!isModerator({}))
  assert(!isModerator(null))
  // user_metadata lo escribe el propio usuario: no cuenta
  assert(!isModerator({ app_metadata: {}, user_metadata: { role: 'moderator' } } as never))
})

// ---------- list ----------

Deno.test('list: defaults pending y límite por defecto', () => {
  assertEquals(parseReviewRequest({ action: 'list' }), {
    ok: true,
    value: { action: 'list', status: 'pending', limit: LIST_DEFAULT_LIMIT, offset: 0 },
  })
})

Deno.test('list: offset para paginar el historial', () => {
  assertEquals(parseReviewRequest({ action: 'list', status: 'approved', limit: 20, offset: 40 }), {
    ok: true,
    value: { action: 'list', status: 'approved', limit: 20, offset: 40 },
  })
  for (const offset of [-1, 10_001, 1.5, '20']) {
    const r = parseReviewRequest({ action: 'list', offset })
    assert(!r.ok && r.field === 'offset', `offset ${offset} debería fallar`)
  }
})

Deno.test('list: valida status y límite', () => {
  assertEquals(parseReviewRequest({ action: 'list', status: 'rejected', limit: 50 }).ok, true)
  assertEquals(parseReviewRequest({ action: 'list', status: 'borrado' }), {
    ok: false, error: 'status must be one of pending, approved, rejected', field: 'status',
  })
  for (const limit of [0, 51, 2.5, '10']) {
    const r = parseReviewRequest({ action: 'list', limit })
    assert(!r.ok && r.field === 'limit', `limit ${limit} debería fallar`)
  }
})

// ---------- decide ----------

Deno.test('decide approve: sin gravedad; recorta motivo y nota', () => {
  assertEquals(parseReviewRequest({
    action: 'decide', queue_id: QUEUE_ID, decision: 'approve', reason: '  falso positivo ', note: '',
  }), {
    ok: true,
    value: {
      action: 'decide', queueId: QUEUE_ID, decision: 'approve',
      severity: null, reason: 'falso positivo', note: null,
    },
  })
})

Deno.test('decide reject: gravedad obligatoria y válida', () => {
  const ok = parseReviewRequest({ action: 'decide', queue_id: QUEUE_ID, decision: 'reject', severity: 'high' })
  assert(ok.ok && ok.value.action === 'decide' && ok.value.severity === 'high')

  for (const severity of [undefined, null, 'extreme']) {
    const r = parseReviewRequest({ action: 'decide', queue_id: QUEUE_ID, decision: 'reject', severity })
    assert(!r.ok && r.field === 'severity', `severity ${severity} debería fallar`)
  }
})

Deno.test('decide approve con gravedad: inválido', () => {
  const r = parseReviewRequest({ action: 'decide', queue_id: QUEUE_ID, decision: 'approve', severity: 'low' })
  assert(!r.ok && r.field === 'severity')
})

Deno.test('decide: valida queue_id, decision y longitudes', () => {
  const base = { action: 'decide', queue_id: QUEUE_ID, decision: 'approve' }
  assertEquals(parseReviewRequest({ ...base, queue_id: 'abc' }).ok, false)
  assertEquals(parseReviewRequest({ ...base, decision: 'delete' }).ok, false)
  assertEquals(parseReviewRequest({ ...base, reason: 'x'.repeat(101) }).ok, false)
  assertEquals(parseReviewRequest({ ...base, note: 'x'.repeat(1001) }).ok, false)
  assertEquals(parseReviewRequest({ ...base, note: 42 }).ok, false)
  assertEquals(parseReviewRequest({ ...base, note: 'x'.repeat(1000) }).ok, true)
})

Deno.test('body inválido o acción desconocida', () => {
  for (const body of [null, [], 'list', 42, {}, { action: 'delete' }]) {
    assertEquals(parseReviewRequest(body).ok, false)
  }
})

// ---------- apelaciones ----------

const APPEAL_ID = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d'

Deno.test('list_appeals: defaults y estados de apelación', () => {
  assertEquals(parseReviewRequest({ action: 'list_appeals' }), {
    ok: true,
    value: { action: 'list_appeals', status: 'pending', limit: LIST_DEFAULT_LIMIT, offset: 0 },
  })
  assertEquals(parseReviewRequest({ action: 'list_appeals', status: 'accepted', limit: 5, offset: 10 }), {
    ok: true,
    value: { action: 'list_appeals', status: 'accepted', limit: 5, offset: 10 },
  })
  // 'approved' es de la cola, no de apelaciones
  const r = parseReviewRequest({ action: 'list_appeals', status: 'approved' })
  assert(!r.ok && r.field === 'status')
  const page = parseReviewRequest({ action: 'list_appeals', limit: 0 })
  assert(!page.ok && page.field === 'limit')
})

Deno.test('decide_appeal: aceptar / rechazar con nota opcional', () => {
  assertEquals(parseReviewRequest({ action: 'decide_appeal', appeal_id: APPEAL_ID, decision: 'accept', note: '  ok ' }), {
    ok: true,
    value: { action: 'decide_appeal', appealId: APPEAL_ID, decision: 'accept', note: 'ok' },
  })
  assertEquals(parseReviewRequest({ action: 'decide_appeal', appeal_id: APPEAL_ID, decision: 'reject' }), {
    ok: true,
    value: { action: 'decide_appeal', appealId: APPEAL_ID, decision: 'reject', note: null },
  })
})

Deno.test('decide_appeal: inválidos', () => {
  const field = (body: Record<string, unknown>) => {
    const r = parseReviewRequest({ action: 'decide_appeal', appeal_id: APPEAL_ID, decision: 'accept', ...body })
    return r.ok ? null : r.field
  }
  assertEquals(field({ appeal_id: 'nope' }), 'appeal_id')
  assertEquals(field({ decision: 'approve' }), 'decision')
  assertEquals(field({ note: 'x'.repeat(1001) }), 'note')
  assertEquals(field({ note: 5 }), 'note')
})

Deno.test('appealDecisionErrorResponse: errores de decide_appeal', () => {
  assertEquals(appealDecisionErrorResponse('appeal_not_found').status, 404)
  assertEquals(appealDecisionErrorResponse('appeal_already_decided').status, 409)
  assertEquals(appealDecisionErrorResponse('appeal_same_moderator'), {
    status: 409, error: 'Appeal must be decided by another moderator', code: 'same_moderator',
  })
  assertEquals(appealDecisionErrorResponse('boom').status, 500)
})
