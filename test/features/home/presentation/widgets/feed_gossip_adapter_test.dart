import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/widgets/feed_gossip_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper para crear FeedGossip en tests
FeedGossip _createFeedGossip({
  String id = 'test-id',
  String subject = 'Test Subject',
  String content = 'Test content',
  String cityId = 'city-123',
  String? imageUrl,
  String publishedAs = 'profile',
  DateTime? createdAt,
  String? createdBy = 'user-123',
  int likes = 10,
  int comments = 5,
  int shares = 2,
  double score = 50.0,
  bool isTrending = false,
  bool? isFromMyCity = true,
}) {
  return FeedGossip(
    id: id,
    subject: subject,
    content: content,
    cityId: cityId,
    imageUrl: imageUrl,
    publishedAs: publishedAs,
    createdAt: createdAt ?? DateTime(2024, 1, 15),
    createdBy: createdBy,
    likes: likes,
    comments: comments,
    shares: shares,
    score: score,
    isTrending: isTrending,
    isFromMyCity: isFromMyCity,
  );
}

void main() {
  group('FeedGossipAdapter', () {
    group('toGossip', () {
      test('debe convertir FeedGossip completo a Gossip', () {
        // Arrange
        final feedGossip = _createFeedGossip(
          id: 'gossip-123',
          subject: 'Test Subject',
          content: 'Test content here',
          cityId: 'city-456',
          imageUrl: 'https://example.com/image.jpg',
          createdBy: 'user-789',
        );

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result, isA<Gossip>());
        expect(result.id, 'gossip-123');
        expect(result.subject, 'Test Subject');
        expect(result.content, 'Test content here');
        expect(result.cityId, 'city-456');
        expect(result.imageUrl, 'https://example.com/image.jpg');
        expect(result.createdBy, 'user-789');
      });

      test('debe mapear campos directos correctamente', () {
        // Arrange
        final feedGossip = _createFeedGossip(
          id: 'id-1',
          subject: 'Subject 1',
          content: 'Content 1',
          cityId: 'city-1',
          imageUrl: null,
          createdBy: 'user-1',
        );

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert - campos directos
        expect(result.id, feedGossip.id);
        expect(result.subject, feedGossip.subject);
        expect(result.content, feedGossip.content);
        expect(result.cityId, feedGossip.cityId);
        expect(result.imageUrl, feedGossip.imageUrl);
        expect(result.createdAt, feedGossip.createdAt);
        expect(result.createdBy, feedGossip.createdBy);
      });

      test('debe asignar valores por defecto a campos no disponibles', () {
        // Arrange
        final feedGossip = _createFeedGossip();

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert - valores por defecto
        expect(result.countryId, 'unknown');
        expect(result.regionId, 'unknown');
        expect(result.status, GossipStatus.published);
        expect(result.moderationStatus, ModerationStatus.approved);
        expect(result.reportedCount, 0);
        expect(result.viewCount, 0);
        expect(result.visibility, GossipVisibility.public);
      });

      test('debe mapear publishedAs "anonymous" a PublishAs.anonymous', () {
        // Arrange
        final feedGossip = _createFeedGossip(publishedAs: 'anonymous');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.publishedAs, PublishAs.anonymous);
      });

      test('debe mapear publishedAs "profile" a PublishAs.profile', () {
        // Arrange
        final feedGossip = _createFeedGossip(publishedAs: 'profile');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.publishedAs, PublishAs.profile);
      });

      test('debe mapear cualquier otro publishedAs a PublishAs.profile', () {
        // Arrange
        final feedGossip = _createFeedGossip(publishedAs: 'unknown_value');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert - default es profile cuando no es 'anonymous'
        expect(result.publishedAs, PublishAs.profile);
      });

      test('debe manejar imageUrl null', () {
        // Arrange
        final feedGossip = _createFeedGossip(imageUrl: null);

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.imageUrl, isNull);
      });

      test('debe manejar imageUrl presente', () {
        // Arrange
        const imageUrl = 'https://example.com/image.jpg';
        final feedGossip = _createFeedGossip(imageUrl: imageUrl);

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.imageUrl, imageUrl);
      });

      test('debe manejar createdBy null usando fallback "anonymous"', () {
        // Arrange
        final feedGossip = _createFeedGossip(createdBy: null);

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.createdBy, 'anonymous');
      });

      test('debe preservar createdBy cuando está presente', () {
        // Arrange
        const userId = 'user-123';
        final feedGossip = _createFeedGossip(createdBy: userId);

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.createdBy, userId);
      });

      test('debe asignar status como published', () {
        // Arrange
        final feedGossip = _createFeedGossip();

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.status, GossipStatus.published);
      });

      test('debe asignar moderationStatus como approved', () {
        // Arrange
        final feedGossip = _createFeedGossip();

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.moderationStatus, ModerationStatus.approved);
      });

      test('debe asignar contadores en 0', () {
        // Arrange
        final feedGossip = _createFeedGossip();

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.reportedCount, 0);
        expect(result.viewCount, 0);
      });

      test('debe asignar visibility como public', () {
        // Arrange
        final feedGossip = _createFeedGossip();

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.visibility, GossipVisibility.public);
      });

      test('debe asignar countryId y regionId como "unknown"', () {
        // Arrange
        final feedGossip = _createFeedGossip();

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.countryId, 'unknown');
        expect(result.regionId, 'unknown');
      });

      test('debe mapear publishedAs case-sensitive', () {
        // Arrange
        final feedGossip = _createFeedGossip(publishedAs: 'Anonymous'); // Mayúscula

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert - no es exactamente 'anonymous', usa default
        expect(result.publishedAs, PublishAs.profile);
      });
    });

    group('Edge cases', () {
      test('debe manejar subject vacío', () {
        // Arrange
        final feedGossip = _createFeedGossip(subject: '');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.subject, '');
      });

      test('debe manejar content vacío', () {
        // Arrange
        final feedGossip = _createFeedGossip(content: '');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.content, '');
      });

      test('debe manejar cityId vacío', () {
        // Arrange
        final feedGossip = _createFeedGossip(cityId: '');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.cityId, '');
      });

      test('debe manejar publishedAs vacío', () {
        // Arrange
        final feedGossip = _createFeedGossip(publishedAs: '');

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert - string vacío no es 'anonymous', usa default
        expect(result.publishedAs, PublishAs.profile);
      });

      test('debe manejar fechas antiguas', () {
        // Arrange
        final oldDate = DateTime(2000, 1, 1);
        final feedGossip = _createFeedGossip(createdAt: oldDate);

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.createdAt, oldDate);
      });

      test('debe manejar fechas futuras', () {
        // Arrange
        final futureDate = DateTime(2030, 12, 31);
        final feedGossip = _createFeedGossip(createdAt: futureDate);

        // Act
        final result = FeedGossipAdapter.toGossip(feedGossip);

        // Assert
        expect(result.createdAt, futureDate);
      });
    });

    group('Integration', () {
      test('debe generar Gossip válido para GossipCard', () {
        // Arrange
        final feedGossip = _createFeedGossip(
          id: 'gossip-id',
          subject: 'Test Gossip',
          content: 'This is test content',
          cityId: 'city-123',
          imageUrl: 'https://example.com/image.jpg',
          createdBy: 'user-456',
        );

        // Act
        final gossip = FeedGossipAdapter.toGossip(feedGossip);

        // Assert - todos los campos necesarios están presentes
        expect(gossip.id, isNotEmpty);
        expect(gossip.subject, isNotEmpty);
        expect(gossip.content, isNotEmpty);
        expect(gossip.cityId, isNotEmpty);
        expect(gossip.status, GossipStatus.published);
        expect(gossip.createdBy, isNotEmpty);
      });

      test('debe convertir múltiples FeedGossips de forma consistente', () {
        // Arrange
        final feedGossips = [
          _createFeedGossip(
            id: 'id-1',
            publishedAs: 'anonymous',
            createdBy: 'user-1',
          ),
          _createFeedGossip(
            id: 'id-2',
            publishedAs: 'profile',
            createdBy: 'user-2',
          ),
        ];

        // Act
        final gossips = feedGossips.map((f) => FeedGossipAdapter.toGossip(f)).toList();

        // Assert
        expect(gossips.length, 2);
        expect(gossips[0].status, GossipStatus.published);
        expect(gossips[1].status, GossipStatus.published);
        expect(gossips[0].publishedAs, PublishAs.anonymous);
        expect(gossips[1].publishedAs, PublishAs.profile);
      });
    });
  });
}
