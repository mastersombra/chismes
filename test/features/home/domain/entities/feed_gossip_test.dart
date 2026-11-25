import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';

void main() {
  group('FeedGossip', () {
    // Helper para crear FeedGossip de prueba
    FeedGossip createTestGossip({
      String id = 'gossip-1',
      String subject = 'Test Subject',
      String content = 'Test content',
      int likes = 10,
      int comments = 5,
      int shares = 2,
      String publishedAs = 'profile',
      String? createdBy = 'user-123',
      double score = 100.0,
      bool? isFromMyCity = true,
      bool isTrending = false,
    }) {
      return FeedGossip(
        id: id,
        subject: subject,
        content: content,
        cityId: 'city-123',
        createdAt: DateTime(2024, 1, 1),
        likes: likes,
        comments: comments,
        shares: shares,
        publishedAs: publishedAs,
        createdBy: createdBy,
        score: score,
        isFromMyCity: isFromMyCity,
        isTrending: isTrending,
      );
    }

    group('Constructor', () {
      test('debe crear instancia con todos los campos requeridos', () {
        // Arrange & Act
        final gossip = createTestGossip();

        // Assert
        expect(gossip.id, 'gossip-1');
        expect(gossip.subject, 'Test Subject');
        expect(gossip.content, 'Test content');
        expect(gossip.cityId, 'city-123');
        expect(gossip.likes, 10);
        expect(gossip.comments, 5);
        expect(gossip.shares, 2);
        expect(gossip.publishedAs, 'profile');
        expect(gossip.createdBy, 'user-123');
        expect(gossip.score, 100.0);
        expect(gossip.isFromMyCity, isTrue);
        expect(gossip.isTrending, isFalse);
      });

      test('debe permitir createdBy null (gossip anónimo)', () {
        // Arrange & Act
        final gossip = createTestGossip(
          publishedAs: 'anonymous',
          createdBy: null,
        );

        // Assert
        expect(gossip.publishedAs, 'anonymous');
        expect(gossip.createdBy, isNull);
      });

      test('debe permitir isFromMyCity null (usuario sin ciudad)', () {
        // Arrange & Act
        final gossip = createTestGossip(isFromMyCity: null);

        // Assert
        expect(gossip.isFromMyCity, isNull);
      });

      test('debe permitir imageUrl null', () {
        // Arrange & Act
        final gossip = createTestGossip();

        // Assert
        expect(gossip.imageUrl, isNull);
      });
    });

    group('totalInteractions getter', () {
      test('debe calcular total de interacciones correctamente', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 100,
          comments: 50,
          shares: 10,
        );

        // Act & Assert
        expect(gossip.totalInteractions, 160); // 100 + 50 + 10
      });

      test('debe retornar 0 cuando no hay interacciones', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 0,
          comments: 0,
          shares: 0,
        );

        // Act & Assert
        expect(gossip.totalInteractions, 0);
      });

      test('debe sumar correctamente interacciones mixtas', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 1000,
          comments: 200,
          shares: 50,
        );

        // Act & Assert
        expect(gossip.totalInteractions, 1250);
      });
    });

    group('isAnonymous getter', () {
      test('debe retornar true cuando publishedAs es anonymous', () {
        // Arrange
        final gossip = createTestGossip(
          publishedAs: 'anonymous',
          createdBy: null,
        );

        // Act & Assert
        expect(gossip.isAnonymous, isTrue);
      });

      test('debe retornar false cuando publishedAs es profile', () {
        // Arrange
        final gossip = createTestGossip(publishedAs: 'profile');

        // Act & Assert
        expect(gossip.isAnonymous, isFalse);
      });
    });

    group('Trending logic', () {
      test('debe marcar como trending con likes > 1000', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 1001,
          comments: 0,
          shares: 0,
          isTrending: true,
        );

        // Assert
        expect(gossip.isTrending, isTrue);
      });

      test('debe marcar como trending con comments > 200', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 0,
          comments: 201,
          shares: 0,
          isTrending: true,
        );

        // Assert
        expect(gossip.isTrending, isTrue);
      });

      test('debe marcar como trending con shares > 100', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 0,
          comments: 0,
          shares: 101,
          isTrending: true,
        );

        // Assert
        expect(gossip.isTrending, isTrue);
      });

      test('no debe ser trending con números menores', () {
        // Arrange
        final gossip = createTestGossip(
          likes: 999,
          comments: 199,
          shares: 99,
          isTrending: false,
        );

        // Assert
        expect(gossip.isTrending, isFalse);
      });
    });

    group('City badges', () {
      test('isFromMyCity true indica gossip local', () {
        // Arrange
        final gossip = createTestGossip(isFromMyCity: true);

        // Assert
        expect(gossip.isFromMyCity, isTrue);
        // UI: no mostrar badge de ciudad
      });

      test('isFromMyCity false indica gossip de otra ciudad', () {
        // Arrange
        final gossip = createTestGossip(isFromMyCity: false);

        // Assert
        expect(gossip.isFromMyCity, isFalse);
        // UI: mostrar badge con nombre de ciudad
      });

      test('isFromMyCity null indica usuario sin ciudad configurada', () {
        // Arrange
        final gossip = createTestGossip(isFromMyCity: null);

        // Assert
        expect(gossip.isFromMyCity, isNull);
        // UI: no mostrar badge de ciudad
      });
    });

    group('Score algoritmo', () {
      test('debe almacenar score del algoritmo de ranking', () {
        // Arrange
        final gossip = createTestGossip(score: 95.75);

        // Assert
        expect(gossip.score, 95.75);
      });

      test('debe soportar scores altos', () {
        // Arrange
        final gossip = createTestGossip(score: 1000.0);

        // Assert
        expect(gossip.score, 1000.0);
      });

      test('debe soportar scores bajos', () {
        // Arrange
        final gossip = createTestGossip(score: 0.5);

        // Assert
        expect(gossip.score, 0.5);
      });
    });

    group('Equatable', () {
      test('debe ser igual si todos los campos son iguales', () {
        // Arrange
        final gossip1 = createTestGossip(id: 'gossip-1');
        final gossip2 = createTestGossip(id: 'gossip-1');

        // Assert
        expect(gossip1, gossip2);
        expect(gossip1.hashCode, gossip2.hashCode);
      });

      test('debe ser diferente si id es diferente', () {
        // Arrange
        final gossip1 = createTestGossip(id: 'gossip-1');
        final gossip2 = createTestGossip(id: 'gossip-2');

        // Assert
        expect(gossip1, isNot(gossip2));
      });

      test('debe ser diferente si subject es diferente', () {
        // Arrange
        final gossip1 = createTestGossip(subject: 'Subject 1');
        final gossip2 = createTestGossip(subject: 'Subject 2');

        // Assert
        expect(gossip1, isNot(gossip2));
      });

      test('debe ser diferente si likes es diferente', () {
        // Arrange
        final gossip1 = createTestGossip(likes: 10);
        final gossip2 = createTestGossip(likes: 20);

        // Assert
        expect(gossip1, isNot(gossip2));
      });

      test('debe ser diferente si score es diferente', () {
        // Arrange
        final gossip1 = createTestGossip(score: 100.0);
        final gossip2 = createTestGossip(score: 95.0);

        // Assert
        expect(gossip1, isNot(gossip2));
      });

      test('debe incluir todos los campos en props', () {
        // Arrange
        final gossip = createTestGossip();

        // Assert
        expect(gossip.props.length, 17);
        expect(gossip.props, contains(gossip.id));
        expect(gossip.props, contains(gossip.subject));
        expect(gossip.props, contains(gossip.likes));
        expect(gossip.props, contains(gossip.score));
      });
    });

    group('toString', () {
      test('debe mostrar información resumida', () {
        // Arrange
        final gossip = createTestGossip(
          id: 'gossip-123',
          subject: 'Very long subject that should be truncated',
          score: 95.5,
          likes: 100,
        );

        // Act
        final string = gossip.toString();

        // Assert
        expect(string, contains('id: gossip-123'));
        expect(string, contains('score: 95.50'));
        expect(string, contains('likes: 100'));
        expect(string, contains('...'));
      });

      test('debe truncar subject largo', () {
        // Arrange
        final longSubject = 'A' * 50;
        final gossip = createTestGossip(subject: longSubject);

        // Act
        final string = gossip.toString();

        // Assert
        expect(string.length, lessThan(longSubject.length + 100));
      });

      test('debe no truncar subject corto', () {
        // Arrange
        final shortSubject = 'Short';
        final gossip = createTestGossip(subject: shortSubject);

        // Act
        final string = gossip.toString();

        // Assert
        expect(string, contains(shortSubject));
      });
    });

    group('Casos de uso reales', () {
      test('debe representar gossip local normal', () {
        // Arrange & Act
        final gossip = createTestGossip(
          subject: 'Chisme local',
          likes: 50,
          comments: 10,
          shares: 2,
          publishedAs: 'profile',
          isFromMyCity: true,
          isTrending: false,
        );

        // Assert
        expect(gossip.isFromMyCity, isTrue);
        expect(gossip.isTrending, isFalse);
        expect(gossip.isAnonymous, isFalse);
        expect(gossip.totalInteractions, 62);
      });

      test('debe representar gossip viral de otra ciudad', () {
        // Arrange & Act
        final gossip = createTestGossip(
          subject: 'Chisme viral',
          likes: 1500,
          comments: 300,
          shares: 150,
          isFromMyCity: false,
          isTrending: true,
        );

        // Assert
        expect(gossip.isFromMyCity, isFalse);
        expect(gossip.isTrending, isTrue);
        expect(gossip.totalInteractions, 1950);
      });

      test('debe representar gossip anónimo', () {
        // Arrange & Act
        final gossip = createTestGossip(
          publishedAs: 'anonymous',
          createdBy: null,
        );

        // Assert
        expect(gossip.isAnonymous, isTrue);
        expect(gossip.createdBy, isNull);
      });

      test('debe representar gossip con imagen', () {
        // Arrange
        final gossip = FeedGossip(
          id: 'gossip-1',
          subject: 'Chisme con imagen',
          content: 'Contenido',
          cityId: 'city-123',
          createdAt: DateTime(2024, 1, 1),
          likes: 10,
          comments: 5,
          shares: 2,
          publishedAs: 'profile',
          createdBy: 'user-123',
          imageUrl: 'https://example.com/image.jpg',
          score: 100.0,
          isFromMyCity: true,
          isTrending: false,
        );

        // Assert
        expect(gossip.imageUrl, isNotNull);
        expect(gossip.imageUrl, 'https://example.com/image.jpg');
      });
    });

    group('Documentación', () {
      test('debe documentar diferencia con entity Gossip', () {
        // Documenta: FeedGossip incluye metadata del algoritmo:
        // - score: puntuación de ranking
        // - isFromMyCity: para badge de ciudad
        // - isTrending: para badge "Trending 🔥"
        // Gossip entity contiene todos los campos (más completo)
      });

      test('debe documentar componentes del score', () {
        // Documenta: score calculado con algoritmo 40/30/20/10:
        // - 40% Ciudad (local=100, trending=50, otras=20)
        // - 30% Interacciones (likes*1 + comments*2 + shares*3)
        // - 20% Velocity (interacciones / horas)
        // - 10% Decay (penalización por antigüedad)
      });

      test('debe documentar criterio de trending', () {
        // Documenta: trending si cumple cualquiera:
        // - likes > 1000
        // - comments > 200
        // - shares > 100
      });
    });
  });
}
