import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_translations_loader.dart';

/// Wrapper para tests de widgets que necesitan i18n
///
/// Uso:
/// ```dart
/// await tester.pumpWidget(
///   testableWidget(
///     child: MyWidget(),
///   ),
/// );
/// ```

/// Crea un widget testeable con i18n configurado usando el TestTranslationsLoader
Widget testableWidget({
  required Widget child,
  Locale locale = const Locale('es'),
  MediaQueryData? mediaQuery,
  bool useScaffold = true,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('es'), Locale('en')],
    path: 'assets/translations', // No se usa con TestTranslationsLoader
    fallbackLocale: const Locale('es'),
    startLocale: locale,
    assetLoader: const TestTranslationsLoader(),
    useOnlyLangCode: true,
    child: Builder(
      builder: (context) {
        Widget result = MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: locale,
          home: useScaffold ? Scaffold(body: child) : child,
        );

        if (mediaQuery != null) {
          result = MediaQuery(
            data: mediaQuery,
            child: result,
          );
        }

        return result;
      },
    ),
  );
}

/// Pump widget con i18n configurado
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
