import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/profile_settings.dart';
import '../entities/user_stats.dart';

/// Repositorio para el perfil del usuario
abstract class ProfileRepository {
  /// Obtiene las estadísticas del usuario
  Future<Result<Failure, UserStats>> getUserStats(String userId);

  /// Obtiene las configuraciones del usuario
  Future<Result<Failure, ProfileSettings>> getSettings(String userId);

  /// Actualiza las configuraciones del usuario
  Future<Result<Failure, void>> updateSettings(
    String userId,
    ProfileSettings settings,
  );

  /// Cierra la sesión del usuario
  Future<Result<Failure, void>> signOut();
}
