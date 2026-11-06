/**
 * Validación de contrato para CreateGossipRequest
 *
 * Fix P1-02: Validar contrato completo ANTES de rate limit y moderación
 *
 * Valida:
 * - Tipos correctos (string, no null/undefined)
 * - Límites de longitud (subject: 200, content: 1000)
 * - UUID v4 válido (idempotency_key)
 * - Enum válido (published_as)
 * - Texto no vacío después de trim
 * - Body size razonable
 */

// ============================================
// CONSTANTES DE VALIDACIÓN
// ============================================

export const VALIDATION_LIMITS = {
  SUBJECT_MAX_LENGTH: 200,
  CONTENT_MAX_LENGTH: 1000,
  AUDIO_BASE64_MAX_LENGTH: 15 * 1024 * 1024, // 15 MB en base64 (~11 MB original)
  IMAGE_BASE64_MAX_LENGTH: 10 * 1024 * 1024, // 10 MB en base64 (~7.5 MB original)
  IDEMPOTENCY_KEY_LENGTH: 36, // UUID v4
}

export const ALLOWED_PUBLISHED_AS = ['anonymous', 'profile'] as const

// ============================================
// TIPOS DE ERROR DE VALIDACIÓN
// ============================================

export interface ValidationError {
  field: string
  message: string
  code: string
}

export class RequestValidationError extends Error {
  errors: ValidationError[]

  constructor(errors: ValidationError[]) {
    super('Request validation failed')
    this.errors = errors
    this.name = 'RequestValidationError'
  }
}

// ============================================
// VALIDADORES INDIVIDUALES
// ============================================

/**
 * Valida que un campo sea un string no vacío después de trim
 */
function validateRequiredString(
  value: any,
  fieldName: string,
  maxLength: number
): ValidationError | null {
  // Tipo correcto
  if (typeof value !== 'string') {
    return {
      field: fieldName,
      message: `${fieldName} must be a string`,
      code: 'INVALID_TYPE',
    }
  }

  // No vacío después de trim
  const trimmed = value.trim()
  if (trimmed.length === 0) {
    return {
      field: fieldName,
      message: `${fieldName} cannot be empty`,
      code: 'EMPTY_STRING',
    }
  }

  // Límite máximo
  if (trimmed.length > maxLength) {
    return {
      field: fieldName,
      message: `${fieldName} exceeds maximum length of ${maxLength} characters (got ${trimmed.length})`,
      code: 'MAX_LENGTH_EXCEEDED',
    }
  }

  return null
}

/**
 * Valida que un campo sea un string opcional
 */
function validateOptionalString(
  value: any,
  fieldName: string,
  maxLength: number
): ValidationError | null {
  // Permitir null/undefined
  if (value === null || value === undefined) {
    return null
  }

  // Si está presente, debe ser string válido
  return validateRequiredString(value, fieldName, maxLength)
}

/**
 * Valida que un UUID sea v4 válido
 */
function validateUUID(value: any, fieldName: string): ValidationError | null {
  if (typeof value !== 'string') {
    return {
      field: fieldName,
      message: `${fieldName} must be a string`,
      code: 'INVALID_TYPE',
    }
  }

  // UUID v4 regex: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  // y puede ser 8, 9, a, o b
  const uuidV4Regex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

  if (!uuidV4Regex.test(value)) {
    return {
      field: fieldName,
      message: `${fieldName} must be a valid UUID v4`,
      code: 'INVALID_UUID',
    }
  }

  return null
}

/**
 * Valida enum de published_as
 */
function validatePublishedAs(value: any): ValidationError | null {
  if (typeof value !== 'string') {
    return {
      field: 'published_as',
      message: 'published_as must be a string',
      code: 'INVALID_TYPE',
    }
  }

  if (!ALLOWED_PUBLISHED_AS.includes(value as any)) {
    return {
      field: 'published_as',
      message: `published_as must be one of: ${ALLOWED_PUBLISHED_AS.join(', ')}`,
      code: 'INVALID_ENUM',
    }
  }

  return null
}

/**
 * Valida base64 de imagen
 */
