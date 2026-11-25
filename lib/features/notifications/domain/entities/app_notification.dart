import 'package:equatable/equatable.dart';

/// Tipos de notificación que conoce la app (`notifications.type`, migración
/// 019). Los que lleguen de versiones futuras del servidor se ignoran.
enum NotificationType {
  /// Alguien empezó a seguirme (trae actor)
  newFollower('new_follower'),

  /// Alguien pidió seguirme: cuenta privada (trae actor)
  followRequest('follow_request'),

  /// Aceptaron mi solicitud (trae actor)
  followAccepted('follow_accepted'),

  /// Un moderador aprobó mi chisme (trae chisme)
  gossipApproved('gossip_approved'),

  /// Un moderador rechazó mi chisme (trae chisme y motivo)
  gossipRejected('gossip_rejected'),

  /// Aceptaron mi apelación (trae chisme)
  appealAccepted('appeal_accepted'),

  /// Rechazaron mi apelación (trae chisme)
  appealRejected('appeal_rejected');

  /// Valor que manda el servidor
  final String value;

  const NotificationType(this.value);

  /// null si el servidor manda un tipo que esta versión no conoce
  static NotificationType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }

  /// Sociales (con actor) vs. de la cuenta (con chisme)
  bool get isSocial =>
      this == newFollower || this == followRequest || this == followAccepted;
}

/// Quién provocó una notificación social (datos públicos)
class NotificationActor extends Equatable {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  /// Si YO lo sigo
  final bool isFollowing;

  const NotificationActor({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isFollowing = false,
  });

  /// `@usuario` o null si no tiene
  String? get handle => username != null ? '@$username' : null;

  /// Nombre visible o, si no hay, @usuario ('' si no tiene ninguno)
  String get name => displayName ?? handle ?? '';

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, isFollowing];
}

/// Chisme propio al que se refiere una notificación de la cuenta
class NotificationGossip extends Equatable {
  final String id;
  final String subject;

  const NotificationGossip({required this.id, required this.subject});

  @override
  List<Object?> get props => [id, subject];
}

/// Notificación in-app del usuario actual
class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final DateTime createdAt;

  /// Leída cuando se cargó (no cambia al marcarlas en esta vista)
  final bool isRead;

  /// Solo en las sociales
  final NotificationActor? actor;

  /// Solo en las de la cuenta
  final NotificationGossip? gossip;

  /// Código del motivo predefinido (solo en `gossipRejected`)
  final String? reason;

  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.actor,
    this.gossip,
    this.reason,
  });

  @override
  List<Object?> get props => [id, type, createdAt, isRead, actor, gossip, reason];
}
