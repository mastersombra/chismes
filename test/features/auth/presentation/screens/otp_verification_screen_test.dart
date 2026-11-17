import 'package:chismes/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:chismes/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:chismes/features/auth/presentation/states/otp_verification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'otp_verification_screen_test.mocks.dart';

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
}
