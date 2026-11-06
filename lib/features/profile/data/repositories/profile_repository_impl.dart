import 'package:injectable/injectable.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_settings_model.dart';

/// Implementación del repositorio de perfil
@Singleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  ProfileRepositoryImpl(
    this._remoteDataSource,
    this._logger,
  );

  @override
  Future<Result<Failure, UserStats>> getUserStats(String userId) async {
    try {
      _logger.d('Getting user stats for userId: $userId');

      final model = await _remoteDataSource.getUserStats(userId);
      final entity = model.toEntity();

      _logger.i('User stats retrieved successfully');
      return Result.success(entity);
    } catch (error, stackTrace) {
      _logger.e(
        'Error getting user stats',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, ProfileSettings>> getSettings(String userId) async {
    try {
      _logger.d('Getting settings for userId: $userId');

      final model = await _remoteDataSource.getSettings(userId);
      final entity = model.toEntity();

      _logger.i('Settings retrieved successfully');
      return Result.success(entity);
    } catch (error, stackTrace) {
      _logger.e(
        'Error getting settings',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, void>> updateSettings(
    String userId,
    ProfileSettings settings,
  ) async {
    try {
      _logger.d('Updating settings for userId: $userId');

      final model = ProfileSettingsModel.fromEntity(settings);
      await _remoteDataSource.updateSettings(userId, model);

      _logger.i('Settings updated successfully');
      return Result.success(null);
    } catch (error, stackTrace) {
      _logger.e(
        'Error updating settings',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, void>> signOut() async {
    try {
      _logger.i('Signing out');

      await _remoteDataSource.signOut();

      _logger.i('Signed out successfully');
      return Result.success(null);
    } catch (error, stackTrace) {
      _logger.e(
        'Error signing out',
        error: error,
        stackTrace: stackTrace,
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }
}
