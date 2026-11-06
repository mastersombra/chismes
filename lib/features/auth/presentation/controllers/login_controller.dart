import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../state/auth_state.dart';

/// Controller para la pantalla de login
///
/// Maneja las acciones de inicio de sesión:
/// - Email + Password
/// - Google OAuth
/// - Apple OAuth
@injectable
class LoginController extends ChangeNotifier {
  final SignInWithEmailUseCase _signInWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;
  final ResetPasswordUseCase _resetPassword;
  final AppLogger _logger;

  LoginController(
    this._signInWithEmail,
    this._signInWithGoogle,
    this._signInWithApple,
    this._resetPassword,
    this._logger,
  );

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Inicia sesión con email y contraseña
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setState(const AuthLoading());

    _logger.i('Login attempt with email', context: {'email': email});

    final result = await _signInWithEmail(
      email: email,
      password: password,
    );

    result.when(
      onFailure: (failure) {
        _logger.w('Login failed',
            error: failure, context: {'email': email, 'code': failure.code});
        _setState(AuthError(failure));
      },
      onSuccess: (user) {
        _logger.i('Login successful',
            context: {'userId': user.id, 'email': user.email});
        _setState(AuthSuccess(user));
      },
    );
  }

  /// Inicia sesión con Google
  Future<void> signInWithGoogle() async {
    _setState(const AuthLoading());

    _logger.i('Google login attempt');

    final result = await _signInWithGoogle();

    result.when(
      onFailure: (failure) {
        // Si el usuario canceló, volver al estado inicial sin mostrar error
        if (failure.code == ErrorCode.oauthCancelled) {
          _logger.i('Google login cancelled by user');
          _setState(const AuthInitial());
          return;
        }

        _logger.w('Google login failed',
            error: failure, context: {'code': failure.code});
        _setState(AuthError(failure));
      },
      onSuccess: (user) {
        _logger.i('Google login successful',
            context: {'userId': user.id, 'email': user.email});
        _setState(AuthSuccess(user));
      },
    );
  }

  /// Inicia sesión con Apple
  Future<void> signInWithApple() async {
    _setState(const AuthLoading());

    _logger.i('Apple login attempt');

    final result = await _signInWithApple();

    result.when(
      onFailure: (failure) {
        _logger.w('Apple login failed',
            error: failure, context: {'code': failure.code});
        _setState(AuthError(failure));
      },
      onSuccess: (user) {
        _logger.i('Apple login successful',
            context: {'userId': user.id, 'email': user.email});
        _setState(AuthSuccess(user));
      },
    );
  }

  /// Envía código OTP para resetear contraseña
  Future<void> resetPassword({
    required String email,
  }) async {
    _setState(const AuthLoading());

    _logger.i('Reset password request', context: {'email': email});

    final result = await _resetPassword(email: email);

    result.when(
      onFailure: (failure) {
        _logger.w('Reset password failed',
            error: failure, context: {'email': email, 'code': failure.code});
        _setState(AuthError(failure));
      },
      onSuccess: (_) {
        _logger.i('Reset password OTP sent', context: {'email': email});
        _setState(AuthOtpSent(email));
      },
    );
  }

  /// Resetea el estado a inicial
  void resetState() {
    _setState(const AuthInitial());
  }
}
