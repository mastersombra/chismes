/**
 * Validación de imágenes subidas por clientes (sin librerías nativas).
 * Compartido por moderate-gossip (chismes) y update-profile (foto de perfil).
 */

export const ALLOWED_IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const
export type ImageMimeType = (typeof ALLOWED_IMAGE_MIME_TYPES)[number]

/**
 * MIME real por los primeros bytes (magic bytes).
 * Security: NO confiar en la extensión ni el Content-Type del cliente.
 * Lanza si no es JPEG, PNG ni WebP.
 */
export function detectImageMimeType(data: Uint8Array): ImageMimeType {
  // JPEG: FF D8 FF
  if (data[0] === 0xFF && data[1] === 0xD8 && data[2] === 0xFF) {
    return 'image/jpeg'
  }

  // PNG: 89 50 4E 47
  if (data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4E && data[3] === 0x47) {
    return 'image/png'
  }

  // WebP: 52 49 46 46 ... 57 45 42 50
  if (data[0] === 0x52 && data[1] === 0x49 && data[2] === 0x46 && data[3] === 0x46 &&
      data[8] === 0x57 && data[9] === 0x45 && data[10] === 0x42 && data[11] === 0x50) {
    return 'image/webp'
  }

  throw new Error('Unsupported or invalid image format (not JPEG, PNG, or WebP)')
}

/** Extensión de archivo para el MIME ya validado */
export function imageExtension(mimeType: ImageMimeType): string {
  return mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg'
}

/** Decodifica base64 → bytes. Lanza si el base64 es inválido */
export function decodeBase64(base64: string): Uint8Array {
  return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0))
}
