# 🎯 Organización de Tests Fallidos - Plan de Acción

**Fecha:** 2026-11-11  
**Tests Totales:** ~2,777  
**Tests Fallidos:** 89 (3.2%)  
**Tests Pasando:** 2,678 (96.8%)

---

## 📊 Resumen Ejecutivo

Los tests fallidos se pueden agrupar en **4 categorías principales**, ordenadas por prioridad:

| # | Categoría | Tests | Tiempo Est. | Prioridad | Complejidad |
|---|-----------|-------|-------------|-----------|-------------|
| 1 | **MaterialApp Duplicado** | 19 | 2-3h | 🔴 CRÍTICA | ⭐ BAJA |
| 2 | **Migración i18n** | 45+ | 4-6h | 🟡 ALTA | ⭐⭐ MEDIA |
| 3 | **Lógica/Comportamiento** | 17 | 2-3h | 🟢 MEDIA | ⭐⭐⭐ ALTA |
| 4 | **Smoke Test** | 1 | 15m | 🔵 BAJA | ⭐ BAJA |

**Total:** 82+ tests | **8-12 horas**

---

## 🎯 Estrategia Recomendada

### Quick Wins Primero ✨
1. **Fase 1: MaterialApp Duplicado** → Impacto alto, esfuerzo bajo
2. **Fase 2: i18n** → Impacto masivo, esfuerzo medio
3. **Fase 3: Lógica** → Requiere análisis detallado
4. **Fase 4: Smoke** → Trivial

---

## 🔴 FASE 1: MaterialApp Duplicado (CRÍTICA)

### 📊 Resumen
- **Tests Afectados:** 19
- **Tiempo Estimado:** 2-3 horas
- **Impacto:** CRÍTICO - Bloquea tests de infraestructura
- **Complejidad:** ⭐ BAJA

### 🎯 Archivos Afectados

```
test/
├── main_test.dart (13 tests)
└── main_additional_test.dart (6 tests)
```

### 🐛 Problema

Los tests encuentran **2 instancias de MaterialApp** cuando esperan 1:

```
Expected: exactly one matching candidate
Actual: _TypeWidgetFinder:<Found 2 widgets with type "MaterialApp": [
  MaterialApp(state: _MaterialAppState#ba486),
  MaterialApp(state: _MaterialAppState#573b7),
]>
Which: is too many
```

### ✅ Solución

**Usar `.first` o `.last` en finders:**

```dart
// ❌ ANTES
final materialApp = tester.widget<MaterialApp>(
  find.byType(MaterialApp)
);

// ✅ DESPUÉS
final materialApp = tester.widget<MaterialApp>(
  find.byType(MaterialApp).first
);
```

### 🔨 Tests Específicos a Arreglar

| Test | Archivo | Línea Aprox |
|------|---------|-------------|
| debe tener una jerarquía de widgets válida | main_test.dart | ~50 |
| debe ser reconstruible múltiples veces sin state | main_test.dart | ~80 |
| debe mantener configuración al reconstruir | main_test.dart | ~100 |
| themeMode debe seguir el sistema | main_test.dart | ~120 |
| home debe ser una instancia const de AuthGate | main_test.dart | ~140 |

### 🚀 Comando para Ejecutar

```bash
# Todos los tests de esta fase
flutter test test/main_test.dart test/main_additional_test.dart

# Individual
flutter test test/main_test.dart --name "debe tener una jerarquía"
flutter test test/main_test.dart --name "themeMode debe seguir"
```

### ✅ Checklist

- [ ] Revisar main_test.dart línea por línea
- [ ] Cambiar todos los `find.byType(MaterialApp)` a `.first`
- [ ] Ejecutar tests y verificar que pasen
- [ ] Revisar main_additional_test.dart
- [ ] Ejecutar todos los tests de la fase
- [ ] Confirmar 0 fallos en esta categoría

---

## 🟡 FASE 2: Migración i18n (ALTA PRIORIDAD)

### 📊 Resumen
- **Tests Afectados:** 45+
- **Tiempo Estimado:** 4-6 horas
- **Impacto:** MASIVO - 51% de los fallos
- **Complejidad:** ⭐⭐ MEDIA

### 🎯 Archivos Afectados (Por Impacto)

```
test/features/
├── gossip/presentation/widgets/
│   ├── location_selector_test.dart (20 tests) ⚠️ MAYOR IMPACTO
│   ├── city_autocomplete_optimized_test.dart (7 tests)
│   ├── city_autocomplete_test.dart (5 tests)
│   ├── report_gossip_dialog_test.dart (6 tests)
│   └── submit_button_test.dart (4 tests)
└── auth/domain/validators/
    └── auth_validator_security_test.dart (4 tests)
```

