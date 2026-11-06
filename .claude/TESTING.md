# Testing Standards - Chismes App

> **Standards y convenciones de testing.** Guía completa de testing en el proyecto.

**Última actualización:** 2026-10-20

---

## 📋 Índice

1. [⚠️ Regla Crítica](#️-regla-crítica)
2. [Estructura](#estructura)
3. [Pattern AAA](#pattern-aaa)
4. [Mocks (Mockito)](#mocks-mockito)
5. [Coverage](#coverage)
6. [Anti-Patterns](#anti-patterns)
7. [Comandos](#comandos)

---

## ⚠️ REGLA CRÍTICA: TESTS NO MODIFICAN CÓDIGO DE PRODUCCIÓN

**NUNCA modificar código de producción para que los tests funcionen.**

```
❌ MAL: Cambiar código de producción para pasar tests
✅ BIEN: Adaptar tests al código de producción existente
```

### Razones

1. **Los tests deben validar el código, no dictarlo**
   - El código de producción tiene requerimientos de negocio
   - Los tests se adaptan a esos requerimientos
   - NO al revés

2. **Código de producción > Tests**
   - Si un test falla, revisar:
     1. ¿El test está mal escrito?
     2. ¿El test asume comportamiento incorrecto?
     3. ¿El código tiene un bug real?
   - SOLO si es bug real → cambiar código

3. **Tests deben ser flexibles**
   - Usar mocks/stubs apropiados
   - Aislar dependencias externas
   - Probar contratos, no implementaciones

### Excepciones (raras)

- ✅ Refactoring para mejor testabilidad (ej: inyectar dependencias)
- ✅ Exponer interfaces para testing (ej: callbacks mockeables)
- ✅ Separar lógica de UI para testear lógica pura

**Si necesitas cambiar código para tests:**
1. Documentar en comentario por qué
2. Verificar que no rompe funcionalidad
3. Considerar si el diseño es correcto

### Ejemplo del proyecto

```dart
// ✅ BIEN: main.dart tiene callbacks mockeables
Future<void> Function() loadEnv = () async { ... };
// Los tests sobrescriben este callback sin cambiar lógica

// ❌ MAL: Cambiar lógica de negocio para pasar test
// NO hacer esto solo para que el test pase
```

---

## Estructura

Los tests siguen la misma estructura que `lib/`:

```
test/
├── core/
│   ├── error/
│   │   ├── error_handler_test.dart
│   │   └── failure_test.dart
│   ├── result/
│   │   └── result_test.dart
│   ├── logging/
│   │   ├── app_logger_test.dart
│   │   └── remote_logger_test.dart
│   └── validation/
│       └── form_validators_test.dart
│
└── features/
    └── gossip/
        ├── data/
        │   ├── datasources/
        │   │   ├── supabase_gossip_remote_data_source_test.dart
        │   │   └── shared_prefs_gossip_local_data_source_test.dart
        │   ├── models/
        │   │   └── gossip_model_test.dart
        │   └── repositories/
        │       └── gossip_repository_impl_test.dart
        ├── domain/
        │   ├── entities/
        │   │   └── gossip_test.dart
        │   └── usecases/
        │       └── create_gossip_test.dart
        └── presentation/
            └── controllers/
                └── add_gossip_controller_test.dart
```

### Naming

```dart
// Archivo de test
gossip_repository_impl_test.dart  // Siempre termina en _test.dart

// Test group
group('GossipRepositoryImpl', () { ... });

// Test individual
test('debe retornar gossips cuando el remoto funciona', () { ... });
test('debe retornar error cuando el remoto falla', () { ... });
```

---

## Pattern AAA (Arrange-Act-Assert)

**SIEMPRE estructurar tests con AAA:**

```dart
test('debe retornar gossips del remoto y guardar en cache', () async {
  // Arrange - Preparar datos y mocks
  final mockModels = [
    GossipModel(id: '1', subject: 'Test', /* ... */),
    GossipModel(id: '2', subject: 'Test 2', /* ... */),
  ];
  
  when(mockRemote.getGossips(any))
      .thenAnswer((_) async => mockModels);
  
  when(mockLocal.saveAll(any))
      .thenAnswer((_) async => Future.value());
  
  final query = GossipQuery(cityId: 'city-1');
  
  // Act - Ejecutar operación
  final result = await repository.getGossips(query);
  
  // Assert - Verificar resultado
  expect(result.isSuccess, isTrue);
  expect(result.successValue, isNotNull);
  expect(result.successValue!.length, 2);
  expect(result.successValue![0].id, '1');
  
  // Verify - Verificar llamadas a mocks
  verify(mockRemote.getGossips(query)).called(1);
  verify(mockLocal.saveAll(mockModels)).called(1);
  verifyNoMoreInteractions(mockRemote);
  verifyNoMoreInteractions(mockLocal);
});
```

### Secciones

**1. Arrange (Preparar)**
- Crear datos de prueba
- Configurar mocks (`when().thenAnswer()`)
- Preparar inputs

**2. Act (Ejecutar)**
- Llamar al método que se está probando
- UNA SOLA operación por test

**3. Assert (Verificar)**
- Verificar resultado esperado
- Usar `expect()` para validaciones
- Verificar llamadas a mocks con `verify()`

---

## Mocks (Mockito)

### Setup

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// 1. Declarar mocks
@GenerateMocks([
  GossipRemoteDataSource,
  GossipLocalDataSource,
  AppLogger,
])
void main() {
  // Tests aquí
}

// 2. Generar mocks
// flutter pub run build_runner build --delete-conflicting-outputs
// Genera: gossip_repository_impl_test.mocks.dart
```

### Uso

```dart
void main() {
  late GossipRepositoryImpl repository;
  late MockGossipRemoteDataSource mockRemote;
  late MockGossipLocalDataSource mockLocal;
  late MockAppLogger mockLogger;
  
  setUp(() {
    mockRemote = MockGossipRemoteDataSource();
    mockLocal = MockGossipLocalDataSource();
    mockLogger = MockAppLogger();
    
    repository = GossipRepositoryImpl(
      mockRemote,
      mockLocal,
      mockLogger,
    );
  });
  
  tearDown(() {
    // Limpiar si es necesario
  });
  
  group('getGossips', () {
    test('debe retornar success cuando remoto funciona', () async {
      // Arrange
      when(mockRemote.getGossips(any))
          .thenAnswer((_) async => [mockModel]);
      when(mockLocal.saveAll(any))
          .thenAnswer((_) async => Future.value());
      
      // Act
      final result = await repository.getGossips(query);
      
      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRemote.getGossips(any)).called(1);
    });
    
    test('debe retornar failure cuando remoto lanza excepción', () async {
      // Arrange
      when(mockRemote.getGossips(any))
          .thenThrow(Exception('Network error'));
      when(mockLocal.getAll())
          .thenThrow(Exception('Cache error'));
      
      // Act
      final result = await repository.getGossips(query);
      
      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<NetworkFailure>());
    });
  });
}
```

### When/Then Patterns

```dart
// Retornar valor
when(mock.method()).thenReturn(value);

// Retornar Future
when(mock.asyncMethod()).thenAnswer((_) async => value);

// Lanzar excepción
when(mock.method()).thenThrow(Exception('Error'));

// Lanzar excepción async
when(mock.asyncMethod()).thenAnswer((_) async => throw Exception('Error'));

// Múltiples llamadas
when(mock.method())
    .thenAnswer((_) async => value1)  // Primera llamada
    .thenAnswer((_) async => value2); // Segunda llamada

// Capturar argumentos
when(mock.method(captureAny)).thenReturn(value);
final captured = verify(mock.method(captureAny)).captured;
expect(captured[0], expectedArg);
```

### Verify Patterns

```dart
// Verificar llamada simple
verify(mock.method()).called(1);

// Verificar nunca llamado
verifyNever(mock.method());

// Verificar orden de llamadas
verifyInOrder([
  mock.method1(),
  mock.method2(),
]);

// Verificar no hay más interacciones
verifyNoMoreInteractions(mock);

// Verificar con argumentos específicos
verify(mock.method('specific-arg')).called(1);

// Verificar con any matcher
verify(mock.method(any)).called(1);
```

---

## Coverage

### Estado Actual

**Coverage Global:** ✅ **78.9%** (1,865 / 2,363 líneas)  
**Tests:** 1,846 pasando / 51 fallando = **1,897 tests totales**  
**Archivos de test:** 59 archivos  
**Última actualización:** 2026-10-20 07:00  
**Reporte HTML:** `coverage/html/index.html` ⭐

### Coverage por Feature

| Feature | Coverage | Estado |
|---------|----------|--------|
| Core | ~88% | ✅ Excelente |
| Gossip | ~80% | ✅ Bueno |
| Location | ~75% | ✅ Bueno |
| Home | ~60% | ⚠️ Mejorar |
| Search | ~55% | ⚠️ Mejorar |

### Archivos con 100% Coverage

- ✅ `core/error/failure.dart` (49 tests)
- ✅ `core/error/error_messages.dart` (70 tests)
- ✅ `core/logging/log_entry.dart` (60 tests)
- ✅ `core/result/result.dart`
- ✅ `core/validation/form_validators.dart`

### Archivos con Coverage Especial

**device_info_provider.dart (20.8%)**
- **Razón:** Plugins nativos no funcionan en unit tests
- **Cubierto:** Error handling (100%), cache, clearCache
- **No cubierto:** Success path (requiere integration tests)
- **Estado:** Aceptable - error handling crítico está cubierto

**remote_logger.dart (~85%)**
- **Cubierto:** MockRemoteLogger (100%), SupabaseRemoteLogger básico
- **Validado:** Persistencia selectiva, fire-and-forget, error handling
- **Nota:** Tests simplificados por limitaciones de Mockito

**app_logger.dart (~95%)** ⭐
- **Cubierto:** Todos los métodos públicos
- **Validado:** Persistencia selectiva, enriquecimiento, logs concurrentes
- **Casos:** Operaciones exitosas, errores, crashes, warnings

**supabase_storage_service.dart (documented)** ⭐
- **Cubierto:** UploadResult (100%), deleteImage() con mocks
- **Documentado:** uploadImageAfterGossipCreated() - lógica completa (59 tests)
- **Validado:** Flujo, validaciones, paths, error handling
- **Nota:** Tests de lógica (no funcionales) por plugins nativos

**image_compressor.dart (documented)**
- **Cubierto:** getFileSizeInKB() con archivos reales (6 tests funcionales)
- **Documentado:** compressGossipImage(), generateThumbnail()
- **Nota:** Tests de documentación por plugins nativos

**deep_link_service.dart (documented)** ⭐
- **Cubierto:** Métodos static generadores (100%)
- **Documentado:** URI parsing, validación, tipos
- **Validado:** 3 tipos de links, query params, errores
- **Tests:** 31 generators, 30 parsing, 5 scenarios, 20 validation

**app_radius.dart (0% técnico)** ⭐
- **Razón 0%:** Solo constantes static (no ejecutables para lcov)
- **Validado:** 7 valores, escala incremental, múltiplos
- **Nota:** 0% coverage es NORMAL para constantes

**shared_prefs_gossip_local_data_source.dart (TBD)** ⭐
- **Cubierto:** getAll, save, saveAll, clear, getCacheInfo
- **Documentado:** Edge Cases y Performance (20 tests)
- **Validado:** Cache persistente, max 100, versión, idempotencia

### Objetivo

**Mantener >75% en nuevas features**

Coverage de 78.9% es EXCELENTE para un MVP. Proyectos comerciales típicos: 50-70%.

---

## Anti-Patterns

### ❌ NO Hacer

```dart
// ❌ Test sin AAA structure
test('test de repository', () async {
  final result = await repository.getGossips(query);
  expect(result.isSuccess, isTrue);
  when(mockRemote.getGossips(any)).thenAnswer((_) async => []);
  // Configurar mock DESPUÉS de usar es incorrecto
});

// ❌ Tests dependientes entre sí
test('test 1', () {
  globalVariable = 'value';  // Modifica estado global
});

test('test 2', () {
  expect(globalVariable, 'value');  // Depende del test 1
});

// ❌ Múltiples Acts en un test
test('test múltiples operaciones', () {
  final result1 = repository.create(input1);  // Act 1
  final result2 = repository.create(input2);  // Act 2
  // Dividir en 2 tests
});

// ❌ No usar setUp/tearDown
test('test 1', () {
  final mock = MockService();  // Duplicado
  final repository = Repository(mock);
});

test('test 2', () {
  final mock = MockService();  // Duplicado
  final repository = Repository(mock);
});

// ❌ Assertions débiles
test('debe retornar algo', () {
  final result = repository.get();
  expect(result, isNotNull);  // Muy débil, cualquier valor pasa
});

// ❌ No verificar mocks
test('debe llamar al remoto', () {
  when(mockRemote.get()).thenAnswer((_) async => data);
  await repository.get();
  // Falta verify() - no se verifica que se llamó
});

// ❌ Tests frágiles (acoplados a implementación)
test('debe hacer exactamente 3 llamadas a logger', () {
  repository.create(input);
  verify(mockLogger.d(any)).called(3);  // Se rompe si agregamos 1 log
});
```

### ✅ Hacer

```dart
// ✅ Tests independientes
setUp(() {
  mock = MockService();
  repository = Repository(mock);
});

test('test 1', () {
  // Usa setup común
});

test('test 2', () {
  // Usa setup común, independiente de test 1
});

// ✅ AAA structure clara
test('debe crear gossip exitosamente', () {
  // Arrange
  final input = CreateGossipInput(/* ... */);
  when(mockRemote.create(any)).thenAnswer((_) async => mockModel);
  
  // Act
  final result = await repository.create(input);
  
  // Assert
  expect(result.isSuccess, isTrue);
  expect(result.successValue!.id, mockModel.id);
  verify(mockRemote.create(any)).called(1);
});

// ✅ Tests descriptivos
test('debe retornar failure cuando remoto lanza excepción de red', () {
  // Nombre descriptivo explica el escenario exacto
});

// ✅ Probar contratos, no implementaciones
test('debe retornar lista de gossips', () {
  // Verifica QUÉ retorna, no CÓMO lo hace internamente
  expect(result, isA<List<Gossip>>());
  expect(result.length, greaterThan(0));
});
```

---

## Comandos

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Feature específico
flutter test test/features/gossip/

# Archivo específico
flutter test test/features/gossip/data/repositories/gossip_repository_impl_test.dart

# Un test específico (por nombre)
flutter test --name "debe retornar gossips del remoto"

# Modo verbose
flutter test --verbose

# Tests en paralelo (más rápido)
flutter test --concurrency=4
```

### Coverage

```bash
# Generar coverage
flutter test --coverage

# Ver reporte en consola
lcov --list coverage/lcov.info

# Generar HTML
genhtml coverage/lcov.info -o coverage/html

# Abrir en navegador
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows

# Ver resumen detallado
cat coverage/RESUMEN_COVERAGE.md
```

### Code Generation (Mocks)

```bash
# Generar mocks
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (regenera automáticamente)
flutter pub run build_runner watch --delete-conflicting-outputs

# Limpiar y regenerar
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### CI/CD

```bash
# Script de CI
#!/bin/bash
set -e

flutter test --coverage
lcov --list coverage/lcov.info

# Fallar si coverage < 75%
COVERAGE=$(lcov --list coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
if (( $(echo "$COVERAGE < 75" | bc -l) )); then
  echo "Coverage $COVERAGE% is below 75%"
  exit 1
fi

echo "Coverage $COVERAGE% is acceptable"
```

---

## 📚 Referencias

- **Testing in Flutter:** https://docs.flutter.dev/testing
- **Mockito:** https://pub.dev/packages/mockito
- **Test Package:** https://pub.dev/packages/test
- **Coverage:** https://github.com/linux-test-project/lcov

---

**Última actualización:** 2026-10-20  
**Mantenedor:** Alejo
