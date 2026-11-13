import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:chismes/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:chismes/core/di/injection_container.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../../../helpers/test_di_helper.dart';
import 'reset_password_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ResetPasswordController>(),
])
void main() {
  late MockResetPasswordController mockController;

  setUp(() async {
    // Inicializar DI primero (necesario para LanguageSelector)
    await setupTestDI();

    mockController = MockResetPasswordController();

    // Proporcionar dummy value para AuthState
    provideDummy<AuthState>(const AuthInitial());

    // Setup mocks básicos
    when(mockController.state).thenReturn(const AuthInitial());
    when(mockController.addListener(any)).thenReturn(null);
    when(mockController.removeListener(any)).thenReturn(null);
    when(mockController.updatePassword(newPassword: anyNamed('newPassword')))
        .thenAnswer((_) async {});

    // Registrar en DI
    if (getIt.isRegistered<ResetPasswordController>()) {
      getIt.unregister<ResetPasswordController>();
    }
    getIt.registerSingleton<ResetPasswordController>(mockController);
  });

  tearDown(() async {
    if (getIt.isRegistered<ResetPasswordController>()) {
      getIt.unregister<ResetPasswordController>();
    }
    await tearDownTestDI();
  });

  Widget createTestWidget() {
    return testableWidget(
      child: const ResetPasswordScreen(email: 'test@example.com'),
      useScaffold: false,
    );
  }

  group('ResetPasswordScreen - Básicos', () {
    testWidgets('debe renderizar la screen', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe agregar listener en initState', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // NOTE: Se llama 2 veces: 1 manual + 1 automático por AnimatedBuilder
      verify(mockController.addListener(any)).called(2);
    });

    testWidgets('debe mostrar formulario con campos', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('debe mostrar botón de cambiar contraseña', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cambiar contraseña'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen - Estados', () {
    testWidgets('debe deshabilitar campos cuando está loading', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(const AuthLoading());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // No usar pumpAndSettle con CircularProgressIndicator

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar estado inicial correctamente', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ResetPasswordScreen - Validación Básica', () {
    testWidgets('debe validar campos al presionar botón', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act: Presionar sin llenar
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();

      // Assert: No debe llamar al controller
      verifyNever(mockController.updatePassword(newPassword: anyNamed('newPassword')));
    });

    testWidgets('debe llamar updatePassword con valores válidos', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      const password = 'ValidPassword123!';

      // Act: Llenar y enviar
      await tester.enterText(find.byType(TextFormField).at(0), password);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.pump();

      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pump();

      // Assert
      verify(mockController.updatePassword(newPassword: password)).called(1);
    });
  });

  group('ResetPasswordScreen - Lifecycle', () {
    testWidgets('debe limpiar resources al hacer dispose', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act: Destruir widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Assert
      // NOTE: Se llama 2 veces: 1 manual + 1 automático por AnimatedBuilder
      verify(mockController.removeListener(any)).called(2);
    });
  });
}
