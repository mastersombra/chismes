import '../../domain/entities/gossip.dart';

/// Model de datos para Gossip - Solo serialización/deserialización
///
/// **Propósito:** DTO (Data Transfer Object) para persistencia y transmisión
///
/// **Responsabilidades:**
/// - Serialización a JSON (toJson)
/// - Deserialización desde JSON (fromJson)
/// - Mapeo desde/hacia Entity (toEntity, fromEntity)
///
/// **Decisión de diseño:**
/// - NO debe contener reglas de negocio
/// - Solo es un contenedor de datos
/// - Toda la lógica de negocio está en Domain Layer (entities, validators, state machine)
///
/// **✅ BACKEND: SUPABASE**
///
/// Timestamps:
/// - Supabase usa TIMESTAMPTZ (PostgreSQL)
/// - Automáticamente serializa a String ISO8601
/// - String createdAt, modifiedAt, deletedAt (ISO8601)
/// - NO requiere conversión especial
///
/// **Conversión en toEntity():**
/// - String ISO8601 → DateTime (usando DateTime.parse())
///
/// **El dominio (Entity) debe mantenerse con DateTime:**
/// - Domain Layer usa DateTime (tipo nativo de Dart)
/// - Data Layer usa String ISO8601 (tipo nativo de Supabase/PostgreSQL)
/// - El Model hace la conversión entre ambos
///
/// **Media (imágenes/audio):**
/// - Se usa String simple (URL de Supabase Storage)
/// - NO se usa MediaReference (decisión: overkill para app simple)
/// - Ver: audio_imagen.md sección "Opción B: String Simple"
///
/// **Validación de tipos:**
/// - fromJson valida tipos de todos los campos
/// - Lanza FormatException si hay tipos incorrectos
/// - Esto previene datos corruptos o incompatibles
class GossipModel {
  /// ID único del chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Notas:**
  /// - En MVP: generado por TimestampIdGenerator (client-side)
  /// - En producción: generado por Supabase (uuid_generate_v4() server-side)
  final String id;

  /// ID del país donde ocurrió el chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Validación:** Campo requerido
  final String countryId;

  /// ID de la región donde ocurrió el chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Validación:** Campo requerido
  final String regionId;

  /// ID de la ciudad donde ocurrió el chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Validación:** Campo requerido
  final String cityId;

  /// Sobre quién o dónde es el chisme (título)
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Longitud máxima: 200 caracteres
  final String subject;

  /// Contenido del chisme (texto principal)
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Longitud máxima: 1000 caracteres
  final String content;

  /// URL del audio adjunto (opcional)
  ///
  /// **Tipo:** String? (URL pública de Supabase Storage)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:** Campo opcional
  ///
  /// **Backend:** Supabase Storage
  /// **Formato:** https://{project}.supabase.co/storage/v1/object/public/images/gossips/audio/{filename}.mp3
  /// **Compresión:** MP3 @ 64kbps, máx 30 segundos (~240 KB)
  /// **Decisión:** String simple es suficiente (no se usa MediaReference)
  /// Ver: audio_imagen.md sección "Opción B: String Simple"
  final String? audioUrl;

  /// URL de la imagen adjunta (opcional)
  ///
  /// **Tipo:** String? (URL pública de Supabase Storage)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:** Campo opcional
  ///
  /// **Backend:** Supabase Storage
  /// **Formato:** https://{project}.supabase.co/storage/v1/object/public/images/gossips/full/{filename}.jpg
  /// **Compresión:** 800x800 px @ 75% calidad JPEG (~100-150 KB)
  /// **Thumbnail:** Se genera aparte en gossips/thumb/{filename}.jpg (200x200 px, ~30 KB)
  /// **Decisión:** String simple es suficiente (no se usa MediaReference)
  /// Ver: audio_imagen.md sección "Opción B: String Simple"
  final String? imageUrl;

  /// URL del thumbnail de la imagen (opcional)
  ///
  /// **Tipo:** String? (URL pública de Supabase Storage)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:** Campo opcional
  ///
  /// **Backend:** Supabase Storage
  /// **Formato:** https://{project}.supabase.co/storage/v1/object/public/images/gossips/thumb/{filename}.jpg
  /// **Compresión:** 200x200 px @ 75% calidad JPEG (~30 KB)
  ///
  /// **Uso:** Debe usarse en feeds y listas para reducir transferencia.
  /// imageUrl se usa solo en vista de detalle del gossip.
  final String? thumbnailUrl;

