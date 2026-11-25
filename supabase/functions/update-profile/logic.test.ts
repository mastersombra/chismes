/**
 * Tests de update-profile/logic.ts
 *
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     test update-profile/logic.test.ts
 */
import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  avatarPath,
  type CurrentProfile,
  databaseErrorResponse,
  diffProfile,
  isReservedUsername,
  moderationText,
  needsModeration,
  parseUpdateProfileRequest,
  profileUpdateRow,
  usernameAvailableAt,
} from './logic.ts'

const PNG = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='

const current: CurrentProfile = {
  username: 'ana_m',
  display_name: 'Ana',
  bio: 'Hola',
  avatar_path: 'u1/1.jpg',
  username_changed_at: null,
}

function parsed(body: unknown) {
  const r = parseUpdateProfileRequest(body)
  if (!r.ok) throw new Error(`esperaba ok: ${r.error}`)
  return r.value
}

function parseError(body: unknown) {
  const r = parseUpdateProfileRequest(body)
  if (r.ok) throw new Error('esperaba error')
  return r
}

Deno.test('parse: body inválido o vacío', () => {
  assertEquals(parseError(null).error, 'Body must be a JSON object')
  assertEquals(parseError([]).error, 'Body must be a JSON object')
  assertEquals(parseError({}).error, 'Nothing to update')
  assertEquals(parseError({ otro: 1 }).error, 'Nothing to update')
})

Deno.test('parse: username en minúsculas, recortado y con formato', () => {
  assertEquals(parsed({ username: '  Ana_M2 ' }).username, 'ana_m2')
  assertEquals(parseError({ username: 'ab' }).field, 'username')
  assertEquals(parseError({ username: 'con espacio' }).field, 'username')
  assertEquals(parseError({ username: 'a'.repeat(31) }).field, 'username')
  assertEquals(parseError({ username: 'ñandú' }).field, 'username')
  assertEquals(parseError({ username: 5 }).error, 'username must be a string')
})

Deno.test('parse: username reservado (también con _ o números al final)', () => {
  assertEquals(parseError({ username: 'admin' }).error, 'username is reserved')
  assertEquals(parseError({ username: 'Soporte_1' }).error, 'username is reserved')
  assertEquals(parseError({ username: 'chismes_app' }).error, 'username is reserved')
  assert(isReservedUsername('moderador99'))
  assert(!isReservedUsername('administra_tu_vida'))
  assert(!isReservedUsername('ana'))
})

Deno.test('parse: display_name recortado; vacío → null; largo máximo', () => {
  assertEquals(parsed({ display_name: '  Ana   María ' }).displayName, 'Ana María')
  assertEquals(parsed({ display_name: '   ' }).displayName, null)
  assertEquals(parsed({ display_name: null }).displayName, null)
  assertEquals(parsed({ display_name: 'a'.repeat(50) }).displayName, 'a'.repeat(50))
  assertEquals(parseError({ display_name: 'a'.repeat(51) }).field, 'display_name')
  assertEquals(parseError({ display_name: 3 }).field, 'display_name')
})

Deno.test('parse: bio conserva saltos de línea; vacío → null; 160 caracteres (emoji = 1)', () => {
  assertEquals(parsed({ bio: ' Hola\nmundo ' }).bio, 'Hola\nmundo')
  assertEquals(parsed({ bio: '' }).bio, null)
  assertEquals(parsed({ bio: null }).bio, null)
  assertEquals(parsed({ bio: '😀'.repeat(160) }).bio, '😀'.repeat(160))
  assertEquals(parseError({ bio: 'a'.repeat(161) }).field, 'bio')
  assertEquals(parseError({ bio: 1 }).field, 'bio')
})

Deno.test('parse: foto en base64, quitar foto y sus errores', () => {
  const avatar = parsed({ avatar_base64: PNG }).avatar!
  assertEquals([avatar[0], avatar[1], avatar[2], avatar[3]], [0x89, 0x50, 0x4E, 0x47])
  assertEquals(parsed({ remove_avatar: true }).removeAvatar, true)
  assertEquals(parsed({ remove_avatar: false, bio: 'x' }).removeAvatar, undefined)
  assertEquals(parseError({ avatar_base64: PNG, remove_avatar: true }).field, 'avatar_base64')
  assertEquals(parseError({ avatar_base64: '' }).field, 'avatar_base64')
  assertEquals(parseError({ avatar_base64: '***' }).error, 'avatar_base64 is not valid base64')
  assertEquals(parseError({ avatar_base64: 'A'.repeat(2_900_000) }).error, 'avatar too large (max 2 MB)')
  assertEquals(parseError({ remove_avatar: 'si' }).field, 'remove_avatar')
})

Deno.test('diffProfile: solo lo que cambia', () => {
  assertEquals(diffProfile(current, { username: 'ana_m', displayName: 'Ana', bio: 'Hola' }), {})
  assertEquals(diffProfile(current, { username: 'ana_z', bio: null }), { username: 'ana_z', bio: null })
  assertEquals(diffProfile({ ...current, avatar_path: null }, { removeAvatar: true }), {})
  assertEquals(diffProfile(current, { removeAvatar: true }), { removeAvatar: true })
  const avatar = new Uint8Array([1])
  assertEquals(diffProfile(current, { avatar }).avatar, avatar)
})

Deno.test('needsModeration y moderationText: solo texto nuevo o foto', () => {
  assert(!needsModeration({ bio: null, displayName: null, removeAvatar: true }))
  assert(needsModeration({ bio: 'nueva' }))
  assert(needsModeration({ avatar: new Uint8Array([1]) }))
  assertEquals(moderationText({ username: 'ana_z', displayName: 'Ana Z', bio: 'Bio' }), {
    subject: 'ana_z\nAna Z',
    content: 'Bio',
  })
  assertEquals(moderationText({ displayName: null, bio: null }), { subject: '', content: '' })
})

Deno.test('usernameAvailableAt: primera elección libre; luego cada N días', () => {
  const now = new Date('2026-11-24T12:00:00Z')
  assertEquals(usernameAvailableAt({ ...current, username: null }, 30, now), null)
  assertEquals(usernameAvailableAt(current, 30, now), null)
  assertEquals(
    usernameAvailableAt({ ...current, username_changed_at: '2026-11-14T12:00:00Z' }, 30, now)?.toISOString(),
    '2026-12-14T12:00:00.000Z',
  )
  assertEquals(usernameAvailableAt({ ...current, username_changed_at: '2026-10-01T00:00:00Z' }, 30, now), null)
})

Deno.test('profileUpdateRow y avatarPath', () => {
  assertEquals(profileUpdateRow({ username: 'x_y', displayName: null, avatar: new Uint8Array() }), {
    username: 'x_y',
    display_name: null,
  })
  assertEquals(profileUpdateRow({ bio: 'b' }), { bio: 'b' })
  assertEquals(avatarPath('u1', 'jpg', 42), 'u1/42.jpg')
})

Deno.test('databaseErrorResponse: duplicado, límite de @usuario, CHECK, otros', () => {
  assertEquals(databaseErrorResponse(null), null)
  assertEquals(databaseErrorResponse({ code: '23505' })?.body.error, 'username_taken')
  const cooldown = databaseErrorResponse({ code: 'P0010', message: 'username_cooldown', details: '2026-12-14' })
  assertEquals(cooldown, {
    status: 409,
    body: { error: 'username_cooldown', field: 'username', available_at: '2026-12-14' },
  })
  assertEquals(databaseErrorResponse({ code: '23514', message: 'check' })?.status, 400)
  assertEquals(databaseErrorResponse({ code: 'XX000', message: 'boom' }), null)
})
