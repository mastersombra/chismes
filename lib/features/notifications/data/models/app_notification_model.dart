import '../../domain/entities/app_notification.dart';

/// Notificación como la manda `get_notifications` (migración 019):
/// `{id, type, created_at, is_read, actor: {...} | null,
///   gossip: {id, subject} | null, reason}`
class AppNotificationModel {
  final String id;
  final String type;
  final String createdAt;
  final bool isRead;
  final NotificationActorModel? actor;
  final NotificationGossipModel? gossip;
  final String? reason;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.actor,
    this.gossip,
    this.reason,
  });

  /// Lanza [FormatException] si falta un campo obligatorio o tiene otro tipo
  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      final actor = json['actor'] as Map<String, dynamic>?;
      final gossip = json['gossip'] as Map<String, dynamic>?;
      return AppNotificationModel(
        id: json['id'] as String,
        type: json['type'] as String,
        createdAt: json['created_at'] as String,
        isRead: json['is_read'] as bool? ?? false,
        actor: actor != null ? NotificationActorModel.fromJson(actor) : null,
        gossip: gossip != null ? NotificationGossipModel.fromJson(gossip) : null,
        reason: json['reason'] as String?,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Error deserializando AppNotificationModel: $e');
    }
  }

  /// null si el tipo no lo conoce esta versión de la app (se ignora)
  AppNotification? toEntity() {
    final notificationType = NotificationType.fromValue(type);
    if (notificationType == null) return null;
    return AppNotification(
      id: id,
      type: notificationType,
      createdAt: DateTime.parse(createdAt),
      isRead: isRead,
      actor: actor?.toEntity(),
      gossip: gossip?.toEntity(),
      reason: reason,
    );
  }
}

/// Actor (`social_user_json`): `{id, username, display_name, avatar_url, is_following}`
class NotificationActorModel {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool isFollowing;

  const NotificationActorModel({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isFollowing = false,
  });

  factory NotificationActorModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationActorModel(
        id: json['id'] as String,
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isFollowing: json['is_following'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Error deserializando NotificationActorModel: $e');
    }
  }

  NotificationActor toEntity() => NotificationActor(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        isFollowing: isFollowing,
      );
}

/// Chisme: `{id, subject}`
class NotificationGossipModel {
  final String id;
  final String subject;

  const NotificationGossipModel({required this.id, required this.subject});

  factory NotificationGossipModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationGossipModel(
        id: json['id'] as String,
        subject: json['subject'] as String? ?? '',
      );
    } catch (e) {
      throw FormatException('Error deserializando NotificationGossipModel: $e');
    }
  }

  NotificationGossip toEntity() => NotificationGossip(id: id, subject: subject);
}
