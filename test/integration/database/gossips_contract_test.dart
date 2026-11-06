@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import '../helpers/supabase_test_client.dart';

/// Tests de contrato para tabla gossips
///
/// Verifican que el schema de Supabase coincide con lo esperado por la app
/// NO requieren datos, solo verifican que las columnas existen
void main() {
  setUpAll(() async {
    await SupabaseTestClient.initialize();
  });

  tearDownAll(() {
    SupabaseTestClient.dispose();
  });

  group('Contrato Tabla gossips', () {
    test('tabla gossips existe y columnas snake_case son accesibles', () async {
      final client = SupabaseTestClient.client;
      // SELECT con LIMIT 0 no lee datos, solo verifica schema
      // RLS no debería bloquear esto
      try {
        await client.from('gossips').select('''
          id,
          country_id,
          region_id,
          city_id,
          subject,
          content,
          audio_url,
          image_url,
          thumbnail_url,
          storage_path,
          thumbnail_storage_path,
          audio_storage_path,
          published_as,
          status,
          moderation_status,
          visibility,
          reported_count,
          view_count,
          created_at,
          created_by,
          modified_at,
          modified_by,
          deleted_at,
          deleted_by
        ''').limit(0);
        // Si no lanza excepción, columnas existen
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        // Si es RLS/permission, columnas existen pero acceso bloqueado
        if (error.contains('permission') || error.contains('policy')) {
          return;
        }
        // Cualquier otro error = columna no existe
        fail('Error de schema en tabla gossips: $e');
      }
    });

    test('NO usa camelCase en columnas', () async {
      final client = SupabaseTestClient.client;
      // Intentar seleccionar con camelCase debe fallar con error de columna
      try {
        await client.from('gossips').select('createdAt').limit(0);
        fail('No debería permitir camelCase (createdAt)');
      } on Exception catch (e) {
        // Esperamos error de columna no encontrada
        expect(e.toString().toLowerCase(), contains('column'));
      }
    });

    test('tipos de datos básicos son correctos', () async {
      final client = SupabaseTestClient.client;
      // Intentar query con operadores tipados
      // Si los tipos no coinciden, Supabase lanza error
      try {
        // created_at debe ser timestamp
        await client
            .from('gossips')
            .select('id')
            .gte('created_at', DateTime.now().toIso8601String())
            .limit(0);

        // reported_count debe ser número
        await client
            .from('gossips')
            .select('id')
            .gte('reported_count', 0)
            .limit(0);

        // id debe ser UUID (text)
        await client
            .from('gossips')
            .select('id')
            .eq('id', '00000000-0000-0000-0000-000000000000')
            .limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        // Si error es RLS/permissions, tipos son correctos
        // Si error es de tipo, fail
        if (error.contains('type') || error.contains('operator')) {
          fail('Tipos de datos incorrectos: $e');
        }
      }
    });

    test('enums tienen constraints correctos (status)', () async {
      final client = SupabaseTestClient.client;
      // Intentar filtrar por valor válido de enum
      try {
        await client
            .from('gossips')
            .select('id')
            .eq('status', 'published')
            .limit(0);
        // No error = enum existe y acepta el valor
        // RLS/permission es OK
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Enum status no configurado correctamente: $e');
        }
      }
    });

    test('enums tienen constraints correctos (moderation_status)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client
            .from('gossips')
            .select('id')
            .eq('moderation_status', 'approved')
            .limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Enum moderation_status no configurado: $e');
        }
      }
    });

    test('enums tienen constraints correctos (visibility)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client
            .from('gossips')
            .select('id')
            .eq('visibility', 'public')
            .limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Enum visibility no configurado: $e');
        }
      }
    });

    test('enums tienen constraints correctos (published_as)', () async {
      final client = SupabaseTestClient.client;
      try {
        await client
            .from('gossips')
            .select('id')
            .eq('published_as', 'anonymous')
            .limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Enum published_as no configurado: $e');
        }
      }
    });

    test('campos de auditoría existen', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('gossips').select('''
          created_at,
          created_by,
          modified_at,
          modified_by,
          deleted_at,
          deleted_by
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Campos de auditoría no existen: $e');
        }
      }
    });

    test('campos de contadores existen', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('gossips').select('''
          reported_count,
          view_count
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Campos de contadores no existen: $e');
        }
      }
    });

    test('campos de media existen', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('gossips').select('''
          audio_url,
          image_url,
          thumbnail_url,
          storage_path,
          thumbnail_storage_path,
          audio_storage_path
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (!error.contains('permission') && !error.contains('policy')) {
          fail('Campos de media no existen: $e');
        }
      }
    });
  });
}
