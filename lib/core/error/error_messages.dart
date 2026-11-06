import 'package:easy_localization/easy_localization.dart';

import 'error_codes.dart';

/// Mensajes de error centralizados con i18n
///
/// Uso:
/// ```dart
/// ErrorMessages.getMessage(error.code)
/// ErrorMessages.getTitle(error.code)
/// ```
class ErrorMessages {
  ErrorMessages._();

  /// Obtiene el mensaje de error para un código específico
  /// [code] El código de error
  /// [params] Parámetros opcionales para el mensaje
  static String getMessage(ErrorCode code, {Map<String, dynamic>? params}) {
    switch (code) {
      // Errores de red
      case ErrorCode.networkError:
        return 'errors.network.connection_error'.tr();
      case ErrorCode.timeoutError:
        return 'errors.network.timeout'.tr();
      case ErrorCode.noInternetConnection:
        return 'errors.network.no_internet'.tr();

      // Errores de servidor
      case ErrorCode.serverError:
        return 'errors.server.error'.tr();
      case ErrorCode.serverMaintenance:
        return 'errors.server.maintenance'.tr();
      case ErrorCode.serviceUnavailable:
        return 'errors.server.unavailable'.tr();
      case ErrorCode.tooManyRequests:
        return params?['message'] as String? ??
            'errors.server.too_many_requests'.tr();
      case ErrorCode.badRequest:
        return 'errors.server.bad_request'.tr();

      // Errores de autenticación
      case ErrorCode.unauthorized:
        return 'errors.auth.unauthorized'.tr();
      case ErrorCode.sessionExpired:
        return 'errors.auth.session_expired'.tr();
      case ErrorCode.invalidCredentials:
        return 'errors.auth.invalid_credentials'.tr();
      case ErrorCode.emailAlreadyInUse:
        return 'errors.auth.email_already_in_use'.tr();
      case ErrorCode.weakPassword:
        return 'errors.auth.weak_password'.tr();
      case ErrorCode.userNotFound:
        return 'errors.auth.user_not_found'.tr();
      case ErrorCode.userNotAuthenticated:
        return 'errors.auth.not_authenticated'.tr();
      case ErrorCode.usernameAlreadyTaken:
        return 'errors.auth.username_taken'.tr();
      case ErrorCode.invalidToken:
        return 'errors.auth.invalid_token'.tr();
      case ErrorCode.expiredToken:
        return 'errors.auth.expired_token'.tr();
      case ErrorCode.oauthCancelled:
        return 'errors.auth.oauth_cancelled'.tr();
      case ErrorCode.oauthProviderError:
        return 'errors.auth.oauth_provider_error'.tr();
      case ErrorCode.emailNotVerified:
        return 'errors.auth.email_not_verified'.tr();
      case ErrorCode.tooManyLoginAttempts:
        return 'errors.auth.too_many_attempts'.tr();

      // Errores de validación
      case ErrorCode.validationError:
        return 'errors.validation.error'.tr();
      case ErrorCode.invalidInput:
        return 'errors.validation.invalid_input'.tr();
      case ErrorCode.missingRequiredField:
        return 'errors.validation.missing_field'.tr();

      // Errores de datos
      case ErrorCode.notFound:
        return 'errors.data.not_found'.tr();
      case ErrorCode.alreadyExists:
        return 'errors.data.already_exists'.tr();
      case ErrorCode.conflict:
        return 'errors.data.conflict'.tr();

      // Errores de permisos
      case ErrorCode.forbidden:
        return 'errors.permissions.forbidden'.tr();
      case ErrorCode.insufficientPermissions:
        return 'errors.permissions.insufficient'.tr();

      // Errores de negocio específicos
      case ErrorCode.invalidLocation:
        return 'errors.business.invalid_location'.tr();
      case ErrorCode.invalidGossipContent:
        return 'errors.business.invalid_gossip_content'.tr();
      case ErrorCode.gossipNotFound:
        return 'errors.business.gossip_not_found'.tr();
      case ErrorCode.moderationRejected:
        return 'errors.business.moderation_rejected'.tr();
      case ErrorCode.mediaUploadFailed:
        return 'errors.business.media_upload_failed'.tr();
      case ErrorCode.rateLimitExceeded:
        return params?['message'] as String? ??
            'errors.business.rate_limit_exceeded'.tr();

      // Errores desconocidos
      case ErrorCode.unknownError:
        return 'errors.unknown'.tr();
    }
  }

  /// Obtiene el título del error para mostrar en diálogos
  static String getTitle(ErrorCode code) {
    switch (code) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
      case ErrorCode.noInternetConnection:
        return 'errors.titles.connection'.tr();
      case ErrorCode.serverError:
      case ErrorCode.serverMaintenance:
      case ErrorCode.serviceUnavailable:
      case ErrorCode.tooManyRequests:
      case ErrorCode.badRequest:
        return 'errors.titles.server'.tr();
      case ErrorCode.unauthorized:
      case ErrorCode.sessionExpired:
      case ErrorCode.invalidCredentials:
      case ErrorCode.emailAlreadyInUse:
      case ErrorCode.weakPassword:
      case ErrorCode.userNotFound:
      case ErrorCode.userNotAuthenticated:
      case ErrorCode.usernameAlreadyTaken:
      case ErrorCode.invalidToken:
      case ErrorCode.expiredToken:
      case ErrorCode.oauthCancelled:
      case ErrorCode.oauthProviderError:
      case ErrorCode.emailNotVerified:
      case ErrorCode.tooManyLoginAttempts:
        return 'errors.titles.auth'.tr();
      case ErrorCode.validationError:
      case ErrorCode.invalidInput:
      case ErrorCode.missingRequiredField:
        return 'errors.titles.validation'.tr();
      case ErrorCode.notFound:
      case ErrorCode.alreadyExists:
      case ErrorCode.conflict:
        return 'errors.titles.data'.tr();
      case ErrorCode.forbidden:
      case ErrorCode.insufficientPermissions:
        return 'errors.titles.permissions'.tr();
      case ErrorCode.invalidLocation:
      case ErrorCode.invalidGossipContent:
      case ErrorCode.gossipNotFound:
      case ErrorCode.moderationRejected:
      case ErrorCode.mediaUploadFailed:
      case ErrorCode.rateLimitExceeded:
        return 'errors.titles.general'.tr();
      case ErrorCode.unknownError:
        return 'errors.titles.unexpected'.tr();
    }
  }
}
