import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/location/domain/entities/region.dart';

void main() {
  group('Region', () {
    group('Constructor', () {
      test('debe crear instancia con todos los campos', () {
        const region = Region(
          id: '1',
          countryId: 'country-1',
          name: 'California',
          type: 'state',
        );

        expect(region.id, '1');
        expect(region.countryId, 'country-1');
        expect(region.name, 'California');
        expect(region.type, 'state');
      });

      test('debe crear instancia con diferentes tipos de región', () {
        const province = Region(
          id: '1',
          countryId: '1',
          name: 'Ontario',
          type: 'province',
        );

        const department = Region(
          id: '2',
          countryId: '2',
          name: 'Cundinamarca',
          type: 'department',
        );

        expect(province.type, 'province');
        expect(department.type, 'department');
      });

      test('debe crear instancia con caracteres especiales en el nombre', () {
        const region = Region(
          id: '1',
          countryId: '1',
          name: 'Bogotá D.C.',
          type: 'capital',
        );

        expect(region.name, 'Bogotá D.C.');
      });

      test('debe crear instancia con ids UUID', () {
        const region = Region(
          id: 'uuid-abc-123',
          countryId: 'uuid-xyz-789',
          name: 'Test Region',
          type: 'state',
        );

        expect(region.id, 'uuid-abc-123');
        expect(region.countryId, 'uuid-xyz-789');
      });
    });

    group('fromJson', () {
      test('debe crear Region desde JSON válido', () {
        final json = {
          'id': '1',
          'country_id': 'country-1',
          'name': 'California',
          'type': 'state',
        };

        final region = Region.fromJson(json);

        expect(region.id, '1');
        expect(region.countryId, 'country-1');
        expect(region.name, 'California');
        expect(region.type, 'state');
      });

      test('debe convertir snake_case a camelCase correctamente', () {
        final json = {
          'id': '123',
          'country_id': '456',
          'name': 'Test Region',
          'type': 'province',
        };

        final region = Region.fromJson(json);

        expect(region.countryId, '456'); // country_id -> countryId
      });

      test('debe manejar JSON con campos adicionales', () {
        final json = {
          'id': '1',
          'country_id': '1',
          'name': 'Texas',
          'type': 'state',
          'extra_field': 'ignored',
          'population': 29000000,
          'capital': 'Austin',
        };

        final region = Region.fromJson(json);

        expect(region.id, '1');
        expect(region.name, 'Texas');
      });

      test('debe crear Region con diferentes tipos', () {
        final stateJson = {'id': '1', 'country_id': '1', 'name': 'State', 'type': 'state'};
        final provinceJson = {'id': '2', 'country_id': '1', 'name': 'Province', 'type': 'province'};
        final departmentJson = {'id': '3', 'country_id': '1', 'name': 'Department', 'type': 'department'};

        final state = Region.fromJson(stateJson);
        final province = Region.fromJson(provinceJson);
        final department = Region.fromJson(departmentJson);

        expect(state.type, 'state');
        expect(province.type, 'province');
        expect(department.type, 'department');
      });

      test('debe manejar nombres con acentos y ñ', () {
        final json = {
          'id': '1',
          'country_id': '1',
          'name': 'Bogotá',
          'type': 'capital',
        };

        final region = Region.fromJson(json);

        expect(region.name, 'Bogotá');
      });

      test('debe crear Region desde JSON de Supabase real', () {
        final json = {
          'id': 'uuid-region-123',
          'country_id': 'uuid-country-456',
          'name': 'Antioquia',
          'type': 'department',
        };

        final region = Region.fromJson(json);

        expect(region.id, 'uuid-region-123');
        expect(region.countryId, 'uuid-country-456');
        expect(region.name, 'Antioquia');
        expect(region.type, 'department');
      });
    });

    group('toJson', () {
      test('debe convertir Region a JSON correctamente', () {
        const region = Region(
          id: '1',
          countryId: 'country-1',
          name: 'California',
          type: 'state',
        );

        final json = region.toJson();

        expect(json['id'], '1');
        expect(json['country_id'], 'country-1');
        expect(json['name'], 'California');
        expect(json['type'], 'state');
        expect(json.keys.length, 4);
      });

      test('debe convertir camelCase a snake_case correctamente', () {
        const region = Region(
          id: '123',
          countryId: '456',
          name: 'Test',
          type: 'state',
        );

        final json = region.toJson();

        expect(json['country_id'], '456'); // countryId -> country_id
      });

      test('debe generar JSON con todos los campos requeridos', () {
        const region = Region(
          id: '789',
          countryId: '321',
          name: 'Ontario',
          type: 'province',
        );

        final json = region.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('country_id'), isTrue);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('type'), isTrue);
      });

      test('debe preservar caracteres especiales', () {
        const region = Region(
          id: '1',
          countryId: '1',
          name: 'São Paulo',
          type: 'state',
        );

        final json = region.toJson();

        expect(json['name'], 'São Paulo');
      });

      test('debe generar JSON válido para Supabase', () {
        const region = Region(
          id: 'uuid-abc',
          countryId: 'uuid-xyz',
          name: 'Île-de-France',
          type: 'region',
        );

        final json = region.toJson();

        expect(json['id'], isA<String>());
        expect(json['country_id'], isA<String>());
        expect(json['name'], isA<String>());
        expect(json['type'], isA<String>());
      });
    });

    group('Serialización round-trip', () {
      test('debe mantener los datos después de fromJson -> toJson', () {
        const original = Region(
          id: '1',
          countryId: 'country-1',
          name: 'California',
          type: 'state',
        );

        final json = original.toJson();
        final restored = Region.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.countryId, original.countryId);
        expect(restored.name, original.name);
        expect(restored.type, original.type);
      });

      test('debe ser idempotente con múltiples conversiones', () {
        const original = Region(
          id: '123',
          countryId: '456',
          name: 'Test Region',
          type: 'province',
        );

        final json1 = original.toJson();
        final region1 = Region.fromJson(json1);
        final json2 = region1.toJson();
        final region2 = Region.fromJson(json2);

        expect(region2.id, original.id);
        expect(region2.countryId, original.countryId);
        expect(region2.name, original.name);
        expect(region2.type, original.type);
      });

      test('debe preservar snake_case en JSON después de round-trip', () {
        final originalJson = {
          'id': '1',
          'country_id': '2',
          'name': 'Test',
          'type': 'state',
        };

        final region = Region.fromJson(originalJson);
        final resultJson = region.toJson();

        expect(resultJson['country_id'], originalJson['country_id']);
        expect(resultJson.containsKey('countryId'), isFalse); // No debe tener camelCase
      });
    });

    group('Inmutabilidad', () {
      test('debe ser const', () {
        const region = Region(
          id: '1',
          countryId: '1',
          name: 'California',
          type: 'state',
        );

        expect(region, isNotNull);
      });

      test('debe crear instancias diferentes con diferentes valores', () {
        const region1 = Region(id: '1', countryId: '1', name: 'California', type: 'state');
        const region2 = Region(id: '2', countryId: '1', name: 'Texas', type: 'state');

        expect(region1.id, isNot(equals(region2.id)));
        expect(region1.name, isNot(equals(region2.name)));
      });
    });

    group('Casos edge', () {
      test('debe manejar id muy largo', () {
        const region = Region(
          id: 'very-long-uuid-string-123456789-abcdefghijklmnopqrstuvwxyz',
          countryId: 'country-1',
          name: 'Test',
          type: 'state',
        );

        expect(region.id.length, greaterThan(10));
      });

      test('debe manejar nombre muy largo', () {
        const region = Region(
          id: '1',
          countryId: '1',
          name: 'Very Long Region Name With Many Words And Characters',
          type: 'state',
        );

        expect(region.name.length, greaterThan(20));
      });

      test('debe manejar diferentes tipos de región', () {
        const types = [
          'state',
          'province',
          'department',
          'region',
          'prefecture',
          'canton',
          'district',
        ];

        for (final type in types) {
          final region = Region(
            id: '1',
            countryId: '1',
            name: 'Test',
            type: type,
          );

          expect(region.type, type);
        }
      });

      test('debe manejar nombres con emojis', () {
        const region = Region(
          id: '1',
          countryId: '1',
          name: 'Emoji Region 🌴',
          type: 'state',
        );

        expect(region.name, contains('🌴'));
      });

      test('debe manejar JSON con strings vacíos (caso inválido pero tolerado)', () {
        final json = {
          'id': '',
          'country_id': '',
          'name': '',
          'type': '',
        };

        final region = Region.fromJson(json);

        expect(region.id, isEmpty);
        expect(region.countryId, isEmpty);
        expect(region.name, isEmpty);
        expect(region.type, isEmpty);
      });
    });

    group('Uso en listas', () {
      test('debe poder crear lista de Regions', () {
        const regions = [
          Region(id: '1', countryId: '1', name: 'California', type: 'state'),
          Region(id: '2', countryId: '1', name: 'Texas', type: 'state'),
          Region(id: '3', countryId: '1', name: 'New York', type: 'state'),
        ];

        expect(regions.length, 3);
        expect(regions[0].name, 'California');
        expect(regions[1].name, 'Texas');
        expect(regions[2].name, 'New York');
      });

      test('debe poder filtrar Regions por countryId', () {
        const regions = [
          Region(id: '1', countryId: 'us', name: 'California', type: 'state'),
          Region(id: '2', countryId: 'ca', name: 'Ontario', type: 'province'),
          Region(id: '3', countryId: 'us', name: 'Texas', type: 'state'),
        ];

        final usRegions = regions.where((r) => r.countryId == 'us').toList();

        expect(usRegions.length, 2);
        expect(usRegions[0].name, 'California');
        expect(usRegions[1].name, 'Texas');
      });

      test('debe poder mapear lista de JSON a Regions', () {
        final jsonList = [
          {'id': '1', 'country_id': '1', 'name': 'California', 'type': 'state'},
          {'id': '2', 'country_id': '1', 'name': 'Texas', 'type': 'state'},
        ];

        final regions = jsonList.map((json) => Region.fromJson(json)).toList();

        expect(regions.length, 2);
        expect(regions[0], isA<Region>());
        expect(regions[1], isA<Region>());
      });

      test('debe poder agrupar regions por tipo', () {
        const regions = [
          Region(id: '1', countryId: '1', name: 'California', type: 'state'),
          Region(id: '2', countryId: '2', name: 'Ontario', type: 'province'),
          Region(id: '3', countryId: '1', name: 'Texas', type: 'state'),
          Region(id: '4', countryId: '3', name: 'Antioquia', type: 'department'),
        ];

        final states = regions.where((r) => r.type == 'state').toList();
        final provinces = regions.where((r) => r.type == 'province').toList();
        final departments = regions.where((r) => r.type == 'department').toList();

        expect(states.length, 2);
        expect(provinces.length, 1);
        expect(departments.length, 1);
      });
    });
  });
}
