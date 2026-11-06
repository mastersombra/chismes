import 'package:flutter/material.dart';

/// Helper para detectar y gestionar el idioma de la aplicación
///
/// Proporciona utilidades para obtener información sobre el idioma
/// del dispositivo y el idioma actual de la aplicación.
class LocaleDetector {
  LocaleDetector._();

  /// Obtiene el idioma del dispositivo del usuario
  ///
  /// Returns: Locale del sistema (ej: Locale('es', 'MX'))
  static Locale getDeviceLocale() {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  /// Verifica si el idioma del dispositivo es soportado
  ///
  /// [supportedLocales] Lista de locales soportados por la app
  static bool isDeviceLocalSupported(List<Locale> supportedLocales) {
    final deviceLocale = getDeviceLocale();
    return supportedLocales.any(
      (locale) => locale.languageCode == deviceLocale.languageCode,
    );
  }

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
      case 'pt':
        return 'Portuguese';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
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
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
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
      case 'pt':
        return '🇧🇷';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      default:
        return '🌐';
    }
  }

  /// Formatea un locale para debugging
  ///
  /// Returns: String legible del locale
  static String formatLocale(Locale locale) {
    final info = getLocaleInfo(locale);
    return '${info['emoji']} ${info['nativeName']} (${info['languageCode']})';
  }
}
