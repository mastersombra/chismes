import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/data/models/feed_gossip_model.dart';
import 'package:chismes/features/home/data/models/paginated_gossips_model.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';

void main() {
  group('PaginatedGossipsModel', () {
    final tFeedGossipJson = {
      'id': 'gossip-123',
      'subject': 'Test Subject',
      'content': 'Test Content',
      'city_id': 'MED',
      'created_at': '2024-01-15T10:30:00Z',
      'likes': 100,
      'comments': 20,
      'shares': 5,
      'published_as': 'anonymous',
      'created_by': 'user-456',
      'image_url': 'https://example.com/image.jpg',
      'score': 123.45,
      'is_from_my_city': true,
      'is_trending': false,
    };

    final tPaginatedJson = {
      'data': [
        tFeedGossipJson,
        {...tFeedGossipJson, 'id': 'gossip-456', 'score': 100.0},
      ],
      'has_more': true,
      'next_cursor': {
        'score': 100.0,
        'id': 'gossip-456',
      },
    };

    group('fromJson', () {
      test('debe crear modelo válido desde JSON completo', () {
        // Act
        final result = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Assert
        expect(result.data.length, 2);
        expect(result.hasMore, true);
        expect(result.nextCursor, isNotNull);
        expect(result.nextCursor!['score'], 100.0);
        expect(result.nextCursor!['id'], 'gossip-456');
      });

      test('debe parsear lista de FeedGossipModel correctamente', () {
        // Act
        final result = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Assert
        expect(result.data, isA<List<FeedGossipModel>>());
        expect(result.data[0].id, 'gossip-123');
        expect(result.data[0].score, 123.45);
        expect(result.data[1].id, 'gossip-456');
        expect(result.data[1].score, 100.0);
      });

      test('debe manejar lista vacía', () {
        // Arrange
        final json = {
          'data': <Map<String, dynamic>>[],
          'has_more': false,
          'next_cursor': null,
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.data, isEmpty);
        expect(result.hasMore, false);
        expect(result.nextCursor, null);
      });

      test('debe manejar nextCursor null', () {
        // Arrange
        final json = {
          'data': [tFeedGossipJson],
          'has_more': false,
          'next_cursor': null,
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.nextCursor, null);
      });

      test('debe lanzar FormatException si data no es lista', () {
        // Arrange
        final json = {
          'data': 'not_a_list',
          'has_more': false,
          'next_cursor': null,
        };

        // Act & Assert
        expect(
          () => PaginatedGossipsModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe lanzar FormatException si falta campo requerido', () {
        // Arrange
        final json = {
          'data': <Map<String, dynamic>>[],
          // Falta 'has_more'
          'next_cursor': null,
        };

        // Act & Assert
        expect(
          () => PaginatedGossipsModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe incluir JSON en el mensaje de error', () {
        // Arrange
        final json = {
          'data': 'invalid',
          'has_more': true,
        };

        // Act & Assert
        try {
          PaginatedGossipsModel.fromJson(json);
          fail('Should throw FormatException');
        } catch (e) {
          expect(e, isA<FormatException>());
          expect(e.toString(), contains('Error deserializando'));
          expect(e.toString(), contains('PaginatedGossipsModel'));
        }
      });
    });

    group('toEntity', () {
      test('debe convertir modelo a entidad correctamente', () {
        // Arrange
        final model = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<PaginatedGossips>());
        expect(entity.data.length, 2);
        expect(entity.hasMore, true);
        expect(entity.nextCursor, isNotNull);
      });

      test('debe convertir lista de models a entities', () {
        // Arrange
        final model = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.data[0].id, 'gossip-123');
        expect(entity.data[0].score, 123.45);
        expect(entity.data[1].id, 'gossip-456');
        expect(entity.data[1].score, 100.0);
      });

      test('debe convertir nextCursor correctamente', () {
        // Arrange
        final model = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.nextCursor, isNotNull);
        expect(entity.nextCursor!.score, 100.0);
        expect(entity.nextCursor!.id, 'gossip-456');
      });

      test('debe manejar nextCursor null', () {
        // Arrange
        final json = {
          'data': [tFeedGossipJson],
          'has_more': false,
          'next_cursor': null,
        };
        final model = PaginatedGossipsModel.fromJson(json);

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.nextCursor, null);
      });

      test('debe convertir lista vacía correctamente', () {
        // Arrange
        final json = {
          'data': <Map<String, dynamic>>[],
          'has_more': false,
          'next_cursor': null,
        };
        final model = PaginatedGossipsModel.fromJson(json);

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.data, isEmpty);
        expect(entity.hasMore, false);
      });
    });

    group('empty constructor', () {
      test('debe crear modelo vacío con valores correctos', () {
        // Act
        const result = PaginatedGossipsModel.empty();

        // Assert
        expect(result.data, isEmpty);
        expect(result.hasMore, false);
        expect(result.nextCursor, null);
      });

      test('debe ser constante', () {
        // Act
        const result1 = PaginatedGossipsModel.empty();
        const result2 = PaginatedGossipsModel.empty();

        // Assert
        expect(identical(result1, result2), true);
      });
    });

    group('toString', () {
      test('debe retornar representación string legible', () {
        // Arrange
        final model = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('PaginatedGossipsModel'));
        expect(result, contains('count: 2'));
        expect(result, contains('hasMore: true'));
        expect(result, contains('hasCursor: true'));
      });

      test('debe indicar hasCursor false cuando nextCursor es null', () {
        // Arrange
        final json = {
          'data': [tFeedGossipJson],
          'has_more': false,
          'next_cursor': null,
        };
        final model = PaginatedGossipsModel.fromJson(json);

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('hasCursor: false'));
      });

      test('debe mostrar count correcto', () {
        // Arrange
        const model = PaginatedGossipsModel.empty();

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('count: 0'));
      });
    });

    group('Edge cases', () {
      test('debe manejar lista con un solo elemento', () {
        // Arrange
        final json = {
          'data': [tFeedGossipJson],
          'has_more': false,
          'next_cursor': null,
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.data.length, 1);
      });

      test('debe manejar lista con muchos elementos', () {
        // Arrange
        final manyGossips = List.generate(
          100,
          (i) => {...tFeedGossipJson, 'id': 'gossip-$i'},
        );
        final json = {
          'data': manyGossips,
          'has_more': true,
          'next_cursor': {'score': 50.0, 'id': 'gossip-99'},
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.data.length, 100);
        expect(result.data.first.id, 'gossip-0');
        expect(result.data.last.id, 'gossip-99');
      });

      test('debe manejar has_more true sin nextCursor', () {
        // Arrange - Esto podría ser un edge case de backend inconsistente
        final json = {
          'data': [tFeedGossipJson],
          'has_more': true,
          'next_cursor': null,
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.hasMore, true);
        expect(result.nextCursor, null);
      });

      test('debe manejar nextCursor con campos adicionales', () {
        // Arrange
        final json = {
          'data': [tFeedGossipJson],
          'has_more': true,
          'next_cursor': {
            'score': 100.0,
            'id': 'gossip-456',
            'extra_field': 'should be preserved',
          },
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.nextCursor!['extra_field'], 'should be preserved');
      });

      test('debe manejar created_at en lugar de score en cursor', () {
        // Arrange - Para following feed que usa created_at
        final json = {
          'data': [tFeedGossipJson],
          'has_more': true,
          'next_cursor': {
            'created_at': '2024-01-15T10:30:00Z',
            'id': 'gossip-456',
          },
        };

        // Act
        final result = PaginatedGossipsModel.fromJson(json);

        // Assert
        expect(result.nextCursor, isNotNull);
        expect(result.nextCursor!['created_at'], '2024-01-15T10:30:00Z');
        expect(result.nextCursor!['id'], 'gossip-456');
      });
    });

    group('Integración con FeedGossipModel', () {
      test('debe propagar errores de FeedGossipModel.fromJson', () {
        // Arrange
        final json = {
          'data': [
            {'invalid': 'gossip'}, // Falta campos requeridos
          ],
          'has_more': false,
          'next_cursor': null,
        };

        // Act & Assert
        expect(
          () => PaginatedGossipsModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe manejar mezcla de gossips válidos e inválidos', () {
        // Arrange
        final json = {
          'data': [
            tFeedGossipJson,
            {'invalid': 'gossip'}, // Segundo elemento inválido
          ],
          'has_more': false,
          'next_cursor': null,
        };

        // Act & Assert
        expect(
          () => PaginatedGossipsModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Serialización roundtrip', () {
      test('debe mantener estructura después de toEntity', () {
        // Arrange
        final model = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.data.length, model.data.length);
        expect(entity.hasMore, model.hasMore);
        expect(entity.nextCursor, isNotNull);
      });

      test('debe mantener datos de gossips después de toEntity', () {
        // Arrange
        final model = PaginatedGossipsModel.fromJson(tPaginatedJson);

        // Act
        final entity = model.toEntity();

        // Assert
        for (var i = 0; i < model.data.length; i++) {
          expect(entity.data[i].id, model.data[i].id);
          expect(entity.data[i].subject, model.data[i].subject);
          expect(entity.data[i].score, model.data[i].score);
        }
      });
    });
  });
}
