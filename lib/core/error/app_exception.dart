import 'error_codes.dart';

/// Excepción base para toda la aplicación
/// Todas las excepciones específicas deben extender esta clase
/// 
/// technicalMessage: Mensaje técnico para debugging/logging (no mostrar al usuario)
abstract class AppException implements Exception {
  final ErrorCode code;
  final String? technicalMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.code,
    this.technicalMessage,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppException: $code${technicalMessage != null ? ' - $technicalMessage' : ''}';
  }
}

/// Excepciones de red
class NetworkException extends AppException {
  const NetworkException({
    required super.code,
    super.technicalMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Excepciones de servidor
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.code,
    super.technicalMessage,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Excepciones de autenticación
class AuthException extends AppException {
  const AuthException({
    required super.code,
    super.technicalMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Excepciones de validación
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.code,
    super.technicalMessage,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });
}

/// Excepciones de datos
class DataException extends AppException {
  const DataException({
    required super.code,
    super.technicalMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Excepciones de permisos
class PermissionException extends AppException {
  const PermissionException({
    required super.code,
    super.technicalMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Excepción genérica para errores desconocidos
/// Se usa cuando no se puede identificar un tipo específico de excepción
class UnknownException extends AppException {
  const UnknownException({
    required super.code,
    super.technicalMessage,
    super.originalError,
    super.stackTrace,
  });
}