### 🐛 Problema

Tests esperan `easy_localization` pero la app migró a `gen-l10n`:

```
'package:easy_localization/src/easy_localization_controller.dart':
Failed assertion: line 49 pos 7: 'isInit': 
EasyLocalization.ensureInitialized() has not been called
```

### ✅ Solución

#### Paso 1: Crear Helper de Testing

```dart
// test/helpers/i18n_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget makeTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: child,
  );
}
```

#### Paso 2: Actualizar Tests

```dart
// ❌ ANTES (easy_localization)
await tester.pumpWidget(
  EasyLocalization(
    supportedLocales: [Locale('es')],
    path: 'assets/translations',
    child: LocationSelector(controller: controller),
  ),
);

// ✅ DESPUÉS (gen-l10n)
import '../../helpers/i18n_test_helper.dart';

await tester.pumpWidget(
  makeTestableWidget(
    LocationSelector(controller: controller),
  ),
);
```

#### Paso 3: Actualizar Imports

```dart
// ❌ REMOVER
import 'package:easy_localization/easy_localization.dart';

// ✅ AGREGAR (si se necesita acceder a traducciones)
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### 🚀 Plan de Ejecución (Orden Recomendado)

#### 1. Crear Helper (5 min)
```bash
# Crear archivo
touch test/helpers/i18n_test_helper.dart
# Copiar código del Paso 1
```

#### 2. location_selector_test.dart (20 tests, 1-1.5h)
```bash
flutter test test/features/gossip/presentation/widgets/location_selector_test.dart
```

**Estrategia:**
- Buscar todos los `EasyLocalization(`
- Reemplazar con `makeTestableWidget(`
- Ajustar la estructura (remover `supportedLocales`, `path`, etc.)
- Actualizar imports

#### 3. city_autocomplete_optimized_test.dart (7 tests, 30 min)
```bash
flutter test test/features/gossip/presentation/widgets/city_autocomplete_optimized_test.dart
```

#### 4. report_gossip_dialog_test.dart (6 tests, 30 min)
```bash
flutter test test/features/gossip/presentation/widgets/report_gossip_dialog_test.dart
```

#### 5. city_autocomplete_test.dart (5 tests, 20 min)
```bash
flutter test test/features/gossip/presentation/widgets/city_autocomplete_test.dart
```

#### 6. submit_button_test.dart (4 tests, 20 min)
```bash
flutter test test/features/gossip/presentation/widgets/submit_button_test.dart
```

#### 7. auth_validator_security_test.dart (4 tests, 20 min)
```bash
flutter test test/features/auth/domain/validators/auth_validator_security_test.dart
```

### ✅ Checklist

- [ ] Crear `test/helpers/i18n_test_helper.dart`
- [ ] Probar helper con 1 test simple
- [ ] Migrar location_selector_test.dart (20 tests)
- [ ] Migrar city_autocomplete_optimized_test.dart (7 tests)
- [ ] Migrar report_gossip_dialog_test.dart (6 tests)
- [ ] Migrar city_autocomplete_test.dart (5 tests)
- [ ] Migrar submit_button_test.dart (4 tests)
- [ ] Migrar auth_validator_security_test.dart (4 tests)
- [ ] Ejecutar todos los tests de la fase juntos
- [ ] Confirmar 0 fallos en esta categoría

---

## 🟢 FASE 3: Lógica/Comportamiento (MEDIA PRIORIDAD)

### 📊 Resumen
- **Tests Afectados:** 17
- **Tiempo Estimado:** 2-3 horas
- **Impacto:** MEDIO - Tests de funcionalidad
- **Complejidad:** ⭐⭐⭐ ALTA

### 🎯 Archivos Afectados

```
test/features/
├── home/presentation/screens/
│   └── main_navigation_screen_test.dart (8 tests)
├── search/presentation/screens/
│   └── search_screen_test.dart (7 tests)
└── location/presentation/managers/
    └── location_manager_test.dart (2 tests)
```

### 🐛 Problemas por Archivo

#### A. main_navigation_screen_test.dart (8 tests)

**Posibles Causas:**
- Falta configuración de i18n (aplicar fix de Fase 2)
- Mocks de controladores incompletos
- Problemas con navegación entre tabs

**Estrategia:**
1. Aplicar fix de i18n primero
2. Verificar mocks de controladores
3. Revisar tests de navegación individualmente

```bash
flutter test test/features/home/presentation/screens/main_navigation_screen_test.dart
```

#### B. search_screen_test.dart (7 tests)

**Problema Identificado:**

El test `debe mostrar loading indicator mientras busca` espera encontrar un `CircularProgressIndicator` pero no lo encuentra.

**Causa:**
- El estado de loading es **demasiado rápido** con mocks
- Entre `await tester.pump()` el estado ya cambió de `isLoading=true` a `isLoading=false`

**Solución:**

```dart
// ❌ PROBLEMA
test('debe mostrar loading indicator mientras busca', () async {
  await tester.enterText(find.byType(TextField), 'Test');
  await tester.pump(); // Estado ya cambió ❌
  
  expect(find.byType(CircularProgressIndicator), findsWidgets); // ❌ No encuentra
});

// ✅ SOLUCIÓN 1: Mock con delay controlado
test('debe mostrar loading indicator mientras busca', () async {
  final completer = Completer<Result<Failure, List<Gossip>>>();
  
  when(mockSearchGossips(query: 'Test'))
      .thenAnswer((_) => completer.future);
  
  await tester.enterText(find.byType(TextField), 'Test');
  await tester.pump(); // Ahora sí debería estar loading
  
  expect(find.byType(CircularProgressIndicator), findsWidgets); // ✅
  
  // Completar la búsqueda
  completer.complete(Result.success([]));
  await tester.pumpAndSettle();
});

// ✅ SOLUCIÓN 2: Usar pump() múltiples veces
test('debe mostrar loading indicator mientras busca', () async {
  await tester.enterText(find.byType(TextField), 'Test');
  await tester.pump(); // Frame 1: Texto ingresado
  await tester.pump(Duration.zero); // Frame 2: Loading state
  
  expect(find.byType(CircularProgressIndicator), findsWidgets); // ✅
  
  await tester.pumpAndSettle(); // Esperar a que termine
});
```

**Comando:**
```bash
flutter test test/features/search/presentation/screens/search_screen_test.dart
```

**Tests a Revisar:**
- debe mostrar loading indicator mientras busca
- debe mostrar resultados de búsqueda
- debe manejar búsqueda vacía
- debe mostrar mensaje de error
- debe filtrar por ciudad cuando filterByCity está activo

#### C. location_manager_test.dart (2 tests)

**Problema:**
Tests esperan `early return` pero no sucede.

**Causa:**
Lógica de `loadDefaultLocation` para casos edge (null, invalid, etc.)

**Estrategia:**
1. Revisar qué casos edge están siendo testeados
2. Verificar lógica del método
3. Ajustar tests o código según corresponda

```bash
flutter test test/features/location/presentation/managers/location_manager_test.dart
```

### ✅ Checklist

- [ ] MainNavigationScreen:
  - [ ] Aplicar fix de i18n
  - [ ] Verificar mocks
  - [ ] Ejecutar tests
  - [ ] Corregir fallos individuales
- [ ] SearchScreen:
  - [ ] Aplicar fix de i18n
  - [ ] Implementar Completer o pump múltiple
  - [ ] Verificar otros tests de búsqueda
  - [ ] Ejecutar todos los tests
- [ ] LocationManager:
  - [ ] Revisar lógica de early return
  - [ ] Ajustar tests
  - [ ] Ejecutar tests
- [ ] Confirmar 0 fallos en esta categoría

---

## 🔵 FASE 4: Smoke Test (BAJA PRIORIDAD)

### 📊 Resumen
- **Tests Afectados:** 1
- **Tiempo Estimado:** 15 minutos
- **Impacto:** BAJO - Test básico
- **Complejidad:** ⭐ BAJA

### 🎯 Archivo

```
test/widget_test.dart
```

### 🐛 Problema

Probablemente relacionado con i18n (no inicializado).

### ✅ Solución

Aplicar fix de i18n (Fase 2):

```dart
// test/widget_test.dart
import 'helpers/i18n_test_helper.dart';

testWidgets('App smoke test', (tester) async {
  await tester.pumpWidget(makeTestableWidget(ChismesApp()));
  // ... resto del test
});
```

### 🚀 Comando

```bash
flutter test test/widget_test.dart
```

### ✅ Checklist

- [ ] Aplicar fix de i18n
- [ ] Ejecutar test
- [ ] Confirmar que pasa

---

## 📋 Scripts de Ayuda

### Script para Ejecutar por Fase

```bash
# Crear archivo: test_by_phase.sh
#!/bin/bash

case "$1" in
  1)
    echo "🔴 FASE 1: MaterialApp Duplicado"
    flutter test test/main_test.dart test/main_additional_test.dart
    ;;
  2)
    echo "🟡 FASE 2: Migración i18n"
    flutter test \
      test/features/gossip/presentation/widgets/location_selector_test.dart \
      test/features/gossip/presentation/widgets/city_autocomplete_optimized_test.dart \
      test/features/gossip/presentation/widgets/city_autocomplete_test.dart \
      test/features/gossip/presentation/widgets/report_gossip_dialog_test.dart \
      test/features/gossip/presentation/widgets/submit_button_test.dart \
      test/features/auth/domain/validators/auth_validator_security_test.dart
    ;;
  3)
    echo "🟢 FASE 3: Lógica/Comportamiento"
    flutter test \
      test/features/home/presentation/screens/main_navigation_screen_test.dart \
      test/features/search/presentation/screens/search_screen_test.dart \
      test/features/location/presentation/managers/location_manager_test.dart
    ;;
  4)
    echo "🔵 FASE 4: Smoke Test"
    flutter test test/widget_test.dart
    ;;
  all)
    echo "🎯 TODAS LAS FASES"
    $0 1 && $0 2 && $0 3 && $0 4
    ;;
  *)
    echo "Uso: $0 [1|2|3|4|all]"
    echo ""
    echo "Fases:"
    echo "  1 - MaterialApp Duplicado (19 tests, 2-3h)"
    echo "  2 - Migración i18n (45+ tests, 4-6h)"
    echo "  3 - Lógica/Comportamiento (17 tests, 2-3h)"
    echo "  4 - Smoke Test (1 test, 15m)"
    echo "  all - Todas las fases"
    exit 1
    ;;
