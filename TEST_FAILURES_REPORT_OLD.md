# Reporte de Tests Fallidos

**Fecha:** 2026-11-07  
**Tests Totales:** 2,836  
**Tests Fallidos:** 224  
**Tests Exitosos:** 2,612  
**Tasa de Éxito:** 92.1%

---

## 📊 Resumen Ejecutivo

| Módulo | Tests Fallidos | % del Total |
|--------|----------------|-------------|
| **Features/Home** | 59 | 26.3% |
| **Features/Gossip** | 57 | 25.4% |
| **Features/Auth** | 50 | 22.3% |
| **Main App** | 31 | 13.8% |
| **Core** | 6 | 2.7% |
| **Search** | 4 | 1.8% |
| **Security** | 4 | 1.8% |
| **Accessibility** | 4 | 1.8% |
| **Otros** | 9 | 4.0% |

---

## 🎯 Top 10 Archivos Críticos

| # | Archivo | Fallos | Módulo |
|---|---------|--------|--------|
| 1 | `main_navigation_screen_test.dart` | 35 | Home |
| 2 | `add_gossip_screen_test.dart` | 30 | Gossip |
| 3 | `home_screen_test.dart` | 24 | Home |
| 4 | `main_test.dart` | 19 | Main |
| 5 | `main_additional_test.dart` | 12 | Main |
| 6 | `image_picker_widget_test.dart` | 10 | Gossip |
| 7 | `update_profile_test.dart` | 9 | Auth |
| 8 | `auth_repository_impl_test.dart` | 9 | Auth |
| 9 | `compact_location_selector_test.dart` | 8 | Gossip |
| 10 | `reset_password_test.dart` | 8 | Auth |

---

## 📱 FEATURE: HOME (59 fallos)

### `main_navigation_screen_test.dart` (35 fallos) 🔴 CRÍTICO

**Categoría:** Presentation Layer - Screen Tests

**Tipos de fallos:**
- Renderizado de componentes (BottomNavigationBar, FloatingActionButton, IndexedStack)
- Navegación entre tabs (HomeScreen ↔ SearchScreen)
- Manejo de estado y ciclo de vida
- Navegación a AddGossipScreen via FAB
- Snackbars de éxito/error

**Impacto:** ALTO - Pantalla principal de la app

---

### `home_screen_test.dart` (24 fallos) 🔴 CRÍTICO

**Categoría:** Presentation Layer - Screen Tests

**Tipos de fallos:**
- Renderizado de GridView y componentes
- Pull-to-refresh
- Gestión de lista de gossips
- Múltiples refreshes consecutivos
- Edge cases (lista vacía, un solo item, muchos items)
- Scroll behavior

**Impacto:** ALTO - Feed principal de gossips

---

## 📝 FEATURE: GOSSIP (57 fallos)

### Presentation Layer (68 fallos)

#### `add_gossip_screen_test.dart` (30 fallos) 🔴 CRÍTICO

**Tipos de fallos:**
- Renderizado de formulario
- Validaciones de campos
- Selección de ubicación
- Image picker
- Botones de acción
- Estados de carga

**Impacto:** ALTO - Creación de gossips (funcionalidad core)

---

#### `image_picker_widget_test.dart` (10 fallos) 🟡 MEDIO

**Tipos de fallos:**
- Selección de imagen
- Preview de imagen
- Eliminar imagen
- Estados del widget

**Impacto:** MEDIO - Feature importante pero no bloqueante

---

#### `compact_location_selector_test.dart` (8 fallos) 🟡 MEDIO

**Tipos de fallos:**
- Selección de ubicación
- Autocomplete
- Validaciones

**Impacto:** MEDIO

---

#### `city_autocomplete_optimized_test.dart` (5 fallos)

**Tipos de fallos:**
- Búsqueda de ciudades
- Debouncing
- Resultados

---

#### Otros widgets (13 fallos)
- `publish_as_selector_test.dart` (4 fallos)
- `location_selector_test.dart` (4 fallos)
- `gossip_card_test.dart` (2 fallos)
- `city_autocomplete_test.dart` (2 fallos)
- `location_change_dialog_test.dart` (1 fallo)

---

#### `add_gossip_controller_test.dart` (2 fallos)

