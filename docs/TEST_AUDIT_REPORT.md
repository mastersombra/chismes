# Test Audit Report - Proyecto Chismes

**Fecha:** 2026-11-17  
**Coverage Actual:** 78.9% (1,865 / 2,363 líneas)  
**Tests Totales:** 1,897 tests  
**Archivos de Test:** 216 archivos

---

## 📊 RESUMEN EJECUTIVO

### Estado Actual

| Métrica | Valor | Estado |
|---------|-------|--------|
| **Coverage Total** | 78.9% | ✅ Por encima del objetivo (>75%) |
| **Tests Totales** | 1,897 | ✅ Buena cobertura |
| **Archivos con 0% coverage** | 17 archivos | ⚠️ Requieren atención |
| **Archivos sin tests** | 49 archivos | ⚠️ Muchos son interfaces/abstracts |
| **Tests pasando** | 1,846 / 1,897 | ⚠️ 51 tests fallando |
| **Archivos .mocks.dart** | 62 | ✅ Uso adecuado de mocks |

### Evaluación General

**🟢 Fortalezas:**
- Coverage general por encima del objetivo (78.9% > 75%)
- Estructura de tests bien organizada siguiendo Clean Architecture
- Uso correcto de mocks (mockito + build_runner)
- Todos los tests tienen asserts (no hay tests vacíos)
- Features principales bien cubiertos (gossip, location, auth)

**🟡 Áreas de Mejora:**
- 51 tests fallando (2.7% failure rate)
- Feature **home** tiene 0 tests en domain layer (8 archivos sin tests)
- Feature **profile** tiene 5 usecases sin tests
- Algunos archivos con over-testing (>100% coverage)
- Tests de integración mezclados con unit tests

**🔴 Gaps Críticos:**
- `home/domain/usecases/` → 0% coverage (4 archivos)
- `profile/domain/usecases/` → 0% coverage (4 archivos)
- Controllers con 0% coverage (add_gossip_controller, following_tab_controller, profile_controller)

---

## 🎯 PRIORIZACIÓN

### Criterios de Priorización

1. **Impacto:** Funcionalidad core vs. auxiliar
2. **Complejidad:** Lógica de negocio vs. DTOs simples
3. **Riesgo:** Archivos con lógica crítica sin tests
4. **Dependencies:** Tests bloqueados por otros

### Matriz de Prioridad

| Prioridad | Feature | Capa | Archivos | Impacto |
|-----------|---------|------|----------|---------|
| 🔴 P0 | home | domain/usecases | 4 archivos | Alto - Feature principal |
| 🔴 P0 | gossip | presentation/controllers | add_gossip_controller | Alto - Funcionalidad core |
| 🟡 P1 | profile | domain/usecases | 4 archivos | Medio - Feature secundaria |
| 🟡 P1 | home | presentation/controllers | following_tab_controller | Medio - Feature principal |
| 🟢 P2 | auth | presentation/widgets | auth_gate | Bajo - Widget simple |
| 🟢 P2 | gossip | domain/services | content_moderator | Bajo - MVP usa mvp_content_moderator |
| 🟢 P3 | Interfaces/Abstracts | domain/repositories | 5 archivos | Muy bajo - Son interfaces |

---

## 📋 ANÁLISIS POR FEATURE

### 1. Feature: AUTH ✅ (Bien Cubierto)

**Coverage:** ~85% (estimado por análisis de archivos)  
**Estado:** ✅ Mayormente completo

#### Tests Existentes
- ✅ Data: datasources (1/2), repositories (1/1), models (1/1)
- ✅ Domain: validators (2/2), usecases (11/11), entities (1/1)
- ✅ Presentation: screens (7/7), controllers (5/6), widgets (7/8), states (3/3)

#### Gaps Identificados

| Archivo | Capa | Prioridad | Razón |
|---------|------|-----------|-------|
| `supabase_auth_datasource.dart` | data | 🟢 P3 | Interface (implementación ya testeada) |
| `auth_repository.dart` | domain | 🟢 P3 | Interface (implementación ya testeada) |
| `reset_password_controller.dart` | presentation | 🟡 P1 | Controller con lógica de negocio |
| `auth_gate.dart` | presentation | 🟢 P2 | Widget simple de routing |

#### Recomendaciones
- ✅ Feature en buen estado
- Completar `reset_password_controller` (P1)
- Considerar `auth_gate` si tiene lógica compleja (actualmente P2)

---

### 2. Feature: GOSSIP ⚠️ (Gaps en Controllers)

**Coverage:** ~72% (calculado por lcov)  
**Estado:** ⚠️ Gaps críticos en presentation

#### Tests Existentes
- ✅ Data: datasources (2/4), repositories (1/1), models (1/1)
- ⚠️ Domain: entities (3/5), validators (2/2), usecases (6/7), services (1/2)
- 🔴 Presentation: screens (2/2), **controllers (0/1)**, widgets (14/15), states (1/1)

#### Gaps Identificados

