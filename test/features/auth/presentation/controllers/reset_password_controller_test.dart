import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:chismes/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'reset_password_controller_test.mocks.dart';

@GenerateMocks([
  UpdatePasswordUseCase,
  AppLogger,
])
void main() {
  late ResetPasswordController controller;
  late MockUpdatePasswordUseCase mockUpdatePassword;
  late MockAppLogger mockLogger;

  const tPassword = 'NewPassword123!@';

  // Provide dummy values for Result types
  provideDummy<Result<Failure, void>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );

  setUp(() {
    mockUpdatePassword = MockUpdatePasswordUseCase();
    mockLogger = MockAppLogger();

    controller = ResetPasswordController(
      mockUpdatePassword,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('ResetPasswordController', () {
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

      when(mockUpdatePassword(newPassword: tPassword))
          .thenAnswer((_) async => Result.success(null));

      // Act
      await controller.updatePassword(newPassword: tPassword);

      // Assert - debe notificar al menos 2 veces (loading + success)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    group('updatePassword', () {
      test('debe cambiar estado a loading al iniciar', () async {
        // Arrange
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final future = controller.updatePassword(newPassword: tPassword);

        // Assert - estado inicial debe ser loading
        expect(controller.state, isA<AuthLoading>());

        await future;
      });

      test('debe cambiar estado a AuthPasswordUpdated cuando es exitoso',
          () async {
        // Arrange
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        expect(controller.state, isA<AuthPasswordUpdated>());
        verify(mockUpdatePassword(newPassword: tPassword)).called(1);
      });

      test('debe logear intento de actualización', () async {
        // Arrange
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        verify(mockLogger.i('Updating password')).called(1);
        verify(mockLogger.i('Password updated successfully')).called(1);
      });

      test('debe cambiar estado a error cuando falla', () async {
        // Arrange
        const tFailure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Password is too weak',
        );
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.weakPassword);
      });

      test('debe logear error cuando actualización falla', () async {
        // Arrange
        const tFailure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Password is too weak',
        );
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        verify(mockLogger.i('Updating password')).called(1);
        verify(mockLogger.w(
          'Update password failed',
          error: tFailure,
          context: {'code': ErrorCode.weakPassword},
        )).called(1);
      });

      test('debe manejar errores de red', () async {
        // Arrange
        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.networkError);
      });

      test('debe manejar contraseña inválida', () async {
        // Arrange
        const tFailure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Password does not meet requirements',
        );
        when(mockUpdatePassword(newPassword: 'weak'))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updatePassword(newPassword: 'weak');

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.invalidInput);
      });

      test('debe manejar sesión expirada', () async {
        // Arrange
        const tFailure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Session expired',
        );
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.unauthorized);
      });

      test('debe permitir múltiples intentos', () async {
        // Arrange - primer intento fallido
        const tFailure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Password too weak',
        );
        when(mockUpdatePassword(newPassword: 'weak123'))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act - primer intento
        await controller.updatePassword(newPassword: 'weak123');
        expect(controller.state, isA<AuthError>());

        // Arrange - segundo intento exitoso
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.success(null));

        // Act - segundo intento
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        expect(controller.state, isA<AuthPasswordUpdated>());
        verify(mockUpdatePassword(newPassword: 'weak123')).called(1);
        verify(mockUpdatePassword(newPassword: tPassword)).called(1);
      });
    });

    group('resetState', () {
      test('debe cambiar estado a initial', () async {
        // Arrange - poner en estado de error
        const tFailure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Password too weak',
        );
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.failure(tFailure));

        await controller.updatePassword(newPassword: tPassword);
        expect(controller.state, isA<AuthError>());

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

      test('debe poder actualizar contraseña después de resetear', () async {
        // Arrange - primer intento fallido
        const tFailure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Password too weak',
        );
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.failure(tFailure));
        await controller.updatePassword(newPassword: tPassword);
        expect(controller.state, isA<AuthError>());

        // Act - resetear estado
        controller.resetState();
        expect(controller.state, isA<AuthInitial>());

        // Arrange - segundo intento exitoso
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.success(null));

        // Act - segundo intento
        await controller.updatePassword(newPassword: tPassword);

        // Assert
        expect(controller.state, isA<AuthPasswordUpdated>());
      });

      test('debe poder resetear desde estado success', () async {
        // Arrange - actualización exitosa
        when(mockUpdatePassword(newPassword: tPassword))
            .thenAnswer((_) async => Result.success(null));
        await controller.updatePassword(newPassword: tPassword);
        expect(controller.state, isA<AuthPasswordUpdated>());

        // Act
        controller.resetState();

        // Assert
        expect(controller.state, isA<AuthInitial>());
      });
    });
  });
}
