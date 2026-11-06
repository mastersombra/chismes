# Testing Roadmap - Plan de Implementación

**Fecha de creación:** 2026-10-22  
**Estado:** 📋 PLANIFICADO  
**Objetivo:** Alcanzar cobertura completa para producción

---

## 🎯 Objetivo: Production-Ready Testing

### Criterios de Éxito

| Métrica | Actual | Objetivo | Gap |
|---------|--------|----------|-----|
| Tests pasando | 93.4% | >95% | 1.6% |
| Cobertura líneas | 78.9% | >80% | 1.1% |
| Tests E2E | 0 | ≥5 | 5 |
| Tests seguridad | 2 | ≥10 | 8 |
| Tests RLS | 0 | ≥5 | 5 |
| Controller tests | 13/61 OK | 61/61 OK | 48 |

---

## 📂 ESTRUCTURA DE CARPETAS A CREAR

```
test/
├── integration/                          # 🆕 CREAR
│   ├── edge_functions/                   # 🆕 Tests de Edge Functions
│   │   ├── moderate_gossip_auth_test.dart
│   │   ├── moderate_gossip_validation_test.dart
│   │   ├── moderate_gossip_moderation_test.dart
│   │   ├── moderate_gossip_limits_test.dart
│   │   └── log_error_security_test.dart
│   │
│   ├── database/                         # 🆕 Tests de DB/RLS
│   │   ├── rls_gossips_test.dart
│   │   ├── rls_storage_test.dart
│   │   ├── state_transitions_test.dart
│   │   ├── idempotency_test.dart
│   │   └── rate_limit_test.dart
│   │
│   ├── storage/                          # 🆕 Tests de Storage/Media
│   │   ├── upload_validation_test.dart
│   │   ├── mime_detection_test.dart
│   │   ├── quarantine_flow_test.dart
│   │   ├── rls_buckets_test.dart
│   │   └── cleanup_test.dart
│   │
│   └── helpers/                          # 🆕 Helpers compartidos
│       ├── test_users.dart               # Usuarios de prueba
│       ├── test_data.dart                # Datos de prueba
│       └── supabase_test_client.dart     # Cliente configurado
│
├── features/gossip/presentation/
│   └── controllers/
│       └── add_gossip_controller_test.dart  # 🔧 ARREGLAR (48 tests rotos)
│
└── security/
    └── edge_function_auth_test.dart      # ✅ Existe, mejorar

integration_test/                         # 🆕 CREAR CARPETA COMPLETA
├── create_gossip_flow_test.dart          # Golden path sin media
├── create_gossip_with_image_test.dart    # Golden path con imagen
├── moderation_flow_test.dart             # Pending → Approved/Rejected
├── retry_idempotency_test.dart           # Mismo idempotency_key
├── offline_flow_test.dart                # Red intermitente
├── location_flow_test.dart               # GPS denegado
└── app_test.dart                         # Smoke test general
```

---

## 🚨 FASE 0: PRE-REQUISITOS (1 día)

### Setup de Infraestructura de Testing

**Objetivo:** Preparar entorno para tests de integración

#### Tareas:

- [ ] **Crear archivo de configuración de test**
```bash
# .env.test
SUPABASE_URL=https://njqamqcsldpmtbiqwbwo.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...  # Solo para tests
TEST_USER_A_EMAIL=test_a@chismes.test
TEST_USER_A_PASSWORD=TestPassword123!
TEST_USER_A_JWT=eyJxxx...
TEST_USER_B_EMAIL=test_b@chismes.test
TEST_USER_B_PASSWORD=TestPassword123!
TEST_USER_B_JWT=eyJxxx...
```

- [ ] **Crear usuarios de prueba en Supabase**
  - Usuario A: `test_a@chismes.test`
  - Usuario B: `test_b@chismes.test`
  - Obtener JWTs válidos de cada uno

- [ ] **Agregar dependencias de testing**
```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  http: ^1.1.0  # Ya existe
```

- [ ] **Crear helpers compartidos**

**Archivo:** `test/integration/helpers/test_users.dart`
```dart
class TestUsers {
  static const userA = TestUser(
    id: 'test-user-a-uuid',
    email: 'test_a@chismes.test',
    jwt: String.fromEnvironment('TEST_USER_A_JWT'),
  );

  static const userB = TestUser(
    id: 'test-user-b-uuid',
    email: 'test_b@chismes.test',
    jwt: String.fromEnvironment('TEST_USER_B_JWT'),
  );
}

class TestUser {
  final String id;
  final String email;
  final String jwt;

  const TestUser({
    required this.id,
    required this.email,
    required this.jwt,
  });
}
```

