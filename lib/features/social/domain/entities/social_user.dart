import 'package:equatable/equatable.dart';

/// Usuario en una lista (seguidores, seguidos, solicitudes, bloqueados,
/// búsqueda). Solo datos públicos + si yo lo sigo.
class SocialUser extends Equatable {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  /// Si YO lo sigo
  final bool isFollowing;

  const SocialUser({
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

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, isFollowing];
}