| Archivo | Capa | Prioridad | Razón | Coverage |
|---------|------|-----------|-------|----------|
| **`add_gossip_controller.dart`** | presentation | 🔴 **P0** | **124 líneas sin tests - CORE FEATURE** | **0%** |
| `gossip_local_data_source.dart` | data | 🟢 P3 | Interface (implementación testeada) | - |
| `gossip_remote_data_source.dart` | data | 🟢 P3 | Interface (implementación testeada) | - |
| `create_gossip_input.dart` | domain | 🟢 P2 | DTO simple (pero tiene 1225% coverage?!) | 1225% |
| `media_reference.dart` | domain | 🟢 P3 | DTO simple, no usado en MVP | - |
| `gossip_repository.dart` | domain | 🟢 P3 | Interface | - |
| `content_moderator.dart` | domain | 🟢 P2 | Interface (MVP usa mvp_content_moderator) | - |
| `search_gossips.dart` | domain | 🟡 P1 | UseCase de búsqueda | - |
| `media_attachment_section.dart` | presentation | 🟡 P1 | Widget complejo de media | - |

#### Problemas Detectados

**🚨 CRÍTICO:**
- `add_gossip_controller_test.dart` existe pero tiene **125 expects**
- El archivo `.dart` tiene **0% coverage**
- Posible problema: test no ejecuta el código real del controller

**⚠️ Over-testing:**
- `create_gossip_input.dart` tiene 1225% coverage (múltiples tests ejecutan el mismo código)
- `gossip_model_test.dart` tiene 118 expects (puede ser normal para DTOs grandes)

#### Recomendaciones
1. 🔴 **URGENTE:** Investigar por qué `add_gossip_controller` tiene 0% coverage si existe test
2. Completar `search_gossips` usecase (P1)
3. Agregar tests para `media_attachment_section` (P1)
4. Revisar over-testing en `create_gossip_input` (optimización)

---

### 3. Feature: HOME 🔴 (Domain Layer Sin Tests)

**Coverage:** ~15% en domain (estimado)  
**Estado:** 🔴 **CRÍTICO - Domain layer completo sin tests**

#### Tests Existentes
- ✅ Data: datasources (2/2), repositories (1/1), models (2/2)
- 🔴 **Domain: usecases (0/4), entities (0/3), repositories (0/1)** ← **CRÍTICO**
- ⚠️ Presentation: screens (3/3), controllers (1/2), widgets (5/5), states (2/2)

#### Gaps Identificados

| Archivo | Capa | Prioridad | Razón | Coverage |
|---------|------|-----------|-------|----------|
| **`get_popular_feed.dart`** | domain | 🔴 **P0** | **UseCase core de feed principal** | **0%** |
| **`get_following_feed.dart`** | domain | 🔴 **P0** | **UseCase core de feed following** | **0%** |
| **`get_recommended_feed.dart`** | domain | 🔴 **P0** | **UseCase core de feed recomendado** | **0%** |
| **`check_new_gossips.dart`** | domain | 🔴 **P0** | **UseCase de polling** | **0%** (pero 1500%?!) |
| `feed_cursor.dart` | domain | 🟡 P1 | Entity para paginación | - |
| `feed_gossip.dart` | domain | 🟡 P1 | Entity de feed | - |
| `paginated_gossips.dart` | domain | 🟡 P1 | Entity de paginación | - |
| `home_repository.dart` | domain | 🟢 P3 | Interface | - |
| **`following_tab_controller.dart`** | presentation | 🔴 **P0** | **99 líneas sin tests** | **0%** |

#### Problemas Detectados

**🚨 CRÍTICOS:**
- **Toda la capa domain sin tests** (0/8 archivos)
- `following_tab_controller` tiene 0% coverage (99 líneas)
- `check_new_gossips.dart` reporta 1500% coverage pero el archivo tiene 0% (inconsistencia)

#### Recomendaciones
1. 🔴 **URGENTE:** Agregar tests para los 4 usecases de domain
2. 🔴 **URGENTE:** Testear `following_tab_controller` (99 líneas de lógica)
3. Agregar tests para entities (feed_cursor, feed_gossip, paginated_gossips)
4. Investigar inconsistencia de coverage en `check_new_gossips`

---

### 4. Feature: LOCATION ✅ (Bien Cubierto)

**Coverage:** ~85% (estimado)  
**Estado:** ✅ Excelente cobertura

#### Tests Existentes
- ✅ Data: datasources (2/2), repositories (2/3)
- ✅ Domain: entities (3/3), usecases (4/4)
- ✅ Presentation: managers (1/1), states (1/2)

#### Gaps Identificados

| Archivo | Capa | Prioridad | Razón |
|---------|------|-----------|-------|
| `location_repository.dart` | domain | 🟢 P3 | Interface |
| `location_error_key.dart` | presentation | 🟢 P2 | Enums simples (ya tiene 250% coverage) |

#### Problemas Detectados

**⚠️ Over-testing:**
- `mock_location_repository_test.dart` tiene **167 expects** (mayor del proyecto)
- `location_manager_test.dart` tiene 112 expects
- Posible duplicación de casos de prueba