function validateImageBase64(value: any): ValidationError | null {
  // Permitir null/undefined
  if (value === null || value === undefined) {
    return null
  }

  if (typeof value !== 'string') {
    return {
      field: 'image_base64',
      message: 'image_base64 must be a string',
      code: 'INVALID_TYPE',
    }
  }

  // Verificar que no sea vacío
  if (value.trim().length === 0) {
    return {
      field: 'image_base64',
      message: 'image_base64 cannot be empty if provided',
      code: 'EMPTY_STRING',
    }
  }

  // Verificar límite de tamaño
  if (value.length > VALIDATION_LIMITS.IMAGE_BASE64_MAX_LENGTH) {
    return {
      field: 'image_base64',
      message: `image_base64 exceeds maximum size of ${VALIDATION_LIMITS.IMAGE_BASE64_MAX_LENGTH} bytes`,
      code: 'MAX_SIZE_EXCEEDED',
    }
  }

  // Validar que sea base64 válido (alfabeto base64)
  const base64Regex = /^[A-Za-z0-9+/]*={0,2}$/
  if (!base64Regex.test(value)) {
    return {
      field: 'image_base64',
      message: 'image_base64 must be valid base64 encoded data',
      code: 'INVALID_BASE64',
    }
  }

  return null
}

/**
 * Valida base64 de audio
 */
function validateAudioBase64(value: any): ValidationError | null {
  // Permitir null/undefined
  if (value === null || value === undefined) {
    return null
  }

  if (typeof value !== 'string') {
    return {
      field: 'audio_base64',
      message: 'audio_base64 must be a string',
      code: 'INVALID_TYPE',
    }
  }

  // Verificar que no sea vacío
  if (value.trim().length === 0) {
    return {
      field: 'audio_base64',
      message: 'audio_base64 cannot be empty if provided',
      code: 'EMPTY_STRING',
    }
  }

  // Verificar límite de tamaño
  if (value.length > VALIDATION_LIMITS.AUDIO_BASE64_MAX_LENGTH) {
    return {
      field: 'audio_base64',
      message: `audio_base64 exceeds maximum size of ${VALIDATION_LIMITS.AUDIO_BASE64_MAX_LENGTH} bytes`,
      code: 'MAX_SIZE_EXCEEDED',
    }
  }

  // Validar que sea base64 válido (alfabeto base64)
  const base64Regex = /^[A-Za-z0-9+/]*={0,2}$/
  if (!base64Regex.test(value)) {
    return {
      field: 'audio_base64',
      message: 'audio_base64 must be valid base64 encoded data',
      code: 'INVALID_BASE64',
    }
  }

  return null
}

// ============================================
// VALIDADOR PRINCIPAL
// ============================================

export interface CreateGossipRequest {
  subject: string
  content: string
  country_id: string
  region_id: string
  city_id: string
  published_as: 'anonymous' | 'profile'
  audio_base64?: string | null
  image_base64?: string | null
  idempotency_key: string
}

/**
 * Valida el contrato completo de CreateGossipRequest
 *
 * IMPORTANTE: Llamar ANTES de rate limit y moderación para evitar
 * gastar recursos en requests inválidos
 *
 * @throws RequestValidationError si hay errores de validación
 */
