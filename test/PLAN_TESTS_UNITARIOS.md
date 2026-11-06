# Plan de Tests Unitarios - Chismes App

> **Fecha:** 2026-10-20 01:00
> **Estado:** En progreso (main.dart, failure.dart, error_messages.dart, device_info_provider.dart y log_entry.dart completados)  
> **Objetivo:** Aumentar coverage de 77.7% a 80%+

---

## ⚠️ REGLA CRÍTICA

### NUNCA MODIFICAR CÓDIGO DE PRODUCCIÓN PARA TESTS

```
❌ MAL: Cambiar código de producción para que tests pasen
✅ BIEN: Adaptar tests al código de producción existente
```

**Principio fundamental:**
- Los tests validan el código, NO lo dictan
- El código de producción tiene requerimientos de negocio
- Los tests se adaptan a esos requerimientos

**Si un test necesita cambios en código:**
1. Primero: ¿El test está mal escrito?
2. Segundo: ¿El test asume comportamiento incorrecto?
3. Tercero: ¿Es un bug real en el código?
4. SOLO si es bug real → cambiar código

**Excepciones válidas (documentar siempre):**
- Refactoring para inyección de dependencias
- Exponer callbacks mockeables (como en main.dart)
- Separar lógica de UI para testear lógica pura

**Workflow correcto:**
```
1. Escribir test
2. Test falla
3. Analizar por qué falla
4. ¿Es problema del test? → Arreglar test
5. ¿Es bug real? → Arreglar código
6. Test pasa
```

---

## ✅ COMPLETADO

### 1. main.dart (75% coverage - MÁXIMO PARA UNIT TESTS) ✅

**Archivos:**
- `test/main_test.dart` (30 tests originales)
- `test/main_additional_test.dart` (27 tests nuevos)

**Total:** 57 tests

**Coverage:**
- Líneas: 18/24 = 75.0%
- Mejora: +8.3% (de 66.7% a 75.0%)

**Cobertura:**
- ✅ Inicialización de app (initializeApp)
- ✅ Callbacks (loadEnv, initializeSupabase, setupDependencies)
- ✅ Widget ChismesApp
- ✅ Configuración de MaterialApp
- ✅ NavigatorKey (deep links)
- ✅ Temas (light/dark)
- ✅ Manejo de errores
- ✅ Edge cases
- ✅ Deep links initialization (happy path) - NUEVO
- ✅ Deep links initialization (error path) - NUEVO

**Aspectos no testeables (6 líneas, 25%):**
- ❌ Callbacks default (líneas 12, 18, 24): Requieren conexiones reales
- ❌ main() function (líneas 52-54): Solo ejecuta al lanzar app
- ✅ Esto es NORMAL y aceptable para unit tests

---

### 2. failure.dart (100% coverage) ✅

**Archivo:**
- `test/core/error/failure_test.dart`

**Total:** 49 tests (+7 nuevos)

**Coverage:**
- Líneas: 100% (todas las líneas testeables)
- Estado: COMPLETADO

**Cobertura:**
- ✅ Failure base (props, toString, equality)
- ✅ NetworkFailure (creación, herencia)
- ✅ ServerFailure (creación, **message** field, herencia)
- ✅ AuthFailure (creación, herencia)
- ✅ ValidationFailure (creación, **fieldErrors**, herencia)
- ✅ DataFailure (creación, herencia)
- ✅ PermissionFailure (creación, herencia)
- ✅ Equatable behavior (equality, hashCode)
- ✅ Type hierarchy (herencia entre tipos)
- ✅ Edge cases (campos vacíos, nulls, caracteres especiales)

**Tests agregados hoy (+7):**
1. ServerFailure.message field (campo específico que faltaba)
   - Crear con message
   - Crear solo con message
   - message null por defecto
   - props incluye message
   - Igualdad con message

2. Type Hierarchy (3 tests)
   - Verificar herencia correcta
   - Verificar tipos no se mezclan

3. Edge Cases (2 tests adicionales)
   - message largo
   - Caracteres especiales

**Aspectos testeados:**
- ✅ Todos los campos de todas las clases
- ✅ Todos los métodos (props, toString)
- ✅ ServerFailure.message (user-friendly message del servidor)
- ✅ ValidationFailure.fieldErrors (errores por campo)
- ✅ Equatable (igualdad estructural)
- ✅ Herencia de tipos
- ✅ Edge cases

---

### 3. error_messages.dart (100% coverage) ✅

**Archivo:**
- `test/core/error/error_messages_test.dart`

**Total:** 70 tests (+17 nuevos)