#### Recomendaciones
- ✅ Feature en excelente estado
- Revisar tests para reducir redundancia (optimización, no urgente)

---

### 5. Feature: PROFILE ⚠️ (Domain Usecases Sin Tests)

**Coverage:** ~45% (estimado por gaps)  
**Estado:** ⚠️ Gaps en domain y presentation

#### Tests Existentes
- ✅ Data: datasources (1/1), repositories (1/1), models (2/2)
- 🔴 Domain: usecases (0/5), entities (2/2)
- ⚠️ Presentation: screens (1/1), controllers (0/1), widgets (2/3)

#### Gaps Identificados

| Archivo | Capa | Prioridad | Razón | Coverage |
|---------|------|-----------|-------|----------|
| **`profile_controller.dart`** | presentation | 🟡 **P1** | **83 líneas sin tests** | **0%** |
| **`get_user_stats.dart`** | domain | 🟡 P1 | UseCase de stats | **0%** |
| **`update_settings.dart`** | domain | 🟡 P1 | UseCase de settings | **0%** |
| **`sign_out.dart`** | domain | 🟡 P1 | UseCase de logout | **0%** |
| `get_settings.dart` | domain | 🟡 P1 | UseCase de settings (tiene 1166% coverage?!) | 1166% |
| `profile_repository.dart` | domain | 🟢 P3 | Interface | - |
| `settings_section.dart` | presentation | 🟢 P2 | Widget simple | - |

#### Problemas Detectados

**🚨 CRÍTICO:**
- `profile_controller` tiene 0% coverage (83 líneas de lógica)
- 4 de 5 usecases sin tests (80% de domain sin cobertura)

**⚠️ Inconsistencia:**
- `get_settings.dart` reporta 1166% coverage pero está en la lista de 0% coverage

#### Recomendaciones
1. 🟡 **ALTA:** Testear `profile_controller` (83 líneas)
2. 🟡 **ALTA:** Agregar tests para usecases (`get_user_stats`, `update_settings`, `sign_out`)
3. Investigar inconsistencia en `get_settings`
4. Agregar test para `settings_section` widget (P2)

---

### 6. Feature: SEARCH ✅ (Mínima pero Completa)

**Coverage:** 100% (1 archivo, 1 test)  
**Estado:** ✅ Completo para MVP

#### Tests Existentes
- ✅ Presentation: screens (1/1)

#### Observaciones
- Feature minimal (solo búsqueda básica)
- No tiene data ni domain layer (usa otros features)
- Un solo archivo, completamente testeado

#### Recomendaciones
- ✅ Feature completa para MVP
- No requiere acción inmediata

---

## 🧩 ANÁLISIS DE CORE

### Core Modules

| Módulo | Archivos | Tests | Coverage | Estado |
|--------|----------|-------|----------|--------|
| **audit** | 2 | 1 | 1416% | ✅ Over-tested |
| **auth** | 3 | 1 | 342% | ✅ Bueno |
| **config** | 1 | 1 | - | ✅ Completo |
| **di** | 2 | 1 | 0% | ⚠️ injection_container sin coverage |
| **error** | 5 | 4 | Mixto | ✅ Mayormente completo |
| **id** | 2 | 1 | 0% | ⚠️ timestamp_id_generator sin coverage |
| **l10n** | 2 | 0 | 0% | 🟢 P3 (archivos generados) |
| **logging** | 6 | 5 | Alto | ✅ Excelente |
| **media** | 2 | 2 | - | ✅ Completo |
| **result** | 1 | 1 | 0% (bug) | ⚠️ Inconsistencia |
| **services** | 5 | 5 | Mixto | ✅ Completo |
| **theme** | 4 | 1 | - | 🟢 P3 (mayormente constantes) |
| **validation** | 1 | 1 | 0% | ⚠️ FormValidators sin coverage real |
| **user** | 1 | 1 | 338% | ✅ Bueno |

### Gaps Críticos en Core

| Archivo | Prioridad | Razón | Coverage |
|---------|-----------|-------|----------|
| `form_validators.dart` | 🟡 P1 | Usado en toda la UI | 0% |
| `timestamp_id_generator.dart` | 🟢 P2 | Generador de IDs | 0% |
| `injection_container.dart` | 🟢 P3 | DI setup (difícil de testear) | 0% |
| `result.dart` | 🟢 P3 | Inconsistencia de coverage | 0% (bug) |

---

## 🔍 PROBLEMAS DE CALIDAD DETECTADOS

### 1. Tests Fallando (51 tests - 2.7%)

**Ubicación:** No especificada en el análisis  
**Impacto:** Alto - Tests rotos degradan confianza en la suite

**Acción Requerida:**
```bash
# Ejecutar y ver qué tests fallan
flutter test --reporter expanded | grep "FAILED"

# Analizar por feature
flutter test test/features/auth --reporter expanded
flutter test test/features/gossip --reporter expanded
flutter test test/features/home --reporter expanded
```

**Prioridad:** 🔴 P0 - Arreglar antes de agregar nuevos tests

---

### 2. Inconsistencias de Coverage

**Archivos reportando >100% coverage pero con 0% real:**

