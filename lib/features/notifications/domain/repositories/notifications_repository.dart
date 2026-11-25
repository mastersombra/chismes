import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/notification_page.dart';

/// Notificaciones in-app del usuario actual (RPCs de la migración 019).
/// Nunca lanza: todo error vuelve como `Result.failure`.
abstract class NotificationsRepository {
  /// Página de notificaciones, más recientes primero. Sin [cursor], la primera.
  Future<Result<Failure, NotificationPage>> getNotifications({
    int pageSize = 30,
    NotificationCursor? cursor,
  });

  /// No leídas (el servidor corta en 100: la UI muestra "99+")
  Future<Result<Failure, int>> getUnreadCount();

  /// Marca como leídas las [ids] o, si es null, todas. Devuelve cuántas marcó.
  Future<Result<Failure, int>> markRead({List<String>? ids});
}
