import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/home/data/datasources/home_remote_datasource.dart';
import 'package:chismes/features/home/data/models/feed_gossip_model.dart';
import 'package:chismes/features/home/data/models/paginated_gossips_model.dart';
import 'package:chismes/features/home/data/repositories/home_repository_impl.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';

import 'home_repository_impl_test.mocks.dart';

@GenerateMocks([HomeRemoteDataSource, AppLogger])
void main() {
  late HomeRepositoryImpl repository;
  late MockHomeRemoteDataSource mockRemoteDataSource;
  late MockAppLogger mockLogger;

  setUp(() {
    mockRemoteDataSource = MockHomeRemoteDataSource();
    mockLogger = MockAppLogger();
    repository = HomeRepositoryImpl(mockRemoteDataSource, mockLogger);
  });

  group('HomeRepositoryImpl', () {
    const testUserId = 'user-123';
    const testCityId = 'MED';

    final tFeedGossipModel = FeedGossipModel(
      id: 'gossip-1',
      subject: 'Test Subject',
      content: 'Test Content',
      cityId: 'MED',
      createdAt: '2024-01-15T10:30:00Z',
      likes: 100,
      comments: 20,
      shares: 5,
      publishedAs: 'anonymous',
      createdBy: null,
      imageUrl: null,
      score: 123.45,
      isFromMyCity: true,
      isTrending: false,
    );

    final tPaginatedModel = PaginatedGossipsModel(
      data: [tFeedGossipModel],
      hasMore: true,
      nextCursor: {'score': 100.0, 'id': 'gossip-1'},
    );

    group('getPopularFeed', () {
      test('debe retornar PaginatedGossips cuando datasource retorna exitosamente',
          () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        final result = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (paginated) {
            expect(paginated, isA<PaginatedGossips>());
            expect(paginated.data.length, 1);
            expect(paginated.hasMore, true);
            expect(paginated.nextCursor, isNotNull);
          },
        );

        verify(mockLogger.d(
          'Getting popular feed',
          context: anyNamed('context'),
        )).called(1);
        verify(mockRemoteDataSource.getPopularFeed(
          userCityId: testCityId,
          pageSize: 20,
          cursor: null,
        )).called(1);
        verify(mockLogger.i(
          'Popular feed retrieved successfully',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final testError = Exception('Network error');
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(testError);

        // Act
        final result = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
          },
          onSuccess: (_) => fail('Should be failure'),
        );

        verify(mockLogger.e(
          'Error getting popular feed',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe pasar cursor correctamente', () async {
        // Arrange
        const cursor = FeedCursor.popular(
          score: 123.45,
          id: 'gossip-123',
        );

        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: cursor,
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
          cursor: cursor,
        );

        // Assert
        verify(mockRemoteDataSource.getPopularFeed(
          userCityId: testCityId,
          pageSize: 20,
          cursor: cursor,
        )).called(1);
      });

      test('debe manejar userId y cityId null', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: null,
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => const PaginatedGossipsModel.empty());

        // Act
        final result = await repository.getPopularFeed(
          userId: null,
          cityId: null,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRemoteDataSource.getPopularFeed(
          userCityId: null,
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe pasar pageSize personalizado', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: 50,
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
          pageSize: 50,
        );

        // Assert
        verify(mockRemoteDataSource.getPopularFeed(
          userCityId: testCityId,
          pageSize: 50,
          cursor: null,
        )).called(1);
      });

      test('debe convertir model a entity correctamente', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        final result = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (paginated) {
            expect(paginated.data.first.id, tFeedGossipModel.id);
            expect(paginated.data.first.subject, tFeedGossipModel.subject);
            expect(paginated.data.first.score, tFeedGossipModel.score);
          },
        );
      });
    });

    group('getFollowingFeed', () {
      test('debe retornar PaginatedGossips cuando datasource retorna exitosamente',
          () async {
        // Arrange
        when(mockRemoteDataSource.getFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        final result = await repository.getFollowingFeed();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (paginated) {
            expect(paginated, isA<PaginatedGossips>());
            expect(paginated.data.length, 1);
          },
        );

        verify(mockLogger.d(
          'Getting following feed',
          context: anyNamed('context'),
        )).called(1);
        verify(mockRemoteDataSource.getFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).called(1);
        verify(mockLogger.i(
          'Following feed retrieved successfully',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final testError = Exception('Database error');
        when(mockRemoteDataSource.getFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(testError);

        // Act
        final result = await repository.getFollowingFeed();

        // Assert
        expect(result.isFailure, isTrue);
        verify(mockLogger.e(
          'Error getting following feed',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
        )).called(1);
      });

      test('debe pasar cursor following correctamente', () async {
        // Arrange
        final cursor = FeedCursor.following(
          createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
          id: 'gossip-123',
        );

        when(mockRemoteDataSource.getFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: cursor,
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        await repository.getFollowingFeed(
          cursor: cursor,
        );

        // Assert
        verify(mockRemoteDataSource.getFollowingFeed(
          pageSize: 20,
          cursor: cursor,
        )).called(1);
      });
    });

    group('getRecommendedFeed', () {
      test('debe usar getPopularFeed internamente', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        final result = await repository.getRecommendedFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRemoteDataSource.getPopularFeed(
          userCityId: testCityId,
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe loguear como recommended feed', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        await repository.getRecommendedFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        verify(mockLogger.d(
          'Getting recommended feed',
          context: anyNamed('context'),
        )).called(1);
        verify(mockLogger.i(
          'Recommended feed retrieved successfully',
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe retornar Failure cuando datasource falla', () async {
        // Arrange
        final testError = Exception('Error');
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(testError);

        // Act
        final result = await repository.getRecommendedFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result.isFailure, isTrue);
        verify(mockLogger.e(
          'Error getting recommended feed',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
        )).called(1);
      });
    });

    group('checkNewGossips', () {
      test('debe retornar count cuando datasource retorna exitosamente',
          () async {
        // Arrange
        final since = DateTime.parse('2024-01-15T10:00:00Z');
        when(mockRemoteDataSource.checkNewGossips(
          userCityId: anyNamed('userCityId'),
          since: since,
        )).thenAnswer((_) async => 5);

        // Act
        final result = await repository.checkNewGossips(
          userId: testUserId,
          cityId: testCityId,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (count) {
            expect(count, 5);
          },
        );

        verify(mockLogger.d(
          'Checking new gossips',
          context: anyNamed('context'),
        )).called(1);
        verify(mockRemoteDataSource.checkNewGossips(
          userCityId: testCityId,
          since: since,
        )).called(1);
        verify(mockLogger.d(
          'New gossips check completed',
          context: {'count': 5},
        )).called(1);
      });

      test('debe retornar cero cuando no hay chismes nuevos', () async {
        // Arrange
        final since = DateTime.parse('2024-01-15T10:00:00Z');
        when(mockRemoteDataSource.checkNewGossips(
          userCityId: anyNamed('userCityId'),
          since: since,
        )).thenAnswer((_) async => 0);

        // Act
        final result = await repository.checkNewGossips(
          userId: testUserId,
          cityId: testCityId,
          since: since,
        );

        // Assert
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (count) {
            expect(count, 0);
          },
        );
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final since = DateTime.now();
        final testError = Exception('Network error');
        when(mockRemoteDataSource.checkNewGossips(
          userCityId: anyNamed('userCityId'),
          since: since,
        )).thenThrow(testError);

        // Act
        final result = await repository.checkNewGossips(
          userId: testUserId,
          cityId: testCityId,
          since: since,
        );

        // Assert
        expect(result.isFailure, isTrue);
        verify(mockLogger.e(
          'Error checking new gossips',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe manejar cityId null', () async {
        // Arrange
        final since = DateTime.parse('2024-01-15T10:00:00Z');
        when(mockRemoteDataSource.checkNewGossips(
          userCityId: null,
          since: since,
        )).thenAnswer((_) async => 3);

        // Act
        final result = await repository.checkNewGossips(
          userId: testUserId,
          cityId: null,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRemoteDataSource.checkNewGossips(
          userCityId: null,
          since: since,
        )).called(1);
      });
    });

    group('Error handling', () {
      test('debe usar ErrorHandler para convertir errores a Failure', () async {
        // Arrange
        final testError = Exception('Test error');
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(testError);

        // Act
        final result = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
          },
          onSuccess: (_) => fail('Should be failure'),
        );
      });

      test('debe incluir contexto relevante en logs de error', () async {
        // Arrange
        final testError = Exception('Test error');
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(testError);

        // Act
        await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        verify(mockLogger.e(
          'Error getting popular feed',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: {
            'userId': testUserId,
            'cityId': testCityId,
          },
        )).called(1);
      });
    });

    group('Edge cases', () {
      test('debe manejar respuesta vacía correctamente', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => const PaginatedGossipsModel.empty());

        // Act
        final result = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (paginated) {
            expect(paginated.data, isEmpty);
            expect(paginated.hasMore, false);
          },
        );
      });

      test('debe manejar múltiples llamadas consecutivas', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => tPaginatedModel);

        // Act
        final result1 = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );
        final result2 = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRemoteDataSource.getPopularFeed(
          userCityId: testCityId,
          pageSize: 20,
          cursor: null,
        )).called(2);
      });

      test('debe manejar diferentes tipos de errores', () async {
        // Arrange
        when(mockRemoteDataSource.getPopularFeed(
          userCityId: anyNamed('userCityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(FormatException('Invalid format'));

        // Act
        final result = await repository.getPopularFeed(
          userId: testUserId,
          cityId: testCityId,
        );

        // Assert
        expect(result.isFailure, isTrue);
      });
    });
  });
}
