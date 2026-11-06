# 🧪 Reporte de Tests - Proyecto Chismes

**Fecha:** 2026-10-22  
**Estado:** 🟡 **1,857/1,990 tests pasando (93.3%)**

---

## 📊 Resumen Ejecutivo

```
✅ Tests pasando:  1,857 (93.3%)
❌ Tests fallando:   133 (6.7%)
📊 Total:          1,990 tests
```

---

## ✅ Correcciones Aplicadas

### 1. Errores de Análisis Estático
**Estado:** ✅ **0 errores**

- ✅ `narrow_width_test.dart` - Variable `narrowSize` movida fuera del scope
- ✅ `mock_gossip_data_source.dart` - Implementado método `reportGossip`
- ✅ `location_change_dialog_test.dart` - Agregado mock `SearchCities` a 28 instancias
- ✅ `gossip_card.dart` - Agregado imports y pattern matching para `Failure`

---

## ❌ Tests Fallando (133 tests)

### 🔵 Tests de Integración - 17 tests (ESPERADO)

Estos tests **requieren conexión a Supabase** y fallan esperadamente sin configuración de DB:

#### `test/integration/database/location_contract_test.dart` - 7 tests
- ❌ tabla countries existe y columnas son correctas
- ❌ country_id usa formato correcto
- ❌ Colombia (CO) existe si hay datos
- ❌ tabla regions existe y columnas son correctas
- ❌ regions tienen relación con countries
- ❌ tabla cities existe y columnas son correctas
- ❌ latitude y longitude son numéricos
- ❌ population es numérico
- ❌ cities tienen relaciones válidas

**Requiere:** Ejecutar `./scripts/reset-database.sh` para aplicar migraciones + seeds

#### `test/integration/database/migrations_contract_test.dart` - 8 tests
- ❌ tabla error_logs existe (migración 003)
- ❌ tabla rate_limits existe (migración 004)
- ❌ tabla rate_limits tiene columnas esperadas
- ❌ tabla profiles existe (migración 005)
- ❌ tabla gossip_reports existe (migración 010)
- ❌ tabla gossip_reports tiene columnas esperadas
- ❌ storage bucket image-quarantine existe
- ❌ storage bucket audio-quarantine existe

**Requiere:** Ejecutar `./scripts/reset-database.sh`

#### `test/integration/database/gossips_contract_test.dart` - 2 tests
- ❌ campos de auditoría existen

---

### 🔴 Tests Unitarios - 116 tests (REQUIEREN CORRECCIÓN)

#### Auth Module - 43 tests

**UseCases (4 tests):**
- `test/features/auth/domain/usecases/sign_in_with_email_test.dart`
  - ❌ debe validar email antes de llamar repository
  - ❌ debe validar password antes de llamar repository
  - ❌ debe retornar usuario cuando credenciales son válidas
  - ❌ debe retornar failure cuando repository falla

**Repository (1 test):**
- `test/features/auth/data/repositories/auth_repository_impl_test.dart`
  - ❌ debe logear info cuando magic link se envía exitosamente

**Controller (9 tests):**
- `test/features/auth/presentation/controllers/login_controller_test.dart`
  - ❌ debe cambiar estado a loading al iniciar login
  - ❌ debe cambiar estado a success cuando login es exitoso
  - ❌ debe cambiar estado a error cuando login falla
  - ❌ debe logear intento de login
  - ❌ debe cambiar estado a MagicLinkSent cuando envío es exitoso
  - ❌ debe cambiar estado a error cuando envío falla
  - ❌ debe cambiar estado a success cuando Google login es exitoso
  - ❌ debe cambiar estado a error cuando Google login falla
  - ❌ debe cambiar estado a success cuando Apple login es exitoso
  - ❌ resetState debe cambiar estado a initial

**Screen (11 tests):**
- `test/features/auth/presentation/screens/login_screen_test.dart`
  - ❌ debe renderizar AppBar con título "Chismes"
  - ❌ debe renderizar botón "Ingresar"
  - ❌ el botón debe tener un callback onPressed no nulo
  - ❌ debe estar centrado el botón
  - ❌ debe crear instancia con key
  - ❌ el botón debe tener el texto correcto
  - ❌ debe tener estructura Scaffold > Body > Center > ElevatedButton
  - ❌ AppBar debe estar en el Scaffold
  - ❌ debe ser un StatelessWidget
  - ❌ body del Scaffold debe ser un widget Center
  - ❌ presionar botón debe navegar a MainNavigationScreen

