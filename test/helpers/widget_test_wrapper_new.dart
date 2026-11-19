import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Wrapper para tests de widgets con localizaciones (gen-l10n)
///
/// Uso:
/// ```dart
/// await tester.pumpWidget(testableWidget(MyWidget()));
/// ```

Widget testableWidget(
  Widget child, {
  Locale locale = const Locale('es'),
  NavigatorObserver? navigatorObserver,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    home: Scaffold(body: child),
  );
}

/// Pump widget con i18n configurado
Future<void> pumpWidgetWithI18n(
  WidgetTester tester,
  Widget widget, {
  Locale locale = const Locale('es'),
}) async {
  await tester.pumpWidget(testableWidget(widget, locale: locale));
}
