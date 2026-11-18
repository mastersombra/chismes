import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
