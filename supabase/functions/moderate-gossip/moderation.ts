/**
 * Moderación de chismes: texto + imagen (+ audio a revisión)
 *
 * Fases:
 * 1. Reglas locales rápidas → amenazas obvias: reject
 * 2. OpenAI omni-moderation-latest → texto e imagen en una sola llamada
 *    (la imagen se envía como data URL: nunca sale una URL de la cuarentena)
 * 3. Reglas complementarias → datos personales, spam, groserías: review
 * 4. Audio → review (todavía no se modera automáticamente)
 *
 * Fail-closed: sin veredicto de la IA (sin API key, error, timeout,
 * respuesta inválida) el chisme NO se publica: va a review. Una caída de
 * OpenAI no puede dejar pasar contenido sin moderar.
 *
 * Separado de index.ts para poder probarlo sin red (`fetch` inyectable):
 * ver moderation.test.ts.
 */

// ============================================
// CONFIGURACIÓN
// ============================================

export const OPENAI_MODERATION_URL = 'https://api.openai.com/v1/moderations'
export const OPENAI_MODERATION_MODEL = 'omni-moderation-latest'
export const OPENAI_TIMEOUT_MS = 10_000

const REVIEW_TERMS = new Set([
  'gonorrea',
  'hijueputa',
  'malparido',
  'marica',
  'perra',
  'puta',
])

// ============================================
// TIPOS
// ============================================

export interface ModerationInput {
  subject: string
  content: string
  /** Imagen como data URL (`data:image/jpeg;base64,...`), si el chisme tiene */
  imageDataUrl?: string | null
  /** El chisme trae audio (no se modera automáticamente: va a review) */
  hasAudio?: boolean
}

export interface ModerationDeps {
  openaiKey?: string | null
  fetchFn?: typeof fetch
  timeoutMs?: number
}

export interface ModerationResult {
  verdict: 'publish' | 'review' | 'reject'
  reasons: string[]
  source: 'local_rules' | 'openai' | 'hybrid'
  details?: {
    openai_categories?: Record<string, boolean>
    openai_scores?: Record<string, number>
    /** Por categoría marcada: si la marcó el texto, la imagen o ambos */
    openai_input_types?: Record<string, string[]>
  }
}

interface OpenAIModerationResponse {
  id: string
  model: string
  results: Array<{
    flagged: boolean
    categories: Record<string, boolean>
    category_scores: Record<string, number>
    category_applied_input_types?: Record<string, string[]>
  }>
}

// ============================================
// MODERACIÓN
// ============================================

export async function moderateContent(
  input: ModerationInput,
  deps: ModerationDeps = {}
): Promise<ModerationResult> {
  const openaiKey = deps.openaiKey === undefined
    ? Deno.env.get('OPENAI_API_KEY')
    : deps.openaiKey
  const fetchFn = deps.fetchFn ?? fetch
  const timeoutMs = deps.timeoutMs ?? OPENAI_TIMEOUT_MS

  const rawText = `${input.subject}\n${input.content}`
  const normalizedText = normalize(rawText)
  const reasons: string[] = []

  // FASE 1: Reglas rápidas
  if (containsCredibleThreat(normalizedText)) {
    console.log('🚨 THREAT DETECTED - Rejected by local rules')
    return { verdict: 'reject', reasons: ['credible_threat'], source: 'local_rules' }
  }

  // FASE 2: OpenAI (texto + imagen). Sin veredicto → review (fail-closed)
  const ai = await callOpenAIModeration(rawText, input.imageDataUrl, openaiKey, fetchFn, timeoutMs)

  if (ai.kind === 'unavailable') {
    console.warn(`⚠️ AI moderation unavailable (${ai.cause}) → review`)
    reasons.push('moderation_unavailable')
  } else if (ai.result.flagged) {
    const flaggedCategories = Object.entries(ai.result.categories)
      .filter(([_, flagged]) => flagged)
      .map(([category]) => category)
    const inputTypes = Object.fromEntries(
      flaggedCategories.map((c) => [c, ai.result.category_applied_input_types?.[c] ?? []])
    )

    console.log('🤖 FLAGGED BY OPENAI:', inputTypes)

    return {
      verdict: 'reject',
      reasons: flaggedCategories,
      source: 'openai',
      details: {
        openai_categories: ai.result.categories,
        openai_scores: ai.result.category_scores,
        openai_input_types: inputTypes,
      },
    }
  } else {
    console.log('✅ APPROVED BY OPENAI')
  }

  // FASE 3: Reglas complementarias
  if (containsPersonalData(rawText)) reasons.push('potential_personal_data')
  if (containsSpam(rawText, normalizedText)) reasons.push('potential_spam')
  if (containsReviewTerm(normalizedText)) reasons.push('potential_profanity')

  // FASE 4: Audio sin moderación automática
  if (input.hasAudio) reasons.push('audio_not_moderated')

  if (reasons.length > 0) {
    console.log('⚠️ SENT TO REVIEW:', reasons)
    return { verdict: 'review', reasons, source: 'local_rules' }
  }

  console.log('✅ APPROVED - Content is clean')
  return { verdict: 'publish', reasons: [], source: 'hybrid' }
}

