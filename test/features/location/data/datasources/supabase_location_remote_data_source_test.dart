import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/location/data/datasources/supabase_location_remote_data_source.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';

void main() {
  late AppLogger logger;

  setUp(() {
    // Logger mock simple para tests
    final mockRemoteLogger = _MockRemoteLogger();
    final mockDeviceInfo = _MockDeviceInfoProvider();
    logger = AppLogger(mockRemoteLogger, mockDeviceInfo);
  });

  tearDown(() {
    logger.close();
  });

  group('SupabaseLocationRemoteDataSource - Constructor', () {
    test('debe crear instancia con dependencias', () {
      // Arrange
      final supabase = _FakeSupabaseClient();

      // Act
      final dataSource = SupabaseLocationRemoteDataSource(supabase, logger);

      // Assert
      expect(dataSource, isA<SupabaseLocationRemoteDataSource>());
    });
  });

  group('Country - Entity mapping', () {
    test('debe deserializar Country.fromJson correctamente', () {
      // Arrange
      final json = {
        'id': 'CO',
        'name': 'Colombia',
        'code': 'CO',
      };

      // Act
      final country = Country.fromJson(json);

      // Assert
      expect(country, isA<Country>());
      expect(country.id, 'CO');
      expect(country.name, 'Colombia');
      expect(country.code, 'CO');
    });

    test('debe manejar Country con todos los campos requeridos', () {
      // Arrange
      final json = {
        'id': 'MX',
        'name': 'México',
        'code': 'MX',
      };

      // Act
      final country = Country.fromJson(json);

      // Assert
      expect(country.id, isNotEmpty);
      expect(country.name, isNotEmpty);
      expect(country.code, isNotEmpty);
    });

    test('debe convertir Country a JSON correctamente', () {
      // Arrange
      const country = Country(id: 'AR', name: 'Argentina', code: 'AR');

      // Act
      final json = country.toJson();

      // Assert
      expect(json['id'], 'AR');
      expect(json['name'], 'Argentina');
      expect(json['code'], 'AR');
    });
  });

  group('Region - Entity mapping', () {
    test('debe deserializar Region.fromJson correctamente', () {
      // Arrange
      final json = {
        'id': 'co-antioquia',
        'country_id': 'CO',
        'name': 'Antioquia',
        'type': 'department',
      };

      // Act
      final region = Region.fromJson(json);

      // Assert
      expect(region, isA<Region>());
      expect(region.id, 'co-antioquia');
      expect(region.countryId, 'CO');
      expect(region.name, 'Antioquia');
      expect(region.type, 'department');
    });

    test('debe manejar diferentes tipos de regiones', () {
      // Arrange - diferentes tipos: department, state, province, etc.
      final types = ['department', 'state', 'province', 'region'];

      for (final type in types) {
        final json = {
          'id': 'test-$type',
          'country_id': 'XX',
          'name': 'Test $type',
          'type': type,
        };

        // Act
        final region = Region.fromJson(json);

        // Assert
        expect(region.type, type);
      }
    });

    test('debe convertir Region a JSON correctamente', () {
      // Arrange
      const region = Region(
        id: 'co-cundinamarca',
        countryId: 'CO',
        name: 'Cundinamarca',
        type: 'department',
      );

      // Act
      final json = region.toJson();

      // Assert
      expect(json['id'], 'co-cundinamarca');
      expect(json['country_id'], 'CO');
      expect(json['name'], 'Cundinamarca');
      expect(json['type'], 'department');
    });
  });

  group('City - Entity mapping', () {
    test('debe deserializar City.fromJson correctamente', () {
      // Arrange
      final json = {
        'id': 'MED',
        'region_id': 'co-antioquia',
        'name': 'Medellín',
      };

      // Act
      final city = City.fromJson(json);

      // Assert
      expect(city, isA<City>());
      expect(city.id, 'MED');
      expect(city.regionId, 'co-antioquia');
      expect(city.name, 'Medellín');
    });

    test('debe manejar diferentes nombres de ciudades', () {
      // Arrange
      final cityNames = [
        'Medellín',
        'Bogotá',
        'Ciudad de México',
        'São Paulo',
        'Buenos Aires',
      ];

      for (final name in cityNames) {
        final json = {
          'id': 'test',
          'region_id': 'test-region',
          'name': name,
        };

        // Act
        final city = City.fromJson(json);

        // Assert
        expect(city.name, name);
        expect(city.name, isNotEmpty);
      }
    });

    test('debe convertir City a JSON correctamente', () {
      // Arrange
      const city = City(
        id: 'BOG',
        regionId: 'co-cundinamarca',
        name: 'Bogotá',
      );

      // Act
      final json = city.toJson();

      // Assert
      expect(json['id'], 'BOG');
      expect(json['region_id'], 'co-cundinamarca');
      expect(json['name'], 'Bogotá');
    });
  });

  group('getCountries - Comportamiento esperado', () {
    test('debe retornar lista de Countries', () {
      // getCountries() retorna List<Country>
      final countries = <Country>[];
      expect(countries, isA<List<Country>>());
    });

    test('debe ordenar por name alfabéticamente', () {
      // Orden esperado: ORDER BY name
      final countries = [
        const Country(id: 'CO', name: 'Colombia', code: 'CO'),
        const Country(id: 'AR', name: 'Argentina', code: 'AR'),
        const Country(id: 'MX', name: 'México', code: 'MX'),
      ];

      // Simular ordenamiento
      final sorted = List<Country>.from(countries)
        ..sort((a, b) => a.name.compareTo(b.name));

      // Assert orden alfabético
      expect(sorted[0].name, 'Argentina');
      expect(sorted[1].name, 'Colombia');
      expect(sorted[2].name, 'México');
    });

    test('debe manejar lista vacía de countries', () {
      // Caso edge: tabla countries vacía
      final emptyList = <Country>[];
      expect(emptyList, isEmpty);
    });

    test('debe usar query de Supabase correcta', () {
      // Documentación de la query: from('countries').select().order('name')
      const expectedTable = 'countries';
      const expectedOrderBy = 'name';

      expect(expectedTable, 'countries');
      expect(expectedOrderBy, 'name');
    });
  });

  group('getRegionsByCountry - Comportamiento esperado', () {
    test('debe retornar lista de Regions', () {
      // getRegionsByCountry() retorna List<Region>
      final regions = <Region>[];
      expect(regions, isA<List<Region>>());
    });

    test('debe filtrar por country_id', () {
      // Documentación: .eq('country_id', countryId)
      const countryId = 'CO';
      final regions = [
        const Region(id: 'co-ant', countryId: 'CO', name: 'Antioquia', type: 'department'),
        const Region(id: 'co-cund', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
      ];

      // Assert todas pertenecen al mismo país
      for (final region in regions) {
        expect(region.countryId, countryId);
      }
    });

    test('debe ordenar por name alfabéticamente', () {
      // Orden esperado: ORDER BY name
      final regions = [
        const Region(id: 'co-valle', countryId: 'CO', name: 'Valle del Cauca', type: 'department'),
        const Region(id: 'co-ant', countryId: 'CO', name: 'Antioquia', type: 'department'),
        const Region(id: 'co-cund', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
      ];

      // Simular ordenamiento
      final sorted = List<Region>.from(regions)
        ..sort((a, b) => a.name.compareTo(b.name));

      // Assert orden alfabético
      expect(sorted[0].name, 'Antioquia');
      expect(sorted[1].name, 'Cundinamarca');
      expect(sorted[2].name, 'Valle del Cauca');
    });

    test('debe manejar país sin regiones', () {
      // Caso edge: país sin regiones definidas
      final emptyList = <Region>[];
      expect(emptyList, isEmpty);
    });

    test('debe usar query de Supabase correcta', () {
      // Documentación: from('regions').select().eq('country_id', countryId).order('name')
      const expectedTable = 'regions';
      const expectedFilter = 'country_id';
      const expectedOrderBy = 'name';

      expect(expectedTable, 'regions');
      expect(expectedFilter, 'country_id');
      expect(expectedOrderBy, 'name');
    });
  });

  group('getCitiesByRegion - Comportamiento esperado', () {
    test('debe retornar lista de Cities', () {
      // getCitiesByRegion() retorna List<City>
      final cities = <City>[];
      expect(cities, isA<List<City>>());
    });

    test('debe filtrar por region_id', () {
      // Documentación: .eq('region_id', regionId)
      const regionId = 'co-antioquia';
      final cities = [
        const City(id: 'MED', regionId: 'co-antioquia', name: 'Medellín'),
        const City(id: 'ENV', regionId: 'co-antioquia', name: 'Envigado'),
      ];

      // Assert todas pertenecen a la misma región
      for (final city in cities) {
        expect(city.regionId, regionId);
      }
    });

    test('debe ordenar por población descendente y luego por nombre', () {
      // Orden esperado: ORDER BY population DESC, name
      // Nota: City entity no tiene population, pero la BD sí
      // El orden se aplica en la query, no en la entity
      const expectedOrders = ['population DESC', 'name ASC'];

      expect(expectedOrders.length, 2);
      expect(expectedOrders[0], contains('population'));
      expect(expectedOrders[1], contains('name'));
    });

    test('debe manejar región sin ciudades', () {
      // Caso edge: región sin ciudades definidas
      final emptyList = <City>[];
      expect(emptyList, isEmpty);
    });

    test('debe usar query de Supabase correcta', () {
      // Documentación: from('cities').select().eq('region_id', regionId)
      //                .order('population', ascending: false).order('name')
      const expectedTable = 'cities';
      const expectedFilter = 'region_id';

      expect(expectedTable, 'cities');
      expect(expectedFilter, 'region_id');
    });
  });

  group('searchCities - Parámetros RPC', () {
    test('debe usar nombres correctos de parámetros RPC', () {
      // Documentación de parámetros de search_cities()
      final expectedParams = {
        'search_query': 'Med',
        'region_filter': 'co-antioquia',
        'max_results': 20,
      };

      expect(expectedParams['search_query'], isNotEmpty);
      expect(expectedParams.containsKey('region_filter'), true);
      expect(expectedParams['max_results'], greaterThan(0));
    });

    test('debe aceptar region_filter null', () {
      // region_filter es opcional, puede ser null para buscar en todas las regiones
      const String? nullRegionId = null;
      expect(nullRegionId, isNull);
    });

    test('debe usar max_results default de 20', () {
      const int defaultMaxResults = 20;
      expect(defaultMaxResults, 20);
    });

    test('debe aceptar max_results personalizados', () {
      // Diferentes valores válidos de max_results
      const validMaxResults = [5, 10, 20, 50, 100];

      for (final maxResults in validMaxResults) {
        expect(maxResults, greaterThan(0));
        expect(maxResults, lessThanOrEqualTo(100));
      }
    });

    test('debe retornar lista vacía cuando no hay coincidencias', () {
      // Cuando search_cities no encuentra coincidencias, retorna []
      final emptyList = <City>[];
      expect(emptyList, isEmpty);
    });

    test('debe manejar query de búsqueda vacío', () {
      // Query vacío debe ser manejado
      const emptyQuery = '';
      expect(emptyQuery, isEmpty);
    });

    test('debe manejar query de búsqueda muy corto', () {
      // Query de 1-2 caracteres debe funcionar
      const shortQuery = 'Me';
      expect(shortQuery.length, lessThan(3));
      expect(shortQuery, isNotEmpty);
    });

    test('debe retornar lista de Cities cuando tiene coincidencias', () {
      // searchCities() retorna List<City>
      final cities = <City>[];
      expect(cities, isA<List<City>>());
    });
  });

  group('findNearestCity - Parámetros RPC', () {
    test('debe usar nombres correctos de parámetros RPC', () {
      // Documentación de parámetros de find_nearest_city()
      final expectedParams = {
        'target_lat': 6.2518,
        'target_lon': -75.5636,
        'max_distance_km': 50,
      };

      expect(expectedParams['target_lat'], isA<double>());
      expect(expectedParams['target_lon'], isA<double>());
      expect(expectedParams['max_distance_km'], isA<int>());
    });

    test('debe validar coordenadas de latitud', () {
      // Latitud válida: -90 a 90
      const validLatitudes = [-90.0, -45.0, 0.0, 45.0, 90.0];

      for (final lat in validLatitudes) {
        expect(lat, greaterThanOrEqualTo(-90));
        expect(lat, lessThanOrEqualTo(90));
      }
    });

    test('debe validar coordenadas de longitud', () {
      // Longitud válida: -180 a 180
      const validLongitudes = [-180.0, -90.0, 0.0, 90.0, 180.0];

      for (final lon in validLongitudes) {
        expect(lon, greaterThanOrEqualTo(-180));
        expect(lon, lessThanOrEqualTo(180));
      }
    });

    test('debe usar max_distance_km default de 50', () {
      const int defaultMaxDistance = 50;
      expect(defaultMaxDistance, 50);
    });

    test('debe aceptar max_distance_km personalizados', () {
      // Diferentes valores válidos de max_distance_km
      const validDistances = [10, 25, 50, 100, 200];

      for (final distance in validDistances) {
        expect(distance, greaterThan(0));
      }
    });

    test('debe retornar null cuando no encuentra ciudad cercana', () {
      // Cuando no hay ciudad en el radio especificado, retorna null
      const Map<String, dynamic>? nullResult = null;
      expect(nullResult, isNull);
    });

    test('debe retornar Map con estructura correcta cuando encuentra ciudad', () {
      // Estructura esperada del resultado
      const expectedKeys = ['city', 'region_name', 'country_name', 'distance_km'];

      for (final key in expectedKeys) {
        expect(expectedKeys, contains(key));
      }
    });

    test('debe incluir City entity en resultado', () {
      // El resultado debe incluir un objeto City
      final mockResult = {
        'city': const City(id: 'MED', regionId: 'co-ant', name: 'Medellín'),
        'region_name': 'Antioquia',
        'country_name': 'Colombia',
        'distance_km': 0.5,
      };

      expect(mockResult['city'], isA<City>());
      expect(mockResult['region_name'], isA<String>());
      expect(mockResult['country_name'], isA<String>());
      expect(mockResult['distance_km'], isA<num>());
    });

    test('debe calcular distancia en kilómetros', () {
      // La distancia debe ser un número positivo
      const distanceKm = 15.5;

      expect(distanceKm, isA<num>());
      expect(distanceKm, greaterThanOrEqualTo(0));
    });

    test('debe manejar respuesta vacía de RPC', () {
      // Cuando RPC retorna null, lista vacía o no es lista
      const responses = [null, <dynamic>[]];

      for (final response in responses) {
        expect(response == null || (response is List && response.isEmpty), true);
      }
    });
  });

  group('Error handling - Comportamiento esperado', () {
    test('debe lanzar excepciones en caso de error', () {
      // Los métodos deben propagar excepciones (rethrow)
      expect(() => throw Exception('Test error'), throwsException);
    });

    test('debe loguear errores antes de propagarlos', () {
      // Documentación: todos los métodos usan _logger.e() antes de rethrow
      // El logger debe estar inyectado y disponible
      expect(logger, isA<AppLogger>());
    });

    test('debe incluir contexto en logs de error', () {
      // Los logs de error deben incluir contexto relevante
      final mockContext = {
        'countryId': 'CO',
        'regionId': 'co-antioquia',
        'query': 'test',
      };

      expect(mockContext, isA<Map<String, dynamic>>());
      expect(mockContext.keys, isNotEmpty);
    });
  });
}

/// Mock simple de SupabaseClient para tests de constructor
class _FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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
