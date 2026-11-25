import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';
import 'package:chismes/features/profile/domain/repositories/profile_repository.dart';
import 'package:chismes/features/profile/domain/usecases/update_settings.dart';

import 'update_settings_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  setUpAll(() {
    provideDummy<Result<Failure, void>>(
      Result.success(null),
    );
  });

  late UpdateSettings useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateSettings(mockRepository);
  });

  group('UpdateSettings', () {
    const tUserId = 'user-123';
    const tSettings = ProfileSettings(
      notificationsEnabled: true,
      emailNotifications: true,
      pushNotifications: true,
      commentsNotifications: true,
      likesNotifications: true,
      followNotifications: true,
      privacyLevel: 'public',
      showEmail: false,
      showActivity: true,
    );

    group('success cases', () {
      test('debe actualizar configuraciones exitosamente', () async {
        // Arrange
        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(tUserId, tSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateSettings(tUserId, tSettings)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe actualizar solo notificaciones', () async {
        // Arrange
        const notificationsSettings = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: false,
          commentsNotifications: false,
          likesNotifications: false,
          followNotifications: false,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: true,
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(tUserId, notificationsSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateSettings(tUserId, notificationsSettings))
            .called(1);
      });

      test('debe actualizar privacidad', () async {
        // Arrange
        const privacySettings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'private', // Changed to private
          showEmail: false,
          showActivity: false, // Hide activity
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(tUserId, privacySettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateSettings(tUserId, privacySettings))
            .called(1);
      });

      test('debe actualizar múltiples configuraciones a la vez', () async {
        // Arrange
        const multipleSettings = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: false,
          followNotifications: true,
          privacyLevel: 'friends',
          showEmail: true,
          showActivity: false,
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(tUserId, multipleSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateSettings(tUserId, multipleSettings))
            .called(1);
      });

      test('debe funcionar con diferentes user IDs', () async {
        // Arrange
        const userId1 = 'user-123';
        const userId2 = 'user-456';

        when(mockRepository.updateSettings(userId1, tSettings))
            .thenAnswer((_) async => Result.success(null));

        when(mockRepository.updateSettings(userId2, tSettings))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result1 = await useCase(userId1, tSettings);
        final result2 = await useCase(userId2, tSettings);

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.updateSettings(userId1, tSettings)).called(1);
        verify(mockRepository.updateSettings(userId2, tSettings)).called(1);
      });
    });

    group('failure cases', () {
      test('debe manejar NetworkFailure', () async {
        // Arrange
        const failure = NetworkFailure(
          code: ErrorCode.noInternetConnection,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId, tSettings);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.updateSettings(tUserId, tSettings)).called(1);
      });

      test('debe manejar ServerFailure', () async {
        // Arrange
        const failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Internal server error',
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId, tSettings);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.updateSettings(tUserId, tSettings)).called(1);
      });

      test('debe manejar AuthFailure', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Unauthorized',
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId, tSettings);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.updateSettings(tUserId, tSettings)).called(1);
      });

      test('debe manejar ValidationFailure', () async {
        // Arrange
        const failure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid settings data',
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId, tSettings);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.updateSettings(tUserId, tSettings)).called(1);
      });

      test('debe manejar error de usuario no encontrado', () async {
        // Arrange
        const failure = DataFailure(
          code: ErrorCode.userNotFound,
          technicalMessage: 'User not found',
        );

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId, tSettings);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
      });
    });

    group('edge cases', () {
      test('debe funcionar con userId vacío', () async {
        // Arrange
        const emptyUserId = '';

        when(mockRepository.updateSettings(emptyUserId, tSettings))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(emptyUserId, tSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateSettings(emptyUserId, tSettings)).called(1);
      });

      test('debe funcionar con configuraciones por defecto', () async {
        // Arrange
        final defaultSettings = ProfileSettings.defaultSettings();

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(tUserId, defaultSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateSettings(tUserId, defaultSettings))
            .called(1);
      });

      test('debe funcionar con todos los niveles de privacidad', () async {
        // Arrange
        final privacyLevels = ['public', 'private'];

        for (final level in privacyLevels) {
          final settings = tSettings.copyWith(privacyLevel: level);

          when(mockRepository.updateSettings(tUserId, settings))
              .thenAnswer((_) async => Result.success(null));

          // Act
          final result = await useCase(tUserId, settings);

          // Assert
          expect(result.isSuccess, isTrue);
        }

        verify(mockRepository.updateSettings(any, any)).called(2);
      });

      test('debe manejar actualizaciones rápidas consecutivas', () async {
        // Arrange
        final settings1 = tSettings.copyWith(showEmail: true);
        final settings2 = tSettings.copyWith(showEmail: false);
        final settings3 = tSettings.copyWith(privacyLevel: 'private');

        when(mockRepository.updateSettings(any, any))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result1 = await useCase(tUserId, settings1);
        final result2 = await useCase(tUserId, settings2);
        final result3 = await useCase(tUserId, settings3);

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        expect(result3.isSuccess, isTrue);
        verify(mockRepository.updateSettings(any, any)).called(3);
      });
    });

  });
}
