import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/l10n/l10n.dart';

void main() {
  group('L10nContext Extension', () {
    Future<BuildContext> createContext(WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox();
            },
          ),
        ),
      );

      return capturedContext;
    }

    testWidgets('l10n getter debe retornar AppLocalizations', (tester) async {
      // Arrange
      final context = await createContext(tester);

      // Act
      final localizations = context.l10n;

      // Assert
      expect(localizations, isA<AppLocalizations>());
    });

    testWidgets('l10n debe ser accesible desde BuildContext', (tester) async {
      // Arrange
      final context = await createContext(tester);

      // Act & Assert - No debe lanzar error
      expect(() => context.l10n, returnsNormally);
    });

    testWidgets('l10n debe retornar la misma instancia para mismo contexto', (tester) async {
      // Arrange
      final context = await createContext(tester);

      // Act
      final localizations1 = context.l10n;
      final localizations2 = context.l10n;

      // Assert
      expect(identical(localizations1, localizations2), isTrue);
    });

    testWidgets('l10n debe tener métodos de traducción disponibles', (tester) async {
      // Arrange
      final context = await createContext(tester);

      // Act
      final localizations = context.l10n;

      // Assert - Verificar que tiene algunos métodos básicos
      expect(() => localizations.appTagline, returnsNormally);
    });

    testWidgets('l10n debe funcionar con español (default)', (tester) async {
      // Arrange
      final context = await createContext(tester);

      // Act
      final localizations = context.l10n;

      // Assert
      expect(localizations, isNotNull);
      expect(localizations.appTagline, isNotEmpty);
    });

    testWidgets('l10n debe funcionar con inglés', (tester) async {
      // Arrange
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox();
            },
          ),
        ),
      );

      // Act
      final localizations = capturedContext.l10n;

      // Assert
      expect(localizations, isNotNull);
      expect(localizations.appTagline, isNotEmpty);
    });

    testWidgets('l10n debe lanzar assertion si AppLocalizations no está configurado', (tester) async {
      // Arrange
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          // NO configurar localizationsDelegates
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox();
            },
          ),
        ),
      );

      // Act & Assert
      expect(
        () => capturedContext.l10n,
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AppLocalizations export', () {
    test('debe exportar AppLocalizations correctamente', () {
      // Assert
      expect(AppLocalizations, isNotNull);
      expect(AppLocalizations.localizationsDelegates, isNotNull);
      expect(AppLocalizations.supportedLocales, isNotNull);
    });

    test('supportedLocales debe contener español e inglés', () {
      // Assert
      expect(
        AppLocalizations.supportedLocales,
        containsAll([
          const Locale('es'),
          const Locale('en'),
        ]),
      );
    });

    test('supportedLocales debe tener exactamente 2 locales', () {
      // Assert
      expect(AppLocalizations.supportedLocales, hasLength(2));
    });
  });
}
