import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Edge Function: Log de Errores Seguro
 *
 * Estrategia de seguridad:
 * 1. ✅ Autenticación obligatoria (auth.uid())
 * 2. ✅ Sanitización de datos sensibles (allowlist de context)
 * 3. ✅ Validación de nivel de log
 * 4. ✅ Rate limiting (max 50 logs/hora por usuario)
 * 5. ✅ Service role insert (bypasa RLS)
 *
 * Datos sensibles NUNCA incluidos:
 * - Texto completo de gossips
 * - URLs firmadas (signed URLs)
 * - Headers HTTP
 * - Tokens de auth
 * - Coordenadas GPS exactas
 * - Contraseñas
 *
 * Datos permitidos en context (allowlist):
 * - IDs (gossipId, userId, cityId, etc.)
 * - Nombres de operaciones (operation)
 * - Códigos de error (errorCode)
 * - Flags booleanos
 */

// ============================================
// CONFIGURACIÓN
// ============================================

const ALLOWED_LEVELS = ['debug', 'info', 'warning', 'error', 'fatal'] as const
type LogLevel = typeof ALLOWED_LEVELS[number]

const RATE_LIMIT = {
  MAX_LOGS_PER_HOUR: 50,
  MAX_LOGS_PER_DAY: 200,
}

// ✅ ALLOWLIST: Solo estos campos se permiten en context
const CONTEXT_ALLOWLIST = new Set([
  // IDs (solo UUIDs/códigos, no datos sensibles)
  'gossipId',
  'userId',
  'cityId',
  'regionId',
  'countryId',
  'commentId',
  'reportId',

  // Operaciones
  'operation',
  'action',
  'screen',
  'component',

  // Códigos de error
  'errorCode',
  'httpStatus',
  'statusCode',

  // Flags
  'isRetry',
  'isOffline',
  'isCached',

  // Contadores (sin datos sensibles)
  'attemptCount',
  'retryCount',

  // Tipos (enums)
  'moderationStatus',
  'gossipStatus',
  'visibility',
])

// ❌ DENYLIST: Estos campos NUNCA se permiten
const CONTEXT_DENYLIST = new Set([
  'password',
  'token',
  'accessToken',
  'refreshToken',
  'idToken',
  'apiKey',
  'secret',
  'latitude',
  'longitude',
  'coords',
  'coordinates',
  'location',
  'gps',
  'subject',
  'content',
  'text',
  'body',
  'message',
  'gossipText',
  'comment',
  'email',
  'phone',
  'phoneNumber',
  'address',
  'url',
  'signedUrl',
  'presignedUrl',
  'headers',
  'authorization',
  'cookie',
  'session',
])

// ============================================
// TIPOS
// ============================================

interface LogRequest {
  level: LogLevel
  message: string
  error_type?: string
  stack_trace?: string
  device_info?: {
    os?: string
    osVersion?: string
    device?: string
    appVersion?: string
    locale?: string
  }
  context?: Record<string, any>
}

// ============================================
// VALIDACIÓN
// ============================================

function validateLogRequest(body: any): LogRequest | { error: string } {
  if (typeof body !== 'object' || body === null) {
    return { error: 'Body must be a JSON object' }
  }

  // Validar level
  if (!body.level || !ALLOWED_LEVELS.includes(body.level)) {
    return { error: `Invalid level. Must be one of: ${ALLOWED_LEVELS.join(', ')}` }
  }

  // Validar message
  if (!body.message || typeof body.message !== 'string') {
    return { error: 'message is required and must be a string' }
  }

  // Limitar longitud de message
  if (body.message.length > 2000) {
    return { error: 'message too long (max 2000 characters)' }
  }

  return body as LogRequest
}

// ============================================
// SANITIZACIÓN
// ============================================

/**
 * Sanitiza el contexto para remover datos sensibles
 *
 * Estrategia:
 * 1. Verificar denylist (rechazar si hay match)
 * 2. Aplicar allowlist (solo pasar campos permitidos)
 * 3. Truncar strings largos
 */
