import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:chismes/features/auth/presentation/controllers/signup_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'signup_controller_test.mocks.dart';

@GenerateMocks([
  SignUpWithEmailUseCase,
  AppLogger,
])
void main() {
  late SignupController controller;
  late MockSignUpWithEmailUseCase mockSignUpWithEmail;
  late MockAppLogger mockLogger;

  // Provide dummy values for Result types
  provideDummy<Result<Failure, void>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );

  setUp(() {
    mockSignUpWithEmail = MockSignUpWithEmailUseCase();
    mockLogger = MockAppLogger();

    controller = SignupController(
      mockSignUpWithEmail,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('SignupController', () {
    const tEmail = 'test@example.com';
    const tPassword = 'Test123!@';

    test('debe inicializar con estado AuthInitial', () {
      // Assert
      expect(controller.state, isA<AuthInitial>());
    });

    test('debe notificar listeners cuando estado cambia', () async {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      when(mockSignUpWithEmail(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => Result.success(null));

      // Act
      await controller.signUpWithEmail(
        email: tEmail,
        password: tPassword,
      );

      // Assert - debe notificar al menos 2 veces (loading + otp sent)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    group('signUpWithEmail', () {
      test('debe cambiar estado a loading al iniciar registro', () async {
        // Arrange
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final future = controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert - estado inicial debe ser loading
        expect(controller.state, isA<AuthLoading>());

        await future;
      });

      test('debe cambiar estado a AuthOtpSent cuando registro es exitoso',
          () async {
        // Arrange
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(controller.state, isA<AuthOtpSent>());
        final otpState = controller.state as AuthOtpSent;
        expect(otpState.email, tEmail);
        verify(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });

      test('debe mostrar mensaje personalizado cuando email ya existe',
          () async {
        // Arrange
        const tFailure = AuthFailure(
          code: ErrorCode.emailAlreadyInUse,
          technicalMessage: 'Email already in use',
        );
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.customMessage,
            'Este email ya está registrado. Inicia sesión en su lugar.');
      });

      test('debe cambiar estado a error cuando registro falla', () async {
        // Arrange
        const tFailure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Password is too weak',
        );
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.failure, tFailure);
      });

      test('debe logear intento de registro', () async {
        // Arrange
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        verify(mockLogger.i(
          'Sign up attempt',
          context: anyNamed('context'),
        )).called(1);
        verify(mockLogger.i(
          'Sign up successful, OTP sent',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe logear error cuando registro falla', () async {
        // Arrange
        final tFailure = AuthFailure(
          code: ErrorCode.emailAlreadyInUse,
          technicalMessage: 'Email already in use',
        );
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        verify(mockLogger.i(
          'Sign up attempt',
          context: anyNamed('context'),
        )).called(1);
        verify(mockLogger.w(
          'Sign up failed',
          error: tFailure,
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe manejar errores de validación', () async {
        // Arrange
        final tFailure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid email format',
        );
        when(mockSignUpWithEmail(
          email: 'invalid-email',
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.signUpWithEmail(
          email: 'invalid-email',
          password: tPassword,
        );

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.failure, tFailure);
      });

      test('debe manejar errores de red', () async {
        // Arrange
        final tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.failure, tFailure);
      });
    });

    group('resetState', () {
      test('debe cambiar estado a initial', () async {
        // Arrange - configurar stub para que falle
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(
              const ValidationFailure(
                code: ErrorCode.invalidInput,
                technicalMessage: 'Email and password are required',
              ),
            ));

        // Arrange - poner en estado de error
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Act
        controller.resetState();

        // Assert
        expect(controller.state, isA<AuthInitial>());
      });

      test('debe notificar listeners al resetear', () {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        // Act
        controller.resetState();

        // Assert
        expect(notificationCount, 1);
      });

      test('debe poder registrar nuevamente después de resetear', () async {
        // Arrange - primer intento fallido
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(
              const ValidationFailure(
                code: ErrorCode.invalidInput,
                technicalMessage: 'Invalid input',
              ),
            ));
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );
        expect(controller.state, isA<AuthError>());

        // Act - resetear estado
        controller.resetState();
        expect(controller.state, isA<AuthInitial>());

        // Arrange - segundo intento exitoso
        when(mockSignUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act - segundo intento
        await controller.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(controller.state, isA<AuthOtpSent>());
      });
    });
  });
}
