# Plan de Mejora de Cobertura de Tests

**Objetivo:** Aumentar cobertura de 53.0% a >90%  
**Fecha:** 2026-11-12  
**Estado actual:** 3,884 / 7,322 líneas (53.0%)  
**Meta:** 6,590 líneas (90%)  
**Gap:** 2,706 líneas adicionales  

---

## 📊 Resumen Ejecutivo

### Estado Actual

| Métrica | Valor |
|---------|-------|
| **Cobertura Global** | 53.0% |
| **Líneas Cubiertas** | 3,884 / 7,322 |
| **Archivos Totales** | 148 archivos |
| **Archivos de Test** | 101 tests |
| **Tests Ejecutados** | ~2,500 tests |

### Distribución de Cobertura

| Rango | Cantidad | Líneas |
|-------|----------|--------|
| **Sin cobertura (0%)** | 41 archivos | 2,062 líneas |
| **Baja cobertura (<50%)** | 18 archivos | - |
| **Media cobertura (50-80%)** | 17 archivos | - |
| **Alta cobertura (>80%)** | 72 archivos | - |

### Cobertura por Feature

| Feature | Cobertura | Estado | Prioridad |
|---------|-----------|--------|-----------|
| **gossip** | 87.5% (1600/1828) | ✅ Excelente | Mantenimiento |
| **location** | 81.4% (301/370) | ✅ Buena | Completar |
| **auth** | 51.8% (831/1604) | 🟡 Media | **Alta** |
| **search** | 68.9% (164/238) | 🟡 Media | Media |
| **home** | 10.8% (86/800) | 🔴 Crítica | **Muy Alta** |
| **profile** | 4.6% (30/651) | 🔴 Crítica | **Muy Alta** |

---

## 🎯 Estrategia de 3 Fases

### Resumen del Plan

| Fase | Descripción | Líneas | % del Total | Sesiones Est. |
|------|-------------|--------|-------------|---------------|
| **Fase 1** | Alto impacto - Archivos críticos sin tests | 1,668 | 22.8% | 3-4 sesiones |
| **Fase 2** | Impacto medio - Mejorar cobertura existente | 457 | 6.2% | 2 sesiones |
| **Fase 3** | Completar cobertura - Low-hanging fruit | 851 | 11.6% | 2-3 sesiones |
| **TOTAL** | | **2,976** | **40.7%** | **7-9 sesiones** |

**Cobertura proyectada:** 93.7% ✅ (supera el objetivo del 90%)

---

## 📋 FASE 1: Alto Impacto (Archivos Críticos Sin Tests)

**Objetivo:** 1,668 líneas (~22.8% del total)  
**Duración estimada:** 3-4 sesiones

### Prioridad 1: Features Home y Profile (Crítico)

#### 1.1 Home Feature Controllers (191 líneas)

| Archivo | Líneas | Complejidad | Sesión |
|---------|--------|-------------|--------|
| `following_tab_controller.dart` | 99 | Media | 1 |
| `popular_tab_controller.dart` | 92 | Media | 1 |

**Tipo de tests necesarios:**
- ✅ Unit tests para controllers
- ✅ State management tests
- ✅ Mock de repositories
- ✅ Tests de paginación y scroll

**Archivos relacionados que necesitan tests:**
- `following_tab.dart` (84 líneas, 1.2% cobertura)
- `following_tab_state.dart` (55 líneas, 1.8% cobertura)
- `popular_tab_state.dart` (55 líneas, 7.3% cobertura)

**Ejemplo de estructura esperada:**
```dart
// test/features/home/presentation/controllers/following_tab_controller_test.dart
group('FollowingTabController', () {
  late FollowingTabController controller;
  late MockGetFollowingFeed mockGetFollowingFeed;
  
  setUp(() {
    mockGetFollowingFeed = MockGetFollowingFeed();
    controller = FollowingTabController(mockGetFollowingFeed);
  });
  
  group('loadInitialGossips', () {
    test('debe cargar gossips iniciales exitosamente', () async { });
    test('debe manejar errores correctamente', () async { });
  });
  
  group('loadMoreGossips', () {
    test('debe cargar más gossips con paginación', () async { });
    test('no debe cargar si ya está cargando', () async { });
  });
});
```

