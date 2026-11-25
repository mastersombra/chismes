import 'package:flutter/material.dart';

import 'error_codes.dart';
import 'failure.dart';
import 'package:chismes/core/l10n/l10n.dart';

/// Mensajes de error centralizados con i18n
///
/// Uso:
/// ```dart
/// ErrorMessages.getMessage(error.code)
/// ErrorMessages.getTitle(error.code)
/// ```
class ErrorMessages {
  ErrorMessages._();

  /// Obtiene el mensaje de error en inglés (para logs y debugging)
  /// [code] El código de error
  static String getMessageEnglish(ErrorCode code) {
    // Versión sin traducción para logs, debugging y lugares sin context
    return code.toString().replaceAll('ErrorCode.', '');
  }

  /// Obtiene el mensaje de error traducido
  /// [context] BuildContext para acceder a localizaciones
  /// [code] El código de error
  /// [params] Parámetros opcionales para el mensaje
  static String getMessage(
    BuildContext context,
    ErrorCode code, {
    Map<String, dynamic>? params,
  }) {
    switch (code) {
      // Errores de red
      case ErrorCode.networkError:
        return context.l10n.errorsNetworkConnectionError;
      case ErrorCode.timeoutError:
        return context.l10n.errorsNetworkTimeout;
      case ErrorCode.noInternetConnection:
        return context.l10n.errorsNetworkNoInternet;

      // Errores de servidor
      case ErrorCode.serverError:
        return context.l10n.errorsServerError;
      case ErrorCode.serverMaintenance:
        return context.l10n.errorsServerMaintenance;
      case ErrorCode.serviceUnavailable:
        return context.l10n.errorsServerUnavailable;
      case ErrorCode.tooManyRequests:
        return params?['message'] as String? ??
            context.l10n.errorsServerTooManyRequests;
      case ErrorCode.badRequest:
        return context.l10n.errorsServerBadRequest;

      // Errores de autenticación
      case ErrorCode.unauthorized:
        return context.l10n.errorsAuthUnauthorized;
      case ErrorCode.sessionExpired:
        return context.l10n.errorsAuthSessionExpired;
      case ErrorCode.invalidCredentials:
        return context.l10n.errorsAuthInvalidCredentials;
      case ErrorCode.emailAlreadyInUse:
        return context.l10n.errorsAuthEmailAlreadyInUse;
      case ErrorCode.weakPassword:
        return context.l10n.errorsAuthWeakPassword;
      case ErrorCode.userNotFound:
        return context.l10n.errorsAuthUserNotFound;
      case ErrorCode.userNotAuthenticated:
        return context.l10n.errorsAuthNotAuthenticated;
      case ErrorCode.usernameAlreadyTaken:
        return context.l10n.errorsAuthUsernameTaken;
      case ErrorCode.invalidToken:
        return context.l10n.errorsAuthInvalidToken;
      case ErrorCode.expiredToken:
        return context.l10n.errorsAuthExpiredToken;
      case ErrorCode.oauthCancelled:
        return context.l10n.errorsAuthOauthCancelled;
      case ErrorCode.oauthProviderError:
        return context.l10n.errorsAuthOauthProviderError;
      case ErrorCode.emailNotVerified:
        return context.l10n.errorsAuthEmailNotVerified;
      case ErrorCode.tooManyLoginAttempts:
        return context.l10n.errorsAuthTooManyAttempts;

      // Errores de validación
      case ErrorCode.validationError:
        return context.l10n.errorsValidationError;
      case ErrorCode.invalidInput:
        return context.l10n.errorsValidationInvalidInput;
      case ErrorCode.missingRequiredField:
        return context.l10n.errorsValidationMissingField;

      // Errores de datos
      case ErrorCode.notFound:
        return context.l10n.errorsDataNotFound;
      case ErrorCode.alreadyExists:
        return context.l10n.errorsDataAlreadyExists;
      case ErrorCode.conflict:
        return context.l10n.errorsDataConflict;

      // Errores de permisos
      case ErrorCode.forbidden:
        return context.l10n.errorsPermissionsForbidden;
      case ErrorCode.insufficientPermissions:
        return context.l10n.errorsPermissionsInsufficient;

      // Errores de negocio específicos
      case ErrorCode.invalidLocation:
        return context.l10n.errorsBusinessInvalidLocation;
      case ErrorCode.invalidGossipContent:
        return context.l10n.errorsBusinessInvalidGossipContent;
      case ErrorCode.gossipNotFound:
        return context.l10n.errorsBusinessGossipNotFound;
      case ErrorCode.moderationRejected:
        return context.l10n.errorsBusinessModerationRejected;
      case ErrorCode.mediaUploadFailed:
        return context.l10n.errorsBusinessMediaUploadFailed;
      case ErrorCode.rateLimitExceeded:
        return params?['message'] as String? ??
            context.l10n.errorsBusinessRateLimitExceeded;
      case ErrorCode.accountRestricted:
        return context.l10n.errorsAccountRestricted;
      case ErrorCode.accountSuspended:
        return context.l10n.errorsAccountSuspended;
      case ErrorCode.usernameChangeCooldown:
        return context.l10n.errorsUsernameChangeCooldown;
      case ErrorCode.usernameReserved:
        return context.l10n.errorsUsernameReserved;
      case ErrorCode.moderationUnavailable:
        return context.l10n.errorsModerationUnavailable;
      case ErrorCode.invalidImage:
        return context.l10n.errorsInvalidImage;
      case ErrorCode.userNotAvailable:
        return context.l10n.errorsUserNotAvailable;
      case ErrorCode.followRateLimited:
        return context.l10n.errorsFollowRateLimited;

      // Errores desconocidos
      case ErrorCode.unknownError:
        return context.l10n.errorsUnknown;
    }
  }

