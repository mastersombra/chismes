/**
 * E2E de sanciones y apelaciones (015_sanctions.sql) contra el Supabase LOCAL.
 * Correr con ./scripts/e2e.sh
 *
 * Verifica: account-status (auth, estado), rechazo humano → restricción que
 * bloquea publicar y reportar, apelación (validación, duplicado, panel,
 * aceptar → desbloquea y republica) y reincidente (elimina la cuenta, se
 * registra con el mismo email → hereda la suspensión).
 */
import { assert, assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  callFunction,
  createGossip,
  createUser,
  gossipRow,
  queueEntry,
  type Row,
  type TestUser,
} from './helpers.ts'

const moderator = await createUser('sanc-moderator', { role: 'moderator' })
const other = await createUser('sanc-other')

function review(body: Record<string, unknown>, token = moderator.token) {
  return callFunction('moderation-review', { token, body })
}

function accountStatus(user: TestUser, body: unknown = {}) {
  return callFunction('account-status', { token: user.token, body })
}

/** Publica algo que va a la cola (IA caída) y el moderador lo rechaza */
async function rejectedGossip(author: TestUser, severity: string): Promise<{ gossipId: string; queueId: string }> {
  const r = await createGossip(author, { content: `Algo para revisar [[ai:down]] ${crypto.randomUUID()}` })
  assertEquals(r.status, 200, JSON.stringify(r.body))
  const entry = await queueEntry(r.body.gossip.id)
  assertExists(entry)
  const decided = await review({
    action: 'decide',
    queue_id: entry.id,
    decision: 'reject',
    severity,
    reason: 'insult',
  })
  assertEquals(decided.status, 200, JSON.stringify(decided.body))
  return { gossipId: r.body.gossip.id, queueId: entry.id }
}

Deno.test('account-status: sin token → 401; cuenta limpia → ok sin rechazos', async () => {
  const noToken = await callFunction('account-status', { token: null, body: {} })
  assertEquals(noToken.status, 401)

  const fresh = await createUser('sanc-fresh')
  const r = await accountStatus(fresh)
  assertEquals(r.status, 200)
  assertEquals(r.body.status.state, 'ok')
  assertEquals(r.body.status.active_points, 0)
  assertEquals(r.body.status.rejections, [])

  const bad = await accountStatus(fresh, { action: 'nope' })
  assertEquals(bad.status, 400)
})

