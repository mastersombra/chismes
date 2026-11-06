import 'package:injectable/injectable.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/feed_cursor.dart';
import '../../domain/entities/paginated_gossips.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

/// Implementación del repositorio de Home Feed.
///
/// **Responsabilidades:**
/// - Implementar contratos del domain (HomeRepository)
/// - Delegar a DataSources (HomeRemoteDataSource)
/// - Convertir Models a Entities
/// - Manejo de errores (ErrorHandler)
/// - Logging
///
/// **Patrón:**
/// ```
/// try {
///   model = await dataSource.method()
///   entity = model.toEntity()
///   return Result.success(entity)
/// } catch (error) {
///   return Result.failure(ErrorHandler.handleError(error))
/// }
/// ```
@Singleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  HomeRepositoryImpl(
    this._remoteDataSource,
    this._logger,
  );

  @override
  Future<Result<Failure, PaginatedGossips>> getPopularFeed({
    required String? userId,
    required String? cityId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    try {
      _logger.d('Getting popular feed', context: {
        'userId': userId,
        'cityId': cityId,
        'pageSize': pageSize,
        'cursor': cursor?.toString(),
      });

      final model = await _remoteDataSource.getPopularFeed(
        userCityId: cityId,
        pageSize: pageSize,
        cursor: cursor,
      );

      final entity = model.toEntity();

      _logger.i('Popular feed retrieved successfully', context: {
        'count': entity.data.length,
        'hasMore': entity.hasMore,
      });

      return Result.success(entity);
    } catch (error, stackTrace) {
      _logger.e(
        'Error getting popular feed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'userId': userId,
          'cityId': cityId,
        },
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, PaginatedGossips>> getFollowingFeed({
    required String userId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    try {
      _logger.d('Getting following feed', context: {
        'userId': userId,
        'pageSize': pageSize,
        'cursor': cursor?.toString(),
      });

      final model = await _remoteDataSource.getFollowingFeed(
        userId: userId,
        pageSize: pageSize,
        cursor: cursor,
      );

      final entity = model.toEntity();

      _logger.i('Following feed retrieved successfully', context: {
        'count': entity.data.length,
        'hasMore': entity.hasMore,
      });

      return Result.success(entity);
    } catch (error, stackTrace) {
      _logger.e(
        'Error getting following feed',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, PaginatedGossips>> getRecommendedFeed({
    required String? userId,
    required String? cityId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    try {
      _logger.d('Getting recommended feed', context: {
        'userId': userId,
        'cityId': cityId,
        'pageSize': pageSize,
      });

      // Recommended feed usa el mismo algoritmo que Popular
      // pero típicamente con menos items
      final model = await _remoteDataSource.getPopularFeed(
        userCityId: cityId,
        pageSize: pageSize,
        cursor: cursor,
      );

      final entity = model.toEntity();

      _logger.i('Recommended feed retrieved successfully', context: {
        'count': entity.data.length,
        'hasMore': entity.hasMore,
      });

      return Result.success(entity);
    } catch (error, stackTrace) {
      _logger.e(
        'Error getting recommended feed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'userId': userId,
          'cityId': cityId,
        },
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, int>> checkNewGossips({
    required String? userId,
    required String? cityId,
    required DateTime since,
  }) async {
    try {
      _logger.d('Checking new gossips', context: {
        'userId': userId,
        'cityId': cityId,
        'since': since.toIso8601String(),
      });

      final count = await _remoteDataSource.checkNewGossips(
        userCityId: cityId,
        since: since,
      );

      _logger.d('New gossips check completed', context: {'count': count});

      return Result.success(count);
    } catch (error, stackTrace) {
      _logger.e(
        'Error checking new gossips',
        error: error,
        stackTrace: stackTrace,
        context: {
          'userId': userId,
          'cityId': cityId,
        },
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }
}
