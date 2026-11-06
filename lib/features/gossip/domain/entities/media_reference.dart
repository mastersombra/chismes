/// Referencia a un archivo multimedia (imagen o audio)
///
/// Representa un archivo almacenado en Supabase Storage con metadatos.
/// Permite rastrear información más allá de una simple URL.
class MediaReference {
  /// Ruta del archivo en Storage (ej: 'gossips/abc123/image.jpg')
  final String storagePath;

  /// URL de descarga pública
  final String downloadUrl;

  /// Tipo MIME del archivo (ej: 'image/jpeg', 'audio/mpeg')
  final String mimeType;

  /// Tamaño del archivo en bytes
  final int size;

  /// Indica si el archivo ha sido procesado (ej: compresión, optimización)
  final bool isProcessed;

  /// Indica si el archivo ha pasado moderación
  final bool isModerated;

  /// Indica si el archivo está disponible para descarga
  final bool isAvailable;

  const MediaReference({
    required this.storagePath,
    required this.downloadUrl,
    required this.mimeType,
    required this.size,
    this.isProcessed = false,
    this.isModerated = false,
    this.isAvailable = true,
  });

  /// Verifica si es una imagen
  bool get isImage => mimeType.startsWith('image/');

  /// Verifica si es audio
  bool get isAudio => mimeType.startsWith('audio/');

  /// Tamaño en formato legible (KB, MB)
  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Crea una copia con algunos campos modificados
  MediaReference copyWith({
    String? storagePath,
    String? downloadUrl,
    String? mimeType,
    int? size,
    bool? isProcessed,
    bool? isModerated,
    bool? isAvailable,
  }) {
    return MediaReference(
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      isProcessed: isProcessed ?? this.isProcessed,
      isModerated: isModerated ?? this.isModerated,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MediaReference &&
        other.storagePath == storagePath &&
        other.downloadUrl == downloadUrl &&
        other.mimeType == mimeType &&
        other.size == size &&
        other.isProcessed == isProcessed &&
        other.isModerated == isModerated &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return storagePath.hashCode ^
        downloadUrl.hashCode ^
        mimeType.hashCode ^
        size.hashCode ^
        isProcessed.hashCode ^
        isModerated.hashCode ^
        isAvailable.hashCode;
  }

  @override
  String toString() {
    return 'MediaReference(storagePath: $storagePath, downloadUrl: $downloadUrl, '
        'mimeType: $mimeType, size: $size, isProcessed: $isProcessed, '
        'isModerated: $isModerated, isAvailable: $isAvailable)';
  }
}
