/**
 * E2E de seguridad de Storage: acceso DIRECTO de clientes a los buckets
 * (lo que podría intentar una app modificada con la anon key o un JWT de
 * usuario), sin pasar por las Edge Functions. Correr con ./scripts/e2e.sh
 *
 * Esperado (006_media_security.sql):
 * - Ningún cliente sube, sobrescribe, mueve, copia ni borra en ningún bucket
 * - Cuarentena: ni descarga, ni metadata, ni URL firmada, ni URL pública
 * - Públicos: el archivo se ve por su URL pública, pero el bucket NO se lista
 * - Nadie administra buckets (hacer pública la cuarentena, vaciar, borrar, crear)
 *
 * Se verifica el EFECTO (el archivo sigue igual, la cuarentena sigue privada),
 * no solo el código HTTP.
 */
import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { ANON_KEY, API, createUser, PNG_BASE64, SERVICE_KEY } from './helpers.ts'

const service = { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` }
const PNG = Uint8Array.from(atob(PNG_BASE64), (c) => c.charCodeAt(0))
const OTHER_BYTES = new TextEncoder().encode('reemplazado por un cliente')

const user = await createUser('storage-attacker')
const CLIENTS: Record<string, Record<string, string>> = {
  anon: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  user: { apikey: ANON_KEY, Authorization: `Bearer ${user.token}` },
}

const BUCKETS = [
  { id: 'images', public: true, file: 'img.png', mime: 'image/png' },
  { id: 'images-quarantine', public: false, file: 'img.png', mime: 'image/png' },
  { id: 'audio', public: true, file: 'clip.m4a', mime: 'audio/mp4' },
  { id: 'audio-quarantine', public: false, file: 'clip.m4a', mime: 'audio/mp4' },
]

async function call(
  method: string,
  path: string,
  headers: Record<string, string>,
  body?: BodyInit,
  contentType = 'application/json',
): Promise<{ status: number; text: string }> {
  const response = await fetch(`${API}/storage/v1${path}`, {
    method,
    headers: { ...headers, ...(body !== undefined ? { 'Content-Type': contentType } : {}) },
    body,
  })
  return { status: response.status, text: await response.text() }
}

const json = (value: unknown) => JSON.stringify(value)

/** Contenido real del archivo (service_role), o null si no existe */
async function contentOf(bucket: string, path: string): Promise<string | null> {
  const r = await fetch(`${API}/storage/v1/object/authenticated/${bucket}/${path}`, { headers: service })
  const bytes = new Uint8Array(await r.arrayBuffer())
  return r.status === 200 ? Array.from(bytes).join(',') : null
}

/** Archivo "de otro usuario" subido por el servidor, como hacen las funciones */
async function seed(bucket: (typeof BUCKETS)[number]): Promise<{ prefix: string; path: string }> {
  const prefix = `quarantine/${crypto.randomUUID()}`
  const path = `${prefix}/${bucket.file}`
  const r = await call('POST', `/object/${bucket.id}/${path}`, service, PNG, bucket.mime)
  if (r.status !== 200) throw new Error(`seed ${bucket.id}: ${r.status} ${r.text}`)
  return { prefix, path }
}

for (const bucket of BUCKETS) {
  for (const [role, headers] of Object.entries(CLIENTS)) {
    Deno.test(`storage ${bucket.id} (${role}): no puede escribir, mover, copiar ni borrar`, async () => {
      const { path } = await seed(bucket)
      const original = await contentOf(bucket.id, path)
      const own = `quarantine/${user.id}/${role}-${bucket.file}`

      const attempts = [
        call('POST', `/object/${bucket.id}/${own}`, headers, PNG, bucket.mime),
        call('PUT', `/object/${bucket.id}/${path}`, headers, OTHER_BYTES, bucket.mime),
        call('POST', `/object/${bucket.id}/${path}`, { ...headers, 'x-upsert': 'true' }, OTHER_BYTES, bucket.mime),
        call('POST', `/object/upload/sign/${bucket.id}/${own}`, headers),
        call('POST', '/object/move', headers, json({ bucketId: bucket.id, sourceKey: path, destinationKey: `${path}.moved` })),
        call('POST', '/object/copy', headers, json({ bucketId: bucket.id, sourceKey: path, destinationKey: `${path}.copy` })),
      ]
      for (const r of await Promise.all(attempts)) {
        assert(r.status >= 400, `una escritura respondió ${r.status}: ${r.text}`)
      }
      // DELETE responde 200 con [] cuando RLS no deja borrar nada
      await call('DELETE', `/object/${bucket.id}`, headers, json({ prefixes: [path] }))

      assertEquals(await contentOf(bucket.id, path), original, 'el archivo cambió o desapareció')
      assertEquals(await contentOf(bucket.id, own), null, 'el cliente logró subir un archivo')
      assertEquals(await contentOf(bucket.id, `${path}.moved`), null)
      assertEquals(await contentOf(bucket.id, `${path}.copy`), null)
    })

    Deno.test(`storage ${bucket.id} (${role}): no puede listar el bucket`, async () => {
      const { prefix } = await seed(bucket)
      for (const listPrefix of [prefix, 'quarantine', '']) {
        const r = await call('POST', `/object/list/${bucket.id}`, headers, json({ prefix: listPrefix, limit: 100 }))
        const items = r.status === 200 ? JSON.parse(r.text) : []
        assertEquals(items, [], `listó ${bucket.id}/${listPrefix}: ${r.text.slice(0, 200)}`)
      }
    })

    if (bucket.public) {
      Deno.test(`storage ${bucket.id} (${role}): el archivo se ve por su URL pública`, async () => {
        const { path } = await seed(bucket)
        const r = await fetch(`${API}/storage/v1/object/public/${bucket.id}/${path}`)
        await r.arrayBuffer()
        assertEquals(r.status, 200)
      })
    } else {
      Deno.test(`storage ${bucket.id} (${role}): no puede leer la cuarentena`, async () => {
        const { path } = await seed(bucket)
        const reads = await Promise.all([
          call('GET', `/object/authenticated/${bucket.id}/${path}`, headers),
          call('GET', `/object/${bucket.id}/${path}`, headers),
          call('GET', `/object/info/${bucket.id}/${path}`, headers),
          call('GET', `/object/public/${bucket.id}/${path}`, {}),
          call('POST', `/object/sign/${bucket.id}/${path}`, headers, json({ expiresIn: 60 })),
        ])
        for (const r of reads) {
          assert(r.status >= 400, `una lectura respondió ${r.status}: ${r.text.slice(0, 200)}`)
        }

        // Firma en lote: puede responder 200, pero sin ninguna URL firmada
        const batch = await call('POST', `/object/sign/${bucket.id}`, headers, json({ expiresIn: 60, paths: [path] }))
        if (batch.status === 200) {
          for (const item of JSON.parse(batch.text) as Array<{ signedURL: string | null }>) {
            assertEquals(item.signedURL, null, `firmó una URL de cuarentena: ${batch.text}`)
          }
        }
      })
    }
  }
}

for (const [role, headers] of Object.entries(CLIENTS)) {
  Deno.test(`storage buckets (${role}): no puede administrar buckets`, async () => {
    const attempts = await Promise.all([
      call('PUT', '/bucket/images-quarantine', headers, json({ public: true })),
      call('PUT', '/bucket/audio-quarantine', headers, json({ public: true })),
      call('POST', '/bucket/images/empty', headers),
      call('DELETE', '/bucket/audio', headers),
      call('POST', '/bucket', headers, json({ name: `evil-${role}`, public: true })),
    ])
    for (const r of attempts) {
      assert(r.status >= 400, `una operación de bucket respondió ${r.status}: ${r.text}`)
    }

    const buckets = JSON.parse((await call('GET', '/bucket', service)).text) as Array<{ id: string; public: boolean }>
    const state = Object.fromEntries(buckets.map((b) => [b.id, b.public]))
    assertEquals(state['images-quarantine'], false)
    assertEquals(state['audio-quarantine'], false)
    assertEquals(state['images'], true)
    assertEquals(state['audio'], true)
    assert(!(`evil-${role}` in state), 'el cliente creó un bucket')
  })
}
