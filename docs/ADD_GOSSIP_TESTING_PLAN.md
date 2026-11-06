# Plan de Testing para Add Gossip Feature

## 🎯 Objetivo: Cobertura >90%

## 📋 Estado Actual

### Tests Existentes
- ✅ `gossip_validator_test.dart` - 15 tests (COMPLETO)
- ⚠️ `add_gossip_controller_test.dart` - No compila (dependencias)
- ⚠️ `add_gossip_screen_test.dart` - No compila (dependencias)
- ⚠️ `create_gossip_test.dart` - No compila (dependencias)

### Problema Bloqueante
```
Error: Couldn't resolve the package 'flutter_image_compress'
```

## 🔧 Paso 1: Resolver Dependencias

### Archivos afectados:
- `lib/core/media/image_compressor.dart`

### Opciones:
1. **Agregar dependencia al pubspec.yaml:**
```yaml
dev_dependencies:
  flutter_image_compress: ^2.0.0
```

2. **Comentar código temporalmente** (para testing MVP)

## 📝 Paso 2: Tests Faltantes (Prioridad Alta)

### A. Domain Layer - Validators (80% completo)

#### `gossip_validator_test.dart` - MEJORAR
**Faltante:**
- [ ] Tests de `validateStatusCombination`
  - Todas las 6 combinaciones válidas
  - Combinaciones inválidas (10 casos)
- [ ] Edge cases con espacios en blanco
  - Subject/content con solo espacios
  - Subject/content con espacios al inicio/final
- [ ] Tests de null handling en `validateLocation`

**Estimado:** +10 tests

---

### B. Presentation - State (0% completo)

#### `add_gossip_state_test.dart` - CREAR
**Tests necesarios:**
```dart
group('AddGossipState', () {
  // copyWith
  test('copyWith actualiza countries correctamente')
  test('copyWith actualiza regions correctamente')
  test('copyWith actualiza cities correctamente')
  test('copyWith actualiza selectedCountryId correctamente')
  test('copyWith actualiza selectedRegionId correctamente')
  test('copyWith actualiza selectedCityId correctamente')
  test('copyWith actualiza publishedAs correctamente')
  test('copyWith actualiza subject correctamente')
  test('copyWith actualiza content correctamente')
  test('copyWith actualiza audioUrl correctamente')
  test('copyWith actualiza imageUrl correctamente')
  test('copyWith actualiza flags de loading correctamente')
  test('copyWith actualiza failure correctamente')
  test('copyWith mantiene otros campos sin cambiar')
  test('copyWith puede establecer nulls con _unset')
  
  // clearFailure
  test('clearFailure limpia failure y mantiene otros campos')
  
  // clearLocation
  test('clearLocation limpia selectedRegionId y selectedCityId')
  test('clearLocation limpia regions y cities')
  test('clearLocation mantiene selectedCountryId')
  
  // Equatable
  test('dos estados con mismos valores son iguales')
  test('dos estados con valores diferentes son distintos')
  test('props incluye todos los campos')
  
  // hasError
  test('hasError retorna true cuando hay failure')
  test('hasError retorna false cuando no hay failure')
});
```

**Estimado:** +24 tests

---

### C. Presentation - Controller (60% completo)

#### `add_gossip_controller_test.dart` - MEJORAR

**Tests existentes (47 tests):**
- ✅ Inicialización
- ✅ Selección de ubicación
- ✅ Race conditions
- ✅ Actualización de campos
- ✅ Submit
- ✅ Reset y Clear
- ✅ Notificaciones