**Archivo:** `test/integration/helpers/supabase_test_client.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTestClient {
  static SupabaseClient createClient({String? jwt}) {
    final url = const String.fromEnvironment('SUPABASE_URL');
    final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    final headers = <String, String>{};
    if (jwt != null) {
      headers['Authorization'] = 'Bearer $jwt';
    }

    return SupabaseClient(url, anonKey, headers: headers);
  }

  static SupabaseClient createServiceRoleClient() {
    final url = const String.fromEnvironment('SUPABASE_URL');
    final serviceKey = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

    return SupabaseClient(url, serviceKey);
  }
}
```

**Estimación:** 1 día

---

## 🔴 FASE 1: BLOQUEADORES (P0) - 10 días

### SEMANA 1: Tests de Seguridad (5 días)

#### DÍA 1: Edge Functions - Autenticación (Alta Prioridad)

**Archivo:** `test/integration/edge_functions/moderate_gossip_auth_test.dart`

**Casos a implementar:**

- [ ] **AUTH-01:** Sin JWT → 401 Unauthorized
- [ ] **AUTH-02:** JWT inválido (formato incorrecto) → 401
- [ ] **AUTH-03:** JWT expirado → 401
- [ ] **AUTH-04:** JWT de otro proyecto Supabase → 401
- [ ] **AUTH-05:** JWT válido → 200 OK

**Template:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/test_users.dart';

void main() {
  group('Moderate Gossip - Autenticación', () {
    final edgeFunctionUrl = Uri.parse(
      '${const String.fromEnvironment('SUPABASE_URL')}/functions/v1/moderate-gossip',
    );

    final validPayload = {
      'subject': 'Test',
      'content': 'Test content',
      'country_id': 'CO',
      'region_id': '34',
      'city_id': '3688689',
      'published_as': 'anonymous',
      'idempotency_key': 'test-${DateTime.now().millisecondsSinceEpoch}',
    };

    test('AUTH-01: Sin JWT → 401', () async {
      final response = await http.post(
        edgeFunctionUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(validPayload),
      );

      expect(response.statusCode, 401);
      expect(json.decode(response.body)['error'], contains('Authorization'));
    });

    test('AUTH-03: JWT expirado → 401', () async {
      const expiredJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZXhwIjoxNTE2MjM5MDIyfQ.abc';
      
      final response = await http.post(
        edgeFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $expiredJwt',
        },
        body: json.encode(validPayload),
      );

      expect(response.statusCode, 401);
    });

    test('AUTH-05: JWT válido → 200', () async {
      final response = await http.post(
        edgeFunctionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${TestUsers.userA.jwt}',
        },
        body: json.encode(validPayload),
      );

      expect(response.statusCode, anyOf([200, 201]));
    });
  });
}
```

**Estimación:** 1 día (8 horas)

---

#### DÍA 2: Edge Functions - Validación de Schema (Alta Prioridad)

**Archivo:** `test/integration/edge_functions/moderate_gossip_validation_test.dart`

**Casos a implementar:**

- [ ] **VAL-01:** Campo `subject` faltante → 400
- [ ] **VAL-02:** Campo `content` faltante → 400
- [ ] **VAL-03:** Campo `country_id` inválido (no existe) → 400
- [ ] **VAL-04:** Campo `city_id` inválido (no existe en región) → 400
- [ ] **VAL-05:** `subject` demasiado largo (>200 chars) → 400
- [ ] **VAL-06:** `content` demasiado largo (>1000 chars) → 400
- [ ] **VAL-07:** `published_as` inválido (no 'anonymous' ni 'profile') → 400
- [ ] **VAL-08:** Payload completo válido → 200

**Template:**
```dart
test('VAL-01: subject faltante → 400', () async {
  final payload = {...validPayload};
  payload.remove('subject');

  final response = await http.post(
    edgeFunctionUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TestUsers.userA.jwt}',
    },
    body: json.encode(payload),
  );

  expect(response.statusCode, 400);
  final body = json.decode(response.body);
  expect(body['error'], contains('subject'));
});