| Archivo | Coverage Reportado | Coverage Real | Problema |
|---------|-------------------|---------------|----------|
| `get_current_user.dart` | 4000% | 0% | Test ejecuta mock, no implementación |
| `profile_service.dart` | 2000% | 0% | Idem |
| `check_new_gossips.dart` | 1500% | 0% | Idem |
| `get_settings.dart` | 1166% | 0% | Idem |
| `result.dart` | 0% | ??? | Inconsistencia de lcov |

**Causa Probable:**
- Tests ejecutan mocks en lugar de implementaciones reales
- lcov cuenta ejecuciones en archivos de test, no de producción

**Acción Requerida:**
1. Revisar configuración de coverage
2. Verificar que tests ejecuten código de producción
3. Considerar separar unit tests de integration tests

**Prioridad:** 🟡 P1 - Afecta métricas de coverage

---

### 3. Over-testing (Optimización)

**Tests con exceso de expects (>100):**

| Archivo | Expects | Es Normal? | Acción |
|---------|---------|------------|--------|
| `mock_location_repository_test.dart` | 167 | ⚠️ Posible redundancia | Revisar casos duplicados |
| `add_gossip_controller_test.dart` | 125 | ⚠️ Mucho para un controller | Revisar si prueba múltiples escenarios redundantes |
| `gossip_query_test.dart` | 125 | ⚠️ Mucho para una query | Revisar |
| `add_gossip_state_test.dart` | 123 | ⚠️ Mucho para un state | Revisar |
| `gossip_model_test.dart` | 118 | ✅ Normal para DTO grande | OK |
| `location_manager_test.dart` | 112 | ⚠️ Revisar | Posible redundancia |
| `profile_settings_test.dart` | 111 | ✅ Normal para entity complejo | OK |

**Recomendación:**
- No es crítico, pero reduce tiempo de ejecución de tests
- Revisar en refactoring futuro

**Prioridad:** 🟢 P3 - Optimización, no bug

---

### 4. Tests de Integración Mezclados

**Archivos que usan Supabase real en lugar de mocks:**

```
test/features/gossip/di/gossip_module_test.dart
test/features/home/data/datasources/home_remote_datasource_test.dart
test/features/auth/data/datasources/supabase_auth_datasource_impl_test.dart
test/features/location/data/datasources/supabase_location_remote_data_source_test.dart
test/features/gossip/data/datasources/supabase_gossip_remote_data_source_test.dart
```

**Problema:**
- Tests de datasources deberían usar mocks de SupabaseClient
- Actualmente son integration tests, no unit tests
- Más lentos y requieren conexión a Supabase

**Recomendación:**
- Está bien tener integration tests, pero deberían estar en `test/integration/`
- Agregar unit tests con mocks para los datasources
- Separar claramente unit vs integration tests

**Prioridad:** 🟡 P1 - Afecta velocidad y confiabilidad de tests

---

## 📅 PLAN DE SESIONES DE TRABAJO

### 🔴 SESIÓN 1: Tests Fallando (CRÍTICO)
**Tiempo Estimado:** 2-3 horas  
**Prioridad:** P0 - URGENTE

**Objetivos:**
- [ ] Ejecutar `flutter test` y documentar los 51 tests que fallan
- [ ] Categorizar por tipo de fallo (mock, async, assertions, etc.)
- [ ] Arreglar tests fallando uno por uno
- [ ] Verificar que todos los tests pasen

**Archivos Potencialmente Afectados:**
- Tests recién agregados (email_field, forgot_password_dialog, etc.)
- Tests con dependencias temporales
- Tests con mocks rotos

**Checklist:**
```bash
# 1. Ver todos los fallos
flutter test --reporter expanded 2>&1 | tee test_failures.log

# 2. Arreglar por prioridad:
#    - Fallos en features core (gossip, home, auth)
#    - Fallos en features secundarias (profile, search)
#    - Fallos en helpers/utils

# 3. Verificar solución
flutter test
```

**Criterio de Éxito:** 100% de tests pasando (1,897/1,897)

---

### 🔴 SESIÓN 2: Home Domain Layer (CRÍTICO)
**Tiempo Estimado:** 3-4 horas  
**Prioridad:** P0

**Objetivo:** Completar tests de domain layer de home (actualmente 0/8)

**Tareas:**

#### 2.1. Usecases (P0)
- [ ] `test/features/home/domain/usecases/get_popular_feed_test.dart`
  - Crear casos: success, failure, pagination
  - Mockear HomeRepository
  - Verificar que retorna Result correcto
  
- [ ] `test/features/home/domain/usecases/get_following_feed_test.dart`
  - Similar a get_popular_feed
  
- [ ] `test/features/home/domain/usecases/get_recommended_feed_test.dart`
  - Similar a get_popular_feed
  
- [ ] `test/features/home/domain/usecases/check_new_gossips_test.dart`
  - Casos: hay nuevos, no hay nuevos, error
  - Verificar lógica de polling

#### 2.2. Entities (P1)
- [ ] `test/features/home/domain/entities/feed_cursor_test.dart`
  - Validar serialización/deserialización
  - Validar copyWith
  