**Faltantes (CRÍTICOS):**
```dart
group('AddGossipController - Location Service', () {
  // loadDefaultLocation
  test('debe cargar ubicación guardada si existe')
  test('debe auto-detectar si no hay ubicación guardada')
  test('debe manejar error al cargar ubicación')
  
  // autoDetectLocation
  test('debe detectar y seleccionar ubicación desde GPS')
  test('debe manejar error de GPS no disponible')
  test('debe manejar error de reverse geocoding')
  test('debe manejar país no encontrado en lista')
  test('debe manejar región no encontrada en lista')
  test('debe manejar ciudad no encontrada en lista')
  test('debe guardar ubicación detectada como default')
  
  // saveLocationPreference
  test('debe guardar ubicación completa')
  test('no debe guardar si faltan datos de ubicación')
  test('debe llamar locationService.saveDefaultLocation')
  
  // locationDisplayText
  test('debe retornar texto formateado cuando hay ciudad y región')
  test('debe retornar null cuando no hay ciudad seleccionada')
  test('debe retornar null cuando ciudad no existe en lista')
  test('debe retornar null cuando región no existe en lista')
});

group('AddGossipController - Image Handling', () {
  // removeImage
  test('debe limpiar _selectedImageFile')
  test('debe limpiar imageUrl del state')
  
  // hasImageSelected
  test('debe retornar true cuando hay imagen')
  test('debe retornar false cuando no hay imagen')
  
  // setImageUrl
  test('debe actualizar imageUrl en el estado')
});

group('AddGossipController - Submit con imagen', () {
  test('debe incluir imageFile en el use case')
  test('debe enviar null si no hay imagen')
});
```

**Estimado:** +26 tests

---

### D. Presentation - Screen (40% completo)

#### `add_gossip_screen_test.dart` - MEJORAR

**Tests existentes (8 tests):**
- ✅ Renderizado básico
- ✅ Validación vacía
- ✅ Loading durante submit
- ✅ Error en submit
- ✅ Selección de ubicación
- ✅ Prevenir doble submit
- ✅ Callback onSuccess
- ✅ Limpiar formulario después de submit

**Faltantes:**
```dart
group('AddGossipScreen - Validaciones de Formulario', () {
  test('debe mostrar error cuando subject excede 200 chars')
  test('debe mostrar error cuando content excede 1000 chars')
  test('debe deshabilitar submit cuando falta ubicación')
  test('debe deshabilitar submit cuando faltan campos')
});

group('AddGossipScreen - Interacciones de Usuario', () {
  test('debe actualizar contador de caracteres en subject')
  test('debe actualizar contador de caracteres en content')
  test('debe cambiar PublishAs correctamente')
  test('debe mostrar/ocultar location change dialog')
});

group('AddGossipScreen - Estados de Error', () {
  test('debe mostrar error de network')
  test('debe mostrar error de validación')
  test('debe limpiar error al escribir en campos')
});
```

**Estimado:** +11 tests

---

### E. Presentation - Widgets (0% completo)

#### Widget Tests Individuales - CREAR

##### `submit_button_test.dart`
```dart
group('SubmitButton', () {
  test('debe estar habilitado cuando isSubmitting = false')
  test('debe estar deshabilitado cuando isSubmitting = true')
  test('debe mostrar CircularProgressIndicator cuando isSubmitting = true')
  test('debe llamar onPressed cuando está habilitado')
  test('no debe llamar onPressed cuando está deshabilitado')
  test('debe tener el texto correcto')
  test('debe tener el estilo correcto')
});
```
**Estimado:** 7 tests

##### `location_selector_test.dart`
```dart
group('LocationSelector', () {
  test('debe mostrar loading cuando isLoadingCountries = true')
  test('debe mostrar lista de países')
  test('debe llamar onCountryChanged al seleccionar país')
  test('debe mostrar loading cuando isLoadingRegions = true')
  test('debe mostrar lista de regiones después de seleccionar país')
  test('debe llamar onRegionChanged al seleccionar región')
  test('debe mostrar loading cuando isLoadingCities = true')
  test('debe mostrar lista de ciudades después de seleccionar región')
  test('debe llamar onCityChanged al seleccionar ciudad')
  test('debe deshabilitar región cuando no hay país')
  test('debe deshabilitar ciudad cuando no hay región')
  test('debe limpiar región al cambiar país')
  test('debe limpiar ciudad al cambiar región')
});
```
**Estimado:** 13 tests

##### `compact_location_selector_test.dart`
```dart
group('CompactLocationSelector', () {
  test('debe mostrar texto de ubicación cuando hay selección')
  test('debe mostrar texto por defecto cuando no hay selección')
  test('debe abrir dialog al hacer tap')
  test('debe actualizar cuando cambia la ubicación')
  test('debe mostrar ícono de ubicación')
});
```
**Estimado:** 5 tests