  /// Path canónico en Storage (fuente de verdad para imagen)
  ///
  /// **Tipo:** String? (path en bucket de Supabase Storage)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:** Campo opcional
  ///
  /// **Formato:** images/gossips/full/{gossipId}_{timestamp}.jpg
  ///
  /// **Decisión:** storage_path es la fuente de verdad, imageUrl es derivado
  /// Las URLs pueden regenerarse desde storage_path si cambia el dominio
  /// Ver: docs/ANALYSIS_P1_01_MEDIA.md
  final String? storagePath;

  /// Path canónico del thumbnail en Storage
  ///
  /// **Tipo:** String? (path en bucket de Supabase Storage)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:** Campo opcional
  ///
  /// **Formato:** images/gossips/thumb/{gossipId}_{timestamp}.jpg
  final String? thumbnailStoragePath;

  /// Cómo el usuario eligió publicar (anónimo o con perfil)
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → PublishAs (enum)
  ///
  /// **Valores válidos:** 'anonymous', 'profile'
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Debe ser un valor válido de PublishAs enum
  final String publishedAs;

  /// Estado de visibilidad/acción del chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → GossipStatus (enum)
  ///
  /// **Valores válidos:** 'draft', 'published', 'hidden', 'deleted'
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Debe ser un valor válido de GossipStatus enum
  /// - Debe formar combinación válida con moderationStatus
  ///
  /// **⚠️ SEGURIDAD:** Solo backend puede cambiar este campo
  final String status;

  /// Estado de calidad/aprobación del contenido
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → ModerationStatus (enum)
  ///
  /// **Valores válidos:** 'pending', 'approved', 'rejected', 'flagged'
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Debe ser un valor válido de ModerationStatus enum
  /// - Debe formar combinación válida con status
  ///
  /// **⚠️ SEGURIDAD:** Solo backend puede cambiar este campo
  final String moderationStatus;

  /// Contador de cuántas veces este chisme ha sido reportado
  ///
  /// **Tipo:** int (para JSON/Supabase)
  /// **Mapeo a Entity:** int → int (sin conversión)
  ///
  /// **Validación:**
  /// - Campo opcional (default: 0)
  /// - Debe ser >= 0
  ///
  /// **⚠️ SEGURIDAD:** Solo backend puede cambiar este campo
  final int reportedCount;

  /// Contador de cuántas veces este chisme ha sido visto
  ///
  /// **Tipo:** int (para JSON/Supabase)
  /// **Mapeo a Entity:** int → int (sin conversión)
  ///
  /// **Validación:**
  /// - Campo opcional (default: 0)
  /// - Debe ser >= 0
  ///
  /// **⚠️ SEGURIDAD:** Solo backend puede cambiar este campo
  final int viewCount;

  /// Timestamp de cuándo fue eliminado el chisme (soft delete)
  ///
  /// **Tipo:** String? (ISO8601 desde Supabase TIMESTAMPTZ)
  /// **Mapeo a Entity:** String? → DateTime? (ISO8601 parse)
  ///
  /// **Validación:**
  /// - Campo opcional
  /// - Si presente, debe ser ISO8601 válido
  ///
  /// **Backend:** Supabase automáticamente convierte TIMESTAMPTZ → ISO8601 String
  /// No requiere conversión especial (DateTime.parse() funciona directo)
  final String? deletedAt;

  /// ID del usuario que eliminó el chisme
  ///
  /// **Tipo:** String? (para JSON/Supabase)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:**
  /// - Campo opcional
  /// - Requerido si deletedAt está presente
  final String? deletedBy;

  /// Quién puede ver el chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → GossipVisibility (enum)
  ///
  /// **Valores válidos:** 'public', 'private', 'followers'
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Debe ser un valor válido de GossipVisibility enum
  final String visibility;

