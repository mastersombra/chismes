/**
 * Media de chismes: cuarentena (privada) → buckets públicos
 *
 * Compartido por moderate-gossip (publicación inmediata) y moderation-review
 * (aprobación de un moderador). Buckets:
 * - images-quarantine (privado) → images (público): full + thumb
 * - audio-quarantine (privado) → audio (público)
 *
 * Los borrados nunca lanzan: se loguean (son limpieza/rollback).
 */

export interface PublicImageResult {
  fullUrl: string
  thumbnailUrl: string
  storagePath: string
  thumbnailStoragePath: string
}

export interface PublicAudioResult {
  audioUrl: string
  storagePath: string
}

export interface MoveOptions {
  /**
   * Borrar el original de la cuarentena tras copiarlo (default true).
   * moderation-review usa false y lo borra después de confirmar la decisión
   * en la base: si esa confirmación falla, el original sigue ahí para reintentar.
   */
  deleteQuarantine?: boolean
}

/**
 * PASO 2: Mover de cuarentena a público
 *
 * Copia archivo de cuarentena a bucket público
 * Crea thumbnail (por ahora, copia misma imagen)
 * Elimina de cuarentena
 *
 * Security:
 * - ✅ Solo se ejecuta después de aprobar moderación
 * - ✅ Transaccional: elimina de cuarentena solo si copia exitosa
 */
export async function moveToPublicBucket(
  quarantinePath: string,
  gossipId: string,
  supabaseClient: any,
  options: MoveOptions = {}
): Promise<PublicImageResult> {
  try {
    // 1. Descargar de cuarentena
    const { data: imageData, error: downloadError } = await supabaseClient.storage
      .from('images-quarantine')
      .download(quarantinePath)

    if (downloadError || !imageData) {
      throw new Error(`Failed to download from quarantine: ${downloadError?.message}`)
    }

    // 2. Paths en bucket público
    const timestamp = Date.now()
    const extension = quarantinePath.split('.').pop()
    const fileName = `${gossipId}_${timestamp}.${extension}`
    const fullPath = `gossips/full/${fileName}`
    const thumbPath = `gossips/thumb/${fileName}`

    // 3. Convertir Blob a Uint8Array
    const arrayBuffer = await imageData.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)

    // 4. Subir a bucket público (full)
    const { error: fullError } = await supabaseClient.storage
      .from('images')
      .upload(fullPath, uint8Array, {
        contentType: imageData.type,
        cacheControl: '3600',
        upsert: false
      })

    if (fullError) {
      throw new Error(`Failed to upload full image: ${fullError.message}`)
    }

    console.log(`✅ Full image uploaded to public: ${fullPath}`)

    // 5. Subir thumbnail (por ahora, misma imagen)
    // TODO: Implementar generación real de thumbnail
    const { error: thumbError } = await supabaseClient.storage
      .from('images')
      .upload(thumbPath, uint8Array, {
        contentType: imageData.type,
        cacheControl: '3600',
        upsert: false
      })

    if (thumbError) {
      // Rollback: eliminar full
      await supabaseClient.storage.from('images').remove([fullPath])
      throw new Error(`Failed to upload thumbnail: ${thumbError.message}`)
    }

    console.log(`✅ Thumbnail uploaded to public: ${thumbPath}`)

    // 6. Eliminar de cuarentena (cleanup)
    if (options.deleteQuarantine ?? true) {
      await deleteFromQuarantine(quarantinePath, supabaseClient)
    }

    // 7. Generar URLs públicas
    const { data: { publicUrl: fullUrl } } = supabaseClient.storage
      .from('images')
      .getPublicUrl(fullPath)

    const { data: { publicUrl: thumbUrl } } = supabaseClient.storage
      .from('images')
      .getPublicUrl(thumbPath)

    return {
      fullUrl,
      thumbnailUrl: thumbUrl,
      storagePath: fullPath,
      thumbnailStoragePath: thumbPath
    }
  } catch (error) {
    console.error('❌ Move to public bucket failed:', error)
    throw error
  }
}

/**
 * Eliminar de cuarentena (cleanup)
 */
