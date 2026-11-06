import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

void main() {
  group('GossipModel', () {
    final validJsonSnakeCase = {
      'id': '123',
      'country_id': 'CO',
      'region_id': 'ANT',
      'city_id': 'MED',
      'subject': 'Test Subject',
      'content': 'Test Content',
      'audio_url': null,
      'image_url': null,
      'published_as': 'anonymous',
      'status': 'published',
      'moderation_status': 'approved',
      'report_count': 0,
      'view_count': 0,
      'deleted_at': null,
      'deleted_by': null,
      'visibility': 'public',
      'created_at': '2024-01-01T00:00:00.000Z',
      'created_by': 'user-123',
      'modified_at': null,
      'modified_by': null,
    };

    test('fromJson debe parsear JSON snake_case correctamente', () {
      // Act
      final model = GossipModel.fromJson(validJsonSnakeCase);

      // Assert
      expect(model.id, '123');
      expect(model.countryId, 'CO');
      expect(model.regionId, 'ANT');
      expect(model.cityId, 'MED');
      expect(model.subject, 'Test Subject');
      expect(model.content, 'Test Content');
      expect(model.publishedAs, 'anonymous');
      expect(model.status, 'published');
      expect(model.moderationStatus, 'approved');
      expect(model.visibility, 'public');
      expect(model.createdAt, '2024-01-01T00:00:00.000Z');
      expect(model.createdBy, 'user-123');
    });

    test('fromJson debe lanzar FormatException cuando falta id', () {
      // Arrange
      final invalidJson = Map<String, dynamic>.from(validJsonSnakeCase);
      invalidJson.remove('id');

      // Act & Assert
      expect(
        () => GossipModel.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson debe lanzar FormatException cuando id tiene tipo incorrecto', () {
      // Arrange
      final invalidJson = Map<String, dynamic>.from(validJsonSnakeCase);
      invalidJson['id'] = 123;

      // Act & Assert
      expect(
        () => GossipModel.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson debe parsear campos opcionales null', () {
      // Act
      final model = GossipModel.fromJson(validJsonSnakeCase);

      // Assert
      expect(model.audioUrl, isNull);
      expect(model.imageUrl, isNull);
      expect(model.deletedAt, isNull);
      expect(model.deletedBy, isNull);
      expect(model.modifiedAt, isNull);
      expect(model.modifiedBy, isNull);
    });

    test('toJson debe serializar a snake_case correctamente', () {
      // Arrange
      final model = GossipModel.fromJson(validJsonSnakeCase);

      // Act
      final json = model.toJson();

      // Assert - toJson() ahora usa snake_case para consistencia con backend
      expect(json['id'], '123');
      expect(json['country_id'], 'CO');
      expect(json['region_id'], 'ANT');
      expect(json['city_id'], 'MED');
      expect(json['subject'], 'Test Subject');
      expect(json['published_as'], 'anonymous');
      expect(json['status'], 'published');
      expect(json['created_at'], '2024-01-01T00:00:00.000Z');
    });

    test('fromEntity debe convertir Entity a Model', () {
      // Arrange
      final entity = Gossip(
        id: '456',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Entity Subject',
        content: 'Entity Content',
        audioUrl: 'https://example.com/audio.mp3',
        imageUrl: 'https://example.com/image.jpg',
        publishedAs: PublishAs.profile,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 5,
        viewCount: 100,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'user-456',
        modifiedAt: DateTime(2024, 1, 2),
        modifiedBy: 'user-789',
      );

      // Act
      final model = GossipModel.fromEntity(entity);

      // Assert
      expect(model.id, '456');
      expect(model.subject, 'Entity Subject');
      expect(model.publishedAs, 'profile');
      expect(model.status, 'published');
      expect(model.createdAt, '2024-01-01T00:00:00.000');
      expect(model.modifiedAt, '2024-01-02T00:00:00.000');
    });

    test('toEntity debe convertir Model a Entity', () {
      // Arrange
      final model = GossipModel.fromJson(validJsonSnakeCase);

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity.id, '123');
      expect(entity.countryId, 'CO');
      expect(entity.subject, 'Test Subject');
      expect(entity.publishedAs, PublishAs.anonymous);
      expect(entity.status, GossipStatus.published);
      expect(entity.moderationStatus, ModerationStatus.approved);
      expect(entity.visibility, GossipVisibility.public);
      expect(entity.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('toEntity debe lanzar FormatException con publishedAs inválido', () {
      // Arrange
      final jsonWithInvalidEnum = Map<String, dynamic>.from(validJsonSnakeCase);
      jsonWithInvalidEnum['published_as'] = 'invalid_value';
      final model = GossipModel.fromJson(jsonWithInvalidEnum);

      // Act & Assert
      expect(
        () => model.toEntity(),
        throwsA(isA<FormatException>()),
      );
    });

    test('round trip: Entity → Model → JSON → Model → Entity', () {
      // Arrange
      final originalEntity = Gossip(
        id: '789',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Round Trip',
        content: 'Test',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 10,
        viewCount: 200,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'user-789',
        modifiedAt: null,
        modifiedBy: null,
      );

      // Act
      final model1 = GossipModel.fromEntity(originalEntity);
      final json = model1.toJson();
      final model2 = GossipModel.fromJson(json);
      final finalEntity = model2.toEntity();

      // Assert
      expect(finalEntity.id, originalEntity.id);
      expect(finalEntity.subject, originalEntity.subject);
      expect(finalEntity.publishedAs, originalEntity.publishedAs);
      expect(finalEntity.status, originalEntity.status);
      expect(finalEntity.createdAt.year, originalEntity.createdAt.year);
    });
  });

  group('GossipModel - Validaciones adicionales', () {
    final validJson = {
      'id': '123',
      'country_id': 'CO',
      'region_id': 'ANT',
      'city_id': 'MED',
      'subject': 'Test',
      'content': 'Content',
      'published_as': 'anonymous',
      'status': 'published',
      'moderation_status': 'approved',
      'visibility': 'public',
      'created_at': '2024-01-01T00:00:00.000Z',
      'created_by': 'user-123',
    };

    test('fromJson debe lanzar FormatException cuando falta subject', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson.remove('subject');
      
      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException cuando falta content', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson.remove('content');
      
      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException cuando falta status', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson.remove('status');
      
      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en audioUrl', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['audio_url'] = 123; // int instead of String
      
      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en imageUrl', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['image_url'] = true; // bool instead of String
      
      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en reportedCount', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['report_count'] = 'not-a-number';
      
      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('toEntity debe lanzar FormatException con status inválido', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['status'] = 'invalid_status';
      final model = GossipModel.fromJson(invalidJson);
      
      expect(() => model.toEntity(), throwsA(isA<FormatException>()));
    });

    test('toEntity debe lanzar FormatException con moderationStatus inválido', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['moderation_status'] = 'invalid_moderation';
      final model = GossipModel.fromJson(invalidJson);
      
      expect(() => model.toEntity(), throwsA(isA<FormatException>()));
    });

    test('toEntity debe lanzar FormatException con visibility inválido', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['visibility'] = 'invalid_visibility';
      final model = GossipModel.fromJson(invalidJson);
      
      expect(() => model.toEntity(), throwsA(isA<FormatException>()));
    });

    test('fromJson debe rechazar camelCase (solo snake_case)', () {
      // Test actualizado (2026-10-22): fromJson() ahora SOLO acepta snake_case
      // para consistencia con toJson() y backend Supabase
      final camelCaseJson = {
        'id': '456',
        'countryId': 'CO',    // ❌ camelCase (rechazado)
        'regionId': 'ANT',    // ❌ camelCase (rechazado)
        'cityId': 'MED',      // ❌ camelCase (rechazado)
        'subject': 'Test',
        'content': 'Content',
        'publishedAs': 'profile',      // ❌ camelCase (rechazado)
        'status': 'published',
        'moderationStatus': 'approved', // ❌ camelCase (rechazado)
        'visibility': 'public',
        'createdAt': '2024-01-01T00:00:00.000Z', // ❌ camelCase (rechazado)
        'createdBy': 'user-456',                 // ❌ camelCase (rechazado)
      };

      // Act & Assert: Debe fallar por falta de country_id (snake_case)
      expect(
        () => GossipModel.fromJson(camelCaseJson),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('country_id'),
        )),
      );
    });

    test('toEntity debe manejar todos los GossipStatus', () {
      final statuses = ['draft', 'published', 'hidden', 'deleted'];
      final expected = [
        GossipStatus.draft,
        GossipStatus.published,
        GossipStatus.hidden,
        GossipStatus.deleted,
      ];

      for (var i = 0; i < statuses.length; i++) {
        final json = Map<String, dynamic>.from(validJson);
        json['status'] = statuses[i];
        final model = GossipModel.fromJson(json);
        final entity = model.toEntity();
        
        expect(entity.status, expected[i]);
      }
    });

    test('toEntity debe manejar todos los ModerationStatus', () {
      final statuses = ['pending', 'approved', 'rejected', 'flagged'];
      final expected = [
        ModerationStatus.pending,
        ModerationStatus.approved,
        ModerationStatus.rejected,
        ModerationStatus.flagged,
      ];

      for (var i = 0; i < statuses.length; i++) {
        final json = Map<String, dynamic>.from(validJson);
        json['moderation_status'] = statuses[i];
        final model = GossipModel.fromJson(json);
        final entity = model.toEntity();
        
        expect(entity.moderationStatus, expected[i]);
      }
    });

    test('toEntity debe manejar todos los GossipVisibility', () {
      final visibilities = ['public', 'private', 'followers'];
      final expected = [
        GossipVisibility.public,
        GossipVisibility.private,
        GossipVisibility.followers,
      ];

      for (var i = 0; i < visibilities.length; i++) {
        final json = Map<String, dynamic>.from(validJson);
        json['visibility'] = visibilities[i];
        final model = GossipModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.visibility, expected[i]);
      }
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en viewCount', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['view_count'] = 'not-a-number'; // String instead of int

      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en deletedAt', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['deleted_at'] = 123; // int instead of String

      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en deletedBy', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['deleted_by'] = true; // bool instead of String

      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en modifiedAt', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['modified_at'] = ['array']; // array instead of String

      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en modifiedBy', () {
      final invalidJson = Map<String, dynamic>.from(validJson);
      invalidJson['modified_by'] = {'object': 'value'}; // object instead of String

      expect(() => GossipModel.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });

    test('fromJson debe aceptar viewCount como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['view_count'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.viewCount, 0); // Defaults to 0
    });

    test('fromJson debe aceptar deletedAt como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['deleted_at'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.deletedAt, isNull);
    });

    test('fromJson debe aceptar deletedBy como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['deleted_by'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.deletedBy, isNull);
    });

    test('fromJson debe aceptar modifiedAt como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['modified_at'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.modifiedAt, isNull);
    });

    test('fromJson debe aceptar modifiedBy como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['modified_by'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.modifiedBy, isNull);
    });

    test('fromJson debe parsear viewCount correctamente cuando es int válido', () {
      final jsonWithViewCount = Map<String, dynamic>.from(validJson);
      jsonWithViewCount['view_count'] = 42;

      final model = GossipModel.fromJson(jsonWithViewCount);

      expect(model.viewCount, 42);
    });

    test('fromJson debe parsear deletedAt correctamente cuando es String válido', () {
      final jsonWithDeletedAt = Map<String, dynamic>.from(validJson);
      jsonWithDeletedAt['deleted_at'] = '2024-12-31T23:59:59.000Z';

      final model = GossipModel.fromJson(jsonWithDeletedAt);

      expect(model.deletedAt, '2024-12-31T23:59:59.000Z');
    });

    test('fromJson debe parsear deletedBy correctamente cuando es String válido', () {
      final jsonWithDeletedBy = Map<String, dynamic>.from(validJson);
      jsonWithDeletedBy['deleted_by'] = 'user-999';

      final model = GossipModel.fromJson(jsonWithDeletedBy);

      expect(model.deletedBy, 'user-999');
    });

    test('fromJson debe parsear modifiedAt correctamente cuando es String válido', () {
      final jsonWithModifiedAt = Map<String, dynamic>.from(validJson);
      jsonWithModifiedAt['modified_at'] = '2024-06-15T12:00:00.000Z';

      final model = GossipModel.fromJson(jsonWithModifiedAt);

      expect(model.modifiedAt, '2024-06-15T12:00:00.000Z');
    });

    test('fromJson debe parsear modifiedBy correctamente cuando es String válido', () {
      final jsonWithModifiedBy = Map<String, dynamic>.from(validJson);
      jsonWithModifiedBy['modified_by'] = 'user-777';

      final model = GossipModel.fromJson(jsonWithModifiedBy);

      expect(model.modifiedBy, 'user-777');
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en thumbnailUrl', () {
      final jsonWithInvalidType = Map<String, dynamic>.from(validJson);
      jsonWithInvalidType['thumbnail_url'] = 123; // int en lugar de String

      expect(
        () => GossipModel.fromJson(jsonWithInvalidType),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('thumbnail_url'),
        )),
      );
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en storagePath', () {
      final jsonWithInvalidType = Map<String, dynamic>.from(validJson);
      jsonWithInvalidType['storage_path'] = 456; // int en lugar de String

      expect(
        () => GossipModel.fromJson(jsonWithInvalidType),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('storage_path'),
        )),
      );
    });

    test('fromJson debe lanzar FormatException con tipo incorrecto en thumbnailStoragePath', () {
      final jsonWithInvalidType = Map<String, dynamic>.from(validJson);
      jsonWithInvalidType['thumbnail_storage_path'] = true; // bool en lugar de String

      expect(
        () => GossipModel.fromJson(jsonWithInvalidType),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('thumbnail_storage_path'),
        )),
      );
    });

    test('fromJson debe aceptar thumbnailUrl como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['thumbnail_url'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.thumbnailUrl, isNull);
    });

    test('fromJson debe aceptar storagePath como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['storage_path'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.storagePath, isNull);
    });

    test('fromJson debe aceptar thumbnailStoragePath como null', () {
      final jsonWithNull = Map<String, dynamic>.from(validJson);
      jsonWithNull['thumbnail_storage_path'] = null;

      final model = GossipModel.fromJson(jsonWithNull);

      expect(model.thumbnailStoragePath, isNull);
    });

    test('toJson debe incluir todos los campos opcionales cuando están presentes', () {
      final model = GossipModel(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        audioUrl: 'https://example.com/audio.mp3',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        storagePath: 'storage/path/image.jpg',
        thumbnailStoragePath: 'storage/path/thumb.jpg',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        reportedCount: 5,
        viewCount: 100,
        deletedAt: '2024-12-31T23:59:59.000Z',
        deletedBy: 'user-999',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-123',
        modifiedAt: '2024-06-15T12:00:00.000Z',
        modifiedBy: 'user-456',
      );

      final json = model.toJson();

      expect(json['audio_url'], 'https://example.com/audio.mp3');
      expect(json['image_url'], 'https://example.com/image.jpg');
      expect(json['thumbnail_url'], 'https://example.com/thumb.jpg');
      expect(json['storage_path'], 'storage/path/image.jpg');
      expect(json['thumbnail_storage_path'], 'storage/path/thumb.jpg');
      expect(json['deleted_at'], '2024-12-31T23:59:59.000Z');
      expect(json['deleted_by'], 'user-999');
      expect(json['modified_at'], '2024-06-15T12:00:00.000Z');
      expect(json['modified_by'], 'user-456');
    });

    test('toJson debe incluir campos opcionales como null cuando no están presentes', () {
      final model = GossipModel(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        thumbnailUrl: null,
        storagePath: null,
        thumbnailStoragePath: null,
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-123',
        deletedAt: null,
        deletedBy: null,
        modifiedAt: null,
        modifiedBy: null,
      );

      final json = model.toJson();

      expect(json['audio_url'], isNull);
      expect(json['image_url'], isNull);
      expect(json['thumbnail_url'], isNull);
      expect(json['storage_path'], isNull);
      expect(json['thumbnail_storage_path'], isNull);
      expect(json['deleted_at'], isNull);
      expect(json['deleted_by'], isNull);
      expect(json['modified_at'], isNull);
      expect(json['modified_by'], isNull);
    });

    test('fromEntity debe manejar todos los campos opcionales como null', () {
      final entity = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        thumbnailUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      final model = GossipModel.fromEntity(entity);

      expect(model.audioUrl, isNull);
      expect(model.imageUrl, isNull);
      expect(model.thumbnailUrl, isNull);
      expect(model.storagePath, isNull);
      expect(model.thumbnailStoragePath, isNull);
      expect(model.deletedAt, isNull);
      expect(model.deletedBy, isNull);
      expect(model.modifiedAt, isNull);
      expect(model.modifiedBy, isNull);
    });

    test('fromEntity debe convertir DateTime opcionales a ISO8601', () {
      final entity = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        publishedAs: PublishAs.profile,
        status: GossipStatus.draft,
        moderationStatus: ModerationStatus.pending,
        reportedCount: 3,
        viewCount: 50,
        deletedAt: DateTime.parse('2024-12-31T23:59:59.000Z'),
        deletedBy: 'admin-789',
        visibility: GossipVisibility.followers,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        createdBy: 'user-123',
        modifiedAt: DateTime.parse('2024-06-15T12:00:00.000Z'),
        modifiedBy: 'user-456',
      );

      final model = GossipModel.fromEntity(entity);

      expect(model.deletedAt, '2024-12-31T23:59:59.000Z');
      expect(model.deletedBy, 'admin-789');
      expect(model.modifiedAt, '2024-06-15T12:00:00.000Z');
      expect(model.modifiedBy, 'user-456');
      expect(model.createdAt, '2024-01-01T00:00:00.000Z');
    });

    test('fromEntity debe convertir enums correctamente', () {
      final entity = Gossip(
        id: '123',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        publishedAs: PublishAs.profile,
        status: GossipStatus.hidden,
        moderationStatus: ModerationStatus.flagged,
        visibility: GossipVisibility.private,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        createdBy: 'user-123',
      );

      final model = GossipModel.fromEntity(entity);

      expect(model.publishedAs, 'profile');
      expect(model.status, 'hidden');
      expect(model.moderationStatus, 'flagged');
      expect(model.visibility, 'private');
    });
  });
}