- [ ] `test/features/home/domain/entities/feed_gossip_test.dart`
  - Similar a gossip_test.dart pero para feed
  
- [ ] `test/features/home/domain/entities/paginated_gossips_test.dart`
  - Validar paginación
  - Validar hasMore logic

**Archivos Necesarios:**
```
test/features/home/domain/usecases/
  - get_popular_feed_test.dart          (NUEVO)
  - get_following_feed_test.dart        (NUEVO)
  - get_recommended_feed_test.dart      (NUEVO)
  - check_new_gossips_test.dart         (NUEVO)

test/features/home/domain/entities/
  - feed_cursor_test.dart               (NUEVO)
  - feed_gossip_test.dart               (NUEVO)
  - paginated_gossips_test.dart         (NUEVO)
```

**Checklist:**
```bash
# 1. Crear estructura
mkdir -p test/features/home/domain/usecases
mkdir -p test/features/home/domain/entities

# 2. Copiar template de otro usecase como base
cp test/features/gossip/domain/usecases/create_gossip_test.dart \
   test/features/home/domain/usecases/get_popular_feed_test.dart

# 3. Implementar cada test siguiendo AAA pattern

# 4. Ejecutar tests
flutter test test/features/home/domain/
```

**Criterio de Éxito:** 
- 7 nuevos archivos de test
- Coverage de home/domain pasa de 0% a >80%
- Todos los tests pasan

---

### 🔴 SESIÓN 3: Controllers Sin Coverage (CRÍTICO)
**Tiempo Estimado:** 4-5 horas  
**Prioridad:** P0

**Objetivo:** Testear controllers con 0% coverage

#### 3.1. Add Gossip Controller
**Archivo:** `add_gossip_controller.dart` (124 líneas)  
**Problema:** Test existe pero no ejecuta código real (0% coverage)

**Investigación:**
- [ ] Revisar `add_gossip_controller_test.dart` actual
- [ ] Identificar por qué no se ejecuta código real
- [ ] Verificar que los mocks están bien configurados
- [ ] Asegurar que el controller se instancia y ejecuta

**Tests a Agregar/Arreglar:**
- [ ] `initState` setup correcto
- [ ] `submitGossip` success path
- [ ] `submitGossip` validation failures
- [ ] `submitGossip` repository failures
- [ ] `pickImage` functionality
- [ ] `clearImage` functionality
- [ ] `setLocation` functionality
- [ ] State transitions (loading, success, error)

#### 3.2. Following Tab Controller
**Archivo:** `following_tab_controller.dart` (99 líneas)  
**Test:** No existe

**Tests a Crear:**
- [ ] `test/features/home/presentation/controllers/following_tab_controller_test.dart`
  - [ ] Initial state
  - [ ] `loadInitialFeed` success
  - [ ] `loadInitialFeed` failure
  - [ ] `loadMoreGossips` pagination
  - [ ] `refreshFeed` functionality
  - [ ] State management (loading, success, error)

#### 3.3. Profile Controller
**Archivo:** `profile_controller.dart` (83 líneas)  
**Test:** No existe

**Tests a Crear:**
- [ ] `test/features/profile/presentation/controllers/profile_controller_test.dart`
  - [ ] Initial load
  - [ ] `loadProfile` success
  - [ ] `loadProfile` failure
  - [ ] `loadStats` success
  - [ ] `updateSettings` functionality
  - [ ] `signOut` functionality
  - [ ] State management

**Checklist:**
```bash
# 1. Investigar add_gossip_controller
flutter test test/features/gossip/presentation/controllers/add_gossip_controller_test.dart --coverage
genhtml coverage/lcov.info -o coverage/html
# Revisar si add_gossip_controller.dart aparece en el reporte

# 2. Crear tests faltantes
touch test/features/home/presentation/controllers/following_tab_controller_test.dart
touch test/features/profile/presentation/controllers/profile_controller_test.dart

# 3. Implementar siguiendo patrón de otros controllers

# 4. Verificar coverage
flutter test --coverage
```

**Criterio de Éxito:**
- `add_gossip_controller` pasa de 0% a >80% coverage
- `following_tab_controller` test creado con >80% coverage
- `profile_controller` test creado con >80% coverage

---

### 🟡 SESIÓN 4: Profile Domain Usecases
**Tiempo Estimado:** 2-3 horas  
**Prioridad:** P1

**Objetivo:** Completar tests de usecases de profile

**Tests a Crear:**

- [ ] `test/features/profile/domain/usecases/get_user_stats_test.dart`
  - [ ] Success case
  - [ ] Repository failure
  - [ ] Verificar llamada a repository

- [ ] `test/features/profile/domain/usecases/update_settings_test.dart`
  - [ ] Success case
  - [ ] Validation failure
  - [ ] Repository failure

- [ ] `test/features/profile/domain/usecases/sign_out_test.dart`
  - [ ] Success case
  - [ ] Repository failure