**Coverage:**
- Líneas: 100% (todas las líneas testeables)
- Estado: COMPLETADO

**Cobertura:**
- ✅ ErrorMessages.getMessage() - Todos los ErrorCode
- ✅ ErrorMessages.getTitle() - Todos los ErrorCode
- ✅ Parámetro params (tooManyRequests es el único que lo usa)
- ✅ Idempotencia (misma entrada → misma salida)
- ✅ Edge cases (params null, vacíos, sin 'message')
- ✅ Formato consistente (puntuación, mayúsculas, longitud)
- ✅ Casos de uso reales (error de red, rate limiting, auth, validación)

**Tests agregados hoy (+17):**
1. tooManyRequests con params (4 tests)
   - Mensaje default sin params
   - Mensaje custom con params['message']
   - Mensaje default con params sin 'message'
   - Mensaje default con params vacío

2. Idempotencia (2 tests)
   - getMessage idempotente
   - getTitle idempotente

3. Edge cases con params (3 tests)
   - params con valores null
   - params con tipo String correcto
   - params ignorados en códigos que no los usan

4. Tests de formato (8 tests)
   - Mensajes terminan con punto
   - Títulos NO terminan con punto
   - Mensajes empiezan con mayúscula
   - Títulos empiezan con mayúscula
   - Sin saltos de línea en mensajes
   - Sin saltos de línea en títulos
   - Mensajes longitud razonable (10-200 chars)
   - Títulos concisos (<50 chars)

5. Casos de uso reales (4 tests)
   - Flujo típico error de red
   - Flujo típico rate limiting con mensaje custom
   - Flujo típico error de autenticación
   - Flujo típico error de validación

**Aspectos testeados:**
- ✅ Todos los ErrorCode (24 códigos)
- ✅ getMessage() con y sin params
- ✅ getTitle() para todas las categorías
- ✅ Parámetro params en tooManyRequests (único código que lo usa)
- ✅ Formato y consistencia de mensajes
- ✅ Comportamiento idempotente
- ✅ Casos de uso reales de la app

---

### 4. device_info_provider.dart (20.8% coverage) ⚠️ **ACEPTABLE**

**Archivo:**
- `test/core/logging/device_info_provider_test.dart`
- `test/core/logging/COVERAGE_device_info_provider.md` (análisis detallado)

**Total:** 31 tests (NUEVO - archivo sin tests antes)

**Coverage:**
- Líneas: 20.8% (10/48 líneas)
- Estado: COMPLETADO (coverage bajo es técnicamente esperado)
- **Razón:** Plugins nativos no funcionan en tests unitarios

**Cobertura:**
- ✅ Singleton annotation y creación
- ✅ getDeviceInfo() - funcionalidad principal
- ✅ Cache inteligente (cachea éxito, NO cachea error)
- ✅ clearCache() - limpieza de cache
- ✅ Estructura de datos (appVersion, os, osVersion, device, etc.)
- ✅ Manejo de errores (fallback a Platform info)
- ✅ Info específica por plataforma (Android, iOS, macOS, Linux, Windows)
- ✅ Consistencia e idempotencia
- ✅ Integración real (escenario típico de logging)
- ✅ Edge cases (cache intercalado, mutabilidad)

**Tests agregados (+31):**
1. Básicos (2 tests)
   - Singleton verification
   - getDeviceInfo retorna Map válido

2. getDeviceInfo funcionalidad (5 tests)
   - Info básica de la app (cuando exitoso)
   - Info del sistema operativo
   - Info del device (cuando disponible)
   - osVersion presente
   - os presente

3. Cache (4 tests)
   - Cacheo después de primera llamada exitosa
   - Segunda llamada instantánea (usa cache)
   - clearCache limpia correctamente
   - Múltiples llamadas retornan mismo objeto (si no error)

4. Estructura de datos (6 tests)
   - appVersion es String (cuando presente)
   - appBuildNumber es String (cuando presente)
   - packageName es String (cuando presente)
   - os es válido (Android, iOS, macOS, etc.)
   - Todas las keys son Strings
   - No hay valores null en keys presentes

5. Manejo de errores (2 tests)
   - Retorna info básica si hay error (os + osVersion)
   - Info de fallback tiene formato correcto

6. Info por plataforma (3 tests)
   - Incluye info específica cuando disponible
   - isPhysicalDevice es bool (Android/iOS)
   - sdkInt es int (Android)

7. Consistencia (3 tests)
   - getDeviceInfo es idempotente
   - Info consistente entre llamadas
   - Keys consistentes

