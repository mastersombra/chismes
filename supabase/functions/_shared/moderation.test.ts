/**
 * Tests de moderation.ts (sin red: OpenAI simulado con un fetch falso)
 *
 * Correr:
 *   deno test supabase/functions/_shared/moderation.test.ts
 * Sin Deno instalado (Docker):
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     test _shared/moderation.test.ts
 */
import {
  assert,
  assertEquals,
} from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  isMissingAutomaticVerdict,
  loadModerationRules,
  moderateContent,
  OPENAI_MODERATION_MODEL,
  OPENAI_MODERATION_URL,
  parseModerationRules,
  type ModerationDeps,
  type ModerationRules,
} from './moderation.ts'

// Mismas filas que el INSERT inicial de moderation_rules (013_moderation.sql)
const SEED_ROWS = [
  { kind: 'builtin', target: 'credible_threat', action: 'reject', min_score: null },
  { kind: 'builtin', target: 'personal_data', action: 'review', min_score: null },
  { kind: 'builtin', target: 'spam', action: 'review', min_score: null },
  ...['gonorrea', 'hijueputa', 'malparido', 'marica', 'perra', 'puta']
    .map((target) => ({ kind: 'term', target, action: 'review', min_score: null })),
]
const SEED_RULES = parseModerationRules(SEED_ROWS) as ModerationRules

function rulesWith(...rows: Array<Record<string, unknown>>): ModerationRules {
  const rules = parseModerationRules([...SEED_ROWS, ...rows])
  assert(rules, 'filas de prueba inválidas')
  return rules
}

const IMAGE = 'data:image/jpeg;base64,/9j/4AAQSkZJRg=='
const CLEAN = { subject: 'Boda en el barrio', content: 'Dicen que se casan el sábado' }

interface Captured {
  url?: string
  body?: Record<string, unknown>
  headers?: Record<string, string>
}

function openai(
  result: Record<string, unknown> | null,
  opts: { status?: number; captured?: Captured; rules?: ModerationRules | null } = {}
): ModerationDeps {
  return {
    rules: opts.rules === undefined ? SEED_RULES : opts.rules,
    openaiKey: 'sk-test',
    timeoutMs: 50,
    fetchFn: (async (url: string, init: RequestInit) => {
      if (opts.captured) {
        opts.captured.url = url
        opts.captured.body = JSON.parse(init.body as string)
        opts.captured.headers = init.headers as Record<string, string>
      }
      return new Response(JSON.stringify({ id: 'm', model: 'omni', results: result ? [result] : [] }), {
        status: opts.status ?? 200,
      })
    }) as typeof fetch,
  }
}

const clean = { flagged: false, categories: { sexual: false, violence: false }, category_scores: {} }

// ---------- Fase 1: reglas locales ----------

Deno.test('amenaza explícita: reject sin llamar a OpenAI', async () => {
  let called = false
  const deps: ModerationDeps = {
    rules: SEED_RULES,
    openaiKey: 'sk-test',
    fetchFn: (() => { called = true; throw new Error('no debería llamarse') }) as typeof fetch,
  }
  const r = await moderateContent({ subject: 'Ojo', content: 'te voy a matar' }, deps)
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['credible_threat'])
  assert(!called)
})

// ---------- Fase 2: OpenAI ----------

Deno.test('texto limpio: publish y usa omni-moderation-latest', async () => {
  const captured: Captured = {}
  const r = await moderateContent(CLEAN, openai(clean, { captured }))
  assertEquals(r.verdict, 'publish')
  assertEquals(captured.url, OPENAI_MODERATION_URL)
  assertEquals(captured.body?.model, OPENAI_MODERATION_MODEL)
  assertEquals(captured.headers?.Authorization, 'Bearer sk-test')
  assertEquals(captured.body?.input, [{ type: 'text', text: `${CLEAN.subject}\n${CLEAN.content}` }])
})

Deno.test('con imagen: texto e imagen van en la misma llamada', async () => {
  const captured: Captured = {}
  const r = await moderateContent({ ...CLEAN, imageDataUrl: IMAGE }, openai(clean, { captured }))
  assertEquals(r.verdict, 'publish')
  assertEquals(captured.body?.input, [
    { type: 'text', text: `${CLEAN.subject}\n${CLEAN.content}` },
    { type: 'image_url', image_url: { url: IMAGE } },
  ])
})

