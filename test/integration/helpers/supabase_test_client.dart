import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cliente Supabase para tests de integración
///
/// Usa las credenciales de .env para conectarse al proyecto real
/// sin depender de plugins de Flutter
class SupabaseTestClient {
  static SupabaseClient? _instance;

  /// Inicializa Supabase con credenciales de .env
  static Future<void> initialize() async {
    if (_instance != null) return;

    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception(
        'SUPABASE_URL y SUPABASE_ANON_KEY deben estar en .env',
      );
    }

    // Crear cliente directamente sin plugins
    _instance = SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Retorna el cliente Supabase
  static SupabaseClient get client {
    if (_instance == null) {
      throw Exception(
        'SupabaseTestClient no inicializado. Llamar initialize() primero.',
      );
    }
    return _instance!;
  }

  /// Cierra la conexión
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