  /// Timestamp de cuándo fue creado el chisme
  ///
  /// **Tipo:** String (ISO8601 desde Supabase TIMESTAMPTZ)
  /// **Mapeo a Entity:** String → DateTime (ISO8601 parse)
  ///
  /// **Validación:**
  /// - Campo requerido
  /// - Debe ser ISO8601 válido
  ///
  /// **Backend:** Supabase automáticamente convierte TIMESTAMPTZ → ISO8601 String
  /// Formato: "2026-10-17T03:49:11.724514+00:00"
  /// No requiere conversión especial (DateTime.parse() funciona directo)
  final String createdAt;

  /// ID del usuario que creó el chisme
  ///
  /// **Tipo:** String (para JSON/Supabase)
  /// **Mapeo a Entity:** String → String (sin conversión)
  ///
  /// **Validación:**
  /// - Campo requerido
  final String createdBy;

  /// Timestamp de cuándo fue modificado el chisme por última vez
  ///
  /// **Tipo:** String? (ISO8601 desde Supabase TIMESTAMPTZ)
  /// **Mapeo a Entity:** String? → DateTime? (ISO8601 parse)
  ///
  /// **Validación:**
  /// - Campo opcional
  /// - Si presente, debe ser ISO8601 válido
  ///
  /// **Backend:** Supabase automáticamente convierte TIMESTAMPTZ → ISO8601 String
  /// No requiere conversión especial (DateTime.parse() funciona directo)
  final String? modifiedAt;

  /// ID del usuario que modificó el chisme por última vez
  ///
  /// **Tipo:** String? (para JSON/Supabase)
  /// **Mapeo a Entity:** String? → String? (sin conversión)
  ///
  /// **Validación:**
  /// - Campo opcional
  /// - Requerido si modifiedAt está presente
  final String? modifiedBy;

  const GossipModel({
    required this.id,
    required this.countryId,
    required this.regionId,
    required this.cityId,
    required this.subject,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    this.thumbnailUrl,
    this.storagePath,
    this.thumbnailStoragePath,
    required this.publishedAs,
    required this.status,
    required this.moderationStatus,
    this.reportedCount = 0,
    this.viewCount = 0,
    this.deletedAt,
    this.deletedBy,
    required this.visibility,
    required this.createdAt,
    required this.createdBy,
    this.modifiedAt,
    this.modifiedBy,
  });