test('VAL-03: country_id inválido → 400', () async {
  final payload = {...validPayload, 'country_id': 'XX'};

  final response = await http.post(
    edgeFunctionUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TestUsers.userA.jwt}',
    },
    body: json.encode(payload),
  );

  expect(response.statusCode, 400);
  expect(json.decode(response.body)['error'], contains('country'));
});
```

**Estimación:** 1 día (8 horas)

---

#### DÍA 3: RLS - Row Level Security Gossips (Crítico)

**Archivo:** `test/integration/database/rls_gossips_test.dart`

**Casos a implementar:**

- [ ] **RLS-01:** Usuario A puede leer sus propios drafts
- [ ] **RLS-02:** Usuario B NO puede leer drafts de Usuario A
- [ ] **RLS-03:** Usuario B puede leer gossips published de Usuario A
- [ ] **RLS-04:** Usuario B NO puede UPDATE gossips de Usuario A
- [ ] **RLS-05:** Usuario B NO puede DELETE gossips de Usuario A
- [ ] **RLS-06:** Anónimo puede leer gossips published
- [ ] **RLS-07:** Anónimo NO puede leer gossips draft
- [ ] **RLS-08:** Anónimo NO puede INSERT gossips (sin JWT)

**Template:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/test_users.dart';
import '../helpers/supabase_test_client.dart';

void main() {
  group('RLS - Gossips Table', () {
    late SupabaseClient clientA;
    late SupabaseClient clientB;
    late SupabaseClient clientAnon;

    setUpAll(() {
      clientA = SupabaseTestClient.createClient(jwt: TestUsers.userA.jwt);
      clientB = SupabaseTestClient.createClient(jwt: TestUsers.userB.jwt);
      clientAnon = SupabaseTestClient.createClient(); // Sin JWT
    });

    test('RLS-02: Usuario B NO puede leer drafts de Usuario A', () async {
      // Arrange: Usuario A crea draft (usando Edge Function o service_role)
      final serviceClient = SupabaseTestClient.createServiceRoleClient();
      final draft = await serviceClient.from('gossips').insert({
        'subject': 'Draft de A',
        'content': 'Contenido privado',
        'status': 'draft',
        'author_id': TestUsers.userA.id,
        'country_id': 'CO',
        'region_id': '34',
        'city_id': '3688689',
      }).select().single();

      // Act: Usuario B intenta leer draft de A
      final result = await clientB
          .from('gossips')
          .select()
          .eq('id', draft['id'])
          .maybeSingle();

      // Assert: RLS debe bloquear
      expect(result, isNull, reason: 'RLS debe impedir leer draft ajeno');

      // Cleanup
      await serviceClient.from('gossips').delete().eq('id', draft['id']);
    });

    test('RLS-03: Usuario B puede leer published de Usuario A', () async {
      // Arrange: Usuario A crea published
      final serviceClient = SupabaseTestClient.createServiceRoleClient();
      final published = await serviceClient.from('gossips').insert({
        'subject': 'Published de A',
        'content': 'Contenido público',
        'status': 'published',
        'author_id': TestUsers.userA.id,
        'country_id': 'CO',
        'region_id': '34',
        'city_id': '3688689',
      }).select().single();

      // Act: Usuario B intenta leer published de A
      final result = await clientB
          .from('gossips')
          .select()
          .eq('id', published['id'])
          .single();

      // Assert: RLS debe permitir
      expect(result['id'], published['id']);
      expect(result['subject'], 'Published de A');

      // Cleanup
      await serviceClient.from('gossips').delete().eq('id', published['id']);
    });
  });
}
```

**Estimación:** 1 día (8 horas)

---

#### DÍA 4: RLS - Storage Buckets (Crítico)

**Archivo:** `test/integration/storage/rls_buckets_test.dart`

**Casos a implementar:**

- [ ] **STOR-01:** Usuario A puede upload a `image-quarantine/{user_id}/`
- [ ] **STOR-02:** Usuario A NO puede upload a `image-quarantine/{otro_user_id}/`
- [ ] **STOR-03:** Usuario A NO puede leer archivos en quarantine de otro usuario
- [ ] **STOR-04:** Usuario A NO puede leer archivos en bucket público de otro usuario
- [ ] **STOR-05:** Archivos en quarantine NO son públicos (sin signed URL)
- [ ] **STOR-06:** Solo Edge Functions pueden mover de quarantine → public

