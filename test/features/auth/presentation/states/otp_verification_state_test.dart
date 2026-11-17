import 'package:chismes/core/error/custom_error_keys.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/auth/presentation/states/otp_verification_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpVerificationState', () {
    const testEmail = 'test@example.com';

    group('Constructor', () {
      test('debe crear instancia con solo email requerido', () {
        // Act
        const state = OtpVerificationState(email: testEmail);

        // Assert
        expect(state.email, testEmail);
        expect(state.isVerifying, isFalse);
        expect(state.isResending, isFalse);
        expect(state.errorCode, isNull);
        expect(state.customErrorKey, isNull);
        expect(state.remainingSeconds, 0);
        expect(state.canResend, isTrue);
      });

      test('debe crear instancia con todos los parámetros', () {
        // Act
        const state = OtpVerificationState(
          email: testEmail,
          isVerifying: true,
          isResending: true,
          errorCode: ErrorCode.networkError,
          customErrorKey: CustomErrorKey.authOtpCodeMustBe6Digits,
          remainingSeconds: 60,
          canResend: false,
        );

        // Assert
        expect(state.email, testEmail);
        expect(state.isVerifying, isTrue);
        expect(state.isResending, isTrue);
        expect(state.errorCode, ErrorCode.networkError);
        expect(state.customErrorKey, CustomErrorKey.authOtpCodeMustBe6Digits);
        expect(state.remainingSeconds, 60);
        expect(state.canResend, isFalse);
      });

      test('debe tener valores por defecto correctos', () {
        // Act
        const state = OtpVerificationState(email: testEmail);

        // Assert - valores por defecto
        expect(state.isVerifying, isFalse);
        expect(state.isResending, isFalse);
        expect(state.remainingSeconds, 0);
        expect(state.canResend, isTrue);
      });
    });

    group('copyWith', () {
      const initialState = OtpVerificationState(email: testEmail);

      test('debe actualizar email', () {
        // Arrange
        const newEmail = 'new@example.com';

        // Act
        final newState = initialState.copyWith(email: newEmail);

        // Assert
        expect(newState.email, newEmail);
        expect(newState.isVerifying, initialState.isVerifying);
        expect(newState.isResending, initialState.isResending);
      });

      test('debe actualizar isVerifying', () {
        // Act
        final newState = initialState.copyWith(isVerifying: true);

        // Assert
        expect(newState.isVerifying, isTrue);
        expect(newState.email, initialState.email);
        expect(newState.isResending, initialState.isResending);
      });

      test('debe actualizar isResending', () {
        // Act
        final newState = initialState.copyWith(isResending: true);

        // Assert
        expect(newState.isResending, isTrue);
        expect(newState.email, initialState.email);
        expect(newState.isVerifying, initialState.isVerifying);
      });

      test('debe actualizar errorCode', () {
        // Act
        final newState = initialState.copyWith(
          errorCode: ErrorCode.invalidCredentials,
        );

        // Assert
        expect(newState.errorCode, ErrorCode.invalidCredentials);
        expect(newState.email, initialState.email);
      });

      test('debe actualizar customErrorKey', () {
        // Act
        final newState = initialState.copyWith(
          customErrorKey: CustomErrorKey.authOtpCodeMustBe6Digits,
        );

        // Assert
        expect(
          newState.customErrorKey,
          CustomErrorKey.authOtpCodeMustBe6Digits,
        );
        expect(newState.email, initialState.email);
      });

      test('debe actualizar remainingSeconds', () {
        // Act
        final newState = initialState.copyWith(remainingSeconds: 45);

        // Assert
        expect(newState.remainingSeconds, 45);
        expect(newState.email, initialState.email);
      });

      test('debe actualizar canResend', () {
        // Act
        final newState = initialState.copyWith(canResend: false);

        // Assert
        expect(newState.canResend, isFalse);
        expect(newState.email, initialState.email);
      });

      test('debe actualizar múltiples campos a la vez', () {
        // Act
        final newState = initialState.copyWith(
          isVerifying: true,
          isResending: true,
          remainingSeconds: 30,
          canResend: false,
        );

        // Assert
        expect(newState.isVerifying, isTrue);
        expect(newState.isResending, isTrue);
        expect(newState.remainingSeconds, 30);
        expect(newState.canResend, isFalse);
        expect(newState.email, initialState.email);
      });

      test('debe mantener valores originales si no se pasan parámetros', () {
        // Arrange
        const originalState = OtpVerificationState(
          email: testEmail,
          isVerifying: true,
          isResending: true,
          errorCode: ErrorCode.networkError,
          remainingSeconds: 45,
          canResend: false,
        );

        // Act
        final newState = originalState.copyWith();

        // Assert
        expect(newState.email, originalState.email);
        expect(newState.isVerifying, originalState.isVerifying);
        expect(newState.isResending, originalState.isResending);
        // Nota: errorCode y customErrorKey NO se preservan en copyWith()
        // sin parámetros porque no usan el operador ?? en la implementación
        expect(newState.errorCode, isNull);
        expect(newState.customErrorKey, isNull);
        expect(newState.remainingSeconds, originalState.remainingSeconds);
        expect(newState.canResend, originalState.canResend);
      });
    });

    group('clearError', () {
      test('debe limpiar errorCode y customErrorKey', () {
        // Arrange
        const stateWithErrors = OtpVerificationState(
          email: testEmail,
          errorCode: ErrorCode.networkError,
          customErrorKey: CustomErrorKey.authOtpCodeMustBe6Digits,
        );

        // Act
        final newState = stateWithErrors.clearError();

        // Assert
        expect(newState.errorCode, isNull);
        expect(newState.customErrorKey, isNull);
      });

      test('debe mantener otros campos intactos', () {
        // Arrange
        const stateWithErrors = OtpVerificationState(
          email: testEmail,
          isVerifying: true,
          isResending: true,
          errorCode: ErrorCode.networkError,
          customErrorKey: CustomErrorKey.authOtpCodeMustBe6Digits,
          remainingSeconds: 30,
          canResend: false,
        );

        // Act
        final newState = stateWithErrors.clearError();

        // Assert
        expect(newState.email, testEmail);
        expect(newState.isVerifying, isTrue);
        expect(newState.isResending, isTrue);
        expect(newState.remainingSeconds, 30);
        expect(newState.canResend, isFalse);
      });

      test('debe funcionar correctamente si no hay errores', () {
        // Arrange
        const stateWithoutErrors = OtpVerificationState(
          email: testEmail,
          isVerifying: true,
        );

        // Act
        final newState = stateWithoutErrors.clearError();

        // Assert
        expect(newState.errorCode, isNull);
        expect(newState.customErrorKey, isNull);
        expect(newState.email, testEmail);
        expect(newState.isVerifying, isTrue);
      });
    });

    group('Estado típico de flujo OTP', () {
      test('debe representar estado inicial correctamente', () {
        // Act
        const state = OtpVerificationState(email: testEmail);

        // Assert - estado inicial listo para verificar
        expect(state.isVerifying, isFalse);
        expect(state.isResending, isFalse);
        expect(state.canResend, isTrue);
        expect(state.remainingSeconds, 0);
        expect(state.errorCode, isNull);
      });

      test('debe representar estado de verificación en progreso', () {
        // Arrange
        const state = OtpVerificationState(email: testEmail);

        // Act
        final verifyingState = state.copyWith(isVerifying: true);

        // Assert
        expect(verifyingState.isVerifying, isTrue);
        expect(verifyingState.isResending, isFalse);
      });

      test('debe representar estado después de reenviar código', () {
        // Arrange
        const state = OtpVerificationState(email: testEmail);

        // Act - simular después de resend exitoso
        final afterResendState = state.copyWith(
          canResend: false,
          remainingSeconds: 60,
        );

        // Assert
        expect(afterResendState.canResend, isFalse);
        expect(afterResendState.remainingSeconds, 60);
      });

      test('debe representar estado con error de validación', () {
        // Arrange
        const state = OtpVerificationState(email: testEmail);

        // Act
        final errorState = state.copyWith(
          customErrorKey: CustomErrorKey.authOtpCodeMustBe6Digits,
        );

        // Assert
        expect(
          errorState.customErrorKey,
          CustomErrorKey.authOtpCodeMustBe6Digits,
        );
        expect(errorState.isVerifying, isFalse);
      });

      test('debe representar estado con error de red', () {
        // Arrange
        const state = OtpVerificationState(email: testEmail);

        // Act
        final errorState = state.copyWith(
          errorCode: ErrorCode.networkError,
          isVerifying: false,
        );

        // Assert
        expect(errorState.errorCode, ErrorCode.networkError);
        expect(errorState.isVerifying, isFalse);
      });
    });

    group('Casos edge', () {
      test('debe manejar countdown de segundos restantes', () {
        // Arrange
        const state = OtpVerificationState(
          email: testEmail,
          remainingSeconds: 60,
          canResend: false,
        );

        // Act - simular countdown
        final state1 = state.copyWith(remainingSeconds: 59);
        final state2 = state1.copyWith(remainingSeconds: 1);
        final state3 = state2.copyWith(remainingSeconds: 0, canResend: true);

        // Assert
        expect(state1.remainingSeconds, 59);
        expect(state1.canResend, isFalse);
        expect(state2.remainingSeconds, 1);
        expect(state2.canResend, isFalse);
        expect(state3.remainingSeconds, 0);
        expect(state3.canResend, isTrue);
      });

      test('debe poder tener ambos errorCode y customErrorKey', () {
        // Act
        const state = OtpVerificationState(
          email: testEmail,
          errorCode: ErrorCode.networkError,
          customErrorKey: CustomErrorKey.authOtpCodeMustBe6Digits,
        );

        // Assert
        expect(state.errorCode, ErrorCode.networkError);
        expect(state.customErrorKey, CustomErrorKey.authOtpCodeMustBe6Digits);
      });

      test('debe poder estar verificando y reenviando simultáneamente (caso edge)', () {
        // Nota: en la práctica esto no debería pasar, pero el state lo permite
        // Act
        const state = OtpVerificationState(
          email: testEmail,
          isVerifying: true,
          isResending: true,
        );

        // Assert
        expect(state.isVerifying, isTrue);
        expect(state.isResending, isTrue);
      });
    });
  });
}
