/**
 * E2E de las Edge Functions contra un Supabase LOCAL real (HTTP + JWT +
 * Postgres + Storage). OpenAI es un servidor falso (fake_openai.ts).
 *
 * Correr SIEMPRE con el script (levanta todo y limpia al final):
 *   ./scripts/e2e.sh
 *
 * Grupos: auth, validación, moderación, media, reportes y cola de revisión.
 */
import { assert, assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  ANON_KEY,
  API,
  callFunction,
  createGossip,
  createUser,
  gossipBody,
  gossipRow,
  lastOpenAIRequest,
  listObjects,
  objectExists,
  PDF_BASE64,
  PNG_BASE64,
  queueEntry,
  resetRateLimit,
  rest,
  type Row,
} from './helpers.ts'

const author = await createUser('author')
const other = await createUser('other')
const reporters = await Promise.all([1, 2, 3].map((i) => createUser(`reporter${i}`)))
const moderator = await createUser('moderator', { role: 'moderator' })

// Cuentas recién creadas: que cuenten para el umbral de reportes
await rest('moderation_settings?key=eq.report_min_account_age_hours', {
  method: 'PATCH',
  body: { value: 0 },
})

function review(body: Record<string, unknown>, token = moderator.token) {
  return callFunction('moderation-review', { token, body })
}

// =====================================================
// AUTH
// =====================================================

Deno.test('auth: moderate-gossip sin Authorization → 401', async () => {
  const r = await callFunction('moderate-gossip', { token: null, body: gossipBody() })
  assertEquals(r.status, 401)
})

Deno.test('auth: token inválido → 401', async () => {
  const r = await callFunction('moderate-gossip', { token: 'no-es-un-jwt', body: gossipBody() })
  assertEquals(r.status, 401)
})

Deno.test('auth: la anon key (sin usuario) no puede publicar → 401', async () => {
  const r = await callFunction('moderate-gossip', { body: gossipBody() })
  assertEquals(r.status, 401)
})

Deno.test('auth: report-gossip sin usuario → 401', async () => {
  const r = await callFunction('report-gossip', { body: { gossip_id: crypto.randomUUID(), reason: 'spam' } })
  assertEquals(r.status, 401)
})

Deno.test('auth: moderation-review con usuario normal → 403', async () => {
  const r = await review({ action: 'list' }, author.token)
  assertEquals(r.status, 403)
})

Deno.test('auth: moderation-review con moderador → 200', async () => {
  const r = await review({ action: 'list' })
  assertEquals(r.status, 200)
  assert(Array.isArray(r.body.items))
})

// =====================================================
// VALIDACIÓN
// =====================================================

Deno.test('validación: asunto vacío → 400 con el campo', async () => {
  const r = await createGossip(author, { subject: '   ' })
  assertEquals(r.status, 400)
  assert(JSON.stringify(r.body).includes('subject'))
})

Deno.test('validación: asunto de más de 200 caracteres → 400', async () => {
  const r = await createGossip(author, { subject: 'a'.repeat(201) })
  assertEquals(r.status, 400)
})

Deno.test('validación: published_as inválido → 400', async () => {
  const r = await createGossip(author, { published_as: 'admin' })
  assertEquals(r.status, 400)
})

Deno.test('validación: idempotency_key que no es UUID → 400', async () => {
  const r = await createGossip(author, { idempotency_key: 'abc' })
  assertEquals(r.status, 400)
})

Deno.test('validación: ciudad que no existe → 400 Invalid location', async () => {
  const r = await createGossip(author, { city_id: 'no-existe' })
  assertEquals(r.status, 400)
  assertEquals(r.body.error, 'Invalid location')
})

Deno.test('validación: JSON inválido → 400', async () => {
  const r = await callFunction('moderate-gossip', { token: author.token, rawBody: '{no es json' })
  assertEquals(r.status, 400)
})

Deno.test('rate limit: dos chismes seguidos → el segundo 429 (cooldown)', async () => {
  const first = await createGossip(author)
  assertEquals(first.status, 200)
  const second = await callFunction('moderate-gossip', { token: author.token, body: gossipBody() })
  assertEquals(second.status, 429)
})

Deno.test('idempotencia: misma key dos veces → mismo chisme, sin duplicar', async () => {
  const body = gossipBody({ subject: 'Idempotente' })
  await resetRateLimit(author)
  const first = await callFunction('moderate-gossip', { token: author.token, body })
  await resetRateLimit(author)
  const retry = await callFunction('moderate-gossip', { token: author.token, body })

  assertEquals(first.status, 200)
  assertEquals(retry.status, 200)
  assertEquals(retry.body.gossip.id, first.body.gossip.id)
  assertEquals(retry.body.idempotent, true)
  const rows = await rest(`gossips?idempotency_key=eq.${body.idempotency_key}&select=id`)
  assertEquals(rows.body.length, 1)
})

