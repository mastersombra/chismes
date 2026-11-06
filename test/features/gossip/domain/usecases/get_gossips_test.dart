import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/repositories/gossip_repository.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/gossip_query.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';

import 'get_gossips_test.mocks.dart';

@GenerateMocks([GossipRepository])
void main() {
  setUpAll(() {
    // Provide dummy values for mockito
    provideDummy<Result<Failure, List<Gossip>>>(Result.success(const []));
  });

  late GetGossips useCase;
  late MockGossipRepository mockRepository;

  setUp(() {
    mockRepository = MockGossipRepository();
    useCase = GetGossips(repository: mockRepository);
  });

  group('GetGossips', () {
    final validGossip = Gossip(
      id: '1',
      countryId: '1',
      regionId: '1',
      cityId: '1',
      subject: 'Test',
      content: 'Content',
      audioUrl: null,
      imageUrl: null,
      publishedAs: PublishAs.anonymous,
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      reportedCount: 0,
      viewCount: 0,
      deletedAt: null,
      deletedBy: null,
      visibility: GossipVisibility.public,
      createdAt: DateTime.now(),
      createdBy: 'user-123',
      modifiedAt: null,
      modifiedBy: null,
    );

    test('debe usar query por defecto cuando no se provee uno', () async {
      // Arrange
      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([validGossip]));

      // Act
      await useCase.call();

      // Assert
      final captured = verify(mockRepository.getGossips(captureAny)).captured;
      expect(captured.length, 1);

      final query = captured[0] as GossipQuery;
      expect(query, equals(GossipQuery.defaultPublic()));
    });

    test('debe usar el query provisto', () async {
      // Arrange
      final customQuery = GossipQuery(
        countryId: '1',
        regionId: '1',
        cityId: '1',
      );

      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([validGossip]));

      // Act
      await useCase.call(customQuery);

      // Assert
      verify(mockRepository.getGossips(customQuery)).called(1);
    });

    test('debe retornar gossips válidos sin filtrar', () async {
      // Arrange
      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([validGossip]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, [validGossip]);
    });

    test('debe filtrar gossips con status diferente a published', () async {
      // Arrange
      final draftGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.draft, // ❌ No publicado
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([draftGossip, validGossip]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.status, GossipStatus.published);
    });

    test('debe filtrar gossips con moderationStatus diferente a approved', () async {
      // Arrange
      final pendingGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.pending, // ❌ No aprobado
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([pendingGossip, validGossip]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.moderationStatus, ModerationStatus.approved);
    });

    test('debe filtrar gossips con visibility diferente a public', () async {
      // Arrange
      final privateGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.private, // ❌ No público
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([privateGossip, validGossip]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.visibility, GossipVisibility.public);
    });

    test('debe filtrar múltiples gossips inválidos', () async {
      // Arrange
      final draftGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.draft, // Inválido
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      final pendingGossip = Gossip(
        id: '2',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.pending, // Inválido
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      final hiddenGossip = Gossip(
        id: '3',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.hidden, // Inválido
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      final validGossip2 = Gossip(
        id: '4',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.getGossips(any)).thenAnswer(
        (_) async => Result.success([
          draftGossip,
          validGossip,
          pendingGossip,
          hiddenGossip,
          validGossip2,
        ]),
      );

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 2); // Solo los 2 válidos
      expect(
        result.successValue?.every((g) =>
            g.status == GossipStatus.published &&
            g.moderationStatus == ModerationStatus.approved &&
            g.visibility == GossipVisibility.public),
        isTrue,
      );
    });

    test('debe retornar lista vacía si no hay gossips válidos', () async {
      // Arrange
      final invalidGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.draft, // Inválido
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([invalidGossip]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe retornar lista vacía si repository retorna lista vacía', () async {
      // Arrange
      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([]));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe propagar failure del repository', () async {
      // Arrange
      final failure = const NetworkFailure(code: ErrorCode.networkError);
      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.failure(failure));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, equals(failure));
    });

    test('debe llamar repository solo una vez', () async {
      // Arrange
      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([validGossip]));

      // Act
      await useCase.call();

      // Assert
      verify(mockRepository.getGossips(any)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('debe aplicar filtrado de seguridad incluso si servidor envía data inválida', () async {
      // Arrange - Simula un bug del servidor que envía gossips inválidos
      final serverBugGossip = Gossip(
        id: '99',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.rejected, // Bug del servidor
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.getGossips(any))
          .thenAnswer((_) async => Result.success([serverBugGossip, validGossip]));

      // Act
      final result = await useCase.call();

      // Assert - El filtro local debe proteger contra bugs del servidor
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.id, validGossip.id);
    });
  });
}
