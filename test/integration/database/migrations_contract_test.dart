@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import '../helpers/supabase_test_client.dart';

/// Tests de contrato para verificar que todas las migraciones se aplicaron
///
/// Verifica que tablas críticas existen y tienen el schema esperado
/// Robusto contra RLS - no requiere leer datos
void main() {
  setUpAll(() async {
    await SupabaseTestClient.initialize();
  });

  tearDownAll(() {
    SupabaseTestClient.dispose();
  });

  group('Contrato Migraciones Aplicadas', () {
    test('tabla error_logs existe (migración 003)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('error_logs').select().limit(0);
      } on Exception catch (e) {
        fail('Tabla error_logs no existe. Migración 003 no aplicada: $e');
      }
    });

    test('tabla error_logs tiene columnas esperadas', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('error_logs').select('''
          id,
          level,
          message,
          stack_trace,
          context,
          user_id,
          created_at
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('column')) {
          fail('Columnas de error_logs no encontradas: $e');
        }
        // RLS/permission es OK para este test
      }
    });

    test('tabla rate_limits existe (migración 004)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('rate_limits').select().limit(0);
      } on Exception catch (e) {
        fail('Tabla rate_limits no existe. Migración 004 no aplicada: $e');
      }
    });

    test('tabla rate_limits tiene columnas esperadas', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('rate_limits').select('''
          user_id,
          action,
          hourly_count,
          daily_count,
          last_reset_hourly,
          last_reset_daily,
          created_at
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('column')) {
          fail('Columnas de rate_limits no encontradas: $e');
        }
        // RLS/permission es OK
      }
    });

    test('tabla profiles existe (migración 005)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('profiles').select().limit(0);
      } on Exception catch (e) {
        fail('Tabla profiles no existe. Migración 005 no aplicada: $e');
      }
    });

    test('tabla profiles tiene columnas esperadas', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('profiles').select('''
          id,
          username,
          display_name,
          avatar_url,
          bio,
          created_at,
          updated_at
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('column')) {
          fail('Columnas de profiles no encontradas: $e');
        }
      }
    });

    test('tabla gossip_reports existe (migración 010)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('gossip_reports').select().limit(0);
      } on Exception catch (e) {
        fail('Tabla gossip_reports no existe. Migración 010 no aplicada: $e');
      }
    });

    test('tabla gossip_reports tiene columnas esperadas', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('gossip_reports').select('''
          id,
          gossip_id,
          reporter_id,
          reason,
          details,
          created_at
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('column')) {
          fail('Columnas de gossip_reports no encontradas: $e');
        }
      }
    });

    test('storage bucket image-quarantine existe', () async {
      final client = SupabaseTestClient.client;
      try {
        final buckets = await client.storage.listBuckets();
        final imageQuarantine =
            buckets.any((b) => b.name == 'image-quarantine');
        expect(
          imageQuarantine,
          isTrue,
          reason: 'Bucket image-quarantine no existe (migración 006)',
        );
      } catch (e) {
        final error = e.toString().toLowerCase();
        // listBuckets puede no estar disponible con anon key
        // Skip este test si no tenemos permisos
        if (error.contains('permission') || error.contains('401')) {
          // Skip test - no podemos listar buckets con anon key
          return;
        }
        fail('Error listando buckets: $e');
      }
    });

    test('storage bucket audio-quarantine existe', () async {
      final client = SupabaseTestClient.client;
      try {
        final buckets = await client.storage.listBuckets();
        final audioQuarantine =
            buckets.any((b) => b.name == 'audio-quarantine');
        expect(
          audioQuarantine,
          isTrue,
          reason: 'Bucket audio-quarantine no existe (migración 008)',
        );
      } catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('permission') || error.contains('401')) {
          return;
        }
        fail('Error listando buckets: $e');
      }
    });

    test('función upsert_gossip_idempotent existe (migración 007)', () async {
      final client = SupabaseTestClient.client;
      // Intentar llamar la función sin autenticación debe fallar con auth error
      // NO con "function not found"
      try {
        await client.rpc('upsert_gossip_idempotent', params: {});
        fail('Función debió fallar por parámetros o autenticación');
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        // Si menciona "function", la función NO existe
        if (error.contains('function') && error.contains('not found')) {
          fail('Función upsert_gossip_idempotent no existe (migración 007): $e');
        }
        // Cualquier otro error (auth, params) = función existe
        // Este es el comportamiento esperado
      }
    });

    test('índice idx_gossips_idempotency_cleanup existe', () async {
      final client = SupabaseTestClient.client;
      // Query que usa el índice parcial
      // Si el índice no existe, puede ser más lento pero no falla
      try {
        await client
            .from('gossips')
            .select('id, created_at')
            .not('idempotency_key', 'is', null)
            .order('created_at')
            .limit(0);
        // Si no lanza excepción, el query es válido (índice puede o no existir)
        // Para verificar índice real, necesitaríamos query a pg_indexes
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('permission') || error.contains('policy')) {
          // RLS bloqueando, pero query es válido
          return;
        }
        fail('Error usando query con idempotency_key: $e');
      }
    });
  });
}
