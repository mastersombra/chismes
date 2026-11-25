import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/services/profile_service.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/domain/usecases/get_following_feed.dart';
import 'package:chismes/features/home/domain/usecases/get_recommended_feed.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/presentation/managers/location_manager.dart';
import 'package:chismes/features/location/presentation/states/location_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/services/auth_service.dart';

import 'following_tab_controller_test.mocks.dart';

@GenerateMocks([
  GetFollowingFeed,
  GetRecommendedFeed,
  LocationManager,
  ProfileService,
  AuthService,
  AppLogger,
])
void main() {
  late FollowingTabController controller;
  late MockGetFollowingFeed mockGetFollowingFeed;
  late MockGetRecommendedFeed mockGetRecommendedFeed;
  late MockLocationManager mockLocationManager;
  late MockProfileService mockProfileService;
  late MockAuthService mockAuthService;
  late MockAppLogger mockLogger;

  // Provide dummies
  provideDummy<Result<Failure, PaginatedGossips>>(
    Result.failure(const NetworkFailure(code: ErrorCode.networkError)),
  );

  final tCity = City(
    id: 'city-1',
    regionId: 'region-1',
    name: 'Buenos Aires',
  );

  final tGossip = FeedGossip(
    id: 'gossip-1',
    subject: 'Test Gossip',
    content: 'Test Content',
    cityId: 'city-1',
    createdAt: DateTime(2024, 1, 1),
    likes: 0,
    comments: 0,
    shares: 0,
    publishedAs: 'anonymous',
    createdBy: null,
    imageUrl: null,
    score: 100.0,
    isFromMyCity: null,
    isTrending: false,
  );

  final tCursor = FeedCursor.following(
    createdAt: DateTime(2024, 1, 1),
    id: 'cursor-1',
  );

  setUp(() {
    mockGetFollowingFeed = MockGetFollowingFeed();
    mockGetRecommendedFeed = MockGetRecommendedFeed();
    mockLocationManager = MockLocationManager();
    mockProfileService = MockProfileService();
    mockLogger = MockAppLogger();
    mockAuthService = MockAuthService();
    when(mockAuthService.userId).thenReturn('user-id');

    // Setup default LocationManager state
    when(mockLocationManager.state).thenReturn(
      LocationState.initial().copyWith(selectedCity: tCity),
    );

    // Setup default ProfileService (usuario sigue a 5 personas)
    when(mockProfileService.getFollowingCount(any))
        .thenAnswer((_) async => 5);

    controller = FollowingTabController(
      mockGetFollowingFeed,
      mockGetRecommendedFeed,
      mockLocationManager,
      mockProfileService,
      mockAuthService,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('FollowingTabController', () {
    test('debe inicializar con estado initial', () {
      expect(controller.state.status, FollowingTabStatus.initial);
      expect(controller.state.gossips, isEmpty);
      expect(controller.state.recommendedGossips, isEmpty);
      expect(controller.state.followingCount, 0);
    });

    test('debe notificar listeners cuando estado cambia', () async {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      final tPaginatedFeed = PaginatedGossips(
        data: [tGossip],
        hasMore: false,
        nextCursor: null,
      );

      when(mockGetFollowingFeed(
        pageSize: anyNamed('pageSize'),
        cursor: anyNamed('cursor'),
      )).thenAnswer((_) async => Result.success(tPaginatedFeed));

      // Act
      await controller.loadFeed();

      // Assert
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    group('loadFeed', () {
      test('debe cambiar estado a loading al iniciar', () async {
        // Arrange
        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        var capturedStates = <FollowingTabStatus>[];
        controller.addListener(() {
          capturedStates.add(controller.state.status);
        });

        // Act
        await controller.loadFeed();

        // Assert
        expect(capturedStates.first, FollowingTabStatus.loading);
      });

      test('usa el id del usuario autenticado (no un placeholder)', () async {
        when(mockAuthService.userId).thenReturn('d68036a0-uuid');
        when(mockProfileService.getFollowingCount(any))
            .thenAnswer((_) async => 0);

        await controller.loadFeed();

        verify(mockProfileService.getFollowingCount('d68036a0-uuid')).called(1);
      });

      test('sin usuario autenticado muestra notFollowing sin llamar al RPC',
          () async {
        when(mockAuthService.userId).thenReturn(null);

        await controller.loadFeed();

        expect(controller.state.status, FollowingTabStatus.notFollowing);
        verifyNever(mockProfileService.getFollowingCount(any));
        verifyNever(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        ));
      });

      test('debe cambiar estado a notFollowing cuando followingCount es 0',
          () async {
        // Arrange - Mockear que el usuario no sigue a nadie
        when(mockProfileService.getFollowingCount(any))
            .thenAnswer((_) async => 0);

        // Act
        await controller.loadFeed();

        // Assert - Debe cambiar a estado notFollowing sin llamar getFollowingFeed
        expect(controller.state.status, FollowingTabStatus.notFollowing);
        expect(controller.state.followingCount, 0);
        expect(controller.state.gossips, isEmpty);
        expect(controller.state.recommendedGossips, isEmpty);

        // No debe llamar a getFollowingFeed ni getRecommendedFeed
        verifyNever(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        ));
        verifyNever(mockGetRecommendedFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        ));
      });

      test('debe cargar gossips exitosamente cuando hay chismes', () async {
        // Arrange
        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, FollowingTabStatus.loaded);
        expect(controller.state.gossips, [tGossip]);
        expect(controller.state.hasMore, isTrue);
        expect(controller.state.nextCursor, tCursor);
        verify(mockGetFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test(
          'debe cargar recomendados cuando feed de following está vacío (fallback)',
          () async {
        // Arrange
        final tEmptyFeed = PaginatedGossips(
          data: [],
          hasMore: false,
          nextCursor: null,
        );

        final tRecommendedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tEmptyFeed));

        when(mockGetRecommendedFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tRecommendedFeed));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, FollowingTabStatus.loadedRecommended);
        expect(controller.state.recommendedGossips, [tGossip]);
        verify(mockGetFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).called(1);
        verify(mockGetRecommendedFeed(
          userId: null,
          cityId: tCity.id,
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe cambiar estado a error cuando falla GetFollowingFeed',
          () async {
        // Arrange
        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, FollowingTabStatus.error);
        expect(controller.state.errorMessage, isNotNull);
      });

      test('debe cambiar estado a error cuando falla GetRecommendedFeed',
          () async {
        // Arrange
        final tEmptyFeed = PaginatedGossips(
          data: [],
          hasMore: false,
          nextCursor: null,
        );

        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tEmptyFeed));

        when(mockGetRecommendedFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, FollowingTabStatus.error);
        expect(controller.state.errorMessage, isNotNull);
      });

      test('debe manejar excepción inesperada en loadFeed', () async {
        // Arrange
        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(Exception('Unexpected database error'));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, FollowingTabStatus.error);
        expect(
            controller.state.errorMessage, 'Unexpected error loading following feed');
      });

      test('debe manejar excepción inesperada en _loadRecommended (fallback)',
          () async {
        // Arrange - Following feed vacío para trigger fallback
        final tEmptyFeed = PaginatedGossips(
          data: [],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tEmptyFeed));

        // Simular excepción en getRecommendedFeed
        when(mockGetRecommendedFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(Exception('Unexpected recommendation error'));

        // Act
        await controller.loadFeed();

        // Assert - Debe manejar la excepción y cambiar a estado error
        expect(controller.state.status, FollowingTabStatus.error);
        expect(controller.state.errorMessage, 'Error loading recommended feed');
      });
    });

    group('refresh', () {
      test('debe resetear paginación y recargar feed', () async {
        // Arrange
        final tInitialFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tInitialFeed));

        // Cargar feed inicial
        await controller.loadFeed();

        final tRefreshedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tRefreshedFeed));

        // Act
        await controller.refresh();

        // Assert
        expect(controller.state.gossips, [tGossip]);
        expect(controller.state.hasMore, isFalse);
        verify(mockGetFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).called(2); // Una vez en loadFeed inicial, otra en refresh
      });
    });

    group('loadMore', () {
      test('debe cargar más gossips de following cuando hay más páginas',
          () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        final tSecondGossip = FeedGossip(
          id: 'gossip-2',
          subject: 'Second Gossip',
          content: 'Second Content',
          cityId: 'city-1',
          createdAt: DateTime(2024, 1, 2),
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          createdBy: null,
          imageUrl: null,
          score: 100.0,
          isFromMyCity: null,
          isTrending: false,
        );

        final tSecondPage = PaginatedGossips(
          data: [tSecondGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: tCursor,
        )).thenAnswer((_) async => Result.success(tSecondPage));

        // Act
        await controller.loadMore();

        // Assert
        expect(controller.state.status, FollowingTabStatus.loaded);
        expect(controller.state.gossips, [tGossip, tSecondGossip]);
        expect(controller.state.hasMore, isFalse);
        verify(mockGetFollowingFeed(
          pageSize: 20,
          cursor: tCursor,
        )).called(1);
      });

      test('debe cargar más gossips recomendados cuando está en modo recommended',
          () async {
        // Arrange - Setup empty following feed to trigger recommended
        final tEmptyFeed = PaginatedGossips(
          data: [],
          hasMore: false,
          nextCursor: null,
        );

        final tFirstRecommendedPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tEmptyFeed));

        when(mockGetRecommendedFeed(
          userId: null,
          cityId: tCity.id,
          pageSize: 20,
          cursor: null,
        )).thenAnswer((_) async => Result.success(tFirstRecommendedPage));

        await controller.loadFeed();

        final tSecondGossip = FeedGossip(
          id: 'gossip-2',
          subject: 'Second Recommended',
          content: 'Second Content',
          cityId: 'city-1',
          createdAt: DateTime(2024, 1, 2),
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          createdBy: null,
          imageUrl: null,
          score: 85.0,
          isFromMyCity: null,
          isTrending: false,
        );

        final tSecondPage = PaginatedGossips(
          data: [tSecondGossip],
          hasMore: false,
          nextCursor: null,
        );

        // Mock para segunda página de recommended
        when(mockGetRecommendedFeed(
          userId: null,
          cityId: tCity.id,
          pageSize: 20,
          cursor: tCursor,
        )).thenAnswer((_) async => Result.success(tSecondPage));

        // Act
        await controller.loadMore();

        // Assert - Debería llamar a _loadMoreRecommended
        expect(controller.state.status, FollowingTabStatus.loadedRecommended);
        expect(controller.state.recommendedGossips, [tGossip, tSecondGossip]);
        expect(controller.state.hasMore, isFalse);
        verify(mockGetRecommendedFeed(
          userId: null,
          cityId: tCity.id,
          pageSize: 20,
          cursor: tCursor,
        )).called(1);
      });

      test('debe mantener gossips recomendados cuando falla loadMore en modo recommended',
          () async {
        // Arrange
        final tEmptyFeed = PaginatedGossips(
          data: [],
          hasMore: false,
          nextCursor: null,
        );

        final tFirstRecommendedPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tEmptyFeed));

        when(mockGetRecommendedFeed(
          userId: null,
          cityId: tCity.id,
          pageSize: 20,
          cursor: null,
        )).thenAnswer((_) async => Result.success(tFirstRecommendedPage));

        await controller.loadFeed();

        const tFailure = NetworkFailure(code: ErrorCode.networkError);

        when(mockGetRecommendedFeed(
          userId: null,
          cityId: tCity.id,
          pageSize: 20,
          cursor: tCursor,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.loadMore();

        // Assert - Debe mantener gossips existentes
        expect(controller.state.status, FollowingTabStatus.loadedRecommended);
        expect(controller.state.recommendedGossips, [tGossip]);
      });

      test('no debe cargar más si ya está cargando', () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        // Simular que está cargando más
        controller.loadMore(); // No await para simular carga en progreso

        // Act
        await controller.loadMore(); // Segunda llamada

        // Assert
        // Solo debe llamar una vez más (no dos veces)
        verify(mockGetFollowingFeed(
          pageSize: 20,
          cursor: tCursor,
        )).called(1);
      });

      test('no debe cargar más si no hay más páginas', () async {
        // Arrange
        final tOnlyPage = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tOnlyPage));

        await controller.loadFeed();

        // Act
        await controller.loadMore();

        // Assert
        // No debe hacer llamada adicional
        verify(mockGetFollowingFeed(
          pageSize: 20,
          cursor: null,
        )).called(1); // Solo la llamada inicial
      });

      test('debe mantener gossips existentes cuando falla loadMore', () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: tCursor,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.loadMore();

        // Assert
        expect(controller.state.status, FollowingTabStatus.loaded);
        expect(controller.state.gossips, [tGossip]); // Mantiene los existentes
      });

      test('debe manejar excepción inesperada en loadMore', () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        // Simular excepción inesperada en loadMore
        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: tCursor,
        )).thenThrow(Exception('Unexpected pagination error'));

        // Act
        await controller.loadMore();

        // Assert - Debe volver al estado anterior sin crashear
        expect(controller.state.status, FollowingTabStatus.loaded);
        expect(controller.state.gossips, [tGossip]); // Mantiene los existentes
      });
    });

    group('activeList', () {
      test('debe retornar gossips cuando está en modo following', () async {
        // Arrange
        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        await controller.loadFeed();

        // Act & Assert
        expect(controller.state.activeList, controller.state.gossips);
        expect(controller.state.activeList, [tGossip]);
      });

      test('debe retornar recommendedGossips cuando está en modo recommended',
          () async {
        // Arrange
        final tEmptyFeed = PaginatedGossips(
          data: [],
          hasMore: false,
          nextCursor: null,
        );

        final tRecommendedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetFollowingFeed(
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tEmptyFeed));

        when(mockGetRecommendedFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tRecommendedFeed));

        await controller.loadFeed();

        // Act & Assert
        expect(
            controller.state.activeList, controller.state.recommendedGossips);
        expect(controller.state.activeList, [tGossip]);
      });
    });

    group('dispose', () {
      test('debe poder hacer dispose sin errores', () {
        // Arrange & Act & Assert
        // tearDown llama a dispose(), así que solo verificamos que el controller existe
        expect(controller, isNotNull);
      });
    });
  });
}