Deno.test('imagen inapropiada con texto inocente: reject e indica que fue la imagen', async () => {
  const r = await moderateContent(
    { ...CLEAN, imageDataUrl: IMAGE },
    openai({
      flagged: true,
      categories: { sexual: true, violence: false },
      category_scores: { sexual: 0.98, violence: 0.01 },
      category_applied_input_types: { sexual: ['image'], violence: [] },
    })
  )
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['sexual'])
  assertEquals(r.source, 'openai')
  assertEquals(r.details?.openai_input_types, { sexual: ['image'] })
})

Deno.test('texto marcado por OpenAI: reject', async () => {
  const r = await moderateContent(
    CLEAN,
    openai({ flagged: true, categories: { harassment: true }, category_scores: { harassment: 0.9 } })
  )
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['harassment'])
  assertEquals(r.details?.openai_input_types, { harassment: [] })
})

// ---------- Fail-closed ----------

Deno.test('fail-closed: sin API key → review', async () => {
  const r = await moderateContent(CLEAN, { rules: SEED_RULES, openaiKey: null })
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['moderation_unavailable'])
})

Deno.test('fail-closed: OpenAI responde error HTTP → review', async () => {
  const r = await moderateContent({ ...CLEAN, imageDataUrl: IMAGE }, openai(clean, { status: 500 }))
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['moderation_unavailable'])
})

Deno.test('fail-closed: respuesta sin resultados → review', async () => {
  const r = await moderateContent(CLEAN, openai(null))
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['moderation_unavailable'])
})

Deno.test('fail-closed: error de red → review', async () => {
  const r = await moderateContent(CLEAN, {
    rules: SEED_RULES,
    openaiKey: 'sk-test',
    fetchFn: (() => Promise.reject(new TypeError('network'))) as typeof fetch,
  })
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['moderation_unavailable'])
})

Deno.test('fail-closed: timeout → review', async () => {
  const r = await moderateContent(CLEAN, {
    rules: SEED_RULES,
    openaiKey: 'sk-test',
    timeoutMs: 20,
    fetchFn: ((_url: string, init: RequestInit) =>
      new Promise((_resolve, reject) => {
        init.signal?.addEventListener('abort', () => reject(init.signal?.reason))
      })) as typeof fetch,
  })
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['moderation_unavailable'])
})

Deno.test('fail-closed: una amenaza se rechaza aunque OpenAI no esté', async () => {
  const r = await moderateContent({ subject: 'x', content: 'los vamos a golpear' }, { rules: SEED_RULES, openaiKey: null })
  assertEquals(r.verdict, 'reject')
})

// ---------- Fase 3 y 4: review ----------

Deno.test('teléfono, link y grosería: review con cada razón', async () => {
  const r = await moderateContent(
    { subject: 'Malparido', content: 'llámalo al 300 123 4567 o mira www.x.co' },
    openai(clean)
  )
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['potential_personal_data', 'potential_spam', 'term:malparido'])
})

Deno.test('con audio: review aunque el texto esté limpio', async () => {
  const r = await moderateContent({ ...CLEAN, hasAudio: true }, openai(clean))
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['audio_not_moderated'])
})

// ---------- Reglas de la tabla moderation_rules ----------

const flaggedNone = (scores: Record<string, number>) => ({
  flagged: false,
  categories: Object.fromEntries(Object.keys(scores).map((k) => [k, false])),
  category_scores: scores,
})

Deno.test('reglas: las filas iniciales reproducen las reglas que tenía el código', () => {
  assertEquals(SEED_RULES.builtins, { credible_threat: 'reject', personal_data: 'review', spam: 'review' })
  assertEquals(SEED_RULES.terms.length, 6)
  assertEquals(SEED_RULES.aiCategories, [])
})

