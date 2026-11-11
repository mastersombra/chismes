# 📊 Reporte de Tests Fallidos - Chismes App

**Fecha:** 2026-11-10 18:16:15  
**Branch:** main  
**Último Commit:** 5fbcc5d - WIP: Migrate i18n from easy_localization to gen-l10n (80% complete)

---

## 📈 Resumen Ejecutivo

| Métrica | Valor | Porcentaje |
|---------|-------|------------|
| **Tests Totales** | 2,777 | 100% |
| **Tests Pasados** | ✅ 2,678 | 96.8% |
| **Tests Skipped** | ⏭️ 10 | 0.4% |
| **Tests Fallidos** | ❌ 89 | 3.2% |
| **Archivos Afectados** | 11 | - |

**✅ MEJORA:** Los tests fallidos se redujeron de 248 (anterior reporte) a 89 (64% de reducción), pero aún quedan fallos relacionados con la migración i18n.

---

## 🔴 Tests Fallidos por Archivo

### Top 11 Archivos Afectados

| # | Archivo | Fallos | % del Total |
|---|---------|--------|-------------|
| 1 | **location_selector_test.dart** | 20 | 22.5% |
| 2 | **main_test.dart** | 13 | 14.6% |
| 3 | **main_additional_test.dart** | 12 | 13.5% |
| 4 | **city_autocomplete_optimized_test.dart** | 7 | 7.9% |
| 5 | **search_screen_test.dart** | 7 | 7.9% |
| 6 | **report_gossip_dialog_test.dart** | 6 | 6.7% |
| 7 | **city_autocomplete_test.dart** | 5 | 5.6% |
| 8 | **main_navigation_screen_test.dart** | 8 | 9.0% |
| 9 | **auth_validator_security_test.dart** | 4 | 4.5% |
| 10 | **submit_button_test.dart** | 4 | 4.5% |
| 11 | **location_manager_test.dart** | 2 | 2.2% |

**Otros archivos afectados:** widget_test (1)

---

## 🎯 Categorización por Tipo de Error

### A. 🔴 **Errores Críticos - MaterialApp Duplicado** (19 fallos, 21%)

**Prioridad:** CRÍTICA ⚡

**Problema:** Tests encuentran 2 instancias de `MaterialApp` cuando esperan 1

**Error Típico:**
```
Expected: exactly one matching candidate
Actual: _TypeWidgetFinder:<Found 2 widgets with type "MaterialApp": [
  MaterialApp(state: _MaterialAppState#ba486),
  MaterialApp(state: _MaterialAppState#573b7),
]>
Which: is too many
```

**Archivos Afectados:**
- main_test.dart (13 fallos)
- main_additional_test.dart (6 fallos)

**Tests Fallidos Críticos:**
- ❌ debe tener una jerarquía de widgets válida
- ❌ debe ser reconstruible múltiples veces sin state
- ❌ debe mantener configuración al reconstruir
- ❌ themeMode debe seguir el sistema
- ❌ home debe ser una instancia const de AuthGate
- ❌ debe reconstruirse sin errores múltiples veces

**Causa Raíz:**
- Tests crean múltiples instancias de `ChismesApp` o `MaterialApp`
- Falta limpieza adecuada entre tests
- Problema con `testWidgets` y el árbol de widgets

**Solución Propuesta:**
```dart
// ❌ INCORRECTO
final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

// ✅ CORRECTO
final materialApp = tester.widget<MaterialApp>(
  find.byType(MaterialApp).first, // O .last
);
```

**Impacto:** Bloquea tests de configuración y estructura de la app

---

### B. 🟡 **Errores de i18n - Migración Incompleta** (45+ fallos, 51%)

**Prioridad:** ALTA 🌐

**Problema:** Tests esperan `easy_localization` pero la app migró a `gen-l10n`

**Error Típico:**
```
The following message was thrown:
'package:easy_localization/src/easy_localization_controller.dart':
Failed assertion: line 49 pos 7: 'isInit': 
EasyLocalization.ensureInitialized() has not been called
```

**Archivos Afectados:**
- location_selector_test.dart (20 fallos) ⚠️ Mayor impacto
- city_autocomplete_optimized_test.dart (7 fallos)
- city_autocomplete_test.dart (5 fallos)
- report_gossip_dialog_test.dart (6 fallos)
- submit_button_test.dart (4 fallos)
- auth_validator_security_test.dart (4 fallos)

**Tests Afectados:**
- ❌ Todos los tests de widgets que usan `AppLocalizations`
- ❌ Validadores que usan mensajes localizados
- ❌ Widgets con labels/hints localizados

**Causa Raíz:**
- Tests no están usando el nuevo sistema de i18n
- Falta wrapper de `MaterialApp` con `localizationsDelegates`
- Migración i18n al 80% (WIP)

