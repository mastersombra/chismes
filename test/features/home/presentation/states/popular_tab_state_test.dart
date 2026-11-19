import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/states/popular_tab_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('PopularTabState - Constructor y defaults', () {
    test('debe crear estado inicial con defaults correctos', () {
      // Arrange & Act
      const state = PopularTabState();

      // Assert
      expect(state.status, equals(PopularTabStatus.initial));
      expect(state.gossips, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.currentCityId, isNull);
      expect(state.currentCityName, isNull);
      expect(state.lastLoadTime, isNull);
      expect(state.hasMore, isTrue);
      expect(state.nextCursor, isNull);
      expect(state.hasNewGossips, isFalse);
      expect(state.newGossipsCount, equals(0));
    });

    test('debe crear estado con valores personalizados', () {
      // Arrange
      final gossips = [
        createTestFeedGossip(id: 'gossip-1'),
        createTestFeedGossip(id: 'gossip-2'),
      ];

      final cursor = FeedCursor.popular(
        score: 75.5,
        id: 'gossip-last',
      );

      final loadTime = DateTime(2024, 1, 1);

      // Act
      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        errorMessage: 'Test error',
        currentCityId: 'city-123',
        currentCityName: 'Buenos Aires',
        lastLoadTime: loadTime,
        hasMore: false,
        nextCursor: cursor,
        hasNewGossips: true,
        newGossipsCount: 3,
      );

      // Assert
      expect(state.status, equals(PopularTabStatus.loaded));
      expect(state.gossips, hasLength(2));
      expect(state.errorMessage, equals('Test error'));
      expect(state.currentCityId, equals('city-123'));
      expect(state.currentCityName, equals('Buenos Aires'));
      expect(state.lastLoadTime, equals(loadTime));
      expect(state.hasMore, isFalse);
      expect(state.nextCursor, equals(cursor));
      expect(state.hasNewGossips, isTrue);
      expect(state.newGossipsCount, equals(3));
    });
  });

  group('PopularTabState - Getters', () {
    test('isLoading debe ser true cuando status es loading', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loading);

      // Assert
      expect(state.isLoading, isTrue);
    });

    test('isLoading debe ser true cuando status es loadingNew', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loadingNew);

      // Assert
      expect(state.isLoading, isTrue);
    });

    test('isLoading debe ser true cuando status es loadingMore', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loadingMore);

      // Assert
      expect(state.isLoading, isTrue);
    });

    test('isLoading debe ser false cuando status es loaded', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loaded);

      // Assert
      expect(state.isLoading, isFalse);
    });

    test('isLoadingInitial debe ser true cuando status es loading', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loading);

      // Assert
      expect(state.isLoadingInitial, isTrue);
    });

    test('isLoadingMore debe ser true cuando status es loadingMore', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loadingMore);

      // Assert
      expect(state.isLoadingMore, isTrue);
    });

    test('hasError debe ser true cuando status es error', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.error);

      // Assert
      expect(state.hasError, isTrue);
    });

    test('isLoaded debe ser true cuando status es loaded', () {
      // Arrange
      const state = PopularTabState(status: PopularTabStatus.loaded);

      // Assert
      expect(state.isLoaded, isTrue);
    });

    test('isEmpty debe ser true cuando gossips está vacío', () {
      // Arrange
      const state = PopularTabState(gossips: []);

      // Assert
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty debe ser false cuando hay gossips', () {
      // Arrange
      final gossips = [createTestFeedGossip()];
      final state = PopularTabState(gossips: gossips);

      // Assert
      expect(state.isEmpty, isFalse);
    });

    test('locationHeaderText debe retornar "Popular 🌎" cuando no hay ciudad',
        () {
      // Arrange
      const state = PopularTabState();

      // Assert
      expect(state.locationHeaderText, equals('Popular 🌎'));
    });

    test('locationHeaderText debe incluir nombre de ciudad cuando está presente',
        () {
      // Arrange
      const state = PopularTabState(currentCityName: 'Buenos Aires');

      // Assert
      expect(state.locationHeaderText, equals('Popular en Buenos Aires'));
      expect(state.locationHeaderText, contains('Buenos Aires'));
    });
  });

  group('PopularTabState - copyWith', () {
    test('debe copiar estado con cambios parciales', () {
      // Arrange
      const originalState = PopularTabState(
        status: PopularTabStatus.loading,
        currentCityName: 'Original City',
        hasMore: true,
      );

      // Act
      final newState = originalState.copyWith(
        status: PopularTabStatus.loaded,
        currentCityName: 'New City',
      );

      // Assert
      expect(newState.status, equals(PopularTabStatus.loaded));
      expect(newState.currentCityName, equals('New City'));
      expect(newState.hasMore, isTrue); // No cambió
    });

    test('debe copiar estado sin cambios si no se pasan parámetros', () {
      // Arrange
      const originalState = PopularTabState(
        status: PopularTabStatus.loaded,
        currentCityName: 'Test City',
      );

      // Act
      final newState = originalState.copyWith();

      // Assert
      expect(newState.status, equals(originalState.status));
      expect(newState.currentCityName, equals(originalState.currentCityName));
    });

    test('debe copiar listas correctamente', () {
      // Arrange
      final gossips1 = [createTestFeedGossip(id: 'gossip-1')];
      final gossips2 = [createTestFeedGossip(id: 'gossip-2')];

      final originalState = PopularTabState(gossips: gossips1);

      // Act
      final newState = originalState.copyWith(gossips: gossips2);

      // Assert
      expect(newState.gossips, equals(gossips2));
      expect(newState.gossips, isNot(equals(gossips1)));
    });

    test('debe copiar DateTime correctamente', () {
      // Arrange
      final time1 = DateTime(2024, 1, 1);
      final time2 = DateTime(2024, 1, 2);

      final originalState = PopularTabState(lastLoadTime: time1);

      // Act
      final newState = originalState.copyWith(lastLoadTime: time2);

      // Assert
      expect(newState.lastLoadTime, equals(time2));
      expect(newState.lastLoadTime, isNot(equals(time1)));
    });
  });

  group('PopularTabState - copyWithNullable', () {
    test('debe limpiar errorMessage cuando clearError es true', () {
      // Arrange
      const originalState = PopularTabState(
        errorMessage: 'Test error',
      );

      // Act
      final newState = originalState.copyWithNullable(clearError: true);

      // Assert
      expect(newState.errorMessage, isNull);
    });

    test('debe mantener errorMessage cuando clearError es false', () {
      // Arrange
      const originalState = PopularTabState(
        errorMessage: 'Test error',
      );

      // Act
      final newState = originalState.copyWithNullable(clearError: false);

      // Assert
      expect(newState.errorMessage, equals('Test error'));
    });

    test('debe limpiar nextCursor cuando clearCursor es true', () {
      // Arrange
      final cursor = FeedCursor.popular(
        score: 75.5,
        id: 'gossip-last',
      );
      final originalState = PopularTabState(nextCursor: cursor);

      // Act
      final newState = originalState.copyWithNullable(clearCursor: true);

      // Assert
      expect(newState.nextCursor, isNull);
    });

    test('debe mantener nextCursor cuando clearCursor es false', () {
      // Arrange
      final cursor = FeedCursor.popular(
        score: 75.5,
        id: 'gossip-last',
      );
      final originalState = PopularTabState(nextCursor: cursor);

      // Act
      final newState = originalState.copyWithNullable(clearCursor: false);

      // Assert
      expect(newState.nextCursor, equals(cursor));
    });
  });

  group('PopularTabState - Equatable', () {
    test('debe ser igual cuando todos los campos son iguales', () {
      // Arrange
      const state1 = PopularTabState(
        status: PopularTabStatus.loaded,
        currentCityName: 'Test City',
      );
      const state2 = PopularTabState(
        status: PopularTabStatus.loaded,
        currentCityName: 'Test City',
      );

      // Assert
      expect(state1, equals(state2));
    });

    test('debe ser diferente cuando status es diferente', () {
      // Arrange
      const state1 = PopularTabState(status: PopularTabStatus.loaded);
      const state2 = PopularTabState(status: PopularTabStatus.loading);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('debe ser diferente cuando currentCityName es diferente', () {
      // Arrange
      const state1 = PopularTabState(currentCityName: 'City A');
      const state2 = PopularTabState(currentCityName: 'City B');

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('debe ser diferente cuando gossips es diferente', () {
      // Arrange
      final gossips1 = [createTestFeedGossip(id: 'gossip-1')];
      final gossips2 = [createTestFeedGossip(id: 'gossip-2')];

      final state1 = PopularTabState(gossips: gossips1);
      final state2 = PopularTabState(gossips: gossips2);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('debe ser diferente cuando hasNewGossips es diferente', () {
      // Arrange
      const state1 = PopularTabState(hasNewGossips: true);
      const state2 = PopularTabState(hasNewGossips: false);

      // Assert
      expect(state1, isNot(equals(state2)));
    });
  });

  group('PopularTabState - toString', () {
    test('debe retornar string con información relevante', () {
      // Arrange
      final gossips = [
        createTestFeedGossip(id: 'gossip-1'),
        createTestFeedGossip(id: 'gossip-2'),
      ];

      final state = PopularTabState(
        status: PopularTabStatus.loaded,
        gossips: gossips,
        hasMore: true,
        hasNewGossips: true,
      );

      // Act
      final stringValue = state.toString();

      // Assert
      expect(stringValue, contains('PopularTabState'));
      expect(stringValue, contains('status: PopularTabStatus.loaded'));
      expect(stringValue, contains('gossips: 2'));
      expect(stringValue, contains('hasMore: true'));
      expect(stringValue, contains('hasNewGossips: true'));
    });
  });
}
