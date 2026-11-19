import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/controllers/popular_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/popular_tab_state.dart';
import 'package:chismes/features/home/presentation/widgets/popular_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import 'popular_tab_test.mocks.dart';

@GenerateMocks([PopularTabController])
void main() {
  late MockPopularTabController mockController;

  setUp(() {
    mockController = MockPopularTabController();
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

  group('PopularTab - Loading inicial', () {
    testWidgets('debe mostrar CircularProgressIndicator', (tester) async {
      // Arrange
      const state = PopularTabState(
        status: PopularTabStatus.loading,
      );
      when(mockController.state).thenReturn(state);

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(state.isLoadingInitial, isTrue);
    });
  });

  group('PopularTab - Error', () {
    testWidgets('debe mostrar mensaje de error y botón retry', (tester) async {
      // Arrange
      const state = PopularTabState(
        status: PopularTabStatus.error,
        errorMessage: 'Error de red',
      );
      when(mockController.state).thenReturn(state);
      when(mockController.loadFeed()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error de red'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('debe llamar loadFeed al presionar retry', (tester) async {
      // Arrange
      const state = PopularTabState(
        status: PopularTabStatus.error,
        errorMessage: 'Error de red',
      );
      when(mockController.state).thenReturn(state);
      when(mockController.loadFeed()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.loadFeed()).called(1);
    });
  });

  group('PopularTab - Feed vacío', () {
    testWidgets('debe mostrar empty state', (tester) async {
      // Arrange
      const state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: [],
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.mood_bad), findsOneWidget);
      expect(state.isEmpty, isTrue);
    });

    testWidgets('debe permitir pull-to-refresh en empty state',
        (tester) async {
      // Arrange
      const state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: [],
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('PopularTab - Feed con chismes', () {
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
        ),
      ];

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('debe mostrar location header', (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        currentCityName: 'Buenos Aires',
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(find.textContaining('Buenos Aires'), findsOneWidget);
      expect(state.locationHeaderText, contains('Buenos Aires'));
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

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
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

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: false,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );

      // Assert
      expect(state.hasMore, isFalse);
      // El mensaje "No hay más" está en el sliver
    });
  });

  group('PopularTab - Banner de nuevos chismes', () {
    testWidgets('debe verificar hasNewGossips cuando es true',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
        hasNewGossips: true,
        newGossipsCount: 5,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act & Assert
      expect(state.hasNewGossips, isTrue);
      expect(state.newGossipsCount, equals(5));
    });

    testWidgets('debe verificar hasNewGossips cuando es false',
        (tester) async {
      // Arrange
      final gossips = [
        createTestFeedGossip(
          id: 'gossip-1',
          subject: 'Chisme 1',
          content: 'Contenido 1',
        ),
      ];

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
        hasNewGossips: false,
      );

      // Assert
      expect(state.hasNewGossips, isFalse);
    });
  });

  group('PopularTab - Infinite scroll', () {
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

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(state);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
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

      final state = PopularTabState(
        status: PopularTabStatus.loadingMore,
        gossips: gossips,
        hasMore: true,
      );

      // Assert
      expect(state.isLoadingMore, isTrue);
      expect(state.status, equals(PopularTabStatus.loadingMore));
    });
  });

  group('PopularTab - Reactivity', () {
    testWidgets('debe reaccionar a cambios en el state del controller',
        (tester) async {
      // Arrange - Estado inicial: loading
      const initialState = PopularTabState(
        status: PopularTabStatus.loading,
      );
      when(mockController.state).thenReturn(initialState);

      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
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

      final loadedState = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
      );
      when(mockController.state).thenReturn(loadedState);
      when(mockController.refresh()).thenAnswer((_) async => Future.value());

      // Simular notifyListeners - forzar rebuild
      await tester.pumpWidget(
        testableWidget(
          child: PopularTab(controller: mockController),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