  /// Deserializa desde JSON con nomenclatura snake_case
  ///
  /// **IMPORTANTE:** Solo acepta snake_case (backend Supabase siempre usa snake_case).
  /// Fallbacks a camelCase eliminados para consistencia.
  ///
  /// Lanza FormatException si:
  /// - Faltan campos obligatorios
  /// - Campos tienen tipo incorrecto
  /// - Se usan keys camelCase (no soportado)
  ///
  /// **Cambio:** Eliminados fallbacks camelCase (2026-10-22)
  /// **Razón:** toJson() ahora usa snake_case, consistencia total
  factory GossipModel.fromJson(Map<String, dynamic> json) {
    // Validar campos obligatorios - fallar explícitamente si faltan o tienen tipo incorrecto
    // Backend Supabase SIEMPRE retorna snake_case
    final id = json['id'];
    if (id == null) throw const FormatException('Missing required field: id');
    if (id is! String) throw FormatException('Invalid type for id: expected String, got ${id.runtimeType}');

    final countryId = json['country_id'];
    if (countryId == null) throw const FormatException('Missing required field: country_id');
    if (countryId is! String) throw FormatException('Invalid type for country_id: expected String, got ${countryId.runtimeType}');

    final regionId = json['region_id'];
    if (regionId == null) throw const FormatException('Missing required field: region_id');
    if (regionId is! String) throw FormatException('Invalid type for region_id: expected String, got ${regionId.runtimeType}');

    final cityId = json['city_id'];
    if (cityId == null) throw const FormatException('Missing required field: city_id');
    if (cityId is! String) throw FormatException('Invalid type for city_id: expected String, got ${cityId.runtimeType}');

    final subject = json['subject'];
    if (subject == null) throw const FormatException('Missing required field: subject');
    if (subject is! String) throw FormatException('Invalid type for subject: expected String, got ${subject.runtimeType}');

    final content = json['content'];
    if (content == null) throw const FormatException('Missing required field: content');
    if (content is! String) throw FormatException('Invalid type for content: expected String, got ${content.runtimeType}');

    final publishedAs = json['published_as'];
    if (publishedAs == null) throw const FormatException('Missing required field: published_as');
    if (publishedAs is! String) throw FormatException('Invalid type for published_as: expected String, got ${publishedAs.runtimeType}');

    final status = json['status'];
    if (status == null) throw const FormatException('Missing required field: status');
    if (status is! String) throw FormatException('Invalid type for status: expected String, got ${status.runtimeType}');

    final moderationStatus = json['moderation_status'];
    if (moderationStatus == null) throw const FormatException('Missing required field: moderation_status');
    if (moderationStatus is! String) throw FormatException('Invalid type for moderation_status: expected String, got ${moderationStatus.runtimeType}');

    final visibility = json['visibility'];
    if (visibility == null) throw const FormatException('Missing required field: visibility');
    if (visibility is! String) throw FormatException('Invalid type for visibility: expected String, got ${visibility.runtimeType}');

    final createdAt = json['created_at'];
    if (createdAt == null) throw const FormatException('Missing required field: created_at');
    if (createdAt is! String) throw FormatException('Invalid type for created_at: expected String, got ${createdAt.runtimeType}');

    final createdBy = json['created_by'];
    if (createdBy == null) throw const FormatException('Missing required field: created_by');
    if (createdBy is! String) throw FormatException('Invalid type for created_by: expected String, got ${createdBy.runtimeType}');

    // Validar campos opcionales con tipo correcto
    final audioUrl = json['audio_url'];
    if (audioUrl != null && audioUrl is! String) {
      throw FormatException('Invalid type for audio_url: expected String or null, got ${audioUrl.runtimeType}');
    }

    final imageUrl = json['image_url'];
    if (imageUrl != null && imageUrl is! String) {
      throw FormatException('Invalid type for image_url: expected String or null, got ${imageUrl.runtimeType}');
    }

    final thumbnailUrl = json['thumbnail_url'];
    if (thumbnailUrl != null && thumbnailUrl is! String) {
      throw FormatException('Invalid type for thumbnail_url: expected String or null, got ${thumbnailUrl.runtimeType}');
    }

    final storagePath = json['storage_path'];
    if (storagePath != null && storagePath is! String) {
      throw FormatException('Invalid type for storage_path: expected String or null, got ${storagePath.runtimeType}');
    }

    final thumbnailStoragePath = json['thumbnail_storage_path'];
    if (thumbnailStoragePath != null && thumbnailStoragePath is! String) {
      throw FormatException('Invalid type for thumbnail_storage_path: expected String or null, got ${thumbnailStoragePath.runtimeType}');
    }

    final reportedCount = json['report_count'];
    if (reportedCount != null && reportedCount is! int) {
      throw FormatException('Invalid type for report_count: expected int or null, got ${reportedCount.runtimeType}');
    }

    final viewCount = json['view_count'];
    if (viewCount != null && viewCount is! int) {
      throw FormatException('Invalid type for view_count: expected int or null, got ${viewCount.runtimeType}');
    }

    final deletedAt = json['deleted_at'];
    if (deletedAt != null && deletedAt is! String) {
      throw FormatException('Invalid type for deleted_at: expected String or null, got ${deletedAt.runtimeType}');
    }

    final deletedBy = json['deleted_by'];
    if (deletedBy != null && deletedBy is! String) {
      throw FormatException('Invalid type for deleted_by: expected String or null, got ${deletedBy.runtimeType}');
    }

    final modifiedAt = json['modified_at'];
    if (modifiedAt != null && modifiedAt is! String) {
      throw FormatException('Invalid type for modified_at: expected String or null, got ${modifiedAt.runtimeType}');
    }

    final modifiedBy = json['modified_by'];
    if (modifiedBy != null && modifiedBy is! String) {
      throw FormatException('Invalid type for modified_by: expected String or null, got ${modifiedBy.runtimeType}');
    }

    return GossipModel(
      id: id,
      countryId: countryId,
      regionId: regionId,
      cityId: cityId,
      subject: subject,
      content: content,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      storagePath: storagePath,
      thumbnailStoragePath: thumbnailStoragePath,
      publishedAs: publishedAs,
      status: status,
      moderationStatus: moderationStatus,
      reportedCount: reportedCount as int? ?? 0,
      viewCount: viewCount as int? ?? 0,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      visibility: visibility,
      createdAt: createdAt,
      createdBy: createdBy,
      modifiedAt: modifiedAt,
      modifiedBy: modifiedBy,
    );
  }