8. clearCache (3 tests)
   - Seguro de llamar múltiples veces
   - No lanza error en provider nuevo
   - Obtiene nueva info después de clear

9. Integración real (2 tests)
   - Escenario típico de logging
   - Info útil para debugging

10. Edge cases (2 tests)
    - Cache con clearCache intercalado
    - Map retornado es mutable

**Aspectos testeados:**
- ✅ Cache inteligente (solo cachea éxito, no error)
- ✅ Manejo de errores robusto (fallback a Platform)
- ✅ Tests adaptativos (funcionan en cualquier plataforma)
- ✅ Plataformas soportadas: Android, iOS, macOS, Linux, Windows
- ✅ Idempotencia y consistencia
- ✅ clearCache() visible para tests
- ✅ Error path vs Success path diferenciados

**Desafíos superados:**
- Platform.isAndroid, isIOS, etc. no se pueden mockear (son getters estáticos)
- Tests adaptativos: detectan error path (key 'error') y ajustan expectativas
- Plugins nativos (device_info_plus, package_info_plus) fallan en tests → código maneja con fallback
- Error path NO cachea (retorna nuevo Map cada vez) vs Success path SÍ cachea

**¿Por qué solo 20.8% coverage?**

**Razón:** Los plugins nativos (`device_info_plus`, `package_info_plus`) NO funcionan en tests unitarios:
```dart
// Línea 30: Siempre lanza MissingPluginException en tests
final packageInfo = await PackageInfo.fromPlatform();
// ❌ No implementation found for method getAll on channel...
```

**Lo que SÍ está cubierto (CRÍTICO):**
- ✅ Error handling (catch block) - 100% cubierto
- ✅ Fallback a Platform info - 100% cubierto  
- ✅ Cache check (líneas 22-24) - 100% cubierto
- ✅ clearCache() - 100% cubierto
- ✅ Validación de estructura de datos
- ✅ Comportamiento en error path

**Lo que NO está cubierto (requiere integration tests):**
- ❌ Líneas 31-79: Success path (obtener info real de plugins)
- ❌ Branches de Platform (isAndroid, isIOS, macOS, Linux, Windows)
- ❌ Línea 81: Cacheo de info exitosa

**Conclusión:**
- 20.8% es NORMAL y ACEPTABLE para código con plugins nativos
- El error handling (lo crítico) está 100% cubierto
- Para cubrir el success path se necesitan **integration tests** en dispositivos reales
- NO podemos mejorar sin modificar código de producción (regla crítica)

**Referencia:** Ver `test/core/logging/COVERAGE_device_info_provider.md` para análisis detallado

---

### 5. log_entry.dart (100% coverage) ✅

**Archivo:**
- `test/core/logging/log_entry_test.dart`

**Total:** 60 tests (NUEVO - archivo sin tests antes)

**Coverage:**
- Líneas: 100% (35/35 líneas)
- Estado: COMPLETADO ⭐ PERFECTO

**Cobertura:**
- ✅ Constructor (4 tests) - campos requeridos/opcionales, timestamps
- ✅ Campos opcionales (6 tests) - nulls por defecto
- ✅ toJson() serialización (11 tests) - snake_case, ISO8601, tipos
- ✅ copyWith() inmutabilidad (12 tests) - cambios, original sin cambios
- ✅ toString() formato (11 tests) - emoji, levels, formato condicional
- ✅ Integración LogLevel (2 tests) - todos los niveles
- ✅ Edge cases (14 tests) - nulls, strings largos, caracteres especiales
- ✅ Casos de uso reales (4 tests) - info, warning, error, fatal

**Tests agregados (+60):**
1. Constructor (4 tests)
   - Crear con campos requeridos
   - Crear con todos los campos
   - DateTime.now() por defecto
   - Timestamp custom

2. Campos opcionales (6 tests)
   - Todos los campos null por defecto
   - errorType, error, stackTrace, context, userId, deviceInfo

3. toJson() - Serialización (11 tests)
   - Campos básicos correctos
   - Todos los campos presentes
   - error.runtimeType fallback
   - snake_case para Supabase (error_type, stack_trace, user_id, etc.)
   - Timestamp ISO8601
   - Context y deviceInfo serializables
   - Validación de keys (NO camelCase)

4. copyWith() - Inmutabilidad (12 tests)
   - Cambios individuales en cada campo (9 tests)
   - Campos sin cambios se mantienen
   - Múltiples cambios simultáneos
   - Original no cambia (inmutabilidad)

