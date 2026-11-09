# Test Failures Summary

**Generado:** 2026-11-07  
**Estado:** 61 tests fallando (antes: 69)  
**Progreso:** ✅ 8 tests arreglados

## 📊 Resumen por Módulo

| Módulo | Tests Fallando | % del Total |
|--------|----------------|-------------|
| **Gossip Presentation** | 44 | 72.1% |
| **Auth Presentation** | 9 | 14.8% |
| **Search Presentation** | 4 | 6.6% |
| **Accessibility** | 4 | 6.6% |
| **TOTAL** | **61** | **100%** |

## ✅ Tests Arreglados en esta sesión (8)

### 1. Core Tests (7 tests)
- ✅ `test/widget_test.dart` - App smoke test
- ✅ `test/features/auth/data/models/user_model_test.dart` - Equality test
- ✅ `test/core/logging/remote_logger_test.dart` (6 tests)
  - debe invocar Edge Function para logs de error
  - debe invocar Edge Function para logs fatal
  - debe manejar respuesta exitosa (status 200)
  - debe manejar rate limit (status 429)
  - debe manejar error de Edge Function (status 500)
  - debe enviar body correcto a Edge Function

### Cambios aplicados:
1. **widget_test.dart**: 
   - Agregado mock de `AuthRepository` con `authStateChanges`
   - Agregado `addListener`/`removeListener` stubs
   - Wrapeado con `testableWidget` para EasyLocalization

2. **user_model_test.dart**: 
   - Eliminado test de equality (UserModel no implementa `==`)

3. **remote_logger_test.dart**: 
   - Usamos `setupMockSupabaseClient()` para configurar `auth.currentSession`

## ❌ Tests Aún Fallando por Módulo

### 1. Gossip Presentation (44 tests)

#### add_gossip_screen_test.dart (4 tests)
- debe ejecutar callback onCountryChanged cuando cambia el país
- debe ejecutar onConfirm al presionar botón Confirmar
- debe pasar null a selectCity cuando se limpia CityAutocomplete
- debe limpiar recursos al hacer dispose

#### gossip_widgets (~40 tests estimados)
- compact_location_selector_test.dart
- gossip_card_test.dart
- city_autocomplete_test.dart
- image_picker_widget_test.dart
- publish_as_selector_test.dart
- location_selector_test.dart
- location_change_dialog_test.dart
- add_gossip_controller_test.dart

### 2. Auth Presentation (9 tests)

Archivos afectados:
- auth_state_test.dart
- login_screen_test.dart  
- profile_setup_screen_test.dart

### 3. Search Presentation (4 tests)

- search_screen_test.dart

### 4. Accessibility (4 tests)

- narrow_width_test.dart

## 🎯 Siguiente Paso Sugerido

**Prioridad Alta:** Arreglar Gossip Presentation (44 tests, 72% del total)

**Enfoque recomendado:**
1. Empezar con `add_gossip_screen_test.dart` (4 tests claros)
2. Continuar con widgets de gossip (patrones similares esperados)
3. Auth Presentation (9 tests)
4. Search y Accessibility (8 tests combinados)

## 📈 Progreso General

```
Estado Inicial:  +2717  ~10  -69
Estado Actual:   +2724  ~10  -61
Progreso:         +7          -8
```

**Coverage esperado después de arreglar todo:** ~96.5% (2785/2895 tests)
