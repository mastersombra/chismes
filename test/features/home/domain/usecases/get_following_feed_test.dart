import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/domain/usecases/get_following_feed.dart';
import 'package:chismes/features/home/domain/repositories/home_repository.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;

import 'get_following_feed_test.mocks.dart';

@GenerateMocks([HomeRepository])
void main() {
  setUpAll(() {
    // Provide dummy value for mockito
    provideDummy<Result<Failure, PaginatedGossips>>(
      Result.success(const PaginatedGossips.empty()),
    );
  });

  late GetFollowingFeed useCase;
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = GetFollowingFeed(mockRepository);
  });

  group('GetFollowingFeed', () {
    const userId = 'user-123';
    const cityId = 'city-456';
    const pageSize = 20;

    // Helper para crear un FeedGossip de prueba
    FeedGossip createTestGossip({
      String id = 'gossip-1',
      String subject = 'Test Subject',
      DateTime? createdAt,
    }) {
      return FeedGossip(
        id: id,
        subject: subject,
        content: 'Test content',
        cityId: cityId,
        createdAt: createdAt ?? DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
        shares: 2,
        publishedAs: 'profile',
        createdBy: userId,
        score: 0.0, // Following feed no usa score
        isFromMyCity: true,
        isTrending: false,
      );
    }

    group('Success cases', () {
      test('debe obtener feed de following exitosamente (primera página)',
          () async {
        // Arrange
        final now = DateTime.now();
        final gossips = [
          createTestGossip(id: 'gossip-1', createdAt: now),
          createTestGossip(
              id: 'gossip-2', createdAt: now.subtract(Duration(hours: 1))),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: FeedCursor.following(
            createdAt: now.subtract(Duration(hours: 1)),
            id: 'gossip-2',
          ),
        );

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.data.length, 2);
        expect(result.successValue?.hasMore, isTrue);
        expect(result.successValue?.nextCursor, isNotNull);
        verify(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe obtener segunda página con cursor', () async {
        // Arrange
        final now = DateTime.now();
        final cursor = FeedCursor.following(
          createdAt: now.subtract(Duration(hours: 1)),
          id: 'gossip-2',
        );
        final gossips = [
          createTestGossip(
              id: 'gossip-3', createdAt: now.subtract(Duration(hours: 2))),
          createTestGossip(
              id: 'gossip-4', createdAt: now.subtract(Duration(hours: 3))),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: FeedCursor.following(
            createdAt: now.subtract(Duration(hours: 3)),
            id: 'gossip-4',
          ),
        );

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: cursor,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: pageSize,
          cursor: cursor,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.data.length, 2);
        verify(mockRepository.getFollowingFeed(
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

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.hasMore, isFalse);
        expect(result.successValue?.nextCursor, isNull);
      });

      test('debe retornar lista vacía cuando no sigue a nadie', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue?.isEmpty, isTrue);
        expect(result.successValue?.hasMore, isFalse);
      });
    });

    group('Parámetros', () {
      test('no recibe user id (el servidor usa auth.uid()) y pasa pageSize', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe usar pageSize por defecto (20)', () async {
        // Arrange
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe aceptar pageSize personalizado', () async {
        // Arrange
        const customPageSize = 50;
        const paginated = PaginatedGossips.empty();

        when(mockRepository.getFollowingFeed(
          pageSize: customPageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: customPageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.getFollowingFeed(
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

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.failure(networkFailure));

        // Act
        final result = await useCase(
          pageSize: pageSize,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, networkFailure);
        verify(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).called(1);
      });

      test('debe manejar error de red', () async {
        // Arrange
        final failure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
        );

        when(mockRepository.getFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
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

        when(mockRepository.getFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<ServerFailure>());
      });

      test('debe manejar error de autorización', () async {
        // Arrange
        final failure = const AuthFailure(
          code: error_codes.ErrorCode.unauthorized,
          technicalMessage: 'User not authenticated',
        );

        when(mockRepository.getFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<AuthFailure>());
      });
    });

    group('Chronological ordering', () {
      test('debe retornar gossips ordenados por created_at DESC', () async {
        // Arrange
        final now = DateTime.now();
        final gossips = [
          createTestGossip(id: 'gossip-1', createdAt: now),
          createTestGossip(
              id: 'gossip-2', createdAt: now.subtract(Duration(hours: 1))),
          createTestGossip(
              id: 'gossip-3', createdAt: now.subtract(Duration(hours: 2))),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        when(mockRepository.getFollowingFeed(
          pageSize: pageSize,
          cursor: null,
        )).thenAnswer((_) async => Result.success(paginated));

        // Act
        final result = await useCase(
          pageSize: pageSize,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final data = result.successValue!.data;
        expect(data[0].createdAt.isAfter(data[1].createdAt), isTrue);
        expect(data[1].createdAt.isAfter(data[2].createdAt), isTrue);
      });
    });

    group('Documentación', () {
      test('debe documentar que solo muestra chismes de quienes sigo', () {
        // Documenta: filtro por tabla user_follows
        // Solo chismes de usuarios que el currentUser sigue
      });

      test('debe documentar filtros de visibilidad', () {
        // Documenta: solo chismes con:
        // - status: published
        // - moderationStatus: approved
        // - visibility: public o followers
      });

      test('debe documentar ordenamiento cronológico', () {
        // Documenta: ordenado por created_at DESC
        // Los chismes más recientes aparecen primero
      });

      test('debe documentar fallback a recommended', () {
        // Documenta: cuando el feed está vacío (no sigue a nadie o sin chismes)
        // El controller debe cargar recommended feed
      });

      test('debe documentar cursor-based pagination', () {
        // Documenta: usa cursor-based pagination con created_at e id
        // Performance: O(1) vs O(n) con offsets grandes
      });
    });
  });
}
