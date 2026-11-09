import 'package:chismes/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('PasswordStrengthIndicator', () {
    testWidgets('no debe renderizar nada cuando password está vacío', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: ''),
        ),
      );

      // Assert
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('debe renderizar indicador para contraseña débil', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Débil'), findsOneWidget);
    });

    testWidgets('debe renderizar indicador para contraseña media', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc12345'),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
    });

    testWidgets('debe renderizar indicador para contraseña fuerte', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc123!@#'),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Fuerte'), findsOneWidget);
    });

    testWidgets('debe mostrar color rojo para contraseña débil', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      final textWidget = tester.widget<Text>(find.text('Débil'));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('debe mostrar color naranja para contraseña media', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc12345'),
        ),
      );

      // Assert
      final textWidget = tester.widget<Text>(find.text('Media'));
      expect(textWidget.style?.color, Colors.orange);
    });

    testWidgets('debe mostrar color verde para contraseña fuerte', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc123!@#'),
        ),
      );

      // Assert
      final textWidget = tester.widget<Text>(find.text('Fuerte'));
      expect(textWidget.style?.color, Colors.green);
    });

    testWidgets('debe mostrar hint para contraseña sin longitud mínima', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Ab1!'),
        ),
      );

      // Assert
      expect(find.textContaining('mínimo 8 caracteres'), findsOneWidget);
    });

    testWidgets('debe mostrar hint para contraseña sin mayúscula', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc12345!'),
        ),
      );

      // Assert
      expect(find.textContaining('una mayúscula'), findsOneWidget);
    });

    testWidgets('debe mostrar hint para contraseña sin minúscula', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'ABC12345!'),
        ),
      );

      // Assert
      expect(find.textContaining('una minúscula'), findsOneWidget);
    });

    testWidgets('debe mostrar hint para contraseña sin número', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abcdefgh!'),
        ),
      );

      // Assert
      expect(find.textContaining('un número'), findsOneWidget);
    });

    testWidgets('debe mostrar hint para contraseña sin símbolo', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc12345'),
        ),
      );

      // Assert
      expect(find.textContaining('un símbolo'), findsOneWidget);
    });

    testWidgets('debe mostrar múltiples hints cuando faltan varios requisitos', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.textContaining('Agrega:'), findsOneWidget);
      expect(find.textContaining('mínimo 8 caracteres'), findsOneWidget);
      expect(find.textContaining('una mayúscula'), findsOneWidget);
      expect(find.textContaining('un número'), findsOneWidget);
      expect(find.textContaining('un símbolo'), findsOneWidget);
    });

    testWidgets('no debe mostrar hints para contraseña fuerte', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc123!@#'),
        ),
      );

      // Assert
      expect(find.textContaining('Agrega:'), findsNothing);
      expect(find.text('Fuerte'), findsOneWidget);
    });

    testWidgets('debe tener LinearProgressIndicator con valor correcto', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, isNotNull);
      expect(progressIndicator.value, greaterThan(0));
      expect(progressIndicator.value, lessThanOrEqualTo(1.0));
    });

    testWidgets('debe tener LinearProgressIndicator con minHeight de 8', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.minHeight, 8);
    });

    testWidgets('debe tener ClipRRect con borderRadius', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('debe tener Row con LinearProgressIndicator y texto', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Débil'), findsOneWidget);
    });

    testWidgets('debe tener Column como contenedor principal', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('password_strength_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(
            key: testKey,
            password: 'abc',
          ),
        ),
      );

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe ser StatelessWidget', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      final widget = tester.widget<PasswordStrengthIndicator>(
        find.byType(PasswordStrengthIndicator),
      );
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('debe tener SizedBox para espaciado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('debe actualizar cuando password cambia', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      expect(find.text('Débil'), findsOneWidget);

      // Act - cambiar a contraseña fuerte
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc123!@#'),
        ),
      );

      // Assert
      expect(find.text('Fuerte'), findsOneWidget);
      expect(find.text('Débil'), findsNothing);
    });

    testWidgets('debe funcionar con contraseña muy corta', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'a'),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Débil'), findsOneWidget);
    });

    testWidgets('debe funcionar con contraseña muy larga', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'Abc123!@#VeryLongPasswordWithManyCharacters'),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Fuerte'), findsOneWidget);
    });

    testWidgets('debe reconocer diferentes símbolos', (WidgetTester tester) async {
      // Arrange
      final passwords = [
        'Abc12345!',
        'Abc12345@',
        'Abc12345#',
        'Abc12345\$',
        'Abc12345%',
      ];

      for (final password in passwords) {
        // Act
        await tester.pumpWidget(
          makeTestableWidget(
            PasswordStrengthIndicator(password: password),
          ),
        );

        // Assert - no debe pedir símbolo
        final hintFinder = find.textContaining('un símbolo');
        expect(hintFinder, findsNothing, reason: 'Failed for password: $password');
      }
    });

    testWidgets('hints deben tener tamaño de fuente pequeño', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      final hintText = tester.widgetList<Text>(find.byType(Text)).firstWhere(
        (text) => text.data?.contains('Agrega:') ?? false,
      );
      expect(hintText.style?.fontSize, 11);
    });

    testWidgets('texto de fortaleza debe tener tamaño y peso correcto', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      final strengthText = tester.widget<Text>(find.text('Débil'));
      expect(strengthText.style?.fontSize, 12);
      expect(strengthText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('debe tener Expanded para LinearProgressIndicator', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          const PasswordStrengthIndicator(password: 'abc'),
        ),
      );

      // Assert
      expect(find.byType(Expanded), findsOneWidget);
    });
  });
}
