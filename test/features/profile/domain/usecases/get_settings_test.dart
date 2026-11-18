import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';
import 'package:chismes/features/profile/domain/repositories/profile_repository.dart';
import 'package:chismes/features/profile/domain/usecases/get_settings.dart';

import 'get_settings_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  setUpAll(() {
    provideDummy<Result<Failure, ProfileSettings>>(
      Result.success(ProfileSettings.defaultSettings()),
    );
  });

  late GetSettings useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = GetSettings(mockRepository);
  });

  group('GetSettings', () {
    const tUserId = 'user-123';
    const tSettings = ProfileSettings(
      notificationsEnabled: true,
      emailNotifications: true,
      pushNotifications: true,
      commentsNotifications: true,
      likesNotifications: true,
      followNotifications: true,
      language: 'es',
      darkMode: false,
      privacyLevel: 'public',
      showEmail: false,
      showActivity: true,
    );

    group('success cases', () {
      test('debe obtener configuraciones exitosamente', () async {
        // Arrange
        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.success(tSettings));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, tSettings);
        verify(mockRepository.getSettings(tUserId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe obtener configuraciones con valores personalizados', () async {
        // Arrange
        const customSettings = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: true,
          commentsNotifications: false,
          likesNotifications: true,
          followNotifications: false,
          language: 'en',
          darkMode: true,
          privacyLevel: 'private',
          showEmail: true,
          showActivity: false,
        );

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.success(customSettings));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, customSettings);
        expect(result.successValue?.language, 'en');
        expect(result.successValue?.darkMode, isTrue);
        expect(result.successValue?.privacyLevel, 'private');
      });

      test('debe obtener configuraciones por defecto', () async {
        // Arrange
        final defaultSettings = ProfileSettings.defaultSettings();

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.success(defaultSettings));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, defaultSettings);
        expect(result.successValue?.notificationsEnabled, isTrue);
        expect(result.successValue?.language, 'es');
        expect(result.successValue?.privacyLevel, 'public');
      });

      test('debe funcionar con diferentes user IDs', () async {
        // Arrange
        const userId1 = 'user-123';
        const userId2 = 'user-456';

        when(mockRepository.getSettings(userId1))
            .thenAnswer((_) async => Result.success(tSettings));

        when(mockRepository.getSettings(userId2))
            .thenAnswer((_) async => Result.success(tSettings));

        // Act
        final result1 = await useCase(userId1);
        final result2 = await useCase(userId2);

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.getSettings(userId1)).called(1);
        verify(mockRepository.getSettings(userId2)).called(1);
      });
    });

    group('failure cases', () {
      test('debe manejar NetworkFailure', () async {
        // Arrange
        const failure = NetworkFailure(
          code: ErrorCode.noInternetConnection,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getSettings(tUserId)).called(1);
      });

      test('debe manejar ServerFailure', () async {
        // Arrange
        const failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Internal server error',
        );

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getSettings(tUserId)).called(1);
      });

      test('debe manejar AuthFailure', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Unauthorized',
        );

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getSettings(tUserId)).called(1);
      });

      test('debe manejar ValidationFailure', () async {
        // Arrange
        const failure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid user ID',
        );

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getSettings(tUserId)).called(1);
      });

      test('debe manejar DataFailure', () async {
        // Arrange
        const failure = DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: 'Settings not found',
        );

        when(mockRepository.getSettings(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getSettings(tUserId)).called(1);
      });
    });

    group('edge cases', () {
      test('debe funcionar con userId vacío', () async {
        // Arrange
        const emptyUserId = '';

        when(mockRepository.getSettings(emptyUserId))
            .thenAnswer((_) async => Result.success(tSettings));

        // Act
        final result = await useCase(emptyUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getSettings(emptyUserId)).called(1);
      });

      test('debe funcionar con userId muy largo', () async {
        // Arrange
        final longUserId = 'user-${'a' * 1000}';

        when(mockRepository.getSettings(longUserId))
            .thenAnswer((_) async => Result.success(tSettings));

        // Act
        final result = await useCase(longUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getSettings(longUserId)).called(1);
      });

      test('debe funcionar con caracteres especiales en userId', () async {
        // Arrange
        const specialUserId = 'user-@#\$%^&*()';

        when(mockRepository.getSettings(specialUserId))
            .thenAnswer((_) async => Result.success(tSettings));

        // Act
        final result = await useCase(specialUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getSettings(specialUserId)).called(1);
      });
    });

  });
}
