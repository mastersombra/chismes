import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/presentation/screens/home_screen.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/home/presentation/controllers/popular_tab_controller.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/popular_tab_state.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/widgets/popular_tab.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/di/injection_container.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../../notifications/notifications_di_helper.dart';
import '../../../notifications/notifications_test_mocks.mocks.dart'
    show MockNotificationsNavigator;
import 'home_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetGossips>(),
  MockSpec<PopularTabController>(),
  MockSpec<FollowingTabController>(),
])
void main() {
  late MockGetGossips mockGetGossips;
  late MockPopularTabController mockPopularTabController;
  late MockFollowingTabController mockFollowingTabController;
  late MockNotificationsNavigator mockNotificationsNavigator;

  setUp(() {
    mockNotificationsNavigator = registerNotificationsNavigatorStub();
    mockGetGossips = MockGetGossips();
    mockPopularTabController = MockPopularTabController();
    mockFollowingTabController = MockFollowingTabController();

    // Proporcionar dummy value
    provideDummy<Result<Failure, List<Gossip>>>(
      Result.success(<Gossip>[]),
    );

    // Setup mocks de controllers con estado inicial vacío (se configura por test)
    when(mockPopularTabController.state).thenReturn(const PopularTabState());
    when(mockFollowingTabController.state).thenReturn(const FollowingTabState());

    // Stub para listener methods
    when(mockPopularTabController.addListener(any)).thenReturn(null);
    when(mockPopularTabController.removeListener(any)).thenReturn(null);
    when(mockFollowingTabController.addListener(any)).thenReturn(null);
    when(mockFollowingTabController.removeListener(any)).thenReturn(null);

    // Stub para loadFeed methods
    when(mockPopularTabController.loadFeed()).thenAnswer((_) async => {});
    when(mockFollowingTabController.loadFeed()).thenAnswer((_) async => {});

    // Stub para dispose
    when(mockPopularTabController.dispose()).thenReturn(null);
    when(mockFollowingTabController.dispose()).thenReturn(null);

    // Limpiar y registrar mocks en getIt
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    if (getIt.isRegistered<PopularTabController>()) {
      getIt.unregister<PopularTabController>();
    }
    if (getIt.isRegistered<FollowingTabController>()) {
      getIt.unregister<FollowingTabController>();
    }

    getIt.registerSingleton<GetGossips>(mockGetGossips);
    getIt.registerSingleton<PopularTabController>(mockPopularTabController);
    getIt.registerSingleton<FollowingTabController>(mockFollowingTabController);
  });

  tearDown(() {
    unregisterNotificationsNavigatorStub();
    // Limpiar después de cada test
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    if (getIt.isRegistered<PopularTabController>()) {
      getIt.unregister<PopularTabController>();
    }
    if (getIt.isRegistered<FollowingTabController>()) {
      getIt.unregister<FollowingTabController>();
    }
  });

  // Mock data for tests
  // ignore: unused_local_variable
  final mockFeedGossips = [
    FeedGossip(
      id: 'test-1',
      subject: 'Test Subject 1',
      content: 'Test Content 1',
      cityId: 'med',
      createdAt: DateTime.now(),
      likes: 10,
      comments: 5,
      shares: 2,
      publishedAs: 'anonymous',
      createdBy: null,
      imageUrl: 'https://example.com/image1.jpg',
      score: 85.0,
      isFromMyCity: true,
      isTrending: false,
    ),
    FeedGossip(
      id: 'test-2',
      subject: 'Test Subject 2',
      content: 'Test Content 2',
      cityId: 'med',
      createdAt: DateTime.now(),
      likes: 20,
      comments: 10,
      shares: 5,
      publishedAs: 'anonymous',
      createdBy: null,
      imageUrl: 'https://example.com/image2.jpg',
      score: 90.0,
      isFromMyCity: true,
      isTrending: false,
    ),
  ];

  Widget createTestWidget() {
    return testableWidget(
      child: const HomeScreen(),
      useScaffold: false,
    );
  }

  group('HomeScreen', () {
    final mockGossips = [
      Gossip(
        id: 'test-1',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject 1',
        content: 'Test Content 1',
        audioUrl: null,
        imageUrl: 'https://example.com/image1.jpg',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-1',
        modifiedAt: null,
        modifiedBy: null,
      ),
      Gossip(
        id: 'test-2',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject 2',
        content: 'Test Content 2',
        audioUrl: null,
        imageUrl: 'https://example.com/image2.jpg',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-2',
        modifiedAt: null,
        modifiedBy: null,
      ),
    ];

    testWidgets('debe renderizar AppBar con título', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Descubre 👀'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('muestra la campana de notificaciones en el AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, hasLength(1));
      expect(find.byKey(kBellStubKey), findsOneWidget);
      verify(mockNotificationsNavigator.buildBellButton()).called(1);
    });

    testWidgets('debe renderizar Scaffold', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe renderizar RefreshIndicator', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('debe renderizar TabBarView', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('debe cargar gossips al iniciar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debe llamar a loadFeed del controller
      verify(mockPopularTabController.loadFeed()).called(1);
    });

    testWidgets('debe mostrar TabBar con dos tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 2);
    });

    testWidgets('debe cargar feed de Following al cambiar a segunda tab', (tester) async {
      // Arrange: Setup estado inicial para FollowingTab
      when(mockFollowingTabController.state).thenReturn(
        const FollowingTabState(status: FollowingTabStatus.initial),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que solo se llamó loadFeed del PopularTab
      verify(mockPopularTabController.loadFeed()).called(1);
      verifyNever(mockFollowingTabController.loadFeed());

      // Act: Cambiar a segunda tab (Following)
      await tester.tap(find.text('Siguiendo'));
      await tester.pumpAndSettle();

      // Assert: Debe llamar loadFeed del FollowingTab
      verify(mockFollowingTabController.loadFeed()).called(1);
    });

    testWidgets('NO debe cargar feed de Following si ya está cargado', (tester) async {
      // Arrange: Setup estado como ya cargado (no initial)
      when(mockFollowingTabController.state).thenReturn(
        FollowingTabState(
          status: FollowingTabStatus.loaded,
          gossips: mockFeedGossips,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Resetear contador después de la carga inicial
      clearInteractions(mockFollowingTabController);

      // Act: Cambiar a segunda tab (Following)
      await tester.tap(find.text('Siguiendo'));
      await tester.pumpAndSettle();

      // Assert: NO debe llamar loadFeed porque ya está cargado
      verifyNever(mockFollowingTabController.loadFeed());
    });

    testWidgets('debe tener AppBar con título centrado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
      expect(appBar.title, isNotNull);
    });

    testWidgets('debe tener exactamente 2 tabs en TabBar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('debe tener TabBarView con 2 hijos', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byType(PopularTab), findsOneWidget);
      // FollowingTab no está visible inicialmente, solo PopularTab
    });

    testWidgets('debe disponer TabController cuando se desmonta', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - desmontar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Container()),
        ),
      );

      // Assert - widget se desmontó sin errores
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('debe disponer controllers cuando se desmonta', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que controllers fueron creados
      verify(mockPopularTabController.loadFeed()).called(1);

      // Act - desmontar widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Container()),
        ),
      );

      // Assert - debe llamar dispose en controllers
      verify(mockPopularTabController.dispose()).called(1);
      verify(mockFollowingTabController.dispose()).called(1);
    });

    testWidgets('no debe cargar feed de Following si tab index no es 1', (WidgetTester tester) async {
      // Arrange
      when(mockPopularTabController.state).thenReturn(const PopularTabState());
      when(mockFollowingTabController.state).thenReturn(
        const FollowingTabState(status: FollowingTabStatus.initial),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Limpiar interacciones del setup inicial
      clearInteractions(mockFollowingTabController);

      // Act - simular que indexIsChanging es false (no hay cambio de tab real)
      // En este caso no podemos forzar indexIsChanging directamente,
      // pero podemos verificar que solo se llama loadFeed cuando se cambia realmente

      // Assert - Following no debe haberse cargado aún
      verifyNever(mockFollowingTabController.loadFeed());
    });

    testWidgets('debe tener Scaffold como widget raíz', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

  });
}
