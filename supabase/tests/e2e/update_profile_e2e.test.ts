/**
 * E2E de update-profile (017_profile_editing.sql) contra el Supabase LOCAL.
 * Correr con ./scripts/e2e.sh
 *
 * Verifica: auth y validación; la app ya no escribe directo en profiles;
 * sin cambios no gasta nada; moderación de texto y foto (rechazo, IA caída →
 * 503, nada se guarda); @usuario (primera elección libre, límite de días,
 * duplicado, reservado); foto (formato real, sube a avatars y borra la
 * anterior, quitar foto); sanción vigente bloquea texto y foto pero no
 * borrar; configuración (user_settings) directa del dueño; eliminar la
 * cuenta borra la foto.
 */
import { assert, assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  ANON_KEY,
  callFunction,
  createGossip,
  createUser,
  http,
  listObjects,
  objectExists,
  PDF_BASE64,
  PNG_BASE64,
  queueEntry,
  resetRateLimit,
  rest,
  type Row,
  type TestUser,
} from './helpers.ts'

const moderator = await createUser('prof-moderator', { role: 'moderator' })

function updateProfile(user: TestUser, body: unknown) {
  return callFunction('update-profile', { token: user.token, body })
}

/** Cambia el perfil sin esperar el cooldown de 30 s entre cambios */
async function update(user: TestUser, body: unknown) {
  await resetRateLimit(user)
  return updateProfile(user, body)
}

async function profileRow(user: TestUser): Promise<Row> {
  const r = await rest(`profiles?id=eq.${user.id}&select=*`)
  return (r.body as Row[])[0]
}

function uniqueUsername(prefix: string): string {
  return `${prefix}_${crypto.randomUUID().replaceAll('-', '').slice(0, 10)}`
}

