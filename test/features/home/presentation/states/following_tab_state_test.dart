import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
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

  group('FollowingTabState - Constructor y defaults', () {
    test('debe crear estado inicial con defaults correctos', () {
      // Arrange & Act
      const state = FollowingTabState();

      // Assert
      expect(state.status, equals(FollowingTabStatus.initial));
      expect(state.gossips, isEmpty);
      expect(state.recommendedGossips, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.followingCount, equals(0));
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

      final recommendedGossips = [
        createTestFeedGossip(id: 'gossip-3'),
      ];

      final cursor = FeedCursor.following(
        createdAt: DateTime(2024, 1, 1),
        id: 'gossip-last',
      );

      // Act
      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        recommendedGossips: recommendedGossips,
        errorMessage: 'Test error',
        followingCount: 5,
        hasMore: false,
        nextCursor: cursor,
        hasNewGossips: true,
        newGossipsCount: 3,
      );

      // Assert
      expect(state.status, equals(FollowingTabStatus.loaded));
      expect(state.gossips, hasLength(2));
      expect(state.recommendedGossips, hasLength(1));
      expect(state.errorMessage, equals('Test error'));
      expect(state.followingCount, equals(5));
      expect(state.hasMore, isFalse);
      expect(state.nextCursor, equals(cursor));
      expect(state.hasNewGossips, isTrue);
      expect(state.newGossipsCount, equals(3));
    });
  });

  group('FollowingTabState - Getters', () {
    test('isLoading debe ser true cuando status es loading', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.loading);

      // Assert
      expect(state.isLoading, isTrue);
    });

    test('isLoading debe ser true cuando status es loadingMore', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.loadingMore);

      // Assert
      expect(state.isLoading, isTrue);
    });

    test('isLoading debe ser false cuando status es loaded', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.loaded);

      // Assert
      expect(state.isLoading, isFalse);
    });

    test('isLoadingInitial debe ser true cuando status es loading', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.loading);

      // Assert
      expect(state.isLoadingInitial, isTrue);
    });

    test('isLoadingMore debe ser true cuando status es loadingMore', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.loadingMore);

      // Assert
      expect(state.isLoadingMore, isTrue);
    });

    test('hasError debe ser true cuando status es error', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.error);

      // Assert
      expect(state.hasError, isTrue);
    });

    test('isShowingFollowing debe ser true cuando status es loaded', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.loaded);

      // Assert
      expect(state.isShowingFollowing, isTrue);
    });

    test('isShowingRecommended debe ser true cuando status es loadedRecommended',
        () {
      // Arrange
      const state =
          FollowingTabState(status: FollowingTabStatus.loadedRecommended);

      // Assert
      expect(state.isShowingRecommended, isTrue);
    });

    test('isNotFollowing debe ser true cuando status es notFollowing', () {
      // Arrange
      const state = FollowingTabState(status: FollowingTabStatus.notFollowing);

      // Assert
      expect(state.isNotFollowing, isTrue);
    });

    test('isEmpty debe ser true cuando no hay gossips ni recommended', () {
      // Arrange
      const state = FollowingTabState(
        gossips: [],
        recommendedGossips: [],
      );

      // Assert
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty debe ser false cuando hay gossips', () {
      // Arrange
      final gossips = [createTestFeedGossip()];
      final state = FollowingTabState(gossips: gossips);

      // Assert
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty debe ser false cuando hay recommendedGossips', () {
      // Arrange
      final recommendedGossips = [createTestFeedGossip()];
      final state =
          FollowingTabState(recommendedGossips: recommendedGossips);

      // Assert
      expect(state.isEmpty, isFalse);
    });

    test('activeList debe retornar gossips cuando status es loaded', () {
      // Arrange
      final gossips = [
        createTestFeedGossip(id: 'gossip-1'),
        createTestFeedGossip(id: 'gossip-2'),
      ];
      final recommendedGossips = [
        createTestFeedGossip(id: 'gossip-3'),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        recommendedGossips: recommendedGossips,
      );

      // Assert
      expect(state.activeList, equals(gossips));
      expect(state.activeList, hasLength(2));
    });

    test(
        'activeList debe retornar recommendedGossips cuando status es loadedRecommended',
        () {
      // Arrange
      final gossips = [
        createTestFeedGossip(id: 'gossip-1'),
      ];
      final recommendedGossips = [
        createTestFeedGossip(id: 'gossip-2'),
        createTestFeedGossip(id: 'gossip-3'),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loadedRecommended,
        gossips: gossips,
        recommendedGossips: recommendedGossips,
      );

      // Assert
      expect(state.activeList, equals(recommendedGossips));
      expect(state.activeList, hasLength(2));
    });
  });

  group('FollowingTabState - copyWith', () {
    test('debe copiar estado con cambios parciales', () {
      // Arrange
      const originalState = FollowingTabState(
        status: FollowingTabStatus.loading,
        followingCount: 5,
        hasMore: true,
      );

      // Act
      final newState = originalState.copyWith(
        status: FollowingTabStatus.loaded,
        followingCount: 10,
      );

      // Assert
      expect(newState.status, equals(FollowingTabStatus.loaded));
      expect(newState.followingCount, equals(10));
      expect(newState.hasMore, isTrue); // No cambió
    });

    test('debe copiar estado sin cambios si no se pasan parámetros', () {
      // Arrange
      const originalState = FollowingTabState(
        status: FollowingTabStatus.loaded,
        followingCount: 5,
      );

      // Act
      final newState = originalState.copyWith();

      // Assert
      expect(newState.status, equals(originalState.status));
      expect(newState.followingCount, equals(originalState.followingCount));
    });

    test('debe copiar listas correctamente', () {
      // Arrange
      final gossips1 = [createTestFeedGossip(id: 'gossip-1')];
      final gossips2 = [createTestFeedGossip(id: 'gossip-2')];

      final originalState = FollowingTabState(gossips: gossips1);

      // Act
      final newState = originalState.copyWith(gossips: gossips2);

      // Assert
      expect(newState.gossips, equals(gossips2));
      expect(newState.gossips, isNot(equals(gossips1)));
    });
  });

  group('FollowingTabState - copyWithNullable', () {
    test('debe limpiar errorMessage cuando clearError es true', () {
      // Arrange
      const originalState = FollowingTabState(
        errorMessage: 'Test error',
      );

      // Act
      final newState = originalState.copyWithNullable(clearError: true);

      // Assert
      expect(newState.errorMessage, isNull);
    });

    test('debe mantener errorMessage cuando clearError es false', () {
      // Arrange
      const originalState = FollowingTabState(
        errorMessage: 'Test error',
      );

      // Act
      final newState = originalState.copyWithNullable(clearError: false);

      // Assert
      expect(newState.errorMessage, equals('Test error'));
    });

    test('debe limpiar nextCursor cuando clearCursor es true', () {
      // Arrange
      final cursor = FeedCursor.following(
        createdAt: DateTime(2024, 1, 1),
        id: 'gossip-last',
      );
      final originalState = FollowingTabState(nextCursor: cursor);

      // Act
      final newState = originalState.copyWithNullable(clearCursor: true);

      // Assert
      expect(newState.nextCursor, isNull);
    });

    test('debe mantener nextCursor cuando clearCursor es false', () {
      // Arrange
      final cursor = FeedCursor.following(
        createdAt: DateTime(2024, 1, 1),
        id: 'gossip-last',
      );
      final originalState = FollowingTabState(nextCursor: cursor);

      // Act
      final newState = originalState.copyWithNullable(clearCursor: false);

      // Assert
      expect(newState.nextCursor, equals(cursor));
    });
  });

  group('FollowingTabState - Equatable', () {
    test('debe ser igual cuando todos los campos son iguales', () {
      // Arrange
      const state1 = FollowingTabState(
        status: FollowingTabStatus.loaded,
        followingCount: 5,
      );
      const state2 = FollowingTabState(
        status: FollowingTabStatus.loaded,
        followingCount: 5,
      );

      // Assert
      expect(state1, equals(state2));
    });

    test('debe ser diferente cuando status es diferente', () {
      // Arrange
      const state1 = FollowingTabState(status: FollowingTabStatus.loaded);
      const state2 = FollowingTabState(status: FollowingTabStatus.loading);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('debe ser diferente cuando followingCount es diferente', () {
      // Arrange
      const state1 = FollowingTabState(followingCount: 5);
      const state2 = FollowingTabState(followingCount: 10);

      // Assert
      expect(state1, isNot(equals(state2)));
    });

    test('debe ser diferente cuando gossips es diferente', () {
      // Arrange
      final gossips1 = [createTestFeedGossip(id: 'gossip-1')];
      final gossips2 = [createTestFeedGossip(id: 'gossip-2')];

      final state1 = FollowingTabState(gossips: gossips1);
      final state2 = FollowingTabState(gossips: gossips2);

      // Assert
      expect(state1, isNot(equals(state2)));
    });
  });

  group('FollowingTabState - toString', () {
    test('debe retornar string con información relevante', () {
      // Arrange
      final gossips = [
        createTestFeedGossip(id: 'gossip-1'),
        createTestFeedGossip(id: 'gossip-2'),
      ];
      final recommendedGossips = [
        createTestFeedGossip(id: 'gossip-3'),
      ];

      final state = FollowingTabState(
        status: FollowingTabStatus.loaded,
        gossips: gossips,
        recommendedGossips: recommendedGossips,
        followingCount: 10,
      );

      // Act
      final stringValue = state.toString();

      // Assert
      expect(stringValue, contains('FollowingTabState'));
      expect(stringValue, contains('status: FollowingTabStatus.loaded'));
      expect(stringValue, contains('gossips: 2'));
      expect(stringValue, contains('recommended: 1'));
      expect(stringValue, contains('following: 10'));
    });
  });
}
