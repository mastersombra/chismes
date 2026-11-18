# Sesión 4 - Utilities/Helpers ✅

**Fecha:** 2026-11-18  
**Objetivo:** Testear archivos de utilidades y helpers simples  
**Status:** Completado

---

## 📊 Resultados

### Tests Creados

| Archivo | Tests | Líneas | Status |
|---------|-------|--------|--------|
| `gossip_mock_data_test.dart` | 7 | 58 | ✅ Completo |
| `supabase_config_test.dart` | 6 | 37 | ✅ Completo |
| `theme_extensions_test.dart` | 17 | 45 | ✅ Completo |
| `locale_notifier_test.dart` | 16 | 59 | ✅ Completo |
| **TOTAL** | **46** | **199** | ✅ |

### Estadísticas Generales

```
Tests nuevos:    46 tests
Todos pasando:   46/46 ✅
Líneas cubiertas: ~199 líneas
Archivos:        4 archivos
Tiempo sesión:   ~45 min
```

---

## 🎯 Archivos Testeados

### 1. gossip_mock_data.dart (58 líneas)

**Ubicación:** `lib/shared/data/gossip_mock_data.dart`

**Coverage:** ~100% (es data estática)

**Tests:**
- ✅ Debe contener 4 gossips de prueba
- ✅ Cada gossip debe tener estructura válida (todos los campos)
- ✅ `publishedAs` debe ser "anonymous" o "profile"
- ✅ `imageUrl` debe ser URL válida
- ✅ `createdAt` debe ser fecha válida ISO 8601
- ✅ `modifiedAt` puede ser null o fecha válida
- ✅ Gossip con id "1" debe tener datos esperados

**Notas:**
- Mock data para testing y desarrollo
- No requiere mocks, es data pura
- Validación de estructura y tipos

---

### 2. supabase_config.dart (37 líneas)

**Ubicación:** `lib/core/config/supabase_config.dart`

**Coverage:** ~50% (solo getters, initialize() no testeado por depender de Supabase global)

**Tests:**
- ✅ `url` debe retornar string
- ✅ `anonKey` debe retornar string
- ✅ `url` debe venir de SUPABASE_URL en .env
- ✅ `anonKey` debe venir de SUPABASE_ANON_KEY en .env
- ✅ Debe tener método `initialize`
- ✅ Debe tener getter `client`

**Notas:**
- Clase de configuración con métodos estáticos
- `initialize()` y `client` no testeados (requieren Supabase inicializado)
- Tests verifican estructura y getters básicos

---

### 3. theme_extensions.dart (45 líneas)

**Ubicación:** `lib/core/theme/theme_extensions.dart`

**Coverage:** ~100%

**Tests:**
- ✅ `colors` debe retornar ColorScheme
- ✅ `textTheme` debe retornar TextTheme
- ✅ `errorColor`, `successColor`, `warningColor` (light mode)
- ✅ `surfaceColor`, `borderColor`
- ✅ `successColor`, `warningColor` (dark mode)
- ✅ `errorBackground` con opacidad 0.1
- ✅ `successBackground` con opacidad 0.1
- ✅ `warningBackground` con opacidad 0.1
- ✅ `errorBorder` con opacidad 0.3
- ✅ `successBorder` con opacidad 0.3
- ✅ `warningBorder` con opacidad 0.3
- ✅ Detección de light/dark mode

**Fix aplicado:**
```dart
// ❌ Deprecated
expect(color.value, equals(expected.value))

// ✅ Correcto
expect(color.toARGB32(), equals(expected.toARGB32()))
```

**Notas:**
- Extension methods para BuildContext
- Requiere crear contexto con MaterialApp + Builder
- Tests para light y dark mode
- Verificación de opacidades con `toARGB32()`

---

### 4. locale_notifier.dart (59 líneas)

**Ubicación:** `lib/core/l10n/locale_notifier.dart`

**Coverage:** ~100%

**Tests:**
- ✅ Debe usar español como locale por defecto
- ✅ Debe cargar locale guardado desde SharedPreferences
- ✅ Debe usar español si locale guardado no es válido
- ✅ `setLocale` debe cambiar el locale
- ✅ `setLocale` debe persistir en SharedPreferences
- ✅ `setLocale` debe notificar listeners
- ✅ `setLocale` NO debe notificar si el locale es el mismo
- ✅ Debe permitir cambiar entre locales soportados
- ✅ `supportedLocales` debe contener español e inglés (2 locales)
- ✅ Debe persistir locale entre instancias
- ✅ Debe mantener español por defecto sin persistencia
- ✅ Debe manejar locale null en SharedPreferences
- ✅ Debe manejar locale vacío en SharedPreferences
- ✅ Debe manejar múltiples listeners

