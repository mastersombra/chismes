/**
 * Tests de _shared/sanctions.ts y _shared/email_hash.ts
 *
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     test _shared/sanctions.test.ts
 */
import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { emailHash } from './email_hash.ts'
import {
  isBlocked,
  loadSanctionStatus,
  RESTRICTED_ERROR_CODE,
  restrictedResponseBody,
  type RpcClient,
  type SanctionStatus,
} from './sanctions.ts'

const OK: SanctionStatus = {
  state: 'ok',
  restricted_until: null,
  active_points: 1,
  strike_count: 1,
  expiry_days: 90,
  thresholds: { restriction_short: 3, restriction_long: 6, suspension: 10 },
}

function fakeClient(responses: Record<string, { data?: unknown; error?: unknown }>) {
  const calls: Array<{ fn: string; args: Record<string, unknown> }> = []
  const client: RpcClient = {
    rpc: (fn, args) => {
      calls.push({ fn, args })
      const r = responses[fn] ?? {}
      return Promise.resolve({ data: r.data ?? null, error: r.error ?? null })
    },
  }
  return { client, calls }
}

Deno.test('loadSanctionStatus: revisa heredadas con la huella y devuelve el estado', async () => {
  const { client, calls } = fakeClient({ get_user_sanction_status: { data: OK } })
  const status = await loadSanctionStatus(client, { id: 'u1', email: ' U1@T.co ' }, 'secret')

  assertEquals(status, OK)
  assertEquals(calls.map((c) => c.fn), ['claim_inherited_strikes', 'get_user_sanction_status'])
  assertEquals(calls[0].args.p_email_hash, await emailHash('u1@t.co', 'secret'))
  assertEquals(calls[1].args, { p_user_id: 'u1' })
})

Deno.test('loadSanctionStatus: sin secret o sin email no revisa heredadas', async () => {
  const noSecret = fakeClient({ get_user_sanction_status: { data: OK } })
  assertEquals(await loadSanctionStatus(noSecret.client, { id: 'u1', email: 'a@t.co' }, undefined), OK)
  assertEquals(noSecret.calls.map((c) => c.fn), ['get_user_sanction_status'])

  const noEmail = fakeClient({ get_user_sanction_status: { data: OK } })
  assertEquals(await loadSanctionStatus(noEmail.client, { id: 'u1', email: null }, 'secret'), OK)
  assertEquals(noEmail.calls.map((c) => c.fn), ['get_user_sanction_status'])
})

Deno.test('loadSanctionStatus: si falla la revisión de heredadas igual devuelve el estado', async () => {
  const { client } = fakeClient({
    claim_inherited_strikes: { error: { message: 'boom' } },
    get_user_sanction_status: { data: OK },
  })
  assertEquals(await loadSanctionStatus(client, { id: 'u1', email: 'a@t.co' }, 'secret'), OK)
})

Deno.test('loadSanctionStatus: error o respuesta inválida → null (fail-closed en quien llama)', async () => {
  const failing = fakeClient({ get_user_sanction_status: { error: { message: 'down' } } })
  assertEquals(await loadSanctionStatus(failing.client, { id: 'u1' }, undefined), null)

  const invalid = fakeClient({ get_user_sanction_status: { data: { state: 'banned' } } })
  assertEquals(await loadSanctionStatus(invalid.client, { id: 'u1' }, undefined), null)
})

Deno.test('isBlocked / restrictedResponseBody', () => {
  assert(!isBlocked(OK))
  const restricted: SanctionStatus = { ...OK, state: 'restricted', restricted_until: '2026-11-22T00:00:00Z' }
  const suspended: SanctionStatus = { ...OK, state: 'suspended' }
  assert(isBlocked(restricted))
  assert(isBlocked(suspended))
  assertEquals(restrictedResponseBody(restricted), {
    error: 'Account restricted',
    code: RESTRICTED_ERROR_CODE,
    state: 'restricted',
    restricted_until: '2026-11-22T00:00:00Z',
  })
})
