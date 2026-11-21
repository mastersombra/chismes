/**
 * E2E de delete-account contra el Supabase LOCAL (ver edge_functions_e2e.test.ts).
 * Correr con ./scripts/e2e.sh
 *
 * Verifica: auth, confirmación, borrado real (auth, chismes, media pública y en
 * cuarentena), registro anónimo de faltas y que el token viejo deja de servir.
 */
import { assert, assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  API,
  callFunction,
  createGossip,
  createUser,
  http,
  listObjects,
  objectExists,
  PNG_BASE64,
  rest,
  type Row,
  SERVICE_KEY,
  type TestUser,
} from './helpers.ts'

const HASH_SECRET = Deno.env.get('E2E_ACCOUNT_HASH_SECRET') ?? ''
const CONFIRM = { confirmation: 'DELETE_MY_ACCOUNT' }
const serviceHeaders = { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` }

const moderator = await createUser('del-moderator', { role: 'moderator' })
const reporters = await Promise.all([1, 2, 3].map((i) => createUser(`del-reporter${i}`)))

// Cuentas recién creadas: que cuenten para el umbral de reportes
await rest('moderation_settings?key=eq.report_min_account_age_hours', {
  method: 'PATCH',
  body: { value: 0 },
})

/** Misma huella que delete-account (HMAC-SHA256 del email normalizado) */
async function emailHash(email: string): Promise<string> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey('raw', enc.encode(HASH_SECRET), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'])
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(email.trim().toLowerCase()))
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('')
}

async function authUserExists(user: TestUser): Promise<boolean> {
  const r = await http(`/auth/v1/admin/users/${user.id}`, { headers: serviceHeaders })
  return r.status === 200
}

async function uploadQuarantine(user: TestUser, name: string): Promise<string> {
  const path = `quarantine/${user.id}/${name}`
  const bytes = Uint8Array.from(atob(PNG_BASE64), (c) => c.charCodeAt(0))
  const r = await fetch(`${API}/storage/v1/object/images-quarantine/${path}`, {
    method: 'POST',
    headers: { ...serviceHeaders, 'Content-Type': 'image/png' },
    body: bytes,
  })
  const text = await r.text()
  if (r.status !== 200) throw new Error(`upload ${path}: ${r.status} ${text}`)
  return path
}

/** Chisme publicado → 3 reportes → el moderador lo rechaza con gravedad */
async function rejectedGossip(author: TestUser, severity: string): Promise<string> {
  const id = (await createGossip(author, { subject: `Para rechazar ${severity}` })).body.gossip.id
  for (const reporter of reporters) {
    const r = await callFunction('report-gossip', { token: reporter.token, body: { gossip_id: id, reason: 'harassment' } })
    assertEquals(r.status, 201)
  }
  const entry = ((await rest(`moderation_queue?gossip_id=eq.${id}&select=id`)).body as Row[])[0]
  assertExists(entry, 'debería estar en la cola')
  const decided = await callFunction('moderation-review', {
    token: moderator.token,
    body: { action: 'decide', queue_id: entry.id, decision: 'reject', severity, reason: 'harassment' },
  })
  assertEquals(decided.status, 200)
  return id
}

Deno.test('delete-account: sin Authorization → 401', async () => {
  const r = await callFunction('delete-account', { token: null, body: CONFIRM })
  assertEquals(r.status, 401)
})

Deno.test('delete-account: la anon key (sin usuario) → 401', async () => {
  const r = await callFunction('delete-account', { body: CONFIRM })
  assertEquals(r.status, 401)
})

Deno.test('delete-account: sin confirmación correcta → 400 y la cuenta sigue', async () => {
  const user = await createUser('del-noconfirm')
  for (const body of [{}, { confirmation: 'yes' }]) {
    const r = await callFunction('delete-account', { token: user.token, body })
    assertEquals(r.status, 400)
  }
  const invalid = await callFunction('delete-account', { token: user.token, rawBody: '{nope' })
  assertEquals(invalid.status, 400)
  assert(await authUserExists(user))
})

Deno.test('delete-account: sin faltas → borra cuenta, chismes y media; sin registro', async () => {
  const user = await createUser('del-clean')
  const published = await createGossip(user, { image_base64: PNG_BASE64 })
  assertEquals(published.status, 200)
  const gossipId = published.body.gossip.id
  const row = ((await rest(`gossips?id=eq.${gossipId}&select=storage_path,thumbnail_storage_path`)).body as Row[])[0]
  assert(await objectExists('images', row.storage_path))
  const leftover = await uploadQuarantine(user, 'sin-cola.png')

  const r = await callFunction('delete-account', { token: user.token, body: { ...CONFIRM, reason: 'E2E' } })
  assertEquals(r.status, 200)
  assertEquals(r.body.deleted, true)

  assert(!(await authUserExists(user)), 'el usuario sigue en auth')
  assertEquals((await rest(`gossips?created_by=eq.${user.id}&select=id`)).body, [])
  assertEquals((await rest(`profiles?id=eq.${user.id}&select=id`)).body, [])
  assert(!(await objectExists('images', row.storage_path)), 'la imagen pública sigue')
  assert(!(await objectExists('images', row.thumbnail_storage_path)), 'el thumbnail sigue')
  assert(!(await objectExists('images-quarantine', leftover)), 'la cuarentena sigue')
  assertEquals(await listObjects('images-quarantine', `quarantine/${user.id}`), [])

  const records = await rest(`account_deletion_records?email_hash=eq.${await emailHash(user.email)}&select=id`)
  assertEquals(records.body, [], 'sin faltas no debe guardar registro')
})

Deno.test('delete-account: con faltas → registro anónimo con gravedad; el token deja de servir', async () => {
  const user = await createUser('del-offender')
  await rejectedGossip(user, 'high')

  const r = await callFunction('delete-account', { token: user.token, body: CONFIRM })
  assertEquals(r.status, 200)
  assert(!(await authUserExists(user)))
  assertEquals((await rest(`moderation_queue?content_author_id=eq.${user.id}&select=id`)).body, [])

  const records = (await rest(
    `account_deletion_records?email_hash=eq.${await emailHash(user.email)}&select=*`,
  )).body as Row[]
  assertEquals(records.length, 1)
  assertEquals(records[0].rejections_high, 1)
  assertEquals(records[0].rejections_critical, 0)
  assertEquals(records[0].deletion_count, 1)
  // Anónimo: ninguna columna guarda el id ni el email
  const raw = JSON.stringify(records[0])
  assert(!raw.includes(user.id) && !raw.includes(user.email))

  // El JWT viejo ya no autentica (el usuario no existe)
  const again = await callFunction('delete-account', { token: user.token, body: CONFIRM })
  assertEquals(again.status, 401)
  const post = await callFunction('moderate-gossip', { token: user.token, body: {} })
  assertEquals(post.status, 401)
})