  /// Serializa a JSON con nomenclatura snake_case
  ///
  /// **IMPORTANTE:** Usa snake_case para consistencia con backend Supabase.
  /// Esta convención aplica para:
  /// - Caché local (SharedPreferences)
  /// - Requests a backend (RPCs, Functions)
  /// - Respuestas de backend
  ///
  /// **Cambio:** Normalizado de camelCase a snake_case (2026-10-22)
  /// **Razón:** Backend siempre usa snake_case, toJson() debe ser consistente
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country_id': countryId,
      'region_id': regionId,
      'city_id': cityId,
      'subject': subject,
      'content': content,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'storage_path': storagePath,
      'thumbnail_storage_path': thumbnailStoragePath,
      'published_as': publishedAs,
      'status': status,
      'moderation_status': moderationStatus,
      'report_count': reportedCount,
      'view_count': viewCount,
      'deleted_at': deletedAt,
      'deleted_by': deletedBy,
      'visibility': visibility,
      'created_at': createdAt,
      'created_by': createdBy,
      'modified_at': modifiedAt,
      'modified_by': modifiedBy,
    };
  }

  /// Mapea desde Entity del dominio
  factory GossipModel.fromEntity(Gossip entity) {
    return GossipModel(
      id: entity.id,
      countryId: entity.countryId,
      regionId: entity.regionId,
      cityId: entity.cityId,
      subject: entity.subject,
      content: entity.content,
      audioUrl: entity.audioUrl,
      imageUrl: entity.imageUrl,
      thumbnailUrl: entity.thumbnailUrl,
      storagePath: null, // No disponible desde Entity (solo Model)
      thumbnailStoragePath: null, // No disponible desde Entity (solo Model)
      publishedAs: entity.publishedAs.value,
      status: entity.status.value,
      moderationStatus: entity.moderationStatus.value,
      reportedCount: entity.reportedCount,
      viewCount: entity.viewCount,
      deletedAt: entity.deletedAt?.toIso8601String(),
      deletedBy: entity.deletedBy,
      visibility: entity.visibility.value,
      createdAt: entity.createdAt.toIso8601String(),
      createdBy: entity.createdBy,
      modifiedAt: entity.modifiedAt?.toIso8601String(),
      modifiedBy: entity.modifiedBy,
    );
  }

  /// Mapea hacia Entity del dominio
  ///
  /// ⚠️ Lanza FormatException si los datos del enum no son válidos.
  /// Esto permite detectar datos corruptos o incompatibles en lugar de ocultarlos.
  Gossip toEntity() {
    return Gossip(
      id: id,
      countryId: countryId,
      regionId: regionId,
      cityId: cityId,
      subject: subject,
      content: content,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      publishedAs: PublishAs.values.firstWhere(
        (e) => e.value == publishedAs,
        orElse: () => throw FormatException(
          'Valor inválido para publishedAs: "$publishedAs". '
          'Valores válidos: ${PublishAs.values.map((e) => e.value).join(", ")}',
        ),
      ),
      status: GossipStatus.values.firstWhere(
        (e) => e.value == status,
        orElse: () => throw FormatException(
          'Valor inválido para status: "$status". '
          'Valores válidos: ${GossipStatus.values.map((e) => e.value).join(", ")}',
        ),
      ),
      moderationStatus: ModerationStatus.values.firstWhere(
        (e) => e.value == moderationStatus,
        orElse: () => throw FormatException(
          'Valor inválido para moderationStatus: "$moderationStatus". '
          'Valores válidos: ${ModerationStatus.values.map((e) => e.value).join(", ")}',
        ),
      ),
      reportedCount: reportedCount,
      viewCount: viewCount,
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
      deletedBy: deletedBy,
      visibility: GossipVisibility.values.firstWhere(
        (e) => e.value == visibility,
        orElse: () => throw FormatException(
          'Valor inválido para visibility: "$visibility". '
          'Valores válidos: ${GossipVisibility.values.map((e) => e.value).join(", ")}',
        ),
      ),
      createdAt: DateTime.parse(createdAt),
      createdBy: createdBy,
      modifiedAt: modifiedAt != null ? DateTime.parse(modifiedAt!) : null,
      modifiedBy: modifiedBy,
    );
  }
}