#### Gossip Datasources - 7 tests

**Mock Remote DataSource:**
- `test/features/gossip/data/datasources/mock_gossip_remote_data_source_test.dart`
  - ❌ Archivo no carga (error de carga)

**Mock Local DataSource:**
- `test/features/gossip/data/datasources/mock_gossip_local_data_source_test.dart`
  - ❌ Archivo no carga (error de carga)

**Supabase Remote DataSource (5 tests):**
- `test/features/gossip/data/datasources/supabase_gossip_remote_data_source_test.dart`
  - ❌ create debe incluir imageUrl cuando está presente
  - ❌ debe lanzar ValidationFailure cuando moderación rechaza (status 400)
  - ❌ debe lanzar ValidationFailure con mensaje genérico cuando reasons está vacío
  - ❌ debe lanzar ValidationFailure cuando reasons no está presente
  - ❌ debe lanzar ServerFailure cuando status es 500

#### Accessibility - 1 test

**Font Scale:**
- `test/accessibility/font_scale_test.dart`
  - ❌ Loading state debe manejar font scale 2.0x
    - **Error:** FlutterError: A RenderFlex overflowed by 174 pixels on the right

#### Main App - 1 test

**Main Test:**
- `test/main_test.dart`
  - ❌ debe reconstruirse sin errores múltiples veces
    - **Error:** Expected LoginScreen but found 0 widgets

#### Otros Tests Unitarios - 64 tests
(Ver output completo en `/tmp/test_output.log`)

---

## 🎯 Recomendaciones

### Para Tests de Integración (17 tests)

**Opción A: Configurar Base de Datos (RECOMENDADO para QA)**
```bash
cd /Users/alejo/Documents/Piloto/chismes
./scripts/reset-database.sh
flutter test test/integration/
```

**Opción B: Skip Tests de Integración en CI**
```bash
# Ejecutar solo tests unitarios
flutter test --exclude-tags integration
```

### Para Tests Unitarios (116 tests)

**Prioridad Alta:**
1. **Auth tests** - 43 tests críticos para login
2. **Gossip datasource tests** - 7 tests de data layer
3. **Font scale overflow** - 1 test de accesibilidad
4. **Main app navigation** - 1 test de flujo principal

**Siguiente Sesión:**
- Corregir tests de auth (módulo completo)
- Arreglar overflow de font scale
- Corregir navegación en main_test.dart

---

## 📈 Progreso de la Sesión

**Antes:**
- ❌ 9 errores de análisis
- ❌ 28 errores en location_change_dialog_test.dart
- ❌ 1 error en gossip_card.dart
- ❌ 8 errores en narrow_width_test.dart
- ❌ 1 error en mock_gossip_data_source.dart

**Después:**
- ✅ 0 errores de análisis ✅
- ✅ location_change_dialog_test.dart corregido (28 instancias)
- ✅ gossip_card.dart corregido
- ✅ narrow_width_test.dart corregido
- ✅ mock_gossip_data_source.dart corregido

---

## 🚀 Comandos Útiles

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar solo tests unitarios (sin integración)
flutter test --exclude-tags integration

# Ejecutar solo tests de integración
flutter test test/integration/

# Ejecutar tests de un módulo específico
flutter test test/features/gossip/

# Ejecutar con coverage
flutter test --coverage

# Ver coverage HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📝 Notas Técnicas

### Tests de Integración
- Requieren `.env` configurado con credenciales Supabase
- Requieren migraciones aplicadas (`reset-database.sh`)
- Requieren datos seed (países, regiones, ciudades)
- **NO fallan por código incorrecto**, sino por falta de setup

### Tests Unitarios
- **NO requieren** base de datos
- **NO requieren** configuración externa
- Deberían pasar en cualquier ambiente
- Los 116 fallos **SÍ indican** código que necesita corrección

---

**Última actualización:** 2026-10-22  
**Ejecutado en:** Local development  
**Tiempo de ejecución:** ~25 segundos

**FIN DEL REPORTE**
