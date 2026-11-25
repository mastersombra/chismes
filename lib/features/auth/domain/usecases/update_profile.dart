import 'dart:typed_data';

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
  /// Solo actualiza los campos que no son null. `''` en [displayName] o
  /// [bio] los borra. El servidor vuelve a validar y además modera.
  ///
  /// [username] Nuevo username (debe ser único; se cambia cada N días)
  /// [displayName] Nuevo nombre a mostrar
  /// [bio] Nueva biografía
  /// [avatar] Foto nueva, ya comprimida
  /// [removeAvatar] Quitar la foto actual
  ///
  /// Returns:
  /// - Success: Usuario actualizado
  /// - Failure: ValidationFailure, UsernameCooldownFailure,
  ///   AccountRestrictedFailure, NetworkFailure, ...
  Future<Result<Failure, User>> call({
    String? username,
    String? displayName,
    String? bio,
    Uint8List? avatar,
    bool removeAvatar = false,
  }) async {
    // Validaciones de dominio
    if (username != null) {
      final usernameValidation = AuthValidator.validateUsername(username);
      if (usernameValidation != null) {
        return Result.failure(usernameValidation);
      }
    }

    if (displayName != null && displayName.isNotEmpty) {
      final displayNameValidation =
          AuthValidator.validateDisplayName(displayName);
      if (displayNameValidation != null) {
        return Result.failure(displayNameValidation);
      }
    }

    if (bio != null && bio.isNotEmpty) {
      final bioValidation = AuthValidator.validateBio(bio);
      if (bioValidation != null) {
        return Result.failure(bioValidation);
      }
    }

    // Ejecutar operación
    return _repository.updateProfile(
      username: username,
      displayName: displayName,
      bio: bio,
      avatar: avatar,
      removeAvatar: removeAvatar,
    );
  }
}
