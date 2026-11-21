/**
 * Tests de delete-account/logic.ts
 *
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     test delete-account/logic.test.ts
 */
import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  cleanPaths,
  DELETE_CONFIRMATION,
  emailHash,
  normalizeEmail,
  parseDeleteRequest,
} from './logic.ts'

Deno.test('parseDeleteRequest: exige la confirmación exacta', () => {
  assertEquals(parseDeleteRequest({ confirmation: DELETE_CONFIRMATION }), { ok: true, reason: null })
  assert(!parseDeleteRequest({ confirmation: 'delete_my_account' }).ok)
  assert(!parseDeleteRequest({}).ok)
  assert(!parseDeleteRequest(null).ok)
  assert(!parseDeleteRequest([DELETE_CONFIRMATION]).ok)
  assert(!parseDeleteRequest('DELETE_MY_ACCOUNT').ok)
})

Deno.test('parseDeleteRequest: motivo opcional, recortado a 200', () => {
  assertEquals(
    parseDeleteRequest({ confirmation: DELETE_CONFIRMATION, reason: '  ya no la uso  ' }),
    { ok: true, reason: 'ya no la uso' },
  )
  assertEquals(
    parseDeleteRequest({ confirmation: DELETE_CONFIRMATION, reason: '   ' }),
    { ok: true, reason: null },
  )
  const long = parseDeleteRequest({ confirmation: DELETE_CONFIRMATION, reason: 'x'.repeat(500) })
  assert(long.ok && long.reason?.length === 200)
  assert(!parseDeleteRequest({ confirmation: DELETE_CONFIRMATION, reason: 42 }).ok)
})

Deno.test('normalizeEmail: trim + minúsculas; vacío → null', () => {
  assertEquals(normalizeEmail('  Ana@Example.COM '), 'ana@example.com')
  assertEquals(normalizeEmail(''), null)
  assertEquals(normalizeEmail('   '), null)
  assertEquals(normalizeEmail(null), null)
  assertEquals(normalizeEmail(undefined), null)
})

Deno.test('emailHash: HMAC estable, hex de 64, depende del secret', async () => {
  const a = await emailHash('Ana@Example.com', 'secret-1')
  const b = await emailHash(' ana@example.com ', 'secret-1')
  const c = await emailHash('ana@example.com', 'secret-2')
  assert(a !== null && /^[0-9a-f]{64}$/.test(a))
  assertEquals(a, b)
  assert(a !== c)
  assertEquals(await emailHash(null, 'secret-1'), null)
})

Deno.test('emailHash: vector conocido (RFC 4231 caso 2)', async () => {
  // HMAC-SHA256(key="Jefe", data="what do ya want for nothing?")
  assertEquals(
    await emailHash('what do ya want for nothing?', 'Jefe'),
    '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
  )
})

Deno.test('cleanPaths: strings válidos sin duplicados', () => {
  assertEquals(
    cleanPaths(['quarantine/u/a.jpg', 'quarantine/u/a.jpg', '', null, 7, '../x', 'quarantine/u/b.jpg']),
    ['quarantine/u/a.jpg', 'quarantine/u/b.jpg'],
  )
})