**Template:**
```dart
test('STOR-02: Usuario A NO puede upload a carpeta de B', () async {
  final clientA = SupabaseTestClient.createClient(jwt: TestUsers.userA.jwt);

  // Act: Usuario A intenta subir a carpeta de B
  try {
    await clientA.storage
        .from('image-quarantine')
        .uploadBinary(
          '${TestUsers.userB.id}/hack.jpg',
          Uint8List.fromList([0xFF, 0xD8, 0xFF]), // JPEG header
        );
    
    fail('RLS debió bloquear el upload');
  } catch (e) {
    // Assert: RLS debe bloquear
    expect(e, isA<StorageException>());
    expect(e.toString(), contains('denied'));
  }
});

test('STOR-05: Archivos en quarantine NO son públicos', () async {
  // Arrange: Subir archivo a quarantine
  final serviceClient = SupabaseTestClient.createServiceRoleClient();
  await serviceClient.storage
      .from('image-quarantine')
      .uploadBinary(
        '${TestUsers.userA.id}/test.jpg',
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
      );

  // Act: Intentar acceder sin signed URL
  final publicUrl = serviceClient.storage
      .from('image-quarantine')
      .getPublicUrl('${TestUsers.userA.id}/test.jpg');

  final response = await http.get(Uri.parse(publicUrl));

  // Assert: Debe ser 400/403 (bucket privado)
  expect(response.statusCode, isNot(200));

  // Cleanup
  await serviceClient.storage
      .from('image-quarantine')
      .remove(['${TestUsers.userA.id}/test.jpg']);
});
```

**Estimación:** 1 día (8 horas)

---

#### DÍA 5: Media Validation (Crítico)

**Archivo:** `test/integration/storage/upload_validation_test.dart`

**Casos a implementar:**

- [ ] **MEDIA-01:** MIME type por magic bytes (no extensión)
- [ ] **MEDIA-02:** Imagen con extensión `.jpg` pero contenido PNG → rechazar
- [ ] **MEDIA-03:** Archivo >10MB → rechazar
- [ ] **MEDIA-04:** Pixel bomb (1px x 999999999px) → rechazar
- [ ] **MEDIA-05:** Archivo sin extensión reconocida → rechazar
- [ ] **MEDIA-06:** Imagen válida JPEG → aceptar
- [ ] **MEDIA-07:** Imagen válida PNG → aceptar

**Template:**
```dart
test('MEDIA-02: Extensión .jpg pero contenido PNG → rechazar', () async {
  // PNG magic bytes: 89 50 4E 47
  final fakePng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);

  final response = await http.post(
    edgeFunctionUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TestUsers.userA.jwt}',
    },
    body: json.encode({
      ...validPayload,
      'image_base64': base64Encode(fakePng),
      'image_filename': 'fake.jpg', // ❌ Extensión incorrecta
    }),
  );

  expect(response.statusCode, 400);
  expect(json.decode(response.body)['error'], contains('MIME'));
});

test('MEDIA-04: Pixel bomb → rechazar', () async {
  // Crear imagen JPEG con dimensiones absurdas
  // (Simulación, en real sería archivo generado)
  final pixelBomb = _createPixelBombJpeg(width: 1, height: 999999999);

  final response = await http.post(
    edgeFunctionUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TestUsers.userA.jwt}',
    },
    body: json.encode({
      ...validPayload,
      'image_base64': base64Encode(pixelBomb),
    }),
  );

  expect(response.statusCode, 400);
  expect(json.decode(response.body)['error'], contains('size'));
});
```

**Estimación:** 1 día (8 horas)

---

### SEMANA 2: Tests E2E y Arreglos (5 días)

#### DÍA 6-7: Tests E2E - Golden Paths (Alta Prioridad)

**Archivo 1:** `integration_test/create_gossip_flow_test.dart`

**Casos a implementar:**

- [ ] **E2E-01:** Crear gossip sin media (solo texto)
- [ ] **E2E-02:** Verificar que aparece "Pendiente de moderación"
- [ ] **E2E-03:** Verificar que no aparece en feed público hasta aprobación

**Archivo 2:** `integration_test/create_gossip_with_image_test.dart`

**Casos a implementar:**

