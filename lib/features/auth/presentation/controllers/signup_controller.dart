import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/error_codes.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../state/auth_state.dart';

/// Controller para la pantalla de registro
///
/// Maneja el registro de nuevos usuarios con email y contraseña.
@injectable
class SignupController extends ChangeNotifier {
  final SignUpWithEmailUseCase _signUpWithEmail;
  final AppLogger _logger;

  SignupController(
    this._signUpWithEmail,
    this._logger,
  );

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Registra un nuevo usuario con email y contraseña
  ///
  /// Envía código OTP al email del usuario.
  /// Al completarse, el estado cambia a AuthOtpSent.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _setState(const AuthLoading());

    _logger.i('Sign up attempt', context: {'email': email});

    final result = await _signUpWithEmail(
      email: email,
      password: password,
    );

    switch (result) {
      case ResultFailure(error: final failure):
        _logger.w('Sign up failed',
            error: failure, context: {'email': email, 'code': failure.code});

        // Personalizar mensaje si el email ya está en uso
        if (failure.code == ErrorCode.emailAlreadyInUse) {
          _setState(const AuthError.custom(
            'Este email ya está registrado. Inicia sesión en su lugar.',
          ));
        } else {
          _setState(AuthError(failure));
        }
      case Success():
        _logger.i('Sign up successful, OTP sent', context: {'email': email});
        _setState(AuthOtpSent(email));
    }
  }

  /// Resetea el estado a inicial
  void resetState() {
    _setState(const AuthInitial());
  }
}
