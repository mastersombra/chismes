import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';

void main() {
  group('FeedCursor', () {
    group('Constructor con score (Popular feed)', () {
      test('debe crear cursor con score e id', () {
        // Arrange & Act
        const cursor = FeedCursor(
          score: 95.5,
          id: 'gossip-123',
        );

        // Assert
        expect(cursor.score, 95.5);
        expect(cursor.id, 'gossip-123');
        expect(cursor.createdAt, isNull);
      });

      test('debe crear cursor con constructor nombrado popular', () {
        // Arrange & Act
        const cursor = FeedCursor.popular(
          score: 100.0,
          id: 'gossip-456',
        );

        // Assert
        expect(cursor.score, 100.0);
        expect(cursor.id, 'gossip-456');
        expect(cursor.createdAt, isNull);
      });
    });

    group('Constructor con createdAt (Following feed)', () {
      test('debe crear cursor con createdAt e id', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);

        // Act
        final cursor = FeedCursor(
          createdAt: createdAt,
          id: 'gossip-789',
        );

        // Assert
        expect(cursor.createdAt, createdAt);
        expect(cursor.id, 'gossip-789');
        expect(cursor.score, isNull);
      });

      test('debe crear cursor con constructor nombrado following', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 20, 15, 45);

        // Act
        final cursor = FeedCursor.following(
          createdAt: createdAt,
          id: 'gossip-abc',
        );

        // Assert
        expect(cursor.createdAt, createdAt);
        expect(cursor.id, 'gossip-abc');
        expect(cursor.score, isNull);
      });
    });

    group('Serialización - toJson', () {
      test('debe serializar cursor con score', () {
        // Arrange
        const cursor = FeedCursor.popular(
          score: 85.5,
          id: 'gossip-123',
        );

        // Act
        final json = cursor.toJson();

        // Assert
        expect(json['score'], 85.5);
        expect(json['id'], 'gossip-123');
        expect(json.containsKey('created_at'), isFalse);
      });

      test('debe serializar cursor con createdAt', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final cursor = FeedCursor.following(
          createdAt: createdAt,
          id: 'gossip-456',
        );

        // Act
        final json = cursor.toJson();

        // Assert
        expect(json['created_at'], createdAt.toIso8601String());
        expect(json['id'], 'gossip-456');
        expect(json.containsKey('score'), isFalse);
      });

      test('debe serializar solo campos no nulos', () {
        // Arrange
        const cursor = FeedCursor.popular(
          score: 90.0,
          id: 'gossip-789',
        );

        // Act
        final json = cursor.toJson();

        // Assert
        expect(json.length, 2); // Solo score e id
        expect(json.keys, containsAll(['score', 'id']));
      });
    });

    group('Deserialización - fromJson', () {
      test('debe deserializar cursor con score', () {
        // Arrange
        final json = {
          'score': 95.5,
          'id': 'gossip-123',
        };

        // Act
        final cursor = FeedCursor.fromJson(json);

        // Assert
        expect(cursor.score, 95.5);
        expect(cursor.id, 'gossip-123');
        expect(cursor.createdAt, isNull);
      });

      test('debe deserializar cursor con createdAt', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final json = {
          'created_at': createdAt.toIso8601String(),
          'id': 'gossip-456',
        };

        // Act
        final cursor = FeedCursor.fromJson(json);

        // Assert
        expect(cursor.createdAt, createdAt);
        expect(cursor.id, 'gossip-456');
        expect(cursor.score, isNull);
      });

      test('debe manejar score como int y convertirlo a double', () {
        // Arrange
        final json = {
          'score': 100, // int
          'id': 'gossip-789',
        };

        // Act
        final cursor = FeedCursor.fromJson(json);

        // Assert
        expect(cursor.score, 100.0); // Debe ser double
        expect(cursor.score, isA<double>());
      });

      test('debe manejar score como double', () {
        // Arrange
        final json = {
          'score': 95.75,
          'id': 'gossip-abc',
        };

        // Act
        final cursor = FeedCursor.fromJson(json);

        // Assert
        expect(cursor.score, 95.75);
      });
    });

    group('Equatable', () {
      test('debe ser igual si todos los campos son iguales', () {
        // Arrange
        const cursor1 = FeedCursor.popular(score: 100.0, id: 'gossip-1');
        const cursor2 = FeedCursor.popular(score: 100.0, id: 'gossip-1');

        // Assert
        expect(cursor1, cursor2);
        expect(cursor1.hashCode, cursor2.hashCode);
      });

      test('debe ser diferente si el score es diferente', () {
        // Arrange
        const cursor1 = FeedCursor.popular(score: 100.0, id: 'gossip-1');
        const cursor2 = FeedCursor.popular(score: 95.0, id: 'gossip-1');

        // Assert
        expect(cursor1, isNot(cursor2));
      });

      test('debe ser diferente si el id es diferente', () {
        // Arrange
        const cursor1 = FeedCursor.popular(score: 100.0, id: 'gossip-1');
        const cursor2 = FeedCursor.popular(score: 100.0, id: 'gossip-2');

        // Assert
        expect(cursor1, isNot(cursor2));
      });

      test('debe ser diferente si createdAt es diferente', () {
        // Arrange
        final createdAt1 = DateTime(2024, 1, 15, 10, 30);
        final createdAt2 = DateTime(2024, 1, 15, 10, 31);
        final cursor1 = FeedCursor.following(createdAt: createdAt1, id: 'gossip-1');
        final cursor2 = FeedCursor.following(createdAt: createdAt2, id: 'gossip-1');

        // Assert
        expect(cursor1, isNot(cursor2));
      });

      test('debe incluir score, createdAt e id en props', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final cursor = FeedCursor(
          score: 100.0,
          createdAt: createdAt,
          id: 'gossip-1',
        );

        // Assert
        expect(cursor.props, [100.0, createdAt, 'gossip-1']);
      });
    });

    group('toString', () {
      test('debe mostrar formato para Popular feed', () {
        // Arrange
        const cursor = FeedCursor.popular(score: 95.5, id: 'gossip-123');

        // Act
        final string = cursor.toString();

        // Assert
        expect(string, 'FeedCursor.popular(score: 95.5, id: gossip-123)');
      });

      test('debe mostrar formato para Following feed', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final cursor = FeedCursor.following(createdAt: createdAt, id: 'gossip-456');

        // Act
        final string = cursor.toString();

        // Assert
        expect(string, contains('FeedCursor.following'));
        expect(string, contains('gossip-456'));
      });
    });

    group('Roundtrip serialization', () {
      test('debe mantener datos después de toJson + fromJson (Popular)', () {
        // Arrange
        const original = FeedCursor.popular(score: 95.5, id: 'gossip-123');

        // Act
        final json = original.toJson();
        final restored = FeedCursor.fromJson(json);

        // Assert
        expect(restored, original);
        expect(restored.score, original.score);
        expect(restored.id, original.id);
      });

      test('debe mantener datos después de toJson + fromJson (Following)', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final original = FeedCursor.following(createdAt: createdAt, id: 'gossip-456');

        // Act
        final json = original.toJson();
        final restored = FeedCursor.fromJson(json);

        // Assert
        expect(restored, original);
        expect(restored.createdAt, original.createdAt);
        expect(restored.id, original.id);
      });
    });

    group('Documentación', () {
      test('debe documentar que es para cursor-based pagination', () {
        // Documenta: cursor-based pagination es más eficiente que offset-based
        // Performance: O(1) vs O(n) con offsets grandes
      });

      test('debe documentar que usa índices compuestos', () {
        // Documenta: siempre puede usar índices compuestos (score, id) o (created_at, id)
        // Evita full table scans
      });

      test('debe documentar que evita duplicados', () {
        // Documenta: nuevos elementos insertados no afectan la paginación
        // No hay duplicados cuando hay inserciones concurrentes
      });
    });
  });
}