**Notas:**
- `get_settings_test.dart` reporta 1166% coverage pero está en lista de 0% → Investigar
- Son usecases simples, no deberían tomar mucho tiempo

**Checklist:**
```bash
# 1. Crear archivos
touch test/features/profile/domain/usecases/get_user_stats_test.dart
touch test/features/profile/domain/usecases/update_settings_test.dart
touch test/features/profile/domain/usecases/sign_out_test.dart

# 2. Copiar template de otro usecase
cp test/features/auth/domain/usecases/sign_out_test.dart \
   test/features/profile/domain/usecases/sign_out_test.dart
# Adaptar

# 3. Ejecutar
flutter test test/features/profile/domain/usecases/
```

**Criterio de Éxito:**
- 3 nuevos tests
- Profile domain coverage >80%

---

### 🟡 SESIÓN 5: Gossip Usecases y Widgets
**Tiempo Estimado:** 2-3 horas  
**Prioridad:** P1

**Objetivo:** Completar gaps en gossip feature

**Tests a Crear:**

#### 5.1. Domain
- [ ] `test/features/gossip/domain/usecases/search_gossips_test.dart`
  - [ ] Search with query
  - [ ] Search with filters
  - [ ] Empty results
  - [ ] Repository failure

#### 5.2. Presentation
- [ ] `test/features/gossip/presentation/widgets/media_attachment_section_test.dart`
  - [ ] Render with image
  - [ ] Render without image
  - [ ] Pick image interaction
  - [ ] Remove image interaction

**Checklist:**
```bash
# 1. Crear tests
touch test/features/gossip/domain/usecases/search_gossips_test.dart
touch test/features/gossip/presentation/widgets/media_attachment_section_test.dart

# 2. Implementar

# 3. Ejecutar
flutter test test/features/gossip/
```

**Criterio de Éxito:**
- 2 nuevos tests
- Gossip feature completo excepto interfaces

---

### 🟡 SESIÓN 6: Auth Remaining Gaps
**Tiempo Estimado:** 1-2 horas  
**Prioridad:** P1

**Objetivo:** Completar gaps menores en auth

**Tests a Crear:**

- [ ] `test/features/auth/presentation/controllers/reset_password_controller_test.dart`
  - Test YA EXISTE pero archivo tiene 252% coverage → investigar
  - Asegurar cobertura completa

- [ ] `test/features/auth/presentation/widgets/auth_gate_test.dart`
  - [ ] Redirect when authenticated
  - [ ] Show login when not authenticated
  - [ ] Loading state

**Checklist:**
```bash
# 1. Revisar reset_password_controller_test.dart existente
flutter test test/features/auth/presentation/controllers/reset_password_controller_test.dart

# 2. Crear auth_gate test
touch test/features/auth/presentation/widgets/auth_gate_test.dart

# 3. Ejecutar
flutter test test/features/auth/
```

**Criterio de Éxito:**
- Auth feature 100% completo (excepto interfaces)

---

### 🟢 SESIÓN 7: Core Modules
**Tiempo Estimado:** 2-3 horas  
**Prioridad:** P2

**Objetivo:** Completar tests de core con 0% coverage

**Tests a Agregar:**

#### 7.1. FormValidators (P1)
**Archivo:** `core/validation/form_validators.dart`  
**Problema:** 0% coverage real (test existe pero no ejecuta código)

**Investigación:**
- [ ] Revisar `form_validators_test.dart`
- [ ] Asegurar que ejecuta FormValidators real

**Tests a Verificar/Agregar:**
- [ ] `required` validator
- [ ] `email` validator
- [ ] `minLength` validator
- [ ] `maxLength` validator
- [ ] `password` validator
- [ ] Combinación de validators

#### 7.2. TimestampIdGenerator (P2)
**Archivo:** `core/id/timestamp_id_generator.dart`  
**Test:** Existe pero 0% coverage

- [ ] Revisar test existente
- [ ] Verificar generación de IDs únicos
- [ ] Verificar formato de timestamp

#### 7.3. InjectionContainer (P3)
**Archivo:** `core/di/injection_container.dart`  
**Problema:** Difícil de testear (setup de DI)

**Decisión:** 
- ¿Testear o marcar como excluido de coverage?
- Si testear: integration test en lugar de unit test

**Checklist:**
```bash
# 1. FormValidators
flutter test test/core/validation/form_validators_test.dart --coverage
# Revisar coverage específico del archivo

# 2. TimestampIdGenerator
flutter test test/core/id/timestamp_id_generator_test.dart --coverage

# 3. InjectionContainer
# Decidir approach
```

**Criterio de Éxito:**
- FormValidators >80% coverage
- TimestampIdGenerator >80% coverage
- Decision tomada sobre InjectionContainer

---

### 🟢 SESIÓN 8: Investigación de Inconsistencias
**Tiempo Estimado:** 2-3 horas  
**Prioridad:** P2

**Objetivo:** Resolver inconsistencias de coverage y over-testing

#### 8.1. Inconsistencias de Coverage

