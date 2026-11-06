import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../../../../fixtures/mocks/mock_gossip_data_source.dart';
import 'package:chismes/features/gossip/domain/entities/gossip_query.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/moderation_decision.dart';
import 'package:chismes/core/id/id_generator.dart';
import 'package:chismes/features/gossip/domain/services/content_moderator.dart';
import 'package:chismes/core/error/app_exception.dart';

import 'mock_gossip_remote_data_source_test.mocks.dart';

@GenerateMocks([IdGenerator, ContentModerator])
void main() {
  group('MockGossipRemoteDataSource', () {
    late MockGossipRemoteDataSource dataSource;
    late MockIdGenerator mockIdGenerator;
    late MockContentModerator mockContentModerator;

    setUp(() {
      mockIdGenerator = MockIdGenerator();
      mockContentModerator = MockContentModerator();
      dataSource = MockGossipRemoteDataSource(
        idGenerator: mockIdGenerator,
        contentModerator: mockContentModerator,
      );

      // Setup default moderation decision
      when(mockContentModerator.moderate(any)).thenAnswer(
        (_) async => ModerationDecision(verdict: ModerationVerdict.publish),
      );

      when(mockIdGenerator.generate()).thenReturn('test-id-123');
    });

    test('getGossips debe retornar todos los gossips por defecto', () async {
      // Arrange
      final query = GossipQuery();

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.length, 2); // Los 2 gossips mock iniciales
    });

    test('getGossips debe filtrar por countryId', () async {
      // Arrange
      final query = GossipQuery(countryId: '1');

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.every((m) => m.countryId == '1'), isTrue);
    });

    test('getGossips debe filtrar por cityId', () async {
      // Arrange
      final query = GossipQuery(cityId: '1');

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.length, 1);
      expect(result.first.cityId, '1');
    });

    test('getGossips debe aplicar límite', () async {
      // Arrange
      final query = GossipQuery(limit: 1);

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.length, 1);
    });

    test('getGossips debe ordenar descendente por defecto', () async {
      // Arrange
      final query = GossipQuery(orderBy: 'createdAt', descending: true);

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.length, 2);
      // El más reciente (id='1') debe estar primero
      expect(result.first.id, '1');
    });

    test('getGossips debe ordenar ascendente cuando descending es false', () async {
      // Arrange
      final query = GossipQuery(orderBy: 'createdAt', descending: false);

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.length, 2);
      // El más antiguo (id='2') debe estar primero
      expect(result.first.id, '2');
    });

    test('create debe crear un gossip con moderación aprobada', () async {
      // Arrange
      final input = CreateGossipInput(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Nuevo chisme',
        content: 'Contenido del nuevo chisme',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'key-123',
      );

      // Act
      final result = await dataSource.createWithImage(input, null);

      // Assert
      expect(result.id, 'test-id-123');
      expect(result.subject, 'Nuevo chisme');
      expect(result.status, 'published');
      expect(result.moderationStatus, 'approved');
      expect(result.visibility, 'public');
      verify(mockIdGenerator.generate()).called(1);
      verify(mockContentModerator.moderate(input)).called(1);
    });

    test('create debe lanzar excepción cuando moderación rechaza', () async {
      // Arrange
      when(mockContentModerator.moderate(any)).thenAnswer(
        (_) async => ModerationDecision(
          verdict: ModerationVerdict.reject,
          reasons: [ModerationReason.potentialSpam],
        ),
      );

      final input = CreateGossipInput(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Spam',
        content: 'Contenido spam',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'key-456',
      );

      // Act & Assert
      expect(
        () => dataSource.createWithImage(input, null),
        throwsA(isA<ValidationException>()),
      );
    });

    test('create debe agregar el nuevo gossip al inicio de la lista', () async {
      // Arrange
      final input = CreateGossipInput(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Nuevo',
        content: 'Contenido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'key-789',
      );

      final initialCount = (await dataSource.getGossips(GossipQuery())).length;

      // Act
      await dataSource.createWithImage(input, null);
      final result = await dataSource.getGossips(GossipQuery());

      // Assert
      expect(result.length, initialCount + 1);
      expect(result.first.subject, 'Nuevo');
    });

    test('getGossips debe filtrar por status', () async {
      // Arrange
      final query = GossipQuery(status: GossipStatus.published);

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.every((m) => m.status == 'published'), isTrue);
    });

    test('getGossips debe filtrar por visibility', () async {
      // Arrange
      final query = GossipQuery(visibility: GossipVisibility.public);

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.every((m) => m.visibility == 'public'), isTrue);
    });

    test('create con moderación review debe crear gossip privado', () async {
      // Arrange
      when(mockContentModerator.moderate(any)).thenAnswer(
        (_) async => ModerationDecision(
          verdict: ModerationVerdict.review,
          reasons: [ModerationReason.potentialProfanity],
        ),
      );

      final input = CreateGossipInput(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Para review',
        content: 'Contenido dudoso',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'key-review',
      );

      // Act
      final result = await dataSource.createWithImage(input, null);

      // Assert
      expect(result.status, 'draft');
      expect(result.moderationStatus, 'pending');
      expect(result.visibility, 'private');
    });

    test('getGossips debe ordenar por subject', () async {
      // Arrange
      final query = GossipQuery(orderBy: 'subject', descending: false);

      // Act
      final result = await dataSource.getGossips(query);

      // Assert - Verificar que está ordenado alfabéticamente
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].subject.compareTo(result[i + 1].subject) <= 0,
          isTrue,
        );
      }
    });

    test('getGossips debe filtrar por regionId', () async {
      // Arrange
      final query = GossipQuery(regionId: '1');

      // Act
      final result = await dataSource.getGossips(query);

      // Assert
      expect(result.every((m) => m.regionId == '1'), isTrue);
    });
  });
}
