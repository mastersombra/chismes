import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

/// Servicio para comprimir imágenes antes de subir a Supabase Storage
///
/// **Estrategia:**
/// - Comprimir a 800x800 px @ 75% calidad JPEG (~100-150 KB)
/// - Generar thumbnails 200x200 px @ 70% calidad (~30 KB)
/// - Usuario NO nota la compresión (se ve perfecta en móvil)
///
/// **Decisión:**
/// - NO usamos MediaReference (overkill para app simple)
/// - Usamos String simple (URL de Supabase Storage)
/// - Ver: audio_imagen.md sección "Opción B: String Simple"
class ImageCompressor {
  /// Comprime imagen para chisme (800x800 px, ~100-150 KB)
  ///
  /// **Uso:**
  /// - Usuario toma foto con cámara (cualquier calidad)
  /// - Flutter automáticamente comprime ANTES de subir
  /// - Usuario NO hace nada especial (invisible)
  ///
  /// **Ejemplo:**
  /// ```
  /// Foto original: 3024×4032 px, 3.5 MB
  ///       ↓ Flutter comprime automáticamente
  /// Foto comprimida: 800×1067 px, 120 KB
  ///       ↓ Se sube a Supabase
  /// Usuario ve: 800×1067 px (perfecta en móvil)
  /// ```
  static Future<File?> compressGossipImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf('.');
    final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 75, // 75% calidad (balance perfecto precio/calidad)
      minWidth: 800, // Máximo 800px ancho
      minHeight: 800, // Máximo 800px alto
      format: CompressFormat.jpeg, // JPEG comprime más que PNG
    );

    return result != null ? File(result.path) : null;
  }

  /// Genera thumbnail para lista (200x200 px, ~30 KB)
  ///
  /// **Uso:**
  /// - Se genera automáticamente al subir imagen
  /// - Se guarda en gossips/thumb/{filename}
  /// - Se usa en lista de chismes (más rápido)
  static Future<File?> generateThumbnail(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf('.');
    final outPath = '${filePath.substring(0, lastIndex)}_thumb.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 70,
      minWidth: 200,
      minHeight: 200,
      format: CompressFormat.jpeg,
    );

    return result != null ? File(result.path) : null;
  }

  /// Obtiene tamaño de archivo en KB
  static Future<double> getFileSizeInKB(File file) async {
    final int bytes = await file.length();
    return bytes / 1024;
  }
}