type AIOutcome =
  | { kind: 'ok'; result: OpenAIModerationResponse['results'][number] }
  | { kind: 'unavailable'; cause: string }

async function callOpenAIModeration(
  text: string,
  imageDataUrl: string | null | undefined,
  openaiKey: string | null | undefined,
  fetchFn: typeof fetch,
  timeoutMs: number
): Promise<AIOutcome> {
  if (!openaiKey) return { kind: 'unavailable', cause: 'no_api_key' }

  const inputs: Array<Record<string, unknown>> = [{ type: 'text', text }]
  if (imageDataUrl) {
    inputs.push({ type: 'image_url', image_url: { url: imageDataUrl } })
  }

  try {
    const response = await fetchFn(OPENAI_MODERATION_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiKey}`,
      },
      body: JSON.stringify({ model: OPENAI_MODERATION_MODEL, input: inputs }),
      signal: AbortSignal.timeout(timeoutMs),
    })

    if (!response.ok) {
      return { kind: 'unavailable', cause: `http_${response.status}` }
    }

    const moderation = await response.json() as OpenAIModerationResponse
    const result = moderation?.results?.[0]
    if (!result || typeof result.flagged !== 'boolean' || typeof result.categories !== 'object') {
      return { kind: 'unavailable', cause: 'invalid_response' }
    }
    return { kind: 'ok', result }
  } catch (error) {
    const cause = error instanceof DOMException && error.name === 'TimeoutError'
      ? 'timeout'
      : 'network_error'
    console.error('❌ Error calling OpenAI API:', error)
    return { kind: 'unavailable', cause }
  }
}

// ============================================
// REGLAS LOCALES
// ============================================

export function normalize(text: string): string {
  const accents = 'áéíóúüñ'
  const replacements = 'aeiouun'
  let normalized = text.toLowerCase()

  for (let i = 0; i < accents.length; i++) {
    normalized = normalized.replaceAll(accents[i], replacements[i])
  }

  return normalized
    .replaceAll('0', 'o')
    .replaceAll('1', 'i')
    .replaceAll('3', 'e')
    .replaceAll('4', 'a')
    .replaceAll('5', 's')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function containsPersonalData(text: string): boolean {
  const hasEmail = /\b[\w.!#$%&'*+/=?^`{|}~-]+@[\w](?:[\w-]{0,61}[\w])?(?:\.[\w](?:[\w-]{0,61}[\w])?)+\b/.test(text)
  const hasPhone = /(?<!\d)(?:\+?57[\s.-]?)?3\d{2}[\s.-]?\d{3}[\s.-]?\d{4}(?!\d)/.test(text)
  return hasEmail || hasPhone
}

function containsSpam(rawText: string, normalizedText: string): boolean {
  const hasUrl = /\b(?:https?:\/\/|www\.)/i.test(rawText)
  const hasLongRepeated = /([a-z])\1{6,}/.test(normalizedText)
  return hasUrl || hasLongRepeated
}

function containsReviewTerm(normalizedText: string): boolean {
  return Array.from(REVIEW_TERMS).some(term => {
    const normalizedTerm = normalize(term)
    const pattern = new RegExp(`(?:^|\\s)${escapeRegex(normalizedTerm)}(?:\\s|$)`)
    return pattern.test(normalizedText)
  })
}

function containsCredibleThreat(text: string): boolean {
  return /\b(?:te|lo|la|los|las)\s+(?:voy|vamos)\s+a\s+(?:matar|golpear|atacar|violar)\b/.test(text)
}

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}
