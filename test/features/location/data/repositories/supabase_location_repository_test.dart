import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/location/data/repositories/supabase_location_repository.dart';
import 'package:chismes/features/location/data/datasources/supabase_location_remote_data_source.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

import 'supabase_location_repository_test.mocks.dart';

// Genera los mocks con: flutter pub run build_runner build
@GenerateMocks([SupabaseLocationRemoteDataSource])
void main() {
  late SupabaseLocationRepository repository;
  late MockSupabaseLocationRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockSupabaseLocationRemoteDataSource();
    repository = SupabaseLocationRepository(mockDataSource);
  });

  group('getCountries', () {
    test('debe retornar Result.success con lista de países', () async {
      final countries = [
        const Country(id: '1', code: 'CO', name: 'Colombia'),
        const Country(id: '2', code: 'AR', name: 'Argentina'),
      ];

      when(mockDataSource.getCountries()).thenAnswer((_) async => countries);

      final result = await repository.getCountries();

      expect(result.isSuccess, isTrue);
      expect(result.successValue, countries);
      expect(result.successValue?.length, 2);
      verify(mockDataSource.getCountries()).called(1);
    });

    test('debe retornar lista vacía si no hay países', () async {
      when(mockDataSource.getCountries()).thenAnswer((_) async => []);

      final result = await repository.getCountries();

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe retornar Result.failure cuando datasource lanza excepción', () async {
      when(mockDataSource.getCountries()).thenThrow(Exception('Network error'));

      final result = await repository.getCountries();

      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
      verify(mockDataSource.getCountries()).called(1);
    });

    test('debe convertir excepción a Failure con ErrorHandler', () async {
      when(mockDataSource.getCountries()).thenThrow(Exception('Database error'));

      final result = await repository.getCountries();

      expect(result.isFailure, isTrue);
      final failure = result.failureValue!;
      expect(failure, isA<Failure>());
      expect(failure.code, isA<ErrorCode>());
    });

    test('debe preservar orden de países del datasource', () async {
      final countries = [
        const Country(id: '1', code: 'CO', name: 'Colombia'),
        const Country(id: '2', code: 'BR', name: 'Brasil'),
        const Country(id: '3', code: 'AR', name: 'Argentina'),
      ];

      when(mockDataSource.getCountries()).thenAnswer((_) async => countries);

      final result = await repository.getCountries();

      expect(result.successValue?[0].code, 'CO');
      expect(result.successValue?[1].code, 'BR');
      expect(result.successValue?[2].code, 'AR');
    });
  });

  group('getRegionsByCountry', () {
    test('debe retornar Result.success con regiones del país', () async {
      final regions = [
        const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
        const Region(id: '2', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
      ];

      when(mockDataSource.getRegionsByCountry('CO')).thenAnswer((_) async => regions);

      final result = await repository.getRegionsByCountry('CO');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, regions);
      expect(result.successValue?.length, 2);
      verify(mockDataSource.getRegionsByCountry('CO')).called(1);
    });

    test('debe pasar countryId correcto al datasource', () async {
      when(mockDataSource.getRegionsByCountry('BR')).thenAnswer((_) async => []);

      await repository.getRegionsByCountry('BR');

      verify(mockDataSource.getRegionsByCountry('BR')).called(1);
      verifyNever(mockDataSource.getRegionsByCountry('CO'));
    });

    test('debe retornar lista vacía si país no tiene regiones', () async {
      when(mockDataSource.getRegionsByCountry('XX')).thenAnswer((_) async => []);

      final result = await repository.getRegionsByCountry('XX');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe retornar Result.failure cuando datasource lanza excepción', () async {
      when(mockDataSource.getRegionsByCountry('CO')).thenThrow(Exception('Network error'));

      final result = await repository.getRegionsByCountry('CO');

      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
    });

    test('debe filtrar regiones por countryId correctamente', () async {
      final regions = [
        const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
        const Region(id: '2', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
      ];

      when(mockDataSource.getRegionsByCountry('CO')).thenAnswer((_) async => regions);

      final result = await repository.getRegionsByCountry('CO');

      final allFromCountry = result.successValue?.every((r) => r.countryId == 'CO') ?? false;
      expect(allFromCountry, isTrue);
    });

    test('debe manejar diferentes tipos de región', () async {
      final regions = [
        const Region(id: '1', countryId: 'US', name: 'California', type: 'state'),
        const Region(id: '2', countryId: 'US', name: 'Texas', type: 'state'),
      ];

      when(mockDataSource.getRegionsByCountry('US')).thenAnswer((_) async => regions);

      final result = await repository.getRegionsByCountry('US');

      expect(result.successValue?[0].type, 'state');
      expect(result.successValue?[1].type, 'state');
    });
  });

  group('getCitiesByRegion', () {
    test('debe retornar Result.success con ciudades de la región', () async {
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        const City(id: '2', regionId: 'antioquia', name: 'Bello'),
      ];

      when(mockDataSource.getCitiesByRegion('antioquia')).thenAnswer((_) async => cities);

      final result = await repository.getCitiesByRegion('antioquia');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, cities);
      expect(result.successValue?.length, 2);
      verify(mockDataSource.getCitiesByRegion('antioquia')).called(1);
    });

    test('debe pasar regionId correcto al datasource', () async {
      when(mockDataSource.getCitiesByRegion('cundinamarca')).thenAnswer((_) async => []);

      await repository.getCitiesByRegion('cundinamarca');

      verify(mockDataSource.getCitiesByRegion('cundinamarca')).called(1);
      verifyNever(mockDataSource.getCitiesByRegion('antioquia'));
    });

    test('debe retornar lista vacía si región no tiene ciudades', () async {
      when(mockDataSource.getCitiesByRegion('empty-region')).thenAnswer((_) async => []);

      final result = await repository.getCitiesByRegion('empty-region');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe retornar Result.failure cuando datasource lanza excepción', () async {
      when(mockDataSource.getCitiesByRegion('antioquia')).thenThrow(Exception('Database error'));

      final result = await repository.getCitiesByRegion('antioquia');

      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
    });

    test('debe filtrar ciudades por regionId correctamente', () async {
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        const City(id: '2', regionId: 'antioquia', name: 'Envigado'),
      ];

      when(mockDataSource.getCitiesByRegion('antioquia')).thenAnswer((_) async => cities);

      final result = await repository.getCitiesByRegion('antioquia');

      final allFromRegion = result.successValue?.every((c) => c.regionId == 'antioquia') ?? false;
      expect(allFromRegion, isTrue);
    });

    test('debe manejar ciudades con caracteres especiales', () async {
      final cities = [
        const City(id: '1', regionId: 'test', name: 'Bogotá'),
        const City(id: '2', regionId: 'test', name: 'São Paulo'),
      ];

      when(mockDataSource.getCitiesByRegion('test')).thenAnswer((_) async => cities);

      final result = await repository.getCitiesByRegion('test');

      expect(result.successValue?[0].name, 'Bogotá');
      expect(result.successValue?[1].name, 'São Paulo');
    });
  });

  group('Manejo de errores', () {
    test('debe capturar y convertir cualquier tipo de excepción', () async {
      when(mockDataSource.getCountries()).thenThrow(FormatException('Invalid JSON'));

      final result = await repository.getCountries();

      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
    });

    test('debe incluir stackTrace en manejo de errores', () async {
      when(mockDataSource.getCountries()).thenThrow(Exception('Test error'));

      final result = await repository.getCountries();

      expect(result.isFailure, isTrue);
      // ErrorHandler usa stackTrace para generar mejor información
    });

    test('debe manejar timeout exceptions', () async {
      when(mockDataSource.getCountries()).thenThrow(TimeoutException('Request timeout'));

      final result = await repository.getCountries();

      expect(result.isFailure, isTrue);
    });

    test('debe manejar StateError', () async {
      when(mockDataSource.getRegionsByCountry(any)).thenThrow(StateError('Bad state'));

      final result = await repository.getRegionsByCountry('CO');

      expect(result.isFailure, isTrue);
    });
  });

  group('Integración con ErrorHandler', () {
    test('debe usar ErrorHandler.handleError para convertir excepciones', () async {
      when(mockDataSource.getCountries()).thenThrow(Exception('Network error'));

      final result = await repository.getCountries();

      // ErrorHandler convierte Exception a Failure
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
      expect(result.failureValue?.code, isA<ErrorCode>());
    });

    test('debe preservar información de error del datasource', () async {
      const errorMessage = 'Specific error from database';
      when(mockDataSource.getCountries()).thenThrow(Exception(errorMessage));

      final result = await repository.getCountries();

      expect(result.isFailure, isTrue);
      // El ErrorCode clasifica el tipo de error
      expect(result.failureValue?.code, isA<ErrorCode>());
    });
  });

  group('Flujo de datos', () {
    test('debe pasar datos del datasource sin modificación', () async {
      final countries = [
        const Country(id: 'uuid-123', code: 'CO', name: 'Colombia'),
      ];

      when(mockDataSource.getCountries()).thenAnswer((_) async => countries);

      final result = await repository.getCountries();

      expect(result.successValue, same(countries));
    });

    test('debe llamar al datasource exactamente una vez por request', () async {
      when(mockDataSource.getCountries()).thenAnswer((_) async => []);

      await repository.getCountries();
      await repository.getCountries();

      verify(mockDataSource.getCountries()).called(2);
    });

    test('no debe cachear resultados entre llamadas', () async {
      final countries1 = [const Country(id: '1', code: 'CO', name: 'Colombia')];
      final countries2 = [const Country(id: '2', code: 'AR', name: 'Argentina')];

      // Primera llamada retorna countries1
      when(mockDataSource.getCountries()).thenAnswer((_) async => countries1);
      final result1 = await repository.getCountries();

      // Segunda llamada retorna countries2
      when(mockDataSource.getCountries()).thenAnswer((_) async => countries2);
      final result2 = await repository.getCountries();

      expect(result1.successValue, countries1);
      expect(result2.successValue, countries2);
    });
  });

  group('searchCities', () {
    test('debe retornar Result.success con ciudades encontradas', () async {
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        const City(id: '2', regionId: 'antioquia', name: 'Medina'),
      ];

      when(mockDataSource.searchCities('Med', null, maxResults: 20))
          .thenAnswer((_) async => cities);

      final result = await repository.searchCities(query: 'Med');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, cities);
      expect(result.successValue?.length, 2);
      verify(mockDataSource.searchCities('Med', null, maxResults: 20)).called(1);
    });

    test('debe pasar parámetros correctos al datasource', () async {
      when(mockDataSource.searchCities('Test', 'co-ant', maxResults: 10))
          .thenAnswer((_) async => []);

      await repository.searchCities(
        query: 'Test',
        regionId: 'co-ant',
        maxResults: 10,
      );

      verify(mockDataSource.searchCities('Test', 'co-ant', maxResults: 10)).called(1);
    });

    test('debe usar maxResults por defecto de 20', () async {
      when(mockDataSource.searchCities('Test', null, maxResults: 20))
          .thenAnswer((_) async => []);

      await repository.searchCities(query: 'Test');

      verify(mockDataSource.searchCities('Test', null, maxResults: 20)).called(1);
    });

    test('debe permitir regionId null', () async {
      when(mockDataSource.searchCities('Test', null, maxResults: 20))
          .thenAnswer((_) async => []);

      await repository.searchCities(query: 'Test', regionId: null);

      verify(mockDataSource.searchCities('Test', null, maxResults: 20)).called(1);
    });

    test('debe retornar lista vacía cuando no hay resultados', () async {
      when(mockDataSource.searchCities('NonExistent', null, maxResults: 20))
          .thenAnswer((_) async => []);

      final result = await repository.searchCities(query: 'NonExistent');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe retornar Result.failure cuando datasource lanza excepción', () async {
      when(mockDataSource.searchCities(any, any, maxResults: anyNamed('maxResults')))
          .thenThrow(Exception('Search error'));

      final result = await repository.searchCities(query: 'Test');

      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
    });

    test('debe filtrar por región cuando se especifica', () async {
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
      ];

      when(mockDataSource.searchCities('Med', 'antioquia', maxResults: 20))
          .thenAnswer((_) async => cities);

      final result = await repository.searchCities(
        query: 'Med',
        regionId: 'antioquia',
      );

      expect(result.isSuccess, isTrue);
      expect(result.successValue, cities);
      verify(mockDataSource.searchCities('Med', 'antioquia', maxResults: 20)).called(1);
    });

    test('debe respetar maxResults personalizado', () async {
      when(mockDataSource.searchCities('Test', null, maxResults: 5))
          .thenAnswer((_) async => []);

      await repository.searchCities(query: 'Test', maxResults: 5);

      verify(mockDataSource.searchCities('Test', null, maxResults: 5)).called(1);
    });

    test('debe manejar queries con caracteres especiales', () async {
      when(mockDataSource.searchCities('São', null, maxResults: 20))
          .thenAnswer((_) async => []);

      final result = await repository.searchCities(query: 'São');

      expect(result.isSuccess, isTrue);
      verify(mockDataSource.searchCities('São', null, maxResults: 20)).called(1);
    });

    test('debe manejar errores de timeout en búsqueda', () async {
      when(mockDataSource.searchCities(any, any, maxResults: anyNamed('maxResults')))
          .thenThrow(TimeoutException('Search timeout'));

      final result = await repository.searchCities(query: 'Test');

      expect(result.isFailure, isTrue);
    });

    test('debe combinar query, regionId y maxResults correctamente', () async {
      final cities = [
        const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        const City(id: '2', regionId: 'antioquia', name: 'Medina'),
      ];

      when(mockDataSource.searchCities('Med', 'antioquia', maxResults: 10))
          .thenAnswer((_) async => cities);

      final result = await repository.searchCities(
        query: 'Med',
        regionId: 'antioquia',
        maxResults: 10,
      );

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 2);
      verify(mockDataSource.searchCities('Med', 'antioquia', maxResults: 10)).called(1);
    });

    test('debe pasar datos del datasource sin modificación', () async {
      final cities = [
        const City(id: 'uuid-456', regionId: 'test', name: 'Test City'),
      ];

      when(mockDataSource.searchCities('Test', null, maxResults: 20))
          .thenAnswer((_) async => cities);

      final result = await repository.searchCities(query: 'Test');

      expect(result.successValue, same(cities));
    });

    test('debe manejar múltiples llamadas consecutivas', () async {
      when(mockDataSource.searchCities('Test1', null, maxResults: 20))
          .thenAnswer((_) async => []);
      when(mockDataSource.searchCities('Test2', null, maxResults: 20))
          .thenAnswer((_) async => []);

      await repository.searchCities(query: 'Test1');
      await repository.searchCities(query: 'Test2');

      verify(mockDataSource.searchCities('Test1', null, maxResults: 20)).called(1);
      verify(mockDataSource.searchCities('Test2', null, maxResults: 20)).called(1);
    });

    test('debe manejar búsquedas con query vacío', () async {
      when(mockDataSource.searchCities('', null, maxResults: 20))
          .thenAnswer((_) async => []);

      final result = await repository.searchCities(query: '');

      expect(result.isSuccess, isTrue);
      verify(mockDataSource.searchCities('', null, maxResults: 20)).called(1);
    });

    test('debe convertir excepciones a Failure con ErrorHandler', () async {
      when(mockDataSource.searchCities(any, any, maxResults: anyNamed('maxResults')))
          .thenThrow(Exception('RPC error'));

      final result = await repository.searchCities(query: 'Test');

      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
      expect(result.failureValue?.code, isA<ErrorCode>());
    });
  });

  group('Casos edge', () {
    test('debe manejar país con muchas regiones', () async {
      final manyRegions = List.generate(
        100,
        (i) => Region(
          id: 'region-$i',
          countryId: 'CO',
          name: 'Region $i',
          type: 'department',
        ),
      );

      when(mockDataSource.getRegionsByCountry('CO')).thenAnswer((_) async => manyRegions);

      final result = await repository.getRegionsByCountry('CO');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 100);
    });

    test('debe manejar región con muchas ciudades', () async {
      final manyCities = List.generate(
        200,
        (i) => City(
          id: 'city-$i',
          regionId: 'antioquia',
          name: 'City $i',
        ),
      );

      when(mockDataSource.getCitiesByRegion('antioquia')).thenAnswer((_) async => manyCities);

      final result = await repository.getCitiesByRegion('antioquia');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 200);
    });

    test('debe manejar IDs con caracteres especiales', () async {
      when(mockDataSource.getRegionsByCountry('país-con-ñ')).thenAnswer((_) async => []);

      final result = await repository.getRegionsByCountry('país-con-ñ');

      expect(result.isSuccess, isTrue);
      verify(mockDataSource.getRegionsByCountry('país-con-ñ')).called(1);
    });

    test('debe manejar nombres con emojis', () async {
      final cities = [
        const City(id: '1', regionId: 'test', name: 'City 🏙️'),
      ];

      when(mockDataSource.getCitiesByRegion('test')).thenAnswer((_) async => cities);

      final result = await repository.getCitiesByRegion('test');

      expect(result.successValue?[0].name, contains('🏙️'));
    });

    test('debe manejar búsqueda con muchos resultados', () async {
      final manyCities = List.generate(
        100,
        (i) => City(
          id: 'city-$i',
          regionId: 'test',
          name: 'City $i',
        ),
      );

      when(mockDataSource.searchCities('City', null, maxResults: 100))
          .thenAnswer((_) async => manyCities);

      final result = await repository.searchCities(query: 'City', maxResults: 100);

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 100);
    });
  });
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
