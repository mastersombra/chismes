# Workflow de Tests - Guía Práctica

> **Propósito:** Flujo de trabajo estandarizado para crear y ejecutar tests  
> **Fecha:** 2026-10-19

---

## ⚠️ REGLA DE ORO

### NUNCA MODIFICAR CÓDIGO DE PRODUCCIÓN PARA TESTS

```
❌ MAL: Cambiar código de producción para que tests pasen
✅ BIEN: Adaptar tests al código de producción existente
```

**Si un test falla:**
1. ¿El test está mal escrito? → Arreglar test
2. ¿El test asume comportamiento incorrecto? → Arreglar test
3. ¿Es un bug real? → SOLO ENTONCES arreglar código

---

## 🔄 WORKFLOW ESTÁNDAR

### Paso 1: Escribir Tests

```bash
# Crear archivo de test
touch test/features/mi_feature/mi_archivo_test.dart
```

**Estructura:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generar mocks si es necesario
@GenerateMocks([MiServicio])
import 'mi_archivo_test.mocks.dart';

void main() {
  group('Descripción del grupo', () {
    late MiClase sut; // System Under Test
    late MockMiServicio mockServicio;
    
    setUp(() {
      mockServicio = MockMiServicio();
      sut = MiClase(mockServicio);
    });
    
    test('debe hacer X cuando Y', () async {
      // Arrange
      when(mockServicio.metodo(any)).thenAnswer((_) async => resultado);
      
      // Act
      final resultado = await sut.metodo();
      
      // Assert
      expect(resultado, esperado);
      verify(mockServicio.metodo(any)).called(1);
    });
  });
}
```

---

### Paso 2: Generar Mocks (si es necesario)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Paso 3: Ejecutar Tests

**Opción 1: Test específico**
```bash
flutter test test/features/mi_feature/mi_archivo_test.dart
```

**Opción 2: Feature completo**
```bash
flutter test test/features/mi_feature/
```

**Opción 3: Todos los tests**
```bash
flutter test
```

---

### Paso 4: Generar Coverage HTML (DESPUÉS DE CADA TEST)

**Comando rápido:**
```bash
./scripts/coverage.sh
```

**O manual:**
```bash
# 1. Ejecutar tests con coverage
flutter test --coverage

# 2. Generar HTML
genhtml coverage/lcov.info -o coverage/html --no-function-coverage

# 3. Abrir en navegador
open coverage/html/index.html
```

**Para test específico:**
```bash
./scripts/coverage.sh test/main_test.dart
```

---

## 📊 REVISAR COVERAGE

### En el HTML

1. **Abrir:** `coverage/html/index.html`
2. **Buscar tu archivo:** Navegar por la jerarquía
3. **Ver líneas:**
   - Verde = Cubierta ✅
   - Rojo = No cubierta ❌
   - Gris = No ejecutable

### En Terminal

```bash
# Ver coverage de un archivo específico
grep -A 50 "SF:lib/main.dart" coverage/lcov.info

# Ver summary
grep -E "LF:|LH:" coverage/lcov.info | head -20
```

---

## 🎯 OBJETIVOS DE COVERAGE

| Capa | Objetivo | Actual |
|------|----------|--------|
| **Domain** | 85-95% | ~90% ✅ |
| **Data** | 80-90% | ~85% ✅ |
| **Presentation** | 60-75% | ~65% ✅ |
| **Core** | 80-90% | ~85% ✅ |

**Coverage total objetivo:** 75-80%
**Coverage total actual:** 77.0% ✅

---

## 🐛 TROUBLESHOOTING

### Test falla: "Mock not registered"

```dart
// Asegurarse de:
1. @GenerateMocks([MiClase]) está presente
2. build_runner generó .mocks.dart
3. Import correcto: import 'archivo_test.mocks.dart';
```

### Test falla: "GetIt not registered"

```dart
// En setUp():
setUp(() {
  // Registrar manualmente en tests
  if (!getIt.isRegistered<MiServicio>()) {
    getIt.registerSingleton<MiServicio>(mockServicio);
  }
});

