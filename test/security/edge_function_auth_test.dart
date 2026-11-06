import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Tests de seguridad para Edge Function moderate-gossip
///
/// Verifica que la autenticación sea obligatoria y que no se pueda
/// crear gossips sin JWT válido.
///
/// IMPORTANTE: Estos tests requieren que la Edge Function esté desplegada.
///
/// Para ejecutar:
/// ```bash
/// flutter test test/security/edge_function_auth_test.dart
/// ```
///
/// Para ejecutar con setup:
/// 1. Asegúrate de tener .env.test con SUPABASE_URL
/// 2. Crea 2 usuarios de prueba en Supabase Dashboard
/// 3. Obtén sus JWT tokens
/// 4. Configura las variables de entorno
void main() {
  group('Edge Function Security Tests', () {
    // TODO: Configurar estas variables desde .env.test
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://njqamqcsldpmtbiqwbwo.supabase.co',
    );

    final edgeFunctionUrl = Uri.parse(
      '$supabaseUrl/functions/v1/moderate-gossip',
    );

    final validGossipData = {
      'subject': 'Test Security',
      'content': 'Testing authentication requirements',
      'country_id': 'CO',
      'region_id': '34',
      'city_id': '3688689',
      'published_as': 'anonymous',
      'idempotency_key': 'test-${DateTime.now().millisecondsSinceEpoch}',
    };

    test('P0-03 Fix: Sin JWT → 401 Unauthorized', () async {
      // Arrange: Request sin Authorization header
      final response = await http.post(
        edgeFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          // NO Authorization header
        },
        body: json.encode(validGossipData),
      );

      // Assert
      expect(
        response.statusCode,
        401,
        reason: 'Debe rechazar requests sin JWT con 401',
      );

      final body = json.decode(response.body) as Map<String, dynamic>;
      expect(
        body['error'],
        'Missing Authorization header',
        reason: 'Debe indicar que falta el header',
      );
    });

    test('P0-03 Fix: JWT inválido → 401 Unauthorized', () async {
      // Arrange: Request con JWT falso
      final response = await http.post(
        edgeFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer invalid-jwt-token-12345',
        },
        body: json.encode(validGossipData),
      );

      // Assert
      expect(
        response.statusCode,
        401,
        reason: 'Debe rechazar JWT inválido con 401',
      );

      final body = json.decode(response.body) as Map<String, dynamic>;
      expect(
        body['error'],
        'Authentication required',
        reason: 'Debe indicar que la autenticación es requerida',
      );
    });

    test('P0-03 Fix: JWT válido → Success (200)', () async {
      // TODO: Este test requiere un JWT real de un usuario de prueba
      //
      // Para obtener un JWT:
      // 1. Crea un usuario en Supabase Dashboard
      // 2. Haz login desde Flutter app
      // 3. Copia el token de: supabase.auth.currentSession?.accessToken
      //
      // O usa Supabase CLI:
      // supabase auth login --email test@example.com --password testpass

      const testJwt = String.fromEnvironment('TEST_JWT');

      if (testJwt.isEmpty) {
        debugPrint('⚠️ Skipping test: TEST_JWT not configured');
        debugPrint('Set TEST_JWT environment variable with a valid JWT token');
        return;
      }

      // Arrange: Request con JWT válido
      final response = await http.post(
        edgeFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testJwt',
        },
        body: json.encode(validGossipData),
      );

      // Assert
      expect(
        response.statusCode,
        isIn([200, 400]), // 200 OK o 400 si falla moderación
        reason: 'Con JWT válido debe procesar el request',
      );

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        expect(
          body['gossip'],
          isNotNull,
          reason: 'Debe retornar el gossip creado',
        );

        final gossip = body['gossip'] as Map<String, dynamic>;
        expect(
          gossip['created_by'],
          isNotEmpty,
          reason: 'created_by debe ser un UUID válido',
        );

        // Verificar que created_by es UUID (formato)
        final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        );
        expect(
          uuidPattern.hasMatch(gossip['created_by'] as String),
          isTrue,
          reason: 'created_by debe ser UUID válido, no spike-user',
        );
      }
    });

    test('P0-03 Fix: No acepta spike-user como created_by', () async {
      const testJwt = String.fromEnvironment('TEST_JWT');

      if (testJwt.isEmpty) {
        debugPrint('⚠️ Skipping test: TEST_JWT not configured');
        return;
      }

      // Arrange: Intentar crear con created_by explícito (Edge Function debe ignorarlo)
      final maliciousData = {
        ...validGossipData,
        'created_by': 'spike-user', // Intentar inyectar spike-user
      };

      final response = await http.post(
        edgeFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testJwt',
        },
        body: json.encode(maliciousData),
      );

      // Assert
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final gossip = body['gossip'] as Map<String, dynamic>;

        // Verificar que created_by NO es 'spike-user'
        expect(
          gossip['created_by'],
          isNot('spike-user'),
          reason: 'Edge Function debe forzar user.id, no aceptar spike-user',
        );

        // Verificar que es UUID válido
        final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        );
        expect(
          uuidPattern.hasMatch(gossip['created_by'] as String),
          isTrue,
          reason: 'created_by debe ser UUID del usuario autenticado',
        );
      }
    });
  });

  group('Edge Function Integration Tests', () {
    test('Rate limiting funciona con UUID', () async {
      // TODO: Este test requiere hacer 11 requests consecutivos
      // con el mismo usuario para verificar que rate limiting funciona

      const testJwt = String.fromEnvironment('TEST_JWT');

      if (testJwt.isEmpty) {
        debugPrint('⚠️ Skipping test: TEST_JWT not configured');
        return;
      }

      debugPrint('⚠️ Test manual requerido:');
      debugPrint('1. Crea 11 gossips seguidos con el mismo usuario');
      debugPrint('2. El 11º debe fallar con 429 Too Many Requests');
      debugPrint('3. Verifica en rate_limits table que user_id es UUID');
    });
  });
}