// =====================================================
// MODERACIÓN DE TEXTO
// =====================================================

Deno.test('moderación: texto limpio → publicado y visible en public_gossips', async () => {
  const r = await createGossip(author)
  assertEquals(r.status, 200)
  assertEquals(r.body.gossip.status, 'published')
  assertEquals(r.body.gossip.moderation_status, 'approved')

  const visible = await visibleCount(r.body.gossip.id, other.token)
  assertEquals(visible, 1)
})

Deno.test('moderación: marcado por la IA → 400 rechazado y no se guarda', async () => {
  const body = gossipBody({ content: 'Contenido horrible [[ai:flag=harassment]]' })
  await resetRateLimit(author)
  const r = await callFunction('moderate-gossip', { token: author.token, body })

  assertEquals(r.status, 400)
  assertEquals(r.body.error, 'Content rejected by moderation')
  assertEquals(r.body.reasons, ['harassment'])
  const rows = await rest(`gossips?idempotency_key=eq.${body.idempotency_key}&select=id`)
  assertEquals(rows.body.length, 0)
})

Deno.test('moderación: IA caída → borrador en la cola (fail-closed), no se publica', async () => {
  const r = await createGossip(author, { content: 'Algo normal [[ai:down]]' })
  assertEquals(r.status, 200)
  assertEquals(r.body.gossip.status, 'draft')

  const entry = await mustQueueEntry(r.body.gossip.id)
  assertExists(entry)
  assertEquals(entry.source, 'ai_unavailable')
  assert(entry.reasons.includes('moderation_unavailable'))
  assertEquals(await visibleCount(r.body.gossip.id, other.token), 0)
})

Deno.test('moderación: grosería de la tabla → revisión con term:<término>', async () => {
  const r = await createGossip(author, { content: 'Ese man es un malparido' })
  assertEquals(r.body.gossip.status, 'draft')
  const entry = await mustQueueEntry(r.body.gossip.id)
  assertEquals(entry.source, 'ai_review')
  assert(entry.reasons.includes('term:malparido'))
})

Deno.test('moderación: regla nueva en la tabla aplica sin desplegar', async () => {
  const rule = await rest('moderation_rules', {
    method: 'POST',
    prefer: 'return=representation',
    body: { kind: 'term', target: 'palabra prohibida', action: 'reject' },
  })
  assertEquals(rule.status, 201)
  try {
    const r = await createGossip(author, { content: 'Esto lleva una Palabra Prohibida' })
    assertEquals(r.status, 400)
    assertEquals(r.body.reasons, ['term:palabra prohibida'])
  } finally {
    await rest(`moderation_rules?id=eq.${rule.body[0].id}`, { method: 'DELETE' })
  }
})

Deno.test('moderación: umbral de IA de la tabla manda a revisión', async () => {
  const rule = await rest('moderation_rules', {
    method: 'POST',
    prefer: 'return=representation',
    body: { kind: 'ai_category', target: 'harassment', action: 'review', min_score: 0.3 },
  })
  try {
    const r = await createGossip(author, { content: 'Medio pesado [[ai:score=harassment:0.45]]' })
    assertEquals(r.body.gossip.status, 'draft')
    const entry = await mustQueueEntry(r.body.gossip.id)
    assert(entry.reasons.includes('ai_score:harassment'))
  } finally {
    await rest(`moderation_rules?id=eq.${rule.body[0].id}`, { method: 'DELETE' })
  }
})

// =====================================================
// MEDIA
// =====================================================

Deno.test('media: imagen válida → publicada en el bucket público, cuarentena vacía', async () => {
  const r = await createGossip(author, { image_base64: PNG_BASE64 })
  assertEquals(r.status, 200)
  const gossip = r.body.gossip
  assertEquals(gossip.status, 'published')
  assertExists(gossip.image_url)

  const row = await mustGossipRow(gossip.id)
  assert(await objectExists('images', row.storage_path), 'la imagen no está en el bucket público')
  assertEquals(await listObjects('images-quarantine', `quarantine/${author.id}`), [])

  // OpenAI recibió la imagen como data URL, nunca una URL de la cuarentena
  const sent = await lastOpenAIRequest()
  const image = sent.input.find((i: { type: string }) => i.type === 'image_url')
  assert(image.image_url.url.startsWith('data:image/png;base64,'))
})