#### 1.2 Profile Feature (263 líneas)

| Archivo | Líneas | Complejidad | Sesión |
|---------|--------|-------------|--------|
| `profile_controller.dart` | 83 | Media | 1 |
| `profile_header.dart` | 69 | Baja | 2 |
| `settings_section.dart` | 175 | Alta | 2 |
| `profile_stats_card.dart` | 47 | Baja | 2 |

**Tipo de tests necesarios:**
- ✅ Unit tests para ProfileController
- ✅ Widget tests para componentes UI
- ✅ Tests de navegación
- ✅ Tests de actualización de settings

#### 1.3 Auth Feature Screens (335 líneas)

| Archivo | Líneas | Complejidad | Sesión |
|---------|--------|-------------|--------|
| `otp_verification_screen.dart` | 116 | Alta | 2 |
| `otp_verification_controller.dart` | 51 | Media | 2 |
| `reset_password_screen.dart` | 84 | Media | 3 |

**Tipo de tests necesarios:**
- ✅ Widget tests para screens
- ✅ Integration tests para flujos completos
- ✅ Tests de validación de formularios
- ✅ Tests de navegación entre pantallas

**Nota importante:** Ya existen muchos tests de auth (26 archivos), estos completan los faltantes.

#### 1.4 Data Layer (419 líneas)

| Archivo | Líneas | Complejidad | Sesión |
|---------|--------|-------------|--------|
| `supabase_auth_datasource_impl.dart` | 201 | Alta | 3 |
| `home_remote_datasource.dart` | 63 | Media | 3 |
| `feed_gossip_model.dart` | 55 | Baja | 3 |
| `profile_settings_model.dart` | 53 | Baja | 3 |
| `supabase_location_remote_data_source.dart` | 47 | Media | 4 |

**Tipo de tests necesarios:**
- ✅ Unit tests con mocks de Supabase
- ✅ Tests de serialización/deserialización
- ✅ Tests de error handling
- ✅ Tests de transformación Model → Entity

#### 1.5 Otros Archivos (460 líneas)

| Archivo | Líneas | Notas | Sesión |
|---------|--------|-------|--------|
| `app_localizations_en.dart` | 433 | Generado automáticamente | - |

**Nota:** Los archivos de localización son generados automáticamente. No priorizar a menos que sea crítico.

---

## 📋 FASE 2: Impacto Medio (Mejorar Cobertura Existente)

**Objetivo:** 457 líneas adicionales (~6.2% del total)  
**Duración estimada:** 2 sesiones

### Prioridad: Archivos con tests parciales

| Archivo | Cobertura Actual | Gap | Complejidad | Sesión |
|---------|------------------|-----|-------------|--------|
| `following_tab.dart` | 1.2% | +83 | Media | 5 |
| `deep_link_service.dart` | 9.9% | +64 | Alta | 5 |
| `following_tab_state.dart` | 1.8% | +54 | Baja | 5 |
| `popular_tab_state.dart` | 7.3% | +51 | Baja | 5 |
| `device_info_provider.dart` | 20.8% | +38 | Media | 6 |
| `auth_service.dart` | 24.4% | +31 | Media | 6 |
| `feed_gossip.dart` | 3.4% | +28 | Baja | 6 |
| `supabase_storage_service.dart` | 29.6% | +19 | Media | 6 |

**Estrategia:**
- ✅ Revisar tests existentes
- ✅ Identificar casos edge no cubiertos
- ✅ Agregar tests para branches no ejecutados
- ✅ Completar tests de error handling

**Ejemplo - Completar coverage de `auth_service.dart`:**
```dart
// Revisar qué ramas no están cubiertas
// Agregar tests para:
- Error handling de Supabase exceptions
- Edge cases de tokens expirados
- Refresh token logic
- Session persistence
```

