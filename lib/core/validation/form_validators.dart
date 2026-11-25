import 'package:flutter/material.dart';
import 'package:chismes/core/l10n/l10n.dart';

/// Helpers de validación para Flutter Form validators
///
/// Centraliza la lógica de validación de campos requeridos para
/// evitar duplicación entre UI validators y domain validators.
///
/// Uso:
/// ```dart
/// TextFormField(
///   validator: (v) => FormValidators.required(context, v, 'un país'),
/// )
/// ```
class FormValidators {
  /// Validador de campo requerido
  ///
  /// Retorna el mensaje de error si el valor es null o vacío
  static String? required(BuildContext context, String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return context.l10n.commonSelect(fieldName);
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
  static String? minLength(BuildContext context, String? value, int minChars) {
    if (value != null && value.length < minChars) {
      return context.l10n.commonMinLength(minChars.toString());
    }
    return null;
  }

  /// Validador de longitud máxima
  ///
  /// Retorna error si el valor excede maxChars
  static String? maxLength(BuildContext context, String? value, int maxChars) {
    if (value != null && value.length > maxChars) {
      return context.l10n.commonMaxLength(maxChars.toString());
    }
    return null;
  }

  /// Validador de email (básico)
  ///
  /// Valida formato de email simple.
  /// Los emails se normalizan a minúsculas para evitar duplicados.
  static String? email(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.commonEnterEmail;
    }

    // Normalizar a minúsculas (los emails son case-insensitive)
    final normalizedEmail = value.toLowerCase().trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      return context.l10n.commonEmailInvalid;
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
  static String? password(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.commonEnterPassword;
    }
    return null;
  }

  /// Validador de @usuario: 3-30 caracteres, minúsculas, números o "_".
  /// Mismas reglas que AuthValidator (dominio) y update-profile (servidor).
  static String? username(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return context.l10n.usernameRequired;
    if (value.length < 3) return context.l10n.usernameTooShort;
    if (value.length > 30) return context.l10n.usernameTooLong;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
      return context.l10n.usernameInvalidChars;
    }
    return null;
  }
}
