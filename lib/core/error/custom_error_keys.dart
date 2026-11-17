import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

/// Keys para mensajes de error personalizados con i18n
///
/// Usado cuando el mensaje no puede ser derivado directamente de un ErrorCode.
/// Cada key mapea a un mensaje traducido en AppLocalizations.
///
/// Este enum garantiza type-safety: un typo en la key resulta en error de compilación
/// en lugar de fallar silenciosamente a `errorsUnknown`.
enum CustomErrorKey {
  /// Email ya registrado, sugerir login en su lugar
  authEmailAlreadyInUseAction,

  /// Código OTP debe tener 6 dígitos
  authOtpCodeMustBe6Digits,

  /// Error genérico al cargar perfil
  profileScreenErrorLoading,

  /// Error genérico al actualizar configuración
  profileSettingsUpdateError,

  /// Error genérico al cerrar sesión
  profileSignOutError;

  /// Obtiene el mensaje traducido correspondiente a esta key
  ///
  /// [context] BuildContext para acceder a localizaciones
  String getMessage(BuildContext context) {
    switch (this) {
      case CustomErrorKey.authEmailAlreadyInUseAction:
        return context.l10n.authEmailAlreadyInUseAction;
      case CustomErrorKey.authOtpCodeMustBe6Digits:
        return context.l10n.authOtpCodeMustBe6Digits;
      case CustomErrorKey.profileScreenErrorLoading:
        return context.l10n.profileScreenErrorLoading;
      case CustomErrorKey.profileSettingsUpdateError:
        return context.l10n.profileSettingsUpdateError;
      case CustomErrorKey.profileSignOutError:
        return context.l10n.profileSignOutError;
    }
  }
}
