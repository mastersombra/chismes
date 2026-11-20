/**
 * OpenAI falso para el E2E (`scripts/e2e.sh`): imita POST /v1/moderations.
 *
 * El test decide la respuesta con marcadores en el texto del chisme:
 *   [[ai:down]]                 → HTTP 500 (fail-closed: el chisme va a revisión)
 *   [[ai:flag=<categoría>]]     → flagged por el texto
 *   [[ai:flag-image=<cat>]]     → flagged solo si viene imagen (input type 'image')
 *   [[ai:score=<cat>:<n>]]      → no flagged, con ese puntaje (umbrales de la tabla)
 *   sin marcador                → limpio
 *
 * GET /__last devuelve el último body recibido (para verificar que la imagen
 * llega como data URL y nunca como URL de la cuarentena).
 *
 * Exige `Authorization: Bearer sk-e2e-fake`.
 */

const PORT = Number(Deno.env.get('PORT') ?? 8000)
const API_KEY = 'sk-e2e-fake'

let lastBody: unknown = null

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve({ port: PORT, hostname: '0.0.0.0' }, async (req) => {
  const url = new URL(req.url)

  if (req.method === 'GET' && url.pathname === '/__health') return json({ ok: true })
  if (req.method === 'GET' && url.pathname === '/__last') return json({ body: lastBody })

  if (req.method !== 'POST' || url.pathname !== '/v1/moderations') {
    return json({ error: 'not found' }, 404)
  }
  if (req.headers.get('Authorization') !== `Bearer ${API_KEY}`) {
    return json({ error: { message: 'Incorrect API key' } }, 401)
  }

  const body = await req.json()
  lastBody = body

  const inputs: Array<Record<string, unknown>> = Array.isArray(body?.input) ? body.input : []
  const text = inputs
    .filter((i) => i.type === 'text')
    .map((i) => String(i.text ?? ''))
    .join('\n')
  const hasImage = inputs.some((i) => i.type === 'image_url')

  if (text.includes('[[ai:down]]')) return json({ error: { message: 'down' } }, 500)

  const categories: Record<string, boolean> = {}
  const scores: Record<string, number> = {}
  const inputTypes: Record<string, string[]> = {}

  for (const [, category] of text.matchAll(/\[\[ai:flag=([a-z/-]+)\]\]/g)) {
    categories[category] = true
    scores[category] = 0.99
    inputTypes[category] = ['text']
  }
  if (hasImage) {
    for (const [, category] of text.matchAll(/\[\[ai:flag-image=([a-z/-]+)\]\]/g)) {
      categories[category] = true
      scores[category] = 0.98
      inputTypes[category] = ['image']
    }
  }
  for (const [, category, score] of text.matchAll(/\[\[ai:score=([a-z/-]+):([0-9.]+)\]\]/g)) {
    categories[category] ??= false
    scores[category] = Number(score)
  }

  const flagged = Object.values(categories).some(Boolean)
  return json({
    id: `modr-e2e-${crypto.randomUUID()}`,
    model: body?.model ?? 'omni-moderation-latest',
    results: [{
      flagged,
      categories,
      category_scores: scores,
      category_applied_input_types: inputTypes,
    }],
  })
})

console.log(`fake OpenAI listening on :${PORT}`)
