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
6. [Value Objects (DDD)](#6-value-objects-ddd)
7. [Factory Pattern](#7-factory-pattern)
8. [Observer Pattern](#8-observer-pattern)

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

## 6. Value Objects (DDD)

### Concepto

**Value Objects** son objetos inmutables sin identidad propia, definidos únicamente por sus atributos.

**Diferencia clave con Entities:**

| Aspecto | Entity | Value Object |
|---------|--------|--------------|
| **Identidad** | Tiene ID único | Sin ID |
| **Mutabilidad** | Puede cambiar | Inmutable |
| **Igualdad** | Por ID | Por atributos |
| **Lifecycle** | Propio | Parte de Entity |

---

### ✅ Value Objects en Chismes

#### Ejemplo 1: ReportReason

**Location:** `features/gossip/domain/entities/report_reason.dart`

```dart
/// Value Object: Razón de reporte
/// 
/// Sin ID, inmutable, definido por sus valores.
/// Dos ReportReason con mismo tipo/descripción son iguales.
@immutable
class ReportReason extends Equatable {
  final ReportReasonType type;
  final String description;
  
  const ReportReason({
    required this.type,
    required this.description,
  });
  
  @override
  List<Object?> get props => [type, description];
  
  // Value Objects pueden tener factory methods
  factory ReportReason.inappropriateContent() => const ReportReason(
    type: ReportReasonType.inappropriateContent,
    description: 'Contenido inapropiado u ofensivo',
  );
  
  factory ReportReason.spam() => const ReportReason(
    type: ReportReasonType.spam,
    description: 'Spam o publicidad no deseada',
  );
}

enum ReportReasonType {
  inappropriateContent,
  spam,
  falseInformation,
  harassment,
  other,
}
```

**Por qué es Value Object:**
- ✅ No tiene ID
- ✅ Inmutable (`@immutable`, campos `final`)
- ✅ Igualdad por valor (Equatable compara atributos)
- ✅ Parte de `Gossip` (no existe independientemente)

---

#### Ejemplo 2: Location (Candidato)

**Current Location:** `lib/core/services/location_service.dart` (Position)

```dart
/// Value Object: Coordenadas geográficas
/// 
/// Sin ID, inmutable, representado por lat/lng.
/// Dos locations con mismas coordenadas son iguales.
@immutable
class Location extends Equatable {
  final double latitude;
  final double longitude;
  
  const Location({
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [latitude, longitude];
  
  // Value Objects pueden tener métodos de dominio
  double distanceTo(Location other) {
    // Cálculo de distancia Haversine
    // ...
  }
  
  bool isWithinRadius(Location center, double radiusKm) {
    return distanceTo(center) <= radiusKm;
  }
  
  // Factory methods útiles
  factory Location.zero() => const Location(latitude: 0, longitude: 0);
  
  factory Location.fromGeoPoint(GeoPoint point) => Location(
    latitude: point.latitude,
    longitude: point.longitude,
  );
}
```

**Por qué es Value Object:**
- ✅ No tiene ID
- ✅ Inmutable
- ✅ Igualdad por valor (dos coordenadas iguales = misma location)
- ✅ Puede tener lógica de dominio (`distanceTo`)

---

#### Ejemplo 3: GossipQuery (Candidato)

**Location:** `features/gossip/domain/entities/gossip_query.dart`

```dart
/// Value Object: Query para buscar gossips
/// 
/// Sin ID, inmutable, representa criterios de búsqueda.
@immutable
class GossipQuery extends Equatable {
  final String? countryId;
  final String? regionId;
  final String? cityId;
  final GossipStatus? status;
  final ModerationStatus? moderationStatus;
  final int limit;
  final int offset;
  
  const GossipQuery({
    this.countryId,
    this.regionId,
    this.cityId,
    this.status,
    this.moderationStatus,
    this.limit = 20,
    this.offset = 0,
  });
  
  @override
  List<Object?> get props => [
    countryId,
    regionId,
    cityId,
    status,
    moderationStatus,
    limit,
    offset,
  ];
  
  // Factory methods para queries comunes
  factory GossipQuery.defaultPublic() => const GossipQuery(
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
  );
  
  factory GossipQuery.byCity(String cityId) => GossipQuery(
    cityId: cityId,
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
  );
  
  // CopyWith para modificar query
  GossipQuery copyWith({
    String? countryId,
    String? regionId,
    String? cityId,
    GossipStatus? status,
    ModerationStatus? moderationStatus,
    int? limit,
    int? offset,
  }) {
    return GossipQuery(
      countryId: countryId ?? this.countryId,
      regionId: regionId ?? this.regionId,
      cityId: cityId ?? this.cityId,
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
```

**Por qué es Value Object:**
- ✅ No tiene ID
- ✅ Inmutable (con `copyWith` para crear nuevas instancias)
- ✅ Igualdad por valor
- ✅ Representa un concepto del dominio (criterio de búsqueda)

---

### ❌ NO es Value Object: Gossip

**Location:** `features/gossip/domain/entities/gossip.dart`

```dart
/// Entity: Gossip
/// 
/// Tiene ID único, tiene lifecycle propio.
/// Dos gossips con mismo contenido pero diferente ID son DIFERENTES.
class Gossip extends Equatable {
  final String id; // ← Identidad única
  final String subject;
  final String content;
  // ... más campos
  
  @override
  List<Object?> get props => [
    id, // ← ID en props
    subject,
    content,
    // ...
  ];
}
```

**Por qué NO es Value Object:**
- ❌ Tiene `id` → Es **Entity**
- ❌ Dos gossips con mismo contenido pero diferente ID son distintos
- ❌ Tiene lifecycle propio (creado, modificado, eliminado)

---

### Cuándo Usar Value Objects

✅ **SÍ usar Value Object cuando:**

- No necesita ID único
- Inmutable por naturaleza
- Igualdad definida por atributos
- Parte de otra Entity
- Representa concepto simple del dominio

**Ejemplos:**
- Coordenadas (lat/lng)
- Dirección postal
- Rango de fechas
- Color RGB
- Dinero (monto + moneda)
- Email, Teléfono

❌ **NO usar Value Object cuando:**

- Necesita ID único
- Tiene lifecycle propio
- Puede cambiar en el tiempo
- Se persiste independientemente

**Ejemplos:**
- Usuario (tiene ID, lifecycle)
- Gossip (tiene ID, lifecycle)
- Comentario (tiene ID, puede ser eliminado)

---

### Reglas para Value Objects

#### 1. Inmutabilidad

```dart
// ✅ BIEN: Inmutable
@immutable
class Money extends Equatable {
  final double amount;
  final String currency;
  
  const Money(this.amount, this.currency);
  
  // Para modificar, retorna NUEVA instancia
  Money add(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies');
    }
    return Money(amount + other.amount, currency);
  }
}

// ❌ MAL: Mutable
class Money {
  double amount;
  String currency;
  
  void add(Money other) {
    amount += other.amount; // ❌ Modifica estado
  }
}
```

#### 2. Igualdad por Valor

```dart
// ✅ BIEN: Equatable compara por valor
@immutable
class Location extends Equatable {
  final double latitude;
  final double longitude;
  
  const Location(this.latitude, this.longitude);
  
  @override
  List<Object?> get props => [latitude, longitude];
}

// Uso
final loc1 = Location(40.7128, -74.0060);
final loc2 = Location(40.7128, -74.0060);
print(loc1 == loc2); // ✅ true (mismo valor)

// ❌ MAL: Sin Equatable
class Location {
  final double latitude;
  final double longitude;
  
  const Location(this.latitude, this.longitude);
}

// Uso
final loc1 = Location(40.7128, -74.0060);
final loc2 = Location(40.7128, -74.0060);
print(loc1 == loc2); // ❌ false (referencias distintas)
```

#### 3. Sin ID

```dart
// ✅ BIEN: Value Object sin ID
@immutable
class ReportReason extends Equatable {
  final ReportReasonType type;
  final String description;
  
  const ReportReason({required this.type, required this.description});
  
  @override
  List<Object?> get props => [type, description];
}

// ❌ MAL: Con ID → es Entity
class ReportReason extends Equatable {
  final String id; // ❌ Tiene ID
  final ReportReasonType type;
  final String description;
  
  @override
  List<Object?> get props => [id, type, description];
}
```

#### 4. Validación en Constructor

```dart
// ✅ BIEN: Validación en constructor
@immutable
class Email extends Equatable {
  final String value;
  
  const Email._(this.value);
  
  // Factory con validación
  factory Email(String value) {
    if (!_isValid(value)) {
      throw ArgumentError('Invalid email: $value');
    }
    return Email._(value);
  }
  
  static bool _isValid(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }
  
  @override
  List<Object?> get props => [value];
}

// Uso
final email = Email('user@example.com'); // ✅ OK
final invalid = Email('invalid'); // ❌ Lanza ArgumentError
```

---

### Checklist Value Objects

Al escribir una clase de dominio:

```
[ ] ¿Necesita ID único? → NO (Value Object) / SÍ (Entity)
[ ] ¿Es inmutable? → SÍ (Value Object) / NO (revisar diseño)
[ ] ¿Igualdad por valor? → SÍ (Value Object + Equatable)
[ ] ¿Parte de otra Entity? → SÍ (probablemente Value Object)
[ ] ¿Lifecycle propio? → NO (Value Object) / SÍ (Entity)
```

---

### Ejemplos Adicionales (Futuro)

#### Money (si se agrega pricing)

```dart
@immutable
class Money extends Equatable {
  final double amount;
  final String currency;
  
  const Money(this.amount, this.currency);
  
  Money add(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies');
    }
    return Money(amount + other.amount, currency);
  }
  
  Money multiply(double factor) {
    return Money(amount * factor, currency);
  }
  
  @override
  List<Object?> get props => [amount, currency];
  
  @override
  String toString() => '$amount $currency';
}
```

#### DateRange (si se agregan filtros temporales)

```dart
@immutable
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;
  
  const DateRange({required this.start, required this.end});
  
  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }
  
  bool overlaps(DateRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }
  
  @override
  List<Object?> get props => [start, end];
}
```

---

## 7. Factory Pattern

### Concepto

**Factory Pattern** crea objetos sin especificar la clase exacta.

Un método factory decide qué instancia concreta retornar basado en parámetros o lógica.

---

### ✅ Factory Pattern en Chismes

#### Ejemplo 1: ErrorHandler (Factory Method)

**Location:** `core/error/error_handler.dart`

```dart
/// Factory Method: Convierte excepciones en Failures
class ErrorHandler {
  ErrorHandler._(); // Constructor privado (clase estática)

  /// Factory method que retorna diferentes tipos de Failure
  /// basado en el tipo de error recibido
  static Failure handleError(dynamic error, [StackTrace? stackTrace]) {
    // Factory decide qué tipo de Failure crear
    
    if (error is AppException) {
      return _exceptionToFailure(error);
    }

    if (error is Failure) {
      return error; // Ya es Failure
    }

    // Network errors
    if (error is SocketException) {
      return const NetworkFailure(
        code: ErrorCode.noInternetConnection,
      );
    }

    // HTTP errors
    if (error is HttpException) {
      return ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: error.message,
      );
    }

    // Validation errors
    if (error is FormatException) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: error.message,
      );
    }

    // Supabase errors
    if (error is supabase.AuthException) {
      return _handleAuthException(error);
    }

    if (error is supabase.PostgrestException) {
      return _handlePostgrestException(error);
    }

    if (error is supabase.StorageException) {
      return _handleStorageException(error);
    }

    // Default: Failure genérico
    return Failure(
      code: ErrorCode.unknownError,
      technicalMessage: error.toString(),
    );
  }

  // Helper factories específicos
  static Failure _handleAuthException(supabase.AuthException error) {
    switch (error.statusCode) {
      case '400':
        if (error.message.contains('invalid login credentials')) {
          return const AuthFailure(code: ErrorCode.invalidCredentials);
        }
        return ValidationFailure(
          code: ErrorCode.badRequest,
          technicalMessage: error.message,
        );
      
      case '401':
        return AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: error.message,
        );
      
      case '403':
        return PermissionFailure(
          code: ErrorCode.forbidden,
          technicalMessage: error.message,
        );
      
      default:
        return AuthFailure(
          code: ErrorCode.unknownError,
          technicalMessage: error.message,
        );
    }
  }

  // Más helper factories...
}
```

**Por qué es Factory Pattern:**
- ✅ Método estático que crea objetos
- ✅ Decide qué tipo concreto retornar basado en input
- ✅ Consumidor no necesita saber qué Failure específico se crea
- ✅ Centraliza lógica de creación

**Uso:**

```dart
// Repository
try {
  final data = await _remote.getData();
  return Result.success(data);
} catch (error, stackTrace) {
  // Factory decide qué Failure crear
  final failure = ErrorHandler.handleError(error, stackTrace);
  return Result.failure(failure);
}
```

---

#### Ejemplo 2: GossipQuery Factory Methods

**Location:** `features/gossip/domain/entities/gossip_query.dart`

```dart
/// Value Object con factory methods
class GossipQuery extends Equatable {
  final String? countryId;
  final String? cityId;
  final GossipStatus? status;
  final ModerationStatus? moderationStatus;
  final int limit;
  
  const GossipQuery({...});
  
  /// Factory method: Query por defecto para feed público
  factory GossipQuery.defaultPublic() => const GossipQuery(
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
    limit: 20,
  );
  
  /// Factory method: Query por ciudad específica
  factory GossipQuery.byCity(String cityId) => GossipQuery(
    cityId: cityId,
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
    limit: 20,
  );
  
  /// Factory method: Query para trending nacional
  factory GossipQuery.trendingNational() => const GossipQuery(
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
    limit: 50, // Más resultados para trending
  );
}

// Uso
final query = GossipQuery.defaultPublic(); // ← Factory method
final result = await repository.getGossips(query);
```

---

#### Ejemplo 3: ReportReason Factory Methods

**Location:** `features/gossip/domain/entities/report_reason.dart`

```dart
/// Value Object con factory methods predefinidos
class ReportReason extends Equatable {
  final ReportReasonType type;
  final String description;
  
  const ReportReason({
    required this.type,
    required this.description,
  });
  
  // Factory methods para razones comunes
  factory ReportReason.inappropriateContent() => const ReportReason(
    type: ReportReasonType.inappropriateContent,
    description: 'Contenido inapropiado u ofensivo',
  );
  
  factory ReportReason.spam() => const ReportReason(
    type: ReportReasonType.spam,
    description: 'Spam o publicidad no deseada',
  );
  
  factory ReportReason.falseInformation() => const ReportReason(
    type: ReportReasonType.falseInformation,
    description: 'Información falsa o engañosa',
  );
  
  factory ReportReason.harassment() => const ReportReason(
    type: ReportReasonType.harassment,
    description: 'Acoso o intimidación',
  );
}

// Uso
final reason = ReportReason.spam(); // ← Factory method
await repository.reportGossip(gossipId: id, reason: reason);
```

---

### Cuándo Usar Factory Pattern

✅ **SÍ usar Factory Pattern cuando:**

- Necesitas crear objetos complejos con lógica condicional
- Quieres ocultar la clase concreta al consumidor
- Tienes múltiples variantes de una clase base
- Quieres centralizar lógica de creación

**Ejemplos:**
- `ErrorHandler.handleError()` - Crea Failures basado en excepciones
- `GossipQuery.defaultPublic()` - Crea queries predefinidos
- `Result.success()` / `Result.failure()` - Crea resultados

❌ **NO usar Factory Pattern cuando:**

- Constructor simple es suficiente
- Solo hay una implementación
- No hay lógica condicional

---

### Ventajas

1. **Encapsulación:** Oculta lógica de creación
2. **Flexibilidad:** Fácil agregar nuevos tipos
3. **Centralización:** Un solo lugar para crear objetos
4. **Testabilidad:** Fácil mockear factories

---

## 8. Observer Pattern

### Concepto

**Observer Pattern** permite que un objeto (Subject) notifique a múltiples observadores cuando su estado cambia.

En Flutter: `ChangeNotifier` / `StateNotifier` implementan este patrón.

---

### ✅ Observer Pattern en Chismes

#### Ejemplo 1: ChangeNotifier (Built-in Flutter)

**Location:** `features/gossip/presentation/controllers/add_gossip_controller.dart`

```dart
/// Subject: Notifica cambios de estado a observadores
@injectable
class AddGossipController extends ChangeNotifier {
  final CreateGossip _createGossip;
  
  AddGossipController(this._createGossip);
  
  // Estado privado (Subject)
  AddGossipState _state = AddGossipState.initial();
  
  // Getter público para leer estado
  AddGossipState get state => _state;
  
  // Método privado que modifica estado y NOTIFICA observadores
  void _setState(AddGossipState newState) {
    _state = newState;
    notifyListeners(); // ← Notifica a todos los observadores
  }
  
  // Acción que modifica estado
  Future<void> submit(CreateGossipInput input) async {
    _setState(state.copyWith(isLoading: true)); // ← Notifica
    
    final result = await _createGossip(input);
    
    result.fold(
      onFailure: (failure) {
        _setState(state.copyWith(
          isLoading: false,
          failure: failure,
        )); // ← Notifica
      },
      onSuccess: (gossip) {
        _setState(state.copyWith(
          isLoading: false,
          gossip: gossip,
        )); // ← Notifica
      },
    );
  }
}
```

**Por qué es Observer Pattern:**
- ✅ `ChangeNotifier` es el Subject
- ✅ `notifyListeners()` notifica a observadores
- ✅ Widgets se suscriben y reciben actualizaciones
- ✅ Desacoplamiento: Controller no conoce a sus observadores

---

#### Ejemplo 2: Widget Observer (ListenableBuilder)

**Observador que escucha cambios:**

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
    
    // Suscribirse a cambios (Observer)
    _controller.addListener(_onStateChanged);
  }
  
  // Callback cuando el estado cambia
  void _onStateChanged() {
    final state = _controller.state;
    
    // Reaccionar a cambios
    if (state.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.failure!.toString())),
      );
    }
    
    if (state.successMessage != null) {
      Navigator.of(context).pop(state.gossip);
    }
  }
  
  @override
  void dispose() {
    // Desuscribirse (importante para evitar memory leaks)
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // ListenableBuilder se reconstruye cuando el controller notifica
    return ListenableBuilder(
      listenable: _controller, // ← Subject
      builder: (context, _) {
        final state = _controller.state;
        
        if (state.isLoading) {
          return const CircularProgressIndicator();
        }
        
        return Form(/* ... */);
      },
    );
  }
}
```

**Flujo:**

```
1. User taps "Publicar"
2. Controller.submit() llamado
3. _setState() actualiza estado interno
4. notifyListeners() dispara
5. Widget._onStateChanged() ejecutado
6. UI se reconstruye (ListenableBuilder)
```

---

#### Ejemplo 3: Stream Observer (AuthRepository)

**Subject con Stream:**

```dart
/// Repository que expone stream de cambios de auth
abstract class AuthRepository {
  // Stream que emite cada vez que el estado de auth cambia
  Stream<User?> get authStateChanges;
  
