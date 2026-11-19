import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/config/app_environment.dart';
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

    group('resolve (precedencia --dart-define / .env)', () {
      test('usa el valor de --dart-define cuando existe, en cualquier entorno', () {
        for (final env in AppEnvironment.values) {
          expect(
            SupabaseConfig.resolve(
              key: 'SUPABASE_URL',
              defined: 'https://prod.supabase.co',
              fromDotenv: 'https://dev.supabase.co',
              environment: env,
            ),
            'https://prod.supabase.co',
            reason: env.name,
          );
        }
      });

      test('en dev cae al valor de .env si no hay define', () {
        expect(
          SupabaseConfig.resolve(
            key: 'SUPABASE_URL',
            defined: '',
            fromDotenv: 'https://dev.supabase.co',
            environment: AppEnvironment.dev,
          ),
          'https://dev.supabase.co',
        );
      });

      test('en dev sin define ni .env retorna vacío', () {
        expect(
          SupabaseConfig.resolve(
            key: 'SUPABASE_URL',
            defined: '',
            fromDotenv: null,
            environment: AppEnvironment.dev,
          ),
          '',
        );
      });

      test('en staging y prod sin define lanza StateError (nunca usa .env)', () {
        for (final env in [AppEnvironment.staging, AppEnvironment.prod]) {
          expect(
            () => SupabaseConfig.resolve(
              key: 'SUPABASE_ANON_KEY',
              defined: '',
              fromDotenv: 'dev-key',
              environment: env,
            ),
            throwsA(isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(contains('SUPABASE_ANON_KEY'),
                  contains('config/${env.name}.json')),
            )),
            reason: env.name,
          );
        }
      });
    });
  });
}
