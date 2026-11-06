import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validator.dart';

/// Caso de uso: Iniciar sesión con email y contraseña
///
/// Valida las credenciales y ejecuta el login.
@injectable
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  SignInWithEmailUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// [email] Email del usuario
  /// [password] Contraseña del usuario
  ///
  /// Returns:
  /// - Success: Usuario autenticado
  /// - Failure: ValidationFailure, InvalidCredentialsFailure, NetworkFailure
  Future<Result<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    // Validación de dominio
    final emailValidation = AuthValidator.validateEmail(email);
    if (emailValidation != null) {
      return Result.failure(emailValidation);
    }

    final passwordValidation = AuthValidator.validatePassword(password);
    if (passwordValidation != null) {
      return Result.failure(passwordValidation);
    }

    // Ejecutar operación
    return _repository.signInWithEmail(
      email: email,
      password: password,
    );
  }
}
