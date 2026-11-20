/**
 * Moderación de chismes: texto + imagen (+ audio a revisión)
 *
 * Las reglas (términos, umbrales por categoría de la IA, reglas fijas on/off)
 * viven en la tabla `moderation_rules` (013_moderation.sql): se editan desde
 * el dashboard sin desplegar. index.ts las carga con loadModerationRules().
 *
 * Fases:
 * 1. Reglas locales con acción reject → reject sin llamar a la IA
 * 2. OpenAI omni-moderation-latest → texto e imagen en una sola llamada
 *    (la imagen se envía como data URL: nunca sale una URL de la cuarentena).
 *    Lo marcado (flagged) se rechaza siempre; los umbrales de la tabla solo
 *    endurecen (puntaje >= min_score → review o reject).
 * 3. Reglas locales con acción review → review
 * 4. Audio → review (todavía no se modera automáticamente)
 *
 * Fail-closed: sin veredicto de la IA (sin API key, error, timeout,
 * respuesta inválida) o sin reglas (no se pudo leer la tabla) el chisme NO se
 * publica: va a review. Una caída no puede dejar pasar contenido sin moderar.
 *
 * Separado de index.ts para poder probarlo sin red (`fetch` inyectable):
 * ver moderation.test.ts.
 */

// ============================================
// CONFIGURACIÓN
// ============================================

export const OPENAI_MODERATION_URL = 'https://api.openai.com/v1/moderations'
/**
 * Solo para el E2E local (`scripts/e2e.sh`): apunta a un OpenAI falso.
 * NO configurarlo en el proyecto remoto.
 */
export const OPENAI_MODERATION_URL_ENV = 'OPENAI_MODERATION_URL'
export const OPENAI_MODERATION_MODEL = 'omni-moderation-latest'
export const OPENAI_TIMEOUT_MS = 10_000

/** Razón cuando la IA no dio veredicto */
export const REASON_AI_UNAVAILABLE = 'moderation_unavailable'
/** Razón cuando no se pudieron leer las reglas de `moderation_rules` */
export const REASON_RULES_UNAVAILABLE = 'rules_unavailable'

/** Debe coincidir con el CHECK de `moderation_rules` (013_moderation.sql) */
export const AI_CATEGORIES = [
  'harassment', 'harassment/threatening', 'hate', 'hate/threatening',
  'illicit', 'illicit/violent', 'self-harm', 'self-harm/intent',
  'self-harm/instructions', 'sexual', 'sexual/minors', 'violence',
  'violence/graphic',
] as const

const BUILTIN_REASONS = {
  credible_threat: 'credible_threat',
  personal_data: 'potential_personal_data',
  spam: 'potential_spam',
} as const

export type RuleAction = 'review' | 'reject'
export type BuiltinRule = keyof typeof BUILTIN_REASONS

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

/** Reglas ya validadas (ver parseModerationRules) */
export interface ModerationRules {
  /** Términos ya normalizados (ver normalize) */
  terms: Array<{ term: string; action: RuleAction }>
  aiCategories: Array<{ category: string; action: RuleAction; minScore: number }>
  /** Regla fija ausente = apagada */
  builtins: Partial<Record<BuiltinRule, RuleAction>>
}

