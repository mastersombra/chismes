import '../../../../core/error/failure.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/result/result.dart';
import '../../../gossip/domain/entities/gossip.dart';
import '../entities/follow_request.dart';
import '../entities/follow_result.dart';
import '../entities/social_page.dart';
import '../entities/social_user.dart';
import '../entities/user_profile.dart';

/// Seguidores, solicitudes, bloqueos y perfiles de otros usuarios.
///
/// Todo lo resuelve el servidor con `auth.uid()` (migración 018): nunca se
/// manda el ID del usuario actual. Errores comunes:
/// - `userNotAvailable`: el usuario no existe o hay un bloqueo (no se
///   distingue a propósito), o no puedo ver sus listas (cuenta privada)
/// - `invalidInput`: acción consigo mismo
/// - `userNotAuthenticated`: sin sesión
abstract class SocialRepository {
  /// Sigue a [userId]: [FollowResult.following] si la cuenta es pública,
  /// [FollowResult.requested] si es privada. Con demasiados seguimientos
  /// nuevos en poco tiempo: `RateLimitFailure(followRateLimited)`.
  Future<Result<Failure, FollowResult>> followUser(String userId);

  /// Deja de seguir (también cancela una solicitud pendiente)
  Future<Result<Failure, void>> unfollowUser(String userId);

  /// Acepta o rechaza la solicitud que me hizo [requesterId]
  Future<Result<Failure, void>> respondFollowRequest(
    String requesterId, {
    required bool accept,
  });

  /// Quita a [followerId] de mis seguidores
  Future<Result<Failure, void>> removeFollower(String followerId);

  /// Bloquea: corta el seguimiento y las solicitudes en ambos sentidos
  Future<Result<Failure, void>> blockUser(String userId);

  Future<Result<Failure, void>> unblockUser(String userId);

  /// Perfil de [userId] visto por mí (`userNotAvailable` si no existe o él
  /// me bloqueó)
  Future<Result<Failure, UserProfile>> getUserProfile(String userId);

  /// Seguidores o seguidos de [userId]
  Future<Result<Failure, SocialPage<SocialUser>>> getFollowList(
    String userId,
    FollowListKind kind, {
    int pageSize = 30,
    SocialCursor? cursor,
  });

  /// Solicitudes que me hicieron (más recientes primero)
  Future<Result<Failure, List<FollowRequest>>> getFollowRequests();

  /// Usuarios que bloqueé
  Future<Result<Failure, List<SocialUser>>> getBlockedUsers();

  /// Busca usuarios por @usuario o nombre (omite bloqueados y a mí)
  Future<Result<Failure, List<SocialUser>>> searchUsers(
    String query, {
    int limit = 20,
  });

  /// Chismes con perfil de [userId] (nunca anónimos), más recientes primero
  Future<Result<Failure, SocialPage<Gossip>>> getUserGossips(
    String userId, {
    int pageSize = 20,
    SocialCursor? cursor,
  });
}