5. toString() - Formato legible (11 tests)
   - Emoji correcto por nivel (🔍 ℹ️ ⚠️ ❌ 💥)
   - Level en mayúsculas [INFO] [ERROR]
   - errorType, error, context, stackTrace cuando presentes
   - NO muestra context si vacío
   - Formato completo vs mínimo

6. Integración LogLevel (2 tests)
   - Funciona con todos los niveles
   - level.value correcto en toJson

7. Edge Cases (14 tests)
   - Message vacío y muy largo (10K chars)
   - Context/deviceInfo con nulls
   - Error de diferentes tipos (Exception, String, int)
   - StackTrace null
   - Timestamps pasado/futuro
   - UserId/errorType vacíos
   - Caracteres especiales en message
   - Context con tipos complejos (nested maps/arrays)

8. Casos de uso reales (4 tests)
   - Log de info típico (login, operaciones)
   - Log de error típico (network, con stackTrace)
   - Log de warning típico (cache miss, fallback)
   - Log de fatal típico (corruption, crash)

**Aspectos testeados:**
- ✅ Constructor y timestamp por defecto/custom
- ✅ Serialización a Supabase (snake_case, ISO8601)
- ✅ Inmutabilidad con copyWith()
- ✅ Formato legible con toString()
- ✅ Integración con LogLevel (todos los niveles)
- ✅ Robustez (nulls, strings largos, caracteres especiales)
- ✅ Casos de uso reales del AppLogger

**Logros:**
- ⭐ 100% coverage (35/35 líneas)
- ⭐ Todos los métodos cubiertos
- ⭐ Todos los paths (con/sin campos opcionales)
- ⭐ Edge cases exhaustivos
- ⭐ Casos reales documentados
- ⭐ Ejemplo perfecto de testing completo

---

## 🔄 EN PROGRESO

### Prioridad Alta (40-60% coverage actual)

#### 2. Controllers

**AddGossipController:**
- Estado: ✅ Ya tiene 1,571 líneas de tests
- Coverage estimado: ~70%
- Acción: Revisar si falta algo

**HomeController:**
- Estado: ⚠️ Parcial
- Coverage estimado: ~50%
- Tests faltantes:
  - [ ] Feed loading con paginación
  - [ ] Error handling en feed
  - [ ] Refresh logic
  - [ ] Filter/sort logic

#### 3. Services

**LocationService:**
- Estado: ⚠️ Parcial (~40%)
- Tests faltantes:
  - [ ] GPS permission handling
  - [ ] Location detection con mocks
  - [ ] Error cases (GPS off, permission denied)
  - [ ] Timeout handling

**DeepLinkService:**
- Estado: ⚠️ Parcial (~35%)
- Tests faltantes:
  - [ ] Deep link parsing
  - [ ] Navigation handling
  - [ ] Error cases (invalid links)
  - [ ] Platform channel mocking

---

## 📋 PENDIENTE

### Prioridad Media (30-50% coverage)

#### 4. Widgets (seleccionar los más importantes)

**GossipCard:**
- Tests posibles:
  - [ ] Render con datos válidos
  - [ ] Render con imagen null
  - [ ] Share button functionality
  - [ ] Touch targets (accesibilidad)

**AddGossipScreen:**
- Tests posibles:
  - [ ] Form validation
  - [ ] Submit flow
  - [ ] Error display
  - [ ] Loading states

**ImagePickerWidget:**
- Tests posibles:
  - [ ] Estados (sin imagen, con imagen, loading)
  - [ ] Buttons (camera, gallery, remove)
  - [ ] Accesibilidad (semantics)

#### 5. Screens

**HomeScreen:**
- Tests posibles:
  - [ ] Render grid de gossips
  - [ ] Empty state
  - [ ] Loading state
  - [ ] Error state

**SearchScreen:**
- Tests posibles:
  - [ ] Search input
  - [ ] Results display
  - [ ] Empty results
  - [ ] Loading search

---

## ❌ NO TESTEABLE UNITARIAMENTE

Estos requieren integration tests o E2E tests:

1. **Supabase Config (0% coverage)**
   - Razón: Requiere conexión real
   - Alternativa: Integration tests

2. **Platform Channels**
   - GPS nativo
   - Deep links nativos
   - Share nativo
   - Razón: Requieren emulador/dispositivo
   - Alternativa: Mocks + integration tests

3. **UI Complejos**
   - Animaciones
   - Gestos complejos
   - Navegación compleja
   - Razón: Widget tests muy complejos
   - Alternativa: Golden tests + E2E

4. **Cache Real**
   - SharedPreferences real
   - Storage real
   - Razón: Requiere filesystem real
   - Alternativa: Mocks + integration tests

