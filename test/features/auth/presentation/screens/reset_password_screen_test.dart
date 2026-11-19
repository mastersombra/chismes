import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:chismes/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/l10n/l10n.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/screens/login_screen.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../../../helpers/test_di_helper.dart';
import 'reset_password_screen_test.mocks.dart';
import 'login_screen_test.mocks.dart' as login_mocks;

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

  group('ResetPasswordScreen - Estados y validación', () {
    AppLocalizations l10nOf(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(ResetPasswordScreen)))!;

    List<VoidCallback> captureListeners() {
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((inv) {
        listeners.add(inv.positionalArguments[0] as VoidCallback);
      });
      return listeners;
    }

    testWidgets('contraseñas distintas muestran error y no envían', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ValidPassword123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'OtherPassword123!');
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).passwordsMustMatch), findsOneWidget);
      verifyNever(mockController.updatePassword(newPassword: anyNamed('newPassword')));
    });

    testWidgets('AuthError muestra snackbar rojo con el mensaje traducido',
        (tester) async {
      final listeners = captureListeners();
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      final failure =
          AuthFailure(code: ErrorCode.networkError, technicalMessage: 'net');

      when(mockController.state).thenReturn(AuthError(failure));
      for (final l in listeners) {
        l();
      }
      await tester.pump();

      expect(tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
          Colors.red);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(AuthError(failure)
              .getMessage(tester.element(find.byType(ResetPasswordScreen)))),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AuthPasswordUpdated muestra diálogo y OK lleva a LoginScreen',
        (tester) async {
      final loginController = login_mocks.MockLoginController();
      when(loginController.state).thenReturn(const AuthInitial());
      getIt.registerSingleton<LoginController>(loginController);
      addTearDown(() => getIt.unregister<LoginController>());

      final listeners = captureListeners();
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      when(mockController.state).thenReturn(const AuthPasswordUpdated());
      for (final l in listeners) {
        l();
      }
      await tester.pumpAndSettle();

      expect(find.text(l10n.passwordUpdatedSuccessTitle), findsOneWidget);
      expect(find.text(l10n.passwordUpdatedSuccessMessage), findsOneWidget);

      await tester.tap(find.text(l10n.resetPasswordOkButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ResetPasswordScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('el diálogo de éxito no se cierra tocando fuera', (tester) async {
      final listeners = captureListeners();
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      when(mockController.state).thenReturn(const AuthPasswordUpdated());
      for (final l in listeners) {
        l();
      }
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
