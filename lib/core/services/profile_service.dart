import 'package:injectable/injectable.dart';

/// Servicio para gestionar información del perfil del usuario.
///
/// **Responsabilidades:**
/// - Obtener información básica del perfil (followingCount, followersCount)
/// - Cache de perfil en memoria
///
/// **Uso:**
/// ```dart
/// final profileService = getIt<ProfileService>();
/// final followingCount = await profileService.getFollowingCount(userId);
/// ```
@singleton
class ProfileService {
  // TODO: Implementar cuando se tenga ProfileRepository
  // Por ahora, retorna placeholder hardcoded

  /// Obtiene la cantidad de usuarios que sigue el usuario.
  ///
  /// **Retorna:** Cantidad de usuarios siguiendo.
  ///
  /// **Uso:** Principalmente para decidir si mostrar empty state en FollowingTab.
  Future<int> getFollowingCount(String userId) async {
    // TODO: Implementar cuando ProfileRepository esté disponible
    // Por ahora, retorna 5 como placeholder (usuario sigue a 5 personas)
    return 5;
  }

  /// Obtiene la cantidad de seguidores del usuario.
  ///
  /// **Retorna:** Cantidad de seguidores.
  Future<int> getFollowersCount(String userId) async {
    // TODO: Implementar cuando ProfileRepository esté disponible
    return 0;
  }
}
