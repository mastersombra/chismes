import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/domain/usecases/get_popular_feed.dart';
import 'package:chismes/features/home/domain/repositories/home_repository.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;

import 'get_popular_feed_test.mocks.dart';

@GenerateMocks([HomeRepository])
void main() {
  setUpAll(() {
    // Provide dummy value for mockito
    provideDummy<Result<Failure, PaginatedGossips>>(
      Result.success(const PaginatedGossips.empty()),
    );
  });

  late GetPopularFeed useCase;
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = GetPopularFeed(mockRepository);
  });

  group('GetPopularFeed', () {
    const userId = 'user-123';
    const cityId = 'city-456';
    const pageSize = 20;

    // Helper para crear un FeedGossip de prueba
    FeedGossip createTestGossip({
      String id = 'gossip-1',
      String subject = 'Test Subject',
      double score = 100.0,
      bool isTrending = false,
    }) {
      return FeedGossip(
        id: id,
        subject: subject,
        content: 'Test content',
        cityId: cityId,
        createdAt: DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
        shares: 2,
        publishedAs: 'profile',
        createdBy: userId,
        score: score,
        isFromMyCity: true,
        isTrending: isTrending,
      );
    }

    group('Success cases', () {
      test('debe obtener feed popular exitosamente (primera página)', () async {
        // Arrange
        final gossips = [
          createTestGossip(id: 'gossip-1', score: 100.0),
          createTestGossip(id: 'gossip-2', score: 90.0),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: FeedCursor.popular(score: 90.0, id: 'gossip-2'),
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.data.length, 2);
        expect(result.successValue?.hasMore, isTrue);
        expect(result.successValue?.nextCursor, isNotNull);
        verify(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe obtener segunda página con cursor', () async {
        // Arrange
        final cursor = FeedCursor.popular(score: 90.0, id: 'gossip-2');
        final gossips = [
          createTestGossip(id: 'gossip-3', score: 85.0),
          createTestGossip(id: 'gossip-4', score: 80.0),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: FeedCursor.popular(score: 80.0, id: 'gossip-4'),
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: cursor,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: cursor,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.data.length, 2);
        verify(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: cursor,
        )).called(1);
      });

      test('debe obtener última página (hasMore: false)', () async {
        // Arrange
        final gossips = [createTestGossip(id: 'gossip-last')];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.hasMore, isFalse);
        expect(result.successValue?.nextCursor, isNull);
      });

      test('debe retornar lista vacía cuando no hay gossips', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.isEmpty, isTrue);
        expect(result.successValue?.hasMore, isFalse);
      });
    });

    group('Parámetros opcionales', () {
      test('debe funcionar con userId null (usuario no autenticado)', () async {
        // Arrange
        final gossips = [createTestGossip()];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getPopularFeed(
          userId: null,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: null,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getPopularFeed(
          userId: null,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe funcionar con cityId null (ciudad no configurada)', () async {
        // Arrange
        final gossips = [createTestGossip()];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: null,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: null,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getPopularFeed(
          userId: userId,
          cityId: null,
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe usar pageSize por defecto (20)', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: 20,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe aceptar pageSize personalizado', () async {
        // Arrange
        const customPageSize = 50;
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: customPageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: customPageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: customPageSize,
          cursor: null,
        )).called(1);
      });
    });

    group('Failure cases', () {
      test('debe retornar failure cuando repository falla', () async {
        // Arrange
        final networkFailure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.failure(networkFailure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, networkFailure);
        verify(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe manejar error de red', () async {
        // Arrange
        final failure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
        );

        when(mockRepository.getPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<NetworkFailure>());
      });

      test('debe manejar error de servidor', () async {
        // Arrange
        final failure = const ServerFailure(
          code: error_codes.ErrorCode.serverError,
          technicalMessage: 'Internal server error',
        );

        when(mockRepository.getPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<ServerFailure>());
      });
    });

    group('Trending gossips', () {
      test('debe incluir gossips trending en el feed', () async {
        // Arrange
        final gossips = [
          createTestGossip(id: 'trending-1', isTrending: true, score: 100.0),
          createTestGossip(id: 'normal-1', isTrending: false, score: 90.0),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final data = result.successValue!.data;
        expect(data[0].isTrending, isTrue);
        expect(data[1].isTrending, isFalse);
      });
    });

    group('Score ordering', () {
      test('debe retornar gossips ordenados por score', () async {
        // Arrange
        final gossips = [
          createTestGossip(id: 'gossip-1', score: 100.0),
          createTestGossip(id: 'gossip-2', score: 90.0),
          createTestGossip(id: 'gossip-3', score: 80.0),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getPopularFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final data = result.successValue!.data;
        expect(data[0].score, 100.0);
        expect(data[1].score, 90.0);
        expect(data[2].score, 80.0);
      });
    });

    group('Documentación de algoritmo', () {
      test('debe documentar algoritmo de ranking (40/30/20/10)', () {
        // Documenta: el algoritmo de ranking usa 4 factores:
        // - 40% Ciudad (local=100, trending=50, otras=20)
        // - 30% Interacciones (likes*1 + comments*2 + shares*3)
        // - 20% Velocity (interacciones / horas)
        // - 10% Decay (penalización por antigüedad)
      });

      test('debe documentar filtro de virales', () {
        // Documenta: chismes de otras ciudades solo aparecen si:
        // - likes > 1000 OR
        // - comments > 200 OR
        // - shares > 100 OR
        // - total interacciones > 500
      });

      test('debe documentar cursor-based pagination', () {
        // Documenta: usa cursor-based pagination (no offset)
        // El cursor contiene score e id del último elemento
        // Performance: O(1) vs O(n) con offsets grandes
      });
    });
  });
}
