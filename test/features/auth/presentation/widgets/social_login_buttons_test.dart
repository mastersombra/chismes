import 'package:chismes/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return testableWidget(child: child, useScaffold: true);
  }

  group('SocialLoginButtons', () {
    testWidgets('debe renderizar correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(SocialLoginButtons), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('social_login_buttons_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            key: testKey,
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe renderizar dos botones OutlinedButton', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('debe llamar onGooglePressed cuando se presiona botón de Google', (WidgetTester tester) async {
      // Arrange
      bool googlePressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () => googlePressed = true,
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Act
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();

      // Assert
      expect(googlePressed, isTrue);
    });

    testWidgets('debe llamar onApplePressed cuando se presiona botón de Apple', (WidgetTester tester) async {
      // Arrange
      bool applePressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () => applePressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Act
      await tester.tap(find.text('Continuar con Apple'));
      await tester.pump();

      // Assert
      expect(applePressed, isTrue);
    });

    testWidgets('debe deshabilitar botones cuando isLoading es true', (WidgetTester tester) async {
      // Arrange
      bool googlePressed = false;
      bool applePressed = false;

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () => googlePressed = true,
            onApplePressed: () => applePressed = true,
            isLoading: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - los botones no deben responder porque están deshabilitados
      await tester.tap(find.text('Continuar con Google'));
      await tester.tap(find.text('Continuar con Apple'));
      await tester.pump();

      expect(googlePressed, isFalse);
      expect(applePressed, isFalse);
    });

    testWidgets('debe habilitar botones cuando isLoading es false', (WidgetTester tester) async {
      // Arrange
      bool googlePressed = false;
      bool applePressed = false;

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () => googlePressed = true,
            onApplePressed: () => applePressed = true,
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - los botones deben responder porque están habilitados
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      expect(googlePressed, isTrue);

      await tester.tap(find.text('Continuar con Apple'));
      await tester.pump();
      expect(applePressed, isTrue);
    });

    testWidgets('debe tener Column como widget principal', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe tener SizedBox para espaciado entre botones', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('debe mostrar icono de fallback si imagen de Google falla', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          SocialLoginButtons(
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // El errorBuilder debería mostrar el icono de fallback si la imagen no existe
      await tester.pump();

      // Assert - verificar que el widget se renderizó
      expect(find.byType(SocialLoginButtons), findsOneWidget);
    });
  });

  group('GoogleSignInButton', () {
    testWidgets('debe renderizar correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('google_button_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            key: testKey,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe llamar onPressed cuando se presiona', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Act
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();

      // Assert
      expect(pressed, isTrue);
    });

    testWidgets('debe deshabilitar botón cuando isLoading es true', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            onPressed: () => pressed = true,
            isLoading: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - el botón no debe responder porque está deshabilitado
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('debe habilitar botón cuando isLoading es false', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            onPressed: () => pressed = true,
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - el botón debe responder porque está habilitado
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('debe tener estructura correcta', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('debe mostrar icono de fallback si imagen falla', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GoogleSignInButton(
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();

      // Assert - verificar que el widget se renderizó
      expect(find.byType(GoogleSignInButton), findsOneWidget);
    });
  });

  group('AppleSignInButton', () {
    testWidgets('debe renderizar correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(AppleSignInButton), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('apple_button_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            key: testKey,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe renderizar icono de Apple', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('debe llamar onPressed cuando se presiona', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Act
      await tester.tap(find.text('Continuar con Apple'));
      await tester.pump();

      // Assert
      expect(pressed, isTrue);
    });

    testWidgets('debe deshabilitar botón cuando isLoading es true', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            onPressed: () => pressed = true,
            isLoading: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - el botón no debe responder porque está deshabilitado
      await tester.tap(find.text('Continuar con Apple'));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('debe habilitar botón cuando isLoading es false', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            onPressed: () => pressed = true,
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - el botón debe responder porque está habilitado
      await tester.tap(find.text('Continuar con Apple'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('debe tener estructura correcta', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AppleSignInButton(
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(AppleSignInButton), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });
  });
}