export interface ModerationDeps {
  /** null = no se pudieron cargar → fail-closed (review) */
  rules: ModerationRules | null
  openaiKey?: string | null
  /** Por defecto: env OPENAI_MODERATION_URL o la URL real de OpenAI */
  openaiUrl?: string
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
  deps: ModerationDeps
): Promise<ModerationResult> {
  const openaiKey = deps.openaiKey === undefined
    ? Deno.env.get('OPENAI_API_KEY')
    : deps.openaiKey
  const fetchFn = deps.fetchFn ?? fetch
  const timeoutMs = deps.timeoutMs ?? OPENAI_TIMEOUT_MS
  const openaiUrl = deps.openaiUrl ?? readEnv(OPENAI_MODERATION_URL_ENV) ?? OPENAI_MODERATION_URL
  if (openaiUrl !== OPENAI_MODERATION_URL) {
    console.warn(`⚠️ Using non-default moderation URL (${OPENAI_MODERATION_URL_ENV}): ${openaiUrl}`)
  }
  const rules = deps.rules

  const rawText = `${input.subject}\n${input.content}`
  const normalizedText = normalize(rawText)
  const reasons: string[] = []

  // FASE 1: Reglas locales que rechazan (sin gastar la llamada a la IA)
  let localReview: string[] = []
  if (!rules) {
    console.warn('⚠️ Moderation rules unavailable → review')
    reasons.push(REASON_RULES_UNAVAILABLE)
  } else {
    const local = evaluateLocalRules(rawText, normalizedText, rules)
    if (local.reject.length > 0) {
      console.log('🚨 Rejected by local rules:', local.reject)
      return { verdict: 'reject', reasons: local.reject, source: 'local_rules' }
    }
    localReview = local.review
  }

  // FASE 2: OpenAI (texto + imagen). Sin veredicto → review (fail-closed)
  let aiReview: string[] = []
  const ai = await callOpenAIModeration(rawText, input.imageDataUrl, openaiKey, openaiUrl, fetchFn, timeoutMs)

  if (ai.kind === 'unavailable') {
    console.warn(`⚠️ AI moderation unavailable (${ai.cause}) → review`)
    reasons.push(REASON_AI_UNAVAILABLE)
  } else {
    const flaggedCategories = ai.result.flagged
      ? Object.entries(ai.result.categories)
        .filter(([_, flagged]) => flagged)
        .map(([category]) => category)
      : []
    const scores = evaluateAIThresholds(ai.result.category_scores, rules)

    if (ai.result.flagged || scores.reject.length > 0) {
      const rejectReasons = ai.result.flagged ? flaggedCategories : scores.reject
      const inputTypes = Object.fromEntries(
        flaggedCategories.map((c) => [c, ai.result.category_applied_input_types?.[c] ?? []])
      )

      console.log('🤖 REJECTED BY OPENAI:', rejectReasons, inputTypes)

      return {
        verdict: 'reject',
        reasons: rejectReasons,
        source: 'openai',
        details: {
          openai_categories: ai.result.categories,
          openai_scores: ai.result.category_scores,
          openai_input_types: inputTypes,
        },
      }
    }

    aiReview = scores.review
    reasons.push(...aiReview)
    if (aiReview.length === 0) console.log('✅ APPROVED BY OPENAI')
  }

  // FASE 3: Reglas locales que mandan a revisión
  reasons.push(...localReview)

  // FASE 4: Audio sin moderación automática
  if (input.hasAudio) reasons.push('audio_not_moderated')

  if (reasons.length > 0) {
    console.log('⚠️ SENT TO REVIEW:', reasons)
    const source = aiReview.length === 0 ? 'local_rules' : localReview.length === 0 ? 'openai' : 'hybrid'
    return { verdict: 'review', reasons, source }
  }

  console.log('✅ APPROVED - Content is clean')
  return { verdict: 'publish', reasons: [], source: 'hybrid' }
}

/** El veredicto 'review' se debe a que faltó la IA o las reglas */
export function isMissingAutomaticVerdict(result: ModerationResult): boolean {
  return result.reasons.includes(REASON_AI_UNAVAILABLE) ||
    result.reasons.includes(REASON_RULES_UNAVAILABLE)
}

type AIOutcome =
  | { kind: 'ok'; result: OpenAIModerationResponse['results'][number] }
  | { kind: 'unavailable'; cause: string }

