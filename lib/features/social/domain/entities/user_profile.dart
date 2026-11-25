import 'package:equatable/equatable.dart';

/// Relación de seguimiento de YO hacia el perfil
enum FollowStatus {
  /// No lo sigo ni hay solicitud
  none,

  /// Solicitud pendiente (cuenta privada)
  requested,

  /// Lo sigo
  following,
}

/// Perfil de un usuario visto por mí (`get_user_profile`, migración 018).
///
/// - [hasBlocked] = YO lo bloqueé: solo trae id, @usuario, nombre y foto
///   (sin bio ni contadores) para poder desbloquear.
/// - [canViewContent] = false en cuentas privadas que no sigo: se ven
///   nombre, foto, bio y contadores, pero no sus listas ni sus chismes.
/// - Si ÉL me bloqueó o no existe, el servidor no manda perfil (el
///   repositorio responde `userNotAvailable`).
class UserProfile extends Equatable {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;

  /// Es mi propio perfil (sin botones de seguir ni bloquear)
  final bool isMe;
  final bool isPrivate;
  final bool canViewContent;
  final bool hasBlocked;
  final bool isFollowing;

  /// Él me sigue
  final bool isFollowedBy;
  final bool isRequested;
  final int followersCount;
  final int followingCount;

  /// Chismes con perfil publicados (null si no puedo ver su contenido)
  final int? gossipsCount;

  const UserProfile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.isMe = false,
    this.isPrivate = false,
    this.canViewContent = false,
    this.hasBlocked = false,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isRequested = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.gossipsCount,
  });

  FollowStatus get followStatus {
    if (isFollowing) return FollowStatus.following;
    if (isRequested) return FollowStatus.requested;
    return FollowStatus.none;
  }

  /// `@usuario` o null si no tiene
  String? get handle => username != null ? '@$username' : null;

  /// Nombre visible o, si no hay, @usuario ('' si no tiene ninguno)
  String get name => displayName ?? handle ?? '';

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  bool get hasBio => bio != null && bio!.trim().isNotEmpty;

  /// Se pueden mostrar seguir/bloquear (no es mi perfil)
  bool get canInteract => !isMe;

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        avatarUrl,
        bio,
        isMe,
        isPrivate,
        canViewContent,
        hasBlocked,
        isFollowing,
        isFollowedBy,
        isRequested,
        followersCount,
        followingCount,
        gossipsCount,
      ];
}
