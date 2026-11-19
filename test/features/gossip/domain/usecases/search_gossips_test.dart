import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/domain/usecases/search_gossips.dart';
import 'package:chismes/features/gossip/domain/repositories/gossip_repository.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';

import 'search_gossips_test.mocks.dart';

@GenerateMocks([
  GossipRepository,
])
void main() {
  setUpAll(() {
    // Provide dummy values for mockito
    provideDummy<Result<Failure, List<Gossip>>>(
      Result.success([]),
    );
  });

  late SearchGossips useCase;
  late MockGossipRepository mockRepository;

  setUp(() {
    mockRepository = MockGossipRepository();
    useCase = SearchGossips(repository: mockRepository);
  });

  group('SearchGossips', () {
    final mockGossip1 = Gossip(
      id: 'gossip-1',
      countryId: '1',
      regionId: '1',
      cityId: 'city-1',
      subject: 'Incendio en el centro',
      content: 'Hubo un incendio en el centro de la ciudad',
      audioUrl: null,
      imageUrl: null,
      publishedAs: PublishAs.anonymous,
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      reportedCount: 0,
      viewCount: 10,
      deletedAt: null,
      deletedBy: null,
      visibility: GossipVisibility.public,
      createdAt: DateTime(2024, 1, 1),
      createdBy: 'user-1',
      modifiedAt: null,
      modifiedBy: null,
    );

    final mockGossip2 = Gossip(
      id: 'gossip-2',
      countryId: '1',
      regionId: '1',
      cityId: 'city-1',
      subject: 'Nuevo restaurante',
      content: 'Abrió un nuevo restaurante en el centro',
      audioUrl: null,
      imageUrl: null,
      publishedAs: PublishAs.profile,
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      reportedCount: 0,
      viewCount: 5,
      deletedAt: null,
      deletedBy: null,
      visibility: GossipVisibility.public,
      createdAt: DateTime(2024, 1, 2),
      createdBy: 'user-2',
      modifiedAt: null,
      modifiedBy: null,
    );

    test('debe retornar gossips cuando query es válido', () async {
      // Arrange
      const query = 'incendio';
      final expectedGossips = [mockGossip1];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);
      result.when(
        onFailure: (_) => fail('Should not fail'),
        onSuccess: (gossips) {
          expect(gossips, expectedGossips);
          expect(gossips.length, 1);
          expect(gossips.first.id, 'gossip-1');
        },
      );

      verify(mockRepository.searchGossips(
        query: query,
        cityId: null,
        limit: 20,
      )).called(1);
    });

    test('debe retornar lista vacía cuando query está vacío', () async {
      // Arrange
      const query = '';

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);
      result.when(
        onFailure: (_) => fail('Should not fail'),
        onSuccess: (gossips) {
          expect(gossips, isEmpty);
        },
      );

      // No debe llamar al repository
      verifyNever(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      ));
    });

    test('debe retornar lista vacía cuando query solo contiene espacios', () async {
      // Arrange
      const query = '   ';

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);
      result.when(
        onFailure: (_) => fail('Should not fail'),
        onSuccess: (gossips) {
          expect(gossips, isEmpty);
        },
      );

      // No debe llamar al repository
      verifyNever(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      ));
    });

    test('debe trimear query antes de buscar', () async {
      // Arrange
      const query = '  incendio  ';
      const trimmedQuery = 'incendio';
      final expectedGossips = [mockGossip1];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);

      // Verificar que se llamó con query trimeado
      verify(mockRepository.searchGossips(
        query: trimmedQuery, // ← Query sin espacios
        cityId: null,
        limit: 20,
      )).called(1);
    });

    test('debe pasar cityId al repository cuando se especifica', () async {
      // Arrange
      const query = 'restaurante';
      const cityId = 'city-1';
      final expectedGossips = [mockGossip2];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: query, cityId: cityId);

      // Assert
      expect(result.isSuccess, isTrue);
      result.when(
        onFailure: (_) => fail('Should not fail'),
        onSuccess: (gossips) {
          expect(gossips, expectedGossips);
          expect(gossips.length, 1);
          expect(gossips.first.cityId, cityId);
        },
      );

      verify(mockRepository.searchGossips(
        query: query,
        cityId: cityId, // ← Verificar que se pasó cityId
        limit: 20,
      )).called(1);
    });

    test('debe usar limit personalizado cuando se especifica', () async {
      // Arrange
      const query = 'centro';
      const customLimit = 50;
      final expectedGossips = [mockGossip1, mockGossip2];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: query, limit: customLimit);

      // Assert
      expect(result.isSuccess, isTrue);
      result.when(
        onFailure: (_) => fail('Should not fail'),
        onSuccess: (gossips) {
          expect(gossips.length, 2);
        },
      );

      verify(mockRepository.searchGossips(
        query: query,
        cityId: null,
        limit: customLimit, // ← Verificar límite personalizado
      )).called(1);
    });

    test('debe usar limit por defecto (20) cuando no se especifica', () async {
      // Arrange
      const query = 'test';
      final expectedGossips = [mockGossip1];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);

      verify(mockRepository.searchGossips(
        query: query,
        cityId: null,
        limit: 20, // ← Verificar límite por defecto
      )).called(1);
    });

    test('debe retornar failure cuando repository falla', () async {
      // Arrange
      const query = 'test';
      const failure = NetworkFailure(code: ErrorCode.networkError);

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.failure(failure));

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isFailure, isTrue);
      result.when(
        onFailure: (error) {
          expect(error, isA<NetworkFailure>());
          expect(error.code, ErrorCode.networkError);
        },
        onSuccess: (_) => fail('Should not succeed'),
      );

      verify(mockRepository.searchGossips(
        query: query,
        cityId: null,
        limit: 20,
      )).called(1);
    });

    test('debe retornar lista vacía cuando repository retorna lista vacía', () async {
      // Arrange
      const query = 'noexiste';

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success([]));

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);
      result.when(
        onFailure: (_) => fail('Should not fail'),
        onSuccess: (gossips) {
          expect(gossips, isEmpty);
        },
      );

      verify(mockRepository.searchGossips(
        query: query,
        cityId: null,
        limit: 20,
      )).called(1);
    });

    test('debe combinar cityId y limit personalizados', () async {
      // Arrange
      const query = 'evento';
      const cityId = 'city-2';
      const customLimit = 100;
      final expectedGossips = [mockGossip1, mockGossip2];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(
        query: query,
        cityId: cityId,
        limit: customLimit,
      );

      // Assert
      expect(result.isSuccess, isTrue);

      verify(mockRepository.searchGossips(
        query: query,
        cityId: cityId,
        limit: customLimit,
      )).called(1);
    });

    test('debe manejar query con caracteres especiales', () async {
      // Arrange
      const query = 'café & té';
      final expectedGossips = [mockGossip1];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: query);

      // Assert
      expect(result.isSuccess, isTrue);

      // El usecase debe pasar el query tal cual al repository
      // (la sanitización es responsabilidad del repository/backend)
      verify(mockRepository.searchGossips(
        query: query,
        cityId: null,
        limit: 20,
      )).called(1);
    });

    test('debe manejar query muy largo', () async {
      // Arrange
      final longQuery = 'a' * 500; // Query de 500 caracteres
      final expectedGossips = [mockGossip1];

      when(mockRepository.searchGossips(
        query: anyNamed('query'),
        cityId: anyNamed('cityId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Result.success(expectedGossips));

      // Act
      final result = await useCase(query: longQuery);

      // Assert
      expect(result.isSuccess, isTrue);

      // El usecase no valida longitud (eso es responsabilidad del repository)
      verify(mockRepository.searchGossips(
        query: longQuery,
        cityId: null,
        limit: 20,
      )).called(1);
    });
  });
}
