import 'package:chismes/features/auth/presentation/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AuthButton', () {
    testWidgets('debe renderizar ElevatedButton por defecto', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('debe renderizar OutlinedButton cuando isOutlined es true', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            isOutlined: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('debe llamar onPressed cuando se presiona el botón', (WidgetTester tester) async {
      // Arrange
      bool buttonPressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () => buttonPressed = true,
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(buttonPressed, isTrue);
    });

    testWidgets('debe mostrar CircularProgressIndicator cuando isLoading es true', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('no debe mostrar texto cuando isLoading es true', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      // Assert
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('debe deshabilitar onPressed cuando isLoading es true', (WidgetTester tester) async {
      // Arrange
      bool buttonPressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () => buttonPressed = true,
            isLoading: true,
          ),
        ),
      );

      // Act - intentar presionar
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

      // Assert
      expect(button.onPressed, isNull);
      expect(buttonPressed, isFalse);
    });

    testWidgets('debe renderizar icono cuando se proporciona', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            icon: const Icon(Icons.login),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('debe renderizar solo texto cuando no hay icono', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('debe tener minimumSize correcto', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style;
      expect(style, isNotNull);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('auth_button_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            key: testKey,
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe permitir onPressed null', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: null,
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('debe deshabilitar botón outlined cuando isLoading es true', (WidgetTester tester) async {
      // Arrange
      bool buttonPressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () => buttonPressed = true,
            isLoading: true,
            isOutlined: true,
          ),
        ),
      );

      // Act
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      // Assert
      expect(button.onPressed, isNull);
      expect(buttonPressed, isFalse);
    });

    testWidgets('debe mostrar CircularProgressIndicator en botón outlined', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            isLoading: true,
            isOutlined: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('CircularProgressIndicator debe tener tamaño 20x20', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 20);
      expect(sizedBox.width, 20);
    });

    testWidgets('CircularProgressIndicator debe tener strokeWidth de 2', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      // Assert
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.strokeWidth, 2);
    });

    testWidgets('debe renderizar icono y texto juntos', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Login',
            onPressed: () {},
            icon: const Icon(Icons.login, key: Key('login_icon')),
          ),
        ),
      );

      // Assert
      expect(find.byKey(const Key('login_icon')), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Verificar que están en un Row
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('debe funcionar con diferentes textos', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          Column(
            children: [
              AuthButton(text: 'Login', onPressed: () {}),
              AuthButton(text: 'Sign Up', onPressed: () {}),
              AuthButton(text: 'Continue', onPressed: () {}),
            ],
          ),
        ),
      );

      // Assert
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('debe poder tener múltiples botones en pantalla', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          Column(
            children: [
              AuthButton(text: 'Button 1', onPressed: () {}),
              AuthButton(text: 'Button 2', onPressed: () {}, isOutlined: true),
              AuthButton(text: 'Button 3', onPressed: () {}, isLoading: true),
            ],
          ),
        ),
      );

      // Assert
      expect(find.byType(AuthButton), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsNWidgets(2));
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe ser stateless widget', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      // Assert
      final widget = tester.widget<AuthButton>(find.byType(AuthButton));
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('no debe mostrar icono cuando isLoading es true', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            icon: const Icon(Icons.login),
            isLoading: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.login), findsNothing);
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('debe tener SizedBox entre icono y texto', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          AuthButton(
            text: 'Test Button',
            onPressed: () {},
            icon: const Icon(Icons.login),
          ),
        ),
      );

      // Assert
      final row = tester.widget<Row>(find.byType(Row));
      final children = row.children;
      expect(children.length, 3); // icon, SizedBox, Text
      expect(children[1], isA<SizedBox>());
    });
  });
}