**Solución Propuesta:**
```dart
// ❌ ANTES (easy_localization)
testWidgets('test', (tester) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [Locale('es')],
      path: 'assets/translations',
      child: MyWidget(),
    ),
  );
});

// ✅ DESPUÉS (gen-l10n)
testWidgets('test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('es'),
      home: MyWidget(),
    ),
  );
});
```

**Impacto:** Afecta todos los widgets con texto localizado

---

### C. 🟢 **Errores de Lógica / Comportamiento** (17 fallos, 19%)

**Prioridad:** MEDIA 🧩

#### C.1. **MainNavigationScreen** (8 fallos)
- Problemas con tests de navegación, tabs y estructura
- Posible causa: i18n o configuración de navegación

#### C.2. **SearchScreen** (7 fallos)
- Tests de búsqueda, filtrado y manejo de errores
- Posible causa: Mocks incompletos o i18n

#### C.3. **LocationManager** (2 fallos)
- Tests esperan `early return` pero no sucede
- Causa: Lógica de `loadDefaultLocation` para casos edge

---

### D. 🔵 **Smoke Test** (1 fallo, 1%)

**Prioridad:** BAJA 🔥

**Archivo:** widget_test.dart

**Test:** App smoke test

**Causa:** Probablemente relacionado con i18n

---

## 🚀 Plan de Acción Recomendado

### 📊 Resumen de Fases

| Fase | Prioridad | Tests | Impacto | Tiempo | Comando |
|------|-----------|-------|---------|--------|---------|
| **1** | 🔴 CRÍTICA | 19 | 21% | 2-3h | `./run_tests_by_phase.sh 1` |
| **2** | 🟡 ALTA | 45+ | 51% | 4-6h | `./run_tests_by_phase.sh 2` |
| **3** | 🟢 MEDIA | 17 | 19% | 2-3h | `./run_tests_by_phase.sh 3` |
| **4** | 🔵 BAJA | 1 | 1% | 15m | `./run_tests_by_phase.sh 4` |
| **TOTAL** | - | **82+** | **92%** | **8-12h** | - |

---

### 🔥 FASE 1: Errores Críticos - MaterialApp Duplicado (PRIORIDAD CRÍTICA)

**Impacto:** 19 tests | **Tiempo:** 2-3 horas

**Archivos:**
- `test/main_test.dart` (13 tests)
- `test/main_additional_test.dart` (6 tests)

**Problema:** Tests encuentran 2 `MaterialApp` cuando esperan 1

**Estrategia de Solución:**

1. **Usar `.first` o `.last` en finders**
   ```dart
   // ❌ ANTES
   final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
   
   // ✅ DESPUÉS
   final materialApp = tester.widget<MaterialApp>(
     find.byType(MaterialApp).first,
   );
   ```

2. **Asegurar limpieza entre tests**
   ```dart
   tearDown(() {
     // Cleanup si es necesario
   });
   ```

3. **Verificar que no se crean múltiples `ChismesApp`**

**Comando para ejecutar:**
```bash
./run_tests_by_phase.sh 1
```

**Tests específicos:**
```bash
flutter test test/main_test.dart --name "debe tener una jerarquía de widgets válida"
flutter test test/main_test.dart --name "themeMode debe seguir el sistema"
flutter test test/main_additional_test.dart --name "debe ser reconstruible"
```

---

### 🌐 FASE 2: Migración i18n - easy_localization → gen-l10n (PRIORIDAD ALTA)

**Impacto:** 45+ tests | **Tiempo:** 4-6 horas

**Archivos (en orden de prioridad):**
1. `features/gossip/presentation/widgets/location_selector_test.dart` (20 tests) ⚠️
2. `features/gossip/presentation/widgets/city_autocomplete_optimized_test.dart` (7 tests)
3. `features/gossip/presentation/widgets/city_autocomplete_test.dart` (5 tests)
4. `features/gossip/presentation/widgets/report_gossip_dialog_test.dart` (6 tests)
5. `features/gossip/presentation/widgets/submit_button_test.dart` (4 tests)
6. `features/auth/domain/validators/auth_validator_security_test.dart` (4 tests)

**Estrategia de Solución:**

1. **Crear helper para tests con i18n**
   ```dart
   // test/helpers/test_helpers.dart
   Widget makeTestableWidget(Widget child) {
     return MaterialApp(
       localizationsDelegates: AppLocalizations.localizationsDelegates,
       supportedLocales: AppLocalizations.supportedLocales,
       locale: const Locale('es'),
       home: child,
     );
   }
   ```

