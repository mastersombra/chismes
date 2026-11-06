import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validator.dart';

/// Caso de uso: Actualizar contraseña
///
/// Actualiza la contraseña del usuario actualmente autenticado.
/// Se usa después de verificar el código OTP en el flujo de reset password.
@injectable
class UpdatePasswordUseCase {
  final AuthRepository _repository;

  UpdatePasswordUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// [newPassword] Nueva contraseña
  ///
  /// Returns:
  /// - Success: void (contraseña actualizada)
  /// - Failure: ValidationFailure, WeakPasswordFailure, NetworkFailure
  Future<Result<Failure, void>> call({
    required String newPassword,
  }) async {
    // Validación de dominio
    final passwordValidation = AuthValidator.validatePassword(newPassword);
    if (passwordValidation != null) {
      return Result.failure(passwordValidation);
    }

    // Ejecutar operación
    return _repository.updatePassword(newPassword: newPassword);
  }
}
