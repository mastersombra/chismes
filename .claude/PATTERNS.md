# Design Patterns - Chismes App

> **Patrones de diseño usados en el proyecto.** Referencia completa de implementación.

**Última actualización:** 2026-10-20

---

## 📋 Índice

1. [Repository Pattern](#repository-pattern)
2. [Result Pattern](#result-pattern)
3. [Dependency Injection](#dependency-injection)
4. [Data Source Pattern](#data-source-pattern)
5. [Controller Pattern](#controller-pattern)

---

## 1. Repository Pattern

### Concepto

El Repository actúa como intermediario entre Domain y Data layers:
- **Domain** define la interfaz (contrato)
- **Data** implementa la lógica de acceso a datos
- **Presentation** consume la interfaz (no conoce la implementación)

### Estructura

```dart
// Domain Layer: Define la interfaz
// features/gossip/domain/repositories/gossip_repository.dart
abstract class GossipRepository {
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);
  Future<Result<Failure, Gossip>> create(CreateGossipInput input);
  Future<Result<Failure, Gossip>> getById(String id);
  Future<Result<Failure, void>> update(String id, UpdateGossipInput input);
  Future<Result<Failure, void>> delete(String id);
}
```

```dart
// Data Layer: Implementa
// features/gossip/data/repositories/gossip_repository_impl.dart
@Singleton(as: GossipRepository)
class GossipRepositoryImpl implements GossipRepository {
  final GossipRemoteDataSource remoteDataSource;
  final GossipLocalDataSource localDataSource;
  final AppLogger _logger;
  
  GossipRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this._logger,
  );
  
  // Cache strategy: write-through, fallback on error
  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    try {
      // 1. Try remote
      _logger.d('Fetching gossips from remote', context: {'query': query.toString()});
      final remoteModels = await remoteDataSource.getGossips(query);
      
      // 2. Save to cache (write-through)
      await localDataSource.saveAll(remoteModels);
      _logger.d('Saved ${remoteModels.length} gossips to cache');
      
      // 3. Convert to entities
      final entities = remoteModels.map((m) => m.toEntity()).toList();
      return Result.success(entities);
      
    } catch (error, stackTrace) {
      _logger.w('Remote fetch failed, trying cache', error: error);
      
      // 3. Fallback to cache
      try {
        final localModels = await localDataSource.getAll();
        final entities = localModels.map((m) => m.toEntity()).toList();
        return Result.success(entities);
      } catch (cacheError) {
        _logger.e('Cache fallback failed', error: cacheError, stackTrace: stackTrace);
        return Result.failure(ErrorHandler.handleError(error));
      }
    }
  }
  
  @override
  Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
    try {
      _logger.i('Creating gossip', context: {'cityId': input.cityId});
      final model = await remoteDataSource.create(input);
      
      // Save to cache
      await localDataSource.save(model);
      
      _logger.i('Gossip created successfully', context: {'id': model.id});
      return Result.success(model.toEntity());
      
    } catch (error, stackTrace) {
      _logger.e('Failed to create gossip', error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error));
    }
  }
}
```

### Reglas

- ✅ Repository SIEMPRE retorna `Result<Failure, Success>`
- ✅ Repository NUNCA lanza excepciones (captura y convierte a Failure)
- ✅ Repository maneja cache strategy (write-through, fallback)
- ✅ Repository convierte Models → Entities
- ✅ Repository loguea operaciones importantes
- ❌ Repository NO contiene lógica de negocio (eso es Domain)
- ❌ Repository NO conoce UI (eso es Presentation)

---

## 2. Result Pattern (Monadic Error Handling)

### Concepto

**NUNCA lanzar excepciones desde repositories/use cases.** Usar `Result<Failure, Success>` para error handling explícito.

### Implementación

```dart
// core/result/result.dart
sealed class Result<F extends Failure, S> {
  const Result();
  
  factory Result.success(S value) = Success<F, S>;
  factory Result.failure(F failure) = Failed<F, S>;
  
  bool get isSuccess => this is Success<F, S>;
  bool get isFailure => this is Failed<F, S>;
  
  S? get successValue => isSuccess ? (this as Success<F, S>).value : null;
  F? get failureValue => isFailure ? (this as Failed<F, S>).failure : null;
  
  R fold<R>({
    required R Function(F failure) onFailure,
    required R Function(S success) onSuccess,
  }) {
    if (this is Success<F, S>) {
      return onSuccess((this as Success<F, S>).value);
    } else {
      return onFailure((this as Failed<F, S>).failure);
    }
  }
}

final class Success<F extends Failure, S> extends Result<F, S> {
  final S value;
  const Success(this.value);
}

final class Failed<F extends Failure, S> extends Result<F, S> {
  final F failure;
  const Failed(this.failure);
}
```

### Uso

```dart
// ❌ MAL: Lanzar excepciones
Future<Gossip> create(CreateGossipInput input) async {
  final gossip = await remoteDataSource.create(input);
  return gossip;  // Si falla, lanza excepción no controlada
}

// ✅ BIEN: Retornar Result
Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
  try {
    final model = await remoteDataSource.create(input);
    return Result.success(model.toEntity());
  } catch (error, stackTrace) {
    _logger.e('Create failed', error: error, stackTrace: stackTrace);
    return Result.failure(ErrorHandler.handleError(error));
  }
}

// Uso en controllers
final result = await repository.create(input);
result.fold(
  onFailure: (failure) {
    _setState(state.copyWith(failure: failure));
    _logger.e('Error creating gossip', context: {'failure': failure.message});
  },
  onSuccess: (gossip) {
    _setState(state.copyWith(gossip: gossip));
    _logger.i('Gossip created', context: {'id': gossip.id});
  },
);
```

### Ventajas

- ✅ Errores explícitos en la firma del método
- ✅ Compilador fuerza el manejo de errores
- ✅ Type-safe error handling
- ✅ No hay excepciones silenciosas
- ✅ Flujo de control claro

### Desventajas

- ⚠️ Más verboso que try-catch tradicional
- ⚠️ Requiere disciplina del equipo

---

## 3. Dependency Injection (Injectable + GetIt)

### Concepto

Usamos **Injectable** (code generation) + **GetIt** (service locator) para DI puro, sin acoplamiento a widgets.

### Setup

```dart
// core/di/injection.dart
final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();
```

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await configureDependencies();  // ← Setup DI
  
  runApp(MyApp());
}
```

### Anotaciones

```dart
// Registro automático (transient)
@injectable
class MyService {
  final Dependency dependency;
  MyService(this.dependency);
}

// Singleton
@singleton
class MySingleton {
  // Una sola instancia en toda la app
}

// Lazy Singleton (se crea al primer uso)
@lazySingleton
class MyLazySingleton {}

// Interfaces
@Singleton(as: MyInterface)
class MyImplementation implements MyInterface {}

// Factory con parámetros
@injectable
class MyFactory {
  @factoryMethod
  static MyFactory create(Dependency dep) => MyFactory._(dep);
  
  final Dependency _dep;
  MyFactory._(this._dep);
}
```

### Uso

```dart
// Obtener instancia
final service = getIt<MyService>();

// En controllers (auto-injection)
@injectable
class AddGossipController extends ChangeNotifier {
  final CreateGossip _createGossip;  // ← Inyectado automáticamente
  final LocationService _locationService;
  final AppLogger _logger;
  
  AddGossipController(
    this._createGossip,
    this._locationService,
    this._logger,
  );
}

// En widgets
final controller = getIt<AddGossipController>();
```

### Regenerar DI

```bash
# Después de agregar/modificar @injectable
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (regenera automáticamente)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Reglas

- ✅ Usar @injectable para servicios transient
- ✅ Usar @singleton para servicios globales únicos
- ✅ Registrar interfaces: `@Singleton(as: Interface)`
- ✅ Regenerar después de cambios
- ❌ NO usar GetIt directamente en widgets de UI (excepto root)
- ❌ NO crear dependencias circulares

---

## 4. Data Source Pattern

### Concepto

Data Sources son la capa más baja de Data Layer:
- **RemoteDataSource:** Acceso a APIs externas (Supabase, REST, etc.)
- **LocalDataSource:** Cache local (SharedPreferences, Hive, SQLite)
- **MockDataSource:** Solo para tests/desarrollo

### Estructura

```dart
// Interface
abstract class GossipRemoteDataSource {
  Future<List<GossipModel>> getGossips(GossipQuery query);
  Future<GossipModel> create(CreateGossipInput input);
  Future<GossipModel> getById(String id);
  Future<void> update(String id, UpdateGossipInput input);
  Future<void> delete(String id);
}

// Implementación Producción
@Singleton(as: GossipRemoteDataSource)
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
  final SupabaseClient _client;
  final AppLogger _logger;
  
  SupabaseGossipRemoteDataSource(this._client, this._logger);
  
  @override
  Future<List<GossipModel>> getGossips(GossipQuery query) async {
    try {
      final response = await _client
          .from('gossips')
          .select('*')
          .eq('city_id', query.cityId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => GossipModel.fromJson(json))
          .toList();
    } catch (error) {
      _logger.e('Supabase fetch failed', error: error);
      rethrow;  // ← Repository lo captura y convierte a Result
    }
  }
}

// Implementación Tests/Desarrollo (NO registrada en producción)
class MockGossipRemoteDataSource implements GossipRemoteDataSource {
  final List<GossipModel> _mockData = [];
  
  @override
  Future<List<GossipModel>> getGossips(GossipQuery query) async {
    await Future.delayed(Duration(milliseconds: 500));  // Simular latencia
    return _mockData.where((g) => g.cityId == query.cityId).toList();
  }
  
  @override
  Future<GossipModel> create(CreateGossipInput input) async {
    final model = GossipModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      // ...
    );
    _mockData.add(model);
    return model;
  }
}
```

### Local Data Source (Cache)

```dart
abstract class GossipLocalDataSource {
  Future<List<GossipModel>> getAll();
  Future<void> save(GossipModel model);
  Future<void> saveAll(List<GossipModel> models);
  Future<void> clear();
}

@Singleton(as: GossipLocalDataSource)
class SharedPrefsGossipLocalDataSource implements GossipLocalDataSource {
  final SharedPreferences _prefs;
  final AppLogger _logger;
  
  static const _key = 'gossips_cache';
  static const _maxCacheSize = 100;
  
  @override
  Future<List<GossipModel>> getAll() async {
    final json = _prefs.getString(_key);
    if (json == null) return [];
    
    final List<dynamic> list = jsonDecode(json);
    return list.map((item) => GossipModel.fromJson(item)).toList();
  }
  
  @override
  Future<void> saveAll(List<GossipModel> models) async {
    // Limitar a max 100 gossips
    final toCache = models.take(_maxCacheSize).toList();
    final json = jsonEncode(toCache.map((m) => m.toJson()).toList());
    await _prefs.setString(_key, json);
  }
}
```

### Reglas

- ✅ Data Sources pueden lanzar excepciones (Repository las captura)
- ✅ Data Sources trabajan con Models (DTOs), NO Entities
- ✅ Remote debe tener timeout configurado
- ✅ Local debe ser rápido (in-memory o simple key-value)
- ✅ Mock solo para tests (NO registrar en DI de producción)
- ❌ Data Sources NO retornan Result (eso es Repository)
- ❌ Data Sources NO convierten Models → Entities

---

## 5. Controller Pattern (Presentation)

### Concepto

Controllers en Presentation layer:
- Manejan estado de UI
- Coordinan Use Cases
- Convierten Failures → UI feedback
- Emiten estados con `notifyListeners()`

### Estructura

```dart
// State Model (inmutable)
@immutable
class AddGossipState extends Equatable {
  final bool isLoading;
  final Gossip? gossip;
  final Failure? failure;
  final String? successMessage;
  
  const AddGossipState({
    this.isLoading = false,
    this.gossip,
    this.failure,
    this.successMessage,
  });
  
  factory AddGossipState.initial() => const AddGossipState();
  
  AddGossipState copyWith({
    bool? isLoading,
    Gossip? gossip,
    Failure? failure,
    String? successMessage,
  }) {
    return AddGossipState(
      isLoading: isLoading ?? this.isLoading,
      gossip: gossip ?? this.gossip,
      failure: failure ?? this.failure,
      successMessage: successMessage ?? this.successMessage,
    );
  }
  
  @override
  List<Object?> get props => [isLoading, gossip, failure, successMessage];
}
```

```dart
// Controller
@injectable
class AddGossipController extends ChangeNotifier {
  final CreateGossip _createGossip;
  final LocationService _locationService;
  final AppLogger _logger;
  
  AddGossipController(
    this._createGossip,
    this._locationService,
    this._logger,
  );
  
  AddGossipState _state = AddGossipState.initial();
  
  AddGossipState get state => _state;
  
  void _setState(AddGossipState newState) {
    _state = newState;
    notifyListeners();
  }
  
  Future<void> createGossip(CreateGossipInput input) async {
    _setState(state.copyWith(isLoading: true, failure: null));
    _logger.i('Creating gossip', context: {'cityId': input.cityId});
    
    final result = await _createGossip(input);
    
    result.fold(
      onFailure: (failure) {
        _setState(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        _logger.e('Create failed', context: {'message': failure.message});
      },
      onSuccess: (gossip) {
        _setState(state.copyWith(
          isLoading: false,
          gossip: gossip,
          successMessage: 'Chisme publicado exitosamente',
        ));
        _logger.i('Create success', context: {'id': gossip.id});
      },
    );
  }
  
  void clearError() {
    _setState(state.copyWith(failure: null));
  }
  
  @override
  void dispose() {
    _logger.d('AddGossipController disposed');
    super.dispose();
  }
}
```

### Uso en Widgets

```dart
class AddGossipScreen extends StatefulWidget {
  @override
  State<AddGossipScreen> createState() => _AddGossipScreenState();
}

class _AddGossipScreenState extends State<AddGossipScreen> {
  late final AddGossipController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = getIt<AddGossipController>();
    _controller.addListener(_onStateChanged);
  }
  
  void _onStateChanged() {
    final state = _controller.state;
    
    if (state.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.failure!.message)),
      );
    }
    
    if (state.successMessage != null) {
      Navigator.of(context).pop(state.gossip);
    }
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        
        if (state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        return Form(/* ... */);
      },
    );
  }
}
```

### Reglas

- ✅ Controllers usan ChangeNotifier (simple, built-in)
- ✅ State es inmutable (Equatable)
- ✅ `_setState()` privado, emite con `notifyListeners()`
- ✅ Controllers loguean operaciones importantes
- ✅ Dispose del controller en widget
- ❌ Controllers NO acceden a repositories directamente (usar Use Cases)
- ❌ Controllers NO contienen lógica de negocio
- ❌ NO exponer setters públicos de estado

---

## 📚 Referencias

- **Clean Architecture:** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Result Type:** https://dart.dev/guides/language/language-tour#generics
- **Injectable:** https://pub.dev/packages/injectable
- **GetIt:** https://pub.dev/packages/get_it

---

**Última actualización:** 2026-10-20  
**Mantenedor:** Alejo
