import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_codes.dart' as app_errors;
import '../../../../core/logging/logging.dart';
import '../../domain/entities/feed_cursor.dart';
import '../models/paginated_gossips_model.dart';

/// DataSource remoto para Home Feed usando Supabase RPC.
///
/// **Responsabilidades:**
/// - Llamar funciones RPC de Supabase (get_popular_feed, etc.)
/// - Deserializar respuestas JSON a Models
/// - Lanzar excepciones en caso de error
///
/// **NO hace:**
/// - Manejo de errores (lo hace el Repository)
/// - Cache (lo hace el Repository si es necesario)
/// - Conversión a Entities (lo hace el Repository)
@singleton
class HomeRemoteDataSource {
  final AppLogger _logger;
  final SupabaseClient _supabase;

  HomeRemoteDataSource(
    this._logger,
  ) : _supabase = SupabaseConfig.client;

  /// Llama a `get_popular_feed` RPC.
  ///
  /// **Parámetros:**
  /// - `userCityId`: Ciudad del usuario (nullable)
  /// - `pageSize`: Chismes por página (default: 20)
  /// - `cursor`: Cursor de paginación (nullable)
  ///
  /// **Returns:**
  /// - `PaginatedGossipsModel`: Respuesta deserializada
  ///
  /// **Throws:**
  /// - `ServerException`: Error en Supabase
  /// - `FormatException`: Error de deserialización
  Future<PaginatedGossipsModel> getPopularFeed({
    required String? userCityId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    try {
      _logger.d('Calling get_popular_feed RPC', context: {
        'userCityId': userCityId,
        'pageSize': pageSize,
        'cursor': cursor?.toString(),
      });

      final response = await _supabase.rpc(
        'get_popular_feed',
        params: {
          'user_city_id': userCityId,
          'page_size': pageSize,
          'cursor_score': cursor?.score,
          'cursor_id': cursor?.id,
        },
      );

      _logger.d('get_popular_feed response received');

      // La función RPC retorna JSON directamente
      if (response == null) {
        _logger.w('get_popular_feed returned null, returning empty');
        return const PaginatedGossipsModel.empty();
      }

      // Deserializar respuesta
      final model = PaginatedGossipsModel.fromJson(
        response as Map<String, dynamic>,
      );

      _logger.i('Popular feed loaded', context: {
        'count': model.data.length,
        'hasMore': model.hasMore,
      });

      return model;
    } on PostgrestException catch (error, stackTrace) {
      _logger.e(
        'Supabase error in get_popular_feed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'code': error.code,
          'message': error.message,
          'details': error.details,
        },
      );
      throw ServerException(
        code: app_errors.ErrorCode.serverError,
        technicalMessage: 'Error al cargar feed popular: ${error.message}',
      );
    } on FormatException catch (error, stackTrace) {
      _logger.e(
        'Format error deserializing popular feed',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        code: app_errors.ErrorCode.serverError,
        technicalMessage: 'Error de formato en respuesta del servidor',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error in get_popular_feed',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        code: app_errors.ErrorCode.unknownError,
        technicalMessage: 'Error inesperado al cargar feed',
      );
    }
  }

  /// Llama a `get_following_feed` RPC.
  ///
  /// **Parámetros:**
  /// - `userId`: ID del usuario actual (requerido)
  /// - `pageSize`: Chismes por página (default: 20)
  /// - `cursor`: Cursor de paginación (nullable)
  ///
  /// **Returns:**
  /// - `PaginatedGossipsModel`: Respuesta deserializada
  ///
  /// **Throws:**
  /// - `ServerException`: Error en Supabase
  /// - `FormatException`: Error de deserialización
  Future<PaginatedGossipsModel> getFollowingFeed({
    required String userId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    try {
      _logger.d('Calling get_following_feed RPC', context: {
        'userId': userId,
        'pageSize': pageSize,
        'cursor': cursor?.toString(),
      });

      final response = await _supabase.rpc(
        'get_following_feed',
        params: {
          'current_user_id': userId,
          'page_size': pageSize,
          'cursor_created_at': cursor?.createdAt?.toIso8601String(),
          'cursor_id': cursor?.id,
        },
      );

      _logger.d('get_following_feed response received');

      if (response == null) {
        _logger.w('get_following_feed returned null, returning empty');
        return const PaginatedGossipsModel.empty();
      }

      final model = PaginatedGossipsModel.fromJson(
        response as Map<String, dynamic>,
      );

      _logger.i('Following feed loaded', context: {
        'count': model.data.length,
        'hasMore': model.hasMore,
      });

      return model;
    } on PostgrestException catch (error, stackTrace) {
      _logger.e(
        'Supabase error in get_following_feed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'code': error.code,
          'message': error.message,
        },
      );
      throw ServerException(
        code: app_errors.ErrorCode.serverError,
        technicalMessage: 'Error al cargar feed de seguidos: ${error.message}',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error in get_following_feed',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        code: app_errors.ErrorCode.unknownError,
        technicalMessage: 'Error inesperado al cargar feed',
      );
    }
  }

  /// Llama a `check_new_gossips` RPC.
  ///
  /// **Parámetros:**
  /// - `userCityId`: Ciudad del usuario (nullable)
  /// - `since`: Timestamp desde cuándo buscar
  ///
  /// **Returns:**
  /// - `int`: Cantidad de chismes nuevos
  ///
  /// **Throws:**
  /// - `ServerException`: Error en Supabase
  Future<int> checkNewGossips({
    required String? userCityId,
    required DateTime since,
  }) async {
    try {
      _logger.d('Calling check_new_gossips RPC', context: {
        'userCityId': userCityId,
        'since': since.toIso8601String(),
      });

      final response = await _supabase.rpc(
        'check_new_gossips',
        params: {
          'user_city_id': userCityId,
          'since_timestamp': since.toIso8601String(),
        },
      );

      final count = response as int;

      _logger.d('check_new_gossips returned', context: {'count': count});

      return count;
    } on PostgrestException catch (error, stackTrace) {
      _logger.e(
        'Supabase error in check_new_gossips',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        code: app_errors.ErrorCode.serverError,
        technicalMessage: 'Error al verificar chismes nuevos: ${error.message}',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error in check_new_gossips',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        code: app_errors.ErrorCode.unknownError,
        technicalMessage: 'Error inesperado al verificar chismes',
      );
    }
  }
}