/** Lo que haría una app modificada: escribir el perfil con su propio JWT */
function directPatch(user: TestUser, table: string, filter: string, body: unknown) {
  return http(`/rest/v1/${table}?${filter}`, {
    method: 'PATCH',
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${user.token}`, Prefer: 'return=representation' },
    body,
  })
}

Deno.test('update-profile: sin token → 401; body inválido o vacío → 400', async () => {
  const user = await createUser('prof-auth')
  assertEquals((await callFunction('update-profile', { token: null, body: { bio: 'x' } })).status, 401)
  assertEquals((await callFunction('update-profile', { body: { bio: 'x' } })).status, 401) // anon key

  const invalid = await callFunction('update-profile', { token: user.token, rawBody: '{no json' })
  assertEquals(invalid.status, 400)
  assertEquals((await updateProfile(user, {})).body.details, 'Nothing to update')
  assertEquals((await updateProfile(user, { username: 'a b' })).body.field, 'username')
  assertEquals((await updateProfile(user, { bio: 'x'.repeat(161) })).body.field, 'bio')
  assertEquals((await updateProfile(user, { username: 'admin' })).body.details, 'username is reserved')
})

Deno.test('profiles: la app ya no puede escribir directo (texto ni avatar_url)', async () => {
  const user = await createUser('prof-direct')
  const before = await profileRow(user)

  const r = await directPatch(user, 'profiles', `id=eq.${user.id}`, {
    bio: 'sin moderar',
    avatar_url: 'https://evil.example/tracker.png',
  })
  assert(r.status >= 400 || (Array.isArray(r.body) && r.body.length === 0), `respondió ${r.status}`)

  const after = await profileRow(user)
  assertEquals(after.bio, before.bio)
  assertEquals(after.avatar_url, before.avatar_url)
})

Deno.test('update-profile: guarda texto limpio; reenviar lo mismo no gasta el límite', async () => {
  const user = await createUser('prof-text')
  const username = uniqueUsername('ana')

  const r = await update(user, { username, display_name: '  Ana   M ', bio: 'Me gustan los chismes\ndel barrio' })
  assertEquals(r.status, 200, JSON.stringify(r.body))
  assertEquals(r.body.profile.username, username)
  assertEquals(r.body.profile.display_name, 'Ana M')
  assertEquals(r.body.profile.bio, 'Me gustan los chismes\ndel barrio')
  assertEquals(r.body.profile.username_changed_at, null, 'la primera elección no inicia el plazo')
  assertEquals(r.body.profile.profile_completed, true)

  // Mismos valores, sin esperar el cooldown de 30 s: no hay cambio → 200
  const same = await updateProfile(user, { username, display_name: 'Ana M' })
  assertEquals(same.status, 200, JSON.stringify(same.body))

  // Un cambio real inmediato sí respeta el cooldown
  const tooSoon = await updateProfile(user, { bio: 'otra' })
  assertEquals(tooSoon.status, 429)

  // Vaciar la bio la borra
  const cleared = await update(user, { bio: '' })
  assertEquals(cleared.status, 200)
  assertEquals((await profileRow(user)).bio, null)
})

Deno.test('update-profile: texto marcado o con datos personales → 400 y no se guarda', async () => {
  const user = await createUser('prof-reject')
  await update(user, { bio: 'Bio original' })

  const flagged = await update(user, { bio: 'Los voy a buscar [[ai:flag=violence]]' })
  assertEquals(flagged.status, 400)
  assertEquals(flagged.body.error, 'content_rejected')

  const phone = await update(user, { bio: 'Escríbanme al 3001234567' })
  assertEquals(phone.status, 400, JSON.stringify(phone.body))
  assertEquals(phone.body.error, 'content_rejected')

  const name = await update(user, { display_name: 'Insulto [[ai:flag=harassment]]' })
  assertEquals(name.body.error, 'content_rejected')

  assertEquals((await profileRow(user)).bio, 'Bio original')
  // El rechazo libera el slot: se puede corregir sin esperar
  assertEquals((await updateProfile(user, { bio: 'Bio corregida' })).status, 200)
})

Deno.test('update-profile: IA caída → 503 moderation_unavailable (fail-closed)', async () => {
  const user = await createUser('prof-ai-down')
  const r = await update(user, { bio: 'Hola [[ai:down]]' })
  assertEquals(r.status, 503)
  assertEquals(r.body.error, 'moderation_unavailable')
  assertEquals((await profileRow(user)).bio, null)
  // Nada queda en la cola de revisión: el perfil no se revisa a mano
  assertEquals((await rest(`moderation_queue?content_author_id=eq.${user.id}&select=id`)).body, [])
})

Deno.test('update-profile: @usuario duplicado → 409; cambio → plazo de 30 días', async () => {
  const first = await createUser('prof-user-a')
  const second = await createUser('prof-user-b')
  const taken = uniqueUsername('tomado')
  assertEquals((await update(first, { username: taken })).status, 200)

  const duplicate = await update(second, { username: taken.toUpperCase() })
  assertEquals(duplicate.status, 409)
  assertEquals(duplicate.body.error, 'username_taken')

  // second elige uno (libre) y luego lo cambia (inicia el plazo)
  assertEquals((await update(second, { username: uniqueUsername('uno') })).status, 200)
  const changed = await update(second, { username: uniqueUsername('dos') })
  assertEquals(changed.status, 200, JSON.stringify(changed.body))
  assertExists(changed.body.profile.username_changed_at)

  const again = await update(second, { username: uniqueUsername('tres') })
  assertEquals(again.status, 409)
  assertEquals(again.body.error, 'username_cooldown')
  const availableAt = new Date(again.body.available_at).getTime()
  const expected = new Date(changed.body.profile.username_changed_at).getTime() + 30 * 86_400_000
  assert(Math.abs(availableAt - expected) < 60_000, `available_at ${again.body.available_at}`)

  // Otros campos sí se pueden cambiar durante el plazo
  assertEquals((await update(second, { bio: 'Durante el plazo' })).status, 200)
})

Deno.test('update-profile: foto → avatars; cambiarla borra la anterior; quitarla', async () => {
  const user = await createUser('prof-avatar')

  const pdf = await update(user, { avatar_base64: PDF_BASE64 })
  assertEquals(pdf.status, 400)
  assertEquals(pdf.body.error, 'invalid_image')

  const first = await update(user, { avatar_base64: PNG_BASE64 })
  assertEquals(first.status, 200, JSON.stringify(first.body))
  const firstPath: string = first.body.profile.avatar_path
  assert(firstPath.startsWith(`${user.id}/`) && firstPath.endsWith('.png'), firstPath)
  assert(await objectExists('avatars', firstPath))
  const publicImage = await fetch(first.body.profile.avatar_url)
  assertEquals(publicImage.status, 200, 'la foto se ve por su URL pública')
  await publicImage.body?.cancel()

  const second = await update(user, { avatar_base64: PNG_BASE64 })
  const secondPath: string = second.body.profile.avatar_path
  assert(secondPath !== firstPath)
  assert(await objectExists('avatars', secondPath))
  assert(!(await objectExists('avatars', firstPath)), 'la foto anterior sigue en el bucket')

  const removed = await update(user, { remove_avatar: true })
  assertEquals(removed.status, 200)
  assertEquals(removed.body.profile.avatar_url, null)
  assertEquals(removed.body.profile.avatar_path, null)
  assertEquals(await listObjects('avatars', user.id), [])
})

Deno.test('update-profile: foto marcada por la IA → 400 y no se sube nada', async () => {
  const user = await createUser('prof-avatar-flag')
  // El OpenAI falso marca la imagen si el texto trae el marcador
  const r = await update(user, { avatar_base64: PNG_BASE64, bio: 'Hola [[ai:flag-image=sexual]]' })
  assertEquals(r.status, 400)
  assertEquals(r.body.error, 'content_rejected')
  assertEquals(await listObjects('avatars', user.id), [])
  const row = await profileRow(user)
  assertEquals(row.avatar_url, null)
  assertEquals(row.bio, null, 'tampoco se guarda el texto del mismo pedido')
})

Deno.test('update-profile: con sanción vigente no cambia texto ni foto, sí puede borrar', async () => {
  const user = await createUser('prof-sanctioned')
  assertEquals((await update(user, { bio: 'Antes de la sanción' })).status, 200)

  // Rechazo humano de gravedad alta (4 pts) → restricción
  const gossip = await createGossip(user, { content: `Para revisar [[ai:down]] ${crypto.randomUUID()}` })
  const entry = await queueEntry(gossip.body.gossip.id)
  assertExists(entry)
  const decided = await callFunction('moderation-review', {
    token: moderator.token,
    body: { action: 'decide', queue_id: entry.id, decision: 'reject', severity: 'high', reason: 'insult' },
  })
  assertEquals(decided.status, 200, JSON.stringify(decided.body))

  const text = await update(user, { bio: 'Nueva bio' })
  assertEquals(text.status, 403)
  assertEquals(text.body.code, 'account_restricted')
  assertEquals((await update(user, { avatar_base64: PNG_BASE64 })).status, 403)

  const cleared = await update(user, { bio: null })
  assertEquals(cleared.status, 200, 'borrar la bio no es contenido nuevo')
  assertEquals((await profileRow(user)).bio, null)
})

Deno.test('user_settings: el dueño la lee y la cambia directo; no la de otro', async () => {
  const user = await createUser('prof-settings')
  const other = await createUser('prof-settings-other')

  const own = await http(`/rest/v1/user_settings?select=*`, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${user.token}` },
  })
  assertEquals(own.status, 200)
  assertEquals(own.body.length, 1, 'solo ve la suya')
  assertEquals(own.body[0].privacy_level, 'public')

  const changed = await directPatch(user, 'user_settings', `user_id=eq.${user.id}`, {
    privacy_level: 'private',
    email_notifications: false,
  })
  assertEquals(changed.status, 200, JSON.stringify(changed.body))
  assertEquals(changed.body[0].privacy_level, 'private')

  const foreign = await directPatch(user, 'user_settings', `user_id=eq.${other.id}`, { privacy_level: 'private' })
  assertEquals(foreign.body, [])
  const otherRow = await rest(`user_settings?user_id=eq.${other.id}&select=privacy_level`)
  assertEquals(otherRow.body[0].privacy_level, 'public')
})

Deno.test('delete-account: también borra la foto de perfil', async () => {
  const user = await createUser('prof-delete')
  const r = await update(user, { avatar_base64: PNG_BASE64 })
  assertEquals(r.status, 200, JSON.stringify(r.body))
  assertEquals((await listObjects('avatars', user.id)).length, 1)

  const deleted = await callFunction('delete-account', {
    token: user.token,
    body: { confirmation: 'DELETE_MY_ACCOUNT' },
  })
  assertEquals(deleted.status, 200, JSON.stringify(deleted.body))
  assertEquals(await listObjects('avatars', user.id), [])
  assertEquals((await rest(`user_settings?user_id=eq.${user.id}&select=user_id`)).body, [])
})