##### `city_autocomplete_test.dart`
```dart
group('CityAutocomplete', () {
  test('debe filtrar ciudades según input')
  test('debe mostrar todas las ciudades cuando input está vacío')
  test('debe llamar onCitySelected al seleccionar')
  test('debe manejar búsqueda sin resultados')
  test('debe ser case-insensitive en búsqueda')
  test('debe limpiar selección al cambiar región')
});
```
**Estimado:** 6 tests

##### `gossip_text_fields_test.dart`
```dart
group('GossipTextFields', () {
  test('debe renderizar campo de subject')
  test('debe renderizar campo de content')
  test('debe mostrar contador de caracteres en subject')
  test('debe mostrar contador de caracteres en content')
  test('debe mostrar error cuando excede max length')
  test('debe actualizar controllers correctamente')
  test('debe validar campos requeridos')
});
```
**Estimado:** 7 tests

##### `publish_as_selector_test.dart`
```dart
group('PublishAsSelector', () {
  test('debe renderizar opción Anonymous')
  test('debe renderizar opción Profile')
  test('debe llamar onChanged al seleccionar')
  test('debe mostrar selección actual')
  test('debe tener estilo correcto según selección')
});
```
**Estimado:** 5 tests

##### `media_attachment_section_test.dart`
```dart
group('MediaAttachmentSection', () {
  test('debe mostrar botón de agregar imagen')
  test('debe mostrar botón de agregar audio')
  test('debe llamar onImagePicked al seleccionar')
  test('debe mostrar preview de imagen cuando existe')
  test('debe mostrar botón de remover cuando hay media')
  test('debe llamar onRemove al remover media')
});
```
**Estimado:** 6 tests

##### `image_picker_widget_test.dart`
```dart
group('ImagePickerWidget', () {
  test('debe mostrar opciones de cámara y galería')
  test('debe llamar onCameraPick al seleccionar cámara')
  test('debe llamar onGalleryPick al seleccionar galería')
  test('debe mostrar preview de imagen')
  test('debe mostrar placeholder cuando no hay imagen')
});
```
**Estimado:** 5 tests

##### `location_change_dialog_test.dart`
```dart
group('LocationChangeDialog', () {
  test('debe renderizar título y mensaje')
  test('debe mostrar botones de confirmar y cancelar')
  test('debe retornar true al confirmar')
  test('debe retornar false al cancelar')
  test('debe cerrar al hacer tap fuera')
});
```
**Estimado:** 5 tests

**Total Widgets:** 59 tests

---

### F. Domain - Use Case (70% completo)

#### `create_gossip_test.dart` - MEJORAR

**Tests existentes:**
- ✅ Validaciones básicas
- ✅ Propagación de errores

**Faltantes:**
```dart
group('CreateGossip - Con Imagen', () {
  test('debe llamar repository con imageFile')
  test('debe subir imagen antes de crear gossip')
  test('debe manejar error al subir imagen')
  test('debe crear gossip sin imagen si imageFile es null')
});

group('CreateGossip - Idempotencia', () {
  test('debe incluir idempotencyKey en el input')
  test('debe generar UUID único para cada llamada')
  test('debe prevenir duplicados con mismo idempotencyKey')
});

group('CreateGossip - Audio', () {
  test('debe crear gossip con audioUrl')
  test('debe crear gossip sin audioUrl si es null')
});
```

**Estimado:** +9 tests

---

### G. Integration Tests (0% completo)

#### `add_gossip_integration_test.dart` - CREAR

