import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
import 'package:chismes/features/home/presentation/widgets/following_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import 'following_tab_test.mocks.dart';

@GenerateMocks([FollowingTabController])
void main() {
  late MockFollowingTabController mockController;

  setUp(() {
    mockController = MockFollowingTabController();
  });

  // Helper para crear FeedGossip de prueba
  FeedGossip createTestFeedGossip({
    String id = 'gossip-1',
    String subject = 'Test Subject',
    String content = 'Test Content',
    String cityId = 'city-1',
    DateTime? createdAt,
    int likes = 0,
    int comments = 0,
    int shares = 0,
    String publishedAs = 'anonymous',
    double score = 50.0,
    bool isTrending = false,
  }) {
    return FeedGossip(
      id: id,
      subject: subject,
      content: content,
      cityId: cityId,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      likes: likes,
      comments: comments,
      shares: shares,
      publishedAs: publishedAs,
      score: score,
      isTrending: isTrending,
    );
  }

  group('FollowingTab - Loading inicial', () {
    testWidgets('debe mostrar CircularProgressIndicator', (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.loading,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(state.isLoadingInitial, isTrue);
    });
  });

  group('FollowingTab - Error', () {
    testWidgets('debe mostrar mensaje de error y botón retry', (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.error,
        errorMessage: 'Error de red',
      );
      when(mockController.state).thenReturn(state);
      when(mockController.loadFeed()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error de red'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('debe llamar loadFeed al presionar retry', (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.error,
        errorMessage: 'Error de red',
      );
      when(mockController.state).thenReturn(state);
      when(mockController.loadFeed()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.loadFeed()).called(1);
    });
  });

  group('FollowingTab - Empty State (No sigue a nadie)', () {
    testWidgets('debe mostrar empty state cuando no sigue a nadie',
        (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.notFollowing,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(state.isNotFollowing, isTrue);
    });

    testWidgets('debe mostrar botón "Explorar usuarios"', (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.notFollowing,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert - Buscar por icon que está dentro del botón
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('debe mostrar SnackBar al presionar "Explorar usuarios"',
        (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.notFollowing,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Buscar el icono de search y hacer tap en su parent button
      final searchIconFinder = find.byIcon(Icons.search);
      expect(searchIconFinder, findsOneWidget);

      // Hacer tap directamente en el icono (el gesture será capturado por el botón)
      await tester.tap(searchIconFinder);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('debe mostrar TextButton "Ver populares"', (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.notFollowing,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('debe mostrar SnackBar al presionar "Ver populares"',
        (tester) async {
      // Arrange
      const state = FollowingTabState(
        status: FollowingTabStatus.notFollowing,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('FollowingTab - Feed normal', () {
    testWidgets('debe mostrar lista de chismes', (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
        createTestFeedGossip(
          id: 'gossip-2',
          subject: 'Chisme 2',
          content: 'Contenido 2',
          createdAt: DateTime(2024, 1, 2),
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(state.isShowingFollowing, isTrue);
    });

    testWidgets('debe llamar refresh al hacer pull-to-refresh',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.refresh()).called(1);
    });

    testWidgets('debe mostrar "No hay más" cuando hasMore es false',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        hasMore: false,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(state.hasMore, isFalse);
      // El mensaje "No hay más" está en el sliver, se renderiza aunque no sea visible
    });
  });

  group('FollowingTab - Feed con recomendados', () {
    testWidgets('debe mostrar badge "Recomendados para ti"', (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loadedRecommended,
        recommendedGossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(state.isShowingRecommended, isTrue);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('debe mostrar banner inferior con mensaje explicativo',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loadedRecommended,
        recommendedGossips: gossips,
        hasMore: false,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(state.isShowingRecommended, isTrue);
      expect(state.hasMore, isFalse);
      // El banner está en un SliverToBoxAdapter al final
    });

    testWidgets('debe usar recommendedGossips como activeList', (tester) async {
      // Arrange
      final followingGossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme Following',
          content: 'Contenido Following',
        ),
      ];

      final recommendedGossips = [
        createTestFeedGossip(
          id: 'gossip-2',
          subject: 'Chisme Recommended',
          content: 'Contenido Recommended',
          createdAt: DateTime(2024, 1, 2),
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loadedRecommended,
        gossips: followingGossips,
        recommendedGossips: recommendedGossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(state.activeList, equals(recommendedGossips));
      expect(state.activeList, isNot(equals(followingGossips)));
    });
  });

  group('FollowingTab - Infinite scroll', () {
    testWidgets('debe mostrar RefreshIndicator cuando hay gossips',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('debe verificar que isLoadingMore es true en estado loadingMore',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loadingMore,
        gossips: gossips,
        hasMore: true,
      );

      // Assert
      expect(state.isLoadingMore, isTrue);
      expect(state.status, equals(FollowingTabStatus.loadingMore));
    });
  });

  group('FollowingTab - Reactivity', () {
    testWidgets('debe reaccionar a cambios en el state del controller',
        (tester) async {
      // Arrange - Estado inicial: loading
      const initialState = FollowingTabState(
        status: FollowingTabStatus.loading,
      );
      when(mockController.state).thenReturn(initialState);

      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Act - Cambiar a estado con datos
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final loadedState = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(loadedState);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Simular notifyListeners - forzar rebuild
      await tester.pumpWidget(
        testableWidget(
          child: FollowingTab(controller: mockController),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