Deno.test('reglas: término con reject → reject sin llamar a OpenAI', async () => {
  let called = false
  const r = await moderateContent({ subject: 'Ojo', content: 'Ese man es un Narco' }, {
    rules: rulesWith({ kind: 'term', target: 'narco', action: 'reject', min_score: null }),
    openaiKey: 'sk-test',
    fetchFn: (() => { called = true; throw new Error('no debería llamarse') }) as typeof fetch,
  })
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['term:narco'])
  assertEquals(r.source, 'local_rules')
  assert(!called)
})

Deno.test('reglas: término normalizado (tildes, mayúsculas, leet) y frases', async () => {
  const rules = rulesWith({ kind: 'term', target: 'Lavado de Dólares', action: 'review', min_score: null })
  const r1 = await moderateContent({ subject: 'x', content: 'qué p3rr4' }, openai(clean, { rules }))
  assertEquals(r1.reasons, ['term:perra'])
  const r2 = await moderateContent({ subject: 'x', content: 'hace LAVADO de dolares!' }, openai(clean, { rules }))
  assertEquals(r2.reasons, ['term:lavado de dolares'])
})

Deno.test('reglas: un término no coincide dentro de otra palabra', async () => {
  const r = await moderateContent({ subject: 'Computadora', content: 'se le dañó la computadora' }, openai(clean))
  assertEquals(r.verdict, 'publish')
})

Deno.test('reglas: si un término está en review y en reject, gana reject', async () => {
  const rules = rulesWith({ kind: 'term', target: 'puta', action: 'reject', min_score: null })
  const r = await moderateContent({ subject: 'x', content: 'puta vida' }, openai(clean, { rules }))
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['term:puta'])
})

Deno.test('reglas: regla fija apagada (sin fila) ya no aplica', async () => {
  const rules = parseModerationRules(SEED_ROWS.filter((r) => r.target !== 'spam')) as ModerationRules
  const r = await moderateContent({ subject: 'x', content: 'mira www.x.co' }, openai(clean, { rules }))
  assertEquals(r.verdict, 'publish')
})

Deno.test('reglas: regla fija con acción cambiada a reject', async () => {
  const rules = parseModerationRules(
    SEED_ROWS.map((r) => r.target === 'spam' ? { ...r, action: 'reject' } : r)
  ) as ModerationRules
  const r = await moderateContent({ subject: 'x', content: 'mira www.x.co' }, openai(clean, { rules }))
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['potential_spam'])
})

Deno.test('umbral IA: puntaje >= min_score sin flagged → review', async () => {
  const rules = rulesWith({ kind: 'ai_category', target: 'harassment', action: 'review', min_score: 0.3 })
  const r = await moderateContent(CLEAN, openai(flaggedNone({ harassment: 0.45 }), { rules }))
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['ai_score:harassment'])
  assertEquals(r.source, 'openai')
})

Deno.test('umbral IA: por debajo de min_score → publish', async () => {
  const rules = rulesWith({ kind: 'ai_category', target: 'harassment', action: 'review', min_score: 0.3 })
  const r = await moderateContent(CLEAN, openai(flaggedNone({ harassment: 0.29 }), { rules }))
  assertEquals(r.verdict, 'publish')
})

Deno.test('umbral IA: review y reject en la misma categoría, gana el que alcanza (reject)', async () => {
  const rules = rulesWith(
    { kind: 'ai_category', target: 'harassment', action: 'review', min_score: 0.3 },
    // NUMERIC puede llegar como texto desde PostgREST
    { kind: 'ai_category', target: 'harassment', action: 'reject', min_score: '0.7' },
  )
  const review = await moderateContent(CLEAN, openai(flaggedNone({ harassment: 0.5 }), { rules }))
  assertEquals(review.reasons, ['ai_score:harassment'])
  assertEquals(review.verdict, 'review')
  const reject = await moderateContent(CLEAN, openai(flaggedNone({ harassment: 0.8 }), { rules }))
  assertEquals(reject.verdict, 'reject')
  assertEquals(reject.reasons, ['ai_score:harassment'])
  assertEquals(reject.source, 'openai')
})

Deno.test('umbral IA: lo marcado (flagged) se rechaza aunque no haya umbrales', async () => {
  const r = await moderateContent(
    CLEAN,
    openai({ flagged: true, categories: { hate: true }, category_scores: { hate: 0.6 } }, { rules: SEED_RULES })
  )
  assertEquals(r.verdict, 'reject')
  assertEquals(r.reasons, ['hate'])
})

