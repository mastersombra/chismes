import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/domain/entities/app_notification.dart';
import 'package:chismes/features/notifications/domain/entities/notification_page.dart';
import 'package:mockito/mockito.dart';

/// Datos de prueba del feature notifications (JSON del servidor y entidades)

const kActorId = '11111111-1111-1111-1111-111111111111';
const kGossipId = '22222222-2222-2222-2222-222222222222';
const kCreatedAt = '2026-11-24T10:00:00.000Z';

Map<String, dynamic> actorJson({
  String id = kActorId,
  String? username = 'beto',
  String? displayName,
  String? avatarUrl,
  bool isFollowing = false,
}) =>
    {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_following': isFollowing,
    };

Map<String, dynamic> notificationJson({
  String id = 'n1',
  String type = 'new_follower',
  String createdAt = kCreatedAt,
  bool isRead = false,
  Map<String, dynamic>? actor,
  Map<String, dynamic>? gossip,
  String? reason,
}) =>
    {
      'id': id,
      'type': type,
      'created_at': createdAt,
      'is_read': isRead,
      'actor': actor,
      'gossip': gossip,
      'reason': reason,
    };

Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> data, {
  bool hasMore = false,
  Map<String, dynamic>? nextCursor,
}) =>
    {'data': data, 'has_more': hasMore, 'next_cursor': nextCursor};

const tActor = NotificationActor(id: kActorId, username: 'beto');
const tGossip = NotificationGossip(id: kGossipId, subject: 'La fiesta de Ana');

AppNotification tNotification({
  String id = 'n1',
  NotificationType type = NotificationType.newFollower,
  DateTime? createdAt,
  bool isRead = false,
  NotificationActor? actor = tActor,
  NotificationGossip? gossip,
  String? reason,
}) =>
    AppNotification(
      id: id,
      type: type,
      createdAt: createdAt ?? DateTime.utc(2026, 11, 24, 10),
      isRead: isRead,
      actor: type.isSocial ? actor : null,
      gossip: type.isSocial ? null : (gossip ?? tGossip),
      reason: reason,
    );

NotificationPage notificationPage(
  List<AppNotification> items, {
  bool hasMore = false,
  NotificationCursor? cursor,
}) =>
    NotificationPage(items: items, hasMore: hasMore, nextCursor: cursor);

final tCursor = NotificationCursor(createdAt: DateTime.utc(2026, 11, 20), id: 'last');

const tServerFailure = ServerFailure(code: ErrorCode.serverError);

/// Valores por defecto de Mockito para los Result del feature
void provideNotificationsDummies() {
  provideDummy<Result<Failure, NotificationPage>>(
    Result.success(notificationPage(const [])),
  );
  provideDummy<Result<Failure, int>>(Result.success(0));
}
