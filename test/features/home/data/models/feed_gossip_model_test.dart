import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/data/models/feed_gossip_model.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';

void main() {
  group('FeedGossipModel', () {
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

    final tFeedGossipModel = FeedGossipModel(
      id: 'gossip-123',
      subject: 'Test Subject',
      content: 'Test Content',
      cityId: 'MED',
      createdAt: '2024-01-15T10:30:00Z',
      likes: 100,
      comments: 20,
      shares: 5,
      publishedAs: 'anonymous',
      createdBy: 'user-456',
      imageUrl: 'https://example.com/image.jpg',
      score: 123.45,
      isFromMyCity: true,
      isTrending: false,
    );

    group('fromJson', () {
      test('debe crear modelo válido desde JSON completo', () {
        // Act
        final result = FeedGossipModel.fromJson(tFeedGossipJson);

        // Assert
        expect(result.id, 'gossip-123');
        expect(result.subject, 'Test Subject');
        expect(result.content, 'Test Content');
        expect(result.cityId, 'MED');
        expect(result.createdAt, '2024-01-15T10:30:00Z');
        expect(result.likes, 100);
        expect(result.comments, 20);
        expect(result.shares, 5);
        expect(result.publishedAs, 'anonymous');
        expect(result.createdBy, 'user-456');
        expect(result.imageUrl, 'https://example.com/image.jpg');
        expect(result.score, 123.45);
        expect(result.isFromMyCity, true);
        expect(result.isTrending, false);
      });

      test('debe manejar campos opcionales como null', () {
        // Arrange
        final json = {
          'id': 'gossip-123',
          'subject': 'Test',
          'content': 'Content',
          'city_id': 'MED',
          'created_at': '2024-01-15T10:30:00Z',
          'likes': 0,
          'comments': 0,
          'shares': 0,
          'published_as': 'anonymous',
          'created_by': null,
          'image_url': null,
          'score': 0.0,
          'is_from_my_city': null,
          'is_trending': false,
        };

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.createdBy, null);
        expect(result.imageUrl, null);
        expect(result.isFromMyCity, null);
      });

      test('debe convertir num a double para score', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['score'] = 100; // int en lugar de double

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.score, 100.0);
        expect(result.score, isA<double>());
      });

      test('debe manejar gossip trending', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['is_trending'] = true;

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.isTrending, true);
      });

      test('debe manejar gossip no trending', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['is_trending'] = false;

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.isTrending, false);
      });

      test('debe lanzar FormatException si falta campo requerido', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json.remove('id');

        // Act & Assert
        expect(
          () => FeedGossipModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe lanzar FormatException si tipo es incorrecto', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['likes'] = 'not_a_number'; // String en lugar de int

        // Act & Assert
        expect(
          () => FeedGossipModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe incluir JSON en el mensaje de error', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['id'] = 123; // int en lugar de String

        // Act & Assert
        try {
          FeedGossipModel.fromJson(json);
          fail('Should throw FormatException');
        } catch (e) {
          expect(e, isA<FormatException>());
          expect(e.toString(), contains('Error deserializando'));
        }
      });
    });

    group('toEntity', () {
      test('debe convertir modelo a entidad correctamente', () {
        // Act
        final entity = tFeedGossipModel.toEntity();

        // Assert
        expect(entity, isA<FeedGossip>());
        expect(entity.id, 'gossip-123');
        expect(entity.subject, 'Test Subject');
        expect(entity.content, 'Test Content');
        expect(entity.cityId, 'MED');
        expect(entity.createdAt, DateTime.parse('2024-01-15T10:30:00Z'));
        expect(entity.likes, 100);
        expect(entity.comments, 20);
        expect(entity.shares, 5);
        expect(entity.publishedAs, 'anonymous');
        expect(entity.createdBy, 'user-456');
        expect(entity.imageUrl, 'https://example.com/image.jpg');
        expect(entity.score, 123.45);
        expect(entity.isFromMyCity, true);
        expect(entity.isTrending, false);
      });

      test('debe parsear correctamente fecha ISO 8601', () {
        // Act
        final entity = tFeedGossipModel.toEntity();

        // Assert
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.createdAt.year, 2024);
        expect(entity.createdAt.month, 1);
        expect(entity.createdAt.day, 15);
        expect(entity.createdAt.hour, 10);
        expect(entity.createdAt.minute, 30);
      });

      test('debe preservar campos opcionales null', () {
        // Arrange
        const model = FeedGossipModel(
          id: 'gossip-123',
          subject: 'Test',
          content: 'Content',
          cityId: 'MED',
          createdAt: '2024-01-15T10:30:00Z',
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          createdBy: null,
          imageUrl: null,
          score: 0.0,
          isFromMyCity: null,
          isTrending: false,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.createdBy, null);
        expect(entity.imageUrl, null);
        expect(entity.isFromMyCity, null);
      });
    });

    group('proximity y city_name', () {
      Map<String, dynamic> json({Object? proximity, Object? cityName}) => {
            'id': 'g1',
            'subject': 's',
            'content': 'c',
            'city_id': 'MED',
            'city_name': cityName,
            'created_at': '2024-01-15T10:30:00Z',
            'likes': 0,
            'comments': 0,
            'shares': 0,
            'published_as': 'profile',
            'score': 1,
            'proximity': proximity,
            'is_trending': false,
          };

      test('parsea proximity y city_name del RPC', () {
        final entity = FeedGossipModel.fromJson(
          json(proximity: 'region', cityName: 'Envigado'),
        ).toEntity();

        expect(entity.proximity, FeedProximity.region);
        expect(entity.cityName, 'Envigado');
      });

      test('proximity ausente o desconocido → global', () {
        expect(FeedGossipModel.fromJson(json()).toEntity().proximity,
            FeedProximity.global);
        expect(
            FeedGossipModel.fromJson(json(proximity: 'planeta')).toEntity().proximity,
            FeedProximity.global);
      });
    });

    group('toJson', () {
      test('debe convertir modelo a JSON correctamente', () {
        // Act
        final json = tFeedGossipModel.toJson();

        // Assert
        expect(json, {
          'id': 'gossip-123',
          'subject': 'Test Subject',
          'content': 'Test Content',
          'city_id': 'MED',
          'city_name': null,
          'created_at': '2024-01-15T10:30:00Z',
          'likes': 100,
          'comments': 20,
          'shares': 5,
          'published_as': 'anonymous',
          'created_by': 'user-456',
          'author_username': null,
          'author_display_name': null,
          'author_avatar_url': null,
          'image_url': 'https://example.com/image.jpg',
          'score': 123.45,
          'proximity': null,
          'is_from_my_city': true,
          'is_trending': false,
        });
      });

      test('debe incluir campos null en JSON', () {
        // Arrange
        const model = FeedGossipModel(
          id: 'gossip-123',
          subject: 'Test',
          content: 'Content',
          cityId: 'MED',
          createdAt: '2024-01-15T10:30:00Z',
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          createdBy: null,
          imageUrl: null,
          score: 0.0,
          isFromMyCity: null,
          isTrending: false,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['created_by'], null);
        expect(json['image_url'], null);
        expect(json['is_from_my_city'], null);
      });
    });

    group('toString', () {
      test('debe retornar representación string legible', () {
        // Act
        final result = tFeedGossipModel.toString();

        // Assert
        expect(result, contains('FeedGossipModel'));
        expect(result, contains('gossip-123'));
        expect(result, contains('Test Subject'));
        expect(result, contains('123.45'));
      });

      test('debe truncar subject largo a 20 caracteres', () {
        // Arrange
        const model = FeedGossipModel(
          id: 'gossip-123',
          subject: 'This is a very long subject that should be truncated',
          content: 'Content',
          cityId: 'MED',
          createdAt: '2024-01-15T10:30:00Z',
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          score: 0.0,
          isTrending: false,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('This is a very long '));
        expect(result, contains('...'));
        expect(result, isNot(contains('that should be truncated')));
      });

      test('debe manejar subject corto sin truncar', () {
        // Arrange
        const model = FeedGossipModel(
          id: 'gossip-123',
          subject: 'Short',
          content: 'Content',
          cityId: 'MED',
          createdAt: '2024-01-15T10:30:00Z',
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          score: 0.0,
          isTrending: false,
        );

        // Act
        final result = model.toString();

        // Assert
        expect(result, contains('Short...'));
      });
    });

    group('Serialización roundtrip', () {
      test('debe mantener datos después de JSON roundtrip', () {
        // Act
        final json = tFeedGossipModel.toJson();
        final restored = FeedGossipModel.fromJson(json);

        // Assert
        expect(restored.id, tFeedGossipModel.id);
        expect(restored.subject, tFeedGossipModel.subject);
        expect(restored.content, tFeedGossipModel.content);
        expect(restored.cityId, tFeedGossipModel.cityId);
        expect(restored.likes, tFeedGossipModel.likes);
        expect(restored.comments, tFeedGossipModel.comments);
        expect(restored.shares, tFeedGossipModel.shares);
        expect(restored.score, tFeedGossipModel.score);
        expect(restored.isTrending, tFeedGossipModel.isTrending);
      });

      test('debe mantener campos null después de roundtrip', () {
        // Arrange
        const model = FeedGossipModel(
          id: 'gossip-123',
          subject: 'Test',
          content: 'Content',
          cityId: 'MED',
          createdAt: '2024-01-15T10:30:00Z',
          likes: 0,
          comments: 0,
          shares: 0,
          publishedAs: 'anonymous',
          createdBy: null,
          imageUrl: null,
          score: 0.0,
          isFromMyCity: null,
          isTrending: false,
        );

        // Act
        final json = model.toJson();
        final restored = FeedGossipModel.fromJson(json);

        // Assert
        expect(restored.createdBy, null);
        expect(restored.imageUrl, null);
        expect(restored.isFromMyCity, null);
      });
    });

    group('Edge cases', () {
      test('debe manejar contadores en cero', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['likes'] = 0;
        json['comments'] = 0;
        json['shares'] = 0;

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.likes, 0);
        expect(result.comments, 0);
        expect(result.shares, 0);
      });

      test('debe manejar números grandes de interacciones', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['likes'] = 999999;
        json['comments'] = 888888;
        json['shares'] = 777777;

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.likes, 999999);
        expect(result.comments, 888888);
        expect(result.shares, 777777);
      });

      test('debe manejar score negativo', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['score'] = -10.5;

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.score, -10.5);
      });

      test('debe manejar score muy grande', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['score'] = 999999.99;

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.score, 999999.99);
      });

      test('debe manejar diferentes valores de published_as', () {
        // Arrange
        final jsonAnonymous = Map<String, dynamic>.from(tFeedGossipJson);
        jsonAnonymous['published_as'] = 'anonymous';

        final jsonProfile = Map<String, dynamic>.from(tFeedGossipJson);
        jsonProfile['published_as'] = 'profile';

        // Act
        final resultAnonymous = FeedGossipModel.fromJson(jsonAnonymous);
        final resultProfile = FeedGossipModel.fromJson(jsonProfile);

        // Assert
        expect(resultAnonymous.publishedAs, 'anonymous');
        expect(resultProfile.publishedAs, 'profile');
      });

      test('debe manejar URLs de imagen largas', () {
        // Arrange
        final json = Map<String, dynamic>.from(tFeedGossipJson);
        json['image_url'] =
            'https://example.com/very/long/path/to/image/with/many/segments/image.jpg?param=value&another=param';

        // Act
        final result = FeedGossipModel.fromJson(json);

        // Assert
        expect(result.imageUrl, isNotNull);
        expect(result.imageUrl!.length, greaterThan(50));
      });

      test('debe manejar fechas en diferentes formatos ISO 8601', () {
        // Arrange
        final jsonWithMillis = Map<String, dynamic>.from(tFeedGossipJson);
        jsonWithMillis['created_at'] = '2024-01-15T10:30:00.123Z';

        final jsonWithoutZ = Map<String, dynamic>.from(tFeedGossipJson);
        jsonWithoutZ['created_at'] = '2024-01-15T10:30:00';

        // Act
        final resultWithMillis = FeedGossipModel.fromJson(jsonWithMillis);
        final resultWithoutZ = FeedGossipModel.fromJson(jsonWithoutZ);

        // Assert
        expect(resultWithMillis.createdAt, '2024-01-15T10:30:00.123Z');
        expect(resultWithoutZ.createdAt, '2024-01-15T10:30:00');
      });
    });
  });
}