---

## 📋 FASE 3: Completar Cobertura (Low-Hanging Fruit)

**Objetivo:** 851 líneas adicionales (~11.6% del total)  
**Duración estimada:** 2-3 sesiones

### Top 10 Archivos Más Fáciles

| Archivo | Cobertura | Gap | Esfuerzo | Sesión |
|---------|-----------|-----|----------|--------|
| `app_localizations_es.dart` | 47.1% | +229 | Bajo | - |
| `search_screen.dart` | 68.9% | +74 | Bajo | 7 |
| `supabase_gossip_remote_data_source.dart` | 54.6% | +64 | Medio | 7 |
| `profile_screen.dart` | 30.4% | +64 | Medio | 7 |
| `location_change_dialog.dart` | 63.0% | +47 | Bajo | 7 |
| `auth_repository_impl.dart` | 74.5% | +41 | Bajo | 8 |
| `gossip_card.dart` | 51.8% | +41 | Bajo | 8 |
| `popular_tab.dart` | 31.0% | +40 | Medio | 8 |
| `login_screen.dart` | 64.9% | +39 | Bajo | 8 |
| `user_model.dart` | 40.3% | +37 | Bajo | 8 |

**Estrategia:**
- ✅ Archivos ya tienen estructura de tests
- ✅ Solo completar casos faltantes
- ✅ Focus en cobertura de branches
- ✅ Tests de error handling simples

---

## 🔧 Recomendaciones Técnicas

### 1. Patrones de Testing por Capa

#### Data Layer (Repositories & DataSources)
```dart
// Pattern: Mock de Supabase client
group('RepositoryImpl', () {
  late Repository repository;
  late MockSupabaseClient mockSupabase;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  
  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    repository = RepositoryImpl(mockRemote, mockLocal);
  });
  
  test('debe retornar datos de remote cuando local falla', () async {
    // Arrange: Mock local failure, remote success
    // Act: Call repository
    // Assert: Verify remote called, result is success
  });
});
```

#### Domain Layer (UseCases)
```dart
// Pattern: Mock de Repository
group('UseCase', () {
  late UseCase useCase;
  late MockRepository mockRepository;
  
  setUp(() {
    mockRepository = MockRepository();
    useCase = UseCase(mockRepository);
  });
  
  test('debe ejecutar lógica de negocio correctamente', () async {
    // Arrange: Mock repository response
    // Act: Execute usecase
    // Assert: Verify business logic
  });
});
```

#### Presentation Layer (Controllers)
```dart
// Pattern: Mock de UseCases + State verification
group('Controller', () {
  late Controller controller;
  late MockUseCase mockUseCase;
  
  setUp(() {
    mockUseCase = MockUseCase();
    controller = Controller(mockUseCase);
  });
  
  test('debe actualizar estado correctamente', () async {
    // Arrange: Mock usecase
    // Act: Call controller method
    // Assert: Verify state changes
    expect(controller.state, isA<LoadingState>());
  });
});
```

#### Presentation Layer (Widgets)
```dart
// Pattern: Widget testing con MaterialApp
testWidgets('debe renderizar correctamente', (tester) async {
  // Arrange: Build widget tree
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(param: value),
    ),
  );
  
  // Act: Interact with widget
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Assert: Verify UI
  expect(find.text('Expected Text'), findsOneWidget);
});
```

### 2. Testing de Archivos Problemáticos

#### Controllers con State Management
```dart
// Verificar múltiples transiciones de estado
test('debe transicionar entre estados correctamente', () async {
  final states = <State>[];
  controller.addListener(() {
    states.add(controller.state);
  });
  
  await controller.load();
  
  expect(states, [
    isA<LoadingState>(),
    isA<SuccessState>(),
  ]);
});
```

#### Screens con Formularios
```dart
// Testing de validación de formularios
testWidgets('debe validar formulario correctamente', (tester) async {
  await tester.pumpWidget(createTestApp(MyScreen()));
  
  // Submit con datos vacíos
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  // Verificar mensajes de error
  expect(find.text('Campo requerido'), findsWidgets);
});
```

