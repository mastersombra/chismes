import 'package:flutter/widgets.dart';

import '../../../../core/error/custom_error_keys.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
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
///
/// Guarda el ErrorCode en lugar del mensaje traducido.
/// El mensaje se obtiene en tiempo de renderizado con BuildContext.
class AuthError extends AuthState {
  final ErrorCode? errorCode;
  final CustomErrorKey? customMessageKey;

  /// Constructor desde Failure
  AuthError(Failure failure)
      : errorCode = failure.code,
        customMessageKey = null;

  /// Constructor para mensaje personalizado con key de l10n
  const AuthError.withMessageKey(CustomErrorKey messageKey)
      : errorCode = null,
        customMessageKey = messageKey;

  /// Obtiene mensaje traducido para mostrar al usuario
  ///
  /// Este método debe llamarse desde la UI que tiene BuildContext.
  String getMessage(BuildContext context) {
    // Mensaje personalizado con key
    if (customMessageKey != null) {
      return customMessageKey!.getMessage(context);
    }

    // Mensaje desde ErrorCode
    if (errorCode != null) {
      return ErrorMessages.getMessage(context, errorCode!);
    }

    // Fallback
    return context.l10n.errorsUnknown;
  }
}

/// Estado cuando usuario no está autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
