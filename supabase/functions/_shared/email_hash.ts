/**
 * Huella del email para el registro anónimo de faltas (account_deletion_records).
 * La usan delete-account (al guardar) y las funciones que detectan
 * reincidentes (_shared/sanctions.ts). Secret: ACCOUNT_HASH_SECRET.
 */

/** Email normalizado para la huella: sin espacios y en minúsculas */
export function normalizeEmail(email: string | null | undefined): string | null {
  const normalized = (email ?? '').trim().toLowerCase()
  return normalized.length > 0 ? normalized : null
}

/**
 * Huella HMAC-SHA256 (hex) del email normalizado, o null si no hay email.
 * Con HMAC (y no SHA-256 solo) nadie sin el secret puede probar emails
 * conocidos contra la tabla.
 */
export async function emailHash(
  email: string | null | undefined,
  secret: string,
): Promise<string | null> {
  const normalized = normalizeEmail(email)
  if (!normalized) return null
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(normalized))
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
