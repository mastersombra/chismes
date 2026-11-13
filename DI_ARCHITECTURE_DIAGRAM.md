# 🏗️ Arquitectura DI - Diagrama Visual

## 📐 Arquitectura Actual

```
┌─────────────────────────────────────────────────────────────┐
│                    CONFIGURACIÓN DI                          │
│  lib/core/di/injection_container.dart                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  final getIt = GetIt.instance;                              │
│                                                              │
│  @InjectableInit()                                           │
│  Future<void> configureDependencies() async {               │
│    // Registros manuales (async/externos)                   │
│    getIt.registerSingleton<SharedPreferences>(...);         │
│    getIt.registerSingleton<GlobalKey>(...);                 │
│                                                              │
│    // Registros automáticos (Injectable)                    │
│    $initGetIt(getIt);  ← Generado por build_runner         │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│               MÓDULOS DE REGISTRO                            │
│  lib/features/gossip/di/gossip_module.dart                  │
├─────────────────────────────────────────────────────────────┤
│  @module                                                     │
│  abstract class GossipModule {                              │
│    @lazySingleton                                            │
│    SupabaseClient get supabaseClient                        │
│      => Supabase.instance.client;  ← UNA SOLA VEZ          │
│                                                              │
│    @singleton                                                │
│    MvpModerationPolicy get moderationPolicy                 │
│      => const MvpModerationPolicy();                        │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  CAPAS CON @injectable                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📱 PRESENTATION (Controllers)                               │
│  @injectable                                                 │
│  class SignupController extends ChangeNotifier {            │
│    final SignUpWithEmail _useCase;  ← Inyectado            │
│    SignupController(this._useCase);                         │
│  }                                                           │
│                                                              │
│  ───────────────────────────────────────────────────────    │
│                                                              │
│  🎯 DOMAIN (Use Cases)                                       │
│  @injectable                                                 │
│  class SignUpWithEmail {                                    │
│    final AuthRepository _repo;  ← Inyectado                │
│    SignUpWithEmail(this._repo);                             │
│  }                                                           │
│                                                              │
│  ───────────────────────────────────────────────────────────│
│                                                              │
│  💾 DATA (Repositories)                                      │
│  @Singleton(as: AuthRepository)  ← Registra como interface │
│  class AuthRepositoryImpl implements AuthRepository {       │
│    final AuthDataSource _dataSource;  ← Inyectado          │
│    AuthRepositoryImpl(this._dataSource);                    │
│  }                                                           │
│                                                              │
│  ───────────────────────────────────────────────────────────│
│                                                              │
│  🔌 DATA (Data Sources)                                      │
│  @Singleton(as: AuthDataSource)  ← Registra como interface │
│  class SupabaseAuthDataSource implements AuthDataSource {  │
│    final SupabaseClient _supabase;  ← Inyectado            │
│    SupabaseAuthDataSource(this._supabase);                  │
│  }                                                           │
│                                                              │
│  ───────────────────────────────────────────────────────────│
│                                                              │
│  🛠️ CORE (Services)                                          │
│  @singleton                                                  │
│  class AuthService {                                        │
│    final AuthRepository _repo;  ← Inyectado                │
│    final SupabaseClient _supabase;  ← Inyectado            │
│    final AppLogger _logger;  ← Inyectado                   │
│    AuthService(this._repo, this._supabase, this._logger);  │
│  }                                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  CONSUMO EN SCREENS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  class _SignupScreenState extends State<SignupScreen> {    │
│                                                              │
│    late SignupController _controller;                       │
│                                                              │
│    @override                                                 │
│    void initState() {                                        │
│      super.initState();                                      │
│      _controller = getIt<SignupController>();  ← GetIt     │
│      _controller.addListener(_onStateChanged);  ← Manual   │
│    }                                                         │
│                                                              │
│    @override                                                 │
│    Widget build(BuildContext context) {                     │
│      return ChangeNotifierProvider.value(  ← Provider      │
│        value: _controller,                                   │
│        child: Consumer<SignupController>(  ← Consumer      │
│          builder: (context, controller, _) {                │
│            // UI rebuild reactivo                            │
│          },                                                  │
│        ),                                                    │
│      );                                                      │
│    }                                                         │
│  }                                                           │
│                                                              │
│  ⚠️ PATRÓN MIXTO: 3 mecanismos                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Dependencias

```
Supabase.instance.client  (Singleton externo)
         │
         ↓
    [GossipModule]  (@lazySingleton)
         │
         ↓
   SupabaseClient  (Registrado 1 vez en GetIt)
         │
         ├──→ SupabaseAuthDataSource
         ├──→ SupabaseGossipRemoteDataSource
         ├──→ SupabaseLocationRepository
         ├──→ SupabaseStorageService
         ├──→ SupabaseRemoteLogger
         └──→ AuthService
