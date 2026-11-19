import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_locale_notifier.dart';

/// Helper centralizado para configurar Dependency Injection en tests
///
/// Este helper registra todas las dependencias globales necesarias para que
/// los widgets se puedan renderizar correctamente en tests.
///
/// **Uso en tests de widgets:**
/// ```dart
/// setUp(() {
///   setupTestDI();
/// });
///
/// tearDown(() async {
///   await tearDownTestDI();
/// });
/// ```
///
/// **Uso en widget_test_wrapper.dart:**
/// El wrapper ya lo usa automáticamente, no necesitas llamarlo manualmente.

/// Inicializa el DI para tests con todas las dependencias globales necesarias
///
/// Registra:
/// - [LocaleNotifier] (con SharedPreferences mock) - Para el selector de idioma
/// - [SharedPreferences] (mock) - Para persistencia básica
///
/// Es idempotente: si ya está registrado, no vuelve a registrar.
///
/// NOTA: Esta función es async porque LocaleNotifier necesita SharedPreferences.
Future<void> setupTestDI({Locale initialLocale = const Locale('es')}) async {
  // LocaleNotifier - CRÍTICO para LanguageSelector
  if (!getIt.isRegistered<LocaleNotifier>()) {
    final localeNotifier = await createMockLocaleNotifier(
      initialLocale: initialLocale,
    );
    getIt.registerSingleton<LocaleNotifier>(localeNotifier);
  }

  // SharedPreferences ya fue configurado por createMockLocaleNotifier
  // pero registrarlo en GetIt por si otros servicios lo necesitan
  if (!getIt.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
  }
}

/// Limpia el DI después de los tests
///
/// Debe llamarse en tearDown() para evitar contaminación entre tests.
Future<void> tearDownTestDI() async {
  // Unregister en orden inverso al registro
  if (getIt.isRegistered<LocaleNotifier>()) {
    await getIt.unregister<LocaleNotifier>();
  }

  if (getIt.isRegistered<SharedPreferences>()) {
    await getIt.unregister<SharedPreferences>();
  }

  // Reset GetIt completamente si es necesario
  // await getIt.reset(); // Usar solo si quieres limpiar TODO
}

/// Registra SharedPreferences mock con valores iniciales
///
/// Usar cuando el test necesita SharedPreferences.
///
/// ```dart
/// setUp(() async {
///   setupTestDI();
///   await setupSharedPreferencesMock({'key': 'value'});
/// });
/// ```
Future<void> setupSharedPreferencesMock([Map<String, Object>? values]) async {
  SharedPreferences.setMockInitialValues(values ?? {});

  if (!getIt.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
  }
}

/// Verifica si el DI está correctamente inicializado para tests
///
/// Útil para debugging. Retorna true si todas las dependencias críticas
/// están registradas.
bool isTestDIReady() {
  return getIt.isRegistered<LocaleNotifier>();
}

/// Obtiene el MockLocaleNotifier para manipulación en tests
///
/// Útil cuando necesitas cambiar el locale durante un test.
///
/// ```dart
/// final localeNotifier = getTestLocaleNotifier();
/// await localeNotifier.setLocale(const Locale('en'));
/// ```
LocaleNotifier getTestLocaleNotifier() {
  if (!getIt.isRegistered<LocaleNotifier>()) {
    throw StateError(
      'LocaleNotifier no está registrado. '
      'Llama a setupTestDI() en setUp() primero.',
    );
  }
  return getIt<LocaleNotifier>();
}
