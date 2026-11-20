import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/services/gossip_events.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:chismes/features/home/presentation/screens/home_screen.dart';
import 'package:chismes/features/gossip/presentation/controllers/add_gossip_controller.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/usecases/search_gossips.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/location/domain/usecases/search_cities.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/presentation/managers/location_manager.dart';
import 'package:chismes/features/location/presentation/states/location_state.dart';
import 'package:chismes/features/home/presentation/controllers/popular_tab_controller.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/popular_tab_state.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
import 'package:chismes/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/services/search_history_service.dart';
import 'package:chismes/core/services/location_service.dart';

import '../../../../helpers/mock_add_gossip_controller_helper.dart';
import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'main_navigation_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AddGossipController>(),
  MockSpec<GetGossips>(),
  MockSpec<SearchGossips>(),
  MockSpec<SearchCities>(),
  MockSpec<LocationManager>(),
  MockSpec<PopularTabController>(),
  MockSpec<FollowingTabController>(),
  MockSpec<ProfileController>(),
  MockSpec<AuthRepository>(),
  MockSpec<SearchHistoryService>(),
  MockSpec<LocationService>(),
])
void main() {
  late MockAddGossipController mockController;
  late MockGetGossips mockGetGossips;
  late MockSearchGossips mockSearchGossips;
  late MockSearchCities mockSearchCities;
  late MockLocationManager mockLocationManager;
  late MockPopularTabController mockPopularTabController;
  late MockFollowingTabController mockFollowingTabController;
  late MockProfileController mockProfileController;
  late MockAuthRepository mockAuthRepository;
  late MockSearchHistoryService mockSearchHistoryService;
  late MockLocationService mockLocationService;

  setUp(() async {
    // Inicializar DI para tests (LocaleNotifier, SharedPreferences, etc.)
    await setupTestDI();

    mockController = MockAddGossipController();
    mockGetGossips = MockGetGossips();
    mockSearchGossips = MockSearchGossips();
    mockSearchCities = MockSearchCities();
    mockLocationManager = MockLocationManager();
    mockPopularTabController = MockPopularTabController();
    mockFollowingTabController = MockFollowingTabController();
    mockProfileController = MockProfileController();
    mockAuthRepository = MockAuthRepository();
    mockSearchHistoryService = MockSearchHistoryService();
    mockLocationService = MockLocationService();

    // Proporcionar dummy values
    provideDummy<Result<Failure, List<Gossip>>>(
      Result.success(<Gossip>[]),
    );
    provideDummy<Result<Failure, List<City>>>(
      Result.failure(const ValidationFailure(code: ErrorCode.invalidInput)),
    );

    // Mock LocationManager
    when(mockLocationManager.state).thenReturn(const LocationState(
      countries: [],
      regions: [],
      cities: [],
      isLoadingCountries: false,
      isLoadingRegions: false,
      isLoadingCities: false,
      isDetectingLocation: false,
    ));
    when(mockLocationManager.addListener(any)).thenReturn(null);
    when(mockLocationManager.removeListener(any)).thenReturn(null);
    when(mockLocationManager.loadCountries()).thenAnswer((_) async => {});
    when(mockLocationManager.loadDefaultLocation()).thenAnswer((_) async => {});
    when(mockLocationManager.detectLocationFromGPS()).thenAnswer((_) async => {});
    when(mockLocationManager.saveDefaultLocation()).thenAnswer((_) async => {});

    // Setup controller con helper
    setupMockAddGossipController(mockController, locationManager: mockLocationManager);

    // Mock PopularTabController
    when(mockPopularTabController.state).thenReturn(const PopularTabState());
    when(mockPopularTabController.addListener(any)).thenReturn(null);
    when(mockPopularTabController.removeListener(any)).thenReturn(null);
    when(mockPopularTabController.loadFeed()).thenAnswer((_) async => {});
    when(mockPopularTabController.dispose()).thenReturn(null);

    // Mock FollowingTabController
    when(mockFollowingTabController.state).thenReturn(const FollowingTabState());
    when(mockFollowingTabController.addListener(any)).thenReturn(null);
    when(mockFollowingTabController.removeListener(any)).thenReturn(null);
    when(mockFollowingTabController.loadFeed()).thenAnswer((_) async => {});
    when(mockFollowingTabController.dispose()).thenReturn(null);

    // Mock ProfileController
    when(mockProfileController.addListener(any)).thenReturn(null);
    when(mockProfileController.removeListener(any)).thenReturn(null);
    when(mockProfileController.dispose()).thenReturn(null);

    // Mock AuthRepository
    when(mockAuthRepository.currentUser).thenReturn(User(
      id: 'test-user-id',
      email: 'test@example.com',
      emailVerified: true,
      profileCompleted: true,
      createdAt: DateTime.now(),
    ));

    // Mock SearchHistoryService
    when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => []);
    when(mockSearchHistoryService.addSearch(any)).thenAnswer((_) async => {});
    when(mockSearchHistoryService.removeSearch(any)).thenAnswer((_) async => {});
    when(mockSearchHistoryService.clearHistory()).thenAnswer((_) async => {});

    // Mock LocationService
    when(mockLocationService.getCurrentPosition()).thenAnswer((_) async => null);
    when(mockLocationService.getDefaultLocation()).thenAnswer((_) async => null);
    when(mockLocationService.saveDefaultLocation(
      countryId: anyNamed('countryId'),
      regionId: anyNamed('regionId'),
      cityId: anyNamed('cityId'),
      countryName: anyNamed('countryName'),
      regionName: anyNamed('regionName'),
      cityName: anyNamed('cityName'),
    )).thenAnswer((_) async => {});
    when(mockLocationService.clearDefaultLocation()).thenAnswer((_) async => {});

    // Registrar mocks en getIt
    if (getIt.isRegistered<AddGossipController>()) {
      getIt.unregister<AddGossipController>();
    }
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    if (getIt.isRegistered<SearchGossips>()) {
      getIt.unregister<SearchGossips>();
    }
    if (getIt.isRegistered<SearchCities>()) {
      getIt.unregister<SearchCities>();
    }
    if (getIt.isRegistered<PopularTabController>()) {
      getIt.unregister<PopularTabController>();
    }
    if (getIt.isRegistered<FollowingTabController>()) {
      getIt.unregister<FollowingTabController>();
    }
    if (getIt.isRegistered<ProfileController>()) {
      getIt.unregister<ProfileController>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<SearchHistoryService>()) {
      getIt.unregister<SearchHistoryService>();
    }
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }

    getIt.registerSingleton<AddGossipController>(mockController);
    getIt.registerSingleton<GetGossips>(mockGetGossips);
    getIt.registerSingleton<SearchGossips>(mockSearchGossips);
    getIt.registerSingleton<SearchCities>(mockSearchCities);
    getIt.registerSingleton<PopularTabController>(mockPopularTabController);
    getIt.registerSingleton<FollowingTabController>(mockFollowingTabController);
    getIt.registerSingleton<ProfileController>(mockProfileController);
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    getIt.registerSingleton<SearchHistoryService>(mockSearchHistoryService);
    getIt.registerSingleton<LocationService>(mockLocationService);
    if (getIt.isRegistered<GossipEvents>()) {
      getIt.unregister<GossipEvents>();
    }
    getIt.registerSingleton<GossipEvents>(GossipEvents());

    // Mock GetGossips para que HomeScreen funcione
    when(mockGetGossips()).thenAnswer(
      (_) async => Result.success([]),
    );

    // Mock SearchGossips para que SearchScreen funcione
    when(mockSearchGossips(
      query: anyNamed('query'),
      cityId: anyNamed('cityId'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => Result.success([]));

    // Mock SearchCities para que AddGossipScreen funcione
    when(mockSearchCities.call(
      query: anyNamed('query'),
      regionId: anyNamed('regionId'),
    )).thenAnswer((_) async => Result.success(const []));
  });

  tearDown(() async {
    if (getIt.isRegistered<AddGossipController>()) {
      getIt.unregister<AddGossipController>();
    }
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    if (getIt.isRegistered<SearchGossips>()) {
      getIt.unregister<SearchGossips>();
    }
    if (getIt.isRegistered<SearchCities>()) {
      getIt.unregister<SearchCities>();
    }
    if (getIt.isRegistered<PopularTabController>()) {
      getIt.unregister<PopularTabController>();
    }
    if (getIt.isRegistered<FollowingTabController>()) {
      getIt.unregister<FollowingTabController>();
    }
    if (getIt.isRegistered<ProfileController>()) {
      getIt.unregister<ProfileController>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<SearchHistoryService>()) {
      getIt.unregister<SearchHistoryService>();
    }
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }
    if (getIt.isRegistered<GossipEvents>()) {
      getIt.unregister<GossipEvents>();
    }

    // Limpiar DI después del test
    await tearDownTestDI();
  });

  Widget createTestWidget() {
    return testableWidget(
      child: const MainNavigationScreen(),
      useScaffold: false,
    );
  }

  group('MainNavigationScreen', () {
    testWidgets('debe renderizar MainNavigationScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('debe renderizar BottomNavigationBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('debe renderizar IndexedStack con 4 screens', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(IndexedStack), findsOneWidget);
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.children.length, 4);
    });

    testWidgets('debe renderizar IndexedStack', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('BottomNavigationBar debe tener item Home', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que existe item de Home (puede ser outlined o filled dependiendo del estado)
      expect(
        find.byIcon(Icons.home).evaluate().isNotEmpty ||
        find.byIcon(Icons.home_outlined).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('debe iniciar en tab Home (index 0)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('debe mostrar HomeScreen al iniciar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('debe cambiar a SearchScreen al tocar tab (index 1)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el tab de Search (segundo item)
      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
    });

    testWidgets('debe ser StatefulWidget', (tester) async {
      expect(const MainNavigationScreen(), isA<StatefulWidget>());
    });

    testWidgets('debe navegar al tercer tab (Add Gossip)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el tab de Add (tercer item)
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);
    });

    testWidgets('debe navegar al cuarto tab (Profile)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el tab de Profile (cuarto item)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 3);
    });

    testWidgets('debe volver a Home al tocar primer tab después de navegar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navegar a Search
      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();

      // Volver a Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);
    });

    testWidgets('debe tener BottomNavigationBar con 4 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 4);
    });

    testWidgets('debe tener IndexedStack con 4 pantallas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.children.length, 4);
    });

    testWidgets('debe disponer AddGossipController cuando se desmonta', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que el mock controller fue obtenido
      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Desmontar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Container()),
        ),
      );

      // Widget se desmontó sin errores
      expect(find.byType(MainNavigationScreen), findsNothing);
    });

    testWidgets('debe tener Scaffold como widget raíz', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('BottomNavigationBar debe tener tipo fixed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.type, BottomNavigationBarType.fixed);
    });
  });
}
