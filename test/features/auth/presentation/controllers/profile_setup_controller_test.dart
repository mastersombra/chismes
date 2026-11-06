import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/usecases/is_username_available.dart';
import 'package:chismes/features/auth/domain/usecases/update_profile.dart';
import 'package:chismes/features/auth/presentation/controllers/profile_setup_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_setup_controller_test.mocks.dart';

@GenerateMocks([
  UpdateProfileUseCase,
  IsUsernameAvailableUseCase,
  AppLogger,
])
void main() {
  late ProfileSetupController controller;
  late MockUpdateProfileUseCase mockUpdateProfile;
  late MockIsUsernameAvailableUseCase mockIsUsernameAvailable;
  late MockAppLogger mockLogger;

  // Provide dummy values for Result types
  provideDummy<Result<Failure, User>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );
  provideDummy<Result<Failure, bool>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );

  setUp(() {
    mockUpdateProfile = MockUpdateProfileUseCase();
    mockIsUsernameAvailable = MockIsUsernameAvailableUseCase();
    mockLogger = MockAppLogger();

    controller = ProfileSetupController(
      mockUpdateProfile,
      mockIsUsernameAvailable,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('ProfileSetupController', () {
    const tUsername = 'testuser';
    const tDisplayName = 'Test User';
    const tBio = 'Test bio';
    const tAvatarUrl = 'https://example.com/avatar.jpg';
    final tUser = User(
      id: '123',
      email: 'test@example.com',
          emailVerified: true,
      username: tUsername,
      displayName: tDisplayName,
      profileCompleted: true,
      createdAt: DateTime(2024, 1, 1),
    );

    test('debe inicializar con estado AuthInitial', () {
      // Assert
      expect(controller.state, isA<AuthInitial>());
      expect(controller.usernameAvailable, isNull);
      expect(controller.checkingUsername, isFalse);
    });

    test('debe notificar listeners cuando estado cambia', () async {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      when(mockUpdateProfile(
        username: tUsername,
        displayName: tDisplayName,
        avatarUrl: null,
        bio: null,
      )).thenAnswer((_) async => Result.success(tUser));

      // Act
      await controller.updateProfile(
        username: tUsername,
        displayName: tDisplayName,
      );

      // Assert - debe notificar al menos 2 veces (loading + success)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    group('updateProfile', () {
      test('debe cambiar estado a loading al iniciar actualización', () async {
        // Arrange
        when(mockUpdateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final future = controller.updateProfile(
          username: tUsername,
          displayName: tDisplayName,
        );

        // Assert - estado inicial debe ser loading
        expect(controller.state, isA<AuthLoading>());

        await future;
      });

      test('debe cambiar estado a success cuando actualización es exitosa',
          () async {
        // Arrange
        when(mockUpdateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        await controller.updateProfile(
          username: tUsername,
          displayName: tDisplayName,
        );

        // Assert
        expect(controller.state, isA<AuthSuccess>());
        final successState = controller.state as AuthSuccess;
        expect(successState.user, tUser);
        verify(mockUpdateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });

      test('debe cambiar estado a error cuando actualización falla', () async {
        // Arrange
        final tFailure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid username',
        );
        when(mockUpdateProfile(
          username: tUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updateProfile(username: tUsername);

        // Assert
        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.failure, tFailure);
      });

      test('debe actualizar todos los campos cuando se proveen', () async {
        // Arrange
        when(mockUpdateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        await controller.updateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
        );

        // Assert
        verify(mockUpdateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
        )).called(1);
      });

      test('debe logear intento de actualización con contexto', () async {
        // Arrange
        when(mockUpdateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        await controller.updateProfile(
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
        );

        // Assert
        verify(mockLogger.i(
          'Update profile attempt',
          context: anyNamed('context'),
        )).called(1);
        verify(mockLogger.i(
          'Update profile successful',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe logear error cuando actualización falla', () async {
        // Arrange
        final tFailure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid username',
        );
        when(mockUpdateProfile(
          username: tUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.updateProfile(username: tUsername);

        // Assert
        verify(mockLogger.w(
          'Update profile failed',
          error: tFailure,
          context: anyNamed('context'),
        )).called(1);
      });
    });

    group('checkUsernameAvailability', () {
      test('debe retornar sin verificar si username está vacío', () async {
        // Act
        await controller.checkUsernameAvailability('');

        // Assert
        expect(controller.usernameAvailable, isNull);
        expect(controller.checkingUsername, isFalse);
        verifyNever(mockIsUsernameAvailable(any));
      });

      test('debe cambiar checkingUsername a true al iniciar verificación',
          () async {
        // Arrange
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(true));

        // Act
        final future = controller.checkUsernameAvailability(tUsername);

        // Assert - estado inicial debe ser checking
        expect(controller.checkingUsername, isTrue);
        expect(controller.usernameAvailable, isNull);

        await future;
      });

      test('debe actualizar usernameAvailable cuando username está disponible',
          () async {
        // Arrange
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(true));

        // Act
        await controller.checkUsernameAvailability(tUsername);

        // Assert
        expect(controller.usernameAvailable, isTrue);
        expect(controller.checkingUsername, isFalse);
        verify(mockIsUsernameAvailable(tUsername)).called(1);
      });

      test(
          'debe actualizar usernameAvailable cuando username NO está disponible',
          () async {
        // Arrange
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(false));

        // Act
        await controller.checkUsernameAvailability(tUsername);

        // Assert
        expect(controller.usernameAvailable, isFalse);
        expect(controller.checkingUsername, isFalse);
      });

      test('debe resetear usernameAvailable a null cuando verificación falla',
          () async {
        // Arrange
        final tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.checkUsernameAvailability(tUsername);

        // Assert
        expect(controller.usernameAvailable, isNull);
        expect(controller.checkingUsername, isFalse);
      });

      test('debe notificar listeners durante la verificación', () async {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(true));

        // Act
        await controller.checkUsernameAvailability(tUsername);

        // Assert - debe notificar al menos 2 veces (checking + result)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('debe logear verificación de username', () async {
        // Arrange
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(true));

        // Act
        await controller.checkUsernameAvailability(tUsername);

        // Assert
        verify(mockLogger.d(
          'Checking username availability',
          context: anyNamed('context'),
        )).called(1);
        verify(mockLogger.d(
          'Username availability checked',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe logear error cuando verificación falla', () async {
        // Arrange
        final tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.checkUsernameAvailability(tUsername);

        // Assert
        verify(mockLogger.w(
          'Check username failed',
          error: tFailure,
          context: anyNamed('context'),
        )).called(1);
      });
    });

    group('resetUsernameCheck', () {
      test('debe resetear estado de verificación de username', () async {
        // Arrange - configurar verificación exitosa
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(true));
        await controller.checkUsernameAvailability(tUsername);

        // Act
        controller.resetUsernameCheck();

        // Assert
        expect(controller.usernameAvailable, isNull);
        expect(controller.checkingUsername, isFalse);
      });

      test('debe notificar listeners al resetear', () {
        // Arrange
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        // Act
        controller.resetUsernameCheck();

        // Assert
        expect(notificationCount, 1);
      });
    });

    group('resetState', () {
      test('debe cambiar estado a initial y resetear username check', () async {
        // Arrange - configurar estado de error
        when(mockUpdateProfile(
          username: tUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.failure(
              const ValidationFailure(
                code: ErrorCode.invalidInput,
                technicalMessage: 'Invalid username',
              ),
            ));
        await controller.updateProfile(username: tUsername);

        // Arrange - configurar verificación de username
        when(mockIsUsernameAvailable(tUsername))
            .thenAnswer((_) async => Result.success(true));
        await controller.checkUsernameAvailability(tUsername);

        // Act
        controller.resetState();

        // Assert
        expect(controller.state, isA<AuthInitial>());
        expect(controller.usernameAvailable, isNull);
        expect(controller.checkingUsername, isFalse);
      });
    });
  });
}