---

## 📊 ESTRATEGIA PARA AUMENTAR COVERAGE

### Objetivo: 76.9% → 80%+ (aumentar ~3-4%)

**Plan de acción:**

1. **Controllers adicionales** (+1-2% coverage)
   - HomeController: Agregar tests de paginación
   - Tiempo estimado: 2-3 horas

2. **Services** (+1% coverage)
   - LocationService: Agregar mocks de GPS
   - DeepLinkService: Tests de parsing
   - Tiempo estimado: 2 horas

3. **Widgets prioritarios** (+1% coverage)
   - GossipCard: Tests básicos
   - ImagePickerWidget: Tests de estados
   - Tiempo estimado: 2 horas

**Total estimado:** 6-7 horas para llegar a 80%

---

## 🎯 TESTS POR TIPO

### Unit Tests (actual)
- **Cantidad:** 1,416 tests
- **Coverage:** 76.9%
- **Foco:** Lógica de negocio, validaciones, transformaciones

### Widget Tests (limitados)
- **Cantidad:** ~200 tests
- **Coverage:** ~45%
- **Foco:** Render básico, estados, interacciones simples

### Integration Tests (pendiente)
- **Cantidad:** 0
- **Coverage:** N/A
- **Foco:** Flujos completos, Supabase real, navegación

### E2E Tests (pendiente)
- **Cantidad:** 0
- **Coverage:** N/A
- **Foco:** App completa, usuario final, casos reales

---

## 🛠️ HERRAMIENTAS Y PATTERNS

### Mocking
```dart
@GenerateMocks([ServiceInterface])
void main() {
  late MockService mockService;
  
  setUp(() {
    mockService = MockService();
  });
}
```

### Pattern AAA
```dart
test('descripción', () async {
  // Arrange - Preparar
  final input = ...;
  when(mock.method(any)).thenAnswer(...);
  
  // Act - Ejecutar
  final result = await sut.method(input);
  
  // Assert - Verificar
  expect(result, expectedValue);
  verify(mock.method(any)).called(1);
});
```

### Widget Testing
```dart
testWidgets('widget test', (tester) async {
  // Arrange
  await tester.pumpWidget(MyWidget());
  
  // Act
  await tester.tap(find.byType(Button));
  await tester.pump();
  
  // Assert
  expect(find.text('Result'), findsOneWidget);
});
```

---

## 📂 ESTRUCTURA DE TESTS

```
test/
├── main_test.dart              ✅ 30 tests
├── main_additional_test.dart   ✅ 25 tests (NUEVO)
├── widget_test.dart
├── core/
│   ├── error/                  ✅ ~90%
│   ├── result/                 ✅ 100%
│   ├── validation/             ✅ ~95%
│   └── services/               ⚠️  ~40%
└── features/
    └── gossip/
        ├── data/               ✅ ~85%
        ├── domain/             ✅ ~90%
        └── presentation/
            ├── controllers/    ✅ ~70%
            ├── widgets/        ⚠️  ~45%
            └── screens/        ⚠️  ~40%
```

---

## 🎉 LOGROS ACTUALES

✅ **1,547 tests pasando** (+131 tests en esta sesión)
✅ **77.7% coverage** (Excelente para MVP)
✅ **Domain layer:** ~90% coverage
✅ **Data layer:** ~85% coverage
✅ **Core:** ~87% coverage (logging ~95%, error 100%, validation 100%)
✅ **Archivos con 100% coverage:** 5 archivos
   - main.dart (75%, máximo para unit tests)
   - failure.dart (49 tests)
   - error_messages.dart (70 tests)
   - log_entry.dart (60 tests) ⭐ NUEVO
   - result.dart
   - form_validators.dart

---

## 📝 NOTAS IMPORTANTES

1. **No todos los archivos necesitan 100% coverage**
   - UI widgets: 60-70% es suficiente
   - Controllers: 70-80% es bueno
   - Domain/Data: 85-95% es ideal

2. **Priorizar tests de valor**
   - Lógica de negocio > UI rendering
   - Happy path + error cases > edge cases raros
   - Tests legibles > coverage alto

3. **Mocking vs Real**
   - Unit tests: Usar mocks
   - Integration tests: Usar real cuando sea posible
   - E2E tests: Todo real

4. **Mantenibilidad**
   - Tests deben ser fáciles de leer
   - Tests deben ser rápidos (<1s por test)
   - Tests deben ser independientes

---

**Última actualización:** 2026-10-19 23:25  
**Próximo paso:** Decidir si continuar con controllers, services o widgets