**Notas:**
- ChangeNotifier para gestión de idioma
- Persistencia con SharedPreferences
- Tests completos de inicialización, setters, listeners, edge cases

---

## 🔧 Desafíos y Soluciones

### 1. Color.value deprecated ⚠️

**Problema:**
```dart
expect(color.value, equals(expected.value))
// Warning: 'value' is deprecated
```

**Solución:**
```dart
expect(color.toARGB32(), equals(expected.toARGB32()))
```

**Razón:**  
Flutter 3.27+ deprecó `Color.value`, usar `toARGB32()` es el reemplazo oficial.

---

### 2. BuildContext en Tests

**Problema:**  
`ThemeExtensions` son extension methods de `BuildContext`, necesitan contexto real.

**Solución:**
```dart
Future<BuildContext> _createContext(WidgetTester tester, ThemeData theme) async {
  late BuildContext capturedContext;

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ),
  );

  return capturedContext;
}
```

---

### 3. SupabaseConfig Limitado

**Problema:**  
`SupabaseConfig.initialize()` y `.client` requieren Supabase global inicializado.

**Solución:**  
Testear solo getters y estructura. `initialize()` se testea en integration tests.

**Coverage:** ~50% (aceptable para clase de configuración)

---

### 4. SharedPreferences Mocking

**Problema:**  
`LocaleNotifier` depende de SharedPreferences.

**Solución:**
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  prefs = await SharedPreferences.getInstance();
});
```

Flutter provee `setMockInitialValues` para tests.

---

## 📈 Progreso Coverage

### Antes de Sesión 4
```
Coverage: 77.8%
Tests: ~3,344 tests
```

### Después de Sesión 4
```
Coverage: ~78-79% (estimado +0.5-1%)
Tests: ~3,390 tests (+46)
```

**Nota:** Coverage incremental bajo porque los archivos testeados son pequeños (199 líneas vs ~2,500 total).

---

## 🎓 Aprendizajes

### 1. Tests de Configuración

✅ **Hacer:**
- Testear getters y estructura
- Verificar que valores vengan de sources correctas (.env, config)
- Testear factory methods/defaults

❌ **No hacer:**
- Testear métodos que requieren estado global (initialize)
- Forzar tests que dependen de servicios externos

---

### 2. Extension Methods

✅ **Patrón:**
```dart
// 1. Crear contexto con theme específico
final context = await _createContext(tester, ThemeData.light());

// 2. Usar extension
final color = context.successColor;

// 3. Verificar
expect(color, equals(AppTheme.successLight));
```

---

### 3. ChangeNotifier Tests

✅ **Patrón completo:**
```dart
test('debe notificar listeners', () async {
  // Arrange
  final notifier = LocaleNotifier(prefs);
  var notified = false;
  notifier.addListener(() {
    notified = true;
  });

  // Act
  await notifier.setLocale(const Locale('en'));

  // Assert
  expect(notified, isTrue);
});
```

**Verificar:**
1. Inicialización
2. Setters (cambio de valor)
3. Persistencia
4. Notificación de listeners
5. Edge cases

---

## ✅ Checklist Completado

- [x] gossip_mock_data.dart (7 tests) ✅
- [x] supabase_config.dart (6 tests) ✅
- [x] theme_extensions.dart (17 tests) ✅
- [x] locale_notifier.dart (16 tests) ✅
- [x] Todos los tests pasando ✅
- [x] Fix deprecations (Color.value) ✅
- [x] Documentación de sesión ✅

---

## 🚀 Próximos Pasos

### Sesión 5 - Opciones Recomendadas

1. **Data Models (Fácil)** ⭐
   - `location_model.dart`
   - `city_model.dart`
   - `region_model.dart`
   - ~150 líneas, tests simples de serialización

2. **Domain Entities (Fácil)** ⭐
   - Entities sin tests
   - Agregar equality tests
   - Agregar copyWith tests

3. **Error Handling (Medio)**
   - `error_handler.dart`
   - `failure.dart`
   - Tests de conversión de errores

---

## 📝 Notas Finales

### Lo Bueno ✅
- Archivos simples, tests rápidos
- 100% passing rate
- Buenos ejemplos de patterns (ChangeNotifier, Extensions)

### Lo Mejorable 🔄
- Coverage incremental bajo (archivos pequeños)
- `supabase_config` solo 50% coverage (aceptable)

### Tiempo Invertido
- **Desarrollo:** ~35 min
- **Documentación:** ~10 min
- **Total:** ~45 min

---

**Sesión completada exitosamente! 🎉**

46 tests nuevos, 100% passing, 4 archivos cubiertos.