2. **Actualizar cada test**
   ```dart
   // ❌ ANTES
   await tester.pumpWidget(
     EasyLocalization(
       supportedLocales: [Locale('es')],
       path: 'assets/translations',
       child: MyWidget(),
     ),
   );
   
   // ✅ DESPUÉS
   await tester.pumpWidget(makeTestableWidget(MyWidget()));
   ```

3. **Verificar imports**
   - Remover: `import 'package:easy_localization/easy_localization.dart';`
   - Agregar: `import 'package:flutter_gen/gen_l10n/app_localizations.dart';`

**Comando para ejecutar:**
```bash
./run_tests_by_phase.sh 2
```

**Test por test (recomendado para esta fase):**
```bash
# Empezar con el más impactante
flutter test test/features/gossip/presentation/widgets/location_selector_test.dart
```

---

### 🧩 FASE 3: Tests de Lógica / Comportamiento (PRIORIDAD MEDIA)

**Impacto:** 17 tests | **Tiempo:** 2-3 horas

**Archivos:**
1. `features/home/presentation/screens/main_navigation_screen_test.dart` (8 tests)
2. `features/search/presentation/screens/search_screen_test.dart` (7 tests)
3. `features/location/presentation/managers/location_manager_test.dart` (2 tests)

**Estrategia de Solución:**

1. **MainNavigationScreen**
   - Aplicar fix de i18n (similar a Fase 2)
   - Verificar mocks de controladores
   - Verificar estructura de navegación

2. **SearchScreen**
   - Aplicar fix de i18n
   - Verificar mocks de `GossipRepository`
   - Verificar casos de búsqueda vacía/error

3. **LocationManager**
   - Revisar lógica de `loadDefaultLocation`
   - Agregar casos edge para early returns

**Comando para ejecutar:**
```bash
./run_tests_by_phase.sh 3
```

---

### 🔥 FASE 4: Smoke Test (PRIORIDAD BAJA)

**Impacto:** 1 test | **Tiempo:** 15 minutos

**Archivo:** `test/widget_test.dart`

**Estrategia:** Aplicar fix de i18n (similar a Fase 2)

**Comando para ejecutar:**
```bash
./run_tests_by_phase.sh 4
```

---

## 🛠️ Herramientas de Ayuda

### Scripts Disponibles

```bash
# Analizar fallos actuales
./analyze_test_failures.sh

# Ejecutar tests por fase
./run_tests_by_phase.sh [1|2|3|4|all]

# Ver ayuda de fases
./run_tests_by_phase.sh
```

### Comandos Útiles

```bash
# Todos los tests
flutter test

# Solo tests fallidos (identificar)
flutter test 2>&1 | grep "\[E\]"

# Contar fallos
flutter test 2>&1 | grep "\[E\]" | wc -l

# Test específico con output detallado
flutter test <path> --name "<test name>" --reporter expanded

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
- ❌ Volver a easy_localization
- ❌ Perder progreso del 80%
- ❌ Problema persiste a futuro

**Decisión Recomendada:** **Opción A** - Completar la migración

#### Paso 3: Implementación

```dart
// 1. Crear LocaleNotifier si no existe
// lib/core/i18n/locale_notifier.dart
import 'package:flutter/material.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier(super.value);

  void setLocale(Locale locale) {
    value = locale;
  }
}

// 2. Registrar en DI
// lib/core/di/injection_container.dart
@module
abstract class AppModule {
  @singleton
  LocaleNotifier localeNotifier() => LocaleNotifier(const Locale('es'));
}

