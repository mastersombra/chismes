import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/auth/presentation/widgets/email_field.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chismes/l10n/app_localizations.dart';

void main() {
  group('EmailField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildWidget({
      TextEditingController? customController,
      String? Function(String?)? validator,
      bool enabled = true,
      String? hintText,
      Widget? prefixIcon,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            child: EmailField(
              controller: customController ?? controller,
              validator: validator,
              enabled: enabled,
              hintText: hintText,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('debe renderizar TextFormField', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildWidget());

        // Assert
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('debe mostrar label de email', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildWidget());

        // Assert
        expect(find.text('Email'), findsOneWidget);
      });

      testWidgets('debe mostrar icono de email por defecto', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildWidget());

        // Assert
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      });

      testWidgets('debe usar prefixIcon personalizado cuando se proporciona',
          (tester) async {
        // Arrange
        const customIcon = Icon(Icons.alternate_email);

        // Act
        await tester.pumpWidget(
          buildWidget(prefixIcon: customIcon),
        );

        // Assert
        expect(find.byIcon(Icons.alternate_email), findsOneWidget);
        expect(find.byIcon(Icons.email_outlined), findsNothing);
      });
    });

    group('Controller', () {
      testWidgets('debe usar controller proporcionado', (tester) async {
        // Arrange
        final customController = TextEditingController(text: 'test@example.com');

        // Act
        await tester.pumpWidget(
          buildWidget(customController: customController),
        );

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);

        // Cleanup
        customController.dispose();
      });

      testWidgets('debe actualizar controller al escribir', (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Assert
        expect(controller.text, 'test@example.com');
      });

      testWidgets('debe responder a cambios en el controller', (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act - Cambiar controller programáticamente
        controller.text = 'new@example.com';
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('new@example.com'), findsOneWidget);
      });

      testWidgets('debe limpiar texto al hacer clear en controller',
          (tester) async {
        // Arrange
        controller.text = 'test@example.com';
        await tester.pumpWidget(buildWidget());

        // Act
        controller.clear();
        await tester.pumpAndSettle();

        // Assert
        expect(controller.text, isEmpty);
        expect(find.text('test@example.com'), findsNothing);
      });
    });

    group('Estado Enabled/Disabled', () {
      testWidgets('debe estar habilitado por defecto', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildWidget());

        // Assert - Campo debe permitir escritura
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.pumpAndSettle();
        expect(controller.text, 'test@example.com');
      });

      testWidgets('NO debe permitir escritura cuando está deshabilitado',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildWidget(enabled: false),
        );

        // Act - Intentar escribir
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.pumpAndSettle();

        // Assert - El texto NO debe cambiar porque está disabled
        expect(controller.text, isEmpty);
      });
    });

    group('LowercaseTextInputFormatter', () {
      testWidgets('debe convertir texto a minúsculas automáticamente',
          (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act - Escribir con mayúsculas
        await tester.enterText(
          find.byType(TextFormField),
          'TEST@EXAMPLE.COM',
        );
        await tester.pumpAndSettle();

        // Assert - Debe estar en minúsculas
        expect(controller.text, 'test@example.com');
      });

      testWidgets('debe convertir mayúsculas mixtas a minúsculas',
          (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act
        await tester.enterText(
          find.byType(TextFormField),
          'TeSt@ExAmPlE.CoM',
        );
        await tester.pumpAndSettle();

        // Assert
        expect(controller.text, 'test@example.com');
      });

      testWidgets('debe preservar texto ya en minúsculas', (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Assert
        expect(controller.text, 'test@example.com');
      });
    });

    group('Validación', () {
      testWidgets('debe fallar validación cuando email es vacío',
          (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act - Validar formulario sin escribir nada
        final formState = tester.state<FormState>(
          find.byType(Form),
        );
        final isValid = formState.validate();
        await tester.pumpAndSettle();

        // Assert - Validación debe fallar
        expect(isValid, isFalse);
      });

      testWidgets('debe fallar validación cuando email es inválido',
          (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act - Escribir email inválido
        await tester.enterText(find.byType(TextFormField), 'invalid-email');
        await tester.pumpAndSettle();

        // Validar formulario
        final formState = tester.state<FormState>(
          find.byType(Form),
        );
        final isValid = formState.validate();
        await tester.pumpAndSettle();

        // Assert - Validación debe fallar
        expect(isValid, isFalse);
      });

      testWidgets('NO debe mostrar error cuando email es válido',
          (tester) async {
        // Arrange
        await tester.pumpWidget(buildWidget());

        // Act - Escribir email válido
        await tester.enterText(
          find.byType(TextFormField),
          'valid@example.com',
        );
        await tester.pumpAndSettle();

        // Validar formulario
        final formState = tester.state<FormState>(
          find.byType(Form),
        );
        final isValid = formState.validate();
        await tester.pumpAndSettle();

        // Assert
        expect(isValid, isTrue);
        expect(find.text('Ingresa un email válido'), findsNothing);
        expect(find.text('Ingresa tu email'), findsNothing);
      });

      testWidgets('debe usar validador personalizado cuando se proporciona',
          (tester) async {
        // Arrange
        String? customValidator(String? value) {
          if (value == null || value.isEmpty) {
            return 'Custom error';
          }
          return null;
        }

        await tester.pumpWidget(
          buildWidget(validator: customValidator),
        );

        // Act - Validar con campo vacío
        final formState = tester.state<FormState>(
          find.byType(Form),
        );
        formState.validate();
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Custom error'), findsOneWidget);
        expect(find.text('Ingresa tu email'), findsNothing);
      });
    });

    group('Temas', () {
      testWidgets('debe renderizar correctamente con tema personalizado',
          (tester) async {
        // Arrange
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.light,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Form(
                child: EmailField(controller: controller),
              ),
            ),
          ),
        );

        // Assert - Verificar que el campo se renderiza correctamente
        expect(find.byType(EmailField), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });
    });
  });

  group('LowercaseTextInputFormatter', () {
    late LowercaseTextInputFormatter formatter;

    setUp(() {
      formatter = LowercaseTextInputFormatter();
    });

    test('debe convertir texto a minúsculas', () {
      // Arrange
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: 'TEST');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, 'test');
    });

    test('debe preservar texto ya en minúsculas', () {
      // Arrange
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: 'test');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, 'test');
    });

    test('debe manejar texto vacío', () {
      // Arrange
      const oldValue = TextEditingValue(text: 'test');
      const newValue = TextEditingValue(text: '');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, '');
    });

    test('debe preservar la selección del cursor', () {
      // Arrange
      const oldValue = TextEditingValue(
        text: 'old',
        selection: TextSelection.collapsed(offset: 3),
      );
      const newValue = TextEditingValue(
        text: 'NEW',
        selection: TextSelection.collapsed(offset: 2),
      );

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.selection, newValue.selection);
      expect(result.selection.baseOffset, 2);
    });

    test('debe convertir emails con mayúsculas a minúsculas', () {
      // Arrange
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: 'TEST@EXAMPLE.COM');

      // Act
      final result = formatter.formatEditUpdate(oldValue, newValue);

      // Assert
      expect(result.text, 'test@example.com');
    });
  });
}