export function validateCreateGossipRequest(body: any): CreateGossipRequest {
  const errors: ValidationError[] = []

  // Validar que body sea un objeto
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    throw new RequestValidationError([
      {
        field: 'body',
        message: 'Request body must be a JSON object',
        code: 'INVALID_BODY',
      },
    ])
  }

  // Validar campos requeridos
  const subjectError = validateRequiredString(
    body.subject,
    'subject',
    VALIDATION_LIMITS.SUBJECT_MAX_LENGTH
  )
  if (subjectError) errors.push(subjectError)

  const contentError = validateRequiredString(
    body.content,
    'content',
    VALIDATION_LIMITS.CONTENT_MAX_LENGTH
  )
  if (contentError) errors.push(contentError)

  const countryIdError = validateRequiredString(body.country_id, 'country_id', 100)
  if (countryIdError) errors.push(countryIdError)

  const regionIdError = validateRequiredString(body.region_id, 'region_id', 100)
  if (regionIdError) errors.push(regionIdError)

  const cityIdError = validateRequiredString(body.city_id, 'city_id', 100)
  if (cityIdError) errors.push(cityIdError)

  const publishedAsError = validatePublishedAs(body.published_as)
  if (publishedAsError) errors.push(publishedAsError)

  const idempotencyKeyError = validateUUID(body.idempotency_key, 'idempotency_key')
  if (idempotencyKeyError) errors.push(idempotencyKeyError)

  // Validar campos opcionales
  const audioBase64Error = validateAudioBase64(body.audio_base64)
  if (audioBase64Error) errors.push(audioBase64Error)

  const imageBase64Error = validateImageBase64(body.image_base64)
  if (imageBase64Error) errors.push(imageBase64Error)

  // Si hay errores, lanzar excepción
  if (errors.length > 0) {
    throw new RequestValidationError(errors)
  }

  // Retornar body tipado y validado
  // Normalizar: trim de strings
  return {
    subject: body.subject.trim(),
    content: body.content.trim(),
    country_id: body.country_id.trim(),
    region_id: body.region_id.trim(),
    city_id: body.city_id.trim(),
    published_as: body.published_as,
    audio_base64: body.audio_base64?.trim() || null,
    image_base64: body.image_base64?.trim() || null,
    idempotency_key: body.idempotency_key,
  }
}

// ============================================
// VALIDACIÓN DE UBICACIÓN
// ============================================

export interface LocationValidationResult {
  valid: boolean
  error?: string
}

/**
 * Valida que la jerarquía de ubicación sea correcta
 *
 * Verifica que:
 * 1. País existe
 * 2. Región pertenece al país
 * 3. Ciudad pertenece a la región
 *
 * @param countryId ID del país
 * @param regionId ID de la región
 * @param cityId ID de la ciudad
 * @param supabaseClient Cliente de Supabase con acceso a DB
 */
export async function validateLocationHierarchy(
  countryId: string,
  regionId: string,
  cityId: string,
  supabaseClient: any
): Promise<LocationValidationResult> {
  try {
    // Validar que la ciudad existe y pertenece a la jerarquía correcta
    const { data: city, error: cityError } = await supabaseClient
      .from('cities')
      .select('id, region_id')
      .eq('id', cityId)
      .maybeSingle()

    if (cityError) {
      console.error('❌ Location validation DB error:', cityError)
      return {
        valid: false,
        error: 'Failed to validate location',
      }
    }

    if (!city) {
      return {
        valid: false,
        error: 'City not found',
      }
    }

    // Verificar que la ciudad pertenece a la región especificada
    if (city.region_id !== regionId) {
      return {
        valid: false,
        error: 'City does not belong to the specified region',
      }
    }

    // Validar que la región existe y pertenece al país
    const { data: region, error: regionError } = await supabaseClient
      .from('regions')
      .select('id, country_id')
      .eq('id', regionId)
      .maybeSingle()

    if (regionError) {
      console.error('❌ Location validation DB error:', regionError)
      return {
        valid: false,
        error: 'Failed to validate location',
      }
    }

    if (!region) {
      return {
        valid: false,
        error: 'Region not found',
      }
    }

    // Verificar que la región pertenece al país especificado
    if (region.country_id !== countryId) {
      return {
        valid: false,
        error: 'Region does not belong to the specified country',
      }
    }

    // Validar que el país existe
    const { data: country, error: countryError } = await supabaseClient
      .from('countries')
      .select('id')
      .eq('id', countryId)
      .maybeSingle()

    if (countryError) {
      console.error('❌ Location validation DB error:', countryError)
      return {
        valid: false,
        error: 'Failed to validate location',
      }
    }

    if (!country) {
      return {
        valid: false,
        error: 'Country not found',
      }
    }

    // Todo válido
    return { valid: true }
  } catch (error) {
    console.error('❌ Unexpected error validating location:', error)
    return {
      valid: false,
      error: 'Unexpected error validating location',
    }
  }
}
