import 'package:chismes/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:chismes/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:chismes/features/auth/presentation/states/otp_verification_state.dart';
import 'package:flutter/material.dart';
import 'package:chismes/core/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/auth/presentation/controllers/profile_setup_controller.dart';
import 'package:chismes/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'otp_verification_screen_test.mocks.dart';
import 'profile_setup_screen_test.mocks.dart' as setup_mocks;

@GenerateMocks([OtpVerificationController])
void main() {
  late MockOtpVerificationController mockController;

  const testEmail = 'test@example.com';

  setUp(() async {
    // Inicializar DI para tests (LocaleNotifier, SharedPreferences, etc.)
    await setupTestDI();

    mockController = MockOtpVerificationController();
  });

  tearDown(() async {
    // Limpiar DI después del test
    await tearDownTestDI();
  });

  Widget createTestWidget({VoidCallback? onSuccess}) {
    return testableWidget(
      child: OtpVerificationScreen(
        controller: mockController,
        onSuccess: onSuccess,
      ),
      useScaffold: false,
    );
  }

  group('OtpVerificationScreen', () {
    testWidgets('debe renderizar AppBar',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('otp_screen_key');
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: OtpVerificationScreen(
            key: testKey,
            controller: mockController,
          ),
          useScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe renderizar icono de email',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byIcon(Icons.mark_email_unread_outlined),
        findsOneWidget,
      );
    });

    testWidgets('debe mostrar el email del usuario',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(testEmail), findsOneWidget);
    });

    testWidgets('debe tener Scaffold y SingleChildScrollView',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('debe renderizar 6 campos de OTP',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields.length, 6);

      // Verificar que todos los campos tienen maxLength 1
      for (final field in textFields) {
        expect(field.maxLength, 1);
        expect(field.keyboardType, TextInputType.number);
        expect(field.textAlign, TextAlign.center);
      }
    });


    testWidgets('debe tener 6 TextEditingControllers internos',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - verificar que hay 6 campos
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.length, 6);
    });

    testWidgets('debe aceptar callback onSuccess personalizado',
        (WidgetTester tester) async {
      // Arrange
      var callbackCalled = false;
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(onSuccess: () {
          callbackCalled = true;
        }),
      );
      await tester.pumpAndSettle();

      // Assert - solo verificar que acepta el callback
      // La ejecución real del callback requeriría simular input complejo
      expect(callbackCalled, isFalse); // No se ha llamado aún
    });

    testWidgets('debe tener estructura correcta de widgets',
        (WidgetTester tester) async {
      // Arrange
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(
        const OtpVerificationState(email: testEmail),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - verificar estructura básica
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('OtpVerificationScreen - Interacción', () {
    void stubState(OtpVerificationState state) {
      when(mockController.addListener(any)).thenReturn(null);
      when(mockController.removeListener(any)).thenReturn(null);
      when(mockController.state).thenReturn(state);
    }

    List<String> digits(WidgetTester tester) => tester
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller!.text)
        .toList();

    bool hasFocus(WidgetTester tester, int index) =>
        tester.widget<TextField>(find.byType(TextField).at(index)).focusNode!.hasFocus;

    Future<void> typeCode(WidgetTester tester, String code) async {
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(find.byType(TextField).at(i), code[i]);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('enfoca el primer dígito al abrir', (tester) async {
      stubState(const OtpVerificationState(email: testEmail));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(hasFocus(tester, 0), isTrue);
    });

    testWidgets('escribir un dígito avanza el foco y borrarlo lo regresa',
        (tester) async {
      stubState(const OtpVerificationState(email: testEmail));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.pump();
      expect(hasFocus(tester, 1), isTrue);

      await tester.enterText(find.byType(TextField).at(1), '2');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pump();
      expect(hasFocus(tester, 0), isTrue);
      verifyNever(mockController.verifyOTP(any));
    });

    testWidgets('con 6 dígitos verifica y llama onSuccess si es correcto',
        (tester) async {
      stubState(const OtpVerificationState(email: testEmail));
      when(mockController.verifyOTP(any)).thenAnswer((_) async => true);
      var successCalls = 0;
      await tester.pumpWidget(createTestWidget(onSuccess: () => successCalls++));
      await tester.pumpAndSettle();

      await typeCode(tester, '123456');

      verify(mockController.verifyOTP('123456')).called(1);
      expect(successCalls, 1);
    });

    testWidgets('código incorrecto limpia los campos y vuelve al primero',
        (tester) async {
      stubState(const OtpVerificationState(email: testEmail));
      when(mockController.verifyOTP(any)).thenAnswer((_) async => false);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await typeCode(tester, '654321');

      verify(mockController.verifyOTP('654321')).called(1);
      expect(digits(tester), List.filled(6, ''));
      expect(hasFocus(tester, 0), isTrue);
    });

    testWidgets('sin onSuccess navega a ProfileSetupScreen', (tester) async {
      final setupController = setup_mocks.MockProfileSetupController();
      final authService = setup_mocks.MockAuthService();
      provideDummy<AuthState>(const AuthInitial());
      when(setupController.state).thenReturn(const AuthInitial());
      when(setupController.checkingUsername).thenReturn(false);
      when(setupController.usernameAvailable).thenReturn(null);
      when(authService.currentUser).thenReturn(null);
      getIt.allowReassignment = true;
      getIt.registerSingleton<ProfileSetupController>(setupController);
      getIt.registerSingleton<AuthService>(authService);
      addTearDown(() async {
        await getIt.unregister<ProfileSetupController>();
        await getIt.unregister<AuthService>();
      });

      stubState(const OtpVerificationState(email: testEmail));
      when(mockController.verifyOTP(any)).thenAnswer((_) async => true);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await typeCode(tester, '111111');

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsNothing);
    });

    testWidgets('muestra el mensaje de error del estado', (tester) async {
      stubState(const OtpVerificationState(
          email: testEmail, errorCode: ErrorCode.serverError));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('sin error no muestra el contenedor de error', (tester) async {
      stubState(const OtpVerificationState(email: testEmail));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('mientras verifica muestra loading y oculta reenviar',
        (tester) async {
      stubState(const OtpVerificationState(email: testEmail, isVerifying: true));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('reenviar disponible llama a resendOTP', (tester) async {
      stubState(const OtpVerificationState(email: testEmail, canResend: true));
      when(mockController.resendOTP()).thenAnswer((_) async {});
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(OtpVerificationScreen)))!;

      await tester.tap(find.text(l10n.authOtpResendCode));
      await tester.pump();

      verify(mockController.resendOTP()).called(1);
    });

    testWidgets('en cuenta regresiva muestra segundos y deshabilita reenviar',
        (tester) async {
      stubState(const OtpVerificationState(
          email: testEmail, canResend: false, remainingSeconds: 42));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(OtpVerificationScreen)))!;

      expect(find.text(l10n.authOtpResendIn(42)), findsOneWidget);
      await tester.tap(find.text(l10n.authOtpResendIn(42)));
      verifyNever(mockController.resendOTP());
    });

    testWidgets('mientras reenvía muestra spinner pequeño y deshabilita',
        (tester) async {
      stubState(const OtpVerificationState(
          email: testEmail, canResend: true, isResending: true));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(CircularProgressIndicator));
      verifyNever(mockController.resendOTP());
    });
  });
}
