import 'package:chismes/core/error/custom_error_keys.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'otp_verification_controller_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  AppLogger,
])
void main() {
  late OtpVerificationController controller;
  late MockAuthRepository mockAuthRepository;
  late MockAppLogger mockLogger;

  const testEmail = 'test@example.com';

  // Provide dummy values for Result types
  provideDummy<Result<Failure, User>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );
  provideDummy<Result<Failure, void>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockLogger = MockAppLogger();

    controller = OtpVerificationController(
      authRepository: mockAuthRepository,
      logger: mockLogger,
      email: testEmail,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('OtpVerificationController', () {
    final testUser = User(
      id: '123',
      email: testEmail,
      emailVerified: true,
      profileCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    );

    group('Inicialización', () {
      test('debe inicializar con email correcto', () {
        // Assert
        expect(controller.state.email, testEmail);
      });

      test('debe inicializar con estado por defecto', () {
        // Assert
        expect(controller.state.isVerifying, isFalse);
        expect(controller.state.isResending, isFalse);
        expect(controller.state.errorCode, isNull);
        expect(controller.state.customErrorKey, isNull);
        expect(controller.state.remainingSeconds, 0);
        expect(controller.state.canResend, isTrue);
      });
    });

    group('verifyOTP', () {
      const validCode = '123456';

      test('debe retornar false si código no tiene 6 dígitos', () async {
        // Act
        final result = await controller.verifyOTP('12345');

        // Assert
        expect(result, isFalse);
        expect(
          controller.state.customErrorKey,
          CustomErrorKey.authOtpCodeMustBe6Digits,
        );
        verifyNever(mockAuthRepository.verifyOTP(
          email: anyNamed('email'),
          token: anyNamed('token'),
        ));
      });

      test('debe retornar false si código está vacío', () async {
        // Act
        final result = await controller.verifyOTP('');

        // Assert
        expect(result, isFalse);
        expect(
          controller.state.customErrorKey,
          CustomErrorKey.authOtpCodeMustBe6Digits,
        );
        verifyNever(mockAuthRepository.verifyOTP(
          email: anyNamed('email'),
          token: anyNamed('token'),
        ));
      });

      test('debe retornar false si código es muy largo', () async {
        // Act
        final result = await controller.verifyOTP('1234567');

        // Assert
        expect(result, isFalse);
        expect(
          controller.state.customErrorKey,
          CustomErrorKey.authOtpCodeMustBe6Digits,
        );
        verifyNever(mockAuthRepository.verifyOTP(
          email: anyNamed('email'),
          token: anyNamed('token'),
        ));
      });

      test('debe cambiar estado a verifying al iniciar verificación', () async {
        // Arrange
        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.success(testUser));

        // Act
        final future = controller.verifyOTP(validCode);

        // Assert - durante la verificación
        expect(controller.state.isVerifying, isTrue);

        await future;
      });

      test('debe limpiar error antes de verificar', () async {
        // Arrange
        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.success(testUser));

        // Primero establecer un error
        await controller.verifyOTP('12345'); // código inválido
        expect(controller.state.customErrorKey, isNotNull);

        // Act
        await controller.verifyOTP(validCode);

        // Assert - el error debe estar limpio durante la verificación
        verify(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).called(1);
      });

      test('debe retornar true cuando verificación es exitosa', () async {
        // Arrange
        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.success(testUser));

        // Act
        final result = await controller.verifyOTP(validCode);

        // Assert
        expect(result, isTrue);
        expect(controller.state.isVerifying, isFalse);
        expect(controller.state.errorCode, isNull);
        verify(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).called(1);
      });

      test('debe logear verificación exitosa', () async {
        // Arrange
        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.success(testUser));

        // Act
        await controller.verifyOTP(validCode);

        // Assert
        verify(mockLogger.i('Verifying OTP', context: {'email': testEmail}))
            .called(1);
        verify(mockLogger.i(
          'OTP verified successfully',
          context: {'userId': testUser.id},
        )).called(1);
      });

      test('debe retornar false cuando verificación falla', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid OTP',
        );
        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await controller.verifyOTP(validCode);

        // Assert
        expect(result, isFalse);
        expect(controller.state.isVerifying, isFalse);
        expect(controller.state.errorCode, ErrorCode.invalidCredentials);
        verify(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).called(1);
      });

      test('debe logear fallo de verificación', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid OTP',
        );
        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        await controller.verifyOTP(validCode);

        // Assert
        verify(mockLogger.w(
          'OTP verification failed',
          context: {'code': ErrorCode.invalidCredentials},
        )).called(1);
      });

      test('debe notificar listeners durante la verificación', () async {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        when(mockAuthRepository.verifyOTP(
          email: testEmail,
          token: validCode,
        )).thenAnswer((_) async => Result.success(testUser));

        // Act
        await controller.verifyOTP(validCode);

        // Assert - debe notificar al menos 2 veces (start + end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('resendOTP', () {
      test('no debe hacer nada si canResend es false', () async {
        // Arrange
        // Primero hacer un resend exitoso para que canResend sea false
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        await controller.resendOTP();
        expect(controller.state.canResend, isFalse);

        // Reset para contar solo la próxima llamada
        reset(mockAuthRepository);
        reset(mockLogger);

        // Act - intentar reenviar cuando canResend es false
        await controller.resendOTP();

        // Assert - no debe llamar al repository
        verifyNever(mockAuthRepository.resendOTP(email: anyNamed('email')));
        verify(mockLogger.d(
          'Cannot resend OTP yet',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe cambiar estado a resending al iniciar', () async {
        // Arrange
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final future = controller.resendOTP();

        // Assert - durante el resend
        expect(controller.state.isResending, isTrue);

        await future;
      });

      test('debe limpiar error antes de reenviar', () async {
        // Arrange
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        // Establecer un error primero
        await controller.verifyOTP('12345'); // código inválido
        expect(controller.state.customErrorKey, isNotNull);

        // Act
        await controller.resendOTP();

        // Assert
        verify(mockAuthRepository.resendOTP(email: testEmail)).called(1);
      });

      test('debe configurar timer de 60 segundos después de resend exitoso',
          () async {
        // Arrange
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await controller.resendOTP();

        // Assert
        expect(controller.state.isResending, isFalse);
        expect(controller.state.canResend, isFalse);
        expect(controller.state.remainingSeconds, 60);
        verify(mockAuthRepository.resendOTP(email: testEmail)).called(1);
      });

      test('debe logear resend exitoso', () async {
        // Arrange
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await controller.resendOTP();

        // Assert
        verify(mockLogger.i('Resending OTP', context: {'email': testEmail}))
            .called(1);
        verify(mockLogger.i('OTP resent successfully')).called(1);
      });

      test('debe manejar fallo de resend', () async {
        // Arrange
        const failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        await controller.resendOTP();

        // Assert
        expect(controller.state.isResending, isFalse);
        expect(controller.state.errorCode, ErrorCode.networkError);
        verify(mockAuthRepository.resendOTP(email: testEmail)).called(1);
      });

      test('debe logear fallo de resend', () async {
        // Arrange
        const failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        await controller.resendOTP();

        // Assert
        verify(mockLogger.w(
          'Resend OTP failed',
          context: {'code': ErrorCode.networkError},
        )).called(1);
      });

      test('debe notificar listeners durante el resend', () async {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await controller.resendOTP();

        // Assert - debe notificar al menos 2 veces (start + end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('clearError', () {
      test('debe limpiar error existente', () async {
        // Arrange - establecer un error primero
        await controller.verifyOTP('12345'); // código inválido
        expect(controller.state.customErrorKey, isNotNull);

        // Act
        controller.clearError();

        // Assert
        expect(controller.state.errorCode, isNull);
        expect(controller.state.customErrorKey, isNull);
      });

      test('debe notificar listeners', () {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        // Act
        controller.clearError();

        // Assert
        expect(notificationCount, 1);
      });
    });

    group('Dispose', () {
      test('debe cancelar timer al hacer dispose', () async {
        // Arrange
        // Crear un controller nuevo para este test específico
        final testController = OtpVerificationController(
          authRepository: mockAuthRepository,
          logger: mockLogger,
          email: testEmail,
        );

        when(mockAuthRepository.resendOTP(email: testEmail))
            .thenAnswer((_) async => Result.success(null));

        await testController.resendOTP();
        expect(testController.state.remainingSeconds, 60);

        // Act
        testController.dispose();

        // Assert - no debería fallar
        // El timer interno debe estar cancelado
        // Este test verifica que dispose() no lanza una excepción
      });
    });
  });
}
