import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validator.dart';

/// Caso de uso: Registrar nuevo usuario con email y contraseña
///
/// Valida las credenciales, verifica que el email no exista,
/// y envía código OTP.
/// El usuario NO queda autenticado hasta verificar el OTP.
@injectable
class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  SignUpWithEmailUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// [email] Email del nuevo usuario
  /// [password] Contraseña del nuevo usuario
  ///
  /// Returns:
  /// - Success: void (OTP enviado por email)
  /// - Failure: ValidationFailure, EmailAlreadyInUseFailure, WeakPasswordFailure
  ///
  /// Flujo:
  /// 1. Validar email/password
  /// 2. Verificar que email no exista y esté confirmado
  /// 3. signUp → OTP enviado → Usuario debe verificar con verifyOTP
  Future<Result<Failure, void>> call({
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

    // Verificar si el email ya existe y está confirmado
    final checkResult = await _repository.checkEmailExistsAndConfirmed(email);

    switch (checkResult) {
      case ResultFailure(error: final failure):
        // Error al verificar (probablemente red)
        return Result.failure(failure);
      case Success(value: final exists):
        if (exists) {
          // Email ya existe y está confirmado → no permitir registro
          return Result.failure(
            const AuthFailure(
              code: ErrorCode.emailAlreadyInUse,
              technicalMessage: 'Email already registered and confirmed',
            ),
          );
        }
    }

    // Email no existe O no está confirmado → permitir registro/reenvío OTP
    return _repository.signUpWithEmail(
      email: email,
      password: password,
    );
  }
}