**Archivos a Investigar:**
- [ ] `get_current_user.dart` (4000% reportado, 0% real)
- [ ] `profile_service.dart` (2000% reportado, 0% real)
- [ ] `check_new_gossips.dart` (1500% reportado, 0% real)
- [ ] `get_settings.dart` (1166% reportado, 0% real)
- [ ] `result.dart` (0% reportado, pero debería tener coverage)

**Acciones:**
1. Revisar configuración de lcov
2. Verificar que tests ejecutan implementación real
3. Considerar separar mocks de tests
4. Actualizar métricas de coverage

#### 8.2. Over-testing

**Tests a Revisar:**
- [ ] `mock_location_repository_test.dart` (167 expects)
- [ ] `add_gossip_controller_test.dart` (125 expects)
- [ ] `location_manager_test.dart` (112 expects)

**Objetivo:** Identificar y eliminar redundancia

**Checklist:**
```bash
# 1. Analizar cada test
code test/features/location/data/repositories/mock_location_repository_test.dart

# 2. Identificar casos duplicados
# 3. Refactorizar si es necesario
# 4. Re-ejecutar para verificar que coverage se mantiene
```

**Criterio de Éxito:**
- Inconsistencias documentadas y resueltas
- Over-testing reducido sin pérdida de coverage

---

### 🟢 SESIÓN 9: Separar Unit vs Integration Tests
**Tiempo Estimado:** 3-4 horas  
**Prioridad:** P2

**Objetivo:** Separar correctamente unit tests de integration tests

**Archivos a Refactorizar:**

#### Integration Tests (mover a test/integration/)
- [ ] `gossip/di/gossip_module_test.dart`
- [ ] `home/data/datasources/home_remote_datasource_test.dart`
- [ ] `auth/data/datasources/supabase_auth_datasource_impl_test.dart`
- [ ] `location/data/datasources/supabase_location_remote_data_source_test.dart`
- [ ] `gossip/data/datasources/supabase_gossip_remote_data_source_test.dart`

#### Unit Tests (crear con mocks)
- [ ] Crear versiones unit test de datasources con mocks de SupabaseClient
- [ ] Mantener integration tests en `test/integration/`

**Estructura Propuesta:**
```
test/
├── unit/                          # NUEVO
│   ├── features/
│   │   ├── auth/
│   │   │   └── data/
│   │   │       └── datasources/
│   │   │           └── supabase_auth_datasource_impl_unit_test.dart
│   │   └── ...
│   └── ...
├── integration/                   # EXISTENTE
│   ├── database/
│   └── datasources/               # NUEVO
│       ├── auth_integration_test.dart
│       └── ...
└── features/                      # MANTENER (unit tests actuales)
    └── ...
```

**Checklist:**
```bash
# 1. Crear estructura
mkdir -p test/unit/features/auth/data/datasources
mkdir -p test/integration/datasources

# 2. Mover integration tests
mv test/features/auth/data/datasources/supabase_auth_datasource_impl_test.dart \
   test/integration/datasources/auth_integration_test.dart

# 3. Crear unit tests con mocks
# Copiar template y adaptar

# 4. Actualizar scripts de CI
# Ejecutar unit tests rápido, integration tests en CI completo
```

**Criterio de Éxito:**
- Clara separación entre unit e integration tests
- Unit tests rápidos (<10s)
- Integration tests en suite separada

---

### 🟢 SESIÓN 10: Limpieza y Optimización
**Tiempo Estimado:** 2-3 horas  
**Prioridad:** P3

**Objetivo:** Optimizar suite de tests

**Tareas:**

#### 10.1. Eliminar Tests Redundantes
- [ ] Revisar tests con >100 expects
- [ ] Identificar casos duplicados
- [ ] Consolidar donde sea apropiado

#### 10.2. Mejorar Helpers
- [ ] Revisar helpers en `test/helpers/`
- [ ] Consolidar helpers duplicados
- [ ] Documentar uso de cada helper

#### 10.3. Documentación
- [ ] Crear `test/README.md` con:
  - [ ] Cómo ejecutar tests
  - [ ] Estructura de tests
  - [ ] Patrones a seguir (AAA, mocks, etc.)
  - [ ] Helpers disponibles

#### 10.4. CI/CD
- [ ] Configurar GitHub Actions para tests
- [ ] Separar unit tests (rápidos) de integration tests
- [ ] Configurar coverage reporting

**Checklist:**
```bash
# 1. Analizar tiempo de ejecución
flutter test --reporter expanded | grep "All tests passed"

# 2. Identificar tests lentos
# 3. Optimizar
# 4. Documentar
```

**Criterio de Éxito:**
- Suite de tests ejecuta en <2 minutos (unit tests)
- Documentación completa
- CI configurado

---

## 📊 MÉTRICAS OBJETIVO

### Coverage Target por Sesión

