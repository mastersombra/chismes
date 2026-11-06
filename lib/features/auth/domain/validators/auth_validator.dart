import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/localization/app_localizations.dart';

/// Validador de reglas de negocio para autenticación
///
/// Este validador contiene la lógica de validación del dominio (business rules).
/// NO es para validación de UI (usar FormValidators para eso).
///
/// Diferencias con FormValidators:
/// - FormValidators: Validación de UI (TextFormField)
/// - AuthValidator: Validación de negocio (casos de uso, repository)
///
/// Ambos son necesarios:
/// 1. FormValidators valida en UI (UX inmediata)
/// 2. AuthValidator valida en domain (seguridad y consistencia)
class AuthValidator {
  AuthValidator._();

  // =====================================================
  // EMAIL
  // =====================================================

  /// Valida formato de email según RFC 5322 (simplificado)
  static ValidationFailure? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: AppLocalizations.emailRequired,
      );
    }

    // Patrón simplificado pero robusto
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.emailInvalid,
      );
    }

    if (email.length > 254) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.emailTooLong,
      );
    }

    return null;
  }

  // =====================================================
  // PASSWORD
  // =====================================================

  /// Valida fortaleza de contraseña
  ///
  /// Reglas:
  /// - Mínimo 8 caracteres
  /// - Máximo 128 caracteres
  /// - Al menos una letra minúscula
  /// - Al menos una letra mayúscula
  /// - Al menos un número
  /// - Al menos un carácter especial
  static ValidationFailure? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: AppLocalizations.passwordRequired,
      );
    }

    if (password.length < 8) {
      return ValidationFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: AppLocalizations.passwordTooShort,
      );
    }

    if (password.length > 128) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.passwordTooLong,
      );
    }

    // Al menos una minúscula
    if (!password.contains(RegExp(r'[a-z]'))) {
      return ValidationFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: AppLocalizations.passwordNeedsLowercase,
      );
    }

    // Al menos una mayúscula
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return ValidationFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: AppLocalizations.passwordNeedsUppercase,
      );
    }

    // Al menos un número
    if (!password.contains(RegExp(r'[0-9]'))) {
      return ValidationFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: AppLocalizations.passwordNeedsNumber,
      );
    }

    // Al menos un carácter especial
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;~`]'))) {
      return ValidationFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: AppLocalizations.passwordNeedsSpecial,
      );
    }

    return null;
  }

  /// Calcula la fortaleza de una contraseña (0-100)
  ///
  /// Útil para mostrar indicador visual de fortaleza.
  ///
  /// Returns:
  /// - 0-33: Débil
  /// - 34-66: Media
  /// - 67-100: Fuerte
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Longitud (max 30 puntos)
    if (password.length >= 8) strength += 10;
    if (password.length >= 12) strength += 10;
    if (password.length >= 16) strength += 10;

    // Caracteres (max 70 puntos)
    if (password.contains(RegExp(r'[a-z]'))) strength += 15; // Minúsculas
    if (password.contains(RegExp(r'[A-Z]'))) strength += 15; // Mayúsculas
    if (password.contains(RegExp(r'[0-9]'))) strength += 15; // Números
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;~`]'))) {
      strength += 15; // Especiales
    }

    // Diversidad (max 20 puntos)
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= 8) strength += 10;
    if (uniqueChars >= 12) strength += 10;

    return strength.clamp(0, 100);
  }

  /// Retorna el nivel de fortaleza de una contraseña
  static PasswordStrength getPasswordStrengthLevel(String password) {
    final strength = calculatePasswordStrength(password);
    if (strength < 34) return PasswordStrength.weak;
    if (strength < 67) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  // =====================================================
  // USERNAME
  // =====================================================

  /// Valida formato de username
  ///
  /// Reglas:
  /// - Mínimo 3 caracteres
  /// - Máximo 30 caracteres
  /// - Solo letras minúsculas, números y guión bajo
  /// - No puede empezar con número
  /// - No puede empezar o terminar con guión bajo
  static ValidationFailure? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: AppLocalizations.usernameRequired,
      );
    }

    if (username.length < 3) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.usernameTooShort,
      );
    }

    if (username.length > 30) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.usernameTooLong,
      );
    }

    // Solo minúsculas, números y guión bajo
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.usernameInvalidChars,
      );
    }

    // No puede empezar con número
    if (RegExp(r'^[0-9]').hasMatch(username)) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.usernameStartsWithNumber,
      );
    }

    // No puede empezar o terminar con guión bajo
    if (username.startsWith('_') || username.endsWith('_')) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.usernameInvalidUnderscore,
      );
    }

    // Palabras reservadas
    const reservedWords = [
      'admin',
      'root',
      'system',
      'chismes',
      'support',
      'help',
      'anonymous',
      'user',
      'guest',
    ];

    if (reservedWords.contains(username.toLowerCase())) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.usernameReserved,
      );
    }

    return null;
  }

  // =====================================================
  // DISPLAY NAME
  // =====================================================

  /// Valida display name
  ///
  /// Reglas:
  /// - Mínimo 1 carácter
  /// - Máximo 50 caracteres
  static ValidationFailure? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: AppLocalizations.displayNameRequired,
      );
    }

    final trimmed = displayName.trim();

    if (trimmed.isEmpty) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.displayNameEmpty,
      );
    }

    if (trimmed.length > 50) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.displayNameTooLong,
      );
    }

    return null;
  }

  // =====================================================
  // BIO
  // =====================================================

  /// Valida biografía
  ///
  /// Reglas:
  /// - Máximo 160 caracteres
  static ValidationFailure? validateBio(String? bio) {
    if (bio == null || bio.isEmpty) {
      return null; // Bio es opcional
    }

    if (bio.length > 160) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: AppLocalizations.bioTooLong,
      );
    }

    return null;
  }
}

/// Nivel de fortaleza de contraseña
enum PasswordStrength {
  weak,
  medium,
  strong,
}
