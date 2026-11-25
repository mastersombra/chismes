import 'package:flutter/widgets.dart';

/// Lista de seguidores o de seguidos
enum FollowListKind {
  followers('followers'),
  following('following');

  /// Valor que espera el RPC `get_follow_list`
  final String value;

  const FollowListKind(this.value);
}

/// Navegación a las pantallas sociales (perfil de usuario, seguidores,
/// solicitudes, bloqueados) sin que otros features importen `social`.
///
/// La implementa el feature social (`@Singleton(as: SocialNavigator)`);
/// gossip, home, search y profile la usan con `getIt<SocialNavigator>()`.
abstract class SocialNavigator {
  /// Abre el perfil de un usuario (si es el propio, sin seguir/bloquear)
  Future<void> openUserProfile(BuildContext context, String userId);

  /// Abre los seguidores o seguidos de un usuario
  Future<void> openFollowList(
    BuildContext context, {
    required String userId,
    required FollowListKind kind,
  });

  /// Abre las solicitudes de seguimiento que me hicieron
  Future<void> openFollowRequests(BuildContext context);

  /// Abre los usuarios que bloqueé
  Future<void> openBlockedUsers(BuildContext context);

  /// Resultados de búsqueda de usuarios para [query] (pestaña Usuarios de
  /// Buscar). El widget busca solo y maneja sus estados.
  Widget buildUserSearchResults(String query);
}
