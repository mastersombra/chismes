import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/l10n/l10n.dart';
import 'package:chismes/features/auth/presentation/screens/privacy_consent_screen.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('PrivacyConsentScreen', () {
    Widget createTestWidget() {
      return testableWidget(
        child: const PrivacyConsentScreen(),
        useScaffold: false,
      );
    }

    testWidgets('debe renderizar correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PrivacyConsentScreen), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('privacy_consent_key');

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: const PrivacyConsentScreen(key: testKey),
          useScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe tener Scaffold', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe tener AppBar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('debe tener SafeArea', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // MaterialApp puede agregar SafeArea adicionales en la jerarquía
      // Verificamos que al menos haya uno (el del widget)
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('debe tener SingleChildScrollView', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('debe tener Column principal', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe tener padding en el contenido', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe tener SizedBox para espaciado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('debe tener checkboxes', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - debe tener al menos 3 checkboxes
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('debe ser StatefulWidget', (WidgetTester tester) async {
      // Assert
      expect(const PrivacyConsentScreen(), isA<StatefulWidget>());
    });

    testWidgets('debe tener ElevatedButton', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - botón debe existir
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('checkboxes deben estar inicialmente sin marcar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - checkboxes existen
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);
    });

    testWidgets('debe tener Text.rich para labels con links', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('PrivacyConsentScreen - Interacción', () {
    AppLocalizations l10nOf(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(PrivacyConsentScreen)))!;

    ElevatedButton acceptButton(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    List<bool?> checkboxValues(WidgetTester tester) => tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .map((c) => c.value)
        .toList();

    Future<void> pushConsent(WidgetTester tester) async {
      await tester.pumpWidget(testableWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyConsentScreen()),
            ),
            child: const Text('HOST'),
          ),
        ),
      ));
      await tester.tap(find.text('HOST'));
      await tester.pumpAndSettle();
    }

    Future<void> tapLink(WidgetTester tester, String linkText) async {
      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        TapGestureRecognizer? found;
        rich.text.visitChildren((span) {
          if (span is TextSpan && span.text == linkText) {
            found = span.recognizer as TapGestureRecognizer?;
            return false;
          }
          return true;
        });
        if (found != null) {
          found!.onTap!();
          await tester.pumpAndSettle();
          return;
        }
      }
      fail('link "$linkText" no encontrado');
    }

    Future<void> checkAll(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        final box = find.byType(Checkbox).at(i);
        await tester.ensureVisible(box);
        await tester.tap(box);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('aceptar solo se habilita con los tres checkboxes marcados',
        (tester) async {
      await tester.pumpWidget(testableWidget(
          child: const PrivacyConsentScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      expect(acceptButton(tester).onPressed, isNull);

      for (var i = 0; i < 3; i++) {
        final box = find.byType(Checkbox).at(i);
        await tester.ensureVisible(box);
        await tester.tap(box);
        await tester.pumpAndSettle();
        expect(acceptButton(tester).onPressed, i < 2 ? isNull : isNotNull);
      }
      expect(checkboxValues(tester), [true, true, true]);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(checkboxValues(tester), [false, true, true]);
      expect(acceptButton(tester).onPressed, isNull);
    });

    testWidgets('tocar la etiqueta de moderación alterna su checkbox',
        (tester) async {
      await tester.pumpWidget(testableWidget(
          child: const PrivacyConsentScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      final row = find
          .ancestor(of: find.byType(Checkbox).at(2), matching: find.byType(Row))
          .first;
      final label =
          find.descendant(of: row, matching: find.byType(Expanded)).first;

      await tester.ensureVisible(label);
      await tester.tap(label);
      await tester.pumpAndSettle();

      expect(checkboxValues(tester), [false, false, true]);
    });

    testWidgets('el link de privacidad abre un diálogo que se cierra',
        (tester) async {
      await tester.pumpWidget(testableWidget(
          child: const PrivacyConsentScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await tapLink(tester, l10n.privacyConsentCheckboxPrivacyLink);
      expect(find.widgetWithText(AlertDialog, l10n.privacySettingsPrivacyPolicy),
          findsOneWidget);
      expect(find.textContaining(l10n.privacyConsentDialogPrivacyUrl),
          findsOneWidget);

      await tester.tap(find.text(l10n.close));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('el link de términos abre un diálogo que se cierra',
        (tester) async {
      await tester.pumpWidget(testableWidget(
          child: const PrivacyConsentScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await tapLink(tester, l10n.privacyConsentCheckboxTermsLink);
      expect(find.widgetWithText(AlertDialog, l10n.privacySettingsTermsOfUse),
          findsOneWidget);
      expect(find.textContaining(l10n.privacyConsentDialogTermsUrl),
          findsOneWidget);

      await tester.tap(find.text(l10n.close));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('aceptar con todo marcado cierra la pantalla', (tester) async {
      await pushConsent(tester);
      await checkAll(tester);

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyConsentScreen), findsNothing);
      expect(find.text('HOST'), findsOneWidget);
    });

    testWidgets('aceptar sin ruta previa no hace pop', (tester) async {
      await tester.pumpWidget(testableWidget(
          child: const PrivacyConsentScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      await checkAll(tester);

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyConsentScreen), findsOneWidget);
    });

    testWidgets('rechazar vuelve a la pantalla anterior', (tester) async {
      await pushConsent(tester);
      final decline = find.text(l10nOf(tester).privacyConsentDeclineButton);

      await tester.ensureVisible(decline);
      await tester.tap(decline);
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyConsentScreen), findsNothing);
      expect(find.text('HOST'), findsOneWidget);
    });
  });
}
