import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema elegido por el usuario: Sistema (por defecto), Claro u Oscuro.
///
/// Preferencia del teléfono (SharedPreferences), como el idioma
/// (LocaleNotifier): no se guarda en el servidor.
@singleton
class ThemeModeNotifier extends ChangeNotifier {
  static const String _key = 'app_theme_mode';
  final SharedPreferences _prefs;

  ThemeMode _mode;

  ThemeModeNotifier(this._prefs) : _mode = _load(_prefs);

  ThemeMode get mode => _mode;

  static ThemeMode _load(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs.setString(_key, mode.name);
    notifyListeners();
  }
}
