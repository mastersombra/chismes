import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/location/domain/usecases/search_cities.dart';
import 'package:chismes/features/location/domain/repositories/location_repository.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

import 'search_cities_test.mocks.dart';

@GenerateMocks([LocationRepository])
void main() {
  late SearchCities useCase;
  late MockLocationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocationRepository();
    useCase = SearchCities(mockRepository);

    // Provide dummy for Result<Failure, List<City>>
    provideDummy<Result<Failure, List<City>>>(
      Result.success(<City>[]),
    );
  });

  group('SearchCities', () {
    test('debe buscar ciudades exitosamente', () async {
      // Arrange
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        const City(id: '2', regionId: 'antioquia', name: 'Medina'),
      ];

      when(mockRepository.searchCities(
        query: 'Med',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success(cities));

      // Act
      final result = await useCase(query: 'Med');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, cities);
      expect(result.successValue?.length, 2);
      verify(mockRepository.searchCities(
        query: 'Med',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe pasar query al repository', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Bogotá',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Bogotá');

      // Assert
      verify(mockRepository.searchCities(
        query: 'Bogotá',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe pasar regionId al repository cuando se especifica', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Med',
        regionId: 'co-antioquia',
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Med', regionId: 'co-antioquia');

      // Assert
      verify(mockRepository.searchCities(
        query: 'Med',
        regionId: 'co-antioquia',
        maxResults: 20,
      )).called(1);
    });

    test('debe usar maxResults por defecto de 20', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Test');

      // Assert
      verify(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe pasar maxResults personalizado al repository', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 10,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Test', maxResults: 10);

      // Assert
      verify(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 10,
      )).called(1);
    });

    test('debe retornar lista vacía cuando no hay resultados', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'NonExistent',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      final result = await useCase(query: 'NonExistent');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe retornar Result.failure cuando repository falla', () async {
      // Arrange
      final failure = const NetworkFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network error',
      );

      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.failure(failure));

      // Act
      final result = await useCase(query: 'Test');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, failure);
    });

    test('debe combinar query, regionId y maxResults correctamente', () async {
      // Arrange
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
      ];

      when(mockRepository.searchCities(
        query: 'Med',
        regionId: 'antioquia',
        maxResults: 5,
      )).thenAnswer((_) async => Result.success(cities));

      // Act
      final result = await useCase(
        query: 'Med',
        regionId: 'antioquia',
        maxResults: 5,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, cities);
      verify(mockRepository.searchCities(
        query: 'Med',
        regionId: 'antioquia',
        maxResults: 5,
      )).called(1);
    });

    test('debe permitir regionId null', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Test', regionId: null);

      // Assert
      verify(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe retornar el resultado directamente del repository', () async {
      // Arrange
      final cities = [
        const City(id: '1', regionId: 'test', name: 'Test City'),
      ];
      final expectedResult = Result<Failure, List<City>>.success(cities);

      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase(query: 'Test');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, cities);
    });

    test('debe llamar al repository cada vez que se invoca', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Test1');
      await useCase(query: 'Test2');
      await useCase(query: 'Test3');

      // Assert
      verify(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).called(3);
    });

    test('debe manejar queries con caracteres especiales', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'São Paulo',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      final result = await useCase(query: 'São Paulo');

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRepository.searchCities(
        query: 'São Paulo',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe manejar queries con acentos', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Bogotá',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Bogotá');

      // Assert
      verify(mockRepository.searchCities(
        query: 'Bogotá',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe manejar queries vacíos', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: '',
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      final result = await useCase(query: '');

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRepository.searchCities(
        query: '',
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe manejar queries muy largos', () async {
      // Arrange
      final longQuery = 'a' * 1000;

      when(mockRepository.searchCities(
        query: longQuery,
        regionId: null,
        maxResults: 20,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      final result = await useCase(query: longQuery);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRepository.searchCities(
        query: longQuery,
        regionId: null,
        maxResults: 20,
      )).called(1);
    });

    test('debe manejar maxResults muy pequeño', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 1,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Test', maxResults: 1);

      // Assert
      verify(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 1,
      )).called(1);
    });

    test('debe manejar maxResults muy grande', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 1000,
      )).thenAnswer((_) async => Result.success([]));

      // Act
      await useCase(query: 'Test', maxResults: 1000);

      // Assert
      verify(mockRepository.searchCities(
        query: 'Test',
        regionId: null,
        maxResults: 1000,
      )).called(1);
    });

    test('debe manejar diferentes tipos de Failure', () async {
      // Arrange
      final serverFailure = const ServerFailure(
        code: ErrorCode.serverError,
        message: 'Server error',
      );

      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.failure(serverFailure));

      // Act
      final result = await useCase(query: 'Test');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ServerFailure>());
    });

    test('debe preservar el orden de ciudades del repository', () async {
      // Arrange
      final cities = [
        const City(id: '1', regionId: 'test', name: 'City A'),
        const City(id: '2', regionId: 'test', name: 'City B'),
        const City(id: '3', regionId: 'test', name: 'City C'),
      ];

      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(cities));

      // Act
      final result = await useCase(query: 'City');

      // Assert
      expect(result.successValue?[0].name, 'City A');
      expect(result.successValue?[1].name, 'City B');
      expect(result.successValue?[2].name, 'City C');
    });

    test('debe manejar lista con muchos resultados', () async {
      // Arrange
      final manyCities = List.generate(
        100,
        (i) => City(
          id: 'city-$i',
          regionId: 'test',
          name: 'City $i',
        ),
      );

      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(manyCities));

      // Act
      final result = await useCase(query: 'City', maxResults: 100);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 100);
    });

    test('debe funcionar con cualquier combinación de parámetros', () async {
      // Arrange
      when(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success([]));

      // Act & Assert - diferentes combinaciones
      await useCase(query: 'A');
      await useCase(query: 'B', regionId: 'region1');
      await useCase(query: 'C', maxResults: 5);
      await useCase(query: 'D', regionId: 'region2', maxResults: 10);

      verify(mockRepository.searchCities(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).called(4);
    });
  });
}