esac
```

Hacer ejecutable:
```bash
chmod +x test_by_phase.sh
```

### Ver Tests Fallidos Rápidamente

```bash
# Contar fallos
flutter test 2>&1 | grep -c "\\[E\\]"

# Ver nombres de tests fallidos
flutter test 2>&1 | grep "\\[E\\]" | grep -oE "test/.*\\.dart"

# Ver detalles de un test específico
flutter test <path> --name "<test name>" --reporter expanded
```

---

## 📊 Tracking de Progreso

### Resumen por Fase

| Fase | Tests | Completados | % | Estado |
|------|-------|-------------|---|--------|
| 1: MaterialApp | 19 | 0 | 0% | ⏳ Pendiente |
| 2: i18n | 45+ | 0 | 0% | ⏳ Pendiente |
| 3: Lógica | 17 | 0 | 0% | ⏳ Pendiente |
| 4: Smoke | 1 | 0 | 0% | ⏳ Pendiente |
| **TOTAL** | **82+** | **0** | **0%** | ⏳ Pendiente |

### Timeline Estimado

```
Día 1 (4-5h):
  ✅ Fase 1: MaterialApp (2-3h)
  ✅ Fase 2: Crear helper + 2 archivos (1.5-2h)

Día 2 (4-5h):
  ✅ Fase 2: Resto de archivos i18n (2.5-3h)
  ✅ Fase 3: MainNavigationScreen (1-1.5h)