Deno.test('media: PDF disfrazado de imagen → 400 por magic bytes', async () => {
  const body = gossipBody({ image_base64: PDF_BASE64 })
  await resetRateLimit(author)
  const r = await callFunction('moderate-gossip', { token: author.token, body })

  assertEquals(r.status, 400)
  assertEquals(r.body.error, 'Image upload failed')
  const rows = await rest(`gossips?idempotency_key=eq.${body.idempotency_key}&select=id`)
  assertEquals(rows.body.length, 0)
})

Deno.test('media: imagen de más de 5 MB → 400', async () => {
  // PNG válido por magic bytes + relleno hasta 6 MB
  const header = Uint8Array.from(atob(PNG_BASE64), (c) => c.charCodeAt(0))
  const big = new Uint8Array(6 * 1024 * 1024)
  big.set(header)
  let binary = ''
  for (let i = 0; i < big.length; i += 0x8000) {
    binary += String.fromCharCode(...big.subarray(i, i + 0x8000))
  }
  const r = await createGossip(author, { image_base64: btoa(binary) })
  assertEquals(r.status, 400)
})

Deno.test('media: imagen marcada por la IA → rechazo y se borra de la cuarentena', async () => {
  const r = await createGossip(author, {
    content: 'Texto inocente [[ai:flag-image=sexual]]',
    image_base64: PNG_BASE64,
  })
  assertEquals(r.status, 400)
  assertEquals(r.body.reasons, ['sexual'])
  assertEquals(await listObjects('images-quarantine', `quarantine/${author.id}`), [])
})

Deno.test('media: en revisión la imagen espera en cuarentena; al aprobar se publica', async () => {
  const r = await createGossip(author, {
    content: 'Con foto y un malparido',
    image_base64: PNG_BASE64,
  })
  const gossipId = r.body.gossip.id
  assertEquals(r.body.gossip.status, 'draft')
  assertEquals(r.body.gossip.image_url ?? null, null)

  const entry = await mustQueueEntry(gossipId)
  assertExists(entry.image_quarantine_path)
  assert(await objectExists('images-quarantine', entry.image_quarantine_path))

  // El moderador ve la imagen con URL firmada
  const list = await review({ action: 'list', limit: 50 })
  const item = list.body.items.find((i: { id: string }) => i.id === entry.id)
  assertExists(item)
  assertExists(item.image_preview_url)

  const decided = await review({ action: 'decide', queue_id: entry.id, decision: 'approve' })
  assertEquals(decided.status, 200)

  const row = await mustGossipRow(gossipId)
  assertEquals(row.status, 'published')
  assertEquals(row.moderation_status, 'approved')
  assertExists(row.image_url)
  assert(await objectExists('images', row.storage_path))
  assert(!(await objectExists('images-quarantine', entry.image_quarantine_path)))
})

// =====================================================
// REPORTES Y COLA DE REVISIÓN
// =====================================================

Deno.test('reportes: validaciones (propio, motivo, inexistente, duplicado)', async () => {
  const gossipId = (await createGossip(author)).body.gossip.id

  const own = await callFunction('report-gossip', {
    token: author.token,
    body: { gossip_id: gossipId, reason: 'spam' },
  })
  assertEquals(own.status, 400)

  const badReason = await callFunction('report-gossip', {
    token: other.token,
    body: { gossip_id: gossipId, reason: 'no_me_gusta' },
  })
  assertEquals(badReason.status, 400)

  const missing = await callFunction('report-gossip', {
    token: other.token,
    body: { gossip_id: crypto.randomUUID(), reason: 'spam' },
  })
  assertEquals(missing.status, 404)

  const first = await callFunction('report-gossip', {
    token: other.token,
    body: { gossip_id: gossipId, reason: 'spam' },
  })
  assertEquals(first.status, 201)
  const duplicate = await callFunction('report-gossip', {
    token: other.token,
    body: { gossip_id: gossipId, reason: 'spam' },
  })
  assertEquals(duplicate.status, 409)
})

