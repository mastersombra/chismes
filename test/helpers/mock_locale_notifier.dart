import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crea un LocaleNotifier para tests sin necesitar SharedPreferences real
///
/// Esta función crea una instancia real de LocaleNotifier pero con un
/// SharedPreferences mock, por lo que es 100% compatible con el código de producción.
///
/// Uso:
/// ```dart
/// // En setUp() del test
/// final localeNotifier = await createMockLocaleNotifier();
/// getIt.registerSingleton<LocaleNotifier>(localeNotifier);
///
/// // Opcional: cambiar locale en el test
/// await localeNotifier.setLocale(const Locale('en'));
/// ```
Future<LocaleNotifier> createMockLocaleNotifier({
  Locale initialLocale = const Locale('es'),
}) async {
  // Configurar SharedPreferences mock con el locale inicial
  SharedPreferences.setMockInitialValues({
    'app_locale': initialLocale.languageCode,
  });

  final prefs = await SharedPreferences.getInstance();
  return LocaleNotifier(prefs);
}

/// Versión sincrónica para casos donde ya tienes SharedPreferences
///
/// Útil cuando ya configuraste SharedPreferences.setMockInitialValues
/// en otro lugar del test.
LocaleNotifier createMockLocaleNotifierSync(SharedPreferences prefs) {
  return LocaleNotifier(prefs);
}
