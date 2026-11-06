import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_translations_loader.dart';

/// Helper para inicializar EasyLocalization en tests
///
/// Para tests de widgets:
/// ```dart
/// testWidgets('mi test', (tester) async {
///   await tester.pumpWidget(
///     await buildTestableWidgetWithLocalization(
///       child: MyWidget(),
///     ),
///   );
/// });
/// ```
///
/// Para tests unitarios:
/// ```dart
/// testWidgets('mi test unitario', (tester) async {
///   await initializeEasyLocalizationForTest(tester);
///
///   final message = 'errors.network.connection_error'.tr();
///   expect(message, 'Error de conexión. Por favor verifica tu internet.');
/// });
/// ```

/// Inicializa EasyLocalization para tests
///
/// IMPORTANTE: Debe usarse dentro de un testWidgets() porque requiere WidgetTester
Future<void> initializeEasyLocalizationForTest(
  WidgetTester tester, {
  Locale locale = const Locale('es'),
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('es'), Locale('en')],
      path: 'assets/translations', // No se usa con el loader personalizado
      fallbackLocale: const Locale('es'),
      startLocale: locale,
      assetLoader: const TestTranslationsLoader(),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: locale,
            home: const SizedBox.shrink(),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Construye un widget envuelto con EasyLocalization para tests
///
/// Ejemplo:
/// ```dart
/// testWidgets('mi test', (tester) async {
///   await tester.pumpWidget(
///     await buildTestableWidgetWithLocalization(
///       child: MyWidget(),
///     ),
///   );
/// });
/// ```
Future<Widget> buildTestableWidgetWithLocalization({
  required Widget child,
  Locale locale = const Locale('es'),
}) async {
  await EasyLocalization.ensureInitialized();

  return EasyLocalization(
    supportedLocales: const [Locale('es'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('es'),
    startLocale: locale,
    child: MaterialApp(
      localizationsDelegates: const [],
      supportedLocales: const [Locale('es'), Locale('en')],
      locale: locale,
      home: child,
    ),
  );
}
