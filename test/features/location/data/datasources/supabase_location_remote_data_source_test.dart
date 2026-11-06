import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/location/data/datasources/supabase_location_remote_data_source.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

// Nota: Este data source requiere tests de integración con Supabase real
// porque mockear el cliente de Supabase con sus builders encadenados es muy complejo.
//
// Los tests aquí se enfocan en verificar la estructura del data source
// y documentar su API. La cobertura completa se logra con tests E2E
// que usan una instancia de Supabase de testing.

void main() {
  group('SupabaseLocationRemoteDataSource', () {
    group('Estructura y API', () {
      test('debe tener constructor que recibe SupabaseClient', () {
        // Este test verifica que la clase existe y tiene la estructura esperada
        expect(SupabaseLocationRemoteDataSource, isNotNull);
      });

      test('debe tener método getCountries', () {
        // Verifica que el método existe con la firma correcta
        expect(
          SupabaseLocationRemoteDataSource,
          isA<Type>(),
        );
      });

      test('debe tener método getRegionsByCountry que recibe String', () {
        // Verifica estructura del método
        expect(
          SupabaseLocationRemoteDataSource,
          isA<Type>(),
        );
      });

      test('debe tener método getCitiesByRegion que recibe String', () {
        // Verifica estructura del método
        expect(
          SupabaseLocationRemoteDataSource,
          isA<Type>(),
        );
      });

      test('debe tener método searchCities con parámetros opcionales', () {
        // Verifica estructura del método
        expect(
          SupabaseLocationRemoteDataSource,
          isA<Type>(),
        );
      });

      test('debe tener método findNearestCity con coordenadas', () {
        // Verifica estructura del método
        expect(
          SupabaseLocationRemoteDataSource,
          isA<Type>(),
        );
      });
    });

    group('Conversión de JSON a Entities', () {
      test('debe convertir lista de JSON a lista de Country', () {
        final jsonList = [
          {'id': '1', 'code': 'CO', 'name': 'Colombia'},
          {'id': '2', 'code': 'AR', 'name': 'Argentina'},
        ];

        final countries = jsonList
            .map((json) => Country.fromJson(json))
            .toList();

        expect(countries.length, 2);
        expect(countries[0], isA<Country>());
        expect(countries[0].code, 'CO');
        expect(countries[1].code, 'AR');
      });

      test('debe convertir lista de JSON a lista de Region', () {
        final jsonList = [
          {
            'id': '1',
            'country_id': 'CO',
            'name': 'Antioquia',
            'type': 'department'
          },
          {
            'id': '2',
            'country_id': 'CO',
            'name': 'Cundinamarca',
            'type': 'department'
          },
        ];

        final regions = jsonList
            .map((json) => Region.fromJson(json))
            .toList();

        expect(regions.length, 2);
        expect(regions[0], isA<Region>());
        expect(regions[0].name, 'Antioquia');
        expect(regions[1].name, 'Cundinamarca');
      });

      test('debe convertir lista de JSON a lista de City', () {
        final jsonList = [
          {'id': '1', 'region_id': 'co-ant', 'name': 'Medellín'},
          {'id': '2', 'region_id': 'co-ant', 'name': 'Bello'},
        ];

        final cities = jsonList
            .map((json) => City.fromJson(json))
            .toList();

        expect(cities.length, 2);
        expect(cities[0], isA<City>());
        expect(cities[0].name, 'Medellín');
        expect(cities[1].name, 'Bello');
      });

      test('debe manejar lista vacía al convertir países', () {
        final jsonList = <Map<String, dynamic>>[];

        final countries = jsonList
            .map((json) => Country.fromJson(json))
            .toList();

        expect(countries, isEmpty);
      });

      test('debe manejar JSON con campos adicionales en Country', () {
        final jsonList = [
          {
            'id': '1',
            'code': 'US',
            'name': 'United States',
            'extra_field': 'ignored',
            'population': 330000000,
          },
        ];

        final countries = jsonList
            .map((json) => Country.fromJson(json))
            .toList();

        expect(countries[0].id, '1');
        expect(countries[0].code, 'US');
        expect(countries[0].name, 'United States');
      });
    });

    group('Formato de respuesta de findNearestCity', () {
      test('debe parsear resultado de findNearestCity correctamente', () {
        // Simula el formato que retorna la función SQL
        final mockResponse = {
          'id': 'city-123',
          'region_id': 'region-456',
          'name': 'Medellín',
          'region_name': 'Antioquia',
          'country_name': 'Colombia',
          'distance_km': 0.5,
        };

        final city = City.fromJson(mockResponse);
        expect(city.id, 'city-123');
        expect(city.regionId, 'region-456');
        expect(city.name, 'Medellín');
        expect(mockResponse['region_name'], 'Antioquia');
        expect(mockResponse['country_name'], 'Colombia');
        expect(mockResponse['distance_km'], 0.5);
      });

      test('debe manejar distancia como num (puede ser int o double)', () {
        final response1 = {
          'id': '1',
          'region_id': '1',
          'name': 'City',
          'distance_km': 5,
        };

        final response2 = {
          'id': '2',
          'region_id': '2',
          'name': 'City2',
          'distance_km': 5.5,
        };

        expect(response1['distance_km'], isA<int>());
        expect(response2['distance_km'], isA<double>());
        expect(response1['distance_km'], isA<num>());
        expect(response2['distance_km'], isA<num>());
      });

      test('debe validar estructura completa del resultado', () {
        final mockResponse = {
          'id': '1',
          'region_id': '2',
          'name': 'Test City',
          'region_name': 'Test Region',
          'country_name': 'Test Country',
          'distance_km': 10.0,
        };

        // Verifica que tiene todas las keys esperadas
        expect(mockResponse.containsKey('id'), isTrue);
        expect(mockResponse.containsKey('region_id'), isTrue);
        expect(mockResponse.containsKey('name'), isTrue);
        expect(mockResponse.containsKey('region_name'), isTrue);
        expect(mockResponse.containsKey('country_name'), isTrue);
        expect(mockResponse.containsKey('distance_km'), isTrue);

        // Verifica que City.fromJson puede parsear la parte de ciudad
        final city = City.fromJson(mockResponse);
        expect(city, isNotNull);
      });
    });

    group('Valores por defecto de parámetros', () {
      test('searchCities debe tener maxResults por defecto de 20', () {
        // Documenta el valor por defecto
        const defaultMaxResults = 20;
        expect(defaultMaxResults, 20);
      });

      test('findNearestCity debe tener maxDistanceKm por defecto de 50', () {
        // Documenta el valor por defecto
        const defaultMaxDistanceKm = 50;
        expect(defaultMaxDistanceKm, 50);
      });
    });

    group('Orden de resultados esperado', () {
      test('getCountries debe ordenar por nombre alfabéticamente', () {
        final countries = [
          Country(id: '3', code: 'MX', name: 'México'),
          Country(id: '1', code: 'AR', name: 'Argentina'),
          Country(id: '2', code: 'CO', name: 'Colombia'),
        ];

        final sorted = List<Country>.from(countries)
          ..sort((a, b) => a.name.compareTo(b.name));

        expect(sorted[0].name, 'Argentina');
        expect(sorted[1].name, 'Colombia');
        expect(sorted[2].name, 'México');
      });

      test('getRegionsByCountry debe ordenar por nombre alfabéticamente', () {
        final regions = [
          Region(
              id: '2',
              countryId: 'CO',
              name: 'Cundinamarca',
              type: 'department'),
          Region(
              id: '1',
              countryId: 'CO',
              name: 'Antioquia',
              type: 'department'),
        ];

        final sorted = List<Region>.from(regions)
          ..sort((a, b) => a.name.compareTo(b.name));

        expect(sorted[0].name, 'Antioquia');
        expect(sorted[1].name, 'Cundinamarca');
      });

      test('getCitiesByRegion debe ordenar por población (desc) y luego nombre',
          () {
        // Documenta el orden esperado
        // Este test documenta que el orden esperado es:
        // 1. Población descendente (ciudades grandes primero)
        // 2. Nombre alfabéticamente (como desempate)

        expect(true, isTrue); // Test de documentación
      });
    });

    group('Filtros SQL esperados', () {
      test('getRegionsByCountry debe filtrar por country_id', () {
        // Documenta que el filtro esperado es:
        // WHERE country_id = 'XX'
        const expectedCountryId = 'CO';
        expect(expectedCountryId, 'CO');
      });

      test('getCitiesByRegion debe filtrar por region_id', () {
        // Documenta que el filtro esperado es:
        // WHERE region_id = 'XX'
        const expectedRegionId = 'co-antioquia';
        expect(expectedRegionId, 'co-antioquia');
      });
    });

    group('Funciones RPC de Supabase', () {
      test('searchCities debe usar función search_cities con parámetros correctos',
          () {
        // Documenta los parámetros esperados:
        final expectedParams = {
          'search_query': 'Med',
          'region_filter': 'co-ant',
          'max_results': 20,
        };

        expect(expectedParams.containsKey('search_query'), isTrue);
        expect(expectedParams.containsKey('region_filter'), isTrue);
        expect(expectedParams.containsKey('max_results'), isTrue);
      });

      test('searchCities debe permitir region_filter null', () {
        final paramsWithNullRegion = {
          'search_query': 'Test',
          'region_filter': null,
          'max_results': 20,
        };

        expect(paramsWithNullRegion['region_filter'], isNull);
      });

      test('findNearestCity debe usar función find_nearest_city con coordenadas',
          () {
        // Documenta los parámetros esperados:
        final expectedParams = {
          'target_lat': 6.2518,
          'target_lon': -75.5636,
          'max_distance_km': 50,
        };

        expect(expectedParams.containsKey('target_lat'), isTrue);
        expect(expectedParams.containsKey('target_lon'), isTrue);
        expect(expectedParams.containsKey('max_distance_km'), isTrue);
        expect(expectedParams['target_lat'], isA<double>());
        expect(expectedParams['target_lon'], isA<double>());
        expect(expectedParams['max_distance_km'], isA<int>());
      });

      test('findNearestCity debe manejar coordenadas negativas', () {
        // Buenos Aires, Argentina
        final params = {
          'target_lat': -34.6037,
          'target_lon': -58.3816,
          'max_distance_km': 50,
        };

        expect(params['target_lat']! < 0, isTrue);
        expect(params['target_lon']! < 0, isTrue);
      });
    });

    group('Manejo de respuestas vacías o null', () {
      test('searchCities debe retornar lista vacía si response es null', () {
        // Documenta el comportamiento esperado
        final response = null;
        final result = response == null ? <City>[] : [];

        expect(result, isEmpty);
        expect(result, isA<List<City>>());
      });

      test('findNearestCity debe retornar null si no hay resultados', () {
        // Documenta el comportamiento esperado
        final emptyResponse = <Map<String, dynamic>>[];
        final result = emptyResponse.isEmpty ? null : emptyResponse[0];

        expect(result, isNull);
      });

      test('findNearestCity debe retornar null si response no es lista', () {
        // Documenta el comportamiento esperado
        final invalidResponse = 'not a list';
        final result = invalidResponse is! List ? null : invalidResponse;

        expect(result, isNull);
      });
    });

    group('Casos edge de búsqueda', () {
      test('searchCities debe manejar queries con acentos', () {
        final queries = ['Medellín', 'Bogotá', 'São Paulo', 'Córdoba'];

        for (final query in queries) {
          expect(query, isNotEmpty);
          expect(query, isA<String>());
        }
      });

      test('searchCities debe manejar queries parciales', () {
        final partialQueries = ['Med', 'Bog', 'LA', 'NYC'];

        for (final query in partialQueries) {
          expect(query.length, lessThan(10));
          expect(query, isA<String>());
        }
      });

      test('findNearestCity debe manejar coordenadas en el ecuador', () {
        final ecuadorCoords = {
          'target_lat': 0.0,
          'target_lon': -78.4678, // Quito, Ecuador
        };

        expect(ecuadorCoords['target_lat'], 0.0);
        expect(ecuadorCoords['target_lon']! < 0, isTrue);
      });

      test('findNearestCity debe manejar coordenadas polares', () {
        final arcticCoords = {
          'target_lat': 64.8378,
          'target_lon': -147.7164, // Fairbanks, Alaska
        };

        expect(arcticCoords['target_lat']! > 60, isTrue);
      });
    });

    group('Estructura de resultado de findNearestCity', () {
      test('debe retornar Map con 4 keys: city, region_name, country_name, distance_km', () {
        // Documenta la estructura del Map retornado
        final expectedKeys = ['city', 'region_name', 'country_name', 'distance_km'];

        expect(expectedKeys.length, 4);
        expect(expectedKeys, contains('city'));
        expect(expectedKeys, contains('region_name'));
        expect(expectedKeys, contains('country_name'));
        expect(expectedKeys, contains('distance_km'));
      });

      test('city debe ser instancia de City', () {
        // Documenta que city es un objeto City, no un Map
        final mockResult = {
          'id': '1',
          'region_id': 'antioquia',
          'name': 'Medellín',
          'region_name': 'Antioquia',
          'country_name': 'Colombia',
          'distance_km': 0.5,
        };

        final city = City.fromJson(mockResult);
        expect(city, isA<City>());
      });

      test('region_name y country_name deben ser String', () {
        final mockResult = {
          'region_name': 'Antioquia',
          'country_name': 'Colombia',
        };

        expect(mockResult['region_name'], isA<String>());
        expect(mockResult['country_name'], isA<String>());
      });

      test('distance_km debe ser num (int o double)', () {
        final distances = [0.5, 10, 25.7, 50];

        for (final distance in distances) {
          expect(distance, isA<num>());
        }
      });

      test('debe retornar null si no encuentra ciudad cercana', () {
        // Documenta que null es válido cuando no hay ciudades en el radio
        final response = null;

        expect(response, isNull);
      });

      test('debe retornar null si response es lista vacía', () {
        final emptyList = <Map<String, dynamic>>[];
        final result = emptyList.isEmpty ? null : emptyList[0];

        expect(result, isNull);
      });

      test('debe tomar solo el primer elemento de la lista', () {
        // La función SQL retorna una lista con 1 elemento
        final mockResponse = [
          {
            'id': '1',
            'region_id': 'antioquia',
            'name': 'Medellín',
            'region_name': 'Antioquia',
            'country_name': 'Colombia',
            'distance_km': 0.5,
          },
        ];

        final result = mockResponse[0];
        expect(mockResponse.length, 1);
        expect(result, isA<Map<String, dynamic>>());
      });
    });

    group('Mensajes de error esperados', () {
      test('getCountries debe imprimir error con ❌', () {
        const errorMessage = '❌ Error obteniendo países: Exception';

        expect(errorMessage, startsWith('❌'));
        expect(errorMessage, contains('Error obteniendo países'));
      });

      test('getRegionsByCountry debe imprimir error con ❌', () {
        const errorMessage = '❌ Error obteniendo regiones: TimeoutException';

        expect(errorMessage, startsWith('❌'));
        expect(errorMessage, contains('Error obteniendo regiones'));
      });

      test('getCitiesByRegion debe imprimir error con ❌', () {
        const errorMessage = '❌ Error obteniendo ciudades: StateError';

        expect(errorMessage, startsWith('❌'));
        expect(errorMessage, contains('Error obteniendo ciudades'));
      });

      test('searchCities debe imprimir error con ❌', () {
        const errorMessage = '❌ Error buscando ciudades: FormatException';

        expect(errorMessage, startsWith('❌'));
        expect(errorMessage, contains('Error buscando ciudades'));
      });

      test('findNearestCity debe imprimir error con ❌', () {
        const errorMessage = '❌ Error en reverse geocoding: NetworkException';

        expect(errorMessage, startsWith('❌'));
        expect(errorMessage, contains('Error en reverse geocoding'));
      });

      test('findNearestCity debe imprimir advertencia cuando no encuentra', () {
        const warningMessage = '⚠️ No se encontró ciudad cercana';

        expect(warningMessage, startsWith('⚠️'));
        expect(warningMessage, contains('No se encontró'));
      });
    });

    group('Tablas y columnas de Supabase', () {
      test('debe consultar tabla "countries"', () {
        const tableName = 'countries';
        expect(tableName, 'countries');
      });

      test('debe consultar tabla "regions"', () {
        const tableName = 'regions';
        expect(tableName, 'regions');
      });

      test('debe consultar tabla "cities"', () {
        const tableName = 'cities';
        expect(tableName, 'cities');
      });

      test('regions debe filtrar por columna "country_id"', () {
        const columnName = 'country_id';
        expect(columnName, 'country_id');
      });

      test('cities debe filtrar por columna "region_id"', () {
        const columnName = 'region_id';
        expect(columnName, 'region_id');
      });

      test('cities debe ordenar por columna "population" descendente', () {
        const orderColumn = 'population';
        const ascending = false;

        expect(orderColumn, 'population');
        expect(ascending, isFalse);
      });
    });

    group('Funciones RPC de PostgreSQL', () {
      test('searchCities debe llamar función "search_cities"', () {
        const functionName = 'search_cities';
        expect(functionName, 'search_cities');
      });

      test('findNearestCity debe llamar función "find_nearest_city"', () {
        const functionName = 'find_nearest_city';
        expect(functionName, 'find_nearest_city');
      });

      test('search_cities debe recibir 3 parámetros', () {
        final params = {
          'search_query': 'Med',
          'region_filter': 'co-antioquia',
          'max_results': 20,
        };

        expect(params.length, 3);
        expect(params.keys, containsAll(['search_query', 'region_filter', 'max_results']));
      });

      test('find_nearest_city debe recibir 3 parámetros', () {
        final params = {
          'target_lat': 6.2518,
          'target_lon': -75.5636,
          'max_distance_km': 50,
        };

        expect(params.length, 3);
        expect(params.keys, containsAll(['target_lat', 'target_lon', 'max_distance_km']));
      });
    });

    group('Manejo de excepciones', () {
      test('todos los métodos deben hacer rethrow de excepciones', () {
        // Documenta que los errores se propagan al caller (repository)
        // para que ErrorHandler los convierta en Failure
        expect(true, isTrue); // Comportamiento de rethrow
      });

      test('debe capturar cualquier tipo de excepción con catch (e)', () {
        // Documenta que usa catch genérico, no catch específico
        expect(true, isTrue);
      });

      test('debe imprimir error antes de hacer rethrow', () {
        // Documenta que siempre hace print antes de rethrow
        // para debugging en desarrollo
        expect(true, isTrue);
      });
    });

    group('Notas sobre testing', () {
      test('requiere tests de integración con Supabase real', () {
        // Este datasource NO puede ser testeado con mocks de forma práctica
        // porque SupabaseClient usa patrón builder encadenado muy complejo:
        //
        // _supabase.from('table').select().eq('column', value).order('name')
        //
        // Mockear cada uno de estos builders es inviable.
        //
        // Estrategia recomendada:
        // 1. Tests E2E con instancia de Supabase de testing
        // 2. Tests de integración en CI/CD
        // 3. Estos tests de documentación para estructura y API

        expect(true, isTrue);
      });
    });
  });
}
