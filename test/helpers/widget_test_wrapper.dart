import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'test_di_helper.dart';

/// Wrapper para tests de widgets que necesitan i18n
///
/// **IMPORTANTE:** Si tu widget usa `LanguageSelector` o cualquier dependencia de GetIt,
/// debes inicializar el DI primero:
///
/// ```dart
/// setUp(() async {
///   await setupTestDI();
/// });
///
/// tearDown(() async {
///   await tearDownTestDI();
/// });
///
/// testWidgets('mi test', (tester) async {
///   await tester.pumpWidget(testableWidget(child: MyWidget()));
/// });
/// ```
///
/// **O usa `pumpWidgetWithDI` que lo hace automáticamente:**
/// ```dart
/// testWidgets('mi test', (tester) async {
///   await pumpWidgetWithDI(tester, MyWidget());
/// });
/// ```

/// Crea un widget testeable con i18n configurado usando gen-l10n
///
/// NOTA: No inicializa DI automáticamente. Si necesitas DI, llama a `setupTestDI()`
/// en setUp() o usa `pumpWidgetWithDI()`.
Widget testableWidget({
  required Widget child,
  Locale locale = const Locale('es'),
  MediaQueryData? mediaQuery,
  bool useScaffold = true,
  NavigatorObserver? navigatorObserver,
}) {
  Widget result = MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    home: useScaffold ? Scaffold(body: child) : child,
  );

  if (mediaQuery != null) {
    result = MediaQuery(
      data: mediaQuery,
      child: result,
    );
  }

  return result;
}

/// Pump widget con i18n configurado
///
/// NOTA: No inicializa DI. Si necesitas DI, usa `pumpWidgetWithDI()`.
Future<void> pumpWidgetWithI18n(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('es'),
  MediaQueryData? mediaQuery,
  bool useScaffold = true,
}) async {
  await tester.pumpWidget(
    testableWidget(
      child: child,
      locale: locale,
      mediaQuery: mediaQuery,
      useScaffold: useScaffold,
    ),
  );
  await tester.pumpAndSettle();
}

/// Pump widget con i18n Y DI configurados automáticamente
///
/// Esta es la función recomendada para la mayoría de los widget tests.
/// Inicializa DI, hace pump del widget, y limpia después.
///
/// **Uso recomendado:**
/// ```dart
/// testWidgets('mi test', (tester) async {
///   await pumpWidgetWithDI(tester, MyWidget());
///
///   // Tu test aquí
///   expect(find.byType(MyWidget), findsOneWidget);
/// });
/// ```
///
/// **Cleanup automático:**
/// Debes llamar a `tearDownTestDI()` en tearDown():
/// ```dart
/// tearDown(() async {
///   await tearDownTestDI();
/// });
/// ```
Future<void> pumpWidgetWithDI(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('es'),
  MediaQueryData? mediaQuery,
  bool useScaffold = true,
  NavigatorObserver? navigatorObserver,
}) async {
  // Inicializar DI si no está ya inicializado
  if (!isTestDIReady()) {
    await setupTestDI(initialLocale: locale);
  }

  // Pump el widget
  await tester.pumpWidget(
    testableWidget(
      child: child,
      locale: locale,
      mediaQuery: mediaQuery,
      useScaffold: useScaffold,
      navigatorObserver: navigatorObserver,
    ),
  );

  await tester.pumpAndSettle();
}
