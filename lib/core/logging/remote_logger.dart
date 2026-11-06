import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'log_entry.dart';

/// Interface para persistir logs remotamente
abstract class RemoteLogger {
  /// Persiste un log en el backend
  ///
  /// **Fire-and-forget:** No bloquea ni lanza excepciones
  /// Si falla, solo loguea en consola pero no propaga el error
  Future<void> log(LogEntry entry);
}

/// Implementación de RemoteLogger usando Edge Function
///
/// **Estrategia de seguridad:**
/// - ✅ Usa Edge Function autenticada (no insert directo)
/// - ✅ Sanitización de datos sensibles en servidor
/// - ✅ Rate limiting en servidor (50/hora, 200/día)
/// - ✅ Allowlist de campos permitidos en context
/// - ✅ Service role insert (bypasa RLS)
///
/// **Datos sensibles NUNCA enviados:**
/// - Texto de gossips, coordenadas GPS, tokens, URLs firmadas
///
/// **Fire-and-forget:**
/// - No bloquea la app
/// - Si falla, solo loguea en consola (no propaga error)
@Singleton(as: RemoteLogger)
class SupabaseRemoteLogger implements RemoteLogger {
  final SupabaseClient _client;

  SupabaseRemoteLogger(this._client);

  @override
  Future<void> log(LogEntry entry) async {
    // Fire-and-forget: no esperar ni propagar errores
    _logAsync(entry).ignore();
  }

  Future<void> _logAsync(LogEntry entry) async {
    try {
      // Solo persistir errores y fatales
      if (!entry.level.shouldPersist) {
        return;
      }

      // ✅ Skip si no hay sesión activa (evita 401)
      if (_client.auth.currentSession == null) {
        return;
      }

      // ✅ FIX: Usar Edge Function en vez de insert directo
      // La Edge Function:
      // - Sanitiza datos sensibles (allowlist de context)
      // - Valida rate limiting
      // - Inserta con service_role (bypasa RLS)
      final response = await _client.functions.invoke(
        'log-error',
        body: entry.toJson(),
      );

      if (response.status == 200) {
        debugPrint('📤 Log enviado a Edge Function: ${entry.level.value}');
      } else if (response.status == 429) {
        // Rate limit excedido, no es error crítico
        debugPrint('⚠️ Rate limit excedido para logging remoto');
      } else {
        debugPrint('⚠️ Edge Function retornó status ${response.status}');
      }
    } catch (error, stackTrace) {
      // Si falla el logging remoto, solo mostrar en consola
      // NO propagar el error (el logging no debe romper la app)
      debugPrint('⚠️ Error enviando log a Edge Function: $error');

      // En DEBUG: Mostrar stack trace para troubleshooting
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}

/// Mock de RemoteLogger que no hace nada (para tests)
///
/// **Uso en tests:**
/// ```dart
/// final mockLogger = MockRemoteLogger();
/// // Usar directamente, no necesita registro en DI
/// ```
class MockRemoteLogger implements RemoteLogger {
  final List<LogEntry> logs = [];

  @override
  Future<void> log(LogEntry entry) async {
    logs.add(entry);
  }

  void clear() => logs.clear();
}
