import '../localization/app_localizations.dart';

/// Helpers de validación para Flutter Form validators
///
/// Centraliza la lógica de validación de campos requeridos para
/// evitar duplicación entre UI validators y domain validators.
///
/// Uso:
/// ```dart
/// TextFormField(
///   validator: FormValidators.required('un país'),
/// )
/// ```
class FormValidators {
  /// Validador de campo requerido
  ///
  /// Retorna el mensaje de error si el valor es null o vacío
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.select(fieldName);
    }
    return null;
  }

  /// Validador de campo requerido con mensaje personalizado
  ///
  /// Permite personalizar el mensaje de error
  static String? requiredWithMessage(String? value, String message) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }

  /// Validador de longitud mínima
  ///
  /// Retorna error si el valor es más corto que minChars
  static String? minLength(String? value, int minChars) {
    if (value != null && value.length < minChars) {
      return AppLocalizations.minLength(minChars);
    }
    return null;
  }

  /// Validador de longitud máxima
  ///
  /// Retorna error si el valor excede maxChars
  static String? maxLength(String? value, int maxChars) {
    if (value != null && value.length > maxChars) {
      return AppLocalizations.maxLength(maxChars);
    }
    return null;
  }

  /// Validador de email (básico)
  ///
  /// Valida formato de email simple.
  /// Los emails se normalizan a minúsculas para evitar duplicados.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.enterEmail;
    }

    // Normalizar a minúsculas (los emails son case-insensitive)
    final normalizedEmail = value.toLowerCase().trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      return AppLocalizations.emailInvalidCommon;
    }
    return null;
  }

  /// Normaliza un email a minúsculas y sin espacios
  ///
  /// Usar antes de enviar el email a servicios backend
  static String normalizeEmail(String email) {
    return email.toLowerCase().trim();
  }

  /// Validador de contraseña (básico para login)
  ///
  /// Solo valida que no esté vacío
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.enterPassword;
    }
    return null;
  }
}
