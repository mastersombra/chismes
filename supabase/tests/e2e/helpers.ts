/**
 * Cliente mínimo (solo fetch) contra el Supabase local del E2E.
 * Variables: las pone scripts/e2e.sh.
 */

function env(name: string): string {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`Falta la variable ${name} (correr con scripts/e2e.sh)`)
  return value
}

export const API = env('E2E_API_URL')
export const ANON_KEY = env('E2E_ANON_KEY')
export const SERVICE_KEY = env('E2E_SERVICE_KEY')
export const FAKE_OPENAI = env('E2E_FAKE_OPENAI_URL')
export const CITY = {
  country_id: env('E2E_COUNTRY_ID'),
  region_id: env('E2E_REGION_ID'),
  city_id: env('E2E_CITY_ID'),
}

/** PNG 1×1 válido (magic bytes reales) */
export const PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
/** Un PDF disfrazado: el cliente dice "imagen", los magic bytes no */
export const PDF_BASE64 = btoa('%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\n%%EOF')

export interface HttpResult {
  status: number
  // deno-lint-ignore no-explicit-any
  body: any
}

export async function http(
  path: string,
  init: { method?: string; headers?: Record<string, string>; body?: unknown; rawBody?: string } = {},
): Promise<HttpResult> {
  const response = await fetch(`${API}${path}`, {
    method: init.method ?? 'GET',
    headers: { 'Content-Type': 'application/json', ...init.headers },
    body: init.rawBody ?? (init.body === undefined ? undefined : JSON.stringify(init.body)),
  })
  const text = await response.text()
  let body: unknown = text
  try {
    body = text ? JSON.parse(text) : null
  } catch { /* texto plano */ }
  return { status: response.status, body }
}

const serviceHeaders = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
}

/** PostgREST con service_role (verificar el estado real en la base) */
export function rest(path: string, init: { method?: string; body?: unknown; prefer?: string } = {}) {
  return http(`/rest/v1/${path}`, {
    method: init.method,
    body: init.body,
    headers: { ...serviceHeaders, ...(init.prefer ? { Prefer: init.prefer } : {}) },
  })
}

/** Llama a una Edge Function como lo hace la app */
export function callFunction(
  name: string,
  opts: { token?: string | null; body?: unknown; rawBody?: string } = {},
) {
  const headers: Record<string, string> = { apikey: ANON_KEY }
  if (opts.token !== null) headers.Authorization = `Bearer ${opts.token ?? ANON_KEY}`
  return http(`/functions/v1/${name}`, { method: 'POST', headers, body: opts.body, rawBody: opts.rawBody })
}

export interface TestUser {
  id: string
  email: string
  token: string
}

/** Crea un usuario confirmado e inicia sesión (JWT real de GoTrue). fixedEmail: re-registro */
export async function createUser(
  name: string,
  appMetadata: Record<string, unknown> = {},
  fixedEmail?: string,
): Promise<TestUser> {
  const email = fixedEmail ?? `${name}-${crypto.randomUUID().slice(0, 8)}@e2e.test`
  const password = `E2e-${crypto.randomUUID()}`

  const created = await http('/auth/v1/admin/users', {
    method: 'POST',
    headers: serviceHeaders,
    body: { email, password, email_confirm: true, app_metadata: appMetadata },
  })
  if (created.status !== 200) throw new Error(`createUser ${name}: ${created.status} ${JSON.stringify(created.body)}`)

  const session = await http('/auth/v1/token?grant_type=password', {
    method: 'POST',
    headers: { apikey: ANON_KEY },
    body: { email, password },
  })
  if (session.status !== 200) throw new Error(`login ${name}: ${session.status} ${JSON.stringify(session.body)}`)

  return { id: created.body.id, email, token: session.body.access_token }
}

/** Borra los contadores de rate limit (cooldown de 30 s entre chismes) */
export async function resetRateLimit(user: TestUser) {
  await rest(`rate_limits?user_id=eq.${user.id}`, { method: 'DELETE' })
}

export function gossipBody(overrides: Record<string, unknown> = {}) {
  return {
    subject: 'Boda en el barrio',
    content: 'Dicen que se casan el sábado en la iglesia del parque',
    ...CITY,
    published_as: 'profile',
    idempotency_key: crypto.randomUUID(),
    ...overrides,
  }
}

/** Publica un chisme (resetea antes el rate limit del autor) */
export async function createGossip(user: TestUser, overrides: Record<string, unknown> = {}) {
  await resetRateLimit(user)
  return callFunction('moderate-gossip', { token: user.token, body: gossipBody(overrides) })
}

/** Objetos de un bucket bajo un prefijo (service_role) */
export async function listObjects(bucket: string, prefix: string): Promise<string[]> {
  const result = await http(`/storage/v1/object/list/${bucket}`, {
    method: 'POST',
    headers: serviceHeaders,
    body: { prefix, limit: 100 },
  })
  if (result.status !== 200) throw new Error(`list ${bucket}: ${result.status} ${JSON.stringify(result.body)}`)
  return (result.body as Array<{ name: string }>).map((o) => o.name)
}

export async function objectExists(bucket: string, path: string): Promise<boolean> {
  const slash = path.lastIndexOf('/')
  const names = await listObjects(bucket, path.slice(0, slash))
  return names.includes(path.slice(slash + 1))
}

/** Último body que recibió el OpenAI falso */
export async function lastOpenAIRequest() {
  const response = await fetch(`${FAKE_OPENAI}/__last`)
  return (await response.json()).body
}

// deno-lint-ignore no-explicit-any
export type Row = Record<string, any>

/** Entrada de la cola de un chisme (o null) */
export async function queueEntry(gossipId: string): Promise<Row | null> {
  const result = await rest(`moderation_queue?gossip_id=eq.${gossipId}&select=*`)
  return (result.body as Row[])[0] ?? null
}

/** Fila real del chisme en la tabla (service_role) */
export async function gossipRow(gossipId: string): Promise<Row | null> {
  const result = await rest(`gossips?id=eq.${gossipId}&select=*`)
  return (result.body as Row[])[0] ?? null
}
