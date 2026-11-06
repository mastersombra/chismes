import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/error_codes.dart' as error_codes;
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/create_gossip_input.dart';
import '../../domain/entities/gossip_query.dart';
import '../../domain/entities/report_reason.dart';
import '../models/gossip_model.dart';
import 'gossip_remote_data_source.dart';

/// Implementación de Supabase para GossipRemoteDataSource
///
/// **SEGURIDAD P0: INSERT vía RPC obligatorio ✅**
/// - Cliente NO puede hacer INSERT directo a tabla gossips
/// - Creación SOLO a través de RPC create_gossip_draft()
/// - RPC valida auth, idempotencia y fuerza estados seguros
/// - Previene bypass de moderación vía REST directo
///
/// **FLUJO DE CREACIÓN:**
/// 1. Cliente llama create() → invoca RPC create_gossip_draft()
/// 2. RPC valida auth.uid() y crea gossip en estado: draft, pending, private
/// 3. (Futuro) Trigger/Edge Function ejecuta moderación asíncrona
/// 4. Si aprobado → cambia a: published, approved, public
///
/// **MODERACIÓN (Pendiente):**
/// - Mover lógica de moderate-gossip Edge Function a trigger/background job
/// - Reglas locales + OpenAI Moderation API
/// - Actualizar estados después de moderar
///
/// Pendiente para producción:
/// - Implementar moderación asíncrona (trigger o Edge Function scheduled)
/// - Subida de archivos a Storage
/// - Políticas RLS adicionales para UPDATE/DELETE
@Singleton(as: GossipRemoteDataSource) // ✅ ACTIVADO: RPC obligatorio para creación
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  SupabaseGossipRemoteDataSource(this._supabase, this._logger);

  @override
  Future<List<GossipModel>> getGossips(GossipQuery query) async {
    // Construir query base
    var builder = _supabase
        .from('gossips')
        .select()
        .eq('status', 'published')
        .eq('moderation_status', 'approved')
        .eq('visibility', 'public')
        .isFilter('deleted_at', null);

    // Filtros de ubicación opcionales
    if (query.countryId != null) {
      builder = builder.eq('country_id', query.countryId!);
    }
    if (query.regionId != null) {
      builder = builder.eq('region_id', query.regionId!);
    }
    if (query.cityId != null) {
      builder = builder.eq('city_id', query.cityId!);
    }

    // ✅ KEYSET PAGINATION: Usa (created_at, id) compuesto
    // Previene duplicados/saltos cuando múltiples registros tienen mismo timestamp
    //
    // Formato cursor: "timestamp,id"
    // Ejemplo: "2024-01-01T00:00:00.000Z,550e8400-e29b-41d4-a716-446655440000"
    if (query.cursor != null) {
      try {
        // Parsear cursor compuesto
        final parts = query.cursor!.split(',');
        if (parts.length == 2) {
          final cursorTimestamp = DateTime.parse(parts[0]);
          final cursorId = parts[1];
          final cursorIso = cursorTimestamp.toUtc().toIso8601String();

          // Keyset pagination con tupla (created_at, id)
          // WHERE (created_at, id) < (cursor_timestamp, cursor_id)
          if (query.descending) {
            // Descendente: (created_at, id) < (cursor_timestamp, cursor_id)
            builder = builder.or(
              'created_at.lt.$cursorIso,and(created_at.eq.$cursorIso,id.lt.$cursorId)'
            );
          } else {
            // Ascendente: (created_at, id) > (cursor_timestamp, cursor_id)
            builder = builder.or(
              'created_at.gt.$cursorIso,and(created_at.eq.$cursorIso,id.gt.$cursorId)'
            );
          }
        } else {
          _logger.w('Invalid cursor format (expected "timestamp,id")', context: {
            'cursor': query.cursor,
          });
        }
      } catch (e) {
        _logger.w('Invalid cursor format, ignoring', context: {
          'cursor': query.cursor,
          'error': e.toString(),
        });
      }
    } else if (query.lastCreatedAt != null && query.lastId != null) {
      // Alternativa: usar lastCreatedAt + lastId directamente
      final cursorIso = query.lastCreatedAt!.toUtc().toIso8601String();
      final cursorId = query.lastId!;

      if (query.descending) {
        builder = builder.or(
          'created_at.lt.$cursorIso,and(created_at.eq.$cursorIso,id.lt.$cursorId)'
        );
      } else {
        builder = builder.or(
          'created_at.gt.$cursorIso,and(created_at.eq.$cursorIso,id.gt.$cursorId)'
        );
      }
    }

    // ✅ FIX P6-1: Traducir orderBy de camelCase → snake_case
    final orderByColumn = _translateOrderBy(query.orderBy);

    // Ordenamiento y límite
    final response = await builder
        .order(orderByColumn, ascending: !query.descending)
        .limit(query.limit);

    // Convertir respuesta a modelos
    return (response as List)
        .map((json) => GossipModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Traduce nombres de columnas de camelCase (Domain) a snake_case (PostgreSQL)
  String _translateOrderBy(String orderBy) {
    switch (orderBy) {
      case 'createdAt':
        return 'created_at';
      case 'modifiedAt':
        return 'modified_at';
      case 'viewCount':
        return 'view_count';
      case 'likeCount':
        return 'like_count';
      case 'commentCount':
        return 'comment_count';
      case 'reportCount':
        return 'report_count';
      default:
        // Si ya está en snake_case o no reconocemos, retornar tal cual
        return orderBy;
    }
  }


  @override
  Future<GossipModel> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  ) async {
    try {
      // ============================================
      // NUEVO FLUJO SEGURO (P1-01 Fix)
      // ============================================
      // Llama a Edge Function moderate-gossip que:
      // 1. Sube imagen a cuarentena (privado)
      // 2. Valida MIME real, dimensiones, tamaño
      // 3. Modera contenido (local + OpenAI)
      // 4. Si aprueba: Mueve a bucket público + INSERT gossip
      // 5. Si rechaza: Elimina de cuarentena
      //
      // ✅ ATÓMICO: Todo o nada (rollback automático)
      // ✅ SEGURO: Cuarentena privada, validación real
      // ✅ STORAGE_PATH: Fuente de verdad (URLs regenerables)

      _logger.d('🔍 Creando gossip con imagen vía Edge Function');

      // Construir body del request
      final body = {
        'subject': input.subject,
        'content': input.content,
        'country_id': input.countryId,
        'region_id': input.regionId,
        'city_id': input.cityId,
        'published_as': input.publishedAs.value,
        'audio_url': input.audioUrl,
        'image_base64': imageBase64, // null si no hay imagen
        'idempotency_key': input.idempotencyKey,
      };

      // Llamar Edge Function
      final response = await _supabase.functions.invoke(
        'moderate-gossip',
        body: body,
      );

      // Verificar respuesta
      if (response.status != 200) {
        _logger.e('Edge Function failed', context: {
          'status': response.status,
          'data': response.data,
        });

        // Manejar errores específicos
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final error = data['error'] as String?;
          final message = data['message'] as String?;

          // Rate limit exceeded
          if (response.status == 429) {
            throw RateLimitFailure(
              code: error_codes.ErrorCode.rateLimitExceeded,
              technicalMessage: message ?? 'Rate limit exceeded',
            );
          }

          // Content rejected by moderation
          if (error == 'Content rejected by moderation') {
            final reasons = data['reasons'] as List<dynamic>?;
            throw ValidationFailure(
              code: error_codes.ErrorCode.moderationRejected,
              technicalMessage: 'Content rejected: ${reasons?.join(', ')}',
            );
          }

          // Image upload failed
          if (error == 'Image upload failed') {
            throw ValidationFailure(
              code: error_codes.ErrorCode.mediaUploadFailed,
              technicalMessage: message ?? 'Image upload failed',
            );
          }
        }

        // Error genérico
        throw ServerFailure(
          code: error_codes.ErrorCode.serverError,
          technicalMessage: 'Edge Function failed with status ${response.status}',
        );
      }

      // Parsear respuesta exitosa
      final responseData = response.data as Map<String, dynamic>;
      final gossipData = responseData['gossip'] as Map<String, dynamic>;
      final isIdempotent = responseData['idempotent'] as bool? ?? false;

      if (isIdempotent) {
        _logger.i('♻️ Gossip duplicado detectado (idempotency)', context: {
          'id': gossipData['id'],
        });
      } else {
        _logger.i('✅ Gossip creado con imagen', context: {
          'id': gossipData['id'],
          'status': gossipData['status'],
          'hasImage': gossipData['image_url'] != null,
        });
      }

      return GossipModel.fromJson(gossipData);
    } catch (e, stackTrace) {
      _logger.e('Error en createWithImage', error: e, stackTrace: stackTrace);

      // Si ya es un Failure, re-throw
      if (e is Failure) {
        rethrow;
      }

      // Manejar errores de autenticación
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('authentication') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthFailure(
          code: error_codes.ErrorCode.unauthorized,
          technicalMessage: 'User must be logged in to create gossips',
        );
      }

      // Error genérico
      throw ServerFailure(
        code: error_codes.ErrorCode.serverError,
        technicalMessage: 'Failed to create gossip with image: $e',
      );
    }
  }

  @override
  Future<void> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      _logger.i('Reportando gossip', context: {
        'gossipId': gossipId,
        'reason': reason.value,
      });

      // Llamar al Edge Function report-gossip
      final response = await _supabase.functions.invoke(
        'report-gossip',
        body: {
          'gossip_id': gossipId,
          'reason': reason.value,
          if (details != null) 'details': details,
        },
      );

      // Verificar respuesta
      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] as String? ?? 'Unknown error';
        throw Exception(errorMessage);
      }

      _logger.i('✅ Gossip reportado exitosamente', context: {
        'gossipId': gossipId,
        'reason': reason.value,
      });
    } catch (e, stackTrace) {
      _logger.e('Error al reportar gossip', error: e, stackTrace: stackTrace);

      // Manejar errores de autenticación
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('authentication') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('missing authorization')) {
        throw const AuthFailure(
          code: error_codes.ErrorCode.unauthorized,
          technicalMessage: 'User must be logged in to report gossips',
        );
      }

      // Manejar reporte duplicado
      if (errorMessage.contains('already reported') ||
          errorMessage.contains('duplicate')) {
        throw const ValidationFailure(
          code: error_codes.ErrorCode.validationError,
          technicalMessage: 'User has already reported this gossip',
        );
      }

      // Error genérico
      throw ServerFailure(
        code: error_codes.ErrorCode.serverError,
        technicalMessage: 'Failed to report gossip: $e',
      );
    }
  }
}
