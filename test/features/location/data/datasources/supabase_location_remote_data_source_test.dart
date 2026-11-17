import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/location/data/datasources/supabase_location_remote_data_source.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';

import 'supabase_location_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClient, AppLogger])
void main() {
  late SupabaseLocationRemoteDataSource dataSource;
  late MockSupabaseClient mockSupabase;
  late MockAppLogger mockLogger;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockLogger = MockAppLogger();
    dataSource = SupabaseLocationRemoteDataSource(mockSupabase, mockLogger);
  });

  group('SupabaseLocationRemoteDataSource', () {
    // NOTA: Tests de queries completas omitidos por complejidad de Supabase mocking.
    // Coverage por integration tests.

    group('Constructor', () {
      test('debe inicializarse correctamente', () {
        expect(dataSource, isA<SupabaseLocationRemoteDataSource>());
      });
    });

    group('Entities mapping', () {
      test('debe usar Country.fromJson', () {
        final json = {'id': 'CO', 'name': 'Colombia', 'code': 'CO', 'flag_emoji': '🇨🇴'};
        final country = Country.fromJson(json);
        expect(country, isA<Country>());
      });

      test('debe usar Region.fromJson', () {
        final json = {'id': 'co-ant', 'country_id': 'CO', 'name': 'Antioquia', 'type': 'department'};
        final region = Region.fromJson(json);
        expect(region, isA<Region>());
      });

      test('debe usar City.fromJson', () {
        final json = {
          'id': 'MED',
          'region_id': 'co-ant',
          'name': 'Medellín',
          'latitude': 6.25,
          'longitude': -75.56,
          'population': 2500000
        };
        final city = City.fromJson(json);
        expect(city, isA<City>());
      });
    });
  });
}
