import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../../domain/entities/moderation_item.dart';
import '../../domain/entities/review_decision.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_remote_data_source.dart';

/// Implementación de [ModerationRepository] sobre `moderation-review`.
///
/// Sin cache: la cola cambia con cada decisión (de cualquier moderador) y las
/// URLs firmadas de la media vencen a los 5 minutos.
@Singleton(as: ModerationRepository)
class ModerationRepositoryImpl implements ModerationRepository {
  final ModerationRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  ModerationRepositoryImpl(this._remoteDataSource, this._logger);

  @override
  Future<Result<Failure, List<ModerationItem>>> getQueue({
    required ModerationQueueStatus status,
    required int limit,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getQueue(
        status: status.value,
        limit: limit,
        offset: offset,
      );
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (error, stackTrace) {
      _logger.e(
        'Error loading moderation queue',
        error: error,
        stackTrace: stackTrace,
        context: {'status': status.value, 'offset': offset},
      );
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> decide(ReviewDecision decision) async {
    try {
      await _remoteDataSource.decide(decision);
      _logger.i('Moderation decision applied', context: {
        'queueId': decision.queueId,
        'decision': decision.approve ? 'approve' : 'reject',
      });
      return Result.success(null);
    } catch (error, stackTrace) {
      final failure = ErrorHandler.handleError(error, stackTrace);
      // Que otro moderador ya haya decidido es flujo normal, no un error
      if (failure.code == ErrorCode.conflict) {
        _logger.w('Moderation item already decided', context: {'queueId': decision.queueId});
      } else {
        _logger.e(
          'Error applying moderation decision',
          error: error,
          stackTrace: stackTrace,
          context: {'queueId': decision.queueId},
        );
      }
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<Failure, List<ModerationAppeal>>> getAppeals({
    required AppealStatus status,
    required int limit,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getAppeals(
        status: status.value,
        limit: limit,
        offset: offset,
      );
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (error, stackTrace) {
      _logger.e(
        'Error loading appeals',
        error: error,
        stackTrace: stackTrace,
        context: {'status': status.value, 'offset': offset},
      );
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> decideAppeal(AppealDecision decision) async {
    try {
      await _remoteDataSource.decideAppeal(decision);
      _logger.i('Appeal decision applied', context: {
        'appealId': decision.appealId,
        'decision': decision.accept ? 'accept' : 'reject',
      });
      return Result.success(null);
    } catch (error, stackTrace) {
      final failure = ErrorHandler.handleError(error, stackTrace);
      if (failure.code == ErrorCode.conflict || failure.code == ErrorCode.insufficientPermissions) {
        _logger.w('Appeal decision not applied', context: {
          'appealId': decision.appealId,
          'code': failure.code.name,
        });
      } else {
        _logger.e(
          'Error applying appeal decision',
          error: error,
          stackTrace: stackTrace,
          context: {'appealId': decision.appealId},
        );
      }
      return Result.failure(failure);
    }
  }
}
