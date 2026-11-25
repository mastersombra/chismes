import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/presentation/controllers/signup_controller.dart';
import 'package:chismes/features/auth/presentation/screens/signup_screen.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:chismes/features/auth/presentation/widgets/auth_button.dart';
import 'package:chismes/features/auth/presentation/widgets/email_field.dart';
import 'package:chismes/features/auth/presentation/widgets/password_field.dart';
import 'package:chismes/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/legal/legal_consent_text.dart';
import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/presentation/controllers/profile_setup_controller.dart';
import 'package:chismes/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:chismes/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'signup_screen_test.mocks.dart';
import 'profile_setup_screen_test.mocks.dart' as setup_mocks;
import '../../../../helpers/mock_app_logger_helper.dart' as logger_helper;

@GenerateMocks([SignupController])
void main() {
  late MockSignupController mockController;

  setUpAll(() {
    provideDummy<AuthState>(const AuthInitial());
  });

  setUp(() async {
    // Inicializar DI para tests (LocaleNotifier, SharedPreferences, etc.)
    await setupTestDI();

    mockController = MockSignupController();
    when(mockController.state).thenReturn(const AuthInitial());
    when(mockController.addListener(any)).thenReturn(null);
    when(mockController.removeListener(any)).thenReturn(null);

    // Registrar mock en GetIt
    if (getIt.isRegistered<SignupController>()) {
      getIt.unregister<SignupController>();
    }
    getIt.registerSingleton<SignupController>(mockController);
  });

  tearDown(() async {
    if (getIt.isRegistered<SignupController>()) {
      getIt.unregister<SignupController>();
    }

    // Limpiar DI después del test
    await tearDownTestDI();
  });

  Widget makeTestableWidget(Widget child) {
    return testableWidget(child: child, useScaffold: false);
  }

  group('SignupScreen', () {
    testWidgets('debe renderizar correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Únete a Chismes'), findsOneWidget);
      expect(find.text('Crea tu cuenta en segundos'), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('signup_screen_key');

      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen(key: testKey)),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe renderizar AppBar con título', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Crear Cuenta'), findsWidgets); // Aparece en AppBar y botón
    });

    testWidgets('debe renderizar todos los campos del formulario', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(EmailField), findsOneWidget);
      expect(find.byType(PasswordField), findsNWidgets(2)); // Contraseña y confirmar
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('debe renderizar botón "Crear Cuenta"', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Crear Cuenta'), findsWidgets); // Aparece en AppBar y botón
      expect(find.widgetWithText(AuthButton, 'Crear Cuenta'), findsOneWidget);
    });

    testWidgets('debe renderizar términos y condiciones', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(LegalConsentText), findsOneWidget);
      expect(
        find.text(
          'Al continuar, aceptas los Términos de uso y la Política de privacidad.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('debe renderizar link de inicio de sesión', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('¿Ya tienes cuenta? '), findsOneWidget);
      expect(find.text('Inicia sesión'), findsOneWidget);
    });

    testWidgets('debe tener campos habilitados cuando no está cargando', (WidgetTester tester) async {
      // Arrange
      when(mockController.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      final emailField = tester.widget<EmailField>(find.byType(EmailField));
      expect(emailField.enabled, isTrue);
    });

    testWidgets('debe deshabilitar campos cuando está cargando', (WidgetTester tester) async {
      // Arrange
      when(mockController.state).thenReturn(const AuthLoading());

      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pump(); // Use pump() not pumpAndSettle() when loading (CircularProgressIndicator animates forever)

      // Assert
      final emailField = tester.widget<EmailField>(find.byType(EmailField));
      expect(emailField.enabled, isFalse);
    });

    testWidgets('debe llamar signUpWithEmail cuando se presiona el botón', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Ingresar datos válidos
      await tester.enterText(find.byType(EmailField), 'test@example.com');

      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'Test123!@');
      await tester.enterText(passwordFields.at(1), 'Test123!@');

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pump();

      // Assert
      verify(mockController.signUpWithEmail(
        email: 'test@example.com',
        password: 'Test123!@',
      )).called(1);
    });

    testWidgets('debe actualizar PasswordStrengthIndicator al escribir contraseña', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Act
      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'weak');
      await tester.pump();

      // Assert
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('debe volver a login al presionar "Inicia sesión"', (WidgetTester tester) async {
      // Arrange
      bool popCalled = false;

      await tester.pumpWidget(
        testableWidget(
          child: Navigator(
            onDidRemovePage: (page) {
              popCalled = true;
            },
            pages: const [
              MaterialPage(child: Scaffold(body: Text('Login'))),
              MaterialPage(child: SignupScreen()),
            ],
          ),
          useScaffold: false,
        ),
      );
      await tester.pumpAndSettle();
      // Act
      await tester.tap(find.text('Inicia sesión'));
      await tester.pumpAndSettle();

      // Assert
      expect(popCalled, isTrue);
    });

    testWidgets('debe tener SafeArea', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('debe tener Scaffold', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe tener Form', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('debe tener SingleChildScrollView', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('el aviso de políticas va antes del botón de crear cuenta', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert: se lee antes de poder crear la cuenta
      final consentY = tester.getTopLeft(find.byType(LegalConsentText)).dy;
      final buttonY = tester
          .getTopLeft(find.widgetWithText(AuthButton, 'Crear Cuenta'))
          .dy;
      expect(consentY, lessThan(buttonY));
    });

    testWidgets('no debe llamar signUpWithEmail si form no es válido', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // No ingresar datos (campos vacíos)

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pump();

      // Assert
      verifyNever(mockController.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    testWidgets('debe tener label "Contraseña" en primer campo de password', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      final passwordFields = tester.widgetList<PasswordField>(find.byType(PasswordField));
      final firstPasswordField = passwordFields.first;
      expect(firstPasswordField.labelText, 'Contraseña');
    });

    testWidgets('debe tener label "Confirmar contraseña" en segundo campo de password', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      final passwordFields = tester.widgetList<PasswordField>(find.byType(PasswordField));
      final secondPasswordField = passwordFields.last;
      expect(secondPasswordField.labelText, 'Confirmar contraseña');
    });

    testWidgets('debe tener Column principal con CrossAxisAlignment.stretch', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      final columnFinder = find.descendant(
        of: find.byType(Form),
        matching: find.byType(Column),
      );
      expect(columnFinder, findsOneWidget);

      final column = tester.widget<Column>(columnFinder);
      expect(column.crossAxisAlignment, CrossAxisAlignment.stretch);
    });

    testWidgets('debe deshabilitar botón "Inicia sesión" cuando está cargando', (WidgetTester tester) async {
      // Arrange
      when(mockController.state).thenReturn(const AuthLoading());

      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pump(); // Use pump() not pumpAndSettle() when loading (CircularProgressIndicator animates forever)

      // Assert
      final textButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Inicia sesión'),
      );
      expect(textButton.onPressed, isNull);
    });

    testWidgets('debe tener SizedBox para espaciado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('debe limpiar controllers en dispose', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Act - remover widget
      await tester.pumpWidget(
        makeTestableWidget(const Scaffold(body: Text('Different screen'))),
      );
      await tester.pumpAndSettle();
      // Assert - verificar que removeListener fue llamado
      verify(mockController.removeListener(any)).called(greaterThan(0));
    });

    testWidgets('AuthSuccess reemplaza la pantalla por ProfileSetupScreen', (WidgetTester tester) async {
      // Arrange
      final setupController = setup_mocks.MockProfileSetupController();
      final authService = setup_mocks.MockAuthService();
      when(setupController.state).thenReturn(const AuthInitial());
      when(setupController.checkingUsername).thenReturn(false);
      when(setupController.usernameAvailable).thenReturn(null);
      when(authService.currentUser).thenReturn(null);
      getIt.registerSingleton<ProfileSetupController>(setupController);
      getIt.registerSingleton<AuthService>(authService);
      addTearDown(() async {
        await getIt.unregister<ProfileSetupController>();
        await getIt.unregister<AuthService>();
      });
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Cambiar estado a success
      final user = User(
        id: '123',
        email: 'test@example.com',
          emailVerified: true,
        profileCompleted: false,
        createdAt: DateTime.now(),
      );
      when(mockController.state).thenReturn(AuthSuccess(user));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pumpAndSettle();

      // Assert - verificar que el listener fue ejecutado
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(SignupScreen), findsNothing);
    });

    testWidgets('AuthError de red muestra snackbar rojo con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Cambiar estado a error
      final failure = AuthFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network error',
      );
      when(mockController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verificar que el listener fue ejecutado
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(SignupScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('debe validar que contraseña de confirmación coincida', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Ingresar datos válidos pero contraseñas diferentes
      await tester.enterText(find.byType(EmailField), 'test@example.com');

      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'Test123!@');
      await tester.enterText(passwordFields.at(1), 'Different123!@');

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pump();

      // Assert - no debería llamar al controller si la validación falla
      verifyNever(mockController.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    testWidgets('debe validar que contraseña de confirmación no esté vacía', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Ingresar datos válidos pero sin confirmar contraseña
      await tester.enterText(find.byType(EmailField), 'test@example.com');

      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'Test123!@');
      // No ingresar nada en el segundo campo

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pump();

      // Assert - no debería llamar al controller si la validación falla
      verifyNever(mockController.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    testWidgets('debe validar contraseña vacía', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Ingresar solo email
      await tester.enterText(find.byType(EmailField), 'test@example.com');
      // No ingresar contraseña

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pump();

      // Assert - no debería llamar al controller si la validación falla
      verifyNever(mockController.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    testWidgets('debe validar contraseña muy corta', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Ingresar contraseña muy corta
      await tester.enterText(find.byType(EmailField), 'test@example.com');

      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'Test12');
      await tester.enterText(passwordFields.at(1), 'Test12');

      // Act
      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pump();

      // Assert - no debería llamar al controller si la validación falla
      verifyNever(mockController.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    testWidgets('debe actualizar _currentPassword al escribir en el campo de contraseña', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Act - escribir en el campo de contraseña
      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'TestPassword123');
      await tester.pump();

      // Assert - PasswordStrengthIndicator debería reflejar el cambio
      final indicator = tester.widget<PasswordStrengthIndicator>(
        find.byType(PasswordStrengthIndicator),
      );
      expect(indicator.password, 'TestPassword123');
    });

    testWidgets('email en uso muestra snackbar con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(makeTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Cambiar estado a error de email en uso
      final failure = AuthFailure(
        code: ErrorCode.emailAlreadyInUse,
        technicalMessage: 'Email already in use',
      );
      when(mockController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verifica que el listener fue capturado y ejecutado
      // (esto cubre _onStateChanged y _showError para error de email en uso)
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(SignupScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('contraseña débil muestra snackbar con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(makeTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Cambiar estado a error de contraseña débil
      final failure = AuthFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: 'Password is too weak',
      );
      when(mockController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verifica que el listener fue capturado y ejecutado
      // (esto cubre _onStateChanged y _showError para error de contraseña débil)
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(SignupScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('debe normalizar email antes de signup', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(makeTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Act - ingresar email con espacios y mayúsculas
      await tester.enterText(find.byType(EmailField), '  NewUser@Example.COM  ');
      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');

      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pumpAndSettle();

      // Assert - debe normalizar email (trim + lowercase)
      verify(mockController.signUpWithEmail(
        email: 'newuser@example.com',
        password: 'Password123!',
      )).called(1);
    });

    testWidgets('sin conexión muestra snackbar con el mensaje traducido', (WidgetTester tester) async {
      // Arrange
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments[0] as VoidCallback);
      });
      when(mockController.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(makeTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Cambiar estado a error de red
      final failure = AuthFailure(
        code: ErrorCode.noInternetConnection,
        technicalMessage: 'No internet connection',
      );
      when(mockController.state).thenReturn(AuthError(failure));

      // Act - llamar listener manualmente
      for (final listener in listeners) {
        listener();
      }
      await tester.pump();

      // Assert - verifica que el listener fue capturado y ejecutado
      // (esto cubre _onStateChanged y _showError para error de red)
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(
        find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(AuthError(failure)
                .getMessage(tester.element(find.byType(SignupScreen))))),
        findsOneWidget,
      );
    });

    testWidgets('no debe llamar signUpWithEmail con formato de email inválido', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(makeTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Act - ingresar email con formato inválido
      await tester.enterText(find.byType(EmailField), 'invalid-email');
      final passwordFields = find.byType(PasswordField);
      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');

      await tester.tap(find.widgetWithText(AuthButton, 'Crear Cuenta'));
      await tester.pumpAndSettle();

      // Assert - no debe llamar signUpWithEmail porque el form no es válido
      verifyNever(mockController.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });
  });

  testWidgets('AuthOtpSent reemplaza la pantalla por OtpVerificationScreen',
      (WidgetTester tester) async {
    getIt.registerSingleton<AppLogger>(logger_helper.MockAppLogger());
    getIt.registerSingleton<AuthRepository>(_MockAuthRepository());
    addTearDown(() async {
      await getIt.unregister<AppLogger>();
      await getIt.unregister<AuthRepository>();
    });
    final listeners = <VoidCallback>[];
    when(mockController.addListener(any)).thenAnswer((invocation) {
      listeners.add(invocation.positionalArguments[0] as VoidCallback);
    });
    await tester.pumpWidget(makeTestableWidget(const SignupScreen()));
    await tester.pumpAndSettle();

    when(mockController.state).thenReturn(const AuthOtpSent('new@test.com'));
    for (final listener in listeners) {
      listener();
    }
    await tester.pumpAndSettle();

    expect(find.byType(SignupScreen), findsNothing);
    final otp =
        tester.widget<OtpVerificationScreen>(find.byType(OtpVerificationScreen));
    expect(otp.controller.state.email, 'new@test.com');
    expect(otp.onSuccess, isNull);
  });
}

class _MockAuthRepository extends Mock implements AuthRepository {}