**Tipos de fallos:**
- Lógica del controlador

---

### Data Layer (2 fallos)

#### `mock_gossip_remote_data_source_test.dart` (2 fallos)

**Tipos de fallos:**
- Mock data source

**Impacto:** BAJO - Tests de mocks

---

## 🔐 FEATURE: AUTH (50 fallos)

### Domain Layer (28 fallos)

#### `update_profile_test.dart` (9 fallos) 🟡 MEDIO

**Tipos de fallos:**
- Validación de username (length, formato, mayúsculas, etc.)
- Validación de displayName
- Validación de bio
- Edge cases (orden de validación)

**Impacto:** MEDIO - Funcionalidad de perfil

---

#### `reset_password_test.dart` (8 fallos) 🟡 MEDIO

**Tipos de fallos:**
- Validación de email (formato, length)
- Edge cases de validación

**Impacto:** MEDIO - Recovery de contraseña

---

#### `is_username_available_test.dart` (7 fallos)

**Tipos de fallos:**
- Validación de username (length, caracteres, formato)
- Edge cases

---

#### `auth_validator_test.dart` (4 fallos)

**Tipos de fallos:**
- Validaciones de email, password, username, displayName
- Casos límite (max length)

---

### Presentation Layer (12 fallos)

#### `auth_state_test.dart` (4 fallos)

**Tipos de fallos:**
- Estados de autenticación
- Mensajes de error traducidos
- Casos de uso comunes

---

#### `signup_screen_test.dart` (3 fallos)

**Tipos de fallos:**
- Deshabilitar campos durante carga

---

#### `profile_setup_screen_test.dart` (3 fallos)

**Tipos de fallos:**
- Configuración inicial de perfil

---

#### `login_screen_test.dart` (2 fallos)

**Tipos de fallos:**
- Botones de autenticación

---

### Data Layer (10 fallos)

#### `auth_repository_impl_test.dart` (9 fallos) 🟡 MEDIO

**Tipos de fallos:**
- Sign in exitoso
- Manejo de credenciales incorrectas
- Manejo de AuthException
- Error handling específico

**Impacto:** MEDIO - Repository de autenticación

---

#### `user_model_test.dart` (1 fallo)

**Tipos de fallos:**
- Equality de modelos

---

## 🚀 MAIN APP (31 fallos)

### `main_test.dart` (19 fallos) 🔴 CRÍTICO

**Tipos de fallos:**
- Inicialización de la app
- Estado y ciclo de vida
- Rebuilds múltiples
- Callbacks de inicialización (loadEnv, initializeSupabase, setupDependencies)

**Impacto:** CRÍTICO - Entrada de la aplicación

---

### `main_additional_test.dart` (12 fallos) 🔴 CRÍTICO

**Tipos de fallos:**
- Funcionalidades adicionales de main
- Casos edge de inicialización

**Impacto:** CRÍTICO

---

### `widget_test.dart` (1 fallo)

**Tipos de fallos:**
- Test básico de widget

---

## 🔍 FEATURE: SEARCH (4 fallos)

### `search_screen_test.dart` (4 fallos) 🟢 BAJO

**Tipos de fallos:**
- Funcionalidad de búsqueda

**Impacto:** BAJO - Feature secundaria

---

## ⚙️ CORE (6 fallos)

### `remote_logger_test.dart` (6 fallos) 🟡 MEDIO

**Tipos de fallos:**
- Invocación de Edge Function para logs error/fatal
- Manejo de respuestas (200, 429, 500)
- Body correcto a Edge Function

**Impacto:** MEDIO - Logging remoto

---

## 🛡️ SECURITY (4 fallos)

### `edge_function_auth_test.dart` (4 fallos) 🟡 MEDIO

**Tipos de fallos:**
- P0-03 Fix: Sin JWT → 401 Unauthorized

**Impacto:** MEDIO - Seguridad de Edge Functions

---

## ♿ ACCESSIBILITY (4 fallos)

### `narrow_width_test.dart` (4 fallos) 🟢 BAJO

**Tipos de fallos:**
- Responsive design en pantallas estrechas

**Impacto:** BAJO - UX en edge cases

---

## 🎯 Recomendaciones de Priorización

### 🔴 Prioridad CRÍTICA (74 fallos - 33%)

