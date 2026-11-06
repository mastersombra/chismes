import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'app_exception.dart';
import 'failure.dart';
import 'error_codes.dart';

/// Convierte excepciones en objetos Failure del dominio
/// Centraliza la lógica de conversión de errores
///
/// ⚠️ SIMPLIFICACIÓN FUTURA RECOMENDADA:
///
/// Actualmente hay una pequeña sobrearquitectura con conversión bidireccional:
///
/// AppException → ErrorHandler → Failure
/// Failure → ErrorHandler → AppException
///
/// Para el flujo de agregar chisme (y en general), simplificar a:
///
/// DataSource
///   ↓
/// throws exception
///   ↓
/// Repository (convierte a Failure)
///   ↓
/// UseCase (usa Failure)
///   ↓
/// Controller (usa Failure)
///
/// El dominio no debería estar lanzando y reconstruyendo excepciones continuamente.
///
/// Solo el DataSource lanza excepciones, el Repository las convierte a Failure,
/// y el resto del flujo usa Failure directamente sin reconversión.
class ErrorHandler {
  ErrorHandler._();

  /// Convierte cualquier excepción a un Failure
  static Failure handleError(dynamic error, [StackTrace? stackTrace]) {
    // Si ya es una AppException, convertirla directamente
    if (error is AppException) {
      return _exceptionToFailure(error);
    }

    // Si ya es un Failure, retornarlo tal cual
    if (error is Failure) {
      return error;
    }

    // Manejar excepciones comunes de Dart/Flutter
    if (error is SocketException) {
      return const NetworkFailure(
        code: ErrorCode.noInternetConnection,
      );
    }

    if (error is HttpException) {
      return ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: error.message, // Mensaje técnico de la excepción original
      );
    }

