import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_environment.dart';

/// Configuración de Supabase
///
/// Las credenciales salen, en este orden:
/// 1. `--dart-define` / `--dart-define-from-file` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`):
///    obligatorio en staging y prod.
/// 2. `.env` (flutter_dotenv): solo como respaldo en dev.
///
/// Ver [AppEnvironment] para cómo compilar cada entorno.
class SupabaseConfig {
  static const String _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _definedAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => resolve(
        key: 'SUPABASE_URL',
        defined: _definedUrl,
        fromDotenv: dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null,
        environment: AppEnvironment.current,
      );

  static String get anonKey => resolve(
        key: 'SUPABASE_ANON_KEY',
        defined: _definedAnonKey,
        fromDotenv:
            dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null,
        environment: AppEnvironment.current,
      );

  /// Elige el valor de una credencial.
  ///
  /// - Si vino por `--dart-define`, se usa ese.
  /// - En dev, si no vino, se usa el de `.env` (o `''`).
  /// - En staging/prod, si no vino, lanza [StateError]: así un build de
  ///   producción nunca apunta por error al proyecto de desarrollo del `.env`.
  @visibleForTesting
  static String resolve({
    required String key,
    required String defined,
    required String? fromDotenv,
    required AppEnvironment environment,
  }) {
    if (defined.isNotEmpty) return defined;
    if (environment != AppEnvironment.dev) {
      throw StateError(
        '$key no está definido para ENV=${environment.name}. Compilar con '
        '--dart-define-from-file=config/${environment.name}.json',
      );
    }
    return fromDotenv ?? '';
  }

  /// Inicializa Supabase
  ///
  /// Debe llamarse en main() antes de runApp()
  ///
  /// **Debug mode:**
  /// - DEBUG: Logs verbose de Supabase
  /// - RELEASE: Sin logs (mejor performance)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      debug: kDebugMode, // ✅ FIX: Solo debug en modo DEBUG
    );
  }

  /// Cliente de Supabase global
  ///
  /// Uso:
  /// ```dart
  /// final response = await SupabaseConfig.client
  ///     .from('gossips')
  ///     .select();
  /// ```
  static SupabaseClient get client => Supabase.instance.client;
}
