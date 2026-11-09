import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:chismes/features/home/presentation/screens/home_screen.dart';
import 'package:chismes/features/gossip/presentation/controllers/add_gossip_controller.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
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

import '../../../../helpers/mock_add_gossip_controller_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'main_navigation_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AddGossipController>(),
  MockSpec<GetGossips>(),
  MockSpec<SearchCities>(),
  MockSpec<LocationManager>(),
  MockSpec<PopularTabController>(),
  MockSpec<FollowingTabController>(),
  MockSpec<ProfileController>(),
  MockSpec<AuthRepository>(),
])
void main() {
  late MockAddGossipController mockController;
  late MockGetGossips mockGetGossips;
  late MockSearchCities mockSearchCities;
  late MockLocationManager mockLocationManager;
  late MockPopularTabController mockPopularTabController;
  late MockFollowingTabController mockFollowingTabController;
  late MockProfileController mockProfileController;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockController = MockAddGossipController();
    mockGetGossips = MockGetGossips();
    mockSearchCities = MockSearchCities();
    mockLocationManager = MockLocationManager();
    mockPopularTabController = MockPopularTabController();
    mockFollowingTabController = MockFollowingTabController();
    mockProfileController = MockProfileController();
    mockAuthRepository = MockAuthRepository();

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

    // Registrar mocks en getIt
    if (getIt.isRegistered<AddGossipController>()) {
      getIt.unregister<AddGossipController>();
    }
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
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

    getIt.registerSingleton<AddGossipController>(mockController);
    getIt.registerSingleton<GetGossips>(mockGetGossips);
    getIt.registerSingleton<SearchCities>(mockSearchCities);
    getIt.registerSingleton<PopularTabController>(mockPopularTabController);
    getIt.registerSingleton<FollowingTabController>(mockFollowingTabController);
    getIt.registerSingleton<ProfileController>(mockProfileController);
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);

    // Mock GetGossips para que HomeScreen funcione
    when(mockGetGossips()).thenAnswer(
      (_) async => Result.success([]),
    );

    // Mock SearchCities para que AddGossipScreen funcione
    when(mockSearchCities.call(
      query: anyNamed('query'),
      regionId: anyNamed('regionId'),
    )).thenAnswer((_) async => Result.success(const []));
  });

  tearDown(() {
    if (getIt.isRegistered<AddGossipController>()) {
      getIt.unregister<AddGossipController>();
    }
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
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
  });
}
