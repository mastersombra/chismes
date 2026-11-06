import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validator.dart';

/// Caso de uso: Resetear contraseña
///
/// Envía un email para resetear la contraseña del usuario.
@injectable
class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// [email] Email del usuario
  ///
  /// Returns:
  /// - Success: void (email enviado)
  /// - Failure: ValidationFailure, UserNotFoundFailure, NetworkFailure
  Future<Result<Failure, void>> call({
    required String email,
  }) async {
    // Validación de dominio
    final emailValidation = AuthValidator.validateEmail(email);
    if (emailValidation != null) {
      return Result.failure(emailValidation);
    }

    // Ejecutar operación
    return _repository.resetPassword(email: email);
  }
}