    if (error is FormatException) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: error.message, // Mensaje técnico de la excepción original
      );
    }

    // Manejar PlatformException (Google Sign-In cancelaciones)
    if (error is PlatformException) {
      // Google Sign-In cancelado por el usuario
      // access_denied está en 'details', no en 'message'
      if (error.code == 'sign_in_failed' && error.details == 'access_denied') {
        return const AuthFailure(code: ErrorCode.oauthCancelled);
      }
    }

    // Intentar manejar errores específicos de Supabase
    final supabaseError = _handleSupabaseError(error);
    if (supabaseError != null) {
      return supabaseError;
    }

    // Para cualquier otro error, loggearlo y retornar error desconocido
    if (kDebugMode) {
      debugPrint('Unhandled error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Preservar el mensaje técnico del error si existe
    final errorMessage = error.toString();
    return Failure(
      code: ErrorCode.unknownError,
      technicalMessage: errorMessage.isNotEmpty ? errorMessage : null,
    );
  }

  /// Maneja errores específicos de Supabase usando códigos estructurados
  ///
  /// ✅ IMPLEMENTACIÓN ROBUSTA:
  ///
  /// Usa type-safe handling con tipos específicos de excepciones de Supabase:
  /// - AuthException (GoTrue auth errors)
  /// - PostgrestException (Database/REST API errors)
  /// - StorageException (Storage errors)
  ///
  /// Cada excepción provee:
  /// - statusCode: Código HTTP estructurado ('400', '401', '403', etc.)
  /// - message: Mensaje descriptivo del error
  ///
  /// **Ventajas sobre string matching:**
  /// - ✅ Type-safe (if (error is AuthException))
  /// - ✅ Usa códigos HTTP estables
  /// - ✅ No se rompe con cambios en mensajes
  /// - ✅ Autocomplete en IDE
  /// - ✅ Fácil de testear
  ///
  /// **Ejemplo:**
  /// ```dart
  /// if (error is AuthException) {
  ///   switch (error.statusCode) {
  ///     case '403': return PermissionFailure(...);
  ///     case '404': return DataFailure(...);
  ///   }
  /// }
  /// ```
  static Failure? _handleSupabaseError(dynamic error) {
    // Manejo type-safe de Auth errors (GoTrue)
    if (error is supabase.AuthException) {
      return _handleAuthException(error);
    }

    // Manejo type-safe de Database errors (PostgreSQL)
    if (error is supabase.PostgrestException) {
      return _handlePostgrestException(error);
    }

    // Manejo type-safe de Storage errors
    if (error is supabase.StorageException) {
      return _handleStorageException(error);
    }

    // No es un error de Supabase
    return null;
  }

  /// Maneja errores de autenticación de Supabase (GoTrue)
  static Failure _handleAuthException(supabase.AuthException error) {
    final statusCode = error.statusCode;
    final message = error.message;

    // Detectar cancelación de OAuth (no es un error real)
    if (message.toLowerCase().contains('oauth_cancelled') ||
        message.toLowerCase().contains('cancelled')) {
      return const AuthFailure(code: ErrorCode.oauthCancelled);
    }

    switch (statusCode) {
      case '400': // Bad request
        if (message.toLowerCase().contains('invalid login credentials')) {
          return const AuthFailure(code: ErrorCode.invalidCredentials);
        }
        if (message.toLowerCase().contains('email not confirmed')) {
          return ValidationFailure(
            code: ErrorCode.validationError,
            technicalMessage: 'Email no confirmado',
          );
        }
        // Detectar token/código expirado
        if (message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('expirado')) {
          return AuthFailure(
            code: ErrorCode.expiredToken,
            technicalMessage: message,
          );
        }
        // Detectar token/código inválido
        if (message.toLowerCase().contains('invalid') ||
            message.toLowerCase().contains('inválido') ||
            message.toLowerCase().contains('token') ||
            message.toLowerCase().contains('code')) {
          return AuthFailure(
            code: ErrorCode.invalidToken,
            technicalMessage: message,
          );
        }
        return ValidationFailure(
          code: ErrorCode.badRequest,
          technicalMessage: message,
        );

      case '401': // Unauthorized
        // Detectar token expirado
        if (message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('expirado')) {
          return AuthFailure(
            code: ErrorCode.expiredToken,
            technicalMessage: message,
          );
        }
        // Detectar token inválido
        if (message.toLowerCase().contains('invalid') ||
            message.toLowerCase().contains('token') ||
            message.toLowerCase().contains('code')) {
          return AuthFailure(
            code: ErrorCode.invalidToken,
            technicalMessage: message,
          );
        }
        return AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: message,
        );

      case '403': // Forbidden
        // Detectar token/código expirado (Supabase usa 403 para OTP expirado)
        if (message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('expirado')) {
          return AuthFailure(
            code: ErrorCode.expiredToken,
            technicalMessage: message,
          );
        }
        // Detectar token/código inválido
        if (message.toLowerCase().contains('invalid') ||
            message.toLowerCase().contains('token') ||
            message.toLowerCase().contains('code')) {
          return AuthFailure(
            code: ErrorCode.invalidToken,
            technicalMessage: message,
          );
        }
        return PermissionFailure(
          code: ErrorCode.forbidden,
          technicalMessage: message,
        );

      case '404': // Not found
        return AuthFailure(
          code: ErrorCode.notFound,
          technicalMessage: message,
        );

      case '422': // Unprocessable entity (validation error)
        if (message.toLowerCase().contains('already registered') ||
            message.toLowerCase().contains('already exists')) {
          return const ValidationFailure(code: ErrorCode.alreadyExists);
        }
        return ValidationFailure(
          code: ErrorCode.validationError,
          technicalMessage: message,
        );

      case '429': // Too many requests (rate limit)
        return ServerFailure(
          code: ErrorCode.tooManyRequests,
          technicalMessage: message,
        );

      case '500': // Internal server error
      case '502': // Bad gateway
      case '503': // Service unavailable
        return ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: message,
        );

      default:
        return AuthFailure(
          code: ErrorCode.unknownError,
          technicalMessage: message,
        );
    }
  }

  /// Maneja errores de PostgreSQL (Database/REST API)
  static Failure _handlePostgrestException(supabase.PostgrestException error) {
    final code = error.code;
    final message = error.message;

    // PostgreSQL error codes: https://www.postgresql.org/docs/current/errcodes-appendix.html
    switch (code) {
      case '23505': // unique_violation
        return DataFailure(
          code: ErrorCode.alreadyExists,
          technicalMessage: message,
        );

      case '23503': // foreign_key_violation
        return ValidationFailure(
          code: ErrorCode.conflict,
          technicalMessage: message,
        );

      case '42P01': // undefined_table
      case '42703': // undefined_column
        return DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: message,
        );

      case 'PGRST116': // Row not found
        return DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: message,
        );

      case 'PGRST301': // Permission denied
        return PermissionFailure(
          code: ErrorCode.forbidden,
          technicalMessage: message,
        );

      default:
        return ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: message,
        );
    }
  }

  /// Maneja errores de Supabase Storage
  static Failure _handleStorageException(supabase.StorageException error) {
    final statusCode = error.statusCode;
    final message = error.message;

    if (statusCode != null) {
      switch (statusCode) {
        case '400':
          return ValidationFailure(
            code: ErrorCode.badRequest,
            technicalMessage: message,
          );

        case '403':
          return PermissionFailure(
            code: ErrorCode.forbidden,
            technicalMessage: message,
          );

        case '404':
          return DataFailure(
            code: ErrorCode.notFound,
            technicalMessage: message,
          );

        case '413': // Payload too large
          return ValidationFailure(
            code: ErrorCode.invalidInput,
            technicalMessage: 'Archivo muy grande',
          );

        default:
          return ServerFailure(
            code: ErrorCode.serverError,
            technicalMessage: message,
          );
      }
    }

    return ServerFailure(
      code: ErrorCode.serverError,
      technicalMessage: message,
    );
  }

  /// Convierte una AppException específica a su Failure correspondiente
  static Failure _exceptionToFailure(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(
        code: exception.code,
        technicalMessage: exception.technicalMessage,
      );
    }

    if (exception is ServerException) {
      return ServerFailure(
        code: exception.code,
        technicalMessage: exception.technicalMessage,
      );
    }

    if (exception is AuthException) {
      return AuthFailure(
        code: exception.code,
        technicalMessage: exception.technicalMessage,
      );
    }

    if (exception is ValidationException) {
      return ValidationFailure(
        code: exception.code,
        technicalMessage: exception.technicalMessage,
        fieldErrors: exception.fieldErrors,
      );
    }

    if (exception is DataException) {
      return DataFailure(
        code: exception.code,
        technicalMessage: exception.technicalMessage,
      );
    }

    if (exception is PermissionException) {
      return PermissionFailure(
        code: exception.code,
        technicalMessage: exception.technicalMessage,
      );
    }

    // Para cualquier otra excepción (incluyendo UnknownException)
    return Failure(
      code: exception.code,
      technicalMessage: exception.technicalMessage,
    );
  }

  /// Lanza una AppException desde un Failure (útil para capas de datos)
  static AppException throwException(Failure failure) {
    if (failure is NetworkFailure) {
      return NetworkException(
        code: failure.code,
        technicalMessage: failure.technicalMessage,
      );
    }

    if (failure is ServerFailure) {
      return ServerException(
        code: failure.code,
        technicalMessage: failure.technicalMessage,
      );
    }

    if (failure is AuthFailure) {
      return AuthException(
        code: failure.code,
        technicalMessage: failure.technicalMessage,
      );
    }

    if (failure is ValidationFailure) {
      return ValidationException(
        code: failure.code,
        technicalMessage: failure.technicalMessage,
        fieldErrors: failure.fieldErrors,
      );
    }

    if (failure is DataFailure) {
      return DataException(
        code: failure.code,
        technicalMessage: failure.technicalMessage,
      );
    }

    if (failure is PermissionFailure) {
      return PermissionException(
        code: failure.code,
        technicalMessage: failure.technicalMessage,
      );
    }

    // Para cualquier otro failure (incluyendo Failure genérico)
    return UnknownException(
      code: failure.code,
      technicalMessage: failure.technicalMessage,
    );
  }
}
