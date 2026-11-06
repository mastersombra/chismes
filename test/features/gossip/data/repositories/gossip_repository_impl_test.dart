import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/data/repositories/gossip_repository_impl.dart';
import 'package:chismes/features/gossip/data/datasources/gossip_remote_data_source.dart';
import 'package:chismes/features/gossip/data/datasources/gossip_local_data_source.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip_query.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/logging/logging.dart';

import 'gossip_repository_impl_test.mocks.dart';

@GenerateMocks([GossipRemoteDataSource, GossipLocalDataSource])
void main() {
  late GossipRepositoryImpl repository;
  late MockGossipRemoteDataSource mockRemoteDataSource;
  late MockGossipLocalDataSource mockLocalDataSource;
  late AppLogger logger;

  setUp(() {
    mockRemoteDataSource = MockGossipRemoteDataSource();
    mockLocalDataSource = MockGossipLocalDataSource();

    // Crear logger para tests
    final mockRemoteLogger = _MockRemoteLogger();
    final mockDeviceInfo = _MockDeviceInfoProvider();
    logger = AppLogger(mockRemoteLogger, mockDeviceInfo);

    repository = GossipRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      logger: logger,
    );
  });

  tearDown(() {
    logger.close();
  });

  group('GossipRepositoryImpl.getGossips', () {
    final query = GossipQuery.defaultPublic();

    final mockModels = [
      GossipModel(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test 1',
        content: 'Content 1',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-15T10:30:00.000Z',
        createdBy: 'user-1',
      ),
      GossipModel(
        id: '2',
        countryId: '1',
        regionId: '1',
        cityId: '2',
        subject: 'Test 2',
        content: 'Content 2',
        publishedAs: 'profile',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-15T11:30:00.000Z',
        createdBy: 'user-2',
      ),
    ];

    test('debe retornar gossips del remoto cuando está disponible', () async {
      // Arrange
      when(mockRemoteDataSource.getGossips(any))
          .thenAnswer((_) async => mockModels);
      when(mockLocalDataSource.saveAll(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2);
      expect(gossips[0].id, '1');
      expect(gossips[0].subject, 'Test 1');
      expect(gossips[1].id, '2');

      verify(mockRemoteDataSource.getGossips(query)).called(1);
      verify(mockLocalDataSource.saveAll(mockModels)).called(1);
    });

    test('debe guardar en caché local después de obtener del remoto', () async {
      // Arrange
      when(mockRemoteDataSource.getGossips(any))
          .thenAnswer((_) async => mockModels);
      when(mockLocalDataSource.saveAll(any)).thenAnswer((_) async {});

      // Act
      await repository.getGossips(query);

      // Assert - Verifica que se guardó en caché
      verify(mockLocalDataSource.saveAll(mockModels)).called(1);
    });

    test('debe hacer fallback a local cuando remoto falla', () async {
      // Arrange
      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('Network error'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => mockModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2);
      expect(gossips[0].id, '2'); // Ordenado desc por createdAt, '2' es más reciente

      verify(mockRemoteDataSource.getGossips(query)).called(1);
      verify(mockLocalDataSource.getAll()).called(1);
      verifyNever(mockLocalDataSource.saveAll(any));
    });

    test('debe retornar failure cuando ambos remoto y local fallan', () async {
      // Arrange
      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('Network error'));
      when(mockLocalDataSource.getAll())
          .thenThrow(Exception('Cache error'));

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isFailure, isTrue);
      verify(mockRemoteDataSource.getGossips(query)).called(1);
      verify(mockLocalDataSource.getAll()).called(1);
    });

    test('debe convertir models a entities correctamente', () async {
      // Arrange
      when(mockRemoteDataSource.getGossips(any))
          .thenAnswer((_) async => mockModels);
      when(mockLocalDataSource.saveAll(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;

      expect(gossips[0], isA<Gossip>());
      expect(gossips[0].publishedAs, PublishAs.anonymous);
      expect(gossips[0].status, GossipStatus.published);
      expect(gossips[0].moderationStatus, ModerationStatus.approved);
      expect(gossips[0].visibility, GossipVisibility.public);
    });

    test('debe propagar el query al remote data source', () async {
      // Arrange
      final customQuery = GossipQuery(
        countryId: 'co',
        regionId: 'antioquia',
        cityId: 'medellin',
        status: GossipStatus.published,
        visibility: GossipVisibility.public,
        orderBy: 'createdAt',
        descending: true,
        limit: 10,
      );

      when(mockRemoteDataSource.getGossips(customQuery))
          .thenAnswer((_) async => mockModels);
      when(mockLocalDataSource.saveAll(any)).thenAnswer((_) async {});

      // Act
      await repository.getGossips(customQuery);

      // Assert
      verify(mockRemoteDataSource.getGossips(customQuery)).called(1);
    });
  });

  group('GossipRepositoryImpl.createWithImage', () {
    final input = CreateGossipInput(
      countryId: '1',
      regionId: '1',
      cityId: '1',
      subject: 'New Gossip',
      content: 'New Content',
      publishedAs: PublishAs.anonymous,
      idempotencyKey: 'test-key-123',
    );

    final createdModel = GossipModel(
      id: 'new-123',
      countryId: '1',
      regionId: '1',
      cityId: '1',
      subject: 'New Gossip',
      content: 'New Content',
      publishedAs: 'anonymous',
      status: 'published',
      moderationStatus: 'approved',
      visibility: 'public',
      createdAt: '2024-01-15T12:00:00.000Z',
      createdBy: 'user-123',
    );

    test('debe crear gossip exitosamente cuando remoto y local funcionan', () async {
      // Arrange
      when(mockRemoteDataSource.createWithImage(any, any))
          .thenAnswer((_) async => createdModel);
      when(mockLocalDataSource.save(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.createWithImage(input, null);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossip = result.successValue!;
      expect(gossip.id, 'new-123');
      expect(gossip.subject, 'New Gossip');
      expect(gossip.content, 'New Content');

      verify(mockRemoteDataSource.createWithImage(input, null)).called(1);
      verify(mockLocalDataSource.save(createdModel)).called(1);
    });

    test('debe crear exitosamente incluso si caché local falla (idempotencia)', () async {
      // Arrange
      when(mockRemoteDataSource.createWithImage(any, any))
          .thenAnswer((_) async => createdModel);
      when(mockLocalDataSource.save(any))
          .thenThrow(Exception('Cache write error'));

      // Act
      final result = await repository.createWithImage(input, null);

      // Assert - El remoto tuvo éxito, así que la operación es exitosa
      expect(result.isSuccess, isTrue);
      final gossip = result.successValue!;
      expect(gossip.id, 'new-123');

      verify(mockRemoteDataSource.createWithImage(input, null)).called(1);
      verify(mockLocalDataSource.save(createdModel)).called(1);
    });

    test('debe retornar failure cuando remoto falla', () async {
      // Arrange
      when(mockRemoteDataSource.createWithImage(any, any))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await repository.createWithImage(input, null);

      // Assert
      expect(result.isFailure, isTrue);
      verify(mockRemoteDataSource.createWithImage(input, null)).called(1);
      verifyNever(mockLocalDataSource.save(any));
    });

    test('debe convertir model a entity correctamente', () async {
      // Arrange
      when(mockRemoteDataSource.createWithImage(any, any))
          .thenAnswer((_) async => createdModel);
      when(mockLocalDataSource.save(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.createWithImage(input, null);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossip = result.successValue!;

      expect(gossip, isA<Gossip>());
      expect(gossip.publishedAs, PublishAs.anonymous);
      expect(gossip.status, GossipStatus.published);
      expect(gossip.moderationStatus, ModerationStatus.approved);
      expect(gossip.visibility, GossipVisibility.public);
      expect(gossip.createdAt, isA<DateTime>());
    });

    test('debe llamar a createWithImage con el input original', () async {
      // Arrange
      when(mockRemoteDataSource.createWithImage(input, any))
          .thenAnswer((_) async => createdModel);
      when(mockLocalDataSource.save(any)).thenAnswer((_) async {});

      // Act
      await repository.createWithImage(input, null);

      // Assert
      verify(mockRemoteDataSource.createWithImage(input, null)).called(1);
    });

    test('debe intentar guardar en caché después de creación exitosa', () async {
      // Arrange
      when(mockRemoteDataSource.createWithImage(any, any))
          .thenAnswer((_) async => createdModel);
      when(mockLocalDataSource.save(any)).thenAnswer((_) async {});

      // Act
      await repository.createWithImage(input, null);

      // Assert
      verify(mockLocalDataSource.save(createdModel)).called(1);
    });
  });

  group('GossipRepositoryImpl - Idempotencia y cache', () {
    test('debe priorizar éxito remoto sobre fallo de caché (idempotencia)', () async {
      // Arrange - Remoto exitoso, caché falla
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'key-1',
      );

      final model = GossipModel(
        id: '123',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test',
        content: 'Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-15T10:00:00.000Z',
        createdBy: 'user-1',
      );

      when(mockRemoteDataSource.createWithImage(any, any))
          .thenAnswer((_) async => model);
      when(mockLocalDataSource.save(any))
          .thenThrow(Exception('Disk full'));

      // Act
      final result = await repository.createWithImage(input, null);

      // Assert - Debe ser exitoso porque remoto funcionó
      expect(result.isSuccess, isTrue);
      expect(result.successValue!.id, '123');
    });

    test('debe usar caché local solo cuando remoto falla completamente', () async {
      // Arrange
      final query = GossipQuery.defaultPublic();
      final cachedModels = [
        GossipModel(
          id: 'cached-1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Cached',
          content: 'From cache',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 1);
      expect(gossips[0].id, 'cached-1');
      expect(gossips[0].subject, 'Cached');
    });
  });

  group('GossipRepositoryImpl - Filtros en fallback local', () {
    test('debe filtrar por countryId cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        countryId: '1',
        orderBy: 'createdAt',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Country 1',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '2',
          regionId: '2',
          cityId: '2',
          subject: 'Country 2',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 1);
      expect(gossips[0].id, '1');
      expect(gossips[0].subject, 'Country 1');
    });

    test('debe filtrar por regionId cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        regionId: '1',
        orderBy: 'createdAt',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Region 1',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '2',
          cityId: '2',
          subject: 'Region 2',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 1);
      expect(gossips[0].id, '1');
      expect(gossips[0].subject, 'Region 1');
    });

    test('debe filtrar por cityId cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        cityId: '1',
        orderBy: 'createdAt',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'City 1',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '2',
          subject: 'City 2',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 1);
      expect(gossips[0].id, '1');
      expect(gossips[0].subject, 'City 1');
    });

    test('debe filtrar por status cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        status: GossipStatus.published,
        orderBy: 'createdAt',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Published',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Draft',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'draft',
          moderationStatus: 'pending',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 1);
      expect(gossips[0].id, '1');
      expect(gossips[0].subject, 'Published');
    });

    test('debe filtrar por visibility cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        visibility: GossipVisibility.public,
        orderBy: 'createdAt',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Public',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Private',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'private',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 1);
      expect(gossips[0].id, '1');
      expect(gossips[0].subject, 'Public');
    });
  });

  group('GossipRepositoryImpl - Ordenamiento en fallback local', () {
    test('debe ordenar por modifiedAt cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        orderBy: 'modifiedAt',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Older',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          modifiedAt: '2024-01-15T12:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Newer',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          modifiedAt: '2024-01-15T14:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2);
      expect(gossips[0].id, '1'); // Older first (ascending)
      expect(gossips[1].id, '2');
    });

    test('debe ordenar por viewCount cuando remoto falla', () async {
      // Arrange
      final query = GossipQuery(
        orderBy: 'viewCount',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'More views',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
          viewCount: 100,
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Less views',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
          viewCount: 50,
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2);
      expect(gossips[0].id, '2'); // Less views first (ascending)
      expect(gossips[1].id, '1');
    });

    test('debe usar ordenamiento default por createdAt cuando orderBy es inválido', () async {
      // Arrange
      final query = GossipQuery(
        orderBy: 'invalidField',
        descending: false,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Older',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Newer',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T11:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2);
      expect(gossips[0].id, '1'); // Older first (ascending by createdAt)
      expect(gossips[1].id, '2');
    });

    test('debe ordenar descendente cuando descending es true', () async {
      // Arrange
      final query = GossipQuery(
        orderBy: 'viewCount',
        descending: true,
        limit: 50,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'More views',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
          viewCount: 100,
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Less views',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
          viewCount: 50,
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2);
      expect(gossips[0].id, '1'); // More views first (descending)
      expect(gossips[1].id, '2');
    });
  });

  group('GossipRepositoryImpl - Límite de resultados', () {
    test('debe aplicar límite cuando hay más resultados en caché', () async {
      // Arrange
      final query = GossipQuery(
        orderBy: 'createdAt',
        descending: false,
        limit: 2,
      );

      final cachedModels = [
        GossipModel(
          id: '1',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'First',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T10:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Second',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T11:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '3',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Third',
          content: 'Content',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-15T12:00:00.000Z',
          createdBy: 'user-1',
        ),
      ];

      when(mockRemoteDataSource.getGossips(any))
          .thenThrow(Exception('No internet'));
      when(mockLocalDataSource.getAll())
          .thenAnswer((_) async => cachedModels);

      // Act
      final result = await repository.getGossips(query);

      // Assert
      expect(result.isSuccess, isTrue);
      final gossips = result.successValue!;
      expect(gossips.length, 2); // Solo retorna 2
      expect(gossips[0].id, '1');
      expect(gossips[1].id, '2');
    });
  });

  group('GossipRepositoryImpl.reportGossip', () {
    test('debe reportar gossip exitosamente', () async {
      // Arrange
      const gossipId = 'gossip-123';
      const reason = ReportReason.spam;
      const details = 'This is spam content';

      when(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).thenAnswer((_) async => {});

      // Act
      final result = await repository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).called(1);
    });

    test('debe reportar gossip sin details', () async {
      // Arrange
      const gossipId = 'gossip-123';
      const reason = ReportReason.harassment;

      when(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: null,
      )).thenAnswer((_) async => {});

      // Act
      final result = await repository.reportGossip(
        gossipId: gossipId,
        reason: reason,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: null,
      )).called(1);
    });

    test('debe retornar failure cuando remoto falla', () async {
      // Arrange
      const gossipId = 'gossip-123';
      const reason = ReportReason.violence;
      const details = 'Contains violence';

      when(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      );

      // Assert
      expect(result.isFailure, isTrue);
      verify(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).called(1);
    });

    test('debe manejar diferentes razones de reporte', () async {
      // Arrange
      const gossipId = 'gossip-123';
      const reasons = [
        ReportReason.spam,
        ReportReason.harassment,
        ReportReason.violence,
        ReportReason.sexualContent,
        ReportReason.misinformation,
        ReportReason.other,
      ];

      for (final reason in reasons) {
        when(mockRemoteDataSource.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: null,
        )).thenAnswer((_) async => {});

        // Act
        final result = await repository.reportGossip(
          gossipId: gossipId,
          reason: reason,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      }

      verify(mockRemoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: anyNamed('reason'),
        details: null,
      )).called(reasons.length);
    });
  });
}

/// Mocks para testing del logger
class _MockRemoteLogger implements RemoteLogger {
  @override
  Future<void> log(LogEntry entry) async {}
}

class _MockDeviceInfoProvider extends DeviceInfoProvider {
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {'os': 'Test', 'device': 'TestDevice'};
  }
}