Deno.test('reportes → cola → el moderador rechaza con gravedad → oculto', async () => {
  const gossipId = (await createGossip(author, { subject: 'Para reportar' })).body.gossip.id

  for (const reporter of reporters) {
    const r = await callFunction('report-gossip', {
      token: reporter.token,
      body: { gossip_id: gossipId, reason: 'harassment' },
    })
    assertEquals(r.status, 201)
  }

  const entry = await mustQueueEntry(gossipId)
  assertExists(entry, 'con 3 reportes debería entrar a la cola')
  assertEquals(entry.source, 'reports')
  assertEquals(entry.report_count, 3)

  // Rechazar exige gravedad
  const noSeverity = await review({ action: 'decide', queue_id: entry.id, decision: 'reject' })
  assertEquals(noSeverity.status, 400)

  const rejected = await review({
    action: 'decide',
    queue_id: entry.id,
    decision: 'reject',
    severity: 'high',
    reason: 'harassment',
    note: 'E2E',
  })
  assertEquals(rejected.status, 200)

  const row = await mustGossipRow(gossipId)
  assertEquals(row.status, 'hidden')
  assertEquals(await visibleCount(gossipId, other.token), 0)

  // No se decide dos veces
  const again = await review({ action: 'decide', queue_id: entry.id, decision: 'approve' })
  assertEquals(again.status, 409)

  // Aparece en el historial de rechazados, con la decisión
  const history = await review({ action: 'list', status: 'rejected', limit: 50 })
  const item = history.body.items.find((i: { id: string }) => i.id === entry.id)
  assertExists(item)
  assertEquals(item.decision_severity, 'high')
  assertEquals(item.decided_by, moderator.id)
})

Deno.test('rechazar un chisme publicado con foto → la foto deja de ser pública', async () => {
  // Autor propio: `author` ya tiene un rechazo alto (restringido, 015_sanctions)
  const photoAuthor = await createUser('photo-author')
  const published = await createGossip(photoAuthor, { subject: 'Foto para rechazar', image_base64: PNG_BASE64 })
  assertEquals(published.status, 200)
  const gossipId = published.body.gossip.id
  const before = await mustGossipRow(gossipId)
  assert(await objectExists('images', before.storage_path))
  const publicUrl = `${API}/storage/v1/object/public/images/${before.storage_path}`

  for (const reporter of reporters) {
    const r = await callFunction('report-gossip', {
      token: reporter.token,
      body: { gossip_id: gossipId, reason: 'harassment' },
    })
    assertEquals(r.status, 201)
  }
  const entry = await mustQueueEntry(gossipId)

  const rejected = await review({
    action: 'decide',
    queue_id: entry.id,
    decision: 'reject',
    severity: 'critical',
    reason: 'personal_data',
  })
  assertEquals(rejected.status, 200)
  assert(!('removed_media' in rejected.body.item), 'la respuesta no debe exponer rutas internas')

  const after = await mustGossipRow(gossipId)
  assertEquals(after.status, 'hidden')
  assertEquals(after.subject, 'Foto para rechazar', 'el texto debe quedar para apelación')
  assertEquals([after.image_url, after.storage_path, after.thumbnail_storage_path], [null, null, null])
  assert(!(await objectExists('images', before.storage_path)), 'la foto sigue en el bucket público')
  assert(!(await objectExists('images', before.thumbnail_storage_path)), 'el thumbnail sigue')
  const r = await fetch(publicUrl)
  await r.body?.cancel()
  assert(r.status >= 400, `la URL pública sigue respondiendo ${r.status}`)
})

Deno.test('cola: paginación con offset sin repetir ítems', async () => {
  const page1 = await review({ action: 'list', status: 'pending', limit: 2, offset: 0 })
  const page2 = await review({ action: 'list', status: 'pending', limit: 2, offset: 2 })
  assertEquals(page1.status, 200)
  assertEquals(page2.status, 200)
  const ids1 = page1.body.items.map((i: { id: string }) => i.id)
  const ids2 = page2.body.items.map((i: { id: string }) => i.id)
  assert(ids1.length > 0)
  assertEquals(ids1.filter((id: string) => ids2.includes(id)), [])
})

async function mustQueueEntry(gossipId: string): Promise<Row> {
  const entry = await queueEntry(gossipId)
  assertExists(entry, `el chisme ${gossipId} no está en la cola`)
  return entry
}

async function mustGossipRow(gossipId: string): Promise<Row> {
  const row = await gossipRow(gossipId)
  assertExists(row, `no existe el chisme ${gossipId}`)
  return row
}

/** Cuántas filas ve un usuario en public_gossips para ese chisme (0 o 1) */
async function visibleCount(gossipId: string, token: string): Promise<number> {
  const response = await fetch(`${API}/rest/v1/public_gossips?id=eq.${gossipId}&select=id`, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${token}` },
  })
  return (await response.json()).length
}