**Impacto inmediato en funcionalidad core:**

1. **main_navigation_screen_test.dart** (35) - Navegación principal
2. **add_gossip_screen_test.dart** (30) - Creación de gossips
3. **main_test.dart** (19) - Inicialización de app
4. **main_additional_test.dart** (12) - Inicialización adicional
5. **home_screen_test.dart** (24) - Feed principal

**Acción:** Resolver en Sprint actual

---

### 🟡 Prioridad MEDIA (85 fallos - 38%)

**Funcionalidades importantes pero no bloqueantes:**

1. Auth Feature completo (50 fallos)
   - Domain validations (28)
   - Repository (9)
   - Presentation (12)
2. Gossip widgets (23 fallos)
   - image_picker_widget (10)
   - compact_location_selector (8)
   - otros widgets (5)
3. Core logging (6 fallos)
4. Security tests (4 fallos)

**Acción:** Planificar para próximo sprint

---

### 🟢 Prioridad BAJA (65 fallos - 29%)

**Nice-to-have o edge cases:**

1. Gossip controllers y data (4 fallos)
2. Search feature (4 fallos)
3. Accessibility (4 fallos)
4. Auth minor tests (user_model: 1)
5. Widget test genérico (1)

**Acción:** Backlog

---

## 📋 Plan de Acción Sugerido

### Sprint Actual (Prioridad CRÍTICA)

1. **Semana 1:** Main App (31 fallos)
   - [ ] main_test.dart (19)
   - [ ] main_additional_test.dart (12)
   
2. **Semana 2:** Home Feature (59 fallos)
   - [ ] main_navigation_screen_test.dart (35)
   - [ ] home_screen_test.dart (24)

3. **Semana 3:** Gossip Core (30 fallos)
   - [ ] add_gossip_screen_test.dart (30)

**Total Sprint Actual: 120 fallos resueltos (53% de los fallos)**

---

### Próximo Sprint (Prioridad MEDIA)

1. **Semana 1:** Auth Feature completo (50 fallos)
2. **Semana 2:** Gossip widgets restantes (23 fallos)
3. **Semana 3:** Core + Security (10 fallos)

**Total Próximo Sprint: 83 fallos resueltos (37%)**

---

### Backlog (Prioridad BAJA)

- Search feature (4)
- Accessibility (4)
- Gossip data layer (4)
- Misceláneos (9)

**Total Backlog: 21 fallos (9%)**

---

## 🔍 Análisis de Patrones Comunes

### Patrones detectados en los fallos:

1. **Widget/Screen Tests (mayoría):**
   - Renderizado de componentes
   - Navegación entre pantallas
   - Estados de UI

2. **Validaciones de Dominio:**
   - Validaciones de length (muy corto/largo)
   - Validaciones de formato
   - Edge cases

3. **Repository/Data Layer:**
   - Manejo de errores
   - Transformación de excepciones

4. **Inicialización:**
   - Setup de dependencias
   - Callbacks de inicio

### Posibles Causas Raíz:

1. **Cambios en Flutter/Packages:** Deprecations de APIs (Flutter 3.27+)
2. **Mocks incompletos:** Falta configuración de mocks en tests de UI
3. **EasyLocalization:** Falta wrapper en tests de widgets
4. **Pump/PumpAndSettle:** Timing issues en tests de UI
5. **Validadores:** Posible cambio en lógica de validación

---

## 📈 Métricas Actuales

```
Coverage Global:    78.9%
Tests Totales:      2,836
Tests Pasando:      2,612 (92.1%)
Tests Fallando:     224 (7.9%)
Tests Skipped:      10 (0.35%)
```

### Objetivo Post-Fix:

```
Coverage Global:    >80%
Tests Totales:      2,836
Tests Pasando:      >2,750 (>97%)
Tests Fallando:     <50 (<2%)
```

---

## 📝 Notas Finales

- **No modificar código de producción para pasar tests** (Regla crítica del proyecto)
- **Adaptar tests al código existente**
- **Seguir pattern AAA** (Arrange-Act-Assert)
- **Usar mocks apropiados**
- **Verificar EasyLocalization wrappers** en widget tests

---

**Generado:** 2026-11-07  
**Por:** Claude Code Analysis
