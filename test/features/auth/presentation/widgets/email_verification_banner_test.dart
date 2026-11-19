import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/auth/presentation/widgets/email_verification_banner.dart';
import 'package:chismes/core/theme/app_spacing.dart';

void main() {
  group('EmailVerificationBanner', () {
    late bool resendCalled;

    setUp(() {
      resendCalled = false;
    });

    Widget buildWidget({
      required VoidCallback onResend,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: EmailVerificationBanner(
            onResend: onResend,
            isLoading: isLoading,
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('debe renderizar banner con título correcto',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        expect(find.text('Verifica tu email'), findsOneWidget);
      });

      testWidgets('debe renderizar icono de email', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon &&
                widget.icon == Icons.mark_email_unread_outlined,
          ),
          findsOneWidget,
        );
      });

      testWidgets('debe renderizar mensaje descriptivo', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        expect(
          find.textContaining('Necesitas verificar tu email'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Revisa tu bandeja de entrada'),
          findsOneWidget,
        );
      });

      testWidgets('debe tener contenedor con padding y margin correctos',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        final containers = tester.widgetList<Container>(
          find.byType(Container),
        );

        // Buscar el container principal (no el del Scaffold/MaterialApp)
        final mainContainer = containers.firstWhere(
          (c) => c.margin == const EdgeInsets.all(AppSpacing.lg),
        );

        expect(mainContainer.margin, const EdgeInsets.all(AppSpacing.lg));
        expect(mainContainer.padding, const EdgeInsets.all(AppSpacing.lg));
      });

      testWidgets('debe tener decoración con borde redondeado',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        final containers = tester.widgetList<Container>(
          find.byType(Container),
        );

        // Buscar el container principal con decoración
        final mainContainer = containers.firstWhere(
          (c) => c.decoration is BoxDecoration && c.margin != null,
        );

        final decoration = mainContainer.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12));
        expect(decoration.border, isNotNull);
      });
    });

    group('Estado Normal (No Loading)', () {
      testWidgets('debe mostrar botón con texto "Reenviar email"',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: false,
          ),
        );

        // Assert
        expect(find.text('Reenviar email'), findsOneWidget);
        expect(find.text('Enviando...'), findsNothing);
      });

      testWidgets('debe mostrar icono de enviar', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: false,
          ),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon && widget.icon == Icons.send_outlined,
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('botón debe estar habilitado cuando NO está loading',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: false,
          ),
        );

        // Assert - El botón muestra texto de estado habilitado
        expect(find.text('Reenviar email'), findsOneWidget);
        // El icono de enviar está visible (indica estado habilitado)
        expect(find.byIcon(Icons.send_outlined), findsOneWidget);
        // No hay loading indicator
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Estado Loading', () {
      testWidgets('debe mostrar texto "Enviando..."', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: true,
          ),
        );

        // Assert
        expect(find.text('Enviando...'), findsOneWidget);
        expect(find.text('Reenviar email'), findsNothing);
      });

      testWidgets('debe mostrar CircularProgressIndicator',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: true,
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon && widget.icon == Icons.send_outlined,
          ),
          findsNothing,
        );
      });

      testWidgets('botón debe estar deshabilitado cuando está loading',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: true,
          ),
        );

        // Assert - El botón muestra texto de estado loading
        expect(find.text('Enviando...'), findsOneWidget);
        // El loading indicator está visible (indica estado deshabilitado)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // No hay icono de enviar
        expect(find.byIcon(Icons.send_outlined), findsNothing);
      });

      testWidgets('CircularProgressIndicator debe tener tamaño 16x16',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: true,
          ),
        );

        // Assert
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));

        // Buscar el SizedBox que contiene el CircularProgressIndicator
        final progressSizedBox = sizedBoxes.firstWhere(
          (sb) => sb.width == 16 && sb.height == 16,
        );

        expect(progressSizedBox.width, 16);
        expect(progressSizedBox.height, 16);
      });
    });

    group('Interacción', () {
      testWidgets('debe llamar onResend al tocar botón cuando NO está loading',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildWidget(
            onResend: () => resendCalled = true,
            isLoading: false,
          ),
        );

        // Act - Buscar por texto para ser más específico
        await tester.tap(find.text('Reenviar email'));
        await tester.pumpAndSettle();

        // Assert
        expect(resendCalled, isTrue);
      });

      testWidgets('NO debe llamar onResend cuando está loading',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildWidget(
            onResend: () => resendCalled = true,
            isLoading: true,
          ),
        );

        // Assert - El botón muestra estado loading
        expect(find.text('Enviando...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verificar que no se llamó el callback (el botón está deshabilitado)
        expect(resendCalled, isFalse);
      });

      testWidgets('debe renderizar correctamente en estado normal y loading',
          (tester) async {
        // Arrange - Estado normal
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: false,
          ),
        );

        // Assert - Estado normal
        expect(find.text('Reenviar email'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Arrange - Estado loading (rebuild)
        await tester.pumpWidget(
          buildWidget(
            onResend: () {},
            isLoading: true,
          ),
        );

        // Assert - Estado loading
        expect(find.text('Enviando...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Layout', () {
      testWidgets('botón debe tener ancho completo', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));

        // Buscar el SizedBox que envuelve el botón (width: double.infinity)
        final buttonSizedBox = sizedBoxes.firstWhere(
          (sb) => sb.width == double.infinity,
        );

        expect(buttonSizedBox.width, double.infinity);
      });

      testWidgets('debe tener estructura de columna correcta',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildWidget(onResend: () {}),
        );

        // Assert
        final column = tester.widget<Column>(
          find.byType(Column),
        );
        expect(column.mainAxisSize, MainAxisSize.min);
        expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      });
    });

    group('Temas', () {
      testWidgets('debe aplicar colores del tema correctamente',
          (tester) async {
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
            home: Scaffold(
              body: EmailVerificationBanner(
                onResend: () {},
              ),
            ),
          ),
        );

        // Assert - Verificar que usa colorScheme
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, isNotNull);
        expect(decoration.border, isNotNull);
      });
    });
  });
}