Deno.test('umbral IA + regla local review: source hybrid y ambas razones', async () => {
  const rules = rulesWith({ kind: 'ai_category', target: 'violence', action: 'review', min_score: 0.2 })
  const r = await moderateContent(
    { subject: 'x', content: 'escríbele a chismoso@correo.com' },
    openai(flaggedNone({ violence: 0.25 }), { rules })
  )
  assertEquals(r.reasons, ['ai_score:violence', 'potential_personal_data'])
  assertEquals(r.source, 'hybrid')
})

// ---------- Fail-closed de reglas ----------

Deno.test('fail-closed: sin reglas → review aunque OpenAI apruebe', async () => {
  const r = await moderateContent(CLEAN, openai(clean, { rules: null }))
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['rules_unavailable'])
  assert(isMissingAutomaticVerdict(r))
})

Deno.test('fail-closed: sin reglas, OpenAI sigue rechazando lo marcado', async () => {
  const r = await moderateContent(
    CLEAN,
    openai({ flagged: true, categories: { violence: true }, category_scores: { violence: 0.9 } }, { rules: null })
  )
  assertEquals(r.verdict, 'reject')
})

Deno.test('fail-closed: sin reglas ni IA → review con ambas razones', async () => {
  const r = await moderateContent(CLEAN, { rules: null, openaiKey: null })
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['rules_unavailable', 'moderation_unavailable'])
})

Deno.test('isMissingAutomaticVerdict: falso si la revisión es por contenido', async () => {
  const r = await moderateContent({ subject: 'x', content: 'mira www.x.co' }, openai(clean))
  assertEquals(r.verdict, 'review')
  assert(!isMissingAutomaticVerdict(r))
})

Deno.test('parseModerationRules: cualquier fila inválida → null', () => {
  const invalid: unknown[] = [
    'no es arreglo',
    [{ kind: 'regex', target: '.*', action: 'review', min_score: null }],
    [{ kind: 'term', target: 'x', action: 'publish', min_score: null }],
    [{ kind: 'builtin', target: 'otra', action: 'review', min_score: null }],
    [{ kind: 'ai_category', target: 'acoso', action: 'review', min_score: 0.5 }],
    [{ kind: 'ai_category', target: 'hate', action: 'review', min_score: null }],
    [{ kind: 'ai_category', target: 'hate', action: 'review', min_score: 0 }],
    [{ kind: 'ai_category', target: 'hate', action: 'review', min_score: 1.5 }],
    [{ kind: 'ai_category', target: 'hate', action: 'review', min_score: 'abc' }],
    [null],
  ]
  for (const rows of invalid) assertEquals(parseModerationRules(rows), null, JSON.stringify(rows))
})

Deno.test('parseModerationRules: término vacío al normalizar se ignora sin invalidar las demás', () => {
  const rules = parseModerationRules([
    { kind: 'term', target: '!!', action: 'review', min_score: null },
    { kind: 'term', target: 'Chismoso', action: 'review', min_score: null },
  ])
  assertEquals(rules?.terms, [{ term: 'chismoso', action: 'review' }])
})

Deno.test('loadModerationRules: error o excepción de la consulta → null', async () => {
  assertEquals(await loadModerationRules(() => Promise.resolve({ data: null, error: { message: 'x' } })), null)
  assertEquals(await loadModerationRules(() => Promise.reject(new Error('red'))), null)
  const ok = await loadModerationRules(() => Promise.resolve({ data: SEED_ROWS, error: null }))
  assertEquals(ok, SEED_RULES)
})

Deno.test('openaiUrl: se puede apuntar a otro servidor (solo E2E local)', async () => {
  const captured: Captured = {}
  const deps = { ...openai(clean, { captured }), openaiUrl: 'http://fake:1/v1/moderations' }
  const r = await moderateContent(CLEAN, deps)
  assertEquals(r.verdict, 'publish')
  assertEquals(captured.url, 'http://fake:1/v1/moderations')
})
