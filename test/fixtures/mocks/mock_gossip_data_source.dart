import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip_query.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';
import 'package:chismes/features/gossip/data/datasources/gossip_remote_data_source.dart';
import 'package:chismes/features/gossip/data/datasources/gossip_local_data_source.dart';
import 'package:chismes/core/id/id_generator.dart';
import 'package:chismes/core/error/app_exception.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/gossip/domain/entities/moderation_decision.dart';
import 'package:chismes/features/gossip/domain/services/content_moderator.dart';

/// ⚠️ MOCK - NO REGISTRADO EN DI DE PRODUCCIÓN
///
/// Este mock NO está activo en la aplicación. Solo se usa para:
/// - ✅ Tests unitarios (con mockito)
/// - ✅ Desarrollo aislado de módulos (sin backend)
/// - ❌ NO se usa en producción
///
/// **Producción usa:** SupabaseGossipRemoteDataSource
/// Ver: `lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart`
///
/// **IMPORTANTE:** La línea `@Singleton` está comentada intencionalmente.
/// NO descomentar sin entender las implicaciones:
/// - Bypasea toda la seguridad de backend
/// - No persiste datos reales
/// - No aplica RLS ni validaciones de servidor
/// - Expone claves de IA en el cliente (riesgo de seguridad)
///
/// **Para activar mock (solo desarrollo temporal):**
/// 1. Descomentar `@Singleton` aquí
/// 2. Comentar `@Singleton` en `supabase_gossip_remote_data_source.dart`
/// 3. Regenerar DI: `flutter pub run build_runner build --delete-conflicting-outputs`
/// 4. **NUNCA commitear con mock activo**
// @Singleton(as: GossipRemoteDataSource) // ← DESACTIVADO: Usando Supabase
class MockGossipRemoteDataSource implements GossipRemoteDataSource {
  final IdGenerator idGenerator;
  final ContentModerator contentModerator;

  /// Simula el backend. En producción, [contentModerator] se ejecuta en el
  /// servidor y no dentro de Flutter para que no se expongan claves de IA.
  ///
  /// TODO: Mover moderación a backend (Cloud Functions) para producción
  /// Riesgo: Claves de IA expuestas en cliente, bypass posible
  /// Ver: docs/audit_add_gossip_module.md sección 9.1
  MockGossipRemoteDataSource({
    required this.idGenerator,
    required this.contentModerator,
  });

  // Estado interno para simular base de datos remota
  final List<Map<String, dynamic>> _remoteData = [
    {
      'id': '1',
      'country_id': '1',
      'region_id': '1',
      'city_id': '1',
      'subject': 'Chisme del día',
      'content': '¿Sabías que Juan se compró un carro nuevo?',
      'audio_url': null,
      'image_url': null,
      'published_as': 'anonymous',
      'status': 'published',
      'moderation_status': 'approved',
      'reported_count': 0,
      'view_count': 0,
      'deleted_at': null,
      'deleted_by': null,
      'visibility': 'public',
      'created_at': '2024-01-15T10:30:00.000Z',
      'created_by': 'mock-user',
      'modified_at': '2024-01-15T10:30:00.000Z',
      'modified_by': 'mock-user',
    },
    {
      'id': '2',
      'country_id': '1',
      'region_id': '1',
      'city_id': '2',
      'subject': 'Rumor en la oficina',
      'content': 'Dicen que María va a ser promovida',
      'audio_url': null,
      'image_url': null,
      'published_as': 'profile',
      'status': 'published',
      'moderation_status': 'approved',
      'reported_count': 0,
      'view_count': 0,
      'deleted_at': null,
      'deleted_by': null,
      'visibility': 'public',
      'created_at': '2024-01-14T15:45:00.000Z',
      'created_by': 'mock-user-2',
      'modified_at': '2024-01-14T15:45:00.000Z',
      'modified_by': 'mock-user-2',
    },
  ];

  @override
  Future<List<GossipModel>> getGossips(GossipQuery query) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    var models = _remoteData
        .map((json) => GossipModel.fromJson(json))
        .toList();

    // Aplicar filtros de ubicación (simulando where de Firestore)
    if (query.countryId != null) {
      models = models.where((m) => m.countryId == query.countryId).toList();
    }
    if (query.regionId != null) {
      models = models.where((m) => m.regionId == query.regionId).toList();
    }
    if (query.cityId != null) {
      models = models.where((m) => m.cityId == query.cityId).toList();
    }

    // Aplicar filtros de estado (simulando where de Firestore)
    if (query.status != null) {
      models = models.where((m) => m.status == query.status!.value).toList();
    }
    if (query.visibility != null) {
      models = models.where((m) => m.visibility == query.visibility!.value).toList();
    }

    // Aplicar ordenamiento (simulando orderBy de Firestore)
    models.sort((a, b) {
      final aValue = _getOrderByValue(a, query.orderBy);
      final bValue = _getOrderByValue(b, query.orderBy);
      return query.descending
          ? bValue.compareTo(aValue)
          : aValue.compareTo(bValue);
    });

    // Aplicar límite (simulando limit de Firestore)
    if (query.limit > 0 && models.length > query.limit) {
      models = models.sublist(0, query.limit);
    }

    // Aplicar cursor para paginación (simulando startAfter de Firestore)
    if (query.cursor != null) {
      final cursorIndex = models.indexWhere((m) => m.id == query.cursor);
      if (cursorIndex >= 0) {
        models = models.sublist(cursorIndex + 1);
      }
    }