  /// Mensaje para un [Failure] concreto: usa los datos que trae (fecha de
  /// fin de una restricción, mensaje del servidor) y si no, el del código
  static String forFailure(BuildContext context, Failure failure) {
    if (failure is AccountRestrictedFailure &&
        failure.code == ErrorCode.accountRestricted &&
        failure.restrictedUntil != null) {
      final local = failure.restrictedUntil!.toLocal();
      final material = MaterialLocalizations.of(context);
      final date = '${material.formatShortDate(local)} · '
          '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
      return context.l10n.errorsAccountRestrictedUntil(date);
    }
    if (failure is UsernameCooldownFailure && failure.availableAt != null) {
      final date = MaterialLocalizations.of(context)
          .formatMediumDate(failure.availableAt!.toLocal());
      return context.l10n.errorsUsernameChangeCooldownUntil(date);
    }
    if (failure is ServerFailure && failure.message != null) return failure.message!;
    if (failure is RateLimitFailure && failure.message != null) return failure.message!;
    return getMessage(context, failure.code);
  }

  /// Obtiene el título del error para mostrar en diálogos
  /// [context] BuildContext para acceder a localizaciones
  static String getTitle(BuildContext context, ErrorCode code) {
    switch (code) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
      case ErrorCode.noInternetConnection:
        return context.l10n.errorsTitlesConnection;
      case ErrorCode.serverError:
      case ErrorCode.serverMaintenance:
      case ErrorCode.serviceUnavailable:
      case ErrorCode.tooManyRequests:
      case ErrorCode.badRequest:
        return context.l10n.errorsTitlesServer;
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
        return context.l10n.errorsTitlesAuth;
      case ErrorCode.validationError:
      case ErrorCode.invalidInput:
      case ErrorCode.missingRequiredField:
        return context.l10n.errorsTitlesValidation;
      case ErrorCode.notFound:
      case ErrorCode.alreadyExists:
      case ErrorCode.conflict:
        return context.l10n.errorsTitlesData;
      case ErrorCode.forbidden:
      case ErrorCode.insufficientPermissions:
        return context.l10n.errorsTitlesPermissions;
      case ErrorCode.invalidLocation:
      case ErrorCode.invalidGossipContent:
      case ErrorCode.gossipNotFound:
      case ErrorCode.moderationRejected:
      case ErrorCode.mediaUploadFailed:
      case ErrorCode.rateLimitExceeded:
      case ErrorCode.accountRestricted:
      case ErrorCode.accountSuspended:
      case ErrorCode.usernameChangeCooldown:
      case ErrorCode.usernameReserved:
      case ErrorCode.moderationUnavailable:
      case ErrorCode.invalidImage:
      case ErrorCode.userNotAvailable:
      case ErrorCode.followRateLimited:
        return context.l10n.errorsTitlesGeneral;
      case ErrorCode.unknownError:
        return context.l10n.errorsTitlesUnexpected;
    }
  }
}
