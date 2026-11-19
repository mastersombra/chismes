import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';
import 'package:chismes/features/profile/domain/repositories/profile_repository.dart';
import 'package:chismes/features/profile/domain/usecases/get_user_stats.dart';

import 'get_user_stats_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  setUpAll(() {
    provideDummy<Result<Failure, UserStats>>(
      Result.success(
        const UserStats(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
        ),
      ),
    );
  });

  late GetUserStats useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = GetUserStats(mockRepository);
  });

  group('GetUserStats', () {
    const tUserId = 'user-123';
    final tLastActivity = DateTime(2026, 11, 18, 10, 30);
    final tStats = UserStats(
      gossipsCount: 42,
      commentsCount: 128,
      followersCount: 256,
      followingCount: 89,
      lastActivityAt: tLastActivity,
    );

    group('success cases', () {
      test('debe obtener estadísticas exitosamente', () async {
        // Arrange
        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(tStats));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, tStats);
        verify(mockRepository.getUserStats(tUserId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe obtener estadísticas con valores personalizados', () async {
        // Arrange
        final customStats = UserStats(
          gossipsCount: 1000,
          commentsCount: 5000,
          followersCount: 10000,
          followingCount: 500,
          lastActivityAt: DateTime(2026, 11, 18),
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(customStats));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, customStats);
        expect(result.successValue?.gossipsCount, 1000);
        expect(result.successValue?.followersCount, 10000);
      });

      test('debe obtener estadísticas de usuario nuevo (ceros)', () async {
        // Arrange
        const newUserStats = UserStats(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
          lastActivityAt: null,
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(newUserStats));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, newUserStats);
        expect(result.successValue?.gossipsCount, 0);
        expect(result.successValue?.followersCount, 0);
        expect(result.successValue?.lastActivityAt, isNull);
      });

      test('debe obtener estadísticas sin lastActivityAt', () async {
        // Arrange
        const statsNoActivity = UserStats(
          gossipsCount: 10,
          commentsCount: 20,
          followersCount: 30,
          followingCount: 15,
          lastActivityAt: null,
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(statsNoActivity));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.lastActivityAt, isNull);
      });

      test('debe funcionar con diferentes user IDs', () async {
        // Arrange
        const userId1 = 'user-123';
        const userId2 = 'user-456';

        final stats1 = UserStats(
          gossipsCount: 10,
          commentsCount: 20,
          followersCount: 30,
          followingCount: 15,
          lastActivityAt: DateTime(2026, 11, 18),
        );

        final stats2 = UserStats(
          gossipsCount: 50,
          commentsCount: 100,
          followersCount: 200,
          followingCount: 75,
          lastActivityAt: DateTime(2026, 11, 17),
        );

        when(mockRepository.getUserStats(userId1))
            .thenAnswer((_) async => Result.success(stats1));

        when(mockRepository.getUserStats(userId2))
            .thenAnswer((_) async => Result.success(stats2));

        // Act
        final result1 = await useCase(userId1);
        final result2 = await useCase(userId2);

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        expect(result1.successValue?.gossipsCount, 10);
        expect(result2.successValue?.gossipsCount, 50);
        verify(mockRepository.getUserStats(userId1)).called(1);
        verify(mockRepository.getUserStats(userId2)).called(1);
      });
    });

    group('failure cases', () {
      test('debe manejar NetworkFailure', () async {
        // Arrange
        const failure = NetworkFailure(
          code: ErrorCode.noInternetConnection,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getUserStats(tUserId)).called(1);
      });

      test('debe manejar ServerFailure', () async {
        // Arrange
        const failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Internal server error',
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getUserStats(tUserId)).called(1);
      });

      test('debe manejar AuthFailure', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Unauthorized',
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getUserStats(tUserId)).called(1);
      });

      test('debe manejar ValidationFailure', () async {
        // Arrange
        const failure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid user ID',
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getUserStats(tUserId)).called(1);
      });

      test('debe manejar DataFailure', () async {
        // Arrange
        const failure = DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: 'User stats not found',
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getUserStats(tUserId)).called(1);
      });
    });

    group('edge cases', () {
      test('debe funcionar con userId vacío', () async {
        // Arrange
        const emptyUserId = '';

        when(mockRepository.getUserStats(emptyUserId))
            .thenAnswer((_) async => Result.success(tStats));

        // Act
        final result = await useCase(emptyUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getUserStats(emptyUserId)).called(1);
      });

      test('debe funcionar con estadísticas muy grandes', () async {
        // Arrange
        final hugeStats = UserStats(
          gossipsCount: 999999,
          commentsCount: 999999,
          followersCount: 999999,
          followingCount: 999999,
          lastActivityAt: DateTime(2026, 11, 18),
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(hugeStats));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.gossipsCount, 999999);
      });

      test('debe funcionar con fecha muy antigua', () async {
        // Arrange
        final oldStats = UserStats(
          gossipsCount: 10,
          commentsCount: 20,
          followersCount: 30,
          followingCount: 15,
          lastActivityAt: DateTime(2020, 1, 1),
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(oldStats));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.lastActivityAt?.year, 2020);
      });

      test('debe funcionar con fecha futura', () async {
        // Arrange
        final futureStats = UserStats(
          gossipsCount: 10,
          commentsCount: 20,
          followersCount: 30,
          followingCount: 15,
          lastActivityAt: DateTime(2030, 12, 31),
        );

        when(mockRepository.getUserStats(any))
            .thenAnswer((_) async => Result.success(futureStats));

        // Act
        final result = await useCase(tUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.lastActivityAt?.year, 2030);
      });
    });

  });
}
