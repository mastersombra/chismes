import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/auth/presentation/screens/login_screen.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/widgets/email_field.dart';
import 'package:chismes/features/auth/presentation/widgets/password_field.dart';
import 'package:chismes/features/auth/presentation/widgets/auth_button.dart';
import 'package:chismes/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:chismes/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:chismes/features/gossip/presentation/controllers/add_gossip_controller.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:chismes/features/auth/presentation/controllers/signup_controller.dart';
import 'package:chismes/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:chismes/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:chismes/features/auth/presentation/screens/signup_screen.dart';
import 'package:chismes/core/logging/app_logger.dart';
import '../../../../helpers/mock_app_logger_helper.dart' as logger_helper;

import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'login_screen_test.mocks.dart';
import 'reset_password_screen_test.mocks.dart' as reset_mocks;
import 'signup_screen_test.mocks.dart' as signup_mocks;

@GenerateMocks([AddGossipController, GetGossips, LoginController])
void main() {
  late MockLoginController mockLoginController;

  setUpAll(() {
    // Provide dummy values for complex types
    provideDummy<Result<Failure, List<Gossip>>>(
      Result.success(const []),
    );
    provideDummy<AuthState>(const AuthInitial());
  });

  setUp(() async {
    // Inicializar DI para tests (LocaleNotifier, SharedPreferences, etc.)
    await setupTestDI();

    mockLoginController = MockLoginController();
    when(mockLoginController.state).thenReturn(const AuthInitial());
    when(mockLoginController.addListener(any)).thenReturn(null);
    when(mockLoginController.removeListener(any)).thenReturn(null);

    // Registrar mock en GetIt
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
    getIt.registerSingleton<LoginController>(mockLoginController);
  });

  tearDown(() async {
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }

    // Limpiar DI después del test
    await tearDownTestDI();
  });

  Widget createTestWidget() {
    return testableWidget(
      child: const LoginScreen(),
      useScaffold: false,
    );
  }

  group('LoginScreen', () {
    testWidgets('debe renderizar AppBar con título "Iniciar Sesión"', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsWidgets);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('login_screen_key');

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: const LoginScreen(key: testKey),
          useScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('AppBar debe estar en el Scaffold', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.appBar, isNotNull);
      expect(scaffold.appBar, isA<AppBar>());
    });

    testWidgets('debe renderizar todos los elementos principales', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Chismes'), findsOneWidget);
      expect(find.text('Comparte historias, descubre secretos'), findsOneWidget);
      expect(find.byType(EmailField), findsOneWidget);
      expect(find.byType(PasswordField), findsOneWidget);
      expect(find.byType(SocialLoginButtons), findsOneWidget);
      expect(find.text('¿No tienes cuenta? '), findsOneWidget);
      expect(find.text('Regístrate'), findsOneWidget);
    });

    testWidgets('debe renderizar botones de autenticación', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Iniciar Sesión'), findsWidgets); // Aparece en AppBar y botón
      expect(find.byType(AuthButton), findsOneWidget); // Botón principal de login
      expect(find.byType(SocialLoginButtons), findsOneWidget); // Botones sociales
      expect(find.text('O continúa con'), findsOneWidget);
    });

    testWidgets('debe tener campos habilitados cuando no está cargando', (WidgetTester tester) async {
      // Arrange
      when(mockLoginController.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final emailField = tester.widget<EmailField>(find.byType(EmailField));
      final passwordField = tester.widget<PasswordField>(find.byType(PasswordField));

      expect(emailField.enabled, isTrue);
      expect(passwordField.enabled, isTrue);
    });

    testWidgets('debe deshabilitar campos cuando está cargando', (WidgetTester tester) async {
      // Arrange - Configurar estado loading desde el principio
      final loadingController = MockLoginController();
      when(loadingController.state).thenReturn(const AuthLoading());
      when(loadingController.addListener(any)).thenReturn(null);
      when(loadingController.removeListener(any)).thenReturn(null);

      // Registrar mock con estado loading
      if (getIt.isRegistered<LoginController>()) {
        getIt.unregister<LoginController>();
      }
      getIt.registerSingleton<LoginController>(loadingController);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Usar pump() en lugar de pumpAndSettle() porque loading tiene animaciones infinitas

      // Assert
      final emailField = tester.widget<EmailField>(find.byType(EmailField));
      final passwordField = tester.widget<PasswordField>(find.byType(PasswordField));

      expect(emailField.enabled, isFalse);
      expect(passwordField.enabled, isFalse);
    });

    testWidgets('debe llamar signInWithEmail cuando se presiona botón de login', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ingresar datos válidos
      await tester.enterText(find.byType(EmailField), 'test@example.com');
      await tester.enterText(find.byType(PasswordField), 'Test123!@');

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Iniciar Sesión'));
      await tester.pump();

      // Assert
      verify(mockLoginController.signInWithEmail(
        email: 'test@example.com',
        password: 'Test123!@',
      )).called(1);
    });

    testWidgets('debe llamar signInWithGoogle cuando se presiona botón de Google', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Buscar el SocialLoginButtons y simular tap en Google
      final socialButtons = tester.widget<SocialLoginButtons>(find.byType(SocialLoginButtons));

      // Act
      socialButtons.onGooglePressed();

      // Assert
      verify(mockLoginController.signInWithGoogle()).called(1);
    });

    testWidgets('debe llamar signInWithApple cuando se presiona botón de Apple', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Buscar el SocialLoginButtons y simular tap en Apple
      final socialButtons = tester.widget<SocialLoginButtons>(find.byType(SocialLoginButtons));

      // Act
      socialButtons.onApplePressed();

      // Assert
      verify(mockLoginController.signInWithApple()).called(1);
    });

    testWidgets('"Regístrate" navega a SignupScreen', (WidgetTester tester) async {
      final signupController = signup_mocks.MockSignupController();
      when(signupController.state).thenReturn(const AuthInitial());
      getIt.registerSingleton<SignupController>(signupController);
      addTearDown(() => getIt.unregister<SignupController>());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Regístrate'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('error de autenticación muestra snackbar rojo con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockLoginController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockLoginController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Cambiar estado a error
      final failure = AuthFailure(
        code: ErrorCode.invalidCredentials,
        technicalMessage: 'Invalid credentials',
      );
      when(mockLoginController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente (esto ejecuta _onStateChanged y _showError)
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verificar que el listener fue capturado y ejecutado
      // (esto cubre las líneas del método _onStateChanged y _showError)
      expect(listeners, isNotEmpty);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(LoginScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('login exitoso no muestra snackbar de error', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockLoginController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockLoginController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Cambiar estado a success
      final user = User(
        id: '123',
        email: 'test@example.com',
          emailVerified: true,
        profileCompleted: true,
        createdAt: DateTime.now(),
      );
      when(mockLoginController.state).thenReturn(AuthSuccess(user));

      // Act - llamar listener manualmente (esto ejecuta _onStateChanged y _navigateToHome)
      for (final listener in listeners) {
        listener();
      }
      await tester.pumpAndSettle();

      // Assert - verificar que el listener fue capturado y ejecutado
      // (esto cubre las líneas del método _onStateChanged y _navigateToHome)
      expect(listeners, isNotEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('debe limpiar controllers en dispose', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - remover widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different screen')),
        ),
      );

      // Assert - verificar que removeListener fue llamado al menos una vez
      verify(mockLoginController.removeListener(any)).called(greaterThan(0));
    });

    testWidgets('no debe llamar signInWithEmail si form no es válido', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // No ingresar datos (campos vacíos)

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Iniciar Sesión'));
      await tester.pump();

      // Assert
      verifyNever(mockLoginController.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    testWidgets('no debe mostrar error si widget no está montado', (WidgetTester tester) async {
      // Arrange
      final failure = AuthFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network error',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Desmontar widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different screen')),
        ),
      );

      // Act - cambiar estado después de desmontar
      when(mockLoginController.state).thenReturn(AuthError(failure));

      // Assert - no debe causar error
      await tester.pump();
    });

    testWidgets('error de timeout muestra snackbar con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockLoginController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockLoginController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Cambiar estado a error de timeout
      final failure = AuthFailure(
        code: ErrorCode.timeoutError,
        technicalMessage: 'Request timeout',
      );
      when(mockLoginController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verifica que el listener fue capturado y ejecutado
      // (esto cubre _onStateChanged y _showError para errores de timeout)
      expect(listeners, isNotEmpty);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(LoginScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('error unauthorized muestra snackbar con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockLoginController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockLoginController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Cambiar estado a error de credenciales inválidas
      final failure = AuthFailure(
        code: ErrorCode.unauthorized,
        technicalMessage: 'Invalid credentials',
      );
      when(mockLoginController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verifica que el listener fue capturado y ejecutado
      // (esto cubre _onStateChanged y _showError para errores de autorización)
      expect(listeners, isNotEmpty);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(LoginScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('debe normalizar email antes de login', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - ingresar email con espacios y mayúsculas
      await tester.enterText(find.byType(EmailField), '  Test@Example.COM  ');
      await tester.enterText(find.byType(PasswordField), 'Password123!');

      await tester.tap(find.widgetWithText(AuthButton, 'Iniciar Sesión'));
      await tester.pumpAndSettle();

      // Assert - debe normalizar email (trim + lowercase)
      verify(mockLoginController.signInWithEmail(
        email: 'test@example.com',
        password: 'Password123!',
      )).called(1);
    });

    testWidgets('debe abrir ForgotPasswordDialog al presionar "¿Olvidaste tu contraseña?"', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - buscar y presionar el link de "Olvidaste tu contraseña"
      final forgotPasswordButton = find.text('¿Olvidaste tu contraseña?');
      expect(forgotPasswordButton, findsOneWidget);

      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      // Assert - debe mostrar ForgotPasswordDialog
      expect(find.byType(ForgotPasswordDialog), findsOneWidget);
    });
  });

  group('LoginScreen - Recuperar contraseña', () {
    setUp(() {
      getIt.registerSingleton<AppLogger>(logger_helper.MockAppLogger());
      getIt.registerSingleton<AuthRepository>(_MockAuthRepository());
      final resetController = reset_mocks.MockResetPasswordController();
      when(resetController.state).thenReturn(const AuthInitial());
      getIt.registerSingleton<ResetPasswordController>(resetController);
      when(mockLoginController.resetPassword(email: anyNamed('email')))
          .thenAnswer((_) async {});
    });

    tearDown(() async {
      await getIt.unregister<AppLogger>();
      await getIt.unregister<AuthRepository>();
      await getIt.unregister<ResetPasswordController>();
    });

    Future<void> sendCode(WidgetTester tester, String email) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      tester
          .widget<ForgotPasswordDialog>(find.byType(ForgotPasswordDialog))
          .onCodeSent(email);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }

    testWidgets('enviar código cierra el diálogo, pide el reset y abre OTP',
        (tester) async {
      await sendCode(tester, 'user@test.com');

      expect(find.byType(ForgotPasswordDialog), findsNothing);
      verify(mockLoginController.resetPassword(email: 'user@test.com')).called(1);
      expect(find.byType(OtpVerificationScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final otp = tester.widget<OtpVerificationScreen>(
          find.byType(OtpVerificationScreen));
      expect(otp.controller.state.email, 'user@test.com');
      expect(otp.onSuccess, isNotNull);
    });

    testWidgets('verificar el OTP reemplaza la pantalla por ResetPasswordScreen',
        (tester) async {
      await sendCode(tester, 'user@test.com');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      tester
          .widget<OtpVerificationScreen>(find.byType(OtpVerificationScreen))
          .onSuccess!();
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsNothing);
      final reset =
          tester.widget<ResetPasswordScreen>(find.byType(ResetPasswordScreen));
      expect(reset.email, 'user@test.com');
    });

    testWidgets('si la pantalla se desmonta antes de 300ms no navega',
        (tester) async {
      await sendCode(tester, 'user@test.com');

      await tester.pumpWidget(const MaterialApp(home: Text('OTRA')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.text('OTRA'), findsOneWidget);
    });
  });
}

class _MockAuthRepository extends Mock implements AuthRepository {}