- [ ] **E2E-04:** Crear gossip con imagen
- [ ] **E2E-05:** Verificar preview de imagen antes de submit
- [ ] **E2E-06:** Verificar imagen en quarantine después de submit
- [ ] **E2E-07:** Verificar imagen movida a público después de aprobación

**Template:**
```dart
// integration_test/create_gossip_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chismes/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Crear Gossip', () {
    testWidgets('E2E-01: Crear gossip sin media', (tester) async {
      // Arrange: Lanzar app y login
      app.main();
      await tester.pumpAndSettle();

      // TODO: Implementar login automático para E2E
      // await _loginAsTestUser(tester, TestUsers.userA);

      // Act: Navegar a crear gossip
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Llenar formulario
      await tester.enterText(
        find.byKey(const Key('subject_field')),
        'Test E2E Automated',
      );
      await tester.enterText(
        find.byKey(const Key('content_field')),
        'Este es un test E2E automatizado. Se puede eliminar.',
      );

      // Seleccionar ubicación (mock GPS o manual)
      await tester.tap(find.text('Usar mi ubicación actual'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Submit
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert: Verificar éxito
      expect(find.text('✅ Chisme creado'), findsOneWidget);
      expect(find.text('Pendiente de moderación'), findsOneWidget);
    });
  });
}
```

**Estimación:** 2 días (16 horas)

---

#### DÍA 8: Idempotencia (Alta Prioridad)

**Archivo:** `integration_test/retry_idempotency_test.dart`

**Casos a implementar:**

- [ ] **IDEMP-01:** Mismo idempotency_key → retorna mismo gossip (no duplica)
- [ ] **IDEMP-02:** Mismo key en <5 min → retorna mismo resultado
- [ ] **IDEMP-03:** Mismo key en >60 min → permite crear nuevo
- [ ] **IDEMP-04:** Keys diferentes → crea gossips diferentes

**Template:**
```dart
test('IDEMP-01: Mismo idempotency_key → no duplica', () async {
  final idempotencyKey = 'test-idemp-${DateTime.now().millisecondsSinceEpoch}';

  // Primera llamada
  final response1 = await http.post(
    edgeFunctionUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TestUsers.userA.jwt}',
    },
    body: json.encode({
      ...validPayload,
      'idempotency_key': idempotencyKey,
    }),
  );

  expect(response1.statusCode, anyOf([200, 201]));
  final body1 = json.decode(response1.body);
  final gossipId1 = body1['gossip_id'];

  // Segunda llamada CON MISMO KEY
  final response2 = await http.post(
    edgeFunctionUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TestUsers.userA.jwt}',
    },
    body: json.encode({
      ...validPayload,
      'idempotency_key': idempotencyKey, // MISMO KEY
    }),
  );

  expect(response2.statusCode, 200);
  final body2 = json.decode(response2.body);
  final gossipId2 = body2['gossip_id'];

  // Assert: Mismo gossip retornado
  expect(gossipId1, gossipId2, reason: 'Debe retornar el mismo gossip');

  // Verificar que no hay duplicados en DB
  final serviceClient = SupabaseTestClient.createServiceRoleClient();
  final duplicates = await serviceClient
      .from('gossips')
      .select()
      .eq('idempotency_key', idempotencyKey);

  expect(duplicates.length, 1, reason: 'No debe haber duplicados');
});
```

**Estimación:** 1 día (8 horas)

---

#### DÍA 9-10: Arreglar Controller Tests (Crítico)

**Archivo:** `test/features/gossip/presentation/controllers/add_gossip_controller_test.dart`

**Problema:** 48 tests fallando porque mocks no tienen los nuevos notifiers.

**Tarea:** Actualizar mocks con:
- `failureNotifier`
- `imageNotifier`
- `isUploadingImageNotifier`
- `isSubmittingNotifier`

**Template de fix:**
```dart
// Mock del controller
class MockAddGossipController extends Mock implements AddGossipController {
  @override
  ValueNotifier<Failure?> get failureNotifier => ValueNotifier(null);

  @override
  ValueNotifier<String?> get imageNotifier => ValueNotifier(null);

  @override
  ValueNotifier<bool> get isUploadingImageNotifier => ValueNotifier(false);

  @override
  ValueNotifier<bool> get isSubmittingNotifier => ValueNotifier(false);

  @override
  AddGossipState get state => AddGossipState.initial();

  @override
  Stream<AddGossipState> get stream => Stream.value(AddGossipState.initial());
}
```

