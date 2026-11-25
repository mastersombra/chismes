import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_page.dart';
import 'app_notification_model.dart';

/// Página de `get_notifications`:
/// `{data: [...], has_more, next_cursor: {created_at, id} | null}`
class NotificationPageModel {
  final List<AppNotificationModel> data;
  final bool hasMore;
  final String? nextCursorCreatedAt;
  final String? nextCursorId;

  const NotificationPageModel({
    required this.data,
    required this.hasMore,
    this.nextCursorCreatedAt,
    this.nextCursorId,
  });

  /// [json] null (RPC sin respuesta) → página vacía.
  /// Lanza [FormatException] si el JSON no tiene la forma esperada.
  factory NotificationPageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const NotificationPageModel(data: [], hasMore: false);
    }
    try {
      final items = (json['data'] as List<dynamic>? ?? const [])
          .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
      final cursor = json['next_cursor'] as Map<String, dynamic>?;
      return NotificationPageModel(
        data: items,
        hasMore: json['has_more'] as bool? ?? false,
        nextCursorCreatedAt: cursor?['created_at'] as String?,
        nextCursorId: cursor?['id'] as String?,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Error deserializando NotificationPageModel: $e');
    }
  }

  /// Omite los tipos desconocidos (el cursor del servidor sigue valiendo).
  /// Sin cursor válido no hay más páginas (evita pedir la misma en bucle).
  NotificationPage toEntity() {
    final cursor = nextCursorCreatedAt != null && nextCursorId != null
        ? NotificationCursor(
            createdAt: DateTime.parse(nextCursorCreatedAt!),
            id: nextCursorId!,
          )
        : null;
    return NotificationPage(
      items: data.map((m) => m.toEntity()).whereType<AppNotification>().toList(),
      hasMore: hasMore && cursor != null,
      nextCursor: cursor,
    );
  }
}
