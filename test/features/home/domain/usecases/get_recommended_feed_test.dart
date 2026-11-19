import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/domain/usecases/get_recommended_feed.dart';
import 'package:chismes/features/home/domain/repositories/home_repository.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;

import 'get_recommended_feed_test.mocks.dart';

@GenerateMocks([HomeRepository])
void main() {
  setUpAll(() {
    // Provide dummy value for mockito
    provideDummy<Result<Failure, PaginatedGossips>>(
      Result.success(const PaginatedGossips.empty()),
    );
  });

  late GetRecommendedFeed useCase;
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = GetRecommendedFeed(mockRepository);
  });

  group('GetRecommendedFeed', () {
    const userId = 'user-123';
    const cityId = 'city-456';
    const pageSize = 20;

    // Helper para crear un FeedGossip de prueba
    FeedGossip createTestGossip({
      String id = 'gossip-1',
      String subject = 'Test Subject',
      double score = 100.0,
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
        isTrending: false,
      );
    }

    group('Success cases', () {
      test('debe obtener feed recomendado exitosamente (primera página)',
          () async {
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

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
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
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
          userId: userId,
          cityId: cityId,
          pageSize: pageSize,
          cursor: cursor,
        )).called(1);
      });

      test('debe retornar lista vacía cuando no hay recomendaciones', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getRecommendedFeed(
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

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
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

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
          userId: userId,
          cityId: null,
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe usar pageSize por defecto (20)', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
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

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
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

        when(mockRepository.getRecommendedFeed(
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
        verify(mockRepository.getRecommendedFeed(
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

        when(mockRepository.getRecommendedFeed(
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

        when(mockRepository.getRecommendedFeed(
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

    group('Documentación', () {
      test('debe documentar que usa mismo algoritmo que Popular', () {
        // Documenta: mismo algoritmo de ranking que Popular feed
        // Pero típicamente con menos items por página
      });

      test('debe documentar uso como fallback de Following', () {
        // Documenta: se usa cuando Following feed está vacío
        // Muestra badge "Recomendados para ti 💡"
      });

      test('debe documentar ordenamiento por score', () {
        // Documenta: ordenado por score (algoritmo 40/30/20/10)
        // No por created_at como Following
      });
    });
  });
}