export async function deleteFromQuarantine(
  quarantinePath: string,
  supabaseClient: any
): Promise<void> {
  try {
    const { error } = await supabaseClient.storage
      .from('images-quarantine')
      .remove([quarantinePath])

    if (error) {
      console.error('⚠️ Failed to delete from quarantine:', error)
    } else {
      console.log(`♻️ Deleted from quarantine: ${quarantinePath}`)
    }
  } catch (error) {
    console.error('⚠️ Unexpected error deleting from quarantine:', error)
  }
}

/**
 * Eliminar de bucket público (rollback)
 */
export async function deleteFromPublicBucket(
  fullPath: string,
  thumbPath: string,
  supabaseClient: any
): Promise<void> {
  try {
    const pathsToDelete = [fullPath, thumbPath].filter(p => p)

    if (pathsToDelete.length === 0) return

    const { error } = await supabaseClient.storage
      .from('images')
      .remove(pathsToDelete)

    if (error) {
      console.error('⚠️ Failed to delete from public bucket:', error)
    } else {
      console.log(`♻️ Deleted from public bucket: ${pathsToDelete.join(', ')}`)
    }
  } catch (error) {
    console.error('⚠️ Unexpected error deleting from public bucket:', error)
  }
}

/**
 * PASO 2: Mover audio de cuarentena a público
 *
 * Copia archivo de cuarentena a bucket público
 * Elimina de cuarentena
 *
 * Security:
 * - ✅ Solo se ejecuta después de aprobar moderación
 * - ✅ Transaccional: elimina de cuarentena solo si copia exitosa
 */
export async function moveAudioToPublicBucket(
  quarantinePath: string,
  gossipId: string,
  supabaseClient: any,
  options: MoveOptions = {}
): Promise<PublicAudioResult> {
  try {
    // 1. Descargar de cuarentena
    const { data: audioData, error: downloadError } = await supabaseClient.storage
      .from('audio-quarantine')
      .download(quarantinePath)

    if (downloadError || !audioData) {
      throw new Error(`Failed to download audio from quarantine: ${downloadError?.message}`)
    }

    // 2. Path en bucket público
    const timestamp = Date.now()
    const extension = quarantinePath.split('.').pop()
    const fileName = `${gossipId}_${timestamp}.${extension}`
    const publicPath = `gossips/${fileName}`

    // 3. Convertir Blob a Uint8Array
    const arrayBuffer = await audioData.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)

    // 4. Subir a bucket público
    const { error: uploadError } = await supabaseClient.storage
      .from('audio')
      .upload(publicPath, uint8Array, {
        contentType: audioData.type,
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) {
      throw new Error(`Failed to upload audio to public: ${uploadError.message}`)
    }

    console.log(`✅ Audio uploaded to public: ${publicPath}`)

    // 5. Eliminar de cuarentena (cleanup)
    if (options.deleteQuarantine ?? true) {
      await deleteAudioFromQuarantine(quarantinePath, supabaseClient)
    }

    // 6. Generar URL pública
    const { data: { publicUrl } } = supabaseClient.storage
      .from('audio')
      .getPublicUrl(publicPath)

    return {
      audioUrl: publicUrl,
      storagePath: publicPath
    }
  } catch (error) {
    console.error('❌ Move audio to public bucket failed:', error)
    throw error
  }
}

/**
 * Eliminar audio de cuarentena (cleanup)
 */
export async function deleteAudioFromQuarantine(
  quarantinePath: string,
  supabaseClient: any
): Promise<void> {
  try {
    const { error } = await supabaseClient.storage
      .from('audio-quarantine')
      .remove([quarantinePath])

    if (error) {
      console.error('⚠️ Failed to delete audio from quarantine:', error)
    } else {
      console.log(`♻️ Deleted audio from quarantine: ${quarantinePath}`)
    }
  } catch (error) {
    console.error('⚠️ Unexpected error deleting audio from quarantine:', error)
  }
}

/**
 * Eliminar audio de bucket público (rollback)
 */
export async function deleteAudioFromPublicBucket(
  audioPath: string,
  supabaseClient: any
): Promise<void> {
  try {
    if (!audioPath) return

    const { error } = await supabaseClient.storage
      .from('audio')
      .remove([audioPath])

    if (error) {
      console.error('⚠️ Failed to delete audio from public bucket:', error)
    } else {
      console.log(`♻️ Deleted audio from public bucket: ${audioPath}`)
    }
  } catch (error) {
    console.error('⚠️ Unexpected error deleting audio from public bucket:', error)
  }
}