async function callOpenAIModeration(
  text: string,
  imageDataUrl: string | null | undefined,
  openaiKey: string | null | undefined,
  url: string,
  fetchFn: typeof fetch,
  timeoutMs: number
): Promise<AIOutcome> {
  if (!openaiKey) return { kind: 'unavailable', cause: 'no_api_key' }

  const inputs: Array<Record<string, unknown>> = [{ type: 'text', text }]
  if (imageDataUrl) {
    inputs.push({ type: 'image_url', image_url: { url: imageDataUrl } })
  }

  try {
    const response = await fetchFn(url, {
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

/** Lee una variable de entorno; undefined si no existe o no hay permiso */
function readEnv(name: string): string | undefined {
  try {
    return Deno.env.get(name) || undefined
  } catch {
    return undefined
  }
}

// ============================================
// NORMALIZACIÓN
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

// ============================================
// CARGA DE REGLAS (tabla moderation_rules)
// ============================================

type RowsQuery = () => PromiseLike<{ data: unknown; error: unknown }>

/**
 * Lee las reglas activas. null si la consulta falla o alguna fila no es
 * válida: el llamador modera en fail-closed (review).
 *
 * Uso: loadModerationRules(() => supabaseAdmin.from('moderation_rules')
 *        .select('kind, target, action, min_score').eq('enabled', true))
 */
export async function loadModerationRules(query: RowsQuery): Promise<ModerationRules | null> {
  try {
    const { data, error } = await query()
    if (error) {
      console.error('❌ Could not load moderation_rules:', error)
      return null
    }
    return parseModerationRules(data)
  } catch (error) {
    console.error('❌ Could not load moderation_rules:', error)
    return null
  }
}

/**
 * Valida las filas de `moderation_rules` (mismas reglas que sus CHECK).
 * Cualquier fila inválida invalida todo (null): mejor revisar todo a mano
 * que moderar con reglas a medias.
 */
export function parseModerationRules(rows: unknown): ModerationRules | null {
  if (!Array.isArray(rows)) return null

  const rules: ModerationRules = { terms: [], aiCategories: [], builtins: {} }

  for (const row of rows) {
    if (typeof row !== 'object' || row === null) return null
    const { kind, target, action, min_score } = row as Record<string, unknown>
    if (typeof target !== 'string' || (action !== 'review' && action !== 'reject')) {
      console.error('❌ Invalid moderation rule:', row)
      return null
    }

    if (kind === 'term') {
      const term = normalize(target)
      if (term.length === 0) {
        // p. ej. "!!": nunca puede coincidir; no invalida las demás
        console.warn('⚠️ Moderation term is empty after normalizing, ignored:', target)
        continue
      }
      rules.terms.push({ term, action })
    } else if (kind === 'ai_category') {
      // PostgREST puede devolver NUMERIC como texto
      const minScore = Number(min_score)
      if (
        !(AI_CATEGORIES as readonly string[]).includes(target) ||
        min_score === null || !Number.isFinite(minScore) || minScore <= 0 || minScore > 1
      ) {
        console.error('❌ Invalid moderation rule:', row)
        return null
      }
      rules.aiCategories.push({ category: target, action, minScore })
    } else if (kind === 'builtin' && target in BUILTIN_REASONS) {
      rules.builtins[target as BuiltinRule] = action
    } else {
      console.error('❌ Invalid moderation rule:', row)
      return null
    }
  }

  return rules
}

// ============================================
// EVALUACIÓN DE REGLAS
// ============================================

interface RuleMatches {
  reject: string[]
  review: string[]
}

function evaluateLocalRules(
  rawText: string,
  normalizedText: string,
  rules: ModerationRules
): RuleMatches {
  const matches: RuleMatches = { reject: [], review: [] }
  const add = (action: RuleAction, reason: string) => {
    if (!matches[action].includes(reason)) matches[action].push(reason)
  }

  const builtinChecks: Record<BuiltinRule, () => boolean> = {
    credible_threat: () => containsCredibleThreat(normalizedText),
    personal_data: () => containsPersonalData(rawText),
    spam: () => containsSpam(rawText, normalizedText),
  }
  for (const [name, check] of Object.entries(builtinChecks) as Array<[BuiltinRule, () => boolean]>) {
    const action = rules.builtins[name]
    if (action && check()) add(action, BUILTIN_REASONS[name])
  }

  // normalizedText solo tiene [a-z0-9] y espacios simples: comparar con
  // espacios alrededor = palabra/frase completa, sin regex
  const padded = ` ${normalizedText} `
  for (const { term, action } of rules.terms) {
    if (padded.includes(` ${term} `)) add(action, `term:${term}`)
  }

  // Si un término está en las dos listas, gana reject
  matches.review = matches.review.filter((r) => !matches.reject.includes(r))
  return matches
}

function evaluateAIThresholds(
  scores: Record<string, number> | undefined,
  rules: ModerationRules | null
): RuleMatches {
  const matches: RuleMatches = { reject: [], review: [] }
  if (!rules || !scores) return matches

  for (const { category, action, minScore } of rules.aiCategories) {
    const score = scores[category]
    const reason = `ai_score:${category}`
    if (typeof score === 'number' && score >= minScore && !matches[action].includes(reason)) {
      matches[action].push(reason)
    }
  }

  matches.review = matches.review.filter((r) => !matches.reject.includes(r))
  return matches
}

// ============================================
// REGLAS FIJAS (las regex no son editables a propósito: ver 013)
// ============================================

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

function containsCredibleThreat(text: string): boolean {
  return /\b(?:te|lo|la|los|las)\s+(?:voy|vamos)\s+a\s+(?:matar|golpear|atacar|violar)\b/.test(text)
}
