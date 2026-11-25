import '../../domain/entities/user_profile.dart';

/// Respuesta de `get_user_profile` (migración 018).
///
/// - Si YO lo bloqueé: solo `{id, username, display_name, avatar_url,
///   has_blocked: true}`; el resto toma valores por defecto.
/// - Si no existe o ÉL me bloqueó, el RPC responde NULL (no llega aquí).
class UserProfileModel {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isMe;
  final bool isPrivate;
  final bool canViewContent;
  final bool hasBlocked;
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isRequested;
  final int followersCount;
  final int followingCount;
  final int? gossipsCount;

  const UserProfileModel({
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

  /// Lanza [FormatException] si falta el id o un campo tiene otro tipo
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfileModel(
        id: json['id'] as String,
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        isMe: json['is_me'] as bool? ?? false,
        isPrivate: json['is_private'] as bool? ?? false,
        canViewContent: json['can_view_content'] as bool? ?? false,
        hasBlocked: json['has_blocked'] as bool? ?? false,
        isFollowing: json['is_following'] as bool? ?? false,
        isFollowedBy: json['is_followed_by'] as bool? ?? false,
        isRequested: json['is_requested'] as bool? ?? false,
        followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
        gossipsCount: (json['gossips_count'] as num?)?.toInt(),
      );
    } catch (e) {
      throw FormatException('Error deserializando UserProfileModel: $e');
    }
  }

  UserProfile toEntity() => UserProfile(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        isMe: isMe,
        isPrivate: isPrivate,
        // Bloqueado por mí: nunca se muestra su contenido
        canViewContent: canViewContent && !hasBlocked,
        hasBlocked: hasBlocked,
        isFollowing: isFollowing,
        isFollowedBy: isFollowedBy,
        isRequested: isRequested,
        followersCount: followersCount,
        followingCount: followingCount,
        gossipsCount: gossipsCount,
      );
}
