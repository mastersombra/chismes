import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'error_codes.dart';

/// Failure representa un error en el dominio de negocio
/// A diferencia de Exception, Failure es un objeto de valor que puede ser
/// pasado entre capas sin lanzar excepciones
/// 
/// code: Código de error independiente del idioma
/// technicalMessage: Mensaje técnico opcional para debugging/logging (no mostrar al usuario)
/// La UI debe usar ErrorMessages.getMessage(code) o AppLocalizations para obtener el mensaje apropiado
class Failure extends Equatable {
  final ErrorCode code;
  final String? technicalMessage;

  const Failure({
    required this.code,
    this.technicalMessage,
  });

  @override
  List<Object?> get props => [code, technicalMessage];

  @override
  String toString() {
    return 'Failure: $code${technicalMessage != null ? ' - $technicalMessage' : ''}';
  }
}

/// Failures específicos para cada tipo de error
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.code,
    super.technicalMessage,
  });
}

class ServerFailure extends Failure {
  /// Mensaje opcional del servidor (user-friendly)
  /// Ejemplo: "Has alcanzado el límite de 10 chismes por hora"
  final String? message;

  const ServerFailure({
    required super.code,
    super.technicalMessage,
    this.message,
  });

  @override
  List<Object?> get props => [code, technicalMessage, message];
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.code,
    super.technicalMessage,
  });
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.code,
    super.technicalMessage,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [
        code,
        technicalMessage,
        fieldErrors != null ? UnmodifiableMapView(fieldErrors!) : null,
      ];
}

class DataFailure extends Failure {
  const DataFailure({
    required super.code,
    super.technicalMessage,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.code,
    super.technicalMessage,
  });
}

class RateLimitFailure extends Failure {
  /// Mensaje del servidor (user-friendly)
  /// Ejemplo: "Has alcanzado el límite de 10 chismes por hora. Espera 45 minutos."
  final String? message;

  /// Segundos hasta que se pueda reintentar
  final int? retryAfter;

  const RateLimitFailure({
    required super.code,
    super.technicalMessage,
    this.message,
    this.retryAfter,
  });

  @override
  List<Object?> get props => [code, technicalMessage, message, retryAfter];
}

/// La cuenta tiene una sanción vigente (restricción o suspensión) y el
/// servidor no la deja publicar ni reportar (`403 account_restricted`).
///
/// code: [ErrorCode.accountRestricted] o [ErrorCode.accountSuspended]
class AccountRestrictedFailure extends Failure {
  /// Fin de la restricción (null en una suspensión: es indefinida)
  final DateTime? restrictedUntil;

  const AccountRestrictedFailure({
    required super.code,
    super.technicalMessage,
    this.restrictedUntil,
  });

  /// Desde el body del 403 (`{ code, state, restricted_until }`), o null si
  /// no es una respuesta de cuenta restringida
  static AccountRestrictedFailure? fromResponse(int status, dynamic details) {
    if (status != 403 || details is! Map || details['code'] != 'account_restricted') {
      return null;
    }
    final until = details['restricted_until'];
    return AccountRestrictedFailure(
      code: details['state'] == 'suspended' ? ErrorCode.accountSuspended : ErrorCode.accountRestricted,
      technicalMessage: 'account ${details['state']}',
      restrictedUntil: until is String ? DateTime.tryParse(until) : null,
    );
  }

  @override
  List<Object?> get props => [code, technicalMessage, restrictedUntil];
}
