import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/repositories/account_status_repository.dart';
import '../datasources/account_status_remote_data_source.dart';

/// Implementación de [AccountStatusRepository] sobre `account-status`.
///
/// Sin cache: una decisión de moderación o el vencimiento de una restricción
/// cambian el estado en cualquier momento.
@Singleton(as: AccountStatusRepository)
class AccountStatusRepositoryImpl implements AccountStatusRepository {
  final AccountStatusRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  AccountStatusRepositoryImpl(this._remoteDataSource, this._logger);

  @override
  Future<Result<Failure, AccountStatus>> getStatus() async {
    try {
      return Result.success(await _remoteDataSource.getStatus());
    } catch (error, stackTrace) {
      _logger.e('Error loading account status', error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, AccountAppeal>> submitAppeal({
    required String queueId,
    required String message,
  }) async {
    try {
      final appeal = await _remoteDataSource.submitAppeal(queueId: queueId, message: message);
      _logger.i('Appeal submitted', context: {'queueId': queueId});
      return Result.success(appeal);
    } catch (error, stackTrace) {
      final failure = ErrorHandler.handleError(error, stackTrace);
      // Ya apelado / fuera de plazo es flujo normal, no un error
      if (failure.code == ErrorCode.conflict) {
        _logger.w('Appeal not allowed', context: {'queueId': queueId});
      } else {
        _logger.e(
          'Error submitting appeal',
          error: error,
          stackTrace: stackTrace,
          context: {'queueId': queueId},
        );
      }
      return Result.failure(failure);
    }
  }
}
