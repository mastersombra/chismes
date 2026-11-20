/**
 * Tests de moderation.ts (sin red: OpenAI simulado con un fetch falso)
 *
 * Correr:
 *   deno test supabase/functions/moderate-gossip/moderation.test.ts
 * Sin Deno instalado (Docker):
 *   docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
 *     test moderate-gossip/moderation.test.ts
 */
import {
  assert,
  assertEquals,
} from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  moderateContent,
  OPENAI_MODERATION_MODEL,
  OPENAI_MODERATION_URL,
  type ModerationDeps,
} from './moderation.ts'

const IMAGE = 'data:image/jpeg;base64,/9j/4AAQSkZJRg=='
const CLEAN = { subject: 'Boda en el barrio', content: 'Dicen que se casan el sábado' }

interface Captured {
  url?: string
  body?: Record<string, unknown>
  headers?: Record<string, string>
}

function openai(
  result: Record<string, unknown> | null,
  opts: { status?: number; captured?: Captured } = {}
): ModerationDeps {
  return {
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
  const r = await moderateContent(CLEAN, { openaiKey: null })
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
    openaiKey: 'sk-test',
    fetchFn: (() => Promise.reject(new TypeError('network'))) as typeof fetch,
  })
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['moderation_unavailable'])
})

Deno.test('fail-closed: timeout → review', async () => {
  const r = await moderateContent(CLEAN, {
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
  const r = await moderateContent({ subject: 'x', content: 'los vamos a golpear' }, { openaiKey: null })
  assertEquals(r.verdict, 'reject')
})

// ---------- Fase 3 y 4: review ----------

Deno.test('teléfono, link y grosería: review con cada razón', async () => {
  const r = await moderateContent(
    { subject: 'Malparido', content: 'llámalo al 300 123 4567 o mira www.x.co' },
    openai(clean)
  )
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['potential_personal_data', 'potential_spam', 'potential_profanity'])
})

Deno.test('con audio: review aunque el texto esté limpio', async () => {
  const r = await moderateContent({ ...CLEAN, hasAudio: true }, openai(clean))
  assertEquals(r.verdict, 'review')
  assertEquals(r.reasons, ['audio_not_moderated'])
})
