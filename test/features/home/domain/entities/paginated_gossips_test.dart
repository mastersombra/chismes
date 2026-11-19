import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';

void main() {
  group('PaginatedGossips', () {
    // Helper para crear FeedGossip de prueba
    FeedGossip createTestGossip({
      String id = 'gossip-1',
      String subject = 'Test Subject',
      double score = 100.0,
    }) {
      return FeedGossip(
        id: id,
        subject: subject,
        content: 'Test content',
        cityId: 'city-123',
        createdAt: DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
        shares: 2,
        publishedAs: 'profile',
        createdBy: 'user-123',
        score: score,
        isFromMyCity: true,
        isTrending: false,
      );
    }

    group('Constructor', () {
      test('debe crear instancia con datos y hasMore true', () {
        // Arrange
        final gossips = [
          createTestGossip(id: 'gossip-1'),
          createTestGossip(id: 'gossip-2'),
        ];
        const cursor = FeedCursor.popular(score: 90.0, id: 'gossip-2');

        // Act
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor,
        );

        // Assert
        expect(paginated.data, gossips);
        expect(paginated.hasMore, isTrue);
        expect(paginated.nextCursor, cursor);
      });

      test('debe crear instancia con hasMore false y cursor null', () {
        // Arrange
        final gossips = [createTestGossip()];

        // Act
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        // Assert
        expect(paginated.data, gossips);
        expect(paginated.hasMore, isFalse);
        expect(paginated.nextCursor, isNull);
      });

      test('debe crear instancia vacía con constructor nombrado', () {
        // Act
        const paginated = PaginatedGossips.empty();

        // Assert
        expect(paginated.data, isEmpty);
        expect(paginated.hasMore, isFalse);
        expect(paginated.nextCursor, isNull);
      });
    });

    group('Invariantes', () {
      test('debe permitir hasMore false con cursor null', () {
        // Arrange
        final gossips = [createTestGossip()];

        // Act & Assert - No debe lanzar excepción
        expect(
          () => PaginatedGossips(
            data: gossips,
            hasMore: false,
            nextCursor: null,
          ),
          returnsNormally,
        );
      });

      test('debe permitir hasMore true con cursor no null', () {
        // Arrange
        final gossips = [createTestGossip()];
        const cursor = FeedCursor.popular(score: 100.0, id: 'gossip-1');

        // Act & Assert - No debe lanzar excepción
        expect(
          () => PaginatedGossips(
            data: gossips,
            hasMore: true,
            nextCursor: cursor,
          ),
          returnsNormally,
        );
      });
    });

    group('Getters de conveniencia', () {
      test('isEmpty debe retornar true cuando data está vacío', () {
        // Arrange
        const paginated = PaginatedGossips.empty();

        // Act & Assert
        expect(paginated.isEmpty, isTrue);
        expect(paginated.isNotEmpty, isFalse);
      });

      test('isEmpty debe retornar false cuando data tiene elementos', () {
        // Arrange
        final gossips = [createTestGossip()];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        // Act & Assert
        expect(paginated.isEmpty, isFalse);
        expect(paginated.isNotEmpty, isTrue);
      });

      test('length debe retornar cantidad de elementos', () {
        // Arrange
        final gossips = [
          createTestGossip(id: 'gossip-1'),
          createTestGossip(id: 'gossip-2'),
          createTestGossip(id: 'gossip-3'),
        ];
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        // Act & Assert
        expect(paginated.length, 3);
      });

      test('length debe retornar 0 para lista vacía', () {
        // Arrange
        const paginated = PaginatedGossips.empty();

        // Act & Assert
        expect(paginated.length, 0);
      });
    });

    group('Equatable', () {
      test('debe ser igual si todos los campos son iguales', () {
        // Arrange
        final gossips1 = [createTestGossip(id: 'gossip-1')];
        final gossips2 = [createTestGossip(id: 'gossip-1')];
        const cursor = FeedCursor.popular(score: 100.0, id: 'gossip-1');

        final paginated1 = PaginatedGossips(
          data: gossips1,
          hasMore: true,
          nextCursor: cursor,
        );
        final paginated2 = PaginatedGossips(
          data: gossips2,
          hasMore: true,
          nextCursor: cursor,
        );

        // Assert
        expect(paginated1, paginated2);
        expect(paginated1.hashCode, paginated2.hashCode);
      });

      test('debe ser diferente si data es diferente', () {
        // Arrange
        final gossips1 = [createTestGossip(id: 'gossip-1')];
        final gossips2 = [createTestGossip(id: 'gossip-2')];

        final paginated1 = PaginatedGossips(
          data: gossips1,
          hasMore: false,
          nextCursor: null,
        );
        final paginated2 = PaginatedGossips(
          data: gossips2,
          hasMore: false,
          nextCursor: null,
        );

        // Assert
        expect(paginated1, isNot(paginated2));
      });

      test('debe ser diferente si hasMore es diferente', () {
        // Arrange
        final gossips = [createTestGossip()];
        const cursor = FeedCursor.popular(score: 100.0, id: 'gossip-1');

        final paginated1 = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor,
        );
        final paginated2 = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        // Assert
        expect(paginated1, isNot(paginated2));
      });

      test('debe ser diferente si nextCursor es diferente', () {
        // Arrange
        final gossips = [createTestGossip()];
        const cursor1 = FeedCursor.popular(score: 100.0, id: 'gossip-1');
        const cursor2 = FeedCursor.popular(score: 90.0, id: 'gossip-1');

        final paginated1 = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor1,
        );
        final paginated2 = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor2,
        );

        // Assert
        expect(paginated1, isNot(paginated2));
      });

      test('debe incluir data, hasMore y nextCursor en props', () {
        // Arrange
        final gossips = [createTestGossip()];
        const cursor = FeedCursor.popular(score: 100.0, id: 'gossip-1');
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor,
        );

        // Assert
        expect(paginated.props, [gossips, true, cursor]);
      });
    });

    group('toString', () {
      test('debe mostrar información resumida', () {
        // Arrange
        final gossips = [
          createTestGossip(id: 'gossip-1'),
          createTestGossip(id: 'gossip-2'),
        ];
        const cursor = FeedCursor.popular(score: 90.0, id: 'gossip-2');
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor,
        );

        // Act
        final string = paginated.toString();

        // Assert
        expect(string, contains('count: 2'));
        expect(string, contains('hasMore: true'));
        expect(string, contains('nextCursor:'));
      });

      test('debe mostrar información para lista vacía', () {
        // Arrange
        const paginated = PaginatedGossips.empty();

        // Act
        final string = paginated.toString();

        // Assert
        expect(string, contains('count: 0'));
        expect(string, contains('hasMore: false'));
        expect(string, contains('nextCursor: null'));
      });
    });

    group('Casos de uso reales', () {
      test('debe representar primera página con más datos disponibles', () {
        // Arrange
        final gossips = List.generate(
          20,
          (i) => createTestGossip(id: 'gossip-$i', score: 100.0 - i),
        );
        final cursor = FeedCursor.popular(
          score: gossips.last.score,
          id: gossips.last.id,
        );

        // Act
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: true,
          nextCursor: cursor,
        );

        // Assert
        expect(paginated.length, 20);
        expect(paginated.hasMore, isTrue);
        expect(paginated.nextCursor, isNotNull);
      });

      test('debe representar última página sin más datos', () {
        // Arrange
        final gossips = [
          createTestGossip(id: 'gossip-1'),
          createTestGossip(id: 'gossip-2'),
        ];

        // Act
        final paginated = PaginatedGossips(
          data: gossips,
          hasMore: false,
          nextCursor: null,
        );

        // Assert
        expect(paginated.length, 2);
        expect(paginated.hasMore, isFalse);
        expect(paginated.nextCursor, isNull);
      });

      test('debe representar respuesta vacía (no hay gossips)', () {
        // Act
        const paginated = PaginatedGossips.empty();

        // Assert
        expect(paginated.isEmpty, isTrue);
        expect(paginated.hasMore, isFalse);
        expect(paginated.nextCursor, isNull);
      });

      test('debe permitir combinar múltiples páginas', () {
        // Arrange - Primera página
        final page1Gossips = [
          createTestGossip(id: 'gossip-1', score: 100.0),
          createTestGossip(id: 'gossip-2', score: 90.0),
        ];
        final page1 = PaginatedGossips(
          data: page1Gossips,
          hasMore: true,
          nextCursor: FeedCursor.popular(score: 90.0, id: 'gossip-2'),
        );

        // Arrange - Segunda página
        final page2Gossips = [
          createTestGossip(id: 'gossip-3', score: 85.0),
          createTestGossip(id: 'gossip-4', score: 80.0),
        ];
        final page2 = PaginatedGossips(
          data: page2Gossips,
          hasMore: false,
          nextCursor: null,
        );

        // Act - Combinar (simulando append en UI)
        final allGossips = [...page1.data, ...page2.data];

        // Assert
        expect(allGossips.length, 4);
        expect(page1.hasMore, isTrue);
        expect(page2.hasMore, isFalse);
      });
    });

    group('Documentación', () {
      test('debe documentar que usa cursor-based pagination', () {
        // Documenta: cursor contiene score/created_at e id del último elemento
        // Permite paginación eficiente sin duplicados
      });

      test('debe documentar cálculo de hasMore en backend', () {
        // Documenta: hasMore se calcula en backend:
        // - Si data.length < pageSize → hasMore = false
        // - Si data.length >= pageSize → hasMore = true
      });

      test('debe documentar uso en UI para loadMore', () {
        // Documenta: en controller, verificar hasMore antes de cargar más:
        // if (!_hasMore || _isLoadingMore) return;
      });
    });
  });
}
