import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración de Supabase
///
/// Inicializa el cliente de Supabase con credenciales desde .env
/// para mantener las keys seguras y fuera del código fuente.
class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

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