  Future<Result<Failure, void>> signIn(...);
  Future<Result<Failure, void>> signOut();
}

@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  
  // Stream del auth state (Subject)
  @override
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((state) {
      // Convierte AuthState de Supabase a User del dominio
      return state.session?.user != null 
          ? UserModel.fromSupabase(state.session!.user).toEntity()
          : null;
    });
  }
}
```

**Observer del Stream:**

```dart
/// Widget que observa cambios de auth
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authRepository = getIt<AuthRepository>();
    
    // Observa el stream (Observer)
    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges, // ← Subject
      builder: (context, snapshot) {
        // Reacciona a cambios
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen(); // Usuario autenticado
        }
        
        return const LoginScreen(); // Usuario no autenticado
      },
    );
  }
}
```

---

### Cuándo Usar Observer Pattern

✅ **SÍ usar Observer Pattern cuando:**

- Múltiples widgets dependen del mismo estado
- Cambios de estado deben propagarse automáticamente
- Desacoplamiento entre Subject y Observers
- Reactividad (UI se actualiza con cambios)

**Ejemplos:**
- Controllers con `ChangeNotifier`
- Auth state con `Stream`
- Theme changes
- Connectivity changes

❌ **NO usar Observer Pattern cuando:**

- Solo un widget necesita el estado
- Estado es local al widget
- `setState()` simple es suficiente

---

### Ventajas

1. **Desacoplamiento:** Subject no conoce Observers
2. **Reactividad:** UI se actualiza automáticamente
3. **Escalabilidad:** Fácil agregar más Observers
4. **Mantenibilidad:** Lógica de estado centralizada

### Desventajas

1. **Memory Leaks:** Olvidar `removeListener()` / cancelar subscripción
2. **Over-notification:** Notificar cambios innecesarios
3. **Debugging:** Difícil rastrear quién causó el cambio

---

### Reglas

- ✅ Siempre llamar `removeListener()` en `dispose()`
- ✅ Usar `ListenableBuilder` para rebuild automático
- ✅ No exponer `_setState()` públicamente
- ✅ Estado inmutable (usar `copyWith`)
- ❌ NO llamar `notifyListeners()` desde build()
- ❌ NO modificar estado sin notificar

---

## 📚 Referencias

- **Clean Architecture:** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Result Type:** https://dart.dev/guides/language/language-tour#generics
- **Injectable:** https://pub.dev/packages/injectable
- **GetIt:** https://pub.dev/packages/get_it
- **Value Objects (DDD):** https://martinfowler.com/bliki/ValueObject.html
- **Equatable:** https://pub.dev/packages/equatable
- **Factory Pattern:** https://refactoring.guru/design-patterns/factory-method
- **Observer Pattern:** https://refactoring.guru/design-patterns/observer
- **ChangeNotifier:** https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html

---

**Última actualización:** 2026-11-12  
**Mantenedor:** Alejo