function sanitizeContext(context: Record<string, any> | undefined): Record<string, any> | null {
  if (!context || typeof context !== 'object') {
    return null
  }

  const sanitized: Record<string, any> = {}

  for (const [key, value] of Object.entries(context)) {
    // ❌ DENYLIST: Rechazar campos prohibidos
    if (CONTEXT_DENYLIST.has(key)) {
      console.log(`🚫 Blocked sensitive field: ${key}`)
      continue
    }

    // ✅ ALLOWLIST: Solo pasar campos permitidos
    if (!CONTEXT_ALLOWLIST.has(key)) {
      console.log(`⚠️ Unknown context field (skipped): ${key}`)
      continue
    }

    // Sanitizar valor
    if (typeof value === 'string') {
      // Truncar strings largos
      sanitized[key] = value.substring(0, 200)
    } else if (typeof value === 'number' || typeof value === 'boolean') {
      sanitized[key] = value
    } else if (value === null) {
      sanitized[key] = null
    } else {
      // Tipos complejos (arrays, objetos): convertir a string truncado
      sanitized[key] = JSON.stringify(value).substring(0, 200)
    }
  }

  return Object.keys(sanitized).length > 0 ? sanitized : null
}

/**
 * Sanitiza device_info
 */
function sanitizeDeviceInfo(deviceInfo: any): Record<string, any> | null {
  if (!deviceInfo || typeof deviceInfo !== 'object') {
    return null
  }

  const allowed = ['os', 'osVersion', 'device', 'appVersion', 'locale']
  const sanitized: Record<string, any> = {}

  for (const key of allowed) {
    if (deviceInfo[key] && typeof deviceInfo[key] === 'string') {
      sanitized[key] = deviceInfo[key].substring(0, 100)
    }
  }

  return Object.keys(sanitized).length > 0 ? sanitized : null
}

// ============================================
// RATE LIMITING
// ============================================

async function checkRateLimit(
  supabaseClient: any,
  userId: string
): Promise<{ allowed: boolean; reason?: string }> {
  try {
    // Contar logs en última hora
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
    const { count: countHour, error: errorHour } = await supabaseClient
      .from('error_logs')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gte('created_at', oneHourAgo)

    if (errorHour) {
      console.error('Error checking rate limit (hour):', errorHour)
      // Fail open: permitir log si falla el check
      return { allowed: true }
    }

    if (countHour && countHour >= RATE_LIMIT.MAX_LOGS_PER_HOUR) {
      return { allowed: false, reason: 'Rate limit exceeded (hour)' }
    }

    // Contar logs en último día
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    const { count: countDay, error: errorDay } = await supabaseClient
      .from('error_logs')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .gte('created_at', oneDayAgo)

    if (errorDay) {
      console.error('Error checking rate limit (day):', errorDay)
      return { allowed: true }
    }

    if (countDay && countDay >= RATE_LIMIT.MAX_LOGS_PER_DAY) {
      return { allowed: false, reason: 'Rate limit exceeded (day)' }
    }

    return { allowed: true }
  } catch (error) {
    console.error('Unexpected error in rate limit:', error)
    // Fail open: permitir log si falla el check
    return { allowed: true }
  }
}

// ============================================
// HANDLER PRINCIPAL
// ============================================

serve(async (req) => {
  try {
    // 1. Verificar autenticación
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Cliente anon para verificar usuario
    const supabaseAnon = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabaseAnon.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Authentication required' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const userId = user.id

    // 2. Parsear y validar body
    const rawBody = await req.json()
    const validated = validateLogRequest(rawBody)

    if ('error' in validated) {
      return new Response(
        JSON.stringify({ error: validated.error }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const body = validated

    // 3. Cliente admin (service_role) para insert
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 4. Rate limiting
    const rateLimitCheck = await checkRateLimit(supabaseAdmin, userId)
    if (!rateLimitCheck.allowed) {
      console.log(`🚫 Rate limit exceeded for user ${userId}`)
      return new Response(
        JSON.stringify({
          error: 'Rate limit exceeded',
          message: rateLimitCheck.reason,
        }),
        { status: 429, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 5. Sanitizar datos
    const sanitizedContext = sanitizeContext(body.context)
    const sanitizedDeviceInfo = sanitizeDeviceInfo(body.device_info)

    // 6. Insertar log con service_role (bypasa RLS)
    const { error: insertError } = await supabaseAdmin.from('error_logs').insert({
      level: body.level,
      message: body.message,
      error_type: body.error_type || null,
      stack_trace: body.stack_trace || null,
      user_id: userId,
      device_info: sanitizedDeviceInfo,
      context: sanitizedContext,
    })

    if (insertError) {
      console.error('❌ Error inserting log:', insertError)
      throw insertError
    }

    console.log(`✅ Log persisted for user ${userId} (level: ${body.level})`)

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('❌ Error in log-error function:', error)

    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