#### DataSources con Supabase
```dart
// Mock de Supabase client
test('debe manejar errores de Supabase correctamente', () async {
  // Arrange
  when(mockSupabase.from('table').select())
    .thenThrow(PostgrestException(message: 'Error'));
  
  // Act
  final result = await dataSource.getData();
  
  // Assert
  expect(result.isFailure, isTrue);
  expect(result.failure, isA<ServerFailure>());
});
```

### 3. Archivos que NO Necesitan Tests

Los siguientes archivos pueden tener baja prioridad o no necesitar tests:

- ✅ **Generated files:** `*.g.dart`, `*.freezed.dart`
- ✅ **Localization:** `app_localizations_*.dart` (generados)
- ✅ **Theme constants:** `app_spacing.dart`, `app_radius.dart`
- ✅ **Simple value objects:** Entities con solo getters
- ✅ **DI modules:** `injection_container.dart` (ya testeado indirectamente)

### 4. Archivos que SÍ Necesitan Tests Urgentes

| Categoría | Archivos | Razón |
|-----------|----------|-------|
| **Controllers** | `following_tab_controller.dart`, `popular_tab_controller.dart`, `profile_controller.dart` | Lógica de negocio crítica |
| **DataSources** | `supabase_auth_datasource_impl.dart`, `home_remote_datasource.dart` | Integración con backend |
| **Screens** | `otp_verification_screen.dart`, `reset_password_screen.dart` | Flujos de usuario críticos |
| **Services** | `deep_link_service.dart`, `auth_service.dart` | Servicios core |

---

## 📝 Checklist por Sesión

### Sesión 1: Home Controllers
- [ ] `following_tab_controller.dart` tests
- [ ] `popular_tab_controller.dart` tests
- [ ] Mock de `GetFollowingFeed` y `GetPopularFeed`
- [ ] Tests de paginación y scroll
- [ ] Tests de refresh

### Sesión 2: Profile & Auth Screens
- [ ] `profile_controller.dart` tests
- [ ] `otp_verification_screen.dart` widget tests
- [ ] `otp_verification_controller.dart` tests
- [ ] `profile_header.dart` widget tests
- [ ] `settings_section.dart` widget tests

### Sesión 3: Data Layer & Auth
- [ ] `supabase_auth_datasource_impl.dart` tests
- [ ] `home_remote_datasource.dart` tests
- [ ] `feed_gossip_model.dart` tests
- [ ] `profile_settings_model.dart` tests
- [ ] `reset_password_screen.dart` widget tests

### Sesión 4: Data Layer Completion
- [ ] `supabase_location_remote_data_source.dart` tests
- [ ] Completar tests de models faltantes
- [ ] Tests de serialización/deserialización

### Sesión 5: Completar Coverage - Tabs & Services
- [ ] Completar `following_tab.dart` tests
- [ ] Completar `following_tab_state.dart` tests
- [ ] Completar `popular_tab_state.dart` tests
- [ ] Completar `deep_link_service.dart` tests

### Sesión 6: Completar Coverage - Core Services
- [ ] Completar `device_info_provider.dart` tests
- [ ] Completar `auth_service.dart` tests
- [ ] Completar `feed_gossip.dart` tests
- [ ] Completar `supabase_storage_service.dart` tests

### Sesión 7: Low-Hanging Fruit (Parte 1)
- [ ] Completar `search_screen.dart` tests
- [ ] Completar `supabase_gossip_remote_data_source.dart` tests
- [ ] Completar `profile_screen.dart` tests
- [ ] Completar `location_change_dialog.dart` tests

### Sesión 8: Low-Hanging Fruit (Parte 2)
- [ ] Completar `auth_repository_impl.dart` tests
- [ ] Completar `gossip_card.dart` tests
- [ ] Completar `popular_tab.dart` tests
- [ ] Completar `login_screen.dart` tests
- [ ] Completar `user_model.dart` tests

