import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

void main() {
  group('Gossip Entity', () {
    final now = DateTime(2024, 1, 1);

    test('debe crear instancia con todos los campos requeridos', () {
      // Act
      final gossip = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Tema de prueba',
        content: 'Contenido de prueba',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
      );

      // Assert
      expect(gossip.id, '123');
      expect(gossip.countryId, 'CO');
      expect(gossip.regionId, 'ANT');
      expect(gossip.cityId, 'MED');
      expect(gossip.subject, 'Tema de prueba');
      expect(gossip.content, 'Contenido de prueba');
      expect(gossip.publishedAs, PublishAs.anonymous);
      expect(gossip.status, GossipStatus.published);
      expect(gossip.moderationStatus, ModerationStatus.approved);
      expect(gossip.visibility, GossipVisibility.public);
      expect(gossip.createdAt, now);
      expect(gossip.createdBy, 'user-123');
    });

    test('debe tener valores por defecto para reportedCount y viewCount', () {
      // Act
      final gossip = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
      );

      // Assert
      expect(gossip.reportedCount, 0);
      expect(gossip.viewCount, 0);
    });

    test('debe permitir valores opcionales null', () {
      // Act
      final gossip = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      // Assert
      expect(gossip.audioUrl, isNull);
      expect(gossip.imageUrl, isNull);
      expect(gossip.deletedAt, isNull);
      expect(gossip.deletedBy, isNull);
      expect(gossip.modifiedAt, isNull);
      expect(gossip.modifiedBy, isNull);
    });

    test('debe permitir valores opcionales con datos', () {
      // Arrange
      final modified = DateTime(2024, 1, 2);
      final deleted = DateTime(2024, 1, 3);

      // Act
      final gossip = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        audioUrl: 'https://example.com/audio.mp3',
        imageUrl: 'https://example.com/image.jpg',
        publishedAs: PublishAs.profile,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 5,
        viewCount: 100,
        deletedAt: deleted,
        deletedBy: 'admin-456',
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
        modifiedAt: modified,
        modifiedBy: 'user-789',
      );

      // Assert
      expect(gossip.audioUrl, 'https://example.com/audio.mp3');
      expect(gossip.imageUrl, 'https://example.com/image.jpg');
      expect(gossip.reportedCount, 5);
      expect(gossip.viewCount, 100);
      expect(gossip.deletedAt, deleted);
      expect(gossip.deletedBy, 'admin-456');
      expect(gossip.modifiedAt, modified);
      expect(gossip.modifiedBy, 'user-789');
    });

    test('dos instancias con mismos valores deben ser iguales (Equatable)', () {
      // Arrange
      final gossip1 = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
      );

      final gossip2 = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
      );

      // Assert
      expect(gossip1, equals(gossip2));
      expect(gossip1.hashCode, equals(gossip2.hashCode));
    });

    test('dos instancias con diferentes valores no deben ser iguales', () {
      // Arrange
      final gossip1 = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
      );

      final gossip2 = Gossip(
        id: '456', // ID diferente
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Test',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: now,
        createdBy: 'user-123',
      );

      // Assert
      expect(gossip1, isNot(equals(gossip2)));
      expect(gossip1.hashCode, isNot(equals(gossip2.hashCode)));
    });
  });

  group('PublishAs Enum', () {
    test('debe tener valor "anonymous"', () {
      expect(PublishAs.anonymous.value, 'anonymous');
    });

    test('debe tener valor "profile"', () {
      expect(PublishAs.profile.value, 'profile');
    });
  });

  group('GossipStatus Enum', () {
    test('debe tener valor "draft"', () {
      expect(GossipStatus.draft.value, 'draft');
    });

    test('debe tener valor "published"', () {
      expect(GossipStatus.published.value, 'published');
    });

    test('debe tener valor "hidden"', () {
      expect(GossipStatus.hidden.value, 'hidden');
    });

    test('debe tener valor "deleted"', () {
      expect(GossipStatus.deleted.value, 'deleted');
    });
  });

  group('ModerationStatus Enum', () {
    test('debe tener valor "pending"', () {
      expect(ModerationStatus.pending.value, 'pending');
    });

    test('debe tener valor "approved"', () {
      expect(ModerationStatus.approved.value, 'approved');
    });

    test('debe tener valor "rejected"', () {
      expect(ModerationStatus.rejected.value, 'rejected');
    });

    test('debe tener valor "flagged"', () {
      expect(ModerationStatus.flagged.value, 'flagged');
    });
  });

  group('GossipVisibility Enum', () {
    test('debe tener valor "public"', () {
      expect(GossipVisibility.public.value, 'public');
    });

    test('debe tener valor "private"', () {
      expect(GossipVisibility.private.value, 'private');
    });

    test('debe tener valor "followers"', () {
      expect(GossipVisibility.followers.value, 'followers');
    });
  });
}
