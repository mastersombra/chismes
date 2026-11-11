import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

/// Gestiona el locale actual de la aplicación
///
/// Usa ChangeNotifier para notificar cambios y SharedPreferences para persistencia.
/// Registrado en GetIt como singleton.
///
/// Uso:
/// ```dart
/// // En main.dart con ListenableBuilder
/// final localeNotifier = getIt<LocaleNotifier>();
///
/// // Para cambiar idioma
/// localeNotifier.setLocale(const Locale('en'));
/// ```
@singleton
class LocaleNotifier extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  final SharedPreferences _prefs;

  Locale _locale;

  LocaleNotifier(this._prefs) : _locale = _loadInitialLocale(_prefs);

  /// Locale actual
  Locale get locale => _locale;

  /// Carga el locale inicial desde SharedPreferences
  static Locale _loadInitialLocale(SharedPreferences prefs) {
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      return Locale(savedLocale);
    }
    // Default: español
    return const Locale('es');
  }

  /// Cambia el locale y persiste el cambio
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    await _prefs.setString(_localeKey, newLocale.languageCode);
    notifyListeners();
  }

  /// Idiomas soportados
  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];
}
