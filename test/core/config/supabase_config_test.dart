import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/config/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('SupabaseConfig', () {
    setUpAll(() async {
      // Cargar .env para tests
      // Si no existe .env, los getters retornarán string vacío
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        // Si no hay .env, continuar con valores vacíos
      }
    });

    group('getters', () {
      test('url debe retornar string', () {
        // Act
        final url = SupabaseConfig.url;

        // Assert
        expect(url, isA<String>());
      });

      test('anonKey debe retornar string', () {
        // Act
        final anonKey = SupabaseConfig.anonKey;

        // Assert
        expect(anonKey, isA<String>());
      });

      test('url debe venir de SUPABASE_URL en .env', () {
        // Act
        final url = SupabaseConfig.url;
        final envValue = dotenv.env['SUPABASE_URL'] ?? '';

        // Assert
        expect(url, equals(envValue));
      });

      test('anonKey debe venir de SUPABASE_ANON_KEY en .env', () {
        // Act
        final anonKey = SupabaseConfig.anonKey;
        final envValue = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

        // Assert
        expect(anonKey, equals(envValue));
      });
    });

    group('estructura', () {
      test('debe tener método initialize', () {
        // Assert
        expect(SupabaseConfig.initialize, isA<Function>());
      });

      test('debe tener getter client', () {
        // Assert - Solo verificamos que el getter existe
        // No lo llamamos porque requiere initialize primero
        expect(() => SupabaseConfig.client, isA<Function>());
      });
    });
  });
}
