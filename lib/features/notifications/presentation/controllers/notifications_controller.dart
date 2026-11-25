import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_page.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notifications_read.dart';
import 'notifications_badge_controller.dart';

enum NotificationsStatus { initial, loading, loaded, error }

/// Lista paginada de notificaciones. Al cargar cada página marca como leídas
/// las no leídas que muestra (por id) y limpia la campana; en esta vista
/// siguen resaltadas las que llegaron sin leer.
@injectable
class NotificationsController extends ChangeNotifier {
  static const pageSize = 30;

  final GetNotifications _getNotifications;
  final MarkNotificationsRead _markRead;
  final NotificationsBadgeController _badge;
  final AppLogger _logger;

  NotificationsController(
    this._getNotifications,
    this._markRead,
    this._badge,
    this._logger,
  );

  NotificationsStatus _status = NotificationsStatus.initial;
  Failure? _failure;
  List<AppNotification> _items = const [];
  bool _hasMore = false;
  NotificationCursor? _cursor;
  bool _isLoadingMore = false;
  final Set<String> _markedIds = {};
  bool _disposed = false;

  NotificationsStatus get status => _status;
  Failure? get failure => _failure;
  List<AppNotification> get items => _items;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Carga la primera página (muestra el spinner)
  Future<void> load() async {
    _status = NotificationsStatus.loading;
    _failure = null;
    _notify();
    await _loadFirst();
  }

  /// Vuelve a pedir la primera página (pull-to-refresh)
  Future<void> refresh() => _loadFirst();

  Future<void> _loadFirst() async {
    final result = await _getNotifications(pageSize: pageSize);
    switch (result) {
      case Success(value: final page):
        _items = page.items;
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
        _status = NotificationsStatus.loaded;
        _failure = null;
        _notify();
        await _markShownAsRead();
      case ResultFailure(error: final failure):
        _failure = failure;
        // Si ya había lista (refresh), se conserva
        if (_status != NotificationsStatus.loaded) {
          _status = NotificationsStatus.error;
        }
        _notify();
    }
  }

  /// Marca leídas solo las no leídas que el usuario tiene en pantalla (por
  /// id): si llegó otra después de pedir la página, sigue sin leer.
  Future<void> _markShownAsRead() async {
    final ids = _items
        .where((n) => !n.isRead && !_markedIds.contains(n.id))
        .map((n) => n.id)
        .toList();
    if (ids.isEmpty) return;
    _markedIds.addAll(ids);
    final result = await _markRead(ids: ids);
    switch (result) {
      case Success():
        _badge.clear();
      case ResultFailure(error: final failure):
        _logger.w('Failed to mark notifications read', context: {
          'code': failure.code.name,
        });
    }
  }

  Future<void> loadMore() async {
    if (_status != NotificationsStatus.loaded ||
        _isLoadingMore ||
        !_hasMore ||
        _cursor == null) {
      return;
    }
    _isLoadingMore = true;
    _notify();

    final result = await _getNotifications(pageSize: pageSize, cursor: _cursor);
    switch (result) {
      case Success(value: final page):
        _items = [..._items, ...page.items];
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
        _isLoadingMore = false;
        _notify();
        await _markShownAsRead();
        return;
      case ResultFailure(error: final failure):
        _logger.w('Failed to load more notifications', context: {
          'code': failure.code.name,
        });
    }
    _isLoadingMore = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
