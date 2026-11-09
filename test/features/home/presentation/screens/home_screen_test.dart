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
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/di/injection_container.dart';

import '../../../../helpers/widget_test_wrapper.dart';
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

  setUp(() {
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

  });
}
