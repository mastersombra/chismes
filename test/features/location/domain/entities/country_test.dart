import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/location/domain/entities/country.dart';

void main() {
  group('Country', () {
    group('Constructor', () {
      test('debe crear instancia con todos los campos', () {
        const country = Country(
          id: '1',
          code: 'US',
          name: 'United States',
        );

        expect(country.id, '1');
        expect(country.code, 'US');
        expect(country.name, 'United States');
      });

      test('debe crear instancia con id numérico como string', () {
        const country = Country(
          id: '123',
          code: 'MX',
          name: 'Mexico',
        );

        expect(country.id, '123');
        expect(country.code, 'MX');
        expect(country.name, 'Mexico');
      });

      test('debe crear instancia con código de dos letras', () {
        const country = Country(
          id: '1',
          code: 'CO',
          name: 'Colombia',
        );

        expect(country.code, 'CO');
        expect(country.code.length, 2);
      });

      test('debe crear instancia con caracteres especiales en el nombre', () {
        const country = Country(
          id: '1',
          code: 'CI',
          name: "Côte d'Ivoire",
        );

        expect(country.name, "Côte d'Ivoire");
      });
    });

    group('fromJson', () {
      test('debe crear Country desde JSON válido', () {
        final json = {
          'id': '1',
          'code': 'US',
          'name': 'United States',
        };

        final country = Country.fromJson(json);

        expect(country.id, '1');
        expect(country.code, 'US');
        expect(country.name, 'United States');
      });

      test('debe crear Country desde JSON con id numérico', () {
        final json = {
          'id': '456',
          'code': 'CA',
          'name': 'Canada',
        };

        final country = Country.fromJson(json);

        expect(country.id, '456');
        expect(country.code, 'CA');
        expect(country.name, 'Canada');
      });

      test('debe manejar JSON con campos adicionales', () {
        final json = {
          'id': '1',
          'code': 'BR',
          'name': 'Brazil',
          'extra_field': 'ignored',
          'population': 211000000,
        };

        final country = Country.fromJson(json);

        expect(country.id, '1');
        expect(country.code, 'BR');
        expect(country.name, 'Brazil');
      });

      test('debe manejar nombres con caracteres especiales', () {
        final json = {
          'id': '1',
          'code': 'ES',
          'name': 'España',
        };

        final country = Country.fromJson(json);

        expect(country.name, 'España');
      });

      test('debe crear Country con código en minúsculas', () {
        final json = {
          'id': '1',
          'code': 'uk',
          'name': 'United Kingdom',
        };

        final country = Country.fromJson(json);

        expect(country.code, 'uk');
      });

      test('debe crear Country desde JSON de Supabase real', () {
        // Formato típico de Supabase
        final json = {
          'id': 'uuid-123-456',
          'code': 'AR',
          'name': 'Argentina',
        };

        final country = Country.fromJson(json);

        expect(country.id, 'uuid-123-456');
        expect(country.code, 'AR');
        expect(country.name, 'Argentina');
      });
    });

    group('toJson', () {
      test('debe convertir Country a JSON correctamente', () {
        const country = Country(
          id: '1',
          code: 'US',
          name: 'United States',
        );

        final json = country.toJson();

        expect(json['id'], '1');
        expect(json['code'], 'US');
        expect(json['name'], 'United States');
        expect(json.keys.length, 3);
      });

      test('debe generar JSON con todos los campos requeridos', () {
        const country = Country(
          id: '789',
          code: 'JP',
          name: 'Japan',
        );

        final json = country.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('code'), isTrue);
        expect(json.containsKey('name'), isTrue);
      });

      test('debe preservar caracteres especiales en el nombre', () {
        const country = Country(
          id: '1',
          code: 'DE',
          name: 'Deutschland',
        );

        final json = country.toJson();

        expect(json['name'], 'Deutschland');
      });

      test('debe generar JSON válido para Supabase', () {
        const country = Country(
          id: 'uuid-abc-123',
          code: 'FR',
          name: 'France',
        );

        final json = country.toJson();

        // Verificar que el formato es compatible con Supabase
        expect(json['id'], isA<String>());
        expect(json['code'], isA<String>());
        expect(json['name'], isA<String>());
      });
    });

    group('Serialización round-trip', () {
      test('debe mantener los datos después de fromJson -> toJson', () {
        const original = Country(
          id: '1',
          code: 'US',
          name: 'United States',
        );

        final json = original.toJson();
        final restored = Country.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.code, original.code);
        expect(restored.name, original.name);
      });

      test('debe ser idempotente con múltiples conversiones', () {
        const original = Country(
          id: '123',
          code: 'MX',
          name: 'México',
        );

        final json1 = original.toJson();
        final country1 = Country.fromJson(json1);
        final json2 = country1.toJson();
        final country2 = Country.fromJson(json2);

        expect(country2.id, original.id);
        expect(country2.code, original.code);
        expect(country2.name, original.name);
      });
    });

    group('Inmutabilidad', () {
      test('debe ser const', () {
        const country = Country(
          id: '1',
          code: 'US',
          name: 'United States',
        );

        expect(country, isNotNull);
      });

      test('debe crear instancias diferentes con diferentes valores', () {
        const country1 = Country(id: '1', code: 'US', name: 'United States');
        const country2 = Country(id: '2', code: 'CA', name: 'Canada');

        expect(country1.id, isNot(equals(country2.id)));
        expect(country1.code, isNot(equals(country2.code)));
        expect(country1.name, isNot(equals(country2.name)));
      });
    });

    group('Casos edge', () {
      test('debe manejar id muy largo', () {
        const country = Country(
          id: 'very-long-uuid-string-123456789-abcdefghijklmnopqrstuvwxyz',
          code: 'US',
          name: 'United States',
        );

        expect(country.id.length, greaterThan(10));
      });

      test('debe manejar nombre muy largo', () {
        const country = Country(
          id: '1',
          code: 'UK',
          name: 'United Kingdom of Great Britain and Northern Ireland',
        );

        expect(country.name.length, greaterThan(20));
      });

      test('debe manejar código con números', () {
        const country = Country(
          id: '1',
          code: 'A1',
          name: 'Test Country',
        );

        expect(country.code, 'A1');
      });

      test('debe manejar nombres con emojis', () {
        const country = Country(
          id: '1',
          code: 'EM',
          name: 'Emoji Land 🌍',
        );

        expect(country.name, contains('🌍'));
      });

      test('debe manejar JSON con strings vacíos (caso inválido pero tolerado)', () {
        final json = {
          'id': '',
          'code': '',
          'name': '',
        };

        final country = Country.fromJson(json);

        expect(country.id, isEmpty);
        expect(country.code, isEmpty);
        expect(country.name, isEmpty);
      });
    });

    group('Uso en listas', () {
      test('debe poder crear lista de Countries', () {
        const countries = [
          Country(id: '1', code: 'US', name: 'United States'),
          Country(id: '2', code: 'CA', name: 'Canada'),
          Country(id: '3', code: 'MX', name: 'Mexico'),
        ];

        expect(countries.length, 3);
        expect(countries[0].code, 'US');
        expect(countries[1].code, 'CA');
        expect(countries[2].code, 'MX');
      });

      test('debe poder filtrar Countries por código', () {
        const countries = [
          Country(id: '1', code: 'US', name: 'United States'),
          Country(id: '2', code: 'CA', name: 'Canada'),
          Country(id: '3', code: 'MX', name: 'Mexico'),
        ];

        final usCountry = countries.where((c) => c.code == 'US').first;

        expect(usCountry.name, 'United States');
      });

      test('debe poder mapear lista de JSON a Countries', () {
        final jsonList = [
          {'id': '1', 'code': 'US', 'name': 'United States'},
          {'id': '2', 'code': 'CA', 'name': 'Canada'},
        ];

        final countries = jsonList.map((json) => Country.fromJson(json)).toList();

        expect(countries.length, 2);
        expect(countries[0], isA<Country>());
        expect(countries[1], isA<Country>());
      });
    });
  });
}