---

## 🎯 Métricas de Éxito

### Por Sesión

Después de cada sesión, verificar:
```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

| Sesión | Cobertura Esperada | Incremento |
|--------|-------------------|------------|
| Inicial | 53.0% | - |
| Sesión 1 | 55.6% | +2.6% |
| Sesión 2 | 60.1% | +4.5% |
| Sesión 3 | 65.8% | +5.7% |
| Sesión 4 | 68.4% | +2.6% |
| Sesión 5 | 74.7% | +6.3% |
| Sesión 6 | 80.9% | +6.2% |
| Sesión 7 | 86.5% | +5.6% |
| Sesión 8 | 93.7% | +7.2% |

### Por Feature

| Feature | Actual | Meta | Gap |
|---------|--------|------|-----|
| gossip | 87.5% | 90%+ | +2.5% |
| location | 81.4% | 90%+ | +8.6% |
| auth | 51.8% | 90%+ | +38.2% |
| search | 68.9% | 90%+ | +21.1% |
| home | 10.8% | 90%+ | +79.2% |
| profile | 4.6% | 90%+ | +85.4% |

---

## 🚀 Comandos Útiles

### Generar Coverage
```bash
# Ejecutar tests con cobertura
flutter test --coverage

# Ver resumen
lcov --summary coverage/lcov.info

# Generar HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Analizar Coverage por Feature
```bash
# Coverage de una feature específica
lcov --extract coverage/lcov.info 'lib/features/home/*' -o coverage/home.info
lcov --summary coverage/home.info
```

### Tests Específicos
```bash
# Ejecutar tests de una feature
flutter test test/features/home

# Ejecutar un archivo específico
flutter test test/features/home/presentation/controllers/following_tab_controller_test.dart

# Watch mode
flutter test --watch
```

---

## 📚 Referencias

### Documentación del Proyecto
- [CLAUDE.md](../CLAUDE.md) - Guía principal
- [TESTING.md](../.claude/TESTING.md) - Standards de testing
- [PATTERNS.md](../.claude/PATTERNS.md) - Patrones arquitectónicos
- [ARCHITECTURE.md](../.claude/ARCHITECTURE.md) - Arquitectura del proyecto

### Testing Resources
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget)
- [Integration Testing](https://flutter.dev/docs/cookbook/testing/integration)

---

## 🎓 Lecciones Aprendidas

### Lo que funciona bien
- ✅ **gossip feature** tiene excelente cobertura (87.5%) - usar como referencia
- ✅ **location feature** tiene buena estructura de tests
- ✅ Pattern AAA (Arrange-Act-Assert) está bien establecido
- ✅ Uso consistente de Mockito para mocks

### Áreas de mejora
- ⚠️ **home** y **profile** features están muy por debajo
- ⚠️ Controllers de tabs no tienen tests
- ⚠️ Algunas screens importantes sin widget tests
- ⚠️ DataSources de Supabase sin tests completos

### Recomendaciones
1. **Mantener** los standards de gossip feature
2. **Priorizar** tests de business logic (controllers, use cases)
3. **Automatizar** verificación de coverage en CI/CD
4. **Establecer** cobertura mínima de 80% para nuevas features
5. **Revisar** coverage en cada PR

---

## 📞 Siguientes Pasos

### Inmediato (Esta Semana)
1. ✅ Revisar este documento con el equipo
2. ✅ Comenzar Sesión 1: Home Controllers
3. ✅ Configurar CI para verificar coverage mínimo

### Corto Plazo (2 Semanas)
1. Completar Fases 1 y 2
2. Alcanzar 80% de cobertura global
3. Implementar gate de coverage en CI

### Mediano Plazo (1 Mes)
1. Completar Fase 3
2. Alcanzar 90%+ de cobertura
3. Establecer proceso de mantenimiento

---

**Última actualización:** 2026-11-12  
**Autor:** Claude Code  
**Versión:** 1.0