| Sesión | Coverage Actual | Coverage Objetivo | Incremento |
|--------|----------------|-------------------|------------|
| **Inicial** | 78.9% | - | - |
| Sesión 1 | 78.9% | 79.0% | +0.1% (arreglar tests) |
| Sesión 2 | 79.0% | 82.0% | +3.0% (home domain) |
| Sesión 3 | 82.0% | 86.0% | +4.0% (controllers) |
| Sesión 4 | 86.0% | 87.5% | +1.5% (profile usecases) |
| Sesión 5 | 87.5% | 88.5% | +1.0% (gossip gaps) |
| Sesión 6 | 88.5% | 89.0% | +0.5% (auth gaps) |
| Sesión 7 | 89.0% | 90.0% | +1.0% (core modules) |
| **Meta Final** | - | **90%** | **+11.1%** |

### Archivos a Cubrir por Sesión

| Sesión | Archivos Nuevos | Archivos Arreglados | Total |
|--------|----------------|---------------------|-------|
| Sesión 1 | 0 | ~51 | 51 |
| Sesión 2 | 7 | 0 | 7 |
| Sesión 3 | 2 | 1 | 3 |
| Sesión 4 | 3 | 0 | 3 |
| Sesión 5 | 2 | 0 | 2 |
| Sesión 6 | 1 | 1 | 2 |
| Sesión 7 | 0 | 3 | 3 |
| **Total** | **15** | **56** | **71** |

---

## 🎯 CRITERIOS DE ÉXITO

### Por Feature

- ✅ **auth:** >90% coverage (actualmente ~85%)
- ✅ **gossip:** >85% coverage (actualmente ~72%)
- ✅ **home:** >85% coverage (actualmente ~15% en domain)
- ✅ **location:** >90% coverage (actualmente ~85%)
- ✅ **profile:** >85% coverage (actualmente ~45%)
- ✅ **search:** Mantener 100%

### Global

- ✅ **Coverage Total:** >90% (actualmente 78.9%)
- ✅ **Tests Pasando:** 100% (actualmente 97.3%)
- ✅ **Archivos Sin Tests:** <10 (actualmente 49, pero muchos son interfaces)
- ✅ **Tests Fallando:** 0 (actualmente 51)

### Calidad

- ✅ **Separación clara:** Unit vs Integration tests
- ✅ **Consistencia:** Todos los tests siguen AAA pattern
- ✅ **Velocidad:** Unit tests <2 minutos
- ✅ **Documentación:** README completo en test/

---

## 📌 RESUMEN DE PRIORIDADES

### 🔴 URGENTE (P0) - Hacer PRIMERO

1. **Sesión 1:** Arreglar 51 tests fallando
2. **Sesión 2:** Home domain layer (0% → 80%)
3. **Sesión 3:** Controllers sin coverage (add_gossip, following_tab, profile)

**Impacto:** Crítico para features principales  
**Tiempo:** ~9-12 horas  
**Coverage Gain:** +7.1%

### 🟡 ALTA (P1) - Hacer DESPUÉS

4. **Sesión 4:** Profile usecases
5. **Sesión 5:** Gossip gaps
6. **Sesión 6:** Auth remaining

**Impacto:** Completa features secundarias  
**Tiempo:** ~5-7 horas  
**Coverage Gain:** +2.5%

### 🟢 MEDIA (P2-P3) - Hacer AL FINAL

7. **Sesión 7:** Core modules
8. **Sesión 8:** Investigación
9. **Sesión 9:** Separación unit/integration
10. **Sesión 10:** Limpieza

**Impacto:** Calidad y mantenibilidad  
**Tiempo:** ~9-13 horas  
**Coverage Gain:** +1.4%

---

## 🚀 CÓMO USAR ESTE REPORTE

### Para Empezar Hoy

```bash
# 1. Ver estado actual
flutter test --reporter expanded

# 2. Empezar por Sesión 1 (tests fallando)
flutter test --reporter expanded 2>&1 | grep "FAIL"

# 3. Arreglar uno por uno
flutter test test/features/auth/presentation/widgets/email_field_test.dart
```

### Para Planificar Sprint

- **Sprint 1 (1 semana):** Sesiones 1-3 (P0)
- **Sprint 2 (1 semana):** Sesiones 4-6 (P1)
- **Sprint 3 (1 semana):** Sesiones 7-10 (P2-P3)

### Para Tracking

- [ ] Sesión 1: Tests Fallando ⏳
- [ ] Sesión 2: Home Domain ⏳
- [ ] Sesión 3: Controllers ⏳
- [ ] Sesión 4: Profile Usecases ⏳
- [ ] Sesión 5: Gossip Gaps ⏳
- [ ] Sesión 6: Auth Remaining ⏳
- [ ] Sesión 7: Core Modules ⏳
- [ ] Sesión 8: Investigación ⏳
- [ ] Sesión 9: Unit/Integration ⏳
- [ ] Sesión 10: Limpieza ⏳

---

## 📚 REFERENCIAS

- **Testing Standards:** `.claude/TESTING.md`
- **Architecture:** `.claude/ARCHITECTURE.md`
- **Patterns:** `.claude/PATTERNS.md`
- **Coverage Report:** `coverage/html/index.html` (después de `flutter test --coverage`)

---

**Última actualización:** 2026-11-17  
**Próxima revisión:** Después de cada sesión completada  
**Mantenedor:** Alejo

**FIN DEL REPORTE**
