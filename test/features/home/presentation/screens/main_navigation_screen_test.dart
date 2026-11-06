import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:chismes/features/home/presentation/screens/home_screen.dart';
import 'package:chismes/features/search/presentation/screens/search_screen.dart';
import 'package:chismes/features/gossip/presentation/controllers/add_gossip_controller.dart';
import 'package:chismes/features/gossip/presentation/screens/add_gossip_screen.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/location/domain/usecases/search_cities.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/home/presentation/controllers/popular_tab_controller.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
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
  MockSpec<PopularTabController>(),
  MockSpec<FollowingTabController>(),
  MockSpec<ProfileController>(),
  MockSpec<AuthRepository>(),
])
void main() {
  late MockAddGossipController mockController;
  late MockGetGossips mockGetGossips;
  late MockSearchCities mockSearchCities;
  late MockPopularTabController mockPopularTabController;
  late MockFollowingTabController mockFollowingTabController;
  late MockProfileController mockProfileController;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockController = MockAddGossipController();
    mockGetGossips = MockGetGossips();
    mockSearchCities = MockSearchCities();
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

    // Setup controller con helper
    setupMockAddGossipController(mockController);

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

    testWidgets('debe renderizar FloatingActionButton', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('debe renderizar IndexedStack', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('BottomNavigationBar debe tener 2 items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 2);
    });

    testWidgets('BottomNavigationBar debe tener item Inicio', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('BottomNavigationBar debe tener item Buscar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Buscar'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('FloatingActionButton debe tener texto Crear Chisme', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Crear Chisme'), findsOneWidget);
    });

    testWidgets('FloatingActionButton debe tener texto y icono', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que tiene texto
      expect(find.text('Crear Chisme'), findsOneWidget);

      // Verificar que tiene icono add
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('debe iniciar en tab Inicio (index 0)', (tester) async {
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

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('debe cambiar a SearchScreen al tocar tab Buscar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap en Buscar
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      // Verificar que SearchScreen está visible
      expect(find.byType(SearchScreen), findsOneWidget);

      // Verificar índice actualizado
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 1);
    });

    testWidgets('debe cambiar de SearchScreen a HomeScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ir a Buscar
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);

      // Volver a Inicio
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('IndexedStack debe contener ambas pantallas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.children.length, 2);
    });

    testWidgets('IndexedStack index debe coincidir con currentIndex', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Index inicial
      var indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 0);

      // Cambiar tab
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 1);
    });

    testWidgets('FloatingActionButton debe existir', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que el FAB existe
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('debe ser StatefulWidget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      final widget = tester.widget(find.byType(MainNavigationScreen));
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('debe mantener estado al cambiar entre tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ir a Buscar
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      // Volver a Inicio
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      // Debe seguir funcionando sin errores
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('BottomNavigationBar debe tener onTap configurado', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.onTap, isNotNull);
    });


    testWidgets('debe existir método dispose', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Dispose del widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // El widget debe haberse dispuesto sin errores
      expect(find.byType(MainNavigationScreen), findsNothing);
    });

    testWidgets('FloatingActionButton debe mostrar texto e icono', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que el FAB contiene tanto texto como icono
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      expect(
        find.descendant(
          of: fabFinder,
          matching: find.text('Crear Chisme'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: fabFinder,
          matching: find.byIcon(Icons.add),
        ),
        findsOneWidget,
      );
    });

    testWidgets('debe contener icono add en FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Buscar el icono add dentro del FAB
      final addIcon = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.add),
      );
      expect(addIcon, findsOneWidget);
    });

    testWidgets('screens debe ser una lista constante', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // La lista de screens debe contener exactamente 2 elementos
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.children.length, 2);
      expect(indexedStack.children[0], isA<HomeScreen>());
      expect(indexedStack.children[1], isA<SearchScreen>());
    });

    testWidgets('debe inicializar controller en initState', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El widget debe estar renderizado sin errores
      // Lo cual implica que el controller fue inicializado correctamente
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('currentIndex inicial debe ser 0', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 0);
    });

    testWidgets('ambos tabs deben ser accesibles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tab 0 (Inicio)
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tab 1 (Buscar)
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('debe tener componentes principales', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que los componentes principales existen
      expect(find.byType(IndexedStack), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('debe navegar a AddGossipScreen al tocar FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificar que se abrió AddGossipScreen
      expect(find.byType(AddGossipScreen), findsOneWidget);
    });

    testWidgets('debe mostrar snackbar de éxito cuando se crea gossip published', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simular retornar un gossip published
      final gossip = Gossip(
        id: '1',
        countryId: 'country1',
        regionId: 'region1',
        cityId: 'city1',
        subject: 'Test',
        content: 'Body',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user1',
      );

      // Volver hacia atrás con el gossip
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(gossip);
      await tester.pumpAndSettle();

      // Verificar que se mostró el snackbar correcto
      expect(find.text('✅ Chisme publicado exitosamente'), findsOneWidget);

      // Verificar que se cambió a tab Home (index 0)
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('debe mostrar snackbar de revisión cuando se crea gossip no published', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simular retornar un gossip en revisión
      final gossip = Gossip(
        id: '1',
        countryId: 'country1',
        regionId: 'region1',
        cityId: 'city1',
        subject: 'Test',
        content: 'Body',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.draft,
        moderationStatus: ModerationStatus.pending,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user1',
      );

      // Volver hacia atrás con el gossip
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(gossip);
      await tester.pumpAndSettle();

      // Verificar que se mostró el snackbar correcto
      expect(find.text('⚠️ Chisme en revisión'), findsOneWidget);

      // Verificar que se cambió a tab Home (index 0)
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('no debe mostrar snackbar cuando se cancela creación de gossip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Cambiar a tab Buscar primero
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      final bottomNavBefore = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBefore.currentIndex, 1);

      // Tocar el FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Volver hacia atrás sin gossip (cancelar)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(null);
      await tester.pumpAndSettle();

      // Verificar que NO se mostró snackbar
      expect(find.text('✅ Chisme publicado exitosamente'), findsNothing);
      expect(find.text('⚠️ Chisme en revisión'), findsNothing);

      // Verificar que NO se cambió de tab (sigue en Buscar, index 1)
      final bottomNavAfter = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavAfter.currentIndex, 1);
    });

    testWidgets('debe pasar controller a AddGossipScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar el FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificar que AddGossipScreen recibió el controller
      final addGossipScreen = tester.widget<AddGossipScreen>(
        find.byType(AddGossipScreen),
      );
      expect(addGossipScreen.controller, isNotNull);
      expect(addGossipScreen.controller, mockController);
    });
  });
}
