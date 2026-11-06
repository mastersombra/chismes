@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import '../helpers/supabase_test_client.dart';

/// Tests de contrato para tablas de location
///
/// Verifican que el schema de location coincide con lo esperado
/// Robusto contra RLS - no fallan si políticas bloquean acceso
void main() {
  setUpAll(() async {
    await SupabaseTestClient.initialize();
  });

  tearDownAll(() {
    SupabaseTestClient.dispose();
  });

  group('Contrato Tabla countries', () {
    test('tabla countries existe y columnas son correctas', () async {
      final client = SupabaseTestClient.client;
      try {
        // LIMIT 0 verifica schema sin leer datos
        await client.from('countries').select('''
          id,
          name,
          created_at
        ''').limit(0);
        // Si no lanza excepción, tabla y columnas existen
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        // Si es RLS/permission, columnas existen pero RLS bloquea
        if (error.contains('permission') || error.contains('policy')) {
          fail(
            'RLS bloqueando countries (debería ser pública): $e\n'
            'Ejecutar: ./scripts/reset-database.sh',
          );
        }
        // Cualquier otro error = problema de schema
        fail('Error de schema en countries: $e');
      }
    });

    test('country_id usa formato correcto', () async {
      final client = SupabaseTestClient.client;
      try {
        // Filtrar por formato ISO válido (2 chars)
        await client
            .from('countries')
            .select('id')
            .eq('id', 'CO')
            .limit(0);
        // No error = columna acepta strings de 2 chars
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('permission') || error.contains('policy')) {
          fail(
            'RLS bloqueando countries: ejecutar ./scripts/reset-database.sh',
          );
        }
        fail('Error en formato de country_id: $e');
      }
    });

    test('Colombia (CO) existe si hay datos', () async {
      final client = SupabaseTestClient.client;
      try {
        final response = await client
            .from('countries')
            .select()
            .eq('id', 'CO')
            .maybeSingle();

        // Si hay response, verificar que es Colombia
        if (response != null) {
          expect(response['name'], 'Colombia');
        }
        // Si no hay response, seed no aplicado (no es error de schema)
      } on Exception catch (e) {
        fail('Error buscando Colombia: $e');
      }
    });
  });

  group('Contrato Tabla regions', () {
    test('tabla regions existe y columnas son correctas', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('regions').select('''
          id,
          name,
          country_id,
          created_at
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('permission') || error.contains('policy')) {
          fail(
            'RLS bloqueando regions: ejecutar ./scripts/reset-database.sh',
          );
        }
        fail('Error de schema en regions: $e');
      }
    });

    test('regions tienen relación con countries', () async {
      final client = SupabaseTestClient.client;
      try {
        // Verificar que se puede filtrar por country_id
        await client
            .from('regions')
            .select()
            .eq('country_id', 'CO')
            .limit(0);
      } on Exception catch (e) {
        fail('Error en relación region-country: $e');
      }
    });
  });

  group('Contrato Tabla cities', () {
    test('tabla cities existe y columnas son correctas', () async {
      final client = SupabaseTestClient.client;
      try {
        await client.from('cities').select('''
          id,
          name,
          region_id,
          latitude,
          longitude,
          population,
          created_at
        ''').limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('permission') || error.contains('policy')) {
          fail(
            'RLS bloqueando cities: ejecutar ./scripts/reset-database.sh',
          );
        }
        fail('Error de schema en cities: $e');
      }
    });

    test('latitude y longitude son numéricos', () async {
      final client = SupabaseTestClient.client;
      try {
        // Filtrar con operadores numéricos
        // Si lat/lng no son números, esto falla
        await client
            .from('cities')
            .select('id')
            .gte('latitude', -90.0)
            .lte('latitude', 90.0)
            .gte('longitude', -180.0)
            .lte('longitude', 180.0)
            .limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('operator') || error.contains('type')) {
          fail('latitude/longitude no son numéricos: $e');
        }
        fail('Error verificando tipos numéricos: $e');
      }
    });

    test('population es numérico', () async {
      final client = SupabaseTestClient.client;
      try {
        await client
            .from('cities')
            .select('id')
            .gte('population', 0)
            .limit(0);
      } on Exception catch (e) {
        final error = e.toString().toLowerCase();
        if (error.contains('operator') || error.contains('type')) {
          fail('population no es numérico: $e');
        }
        fail('Error verificando population: $e');
      }
    });

    test('cities tienen relaciones válidas', () async {
      final client = SupabaseTestClient.client;
      try {
        // Verificar que se puede filtrar por foreign keys
        await client
            .from('cities')
            .select()
            .eq('region_id', '25')
            .limit(0);
      } on Exception catch (e) {
        fail('Error en relaciones city-country-region: $e');
      }
    });
  });
}