**Estimación:** 2 días (16 horas)

---

## 🟡 FASE 2: POST-LANZAMIENTO (P1) - 8 días

### DÍA 11-12: Tests de Moderación

**Archivo:** `test/integration/edge_functions/moderate_gossip_moderation_test.dart`

**Casos a implementar:**

- [ ] **MOD-01:** OpenAI timeout → fallback a "pending"
- [ ] **MOD-02:** OpenAI down → retry 3 veces
- [ ] **MOD-03:** Texto con contenido flagged → "rejected"
- [ ] **MOD-04:** Texto safe → "approved"
- [ ] **MOD-05:** Rate limit OpenAI → queue/retry

**Estimación:** 2 días

---

### DÍA 13-14: Tests de Rate Limiting

**Archivo:** `test/integration/edge_functions/moderate_gossip_limits_test.dart`

**Casos a implementar:**

- [ ] **LIMIT-01:** >10 gossips/hora → 429
- [ ] **LIMIT-02:** Payload >1MB → 413
- [ ] **LIMIT-03:** Imagen >10MB → 400
- [ ] **LIMIT-04:** Rate limit se resetea después de 1 hora

**Estimación:** 2 días

---

### DÍA 15-16: Tests de Database Avanzados

**Archivo:** `test/integration/database/state_transitions_test.dart`

**Casos a implementar:**

- [ ] **STATE-01:** draft → published → hidden
- [ ] **STATE-02:** published → deleted (soft delete)
- [ ] **STATE-03:** NO permitir published → draft

**Archivo:** `test/integration/database/rate_limit_test.dart`

**Casos a implementar:**

- [ ] **RL-DB-01:** Reserva de slot en rate_limit_daily
- [ ] **RL-DB-02:** Rollback si falla creación

**Estimación:** 2 días

---

### DÍA 17-18: Tests E2E Adicionales

**Archivo:** `integration_test/offline_flow_test.dart`

**Casos a implementar:**

- [ ] **OFF-01:** Submit sin red → error graceful
- [ ] **OFF-02:** Submit con red intermitente → retry

**Archivo:** `integration_test/location_flow_test.dart`

**Casos a implementar:**

- [ ] **LOC-01:** GPS denegado → selección manual
- [ ] **LOC-02:** GPS timeout → fallback manual

**Estimación:** 2 días

---

## 🟢 FASE 3: MEJORAS (P2) - 5 días

### DÍA 19-20: Tests de Accesibilidad

**Archivo:** `test/accessibility/scaling_test.dart`

**Casos:**
- [ ] Texto grande (textScaleFactor 2.0) sin overflow
- [ ] Alto contraste
- [ ] Lector de pantalla (semántica)

**Estimación:** 2 días

---

### DÍA 21-23: Tests de Rendimiento

**Archivo:** `test/performance/benchmarks_test.dart`

**Casos:**
- [ ] Tiempo de carga inicial <500ms
- [ ] Submit con imagen <3s
- [ ] Memory leaks en navegación
- [ ] Scroll 60 fps

**Estimación:** 3 días

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

### Pre-requisitos
- [ ] Crear usuarios de prueba en Supabase
- [ ] Obtener JWTs de prueba
- [ ] Configurar .env.test
- [ ] Crear helpers compartidos

### Fase 1 - BLOQUEADORES (P0)
**Seguridad (DÍA 1-5):**
- [ ] Tests de autenticación Edge Functions
- [ ] Tests de validación Edge Functions
- [ ] Tests de RLS gossips table
- [ ] Tests de RLS storage buckets
- [ ] Tests de validación media

**E2E y Fixes (DÍA 6-10):**
- [ ] E2E: Crear gossip sin media
- [ ] E2E: Crear gossip con imagen
- [ ] Tests de idempotencia
- [ ] Arreglar controller tests (48 rotos)

### Fase 2 - POST-LANZAMIENTO (P1)
**DÍA 11-18:**
- [ ] Tests de moderación (OpenAI)
- [ ] Tests de rate limiting
- [ ] Tests de transiciones de estado
- [ ] Tests E2E adicionales (offline, GPS)

### Fase 3 - MEJORAS (P2)
**DÍA 19-23:**
- [ ] Tests de accesibilidad
- [ ] Tests de rendimiento

