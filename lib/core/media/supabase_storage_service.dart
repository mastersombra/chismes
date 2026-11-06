import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'image_compressor.dart';
import '../logging/logging.dart';

/// Servicio para subir archivos a Supabase Storage
///
/// **ESTRATEGIA 1: Subir DESPUÉS de crear gossip**
///
/// **Por qué:**
/// - Evita archivos huérfanos (imagen solo se sube si gossip existe)
/// - Simple de implementar
/// - No requiere cleanup
/// - No requiere transacciones
///
/// **Flujo:**
/// ```
/// 1. Crear gossip SIN imagen → DB
/// 2. Subir imagen con gossipId → Storage
/// 3. Actualizar gossip con URL → DB
/// ```
///
/// **Ventajas:**
/// - ✅ 0% archivos huérfanos
/// - ✅ Simple (30 min implementación)
/// - ✅ No requiere SQL complejo
///
/// **Desventaja:**
/// - ⚠️ Ligeramente más lento (CREATE + UPDATE)
///
/// Ver: audio_imagen.md sección "Estrategia 1"
@lazySingleton
class SupabaseStorageService {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  SupabaseStorageService(this._supabase, this._logger);

  /// Sube imagen DESPUÉS de crear gossip (evita huérfanos)
  ///
  /// **Parámetros:**
  /// - `gossipId`: ID del gossip ya creado
  /// - `imageFile`: Archivo original (cualquier tamaño)
  ///
  /// **Retorna:**
  /// - URL pública de la imagen en Supabase Storage
  ///
  /// **Lanza:**
  /// - `Exception` si falla compresión o upload
  ///
  /// **Ejemplo:**
  /// ```dart
  /// final gossip = await repository.create(input);
  /// final imageUrl = await storageService.uploadImageAfterGossipCreated(
  ///   gossipId: gossip.id,
  ///   imageFile: selectedImage,
  /// );
  /// ```
  Future<UploadResult> uploadImageAfterGossipCreated({
    required String gossipId,
    required File imageFile,
  }) async {
    // 1. Comprimir imagen
    final compressedFile = await ImageCompressor.compressGossipImage(imageFile);
    if (compressedFile == null) {
      throw Exception('Error al comprimir imagen');
    }

    // 2. Verificar tamaño
    final sizeKB = await ImageCompressor.getFileSizeInKB(compressedFile);
    if (sizeKB > 300) {
      throw Exception(
        'Imagen muy grande: ${sizeKB.toStringAsFixed(1)} KB. Máximo 300 KB',
      );
    }

    final originalSize = await ImageCompressor.getFileSizeInKB(imageFile);
    _logger.d('📸 Imagen comprimida', context: {
      'originalKB': originalSize,
      'compressedKB': sizeKB,
    });

    // 3. Nombre incluye gossipId (para identificar)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${gossipId}_$timestamp.jpg';

    // 4. Subir imagen completa
    final fullPath = 'gossips/full/$fileName';
    await _supabase.storage.from('images').upload(fullPath, compressedFile);

    // 5. Generar y subir thumbnail
    String? thumbPath;
    final thumbnailFile = await ImageCompressor.generateThumbnail(imageFile);
    if (thumbnailFile != null) {
      thumbPath = 'gossips/thumb/$fileName';
      await _supabase.storage.from('images').upload(thumbPath, thumbnailFile);
    }

    // 6. Obtener URLs públicas (CDN automático)
    final fullUrl = _supabase.storage.from('images').getPublicUrl(fullPath);

    final thumbUrl = thumbPath != null
        ? _supabase.storage.from('images').getPublicUrl(thumbPath)
        : fullUrl;

    return UploadResult(
      fullUrl: fullUrl,
      thumbnailUrl: thumbUrl,
      sizeKB: sizeKB,
      storagePath: fullPath,
    );
  }

  /// Elimina imagen de Storage
  ///
  /// **Uso:**
  /// - Cuando se borra un gossip
  /// - Cleanup de archivos
  Future<void> deleteImage(String storagePath) async {
    try {
      await _supabase.storage.from('images').remove([storagePath]);

      // Intentar borrar thumbnail también
      final thumbPath = storagePath.replaceFirst('full/', 'thumb/');
      await _supabase.storage.from('images').remove([thumbPath]);

      _logger.i('🗑️ Imagen eliminada: $storagePath');
    } catch (e) {
      _logger.w('⚠️ Error eliminando imagen', context: {'error': e.toString()});
      // No lanzar error, solo loggear
    }
  }
}

/// Resultado de subir una imagen
class UploadResult {
  final String fullUrl; // URL imagen completa (800x800)
  final String thumbnailUrl; // URL thumbnail (200x200)
  final double sizeKB; // Tamaño en KB
  final String storagePath; // Path en storage (para borrar)

  UploadResult({
    required this.fullUrl,
    required this.thumbnailUrl,
    required this.sizeKB,
    required this.storagePath,
  });
}