Día 3 (2-3h):
  ✅ Fase 3: SearchScreen + LocationManager (1.5-2h)
  ✅ Fase 4: Smoke test (15m)
  ✅ Verificación final (30m)
```

---

## 🎯 Decisión Inmediata

### ¿Por Dónde Empezar?

**Recomendación:** FASE 1 (MaterialApp Duplicado)

**Razones:**
1. ✅ **Quick Win** - Problema simple, solución clara
2. ✅ **Alto Impacto** - 19 tests, 21% de los fallos
3. ✅ **Baja Complejidad** - Cambiar `.first` en finders
4. ✅ **Desbloquea** - Tests de infraestructura críticos
5. ✅ **Motivación** - Victoria temprana para momentum

### Comando para Empezar AHORA

```bash
# Ver el primer archivo
code test/main_test.dart

# O ejecutar para ver los fallos
flutter test test/main_test.dart
```

---

## 📚 Referencias

- [CLAUDE.md](CLAUDE.md) - Quick reference del proyecto
- [.claude/TESTING.md](.claude/TESTING.md) - Standards de testing
- [TEST_FAILURES_REPORT.md](TEST_FAILURES_REPORT.md) - Reporte completo de fallos
- [Flutter Testing Docs](https://flutter.dev/docs/testing)

---

## 🏁 Meta Final

```
Estado Actual:  2,678 / 2,777 tests pasando (96.8%)
Meta:           2,777 / 2,777 tests pasando (100%)
Faltan:         89 tests (3.2%)
Tiempo:         8-12 horas de trabajo
```

**¡Vamos a lograrlo! 💪**

---

*Documento creado: 2026-11-11*  
*Última actualización: 2026-11-11*
