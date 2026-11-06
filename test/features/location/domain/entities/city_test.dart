import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

void main() {
  group('City', () {
    group('Constructor', () {
      test('debe crear instancia con todos los campos', () {
        const city = City(
          id: '1',
          regionId: 'region-1',
          name: 'Los Angeles',
        );

        expect(city.id, '1');
        expect(city.regionId, 'region-1');
        expect(city.name, 'Los Angeles');
      });

      test('debe crear instancia con ids numéricos como string', () {
        const city = City(
          id: '123',
          regionId: '456',
          name: 'New York',
        );

        expect(city.id, '123');
        expect(city.regionId, '456');
        expect(city.name, 'New York');
      });

      test('debe crear instancia con caracteres especiales en el nombre', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'São Paulo',
        );

        expect(city.name, 'São Paulo');
      });

      test('debe crear instancia con ids UUID', () {
        const city = City(
          id: 'uuid-city-abc',
          regionId: 'uuid-region-xyz',
          name: 'Test City',
        );

        expect(city.id, 'uuid-city-abc');
        expect(city.regionId, 'uuid-region-xyz');
      });

      test('debe crear instancia con nombres con espacios', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'New York City',
        );

        expect(city.name, contains(' '));
        expect(city.name.split(' ').length, 3);
      });
    });

    group('fromJson', () {
      test('debe crear City desde JSON válido', () {
        final json = {
          'id': '1',
          'region_id': 'region-1',
          'name': 'Los Angeles',
        };

        final city = City.fromJson(json);

        expect(city.id, '1');
        expect(city.regionId, 'region-1');
        expect(city.name, 'Los Angeles');
      });

      test('debe convertir snake_case a camelCase correctamente', () {
        final json = {
          'id': '123',
          'region_id': '456',
          'name': 'Test City',
        };

        final city = City.fromJson(json);

        expect(city.regionId, '456'); // region_id -> regionId
      });

      test('debe manejar JSON con campos adicionales', () {
        final json = {
          'id': '1',
          'region_id': '1',
          'name': 'Chicago',
          'extra_field': 'ignored',
          'population': 2700000,
          'latitude': 41.8781,
          'longitude': -87.6298,
        };

        final city = City.fromJson(json);

        expect(city.id, '1');
        expect(city.name, 'Chicago');
      });

      test('debe manejar nombres con acentos', () {
        final json = {
          'id': '1',
          'region_id': '1',
          'name': 'Bogotá',
        };

        final city = City.fromJson(json);

        expect(city.name, 'Bogotá');
      });

      test('debe manejar nombres con ñ', () {
        final json = {
          'id': '1',
          'region_id': '1',
          'name': 'La Coruña',
        };

        final city = City.fromJson(json);

        expect(city.name, 'La Coruña');
      });

      test('debe manejar nombres con apóstrofes', () {
        final json = {
          'id': '1',
          'region_id': '1',
          'name': "N'Djamena",
        };

        final city = City.fromJson(json);

        expect(city.name, "N'Djamena");
      });

      test('debe crear City desde JSON de Supabase real', () {
        final json = {
          'id': 'uuid-city-123',
          'region_id': 'uuid-region-456',
          'name': 'Medellín',
        };

        final city = City.fromJson(json);

        expect(city.id, 'uuid-city-123');
        expect(city.regionId, 'uuid-region-456');
        expect(city.name, 'Medellín');
      });
    });

    group('toJson', () {
      test('debe convertir City a JSON correctamente', () {
        const city = City(
          id: '1',
          regionId: 'region-1',
          name: 'Los Angeles',
        );

        final json = city.toJson();

        expect(json['id'], '1');
        expect(json['region_id'], 'region-1');
        expect(json['name'], 'Los Angeles');
        expect(json.keys.length, 3);
      });

      test('debe convertir camelCase a snake_case correctamente', () {
        const city = City(
          id: '123',
          regionId: '456',
          name: 'Test',
        );

        final json = city.toJson();

        expect(json['region_id'], '456'); // regionId -> region_id
      });

      test('debe generar JSON con todos los campos requeridos', () {
        const city = City(
          id: '789',
          regionId: '321',
          name: 'Toronto',
        );

        final json = city.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('region_id'), isTrue);
        expect(json.containsKey('name'), isTrue);
      });

      test('debe preservar caracteres especiales', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'Zürich',
        );

        final json = city.toJson();

        expect(json['name'], 'Zürich');
      });

      test('debe generar JSON válido para Supabase', () {
        const city = City(
          id: 'uuid-abc',
          regionId: 'uuid-xyz',
          name: 'París',
        );

        final json = city.toJson();

        expect(json['id'], isA<String>());
        expect(json['region_id'], isA<String>());
        expect(json['name'], isA<String>());
      });
    });

    group('Serialización round-trip', () {
      test('debe mantener los datos después de fromJson -> toJson', () {
        const original = City(
          id: '1',
          regionId: 'region-1',
          name: 'Los Angeles',
        );

        final json = original.toJson();
        final restored = City.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.regionId, original.regionId);
        expect(restored.name, original.name);
      });

      test('debe ser idempotente con múltiples conversiones', () {
        const original = City(
          id: '123',
          regionId: '456',
          name: 'Test City',
        );

        final json1 = original.toJson();
        final city1 = City.fromJson(json1);
        final json2 = city1.toJson();
        final city2 = City.fromJson(json2);

        expect(city2.id, original.id);
        expect(city2.regionId, original.regionId);
        expect(city2.name, original.name);
      });

      test('debe preservar snake_case en JSON después de round-trip', () {
        final originalJson = {
          'id': '1',
          'region_id': '2',
          'name': 'Test',
        };

        final city = City.fromJson(originalJson);
        final resultJson = city.toJson();

        expect(resultJson['region_id'], originalJson['region_id']);
        expect(resultJson.containsKey('regionId'), isFalse); // No debe tener camelCase
      });
    });

    group('Inmutabilidad', () {
      test('debe ser const', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'Los Angeles',
        );

        expect(city, isNotNull);
      });

      test('debe crear instancias diferentes con diferentes valores', () {
        const city1 = City(id: '1', regionId: '1', name: 'Los Angeles');
        const city2 = City(id: '2', regionId: '1', name: 'San Francisco');

        expect(city1.id, isNot(equals(city2.id)));
        expect(city1.name, isNot(equals(city2.name)));
      });
    });

    group('Casos edge', () {
      test('debe manejar id muy largo', () {
        const city = City(
          id: 'very-long-uuid-string-123456789-abcdefghijklmnopqrstuvwxyz',
          regionId: 'region-1',
          name: 'Test',
        );

        expect(city.id.length, greaterThan(10));
      });

      test('debe manejar nombre muy largo', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch',
        );

        expect(city.name.length, greaterThan(20));
      });

      test('debe manejar nombres con múltiples palabras', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'San José de Costa Rica',
        );

        expect(city.name, contains(' '));
        expect(city.name.split(' ').length, greaterThan(1));
      });

      test('debe manejar nombres con guiones', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'Saint-Pierre',
        );

        expect(city.name, contains('-'));
      });

      test('debe manejar nombres con emojis', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'Emoji City 🏙️',
        );

        expect(city.name, contains('🏙️'));
      });

      test('debe manejar JSON con strings vacíos (caso inválido pero tolerado)', () {
        final json = {
          'id': '',
          'region_id': '',
          'name': '',
        };

        final city = City.fromJson(json);

        expect(city.id, isEmpty);
        expect(city.regionId, isEmpty);
        expect(city.name, isEmpty);
      });

      test('debe manejar nombres con números', () {
        const city = City(
          id: '1',
          regionId: '1',
          name: 'Ciudad 2000',
        );

        expect(city.name, contains('2000'));
      });

      test('debe manejar nombres en diferentes idiomas', () {
        const cities = [
          City(id: '1', regionId: '1', name: '東京'), // Tokio en japonés
          City(id: '2', regionId: '1', name: 'Москва'), // Moscú en ruso
          City(id: '3', regionId: '1', name: 'القاهرة'), // El Cairo en árabe
        ];

        expect(cities[0].name, '東京');
        expect(cities[1].name, 'Москва');
        expect(cities[2].name, 'القاهرة');
      });
    });

    group('Uso en listas', () {
      test('debe poder crear lista de Cities', () {
        const cities = [
          City(id: '1', regionId: '1', name: 'Los Angeles'),
          City(id: '2', regionId: '1', name: 'San Francisco'),
          City(id: '3', regionId: '1', name: 'San Diego'),
        ];

        expect(cities.length, 3);
        expect(cities[0].name, 'Los Angeles');
        expect(cities[1].name, 'San Francisco');
        expect(cities[2].name, 'San Diego');
      });

      test('debe poder filtrar Cities por regionId', () {
        const cities = [
          City(id: '1', regionId: 'ca', name: 'Los Angeles'),
          City(id: '2', regionId: 'tx', name: 'Houston'),
          City(id: '3', regionId: 'ca', name: 'San Francisco'),
        ];

        final caCities = cities.where((c) => c.regionId == 'ca').toList();

        expect(caCities.length, 2);
        expect(caCities[0].name, 'Los Angeles');
        expect(caCities[1].name, 'San Francisco');
      });

      test('debe poder mapear lista de JSON a Cities', () {
        final jsonList = [
          {'id': '1', 'region_id': '1', 'name': 'Los Angeles'},
          {'id': '2', 'region_id': '1', 'name': 'San Francisco'},
        ];

        final cities = jsonList.map((json) => City.fromJson(json)).toList();

        expect(cities.length, 2);
        expect(cities[0], isA<City>());
        expect(cities[1], isA<City>());
      });

      test('debe poder ordenar cities por nombre', () {
        const cities = [
          City(id: '3', regionId: '1', name: 'San Diego'),
          City(id: '1', regionId: '1', name: 'Los Angeles'),
          City(id: '2', regionId: '1', name: 'San Francisco'),
        ];

        final sorted = List<City>.from(cities)..sort((a, b) => a.name.compareTo(b.name));

        expect(sorted[0].name, 'Los Angeles');
        expect(sorted[1].name, 'San Diego');
        expect(sorted[2].name, 'San Francisco');
      });

      test('debe poder buscar city por id', () {
        const cities = [
          City(id: '1', regionId: '1', name: 'Los Angeles'),
          City(id: '2', regionId: '1', name: 'San Francisco'),
          City(id: '3', regionId: '1', name: 'San Diego'),
        ];

        final city = cities.where((c) => c.id == '2').firstOrNull;

        expect(city, isNotNull);
        expect(city?.name, 'San Francisco');
      });

      test('debe poder buscar city por nombre parcial', () {
        const cities = [
          City(id: '1', regionId: '1', name: 'Los Angeles'),
          City(id: '2', regionId: '1', name: 'San Francisco'),
          City(id: '3', regionId: '1', name: 'San Diego'),
        ];

        final sanCities = cities.where((c) => c.name.startsWith('San')).toList();

        expect(sanCities.length, 2);
        expect(sanCities[0].name, 'San Francisco');
        expect(sanCities[1].name, 'San Diego');
      });
    });

    group('Comparación', () {
      test('dos cities con mismo id deben ser iguales si son const', () {
        const city1 = City(id: '1', regionId: '1', name: 'Test');
        const city2 = City(id: '1', regionId: '1', name: 'Test');

        // Como son const con mismos valores, son la misma instancia
        expect(city1 == city2, isTrue);
      });

      test('dos cities con diferentes ids no deben ser iguales', () {
        const city1 = City(id: '1', regionId: '1', name: 'Test');
        const city2 = City(id: '2', regionId: '1', name: 'Test');

        expect(city1.id == city2.id, isFalse);
      });
    });
  });
}
