import 'package:injectable/injectable.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/notification_page.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/supabase_notifications_remote_data_source.dart';

/// Implementación de [NotificationsRepository] sobre los RPC de la migración
/// 019. Nunca lanza: todo error vuelve como `Result.failure`.
@Singleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  final SupabaseNotificationsRemoteDataSource _remote;
  final AppLogger _logger;

  NotificationsRepositoryImpl(this._remote, this._logger);

  @override
  Future<Result<Failure, NotificationPage>> getNotifications({
    int pageSize = 30,
    NotificationCursor? cursor,
  }) =>
      _guard('getNotifications', () async {
        final page = await _remote.getNotifications(
          pageSize: pageSize,
          cursorCreatedAt: cursor?.createdAt.toUtc().toIso8601String(),
          cursorId: cursor?.id,
        );
        return page.toEntity();
      });

  @override
  Future<Result<Failure, int>> getUnreadCount() =>
      _guard('getUnreadCount', _remote.getUnreadCount);

  @override
  Future<Result<Failure, int>> markRead({List<String>? ids}) =>
      _guard('markRead', () => _remote.markRead(ids));

  /// Ejecuta [action] y convierte cualquier error en `Result.failure`
  Future<Result<Failure, T>> _guard<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return Result.success(await action());
    } catch (error, stackTrace) {
      final failure = ErrorHandler.handleError(error, stackTrace);
      _logger.w('Notifications $operation failed', context: {
        'code': failure.code.name,
      });
      return Result.failure(failure);
    }
  }
}
