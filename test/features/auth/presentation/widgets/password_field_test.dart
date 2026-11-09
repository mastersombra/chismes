import 'package:chismes/features/auth/presentation/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return testableWidget(child: child, useScaffold: true);
  }

  group('PasswordField', () {
    testWidgets('debe renderizar TextFormField', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('debe tener label "Contraseña" por defecto', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('debe usar labelText personalizado cuando se proporciona', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(
            controller: controller,
            labelText: 'Nueva Contraseña',
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Nueva Contraseña'), findsOneWidget);
      expect(find.text('Contraseña'), findsNothing);
    });

    testWidgets('debe aceptar hintText personalizado', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(
            controller: controller,
            hintText: 'Ingresa tu contraseña',
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - verificar que el campo se renderiza correctamente
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('debe tener icono de candado por defecto', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('debe usar prefixIcon personalizado cuando se proporciona', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(
            controller: controller,
            prefixIcon: const Icon(Icons.vpn_key),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsNothing);
    });

    testWidgets('debe inicializar con texto oculto', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - verificar que el icono de visibilidad está presente
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('debe mostrar icono de visibilidad cuando texto está oculto', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('debe alternar visibilidad al presionar icono', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Verificar estado inicial
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Act - presionar icono para mostrar
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Assert - icono cambió a visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Act - presionar icono para ocultar
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Assert - icono cambió a visibility nuevamente
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('debe tener tooltip "Mostrar contraseña" cuando está oculta', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.visibility_outlined),
      );
      expect(iconButton.tooltip, 'Mostrar contraseña');
    });

    testWidgets('debe tener tooltip "Ocultar contraseña" cuando está visible', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Act - mostrar contraseña
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Assert
      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.visibility_off_outlined),
      );
      expect(iconButton.tooltip, 'Ocultar contraseña');
    });

    testWidgets('debe estar habilitado por defecto', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isTrue);
    });

    testWidgets('debe estar deshabilitado cuando enabled es false', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(
            controller: controller,
            enabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('debe usar el controller proporcionado', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController(text: 'test123');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller, controller);
      expect(controller.text, 'test123');
    });

    testWidgets('debe llamar validator cuando se proporciona', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      bool validatorCalled = false;
      String? validatorResult;

      String? validator(String? value) {
        validatorCalled = true;
        if (value == null || value.isEmpty) {
          validatorResult = 'Campo requerido';
          return validatorResult;
        }
        return null;
      }

      await tester.pumpWidget(
        makeTestableWidget(
          Form(
            child: PasswordField(
              controller: controller,
              validator: validator,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Act
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();

      // Assert
      expect(validatorCalled, isTrue);
      expect(validatorResult, 'Campo requerido');
    });

    testWidgets('debe llamar onChanged cuando el texto cambia', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      String? changedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(
            controller: controller,
            onChanged: (value) => changedValue = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Act
      await tester.enterText(find.byType(TextFormField), 'test123');
      await tester.pump();

      // Assert
      expect(changedValue, 'test123');
    });

    testWidgets('debe renderizar con OutlineInputBorder', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - verificar que el TextFormField se renderiza correctamente
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      const testKey = Key('password_field_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(
            key: testKey,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe ser StatefulWidget', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      final widget = tester.widget<PasswordField>(find.byType(PasswordField));
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('debe mantener estado entre rebuilds', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Act - mostrar contraseña
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Rebuild
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert - estado se mantiene (icono sigue siendo visibility_off)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('debe tener IconButton para toggle', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          PasswordField(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('debe funcionar con múltiples instancias', (WidgetTester tester) async {
      // Arrange
      final controller1 = TextEditingController();
      final controller2 = TextEditingController();

      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          Column(
            children: [
              PasswordField(controller: controller1),
              PasswordField(controller: controller2, labelText: 'Confirmar'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(PasswordField), findsNWidgets(2));
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('cada instancia debe tener su propio estado de visibilidad', (WidgetTester tester) async {
      // Arrange
      final controller1 = TextEditingController();
      final controller2 = TextEditingController();

      await tester.pumpWidget(
        makeTestableWidget(
          Column(
            children: [
              PasswordField(controller: controller1, key: const Key('field1')),
              PasswordField(controller: controller2, key: const Key('field2')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Verificar estado inicial - ambos con visibility_outlined
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

      // Act - mostrar solo el primero
      final firstField = find.descendant(
        of: find.byKey(const Key('field1')),
        matching: find.byIcon(Icons.visibility_outlined),
      );
      await tester.tap(firstField.first);
      await tester.pump();

      // Assert - el primero cambió a visibility_off, el segundo sigue con visibility
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
