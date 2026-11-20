import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/domain/usecases/check_new_gossips.dart';
import 'package:chismes/features/home/domain/usecases/get_popular_feed.dart';
import 'package:chismes/features/home/presentation/controllers/popular_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/popular_tab_state.dart';
import 'dart:async';

import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:flutter/foundation.dart';
import 'package:chismes/features/location/presentation/managers/location_manager.dart';
import 'package:chismes/features/location/presentation/states/location_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/localization/device_region.dart';
import 'package:chismes/core/services/gossip_events.dart';

import 'popular_tab_controller_test.mocks.dart';

@GenerateMocks([
  GetPopularFeed,
  CheckNewGossips,
  LocationManager,
  DeviceRegion,
  AppLogger,
])
void main() {
  late PopularTabController controller;
  late MockGetPopularFeed mockGetPopularFeed;
  late MockCheckNewGossips mockCheckNewGossips;
  late MockLocationManager mockLocationManager;
  late MockDeviceRegion mockDeviceRegion;
  late GossipEvents gossipEvents;
  late MockAppLogger mockLogger;

  // Provide dummies
  provideDummy<Result<Failure, PaginatedGossips>>(
    Result.failure(const NetworkFailure(code: ErrorCode.networkError)),
  );

  provideDummy<Result<Failure, int>>(
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

  final tCursor = FeedCursor.popular(
    score: 100.0,
    id: 'cursor-1',
  );

  setUp(() {
    mockGetPopularFeed = MockGetPopularFeed();
    mockCheckNewGossips = MockCheckNewGossips();
    mockLocationManager = MockLocationManager();
    mockDeviceRegion = MockDeviceRegion();
    gossipEvents = GossipEvents();
    mockLogger = MockAppLogger();

    // Región del teléfono por defecto: sin país
    when(mockDeviceRegion.countryCode).thenReturn(null);

    // Setup default LocationManager state
    when(mockLocationManager.state).thenReturn(
      LocationState.initial().copyWith(selectedCity: tCity),
    );

    controller = PopularTabController(
      mockGetPopularFeed,
      mockCheckNewGossips,
      mockLocationManager,
      mockDeviceRegion,
      gossipEvents,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('PopularTabController', () {
    test('debe inicializar con estado initial', () {
      expect(controller.state.status, PopularTabStatus.initial);
      expect(controller.state.gossips, isEmpty);
      expect(controller.state.hasNewGossips, isFalse);
      expect(controller.state.newGossipsCount, 0);
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

      when(mockGetPopularFeed(
        userId: anyNamed('userId'),
        cityId: anyNamed('cityId'),
        regionId: anyNamed('regionId'),
        countryId: anyNamed('countryId'),
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

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        var capturedStates = <PopularTabStatus>[];
        controller.addListener(() {
          capturedStates.add(controller.state.status);
        });

        // Act
        await controller.loadFeed();

        // Assert
        expect(capturedStates.first, PopularTabStatus.loading);
      });

      test('debe cargar feed exitosamente con ciudad', () async {
        // Arrange
        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, PopularTabStatus.loaded);
        expect(controller.state.gossips, [tGossip]);
        expect(controller.state.currentCityId, tCity.id);
        expect(controller.state.currentCityName, tCity.name);
        expect(controller.state.hasMore, isTrue);
        expect(controller.state.nextCursor, tCursor);
        expect(controller.state.lastLoadTime, isNotNull);
        verify(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe cargar feed exitosamente sin ciudad (global)', () async {
        // Arrange
        when(mockLocationManager.state).thenReturn(
          LocationState.initial(), // Sin ciudad
        );

        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, PopularTabStatus.loaded);
        expect(controller.state.currentCityId, isNull);
        expect(controller.state.currentCityName, isNull);
        verify(mockGetPopularFeed(
          userId: null,
          cityId: null,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'), // Feed global
          pageSize: 20,
          cursor: null,
        )).called(1);
      });

      test('debe cambiar estado a error cuando falla', () async {
        // Arrange
        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, PopularTabStatus.error);
        expect(controller.state.errorMessage, isNotNull);
      });

      test('debe manejar excepción inesperada en loadFeed', () async {
        // Arrange
        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenThrow(Exception('Unexpected database error'));

        // Act
        await controller.loadFeed();

        // Assert
        expect(controller.state.status, PopularTabStatus.error);
        expect(controller.state.errorMessage, 'Error inesperado al cargar feed');
      });
    });

    group('refresh', () {
      test('debe resetear paginación y banner de nuevos chismes', () async {
        // Arrange
        final tInitialFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tInitialFeed));

        await controller.loadFeed();

        // Simular que hay nuevos chismes
        when(mockCheckNewGossips(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          since: anyNamed('since'),
        )).thenAnswer((_) async => Result.success(5));

        final tRefreshedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tRefreshedFeed));

        // Act
        await controller.refresh();

        // Assert
        expect(controller.state.hasNewGossips, isFalse);
        expect(controller.state.newGossipsCount, 0);
        expect(controller.state.hasMore, isFalse); // Refleja la respuesta final
        verify(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: 20,
          cursor: null,
        )).called(2); // Una vez en loadFeed inicial, otra en refresh
      });
    });

    group('loadMore', () {
      test('debe cargar más gossips cuando hay más páginas', () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
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
          score: 90.0,
          isFromMyCity: null,
          isTrending: false,
        );

        final tSecondPage = PaginatedGossips(
          data: [tSecondGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: 20,
          cursor: tCursor,
        )).thenAnswer((_) async => Result.success(tSecondPage));

        // Act
        await controller.loadMore();

        // Assert
        expect(controller.state.status, PopularTabStatus.loaded);
        expect(controller.state.gossips, [tGossip, tSecondGossip]);
        expect(controller.state.hasMore, isFalse);
        verify(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: 20,
          cursor: tCursor,
        )).called(1);
      });

      test('no debe cargar más si ya está cargando', () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        // Simular que está cargando más
        controller.loadMore(); // No await

        // Act
        await controller.loadMore(); // Segunda llamada

        // Assert
        // Solo debe llamar una vez más
        verify(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
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

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tOnlyPage));

        await controller.loadFeed();

        // Act
        await controller.loadMore();

        // Assert
        verify(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
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

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
        );

        when(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: 20,
          cursor: tCursor,
        )).thenAnswer((_) async => Result.failure(tFailure));

        // Act
        await controller.loadMore();

        // Assert
        expect(controller.state.status, PopularTabStatus.loaded);
        expect(controller.state.gossips, [tGossip]); // Mantiene los existentes
      });

      test('debe manejar excepción inesperada en loadMore', () async {
        // Arrange
        final tFirstPage = PaginatedGossips(
          data: [tGossip],
          hasMore: true,
          nextCursor: tCursor,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tFirstPage));

        await controller.loadFeed();

        // Simular excepción inesperada en loadMore
        when(mockGetPopularFeed(
          userId: null,
          cityId: tCity.id,
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: 20,
          cursor: tCursor,
        )).thenThrow(Exception('Unexpected pagination error'));

        // Act
        await controller.loadMore();

        // Assert - Debe volver a estado loaded sin crashear
        expect(controller.state.status, PopularTabStatus.loaded);
        expect(controller.state.gossips, [tGossip]); // Mantiene los existentes
      });
    });

    group('loadNewGossips', () {
      test('debe ocultar banner y recargar feed', () async {
        // Arrange
        final tInitialFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tInitialFeed));

        await controller.loadFeed();

        final tNewGossip = FeedGossip(
          id: 'gossip-2',
          subject: 'New Gossip',
          content: 'New Content',
          cityId: 'city-1',
          createdAt: DateTime(2024, 1, 2),
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          createdBy: null,
          imageUrl: null,
          score: 95.0,
          isFromMyCity: null,
          isTrending: false,
        );

        final tRefreshedFeed = PaginatedGossips(
          data: [tNewGossip, tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tRefreshedFeed));

        // Act
        await controller.loadNewGossips();

        // Assert
        expect(controller.state.hasNewGossips, isFalse);
        expect(controller.state.newGossipsCount, 0);
        expect(controller.state.gossips.length, 2);
      });
    });

    group('locationHeaderText', () {
      test('debe retornar texto con ciudad cuando hay ciudad', () async {
        // Arrange
        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        await controller.loadFeed();

        // Act & Assert
        expect(controller.state.locationHeaderText, 'Popular en Buenos Aires');
      });

      test('debe retornar texto global cuando no hay ciudad', () async {
        // Arrange
        when(mockLocationManager.state).thenReturn(
          LocationState.initial(), // Sin ciudad
        );

        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        await controller.loadFeed();

        // Act & Assert
        expect(controller.state.locationHeaderText, 'Popular 🌎');
      });
    });

    group('polling', () {
      test('debe iniciar polling después de loadFeed exitoso', () {
        fakeAsync((async) {
          // Arrange - Crear controller independiente
          final testController = PopularTabController(
            mockGetPopularFeed,
            mockCheckNewGossips,
            mockLocationManager,
            mockDeviceRegion,
            gossipEvents,
            mockLogger,
          );

          final tPaginatedFeed = PaginatedGossips(
            data: [tGossip],
            hasMore: false,
            nextCursor: null,
          );

          when(mockGetPopularFeed(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            pageSize: anyNamed('pageSize'),
            cursor: anyNamed('cursor'),
          )).thenAnswer((_) async => Result.success(tPaginatedFeed));

          when(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).thenAnswer((_) async => Result.success(3));

          // Act - Cargar feed (esto inicia el polling)
          testController.loadFeed();
          async.flushMicrotasks();

          // Assert - Verificar que polling se ejecuta después de 60 segundos
          verifyNever(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          ));

          // Avanzar 60 segundos (intervalo de polling)
          async.elapse(const Duration(seconds: 60));

          // Verificar que se llamó checkNewGossips
          verify(mockCheckNewGossips(
            userId: null,
            cityId: tCity.id,
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).called(1);

          // Limpiar
          testController.dispose();
        });
      });

      test('debe detener polling en dispose', () {
        fakeAsync((async) {
          // Arrange - Crear controller independiente
          final testController = PopularTabController(
            mockGetPopularFeed,
            mockCheckNewGossips,
            mockLocationManager,
            mockDeviceRegion,
            gossipEvents,
            mockLogger,
          );

          final tPaginatedFeed = PaginatedGossips(
            data: [tGossip],
            hasMore: false,
            nextCursor: null,
          );

          when(mockGetPopularFeed(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            pageSize: anyNamed('pageSize'),
            cursor: anyNamed('cursor'),
          )).thenAnswer((_) async => Result.success(tPaginatedFeed));

          when(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).thenAnswer((_) async => Result.success(0));

          testController.loadFeed();
          async.flushMicrotasks();

          // Act - Dispose del controller
          testController.dispose();

          // Avanzar 60 segundos (no debería llamar checkNewGossips)
          async.elapse(const Duration(seconds: 60));

          // Assert - No debe llamar checkNewGossips después de dispose
          verifyNever(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          ));
        });
      });

      test('debe detectar nuevos chismes y actualizar estado', () {
        fakeAsync((async) {
          // Arrange - Crear controller independiente
          final testController = PopularTabController(
            mockGetPopularFeed,
            mockCheckNewGossips,
            mockLocationManager,
            mockDeviceRegion,
            gossipEvents,
            mockLogger,
          );

          final tPaginatedFeed = PaginatedGossips(
            data: [tGossip],
            hasMore: false,
            nextCursor: null,
          );

          when(mockGetPopularFeed(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            pageSize: anyNamed('pageSize'),
            cursor: anyNamed('cursor'),
          )).thenAnswer((_) async => Result.success(tPaginatedFeed));

          // Simular que hay 5 nuevos chismes
          when(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).thenAnswer((_) async => Result.success(5));

          testController.loadFeed();
          async.flushMicrotasks();

          // Act - Avanzar 60 segundos (trigger polling)
          async.elapse(const Duration(seconds: 60));
          async.flushMicrotasks();

          // Assert - Estado debe reflejar nuevos chismes
          expect(testController.state.hasNewGossips, isTrue);
          expect(testController.state.newGossipsCount, 5);

          // Limpiar
          testController.dispose();
        });
      });

      test('no debe actualizar estado cuando no hay nuevos chismes', () {
        fakeAsync((async) {
          // Arrange - Crear controller independiente
          final testController = PopularTabController(
            mockGetPopularFeed,
            mockCheckNewGossips,
            mockLocationManager,
            mockDeviceRegion,
            gossipEvents,
            mockLogger,
          );

          final tPaginatedFeed = PaginatedGossips(
            data: [tGossip],
            hasMore: false,
            nextCursor: null,
          );

          when(mockGetPopularFeed(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            pageSize: anyNamed('pageSize'),
            cursor: anyNamed('cursor'),
          )).thenAnswer((_) async => Result.success(tPaginatedFeed));

          // Simular que NO hay nuevos chismes
          when(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).thenAnswer((_) async => Result.success(0));

          testController.loadFeed();
          async.flushMicrotasks();

          // Act - Avanzar 60 segundos (trigger polling)
          async.elapse(const Duration(seconds: 60));
          async.flushMicrotasks();

          // Assert - Estado NO debe cambiar
          expect(testController.state.hasNewGossips, isFalse);
          expect(testController.state.newGossipsCount, 0);

          // Limpiar
          testController.dispose();
        });
      });

      test('debe fallar silenciosamente cuando checkNewGossips retorna failure',
          () {
        fakeAsync((async) {
          // Arrange - Crear controller independiente
          final testController = PopularTabController(
            mockGetPopularFeed,
            mockCheckNewGossips,
            mockLocationManager,
            mockDeviceRegion,
            gossipEvents,
            mockLogger,
          );

          final tPaginatedFeed = PaginatedGossips(
            data: [tGossip],
            hasMore: false,
            nextCursor: null,
          );

          when(mockGetPopularFeed(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            pageSize: anyNamed('pageSize'),
            cursor: anyNamed('cursor'),
          )).thenAnswer((_) async => Result.success(tPaginatedFeed));

          // Simular fallo en checkNewGossips
          const tFailure = NetworkFailure(code: ErrorCode.networkError);
          when(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).thenAnswer((_) async => Result.failure(tFailure));

          testController.loadFeed();
          async.flushMicrotasks();

          // Act - Avanzar 60 segundos (trigger polling)
          async.elapse(const Duration(seconds: 60));
          async.flushMicrotasks();

          // Assert - No debe crashear, estado no cambia
          expect(testController.state.hasNewGossips, isFalse);
          expect(testController.state.newGossipsCount, 0);

          // Limpiar
          testController.dispose();
        });
      });

      test('debe fallar silenciosamente cuando checkNewGossips lanza excepción',
          () {
        fakeAsync((async) {
          // Arrange - Crear controller independiente
          final testController = PopularTabController(
            mockGetPopularFeed,
            mockCheckNewGossips,
            mockLocationManager,
            mockDeviceRegion,
            gossipEvents,
            mockLogger,
          );

          final tPaginatedFeed = PaginatedGossips(
            data: [tGossip],
            hasMore: false,
            nextCursor: null,
          );

          when(mockGetPopularFeed(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            pageSize: anyNamed('pageSize'),
            cursor: anyNamed('cursor'),
          )).thenAnswer((_) async => Result.success(tPaginatedFeed));

          // Simular excepción inesperada
          when(mockCheckNewGossips(
            userId: anyNamed('userId'),
            cityId: anyNamed('cityId'),
            regionId: anyNamed('regionId'),
            countryId: anyNamed('countryId'),
            since: anyNamed('since'),
          )).thenThrow(Exception('Unexpected polling error'));

          testController.loadFeed();
          async.flushMicrotasks();

          // Act - Avanzar 60 segundos (trigger polling)
          async.elapse(const Duration(seconds: 60));
          async.flushMicrotasks();

          // Assert - No debe crashear, estado no cambia
          expect(testController.state.hasNewGossips, isFalse);
          expect(testController.state.newGossipsCount, 0);

          // Limpiar
          testController.dispose();
        });
      });
    });

    group('dispose', () {
      test('debe poder hacer dispose sin errores', () async {
        // Arrange
        final tPaginatedFeed = PaginatedGossips(
          data: [tGossip],
          hasMore: false,
          nextCursor: null,
        );

        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPaginatedFeed));

        await controller.loadFeed(); // Esto inicia el polling

        // Act & Assert
        // tearDown llama a dispose(), así que solo verificamos que el controller existe
        // y que loadFeed se ejecutó correctamente
        expect(controller, isNotNull);
        expect(controller.state.status, PopularTabStatus.loaded);
      });
    });
    group('ubicación del feed (anillos de cercanía)', () {
      final tPage = PaginatedGossips(data: [tGossip], hasMore: false);

      void stubFeed() {
        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) async => Result.success(tPage));
      }

      VoidCallback capturedLocationListener() =>
          verify(mockLocationManager.addListener(captureAny)).captured.single
              as VoidCallback;

      test('con ciudad envía ciudad, región y país seleccionados', () async {
        stubFeed();
        when(mockLocationManager.state).thenReturn(LocationState.initial().copyWith(
          selectedCountry: const Country(id: 'CO', code: 'CO', name: 'Colombia'),
          selectedCity: tCity,
        ));

        await controller.loadFeed();

        verify(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: 'city-1',
          regionId: 'region-1',
          countryId: 'CO',
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).called(1);
      });

      test('sin ciudad usa solo el país de la región del teléfono', () async {
        stubFeed();
        when(mockLocationManager.state).thenReturn(LocationState.initial());
        when(mockDeviceRegion.countryCode).thenReturn('CO');

        await controller.loadFeed();

        verify(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: null,
          regionId: null,
          countryId: 'CO',
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).called(1);
      });

      test('recarga cuando cambia la ciudad (LocationManager compartido)', () async {
        stubFeed();
        when(mockLocationManager.state).thenReturn(LocationState.initial());
        await controller.loadFeed();
        final listener = capturedLocationListener();

        // El usuario elige/detecta Medellín en Crea
        when(mockLocationManager.state).thenReturn(
          LocationState.initial().copyWith(selectedCity: tCity),
        );
        listener();
        await untilCalled(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: 'city-1',
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        ));

        verify(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: 'city-1',
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).called(1);
      });

      test('no recarga si la ubicación no cambió o aún está cargando', () async {
        stubFeed();
        await controller.loadFeed();
        final listener = capturedLocationListener();
        clearInteractions(mockGetPopularFeed);

        listener(); // misma ubicación
        when(mockLocationManager.state).thenReturn(
          LocationState.initial().copyWith(isDetectingLocation: true),
        );
        listener(); // detectando: esperar a que termine
        await Future<void>.delayed(Duration.zero);

        verifyNever(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        ));
      });

      test('recarga el feed al publicar un chisme', () async {
        stubFeed();
        await controller.loadFeed();
        clearInteractions(mockGetPopularFeed);

        gossipEvents.gossipPublished();
        await untilCalled(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        ));
        await Future<void>.delayed(Duration.zero); // dejar que responda

        expect(controller.state.status, PopularTabStatus.loaded);
      });

      test('descarta la respuesta de un loadFeed viejo', () async {
        final stale = Completer<Result<Failure, PaginatedGossips>>();
        final staleGossip = FeedGossip(
          id: 'old',
          subject: 'Viejo',
          content: 'c',
          cityId: 'x',
          createdAt: DateTime(2024),
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'profile',
          score: 1,
          isTrending: false,
        );
        var call = 0;
        when(mockGetPopularFeed(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          regionId: anyNamed('regionId'),
          countryId: anyNamed('countryId'),
          pageSize: anyNamed('pageSize'),
          cursor: anyNamed('cursor'),
        )).thenAnswer((_) => ++call == 1 ? stale.future : Future.value(Result.success(tPage)));

        final first = controller.loadFeed();
        await controller.loadFeed(); // más nuevo, responde primero
        stale.complete(Result.success(
          PaginatedGossips(data: [staleGossip], hasMore: false),
        ));
        await first;

        expect(controller.state.gossips, [tGossip]);
      });

      test('dispose deja de escuchar ubicación y publicaciones', () {
        final local = PopularTabController(
          mockGetPopularFeed,
          mockCheckNewGossips,
          mockLocationManager,
          mockDeviceRegion,
          gossipEvents,
          mockLogger,
        );
        local.dispose();

        verify(mockLocationManager.removeListener(any)).called(1);
        expect(() => gossipEvents.gossipPublished(), returnsNormally);
      });
    });
  });
}