Deno.test('sanción: rechazo alto → restringido, no publica ni reporta; apelar → aceptar desbloquea', async () => {
  const author = await createUser('sanc-author')
  const { gossipId, queueId } = await rejectedGossip(author, 'high')

  // Estado: restringido 24 h (4 puntos)
  const status = await accountStatus(author)
  assertEquals(status.status, 200)
  assertEquals(status.body.status.state, 'restricted')
  assertEquals(status.body.status.active_points, 4)
  assertExists(status.body.status.restricted_until)
  const rejection: Row = status.body.status.rejections[0]
  assertEquals(rejection.queue_id, queueId)
  assertEquals(rejection.severity, 'high')
  assertEquals(rejection.can_appeal, true)
  assertEquals(rejection.sanction, 'restriction')
  assert(!JSON.stringify(status.body).includes('decided_by'), 'no expone al moderador')

  // Bloqueado al publicar y al reportar
  const publish = await createGossip(author)
  assertEquals(publish.status, 403)
  assertEquals(publish.body.code, 'account_restricted')
  assertEquals(publish.body.state, 'restricted')
  assertExists(publish.body.restricted_until)

  const target = await createGossip(other, { content: `De otro ${crypto.randomUUID()}` })
  assertEquals(target.status, 200)
  const report = await callFunction('report-gossip', {
    token: author.token,
    body: { gossip_id: target.body.gossip.id, reason: 'spam' },
  })
  assertEquals(report.status, 403)
  assertEquals(report.body.code, 'account_restricted')

  // Apelar: mensaje corto → 400; ajeno → 404; válido → 201; otra vez → 409
  const short = await accountStatus(author, { action: 'appeal', queue_id: queueId, message: 'corto' })
  assertEquals(short.status, 400)
  const foreign = await accountStatus(other, { action: 'appeal', queue_id: queueId, message: 'Esto no es mío pero apelo' })
  assertEquals(foreign.status, 404)
  const appeal = await accountStatus(author, {
    action: 'appeal',
    queue_id: queueId,
    message: 'No era un insulto, era un chiste entre amigos',
  })
  assertEquals(appeal.status, 201, JSON.stringify(appeal.body))
  assertEquals(appeal.body.appeal.status, 'pending')
  const again = await accountStatus(author, { action: 'appeal', queue_id: queueId, message: 'Insisto en mi apelación' })
  assertEquals(again.status, 409)
  assertEquals(again.body.code, 'appeal_already_exists')

  // Panel: un usuario normal no lista; el moderador la ve con el contenido original
  const forbidden = await review({ action: 'list_appeals' }, other.token)
  assertEquals(forbidden.status, 403)
  const list = await review({ action: 'list_appeals', status: 'pending', limit: 50 })
  assertEquals(list.status, 200)
  const item: Row | undefined = list.body.items.find((i: Row) => i.id === appeal.body.appeal.id)
  assertExists(item)
  assertEquals(item.gossip_id, gossipId)
  assertEquals(item.original_severity, 'high')
  assertEquals(item.message, 'No era un insulto, era un chiste entre amigos')

  // Aceptar → falta anulada, texto republicado, puede publicar otra vez
  const accepted = await review({ action: 'decide_appeal', appeal_id: item.id, decision: 'accept', note: 'tiene razón' })
  assertEquals(accepted.status, 200, JSON.stringify(accepted.body))
  assertEquals(accepted.body.appeal.status, 'accepted')
  const twice = await review({ action: 'decide_appeal', appeal_id: item.id, decision: 'reject' })
  assertEquals(twice.status, 409)

  const gossip = await gossipRow(gossipId)
  assertEquals(gossip?.status, 'published')
  assertEquals(gossip?.moderation_status, 'approved')

  const after = await accountStatus(author)
  assertEquals(after.body.status.state, 'ok')
  assertEquals(after.body.status.active_points, 0)
  assertEquals(after.body.status.rejections[0].overturned, true)
  assertEquals(after.body.status.rejections[0].appeal.status, 'accepted')

  const publishAgain = await createGossip(author)
  assertEquals(publishAgain.status, 200, JSON.stringify(publishAgain.body))

  const history = await review({ action: 'list_appeals', status: 'accepted' })
  assert(history.body.items.some((i: Row) => i.id === item.id))
})

Deno.test('sanción: una leve → advertencia, sigue publicando', async () => {
  const author = await createUser('sanc-warned')
  await rejectedGossip(author, 'low')

  const status = await accountStatus(author)
  assertEquals(status.body.status.state, 'ok')
  assertEquals(status.body.status.rejections[0].sanction, 'warning')
  const publish = await createGossip(author)
  assertEquals(publish.status, 200)
})

Deno.test('reincidente: crítica → elimina la cuenta → mismo email → sigue suspendido', async () => {
  const author = await createUser('sanc-repeat')
  await rejectedGossip(author, 'critical')
  assertEquals((await accountStatus(author)).body.status.state, 'suspended')

  const deleted = await callFunction('delete-account', {
    token: author.token,
    body: { confirmation: 'DELETE_MY_ACCOUNT' },
  })
  assertEquals(deleted.status, 200, JSON.stringify(deleted.body))

  const reborn = await createUser('sanc-repeat', {}, author.email)
  const publish = await createGossip(reborn)
  assertEquals(publish.status, 403)
  assertEquals(publish.body.state, 'suspended')

  const status = await accountStatus(reborn)
  assertEquals(status.body.status.state, 'suspended')
  assertEquals(status.body.status.rejections, [])
  assertEquals(status.body.status.inherited.sanction, 'suspension')
})
