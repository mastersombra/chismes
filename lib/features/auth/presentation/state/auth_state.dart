import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';

/// Estado de autenticación para controllers de UI
///
/// Representa los diferentes estados por los que pasa
/// una operación de autenticación.
sealed class AuthState {
  const AuthState();
}

/// Estado inicial (sin acción)
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga (operación en proceso)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado de éxito con usuario autenticado
class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess(this.user);
}

/// Estado cuando OTP fue enviado al email
class AuthOtpSent extends AuthState {
  final String email;

  const AuthOtpSent(this.email);
}

/// Estado cuando contraseña fue actualizada exitosamente
class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated();
}

/// Estado de error
class AuthError extends AuthState {
  final Failure? failure;
  final String? customMessage;

  const AuthError(this.failure) : customMessage = null;

  /// Constructor para mensaje personalizado
  const AuthError.custom(String message)
      : failure = null,
        customMessage = message;

  /// Obtiene mensaje para mostrar al usuario
  String get message {
    if (customMessage != null) return customMessage!;
    if (failure != null) return ErrorMessages.getMessage(failure!.code);
    return 'Error desconocido';
  }
}

/// Estado cuando usuario no está autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