// En tearDown():
tearDown(() {
  // Limpiar para no afectar otros tests
  if (getIt.isRegistered<MiServicio>()) {
    getIt.unregister<MiServicio>();
  }
});
```

### Coverage no aumenta

**Posibles razones:**
1. La línea no es ejecutable (comentario, declaración)
2. La línea requiere setup específico
3. La línea requiere conexión externa (no testeable)

**Verificar:**
```bash
# Ver qué líneas específicas no están cubiertas
grep -A 100 "SF:lib/tu_archivo.dart" coverage/lcov.info
```

---

## 📝 CHECKLIST ANTES DE COMMIT

### Para Cada Test File:

- [ ] Tests siguen patrón AAA (Arrange, Act, Assert)
- [ ] Mocks generados correctamente (`.mocks.dart` existe)
- [ ] Todos los tests pasan: `flutter test test/mi_test.dart`
- [ ] Coverage actualizado: `./scripts/coverage.sh`
- [ ] Coverage revisado en HTML (líneas verdes)
- [ ] NO se modificó código de producción para tests

### Antes de PR:

- [ ] Todos los tests pasan: `flutter test`
- [ ] Coverage total ≥ 75%: Ver `coverage/html/index.html`
- [ ] Tests documentados en `PLAN_TESTS_UNITARIOS.md`
- [ ] No hay tests con `skip` o `@Skip` sin justificación

---

## 🚀 COMANDOS ÚTILES

### Tests

```bash
# Ejecutar tests con watch (re-ejecuta al cambiar)
flutter test --watch

# Ejecutar tests en paralelo (más rápido)
flutter test --concurrency=4

# Ejecutar solo tests de un grupo
flutter test --name "Descripción del grupo"

# Ejecutar tests excepto algunos
flutter test --exclude-tags=slow
```

### Coverage

```bash
# Coverage de feature específico
./scripts/coverage.sh test/features/gossip/

# Coverage solo de main.dart
./scripts/coverage.sh test/main_test.dart test/main_additional_test.dart

# Ver resumen de coverage
cat coverage/RESUMEN_COVERAGE.md
```

### Debugging

```bash
# Ver output detallado
flutter test --reporter expanded

# Ver solo tests que fallan
flutter test --reporter compact

# Debugging con prints
flutter test --plain-name="nombre del test" --reporter expanded
```

---

## 📚 RECURSOS

### Documentos del Proyecto

- `test/PLAN_TESTS_UNITARIOS.md` - Plan general de testing
- `test/COVERAGE_main_dart_FINAL.md` - Análisis de main.dart
- `coverage/RESUMEN_COVERAGE.md` - Estado actual de coverage
- `CLAUDE.md` - Sección "🧪 TESTING STANDARDS"

### Archivos Clave

- `scripts/coverage.sh` - Script para generar coverage
- `coverage/html/index.html` - Reporte visual de coverage
- `coverage/lcov.info` - Datos raw de coverage

### Packages Usados

- `flutter_test` - Framework de testing
- `mockito` - Mocking framework
- `build_runner` - Generador de código (mocks)

---

## 💡 TIPS

### 1. Tests Rápidos

```dart
// Usar setUp y tearDown para evitar repetición
setUp(() {
  // Setup común
});

tearDown(() {
  // Limpieza común
});
```

### 2. Mocks Reutilizables

```dart
// Crear helpers para mocks comunes
MockMiServicio crearMockExitoso() {
  final mock = MockMiServicio();
  when(mock.metodo(any)).thenAnswer((_) async => exitoso);
  return mock;
}
```

### 3. Tests Legibles

```dart
// Nombres descriptivos y específicos
test('debe retornar error cuando el servidor responde 404', () {
  // Test aquí
});

// NO nombres genéricos
test('test1', () { ... }); // ❌ MAL
```

### 4. Verificar Comportamiento

```dart
// No solo verificar resultado, sino comportamiento
verify(mockLogger.logError(any, any)).called(1);
verifyNever(mockCache.clear());
```

---

## 🎯 SIGUIENTE PASO

Después de completar tests de un archivo:

1. ✅ Ejecutar `./scripts/coverage.sh`
2. ✅ Revisar HTML en navegador
3. ✅ Verificar coverage aumentó
4. ✅ Documentar en `PLAN_TESTS_UNITARIOS.md`
5. ✅ Commit con mensaje: "test: agregar tests para [archivo]"

---

**Última actualización:** 2026-10-19  
**Coverage actual:** 77.0%  
**Tests totales:** 1,418 tests

