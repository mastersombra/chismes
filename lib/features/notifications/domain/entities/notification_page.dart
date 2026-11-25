import 'package:equatable/equatable.dart';

import 'app_notification.dart';

/// Cursor de la lista de notificaciones: (created_at, id) del último elemento
class NotificationCursor extends Equatable {
  final DateTime createdAt;
  final String id;

  const NotificationCursor({required this.createdAt, required this.id});

  @override
  List<Object?> get props => [createdAt, id];
}

/// Página de notificaciones (más recientes primero)
class NotificationPage extends Equatable {
  final List<AppNotification> items;
  final bool hasMore;

  /// Cursor para pedir la siguiente página (null si no hay más)
  final NotificationCursor? nextCursor;

  const NotificationPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  @override
  List<Object?> get props => [items, hasMore, nextCursor];
}