```dart
group('Add Gossip - Flujo Completo E2E', () {
  testWidgets('flujo completo: crear gossip exitoso', (tester) async {
    // 1. Abrir pantalla
    // 2. Seleccionar ubicación (país → región → ciudad)
    // 3. Escribir subject y content
    // 4. Seleccionar PublishAs
    // 5. Submit
    // 6. Verificar éxito
    // 7. Verificar navegación
  });
  
  testWidgets('flujo con imagen: seleccionar y subir', (tester) async {
    // 1. Abrir pantalla
    // 2. Seleccionar imagen
    // 3. Ver preview
    // 4. Completar formulario
    // 5. Submit con imagen
    // 6. Verificar subida
  });
  
  testWidgets('flujo con error: mostrar y recuperar', (tester) async {
    // 1. Abrir pantalla
    // 2. Completar formulario
    // 3. Submit falla (network error)
    // 4. Mostrar error
    // 5. Reintentar
    // 6. Verificar éxito
  });
  
  testWidgets('flujo con ubicación GPS', (tester) async {
    // 1. Abrir pantalla
    // 2. Auto-detectar ubicación
    // 3. Verificar ubicación cargada
    // 4. Completar formulario
    // 5. Submit
  });
  
  testWidgets('flujo cancelar y limpiar', (tester) async {
    // 1. Abrir pantalla
    // 2. Llenar parcialmente
    // 3. Cancelar/Reset
    // 4. Verificar limpieza
  });
});
```

**Estimado:** 5 tests

---

## 📊 Resumen de Tests Totales

| Categoría | Estado | Tests Actuales | Tests Nuevos | Total |
|-----------|--------|----------------|--------------|-------|
| Validators | ⚠️ Mejorar | 15 | +10 | 25 |
| State | ❌ Crear | 0 | +24 | 24 |
| Controller | ⚠️ Mejorar | 47 | +26 | 73 |
| Screen | ⚠️ Mejorar | 8 | +11 | 19 |
| Widgets | ❌ Crear | 0 | +59 | 59 |
| Use Case | ⚠️ Mejorar | ~10 | +9 | 19 |
| Integration | ❌ Crear | 0 | +5 | 5 |
| **TOTAL** | | **~80** | **+144** | **224** |

---

## 🎯 Plan de Ejecución

### Fase 1: Desbloqueo (Día 1)
1. ✅ Agregar `flutter_image_compress` al pubspec.yaml
2. ✅ Verificar que tests existentes compilen
3. ✅ Ejecutar tests existentes

### Fase 2: Tests Críticos (Día 1-2)
**Prioridad 1:**
1. ✅ `add_gossip_state_test.dart` (24 tests)
2. ✅ Completar `add_gossip_controller_test.dart` (+26 tests)
3. ✅ Completar `gossip_validator_test.dart` (+10 tests)

### Fase 3: Widgets (Día 2-3)
**Prioridad 2:**
4. ✅ `submit_button_test.dart` (7 tests)
5. ✅ `location_selector_test.dart` (13 tests)
6. ✅ `publish_as_selector_test.dart` (5 tests)
7. ✅ `gossip_text_fields_test.dart` (7 tests)
8. ⚠️ Otros widgets según necesidad

### Fase 4: Use Case & Screen (Día 3)
**Prioridad 3:**
9. ✅ Completar `create_gossip_test.dart` (+9 tests)
10. ✅ Completar `add_gossip_screen_test.dart` (+11 tests)

### Fase 5: Integration (Día 4)
**Prioridad 4:**
11. ✅ `add_gossip_integration_test.dart` (5 tests)

---

## 🎬 Comandos Útiles

```bash
# Ejecutar solo tests de add_gossip
flutter test test/features/gossip/presentation/controllers/
flutter test test/features/gossip/domain/
flutter test test/features/gossip/integration/

# Generar coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Ver coverage de un archivo específico
lcov --list coverage/lcov.info | grep add_gossip
```

---

## ✅ Criterios de Éxito

- [ ] Todos los tests pasan (224 tests)
- [ ] Cobertura de líneas >90%
- [ ] Cobertura de branches >85%
- [ ] Sin tests flaky (intermitentes)
- [ ] Sin warnings en test output
- [ ] Documentación actualizada

---

## 🚀 Siguiente Paso

**ACCIÓN INMEDIATA:**
```bash
# 1. Agregar dependencia
flutter pub add dev:flutter_image_compress

# 2. Ejecutar tests existentes
flutter test test/features/gossip/

# 3. Crear add_gossip_state_test.dart
```