---

## 🎯 PRIORIZACIÓN: ¿Por Dónde Empezar?

### Orden Recomendado (Impacto vs Esfuerzo)

| Orden | Tarea | Días | Impacto | Bloquea Producción |
|-------|-------|------|---------|-------------------|
| 1 | Pre-requisitos (setup) | 1 | 🔴 Alto | ✅ Sí |
| 2 | Edge Functions - Auth | 1 | 🔴 Crítico | ✅ Sí |
| 3 | RLS Gossips | 1 | 🔴 Crítico | ✅ Sí |
| 4 | RLS Storage | 1 | 🔴 Crítico | ✅ Sí |
| 5 | Media Validation | 1 | 🔴 Alto | ✅ Sí |
| 6 | E2E Golden Paths | 2 | 🔴 Alto | ✅ Sí |
| 7 | Idempotencia | 1 | 🔴 Alto | ✅ Sí |
| 8 | Arreglar Controller | 2 | 🟡 Medio | ❌ No |
| 9 | Edge Functions - Validation | 1 | 🟡 Medio | ❌ No |
| 10 | Resto de Fase 2 | 8 | 🟢 Bajo | ❌ No |

**Total BLOQUEADORES:** 10 días
**Total POST-LANZAMIENTO:** 8 días

---

## 📊 MÉTRICAS DE PROGRESO

### Dashboard de Avance

```
FASE 1 (P0) - BLOQUEADORES: [░░░░░░░░░░] 0/10 días
├─ Pre-requisitos:           [░] 0/1
├─ Edge Functions Auth:      [░] 0/1
├─ RLS Gossips:              [░] 0/1
├─ RLS Storage:              [░] 0/1
├─ Media Validation:         [░] 0/1
├─ E2E Golden Paths:         [░░] 0/2
├─ Idempotencia:             [░] 0/1
└─ Arreglar Controller:      [░░] 0/2

FASE 2 (P1) - POST-LANZAMIENTO: [░░░░░░░░] 0/8 días
FASE 3 (P2) - MEJORAS:          [░░░░░] 0/5 días

Tests pasando: 1834/1964 (93.4%)
Objetivo: >1870/1964 (>95%)
Gap: 36 tests
```

---

## 🚀 COMANDOS ÚTILES

### Ejecutar tests por fase

```bash
# Pre-requisitos
flutter test test/integration/helpers/

# Fase 1: Seguridad
flutter test test/integration/edge_functions/moderate_gossip_auth_test.dart
flutter test test/integration/database/rls_gossips_test.dart
flutter test test/integration/storage/rls_buckets_test.dart
flutter test test/integration/storage/upload_validation_test.dart

# Fase 1: E2E
flutter test integration_test/create_gossip_flow_test.dart
flutter test integration_test/create_gossip_with_image_test.dart
flutter test integration_test/retry_idempotency_test.dart

# Fase 1: Fixes
flutter test test/features/gossip/presentation/controllers/add_gossip_controller_test.dart

# Fase 2
flutter test test/integration/edge_functions/moderate_gossip_moderation_test.dart
flutter test test/integration/edge_functions/moderate_gossip_limits_test.dart

# Todos los tests de integración
flutter test test/integration/

# Todos los tests E2E
flutter test integration_test/

# Suite completa
flutter test
```

### Generar coverage

```bash
# Coverage de integración
flutter test test/integration/ --coverage

# Coverage E2E (requiere dispositivo)
flutter test integration_test/ --coverage

# Ver coverage HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📝 NOTAS FINALES

### Dependencias Externas

- Usuarios de prueba en Supabase creados
- JWTs válidos obtenidos
- OpenAI API key configurada (para tests de moderación)
- Dispositivo físico o emulador (para E2E)

### Consideraciones

1. **Tests de integración requieren internet:** No pueden ejecutarse offline
2. **Tests E2E requieren app corriendo:** Usar emulador o dispositivo real
3. **RLS tests necesitan service_role:** Solo para cleanup, no para asserts
4. **Rate limiting puede afectar tests:** Usar diferentes idempotency keys

### Referencias

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Supabase Testing Guide](https://supabase.com/docs/guides/testing)
- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)

---

**FIN DEL ROADMAP**

**Última actualización:** 2026-10-22  
**Versión:** 1.0  
**Mantenedor:** Alejo
