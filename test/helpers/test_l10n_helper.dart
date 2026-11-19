import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/l10n/app_localizations.dart';

/// Helper para proveer context con AppLocalizations en tests
///
/// Uso:
/// ```dart
/// testWidgets('mi test', (tester) async {
///   await tester.pumpWidget(
///     TestL10nApp(
///       child: Builder(
///         builder: (context) {
///           // Aquí tienes context con context.l10n disponible
///           final result = FormValidators.email(context, 'test@test.com');
///           return Text(result ?? 'valid');
///         },
///       ),
///     ),
///   );
/// });
/// ```

class TestL10nApp extends StatelessWidget {
  final Widget child;
  final Locale locale;

  const TestL10nApp({
    super.key,
    required this.child,
    this.locale = const Locale('es'),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}

/// Wrapper más simple para tests unitarios
///
/// Retorna el context dentro del callback para usar en asserts
Future<T> withL10nContext<T>(
  WidgetTester tester,
  T Function(BuildContext context) callback, {
  Locale locale = const Locale('es'),
}) async {
  late T result;

  await tester.pumpWidget(
    TestL10nApp(
      locale: locale,
      child: Builder(
        builder: (context) {
          result = callback(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  await tester.pumpAndSettle();

  return result;
}
