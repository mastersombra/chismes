/**
 * Tests de account-status/logic.ts
 *
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     test account-status/logic.test.ts
 */
import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { appealErrorResponse, parseAccountStatusRequest } from './logic.ts'

const QUEUE_ID = '6f1c2a7e-4b5d-4c3e-9f8a-1b2c3d4e5f60'

Deno.test('parseAccountStatusRequest: sin body o status → estado', () => {
  assertEquals(parseAccountStatusRequest(null), { ok: true, value: { action: 'status' } })
  assertEquals(parseAccountStatusRequest({}), { ok: true, value: { action: 'status' } })
  assertEquals(parseAccountStatusRequest({ action: 'status' }), { ok: true, value: { action: 'status' } })
})

Deno.test('parseAccountStatusRequest: apelación válida, mensaje recortado', () => {
  assertEquals(
    parseAccountStatusRequest({ action: 'appeal', queue_id: QUEUE_ID, message: '  No era un insulto  ' }),
    { ok: true, value: { action: 'appeal', queueId: QUEUE_ID, message: 'No era un insulto' } },
  )
})

Deno.test('parseAccountStatusRequest: apelación inválida', () => {
  const bad = (body: unknown, field?: string) => {
    const r = parseAccountStatusRequest(body)
    assert(!r.ok)
    if (field) assertEquals(r.field, field)
  }
  bad({ action: 'appeal', queue_id: 'x', message: 'mensaje suficiente' }, 'queue_id')
  bad({ action: 'appeal', queue_id: QUEUE_ID, message: '   corto   ' }, 'message')
  bad({ action: 'appeal', queue_id: QUEUE_ID, message: 'a'.repeat(1001) }, 'message')
  bad({ action: 'appeal', queue_id: QUEUE_ID, message: 42 }, 'message')
  bad({ action: 'delete' }, 'action')
  bad([1, 2])
  bad('status')
})

Deno.test('appealErrorResponse: errores de submit_appeal', () => {
  assertEquals(appealErrorResponse('appeal_target_not_found'), { status: 404, code: 'not_found' })
  assertEquals(appealErrorResponse('appeal_already_exists'), { status: 409, code: 'appeal_already_exists' })
  assertEquals(appealErrorResponse('appeal_window_closed'), { status: 409, code: 'appeal_window_closed' })
  assertEquals(appealErrorResponse('invalid_appeal_message'), { status: 400, code: 'validation_error' })
  assertEquals(appealErrorResponse('connection reset'), { status: 500, code: 'server_error' })
})
