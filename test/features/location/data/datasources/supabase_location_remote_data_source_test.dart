import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/features/location/data/datasources/supabase_location_remote_data_source.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

import '../../../../helpers/fake_supabase_http.dart';
import '../../../../helpers/mock_app_logger_helper.dart';

void main() {
  late FakeSupabaseHttp fake;
  late SupabaseLocationRemoteDataSource dataSource;

  setUp(() {
    fake = FakeSupabaseHttp();
    dataSource = SupabaseLocationRemoteDataSource(fake.client, MockAppLogger());
  });

  group('getCountries', () {
    test('consulta countries y mapea a Country', () async {
      fake.respondJson([
        {'id': 'AR', 'code': 'AR', 'name': 'Argentina'},
        {'id': 'CO', 'code': 'CO', 'name': 'Colombia'},
      ]);

      final countries = await dataSource.getCountries();

      expect(fake.lastRequest.method, 'GET');
      expect(fake.lastRequest.url.path, '/rest/v1/countries');
      expect(countries.map((c) => c.name), ['Argentina', 'Colombia']);
      expect(countries.first.code, 'AR');
    });

    test('retorna lista vacía cuando la tabla está vacía', () async {
      fake.respondJson([]);

      expect(await dataSource.getCountries(), isEmpty);
    });

    test('propaga PostgrestException', () async {
      fake.respondError(400, message: 'permission denied');

      expect(dataSource.getCountries(), throwsA(isA<PostgrestException>()));
    });

    test('ordena por name ascendente', () async {
      fake.respondJson([]);
      await dataSource.getCountries();
      expect(
        fake.lastRequest.url.queryParameters['order'],
        'name.asc.nullslast',
      );
    });
  });

  group('getRegionsByCountry', () {
    test('filtra por country_id y mapea a Region', () async {
      fake.respondJson([
        {
          'id': 'co-ant',
          'country_id': 'CO',
          'name': 'Antioquia',
          'type': 'department',
        },
      ]);

      final regions = await dataSource.getRegionsByCountry('CO');

      final params = fake.lastRequest.url.queryParameters;
      expect(fake.lastRequest.url.path, '/rest/v1/regions');
      expect(params['country_id'], 'eq.CO');
      expect(regions.single.id, 'co-ant');
      expect(regions.single.type, 'department');
    });

    test('propaga PostgrestException', () async {
      fake.respondError(400);

      expect(
        dataSource.getRegionsByCountry('CO'),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('ordena por name ascendente', () async {
      fake.respondJson([]);
      await dataSource.getRegionsByCountry('CO');
      expect(
        fake.lastRequest.url.queryParameters['order'],
        'name.asc.nullslast',
      );
    });
  });

  group('getCitiesByRegion', () {
    test('filtra por region_id y ordena primero por population desc', () async {
      fake.respondJson([
        {'id': 'MED', 'region_id': 'co-ant', 'name': 'Medellín'},
        {'id': 'ENV', 'region_id': 'co-ant', 'name': 'Envigado'},
      ]);

      final cities = await dataSource.getCitiesByRegion('co-ant');

      final params = fake.lastRequest.url.queryParameters;
      expect(fake.lastRequest.url.path, '/rest/v1/cities');
      expect(params['region_id'], 'eq.co-ant');
      expect(params['order'], startsWith('population.desc'));
      expect(cities.map((c) => c.id), ['MED', 'ENV']);
    });

    test('propaga PostgrestException', () async {
      fake.respondError(400);

      expect(
        dataSource.getCitiesByRegion('co-ant'),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('desempata por name ascendente', () async {
      fake.respondJson([]);
      await dataSource.getCitiesByRegion('co-ant');
      expect(
        fake.lastRequest.url.queryParameters['order'],
        'population.desc.nullslast,name.asc.nullslast',
      );
    });
  });

  group('searchCities', () {
    test('llama al RPC search_cities con query, región y límite', () async {
      fake.respondJson([
        {'id': 'MED', 'region_id': 'co-ant', 'name': 'Medellín'},
      ]);

      final cities = await dataSource.searchCities(
        'Med',
        'co-ant',
        maxResults: 5,
      );

      expect(fake.lastRequest.url.path, '/rest/v1/rpc/search_cities');
      expect(fake.lastBody, {
        'search_query': 'Med',
        'region_filter': 'co-ant',
        'max_results': 5,
      });
      expect(cities.single.name, 'Medellín');
    });

    test('usa maxResults 20 por defecto y región null', () async {
      fake.respondJson([]);

      await dataSource.searchCities('Bog', null);

      expect(fake.lastBody['region_filter'], isNull);
      expect(fake.lastBody['max_results'], 20);
    });

    test('retorna lista vacía cuando el RPC responde null', () async {
      fake.respondRaw('null');

      expect(await dataSource.searchCities('x', null), isEmpty);
    });

    test('propaga PostgrestException', () async {
      fake.respondError(400);

      expect(
        dataSource.searchCities('x', null),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('findNearestCity', () {
    test(
      'llama al RPC find_nearest_city y retorna ciudad con metadatos',
      () async {
        fake.respondJson([
          {
            'id': 'MED',
            'region_id': 'co-ant',
            'name': 'Medellín',
            'region_name': 'Antioquia',
            'country_name': 'Colombia',
            'distance_km': 0.02,
          },
        ]);

        final result = await dataSource.findNearestCity(6.2518, -75.5636);

        expect(fake.lastRequest.url.path, '/rest/v1/rpc/find_nearest_city');
        expect(fake.lastBody, {
          'target_lat': 6.2518,
          'target_lon': -75.5636,
          'max_distance_km': 50,
        });
        expect(result, isNotNull);
        expect((result!['city'] as City).id, 'MED');
        expect(result['region_name'], 'Antioquia');
        expect(result['country_name'], 'Colombia');
        expect(result['distance_km'], 0.02);
      },
    );

    test('envía maxDistanceKm personalizado', () async {
      fake.respondJson([]);

      await dataSource.findNearestCity(0, 0, maxDistanceKm: 10);

      expect(fake.lastBody['max_distance_km'], 10);
    });

    test('retorna null cuando el RPC responde lista vacía', () async {
      fake.respondJson([]);

      expect(await dataSource.findNearestCity(0, 0), isNull);
    });

    test('retorna null cuando el RPC responde null', () async {
      fake.respondRaw('null');

      expect(await dataSource.findNearestCity(0, 0), isNull);
    });

    test('retorna null cuando el RPC responde algo que no es lista', () async {
      fake.respondJson({'id': 'MED'});

      expect(await dataSource.findNearestCity(0, 0), isNull);
    });

    test('propaga PostgrestException', () async {
      fake.respondError(400);

      expect(
        dataSource.findNearestCity(0, 0),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