    return models;
  }

  dynamic _getOrderByValue(GossipModel model, String orderBy) {
    switch (orderBy) {
      case 'createdAt':
        return model.createdAt;
      case 'subject':
        return model.subject;
      case 'viewCount':
        return model.viewCount;
      default:
        return model.createdAt;
    }
  }


  @override
  Future<GossipModel> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  ) async {
    // Simular delay de red (mayor porque incluye subida de imagen)
    await Future.delayed(const Duration(milliseconds: 1200));

    // Simular procesamiento de imagen si existe
    String? mockImageUrl;
    String? mockThumbnailUrl;

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      // Simular URLs de imagen procesada
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      mockImageUrl = 'https://mock-storage.example.com/images/$timestamp.jpg';
      mockThumbnailUrl = 'https://mock-storage.example.com/thumbnails/$timestamp.jpg';
    }

    // Crear input modificado con URLs de imagen
    final inputWithImage = CreateGossipInput(
      countryId: input.countryId,
      regionId: input.regionId,
      cityId: input.cityId,
      subject: input.subject,
      content: input.content,
      audioUrl: input.audioUrl,
      imageUrl: mockImageUrl ?? input.imageUrl,
      publishedAs: input.publishedAs,
      idempotencyKey: input.idempotencyKey,
    );

    // Lógica de creación (antes en create())
    final moderationDecision = await contentModerator.moderate(inputWithImage);
    if (moderationDecision.isRejected) {
      throw ValidationException(
        code: ErrorCode.invalidGossipContent,
        technicalMessage:
            'Rejected by moderation: ${moderationDecision.reasons.map((reason) => reason.name).join(', ')}',
      );
    }

    final tempId = idGenerator.generate();
    final now = DateTime.now();
    final nowString = now.toIso8601String();

    final model = GossipModel(
      id: tempId,
      countryId: inputWithImage.countryId,
      regionId: inputWithImage.regionId,
      cityId: inputWithImage.cityId,
      subject: inputWithImage.subject,
      content: inputWithImage.content,
      audioUrl: inputWithImage.audioUrl,
      imageUrl: inputWithImage.imageUrl,
      publishedAs: inputWithImage.publishedAs.value,
      status: moderationDecision.initialGossipStatus.value,
      moderationStatus: moderationDecision.initialModerationStatus.value,
      reportedCount: 0,
      viewCount: 0,
      deletedAt: null,
      deletedBy: null,
      visibility: moderationDecision.verdict == ModerationVerdict.publish
          ? 'public'
          : 'private',
      createdAt: nowString,
      createdBy: 'mock-user',
      modifiedAt: nowString,
      modifiedBy: 'mock-user',
    );

    // Agregar al estado interno
    _remoteData.insert(0, model.toJson());

    // Si había imagen, agregar también thumbnailUrl al modelo
    if (mockThumbnailUrl != null) {
      final modelWithThumbnail = GossipModel(
        id: model.id,
        countryId: model.countryId,
        regionId: model.regionId,
        cityId: model.cityId,
        subject: model.subject,
        content: model.content,
        audioUrl: model.audioUrl,
        imageUrl: model.imageUrl,
        thumbnailUrl: mockThumbnailUrl,
        storagePath: model.storagePath,
        thumbnailStoragePath: model.thumbnailStoragePath,
        publishedAs: model.publishedAs,
        status: model.status,
        moderationStatus: model.moderationStatus,
        reportedCount: model.reportedCount,
        viewCount: model.viewCount,
        deletedAt: model.deletedAt,
        deletedBy: model.deletedBy,
        visibility: model.visibility,
        createdAt: model.createdAt,
        createdBy: model.createdBy,
        modifiedAt: model.modifiedAt,
        modifiedBy: model.modifiedBy,
      );

      // Actualizar en estado interno
      final index = _remoteData.indexWhere((json) => json['id'] == model.id);
      if (index >= 0) {
        _remoteData[index] = modelWithThumbnail.toJson();
      }

      return modelWithThumbnail;
    }

    return model;
  }

  @override
  Future<void> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 300));

    // Simular reporte exitoso
    // En un mock real, podríamos incrementar reported_count
    final index = _remoteData.indexWhere((json) => json['id'] == gossipId);
    if (index >= 0) {
      _remoteData[index]['reported_count'] = (_remoteData[index]['reported_count'] as int) + 1;
    }
  }
}

/// Implementación mock de GossipLocalDataSource
/// Simula un almacenamiento local usando datos en memoria
///
/// ⚠️ SOLO PARA TESTS - NO SE USA EN PRODUCCIÓN
/// La implementación de producción es SharedPrefsGossipLocalDataSource
/// que usa SharedPreferences para persistencia real.
///
/// Este mock mantiene datos en memoria volátil (se pierden al cerrar app).
/// Se mantiene para tests unitarios donde no queremos dependencias externas.
// @Singleton(as: GossipLocalDataSource) // ← DESACTIVADO: Usando SharedPrefsGossipLocalDataSource
class MockGossipLocalDataSource implements GossipLocalDataSource {
  // Estado interno para simular caché local
  final List<Map<String, dynamic>> _localData = [];

  @override
  Future<List<GossipModel>> getAll() async {
    final models = _localData
        .map((json) => GossipModel.fromJson(json))
        .toList();
    return models;
  }

  @override
  Future<void> save(GossipModel gossip) async {
    _localData.insert(0, gossip.toJson());
  }

  @override
  Future<void> saveAll(List<GossipModel> gossips) async {
    _localData.clear();
    _localData.addAll(gossips.map((g) => g.toJson()));
  }

  @override
  Future<void> clear() async {
    _localData.clear();
  }
}
