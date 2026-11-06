import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/location/data/repositories/mock_location_repository.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

void main() {
  late MockLocationRepository repository;

  setUp(() {
    repository = MockLocationRepository();
  });

  group('getCountries', () {
    test('debe retornar Result.success con países mockeados', () async {
      final result = await repository.getCountries();

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isNotNull);
      expect(result.successValue, isA<List<Country>>());
    });

    test('debe retornar exactamente 4 países', () async {
      final result = await repository.getCountries();

      expect(result.successValue?.length, 4);
    });

    test('debe incluir Colombia en la lista', () async {
      final result = await repository.getCountries();

      final colombia = result.successValue?.firstWhere(
        (country) => country.code == 'CO',
      );

      expect(colombia, isNotNull);
      expect(colombia?.name, 'Colombia');
      expect(colombia?.id, 'co');
    });

    test('debe incluir Brasil en la lista', () async {
      final result = await repository.getCountries();

      final brasil = result.successValue?.firstWhere(
        (country) => country.code == 'BR',
      );

      expect(brasil, isNotNull);
      expect(brasil?.name, 'Brasil');
      expect(brasil?.id, 'br');
    });

    test('debe incluir Perú en la lista', () async {
      final result = await repository.getCountries();

      final peru = result.successValue?.firstWhere(
        (country) => country.code == 'PE',
      );

      expect(peru, isNotNull);
      expect(peru?.name, 'Perú');
      expect(peru?.id, 'pe');
    });

    test('debe incluir Ecuador en la lista', () async {
      final result = await repository.getCountries();

      final ecuador = result.successValue?.firstWhere(
        (country) => country.code == 'EC',
      );

      expect(ecuador, isNotNull);
      expect(ecuador?.name, 'Ecuador');
      expect(ecuador?.id, 'ec');
    });

    test('todos los países deben tener id, code y name', () async {
      final result = await repository.getCountries();

      for (final country in result.successValue ?? []) {
        expect(country.id, isNotEmpty);
        expect(country.code, isNotEmpty);
        expect(country.name, isNotEmpty);
      }
    });

    test('debe usar códigos ISO de 2 letras', () async {
      final result = await repository.getCountries();

      for (final country in result.successValue ?? []) {
        expect(country.code.length, 2);
        expect(country.code, equals(country.code.toUpperCase()));
      }
    });

    test('debe ser consistente entre llamadas', () async {
      final result1 = await repository.getCountries();
      final result2 = await repository.getCountries();

      expect(result1.successValue?.length, result2.successValue?.length);
      expect(result1.successValue?.first.code, result2.successValue?.first.code);
    });
  });

  group('getRegionsByCountry', () {
    test('debe retornar regiones de Colombia', () async {
      final result = await repository.getRegionsByCountry('co');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 4);
    });

    test('debe filtrar correctamente por countryId', () async {
      final result = await repository.getRegionsByCountry('co');

      final allFromCountry = result.successValue?.every(
        (region) => region.countryId == 'co',
      ) ?? false;

      expect(allFromCountry, isTrue);
    });

    test('debe incluir Antioquia para Colombia', () async {
      final result = await repository.getRegionsByCountry('co');

      final antioquia = result.successValue?.firstWhere(
        (region) => region.id == 'antioquia',
      );

      expect(antioquia, isNotNull);
      expect(antioquia?.name, 'Antioquia');
      expect(antioquia?.type, 'department');
    });

    test('debe incluir Cundinamarca para Colombia', () async {
      final result = await repository.getRegionsByCountry('co');

      final cundinamarca = result.successValue?.firstWhere(
        (region) => region.id == 'cundinamarca',
      );

      expect(cundinamarca, isNotNull);
      expect(cundinamarca?.name, 'Cundinamarca');
    });

    test('debe incluir Valle del Cauca para Colombia', () async {
      final result = await repository.getRegionsByCountry('co');

      final valle = result.successValue?.firstWhere(
        (region) => region.id == 'valle',
      );

      expect(valle, isNotNull);
      expect(valle?.name, 'Valle del Cauca');
    });

    test('debe incluir Atlántico para Colombia', () async {
      final result = await repository.getRegionsByCountry('co');

      final atlantico = result.successValue?.firstWhere(
        (region) => region.id == 'atlantico',
      );

      expect(atlantico, isNotNull);
      expect(atlantico?.name, 'Atlántico');
    });

    test('debe retornar regiones de Brasil', () async {
      final result = await repository.getRegionsByCountry('br');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 2);
    });

    test('debe incluir São Paulo para Brasil', () async {
      final result = await repository.getRegionsByCountry('br');

      final saoPaulo = result.successValue?.firstWhere(
        (region) => region.id == 'sao-paulo',
      );

      expect(saoPaulo, isNotNull);
      expect(saoPaulo?.name, 'São Paulo');
      expect(saoPaulo?.type, 'state');
      expect(saoPaulo?.countryId, 'br');
    });

    test('debe incluir Rio de Janeiro para Brasil', () async {
      final result = await repository.getRegionsByCountry('br');

      final rio = result.successValue?.firstWhere(
        (region) => region.id == 'rio-de-janeiro',
      );

      expect(rio, isNotNull);
      expect(rio?.name, 'Rio de Janeiro');
      expect(rio?.type, 'state');
    });

    test('debe retornar una región para Perú', () async {
      final result = await repository.getRegionsByCountry('pe');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Lima');
    });

    test('debe retornar una región para Ecuador', () async {
      final result = await repository.getRegionsByCountry('ec');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Pichincha');
      expect(result.successValue?.first.type, 'province');
    });

    test('debe retornar lista vacía para país no existente', () async {
      final result = await repository.getRegionsByCountry('xx');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe manejar diferentes tipos de región', () async {
      final resultCO = await repository.getRegionsByCountry('co');
      final resultBR = await repository.getRegionsByCountry('br');
      final resultEC = await repository.getRegionsByCountry('ec');

      // Colombia usa "department"
      expect(resultCO.successValue?.first.type, 'department');

      // Brasil usa "state"
      expect(resultBR.successValue?.first.type, 'state');

      // Ecuador usa "province"
      expect(resultEC.successValue?.first.type, 'province');
    });

    test('todas las regiones deben tener id, countryId, name y type', () async {
      final result = await repository.getRegionsByCountry('co');

      for (final region in result.successValue ?? []) {
        expect(region.id, isNotEmpty);
        expect(region.countryId, isNotEmpty);
        expect(region.name, isNotEmpty);
        expect(region.type, isNotEmpty);
      }
    });
  });

  group('getCitiesByRegion', () {
    test('debe retornar ciudades de Antioquia', () async {
      final result = await repository.getCitiesByRegion('antioquia');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 3);
    });

    test('debe filtrar correctamente por regionId', () async {
      final result = await repository.getCitiesByRegion('antioquia');

      final allFromRegion = result.successValue?.every(
        (city) => city.regionId == 'antioquia',
      ) ?? false;

      expect(allFromRegion, isTrue);
    });

    test('debe incluir Medellín en Antioquia', () async {
      final result = await repository.getCitiesByRegion('antioquia');

      final medellin = result.successValue?.firstWhere(
        (city) => city.id == 'medellin',
      );

      expect(medellin, isNotNull);
      expect(medellin?.name, 'Medellín');
    });

    test('debe incluir Envigado en Antioquia', () async {
      final result = await repository.getCitiesByRegion('antioquia');

      final envigado = result.successValue?.firstWhere(
        (city) => city.id == 'envigado',
      );

      expect(envigado, isNotNull);
      expect(envigado?.name, 'Envigado');
    });

    test('debe incluir Bello en Antioquia', () async {
      final result = await repository.getCitiesByRegion('antioquia');

      final bello = result.successValue?.firstWhere(
        (city) => city.id == 'bello',
      );

      expect(bello, isNotNull);
      expect(bello?.name, 'Bello');
    });

    test('debe retornar ciudades de Cundinamarca', () async {
      final result = await repository.getCitiesByRegion('cundinamarca');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 2);
    });

    test('debe incluir Bogotá en Cundinamarca', () async {
      final result = await repository.getCitiesByRegion('cundinamarca');

      final bogota = result.successValue?.firstWhere(
        (city) => city.id == 'bogota',
      );

      expect(bogota, isNotNull);
      expect(bogota?.name, 'Bogotá');
    });

    test('debe incluir Soacha en Cundinamarca', () async {
      final result = await repository.getCitiesByRegion('cundinamarca');

      final soacha = result.successValue?.firstWhere(
        (city) => city.id == 'soacha',
      );

      expect(soacha, isNotNull);
      expect(soacha?.name, 'Soacha');
    });

    test('debe retornar Cali para Valle del Cauca', () async {
      final result = await repository.getCitiesByRegion('valle');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Cali');
    });

    test('debe retornar Barranquilla para Atlántico', () async {
      final result = await repository.getCitiesByRegion('atlantico');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Barranquilla');
    });

    test('debe retornar ciudades de São Paulo', () async {
      final result = await repository.getCitiesByRegion('sao-paulo');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 2);
    });

    test('debe incluir São Paulo city en la región de São Paulo', () async {
      final result = await repository.getCitiesByRegion('sao-paulo');

      final city = result.successValue?.firstWhere(
        (city) => city.id == 'sao-paulo-city',
      );

      expect(city, isNotNull);
      expect(city?.name, 'São Paulo');
    });

    test('debe incluir Campinas en São Paulo', () async {
      final result = await repository.getCitiesByRegion('sao-paulo');

      final campinas = result.successValue?.firstWhere(
        (city) => city.id == 'campinas',
      );

      expect(campinas, isNotNull);
      expect(campinas?.name, 'Campinas');
    });

    test('debe retornar Rio de Janeiro city', () async {
      final result = await repository.getCitiesByRegion('rio-de-janeiro');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Rio de Janeiro');
    });

    test('debe retornar Lima para Perú', () async {
      final result = await repository.getCitiesByRegion('lima');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Lima');
    });

    test('debe retornar Quito para Ecuador', () async {
      final result = await repository.getCitiesByRegion('pichincha');

      expect(result.isSuccess, isTrue);
      expect(result.successValue?.length, 1);
      expect(result.successValue?.first.name, 'Quito');
    });

    test('debe retornar lista vacía para región no existente', () async {
      final result = await repository.getCitiesByRegion('non-existent');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('todas las ciudades deben tener id, regionId y name', () async {
      final result = await repository.getCitiesByRegion('antioquia');

      for (final city in result.successValue ?? []) {
        expect(city.id, isNotEmpty);
        expect(city.regionId, isNotEmpty);
        expect(city.name, isNotEmpty);
      }
    });

    test('debe manejar nombres con caracteres especiales', () async {
      final resultCO = await repository.getCitiesByRegion('cundinamarca');
      final resultBR = await repository.getCitiesByRegion('sao-paulo');

      // Bogotá tiene tilde
      final bogota = resultCO.successValue?.first;
      expect(bogota?.name, contains('á'));

      // São Paulo tiene tilde
      final saoPaulo = resultBR.successValue?.first;
      expect(saoPaulo?.name, contains('ão'));
    });
  });

  group('Consistencia de datos', () {
    test('debe tener regiones solo para países existentes', () async {
      final countries = await repository.getCountries();
      final countryIds = countries.successValue?.map((c) => c.id).toSet() ?? {};

      final allRegions = <Region>[];
      for (final countryId in countryIds) {
        final result = await repository.getRegionsByCountry(countryId);
        allRegions.addAll(result.successValue ?? []);
      }

      // Todas las regiones deben pertenecer a países existentes
      for (final region in allRegions) {
        expect(countryIds.contains(region.countryId), isTrue);
      }
    });

    test('debe tener ciudades solo para regiones existentes', () async {
      final countries = await repository.getCountries();
      final countryIds = countries.successValue?.map((c) => c.id).toSet() ?? {};

      final allRegions = <Region>[];
      for (final countryId in countryIds) {
        final result = await repository.getRegionsByCountry(countryId);
        allRegions.addAll(result.successValue ?? []);
      }

      final regionIds = allRegions.map((r) => r.id).toSet();

      final allCities = <City>[];
      for (final regionId in regionIds) {
        final result = await repository.getCitiesByRegion(regionId);
        allCities.addAll(result.successValue ?? []);
      }

      // Todas las ciudades deben pertenecer a regiones existentes
      for (final city in allCities) {
        expect(regionIds.contains(city.regionId), isTrue);
      }
    });

    test('debe tener al menos una región por país', () async {
      final countries = await repository.getCountries();

      for (final country in countries.successValue ?? []) {
        final regions = await repository.getRegionsByCountry(country.id);
        expect(regions.successValue, isNotEmpty, reason: 'País ${country.name} debe tener al menos una región');
      }
    });

    test('debe tener al menos una ciudad por región', () async {
      final countries = await repository.getCountries();
      final countryIds = countries.successValue?.map((c) => c.id).toSet() ?? {};

      for (final countryId in countryIds) {
        final regions = await repository.getRegionsByCountry(countryId);
        for (final region in regions.successValue ?? []) {
          final cities = await repository.getCitiesByRegion(region.id);
          expect(cities.successValue, isNotEmpty, reason: 'Región ${region.name} debe tener al menos una ciudad');
        }
      }
    });
  });

  group('Cobertura completa de datos', () {
    test('debe tener exactamente 8 regiones en total', () async {
      final countries = await repository.getCountries();
      final countryIds = countries.successValue?.map((c) => c.id).toSet() ?? {};

      var totalRegions = 0;
      for (final countryId in countryIds) {
        final result = await repository.getRegionsByCountry(countryId);
        totalRegions += result.successValue?.length ?? 0;
      }

      expect(totalRegions, 8);
    });

    test('debe tener exactamente 12 ciudades en total', () async {
      final countries = await repository.getCountries();
      final countryIds = countries.successValue?.map((c) => c.id).toSet() ?? {};

      var totalCities = 0;
      for (final countryId in countryIds) {
        final regions = await repository.getRegionsByCountry(countryId);
        for (final region in regions.successValue ?? []) {
          final cities = await repository.getCitiesByRegion(region.id);
          totalCities += cities.successValue?.length ?? 0;
        }
      }

      expect(totalCities, 12);
    });

    test('debe cubrir 4 países de Sudamérica', () async {
      final countries = await repository.getCountries();
      final codes = countries.successValue?.map((c) => c.code).toSet() ?? {};

      expect(codes, contains('CO')); // Colombia
      expect(codes, contains('BR')); // Brasil
      expect(codes, contains('PE')); // Perú
      expect(codes, contains('EC')); // Ecuador
    });
  });

  group('searchCities', () {
    test('debe buscar ciudades por nombre', () async {
      final result = await repository.searchCities(query: 'Med');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isNotEmpty);

      // Debe contener Medellín
      final hasMedellin = result.successValue?.any((city) => city.name == 'Medellín') ?? false;
      expect(hasMedellin, isTrue);
    });

    test('debe buscar case-insensitive', () async {
      final result1 = await repository.searchCities(query: 'MEDELLÍN');
      final result2 = await repository.searchCities(query: 'medellín');
      final result3 = await repository.searchCities(query: 'MeDeLLín');

      expect(result1.successValue, isNotEmpty);
      expect(result2.successValue, isNotEmpty);
      expect(result3.successValue, isNotEmpty);

      // Todas deben encontrar Medellín
      final hasMedellin1 = result1.successValue?.any((city) => city.name == 'Medellín') ?? false;
      final hasMedellin2 = result2.successValue?.any((city) => city.name == 'Medellín') ?? false;
      final hasMedellin3 = result3.successValue?.any((city) => city.name == 'Medellín') ?? false;

      expect(hasMedellin1, isTrue);
      expect(hasMedellin2, isTrue);
      expect(hasMedellin3, isTrue);
    });

    test('debe buscar sin filtro de región', () async {
      final result = await repository.searchCities(query: 'São Paulo');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isNotEmpty);

      final saoPaulo = result.successValue?.firstWhere((city) => city.name == 'São Paulo');
      expect(saoPaulo, isNotNull);
    });

    test('debe filtrar por regionId cuando se especifica', () async {
      final result = await repository.searchCities(query: 'a', regionId: 'antioquia');

      expect(result.isSuccess, isTrue);

      // Todas las ciudades deben ser de Antioquia
      final allFromAntioquia = result.successValue?.every((city) => city.regionId == 'antioquia') ?? false;
      expect(allFromAntioquia, isTrue);
    });

    test('debe buscar coincidencias parciales', () async {
      final result = await repository.searchCities(query: 'Bo');

      expect(result.isSuccess, isTrue);

      // Debe encontrar Bogotá
      final hasBogota = result.successValue?.any((city) => city.name.contains('Bogotá')) ?? false;
      expect(hasBogota, isTrue);
    });

    test('debe retornar lista vacía cuando no hay coincidencias', () async {
      final result = await repository.searchCities(query: 'XYZ123NonExistent');

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe limitar resultados con maxResults', () async {
      final result = await repository.searchCities(query: 'a', maxResults: 3);

      expect(result.isSuccess, isTrue);
      expect(result.successValue!.length, lessThanOrEqualTo(3));
    });

    test('debe usar maxResults por defecto de 20', () async {
      final result = await repository.searchCities(query: 'a');

      expect(result.isSuccess, isTrue);
      expect(result.successValue!.length, lessThanOrEqualTo(20));
    });

    test('debe combinar filtro de región y búsqueda', () async {
      final result = await repository.searchCities(
        query: 'São',
        regionId: 'sao-paulo',
      );

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isNotEmpty);

      // Solo ciudades de São Paulo que contengan 'São'
      for (final city in result.successValue ?? []) {
        expect(city.regionId, 'sao-paulo');
        expect(city.name.toLowerCase(), contains('são'));
      }
    });

    test('debe manejar acentos en búsqueda', () async {
      final result1 = await repository.searchCities(query: 'Bogotá');
      final result2 = await repository.searchCities(query: 'São Paulo');
      final result3 = await repository.searchCities(query: 'Atlántico');

      expect(result1.successValue, isNotEmpty);
      expect(result2.successValue, isNotEmpty);
      // Atlántico es región, no ciudad, pero debe buscar sin errores
      expect(result3.isSuccess, isTrue);
    });

    test('debe buscar en todas las regiones cuando regionId es null', () async {
      final result = await repository.searchCities(query: 'a');

      expect(result.isSuccess, isTrue);

      // Debe tener ciudades de diferentes regiones
      final regionIds = result.successValue?.map((city) => city.regionId).toSet() ?? {};
      expect(regionIds.length, greaterThan(1));
    });

    test('debe retornar lista vacía cuando región no existe', () async {
      final result = await repository.searchCities(
        query: 'Med',
        regionId: 'non-existent-region',
      );

      expect(result.isSuccess, isTrue);
      expect(result.successValue, isEmpty);
    });

    test('debe manejar búsqueda con query vacío', () async {
      final result = await repository.searchCities(query: '');

      expect(result.isSuccess, isTrue);
      // Query vacío debería retornar todas las ciudades (hasta maxResults)
      expect(result.successValue, isNotEmpty);
    });

    test('debe encontrar ciudades por nombre completo', () async {
      final result = await repository.searchCities(query: 'Medellín');

      expect(result.isSuccess, isTrue);

      final medellin = result.successValue?.firstWhere((city) => city.name == 'Medellín');
      expect(medellin, isNotNull);
      expect(medellin?.id, 'medellin');
      expect(medellin?.regionId, 'antioquia');
    });

    test('debe encontrar múltiples ciudades con query corto', () async {
      final result = await repository.searchCities(query: 'a');

      expect(result.isSuccess, isTrue);
      expect(result.successValue!.length, greaterThan(1));
    });

    test('debe aplicar maxResults correctamente', () async {
      final result1 = await repository.searchCities(query: 'a', maxResults: 1);
      final result2 = await repository.searchCities(query: 'a', maxResults: 5);
      final result3 = await repository.searchCities(query: 'a', maxResults: 100);

      expect(result1.successValue!.length, lessThanOrEqualTo(1));
      expect(result2.successValue!.length, lessThanOrEqualTo(5));
      expect(result3.successValue!.length, lessThanOrEqualTo(100));
    });

    test('debe ser consistente en búsquedas repetidas', () async {
      final result1 = await repository.searchCities(query: 'Med');
      final result2 = await repository.searchCities(query: 'Med');

      expect(result1.successValue?.length, result2.successValue?.length);
      expect(result1.successValue?.first.id, result2.successValue?.first.id);
    });
  });

  group('Comportamiento del mock', () {
    test('nunca debe retornar Failure', () async {
      final countries = await repository.getCountries();
      final regions = await repository.getRegionsByCountry('co');
      final cities = await repository.getCitiesByRegion('antioquia');
      final search = await repository.searchCities(query: 'Med');

      expect(countries.isFailure, isFalse);
      expect(regions.isFailure, isFalse);
      expect(cities.isFailure, isFalse);
      expect(search.isFailure, isFalse);
    });

    test('debe ser síncrono (respuesta inmediata)', () async {
      final stopwatch = Stopwatch()..start();
      await repository.getCountries();
      stopwatch.stop();

      // Mock debe responder casi instantáneamente (< 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('debe ser determinista (mismos datos siempre)', () async {
      final result1 = await repository.getCountries();
      final result2 = await repository.getCountries();
      final result3 = await repository.getCountries();

      expect(result1.successValue?.length, result2.successValue?.length);
      expect(result2.successValue?.length, result3.successValue?.length);
      expect(result1.successValue?.first.code, result2.successValue?.first.code);
    });
  });
}
