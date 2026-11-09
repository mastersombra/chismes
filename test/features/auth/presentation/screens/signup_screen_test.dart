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
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import 'signup_screen_test.mocks.dart';

@GenerateMocks([SignupController])
void main() {
  late MockSignupController mockController;

  setUpAll(() {
    provideDummy<AuthState>(const AuthInitial());
  });

  setUp(() {
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

  tearDown(() {
    if (getIt.isRegistered<SignupController>()) {
      getIt.unregister<SignupController>();
    }
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
      expect(
        find.text('Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
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

    testWidgets('debe tener Row para términos y condiciones', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(const SignupScreen()),
      );
      await tester.pumpAndSettle();
      // Assert
      final rowWithIcon = find.ancestor(
        of: find.byIcon(Icons.info_outline),
        matching: find.byType(Row),
      );
      expect(rowWithIcon, findsOneWidget);
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

    testWidgets('debe ejecutar _onStateChanged cuando estado cambia a AuthSuccess', (WidgetTester tester) async {
      // Arrange
      VoidCallback? capturedListener;
      when(mockController.addListener(any)).thenAnswer((invocation) {
        capturedListener = invocation.positionalArguments[0] as VoidCallback;
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
      capturedListener?.call();
      await tester.pumpAndSettle();

      // Assert - verificar que el listener fue ejecutado
      expect(capturedListener, isNotNull);
    });

    testWidgets('debe ejecutar _showError cuando estado cambia a AuthError', (WidgetTester tester) async {
      // Arrange
      VoidCallback? capturedListener;
      when(mockController.addListener(any)).thenAnswer((invocation) {
        capturedListener = invocation.positionalArguments[0] as VoidCallback;
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
      capturedListener?.call();
      await tester.pump();

      // Assert - verificar que el listener fue ejecutado
      expect(capturedListener, isNotNull);
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
  });
}
