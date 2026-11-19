import 'package:flutter/material.dart';

/// Helper con información de presentación de cada idioma soportado
/// (nombre, nombre nativo y emoji), usado por `LanguageSelector`.
class LocaleDetector {
  LocaleDetector._();

  /// Obtiene información del idioma actual
  ///
  /// Returns: Map con información detallada
  static Map<String, String> getLocaleInfo(Locale locale) {
    return {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode ?? 'N/A',
      'scriptCode': locale.scriptCode ?? 'N/A',
      'displayName': _getDisplayName(locale.languageCode),
      'nativeName': _getNativeName(locale.languageCode),
      'emoji': _getEmoji(locale.languageCode),
    };
  }

  /// Obtiene el nombre del idioma en inglés
  static String _getDisplayName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Spanish';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }

  /// Obtiene el nombre del idioma en su idioma nativo
  static String _getNativeName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }

  /// Obtiene el emoji de bandera del idioma
  static String _getEmoji(String languageCode) {
    switch (languageCode) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇺🇸';
      default:
        return '🌐';
    }
  }

}