```

**✅ Correcta:** Una sola instancia compartida por todos.

---

## 🎯 Patrón de Registro

### Servicios
```dart
@singleton
class AuthService { ... }
```
**Una instancia** para toda la app.

### Repositories (Implementación)
```dart
@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository { ... }
```
**Registrada como interface**, permite mockear en tests.

### Use Cases
```dart
@injectable
class SignUpWithEmail { ... }
```
**Nueva instancia** cada vez que se solicita.

### Controllers
```dart
@injectable
class SignupController extends ChangeNotifier { ... }
```
**Nueva instancia + ChangeNotifier** para reactivity.

---

## ⚠️ Problema Actual: Consumo Mixto

```
┌─────────────────────────────────────────────────────┐
│  SCREEN OBTIENE CONTROLLER                          │
│  _controller = getIt<SignupController>()            │
│                    │                                 │
│  ┌─────────────────┼─────────────────┐             │
│  │                 │                 │             │
│  ▼                 ▼                 ▼             │
│ GetIt         addListener      Provider           │
│ (Instancia)   (Manual)          (Reactivo)        │
│                                                     │
│  ⚠️ 3 mecanismos para state management             │
└─────────────────────────────────────────────────────┘
```

### ¿Por qué es confuso?

1. **GetIt** → Obtención de instancia (DI)
2. **addListener** → Escuchar cambios manualmente
3. **ChangeNotifierProvider** → Pasar al árbol de widgets
4. **Consumer** → Rebuild reactivo

**4 pasos cuando 2 bastarían.**

---

## ✅ Solución Propuesta

### Opción A: setState (Simple)

```
┌────────────────────────────────────┐
│  SCREEN OBTIENE CONTROLLER         │
│  _controller = getIt<Controller>() │
│           │                         │
│           ↓                         │
│  _controller.addListener(          │
│    () => setState(() {})           │
│  )                                  │
│           │                         │
│           ↓                         │
│  build() accede a _controller      │
│  directamente                       │
│                                     │
│  ✅ 2 pasos, sin Provider          │
└────────────────────────────────────┘
```

### Opción B: AnimatedBuilder (Granular)

```
┌────────────────────────────────────┐
│  SCREEN OBTIENE CONTROLLER         │
│  _controller = getIt<Controller>() │
│           │                         │
│           ↓                         │
│  AnimatedBuilder(                  │
│    animation: _controller,         │
│    builder: (context, child) {     │
│      // Solo esto se reconstruye   │
│    }                                │
│  )                                  │
│                                     │
│  ✅ 2 pasos, rebuild granular      │
└────────────────────────────────────┘
```

---

## 📊 Comparación de Patrones

| Aspecto | Actual | Opción A | Opción B |
|---------|--------|----------|----------|
| **Mecanismos** | 3 | 1 | 1 |
| **Complejidad** | Alta | Baja | Media |
| **Rebuild** | Granular | Full widget | Granular |
| **Dependencias** | GetIt + Provider | GetIt | GetIt |
| **Curva aprendizaje** | Alta | Baja | Media |
| **Testeable** | ✅ | ✅ | ✅ |

---

## 🎯 Recomendación Final

**SIMPLIFICAR** con Opción A o B:
- ✅ Elimina ChangeNotifierProvider
- ✅ Elimina Consumer
- ✅ Usa solo GetIt
- ✅ Menos dependencias
- ✅ Más directo

**Esfuerzo:** 1-2 horas para 4 screens  
**Beneficio:** Arquitectura más simple y clara

---

**Generado:** 2026-11-13  
**Ver también:** 
- `DI_ARCHITECTURE_AUDIT_REPORT.md` (completo)
- `DI_AUDIT_EXECUTIVE_SUMMARY.md` (resumen)
