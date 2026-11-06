import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validator.dart';

/// Caso de uso: Actualizar perfil del usuario
///
/// Actualiza uno o más campos del perfil del usuario actual.
@injectable
class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// Solo actualiza los campos que no son null.
  ///
  /// [username] Nuevo username (debe ser único)
  /// [displayName] Nuevo nombre a mostrar
  /// [avatarUrl] Nueva URL de avatar
  /// [bio] Nueva biografía
  ///
  /// Returns:
  /// - Success: Usuario actualizado
  /// - Failure: ValidationFailure, UsernameAlreadyTakenFailure, NetworkFailure
  Future<Result<Failure, User>> call({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    // Validaciones de dominio
    if (username != null) {
      final usernameValidation = AuthValidator.validateUsername(username);
      if (usernameValidation != null) {
        return Result.failure(usernameValidation);
      }
    }

    if (displayName != null) {
      final displayNameValidation =
          AuthValidator.validateDisplayName(displayName);
      if (displayNameValidation != null) {
        return Result.failure(displayNameValidation);
      }
    }

    if (bio != null) {
      final bioValidation = AuthValidator.validateBio(bio);
      if (bioValidation != null) {
        return Result.failure(bioValidation);
      }
    }

    // Ejecutar operación
    return _repository.updateProfile(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }
}