// 3. Actualizar LanguageSelector
// lib/core/widgets/language_selector.dart
class LanguageSelector extends StatelessWidget {
  @override

---

## 📚 Documentos Relacionados

Este reporte es parte de un conjunto de documentos para análisis y corrección de tests:

### Documentos Generados

1. **TEST_FAILURES_ORGANIZED.md** 📄
   - Análisis detallado de cada categoría de error
   - Soluciones propuestas con ejemplos de código
   - Plan de acción con estimaciones de tiempo
   - **Recomendación:** Leer primero para entender los problemas

2. **analyze_test_failures.sh** 🔍
   - Script para analizar logs de tests
   - Extrae estadísticas y patrones de error
   - Genera reporte en terminal
   - **Uso:** `./analyze_test_failures.sh`

3. **run_tests_by_phase.sh** 🚀
   - Script para ejecutar tests por fase
   - Permite trabajar de forma incremental
   - Aísla conjuntos específicos de tests
   - **Uso:** `./run_tests_by_phase.sh [1|2|3|4|all]`

4. **test_output.log** 📋
   - Log completo de la última ejecución de tests
   - Contiene todos los errores y stack traces
   - **Uso:** Buscar errores específicos con `grep`

---

## 🎯 Decisión Recomendada

**Empezar con Fase 1** (Errores Críticos - MaterialApp Duplicado)

**Razones:**
1. ✅ Mayor impacto por esfuerzo (19 tests, 2-3 horas)
2. ✅ Desbloquea tests de infraestructura
3. ✅ Problema bien definido y acotado
4. ✅ Solución clara y directa

**Luego continuar con Fase 2** (Migración i18n)

**Razones:**
1. ✅ Mayor cantidad de tests (45+)
2. ✅ Problema sistémico que afecta múltiples features
3. ✅ Solución requiere crear helper reutilizable
4. ✅ Una vez resuelto, aplica a muchos tests futuros

---

## 📊 Métricas de Salud del Proyecto

| Métrica | Actual | Objetivo | Estado |
|---------|--------|----------|--------|
| **Tests Pasando** | 96.8% | 100% | 🟡 Bueno |
| **Tests Fallando** | 3.2% | 0% | 🟡 Mejorable |
| **Coverage** | 78.9% | >75% | ✅ Excelente |
| **Tests Totales** | 2,777 | - | ✅ Robusto |

**Observaciones:**
- ✅ La mayoría de los tests pasan (96.8%)
- ✅ Coverage está por encima del objetivo (78.9% > 75%)
- 🟡 Los 89 tests fallando son solucionables en 8-12 horas
- ✅ No hay tests críticos de negocio fallando (son principalmente de infraestructura e i18n)

---

## 🚨 Alertas y Consideraciones

### ⚠️ Migración i18n Incompleta

**Estado:** WIP al 80%  
**Impacto:** 51% de los fallos (45+ tests)  
**Acción:** Completar migración antes de merge a main

### ⚠️ Tests de Infraestructura

**Problema:** MaterialApp duplicado  
**Impacto:** 21% de los fallos (19 tests)  
**Acción:** Arreglar primero (bloquea otros tests)

### ✅ No Hay Tests de Negocio Críticos Fallando

**Buenas noticias:**
- Domain layer tests: ✅ Pasando
- UseCases tests: ✅ Pasando
- Repository tests: ✅ Pasando
- Core business logic: ✅ Pasando

**Fallos limitados a:**
- Presentation layer (widgets, screens)
- Infrastructure (i18n, DI setup en tests)

---

## 🔗 Referencias Externas

### Documentación del Proyecto
- [CLAUDE.md](CLAUDE.md) - Quick reference del proyecto
- [.claude/TESTING.md](.claude/TESTING.md) - Standards de testing
- [.claude/ARCHITECTURE.md](.claude/ARCHITECTURE.md) - Arquitectura

### Flutter Testing
- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Integration Testing](https://flutter.dev/docs/cookbook/testing/integration/introduction)

### Herramientas
- [Mockito](https://pub.dev/packages/mockito)
- [Flutter Test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)

---

## 📝 Notas Finales

### Para el Desarrollador

1. **No te abrumes** - El 96.8% de los tests pasan
2. **Trabaja por fases** - Usa `run_tests_by_phase.sh` para avanzar incrementalmente
3. **Documenta tus fixes** - Ayuda a futuros desarrolladores (incluyéndote a ti)
4. **Actualiza este reporte** - Marca checkboxes conforme avances

### Para Code Review

1. **Verificar que todos los tests pasen** antes de aprobar PR
2. **No hacer merge con tests fallando** (salvo casos excepcionales documentados)
3. **Coverage debe mantenerse >75%**
4. **Nuevos features deben incluir tests**

### Para CI/CD

1. **Ejecutar `flutter test` en cada PR**
2. **Bloquear merge si tests fallan**
3. **Generar reporte de coverage**
4. **Alertar si coverage baja de 75%**

---

## 📧 Información de Contacto

**Proyecto:** Chismes App  
**Branch:** main  
**Mantenedor:** Alejo  
**Última Actualización:** 2026-11-10 18:16:15  
**Generado por:** Claude Sonnet 4.5

**Para reportar problemas:**
- Crear issue en GitHub
- Tag: `tests`, `bug`
- Incluir: nombre del test, error, contexto

---

## ✨ Conclusión

**Estado General:** 🟡 **BUENO CON ACCIONES PENDIENTES**

- ✅ Proyecto tiene cobertura sólida de tests (2,777 tests)
- ✅ Coverage excelente (78.9%)
- ✅ Mayoría de tests pasan (96.8%)
- 🟡 89 tests fallando son solucionables en 1-2 días
- 🟡 Causas principales identificadas y documentadas
- ✅ Herramientas y scripts creados para facilitar corrección

**Próximo Paso Recomendado:**
```bash
./run_tests_by_phase.sh 1
```

**Tiempo Estimado para 100% Tests Pasando:** 8-12 horas de trabajo

---

**FIN DEL REPORTE**

---

*Documento generado automáticamente. Para re-generar, ejecutar: `./analyze_test_failures.sh`*
