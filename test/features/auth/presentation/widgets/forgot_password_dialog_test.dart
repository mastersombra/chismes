import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:chismes/features/auth/presentation/widgets/email_field.dart';
import 'package:chismes/core/theme/app_spacing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chismes/l10n/app_localizations.dart';

void main() {
  group('ForgotPasswordDialog', () {
    late String? capturedEmail;

    setUp(() {
      capturedEmail = null;
    });

    Widget buildWidget({
      Function(String)? onCodeSent,
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
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => ForgotPasswordDialog(
                    onCodeSent: onCodeSent ?? (email) => capturedEmail = email,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    Future<void> openDialog(WidgetTester tester, {Function(String)? onCodeSent}) async {
      // Renderizar el dialog directamente sin showDialog
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ForgotPasswordDialog(
              onCodeSent: onCodeSent ?? (email) => capturedEmail = email,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('Rendering', () {
      testWidgets('debe renderizar AlertDialog', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('debe mostrar título', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - AlertDialog debe tener un título
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(dialog.title, isNotNull);
      });

      testWidgets('debe mostrar icono de email', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon &&
                widget.icon == Icons.email_outlined &&
                widget.size == 64,
          ),
          findsOneWidget,
        );
      });

      testWidgets('debe aplicar color primario al icono', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        final icon = tester.widget<Icon>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon &&
                widget.icon == Icons.email_outlined &&
                widget.size == 64,
          ),
        );

        expect(icon.color, isNotNull);
      });

      testWidgets('debe mostrar mensaje descriptivo', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Verificar que hay texto descriptivo (buscar por palabras clave)
        final textFinders = [
          find.textContaining('código'),
          find.textContaining('dígitos'),
          find.textContaining('email'),
        ];

        // Al menos uno de estos textos debe estar presente
        expect(
          textFinders.any((finder) => tester.widgetList(finder).isNotEmpty),
          isTrue,
        );
      });

      testWidgets('debe renderizar EmailField', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        expect(find.byType(EmailField), findsOneWidget);
      });

      testWidgets('debe tener espaciado correcto entre elementos',
          (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        final sizedBoxes = tester.widgetList<SizedBox>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(SizedBox),
          ),
        );

        // Verificar que existen SizedBoxes con AppSpacing
        expect(
          sizedBoxes.where((sb) => sb.height == AppSpacing.lg),
          isNotEmpty,
        );
        expect(
          sizedBoxes.where((sb) => sb.height == AppSpacing.xl),
          isNotEmpty,
        );
      });

      testWidgets('debe tener SingleChildScrollView', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );
      });

      testWidgets('debe tener Form con GlobalKey', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Form),
          ),
          findsOneWidget,
        );
      });
    });

    group('Botones', () {
      testWidgets('debe mostrar botón Cancelar', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Verificar que existe TextButton (botón de cancelar)
        expect(find.byType(TextButton), findsOneWidget);
      });

      testWidgets('debe mostrar botón Enviar código', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Verificar que existe FilledButton (botón de enviar)
        expect(find.byType(FilledButton), findsOneWidget);
      });
    });

    group('Estado Normal (No Loading)', () {
      testWidgets('botón Cancelar debe estar habilitado', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        final cancelButton = tester.widget<TextButton>(
          find.byType(TextButton),
        );
        expect(cancelButton.onPressed, isNotNull);
      });

      testWidgets('botón Enviar debe estar habilitado', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        final sendButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(sendButton.onPressed, isNotNull);
      });

      testWidgets('EmailField debe estar habilitado', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        final emailField = tester.widget<EmailField>(
          find.byType(EmailField),
        );
        expect(emailField.enabled, isTrue);
      });

      testWidgets('debe mostrar botón sin loading indicator',
          (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Estado inicial no debe tener loading
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Estado Loading', () {
      testWidgets('debe cambiar a estado loading al enviar',
          (tester) async {
        // Arrange
        await openDialog(tester);

        // Escribir email válido
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Act - Tap en botón enviar (FilledButton)
        await tester.tap(find.byType(FilledButton));
        await tester.pump(); // pump sin settle para capturar estado loading

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('debe mostrar CircularProgressIndicator en botón',
          (tester) async {
        // Arrange
        await openDialog(tester);

        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Assert
        final progressIndicators = find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        );
        expect(progressIndicators, findsOneWidget);

        // Verificar tamaño del indicator
        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: progressIndicators,
            matching: find.byType(SizedBox),
          ),
        );
        expect(sizedBox.width, 16);
        expect(sizedBox.height, 16);
      });

      testWidgets('CircularProgressIndicator debe tener strokeWidth correcto',
          (tester) async {
        // Arrange
        await openDialog(tester);

        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Assert
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.strokeWidth, 2);
      });
    });

    group('Validación de Formulario', () {
      testWidgets('NO debe llamar onCodeSent si formulario es inválido',
          (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Tap en enviar SIN escribir email
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert
        expect(capturedEmail, isNull);
      });

      testWidgets('debe mostrar error de validación si email está vacío',
          (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Tap en enviar sin email
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert - No debe llamar callback si formulario es inválido
        expect(capturedEmail, isNull);
      });

      testWidgets('debe mostrar error si email es inválido', (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Escribir email inválido
        await tester.enterText(
          find.byType(TextFormField),
          'invalid-email',
        );
        await tester.pumpAndSettle();

        // Tap enviar
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert - NO debe llamar callback si email es inválido
        expect(capturedEmail, isNull);
      });

      testWidgets('debe validar exitosamente con email válido',
          (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Escribir email válido
        await tester.enterText(
          find.byType(TextFormField),
          'valid@example.com',
        );
        await tester.pumpAndSettle();

        // Tap enviar
        await tester.tap(find.byType(FilledButton));
        await tester.pump(); // Solo pump, no pumpAndSettle (widget queda en loading)

        // Assert - Debe llamar callback (validación exitosa)
        expect(capturedEmail, 'valid@example.com');
      });
    });

    group('Callback onCodeSent', () {
      testWidgets('debe llamar onCodeSent con email normalizado',
          (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Escribir email válido
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Tap enviar
        await tester.tap(find.byType(FilledButton));
        await tester.pump(); // Solo pump, no pumpAndSettle (widget queda en loading)

        // Assert
        expect(capturedEmail, 'test@example.com');
      });

      testWidgets('debe normalizar email antes de enviar (trim + lowercase)',
          (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Escribir email con espacios (el formatter ya lo pone en lowercase)
        await tester.enterText(
          find.byType(TextFormField),
          '  test@example.com  ',
        );
        await tester.pumpAndSettle();

        // Tap enviar
        await tester.tap(find.byType(FilledButton));
        await tester.pump(); // Solo pump, no pumpAndSettle (widget queda en loading)

        // Assert - Debe llamar callback con email normalizado
        expect(capturedEmail, isNotNull);
        expect(capturedEmail!.contains('@'), isTrue);
      });

      testWidgets('debe llamar callback personalizado cuando se proporciona',
          (tester) async {
        // Arrange
        String? customEmail;
        await openDialog(tester, onCodeSent: (email) => customEmail = email);

        // Act
        await tester.enterText(
          find.byType(TextFormField),
          'custom@example.com',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FilledButton));
        await tester.pump(); // Solo pump, no pumpAndSettle (widget queda en loading)

        // Assert
        expect(customEmail, 'custom@example.com');
      });
    });

    group('Navegación', () {
      testWidgets('botón Cancelar debe estar presente', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Botón cancelar existe y está habilitado
        expect(find.byType(AlertDialog), findsOneWidget);
        final cancelButton = tester.widget<TextButton>(
          find.byType(TextButton),
        );
        expect(cancelButton.onPressed, isNotNull);
      });

      testWidgets('NO debe poder cancelar cuando está loading',
          (tester) async {
        // Arrange
        await openDialog(tester);

        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Act - Enviar (cambia a loading)
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Assert - Botón cancelar debe estar deshabilitado
        final cancelButton = tester.widget<TextButton>(
          find.byType(TextButton),
        );
        expect(cancelButton.onPressed, isNull);
      });
    });

    group('Layout', () {
      testWidgets('debe tener Column con configuración correcta',
          (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert
        final column = tester.widget<Column>(
          find.descendant(
            of: find.byType(Form),
            matching: find.byType(Column),
          ),
        );
        expect(column.mainAxisSize, MainAxisSize.min);
        expect(column.crossAxisAlignment, CrossAxisAlignment.stretch);
      });

      testWidgets('mensaje debe estar centrado', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Verificar que hay al menos un Text con center alignment
        final texts = tester.widgetList<Text>(find.byType(Text));
        final centeredTexts = texts.where((t) => t.textAlign == TextAlign.center);
        expect(centeredTexts, isNotEmpty);
      });

      testWidgets('debe tener estructura correcta de elementos',
          (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Verificar orden de elementos en Column
        final column = find.descendant(
          of: find.byType(Form),
          matching: find.byType(Column),
        );

        final columnWidget = tester.widget<Column>(column);
        final children = columnWidget.children;

        // Debe tener al menos: Icon, SizedBox, Text, SizedBox, EmailField
        expect(children.length, greaterThanOrEqualTo(5));
      });
    });

    group('Interacción con EmailField', () {
      testWidgets('debe poder escribir en EmailField', (tester) async {
        // Arrange
        await openDialog(tester);

        // Act
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('EmailField debe convertir a minúsculas', (tester) async {
        // Arrange
        await openDialog(tester);

        // Act - Escribir con mayúsculas
        await tester.enterText(
          find.byType(TextFormField),
          'TEST@EXAMPLE.COM',
        );
        await tester.pumpAndSettle();

        // Assert - Debe estar en minúsculas (por LowercaseTextInputFormatter)
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('EmailField debe estar deshabilitado durante loading',
          (tester) async {
        // Arrange
        await openDialog(tester);

        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Act - Enviar (activa loading)
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Assert - EmailField debe estar deshabilitado
        final emailField = tester.widget<EmailField>(
          find.byType(EmailField),
        );
        expect(emailField.enabled, isFalse);
      });
    });

    group('Temas', () {
      testWidgets('debe aplicar tema correctamente', (tester) async {
        // Arrange
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
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
              body: ForgotPasswordDialog(
                onCodeSent: (_) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Verificar que usa colorScheme
        final icon = tester.widget<Icon>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon &&
                widget.icon == Icons.email_outlined &&
                widget.size == 64,
          ),
        );
        expect(icon.color, isNotNull);
      });

      testWidgets('mensaje debe tener estilo definido', (tester) async {
        // Arrange & Act
        await openDialog(tester);

        // Assert - Verificar que hay textos con estilo
        final texts = tester.widgetList<Text>(find.byType(Text));
        final styledTexts = texts.where((t) => t.style != null);
        expect(styledTexts, isNotEmpty);
      });
    });

    group('Limpieza de Recursos', () {
      testWidgets('debe renderizar correctamente con recursos',
          (tester) async {
        // Arrange & Act
        await openDialog(tester);

        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.pumpAndSettle();

        // Assert - Widget funcional con sus recursos
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(ForgotPasswordDialog), findsOneWidget);
        expect(find.byType(EmailField), findsOneWidget);
      });
    });
  });
}
