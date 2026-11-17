# SOLID Principles - Chismes App

> **Aplicación de principios SOLID en el proyecto.** Ejemplos reales del código, anti-patterns y guías.

**Última actualización:** 2026-11-12  
**Versión:** 1.0

---

## 📋 Índice

1. [Single Responsibility Principle (SRP)](#1-single-responsibility-principle-srp)
2. [Open/Closed Principle (OCP)](#2-openclosed-principle-ocp)
3. [Liskov Substitution Principle (LSP)](#3-liskov-substitution-principle-lsp)
4. [Interface Segregation Principle (ISP)](#4-interface-segregation-principle-isp)
5. [Dependency Inversion Principle (DIP)](#5-dependency-inversion-principle-dip)
6. [Checklist de Validación](#-checklist-de-validación)

---

## 1. Single Responsibility Principle (SRP)

### Definición

> **Una clase debe tener una única razón para cambiar.**

Cada clase debe hacer **una sola cosa** y hacerla bien.

---

### ✅ Ejemplos en Chismes

#### Ejemplo 1: Repository vs Validator

**❌ MAL: Mezclar responsabilidades**

```dart
class GossipRepository {
  Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
    // ❌ Validación NO es responsabilidad del Repository
    if (input.subject.isEmpty) {
      return Result.failure(ValidationFailure(code: ErrorCode.invalidInput));
    }
    
    if (input.content.length > 1000) {
      return Result.failure(ValidationFailure(code: ErrorCode.invalidInput));
    }
    
    // Guardar en DB
    final model = await _remoteDataSource.create(input);
    return Result.success(model.toEntity());
  }
}
```

**✅ BIEN: Separar responsabilidades**

```dart
// Domain Validator: SU ÚNICA RESPONSABILIDAD es validar
// features/gossip/domain/validators/gossip_validator.dart
class GossipValidator {
  static Failure? validateSubject(String subject) {
    if (subject.isEmpty) {
      return const ValidationFailure(code: ErrorCode.subjectRequired);
    }
    if (subject.length > 200) {
      return const ValidationFailure(code: ErrorCode.subjectTooLong);
    }
    return null;
  }
  
  static Failure? validateContent(String content) {
    if (content.isEmpty) {
      return const ValidationFailure(code: ErrorCode.contentRequired);
    }
    if (content.length > 1000) {
      return const ValidationFailure(code: ErrorCode.contentTooLong);
    }
    return null;
  }
}

// Repository: SU ÚNICA RESPONSABILIDAD es persistir datos
class GossipRepositoryImpl implements GossipRepository {
  @override
  Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
    try {
      // Solo persiste, NO valida
      final model = await _remoteDataSource.create(input);
      return Result.success(model.toEntity());
    } catch (error) {
      return Result.failure(ErrorHandler.handleError(error));
    }
  }
}

// UseCase: COORDINA validación + persistencia
@injectable
class CreateGossip {
  final GossipRepository _repository;
  
  CreateGossip(this._repository);
  
  Future<Result<Failure, Gossip>> call(CreateGossipInput input) async {
    // 1. Validar (responsabilidad del Validator)
    final validation = GossipValidator.validateSubject(input.subject) 
        ?? GossipValidator.validateContent(input.content);
    
    if (validation != null) {
      return Result.failure(validation);
    }
    
    // 2. Persistir (responsabilidad del Repository)
    return _repository.create(input);
  }
}
```

**Por qué es mejor:**
- `GossipValidator` solo valida → Una razón para cambiar: reglas de validación
- `GossipRepository` solo persiste → Una razón para cambiar: fuente de datos
- `CreateGossip` coordina → Una razón para cambiar: flujo de negocio

---

#### Ejemplo 2: Controller

**✅ BIEN: Controller solo maneja estado UI**

```dart
// features/gossip/presentation/controllers/add_gossip_controller.dart
@injectable
class AddGossipController extends StateNotifier<AddGossipState> {
  final CreateGossip _createGossip;
  final AppLogger _logger;
  
  AddGossipController(this._createGossip, this._logger) 
      : super(const AddGossipState.initial());
  
  // SU ÚNICA RESPONSABILIDAD: Manejar estado UI
  Future<void> submit(CreateGossipInput input) async {
    state = const AddGossipState.loading();
    
    // Delega lógica de negocio al UseCase
    final result = await _createGossip(input);
    
    result.fold(
      onFailure: (failure) {
        state = AddGossipState.error(failure);
        _logger.e('Failed to create gossip', context: {'error': failure});
      },
      onSuccess: (gossip) {
        state = AddGossipState.success(gossip);
        _logger.i('Gossip created', context: {'id': gossip.id});
      },
    );
  }
}
```

**Por qué cumple SRP:**
- NO valida (lo hace GossipValidator)
- NO persiste (lo hace GossipRepository)
- Solo coordina UI y llama UseCase

---

### 🎯 Checklist SRP

Al escribir una clase, pregúntate:

- [ ] ¿Esta clase tiene más de una razón para cambiar?
- [ ] ¿Puedo describir su responsabilidad en una oración sin usar "Y"?
- [ ] ¿Esta clase valida Y persiste? (❌ Separar)
- [ ] ¿Esta clase renderiza UI Y hace lógica de negocio? (❌ Separar)

**Razones válidas para cambiar:**
- Repository → Cambia fuente de datos (Supabase → Firebase)
- Validator → Cambian reglas de validación
- Controller → Cambia flujo UI
- UseCase → Cambia lógica de negocio

---

## 2. Open/Closed Principle (OCP)

### Definición

> **Las clases deben estar abiertas a extensión, pero cerradas a modificación.**

Agrega funcionalidad **sin modificar** código existente.

---

### ✅ Ejemplos en Chismes

#### Ejemplo 1: Repository con Interfaces

**✅ BIEN: Extensible via interfaces**

```dart
// Domain: Interface (cerrada a modificación)
abstract class GossipRepository {
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);
  Future<Result<Failure, Gossip>> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  );
}

// Data: Implementación 1 - Supabase (extensión)
@Singleton(as: GossipRepository)
class GossipRepositoryImpl implements GossipRepository {
  final SupabaseGossipRemoteDataSource _remote;
  final SharedPrefsGossipLocalDataSource _local;
  
  // Implementa métodos...
}

// Data: Implementación 2 - Mock para tests (extensión)
class MockGossipRepository implements GossipRepository {
  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    return Result.success([/* mocks */]);
  }
  
  // Implementa métodos...
}

// FUTURO: Implementación 3 - Firebase (extensión sin tocar código existente)
@Singleton(as: GossipRepository)
class FirebaseGossipRepository implements GossipRepository {
  // Nueva implementación sin modificar GossipRepositoryImpl
}
```

**Por qué cumple OCP:**
- ✅ Interface `GossipRepository` cerrada a modificación
- ✅ Nuevas implementaciones extienden sin modificar existentes
- ✅ Presentation solo depende de la interface

---

#### Ejemplo 2: Error Handling Extensible

**✅ BIEN: Factory Pattern permite extensión**

```dart
// core/error/error_handler.dart
class ErrorHandler {
  /// Factory method extensible
  static Failure handleError(Object error, [StackTrace? stackTrace]) {
    // Supabase errors
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }
    
    // Auth errors
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    
    // Storage errors
    if (error is StorageException) {
      return _handleStorageError(error);
    }
    
    // Network errors
    if (error is SocketException) {
      return const NetworkFailure(code: ErrorCode.noConnection);
    }
    
    // FUTURO: Agregar nuevo tipo de error sin modificar casos existentes
    // if (error is NewErrorType) {
    //   return _handleNewError(error);
    // }
    
    // Default
    return ServerFailure(
      code: ErrorCode.unknownError,
      technicalMessage: error.toString(),
    );
  }
  
  // Métodos privados helpers
  static Failure _handlePostgrestError(PostgrestException error) { ... }
  static Failure _handleAuthError(AuthException error) { ... }
  static Failure _handleStorageError(StorageException error) { ... }
}
```

**Por qué cumple OCP:**
- ✅ Agregar nuevo tipo de error → Solo agregar if + handler
- ✅ No modifica handlers existentes

---

#### Ejemplo 3: Strategy Pattern (Futuro)

**✅ BIEN: Cache Strategy extensible**

```dart
// core/cache/cache_strategy.dart
abstract class CacheStrategy {
  Future<void> save(String key, String value);
  Future<String?> get(String key);
  Future<void> clear();
}

// Implementación 1: SharedPreferences (actual)
class SharedPrefsCacheStrategy implements CacheStrategy {
  final SharedPreferences _prefs;
  
  @override
  Future<void> save(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  // ...
}

// FUTURO: Implementación 2 - Secure Storage (extensión)
class SecureStorageCacheStrategy implements CacheStrategy {
  final FlutterSecureStorage _storage;
  
  @override
  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  // ...
}

// FUTURO: Implementación 3 - Hive (extensión)
class HiveCacheStrategy implements CacheStrategy {
  final Box _box;
  
  @override
  Future<void> save(String key, String value) async {
    await _box.put(key, value);
  }
  
  // ...
}

// Repository usa interface (cerrado a modificación)
class GossipRepositoryImpl {
  final CacheStrategy _cache; // ← Interface, no implementación
  
  // Funciona con cualquier estrategia sin modificar código
}
```

---

### 🎯 Checklist OCP

- [ ] ¿Nuevas features requieren modificar código existente?
- [ ] ¿Estoy usando interfaces para abstraer comportamiento?
- [ ] ¿Puedo cambiar implementación sin tocar consumidores?
- [ ] ¿Factory/Strategy patterns donde hay variaciones?

---

## 3. Liskov Substitution Principle (LSP)

### Definición

> **Las subclases deben ser sustituibles por su clase base sin romper funcionalidad.**

Si `B` implementa `A`, entonces puedo usar `B` donde espero `A`.

---

### ✅ Ejemplos en Chismes

#### Ejemplo 1: Repository Intercambiable

**✅ BIEN: Cualquier implementación funciona igual**

```dart
// Domain: Contrato
abstract class GossipRepository {
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);
}

// Implementación 1: Supabase
class GossipRepositoryImpl implements GossipRepository {
  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    // Query a Supabase
    final models = await _remote.getGossips(query);
    return Result.success(models.map((m) => m.toEntity()).toList());
  }
}

// Implementación 2: Mock
class MockGossipRepository implements GossipRepository {
  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    // Retorna mocks
    return Result.success(GossipMockData.gossips);
  }
}

// UseCase: NO SABE cuál implementación usa
@injectable
class GetGossips {
  final GossipRepository _repository; // ← Interface
  
  GetGossips(this._repository);
  
  Future<Result<Failure, List<Gossip>>> call(GossipQuery query) {
    // Funciona con Supabase, Mock, o cualquier implementación futura
    return _repository.getGossips(query);
  }
}

// DI decide cuál usar
@module
abstract class GossipModule {
  @Singleton(as: GossipRepository)
  GossipRepositoryImpl repository(
    SupabaseGossipRemoteDataSource remote,
    SharedPrefsGossipLocalDataSource local,
    AppLogger logger,
  ) => GossipRepositoryImpl(remote, local, logger);
}

// En tests
void main() {
  test('debe obtener gossips', () async {
    // Sustituye con Mock sin romper funcionalidad
    final repository = MockGossipRepository();
    final useCase = GetGossips(repository);
    
    final result = await useCase(GossipQuery.defaultPublic());
    
    expect(result.isSuccess, isTrue);
  });
}
```

**Por qué cumple LSP:**
- ✅ `MockGossipRepository` sustituye `GossipRepositoryImpl` sin cambios
- ✅ UseCase funciona igual con cualquier implementación
- ✅ Tests usan Mock, producción usa Supabase, sin modificar UseCase

---

#### Ejemplo 2: Failure Hierarchy

**✅ BIEN: Todas las Failures son sustituibles**

```dart
// Base class
class Failure extends Equatable {
  final ErrorCode code;
  final String? technicalMessage;
  
  const Failure({required this.code, this.technicalMessage});
  
  @override
  List<Object?> get props => [code, technicalMessage];
}

// Subclases específicas
class NetworkFailure extends Failure {
  const NetworkFailure({required super.code, super.technicalMessage});
}

class ServerFailure extends Failure {
  final String? message; // Campo adicional
  
  const ServerFailure({
    required super.code,
    super.technicalMessage,
    this.message,
  });
  
  @override
  List<Object?> get props => [code, technicalMessage, message];
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.code, super.technicalMessage});
}

// Consumidor: Funciona con cualquier Failure
void handleError(Failure failure) {
  // Puede recibir NetworkFailure, ServerFailure, ValidationFailure
  _logger.e('Error: ${failure.code}', context: {
    'technical': failure.technicalMessage,
  });
  
  // Si necesita comportamiento específico, usa pattern matching
  if (failure is ServerFailure && failure.message != null) {
    showSnackBar(failure.message!);
  } else {
    showSnackBar(ErrorMessages.getMessage(failure.code));
  }
}
```

**Por qué cumple LSP:**
- ✅ Todas las subclases son `Failure`
- ✅ Consumidor funciona con cualquier tipo de Failure
- ✅ Comportamiento específico opcional via pattern matching

---

### ❌ Anti-Pattern: Violando LSP

```dart
// ❌ MAL: Subclase rompe contrato
abstract class Repository {
  Future<List<Item>> getAll();
}

class NetworkRepository implements Repository {
  @override
  Future<List<Item>> getAll() async {
    // Retorna lista (OK)
    return await _api.getAll();
  }
}

class CacheRepository implements Repository {
  @override
  Future<List<Item>> getAll() async {
    final cached = await _cache.get();
    if (cached == null) {
      // ❌ VIOLA LSP: Lanza excepción cuando se esperaba lista
      throw CacheException('No data');
    }
    return cached;
  }
}

// Consumidor se rompe con CacheRepository
final repo = getIt<Repository>(); // Puede ser Cache o Network
final items = await repo.getAll(); // ❌ Explota si es CacheRepository
```

**Solución:**

```dart
// ✅ BIEN: Ambas retornan Result
abstract class Repository {
  Future<Result<Failure, List<Item>>> getAll();
}

class NetworkRepository implements Repository {
  @override
  Future<Result<Failure, List<Item>>> getAll() async {
    try {
      final items = await _api.getAll();
      return Result.success(items);
    } catch (error) {
      return Result.failure(NetworkFailure(...));
    }
  }
}

class CacheRepository implements Repository {
  @override
  Future<Result<Failure, List<Item>>> getAll() async {
    final cached = await _cache.get();
    if (cached == null) {
      return Result.failure(CacheFailure(code: ErrorCode.cacheEmpty));
    }
    return Result.success(cached);
  }
}

// Ahora ambas son sustituibles
final repo = getIt<Repository>();
final result = await repo.getAll(); // ✅ Siempre retorna Result
```

---

### 🎯 Checklist LSP

- [ ] ¿Todas las implementaciones cumplen el contrato de la interface?
- [ ] ¿Puedo intercambiar implementaciones sin modificar consumidores?
- [ ] ¿Tests funcionan con Mock igual que con implementación real?
- [ ] ¿Subclases no lanzan excepciones inesperadas?

---

## 4. Interface Segregation Principle (ISP)

### Definición

> **Muchas interfaces específicas son mejores que una general.**

No forzar a implementar métodos no usados.

---

### ✅ Ejemplos en Chismes

#### Ejemplo 1: DataSource Específicos

**✅ BIEN: Interfaces separadas**

```dart
// Interfaces específicas (NO una sola "DataSource" genérica)

// features/gossip/data/datasources/gossip_remote_data_source.dart
abstract class GossipRemoteDataSource {
  // Solo operaciones remotas
  Future<List<GossipModel>> getGossips(GossipQuery query);
  Future<GossipModel> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  );
  Future<void> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  });
  Future<List<GossipModel>> searchGossips({
    required String query,
    String? cityId,
    int limit = 20,
  });
}

// features/gossip/data/datasources/gossip_local_data_source.dart
abstract class GossipLocalDataSource {
  // Solo operaciones locales
  Future<List<GossipModel>> getCachedGossips();
  Future<void> cacheGossips(List<GossipModel> gossips);
  Future<void> clearCache();
}

// Implementaciones solo implementan lo que necesitan
@injectable
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
  // Solo implementa métodos remotos, NO cache
}

@injectable
class SharedPrefsGossipLocalDataSource implements GossipLocalDataSource {
  // Solo implementa métodos cache, NO network
}
```

**Por qué cumple ISP:**
- ✅ Remote NO tiene que implementar cache
- ✅ Local NO tiene que implementar network
- ✅ Cada clase implementa solo lo que usa

---

#### Ejemplo 2: Repository Específico

**❌ MAL: Interface demasiado general**

```dart
// ❌ NO hacer esto
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T> getById(String id);
  Future<void> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
  Future<void> sync();        // ❌ No todos sincronizan
  Future<void> exportToCSV(); // ❌ No todos exportan
  Future<void> importFromJSON(); // ❌ No todos importan
}

// GossipRepository se ve forzado a implementar métodos no usados
class GossipRepositoryImpl implements Repository<Gossip> {
  @override
  Future<void> sync() async {
    throw UnimplementedError(); // ❌ No usa sync
  }
  
  @override
  Future<void> exportToCSV() async {
    throw UnimplementedError(); // ❌ No exporta
  }
  
  @override
  Future<void> importFromJSON() async {
    throw UnimplementedError(); // ❌ No importa
  }
}
```

**✅ BIEN: Interfaces segregadas**

```dart
// Interface base mínima
abstract class ReadRepository<T> {
  Future<List<T>> getAll();
  Future<T> getById(String id);
}

// Interface para escritura
abstract class WriteRepository<T> {
  Future<void> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
}

// Interface para sync (opcional)
abstract class SyncableRepository {
  Future<void> sync();
}

// Interface para export (opcional)
abstract class ExportableRepository {
  Future<void> exportToCSV();
}

// Gossip solo implementa lo que usa
abstract class GossipRepository 
    implements ReadRepository<Gossip>, WriteRepository<Gossip> {
  // NO implementa Syncable ni Exportable
  
  // Métodos específicos de Gossip
  Future<Result<Failure, Gossip>> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  );
  Future<Result<Failure, void>> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  });
}
```

---

### ✅ Ejemplo Actual en Chismes

```dart
// Cada repository tiene interface específica, NO genérica

// features/gossip/domain/repositories/gossip_repository.dart
abstract class GossipRepository {
  // Solo métodos que Gossip realmente usa
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);
  Future<Result<Failure, Gossip>> createWithImage(...);
  Future<Result<Failure, void>> reportGossip(...);
  Future<Result<Failure, List<Gossip>>> searchGossips(...);
}

// features/location/domain/repositories/location_repository.dart
abstract class LocationRepository {
  // Solo métodos que Location realmente usa
  Future<Result<Failure, List<Country>>> getCountries();
  Future<Result<Failure, List<Region>>> getRegionsByCountry(String countryId);
  Future<Result<Failure, List<City>>> getCitiesByRegion(String regionId);
}

// features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  // Solo métodos que Auth realmente usa
  Future<Result<Failure, User>> signInWithEmail(String email, String password);
  Future<Result<Failure, User>> signUpWithEmail(String email, String password);
  Future<Result<Failure, void>> signOut();
  Stream<User?> get authStateChanges;
}
```

**Por qué cumple ISP:**
- ✅ Cada repository define solo sus métodos
- ✅ NO hay "BaseRepository" forzando métodos no usados
- ✅ Features no implementan funcionalidad ajena

---

### 🎯 Checklist ISP

- [ ] ¿Mis interfaces son pequeñas y específicas?
- [ ] ¿Alguna clase implementa métodos que lanza `UnimplementedError`?
- [ ] ¿Puedo dividir interface grande en varias pequeñas?
- [ ] ¿Cada interface tiene cohesión (métodos relacionados)?

---

## 5. Dependency Inversion Principle (DIP)

### Definición

> **Depender de abstracciones (interfaces), NO de implementaciones concretas.**

Las clases de alto nivel no deben depender de clases de bajo nivel.

---

### ✅ Ejemplos en Chismes

#### Ejemplo 1: UseCase depende de Interface

**✅ BIEN: UseCase depende de abstracción**

```dart
// Domain: Interface (abstracción)
abstract class GossipRepository {
  Future<Result<Failure, Gossip>> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  );
}

// Domain: UseCase depende de abstracción
@injectable
class CreateGossip {
  final GossipRepository _repository; // ← Interface, NO implementación
  
  CreateGossip(this._repository);
  
  Future<Result<Failure, Gossip>> call(
    CreateGossipInput input,
    String? imageBase64,
  ) async {
    // Validación
    final validation = GossipValidator.validateSubject(input.subject) 
        ?? GossipValidator.validateContent(input.content);
    
    if (validation != null) {
      return Result.failure(validation);
    }
    
    // Delega a repository (abstracción)
    return _repository.createWithImage(input, imageBase64);
  }
}

// Data: Implementación concreta (bajo nivel)
@Singleton(as: GossipRepository) // ← Se registra como interface
class GossipRepositoryImpl implements GossipRepository {
  final SupabaseGossipRemoteDataSource _remote;
  final SharedPrefsGossipLocalDataSource _local;
  final AppLogger _logger;
  
  GossipRepositoryImpl(this._remote, this._local, this._logger);
  
  @override
  Future<Result<Failure, Gossip>> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  ) async {
    // Implementación...
  }
}
```

**Por qué cumple DIP:**
- ✅ `CreateGossip` (alto nivel) depende de `GossipRepository` (abstracción)
- ✅ `GossipRepositoryImpl` (bajo nivel) implementa abstracción
- ✅ DI inyecta implementación concreta en tiempo de ejecución
- ✅ Cambiar de Supabase a Firebase solo requiere nueva implementación, sin tocar UseCase

---

#### Ejemplo 2: Controller depende de UseCase (abstracción)

**✅ BIEN: Controller depende de casos de uso**

```dart
// Presentation: Controller (alto nivel)
@injectable
class AddGossipController extends StateNotifier<AddGossipState> {
  final CreateGossip _createGossip; // ← UseCase (abstracción de lógica)
  final AppLogger _logger;
  
  AddGossipController(this._createGossip, this._logger) 
      : super(const AddGossipState.initial());
  
  Future<void> submit(CreateGossipInput input, String? imageBase64) async {
    state = const AddGossipState.loading();
    
    // Depende de UseCase, NO de Repository directamente
    final result = await _createGossip(input, imageBase64);
    
    result.fold(
      onFailure: (failure) => state = AddGossipState.error(failure),
      onSuccess: (gossip) => state = AddGossipState.success(gossip),
    );
  }
}
```

**Por qué cumple DIP:**
- ✅ Controller NO sabe nada de Supabase, SharedPreferences, o Data layer
- ✅ Depende de `CreateGossip` (abstracción de lógica de negocio)
- ✅ UseCase puede cambiar implementación sin afectar Controller

---

#### Ejemplo 3: DataSource Injection

**✅ BIEN: Repository depende de interfaces DataSource**

```dart
// Data: Repository depende de abstracciones DataSource
@Singleton(as: GossipRepository)
class GossipRepositoryImpl implements GossipRepository {
  final GossipRemoteDataSource _remote; // ← Interface
  final GossipLocalDataSource _local;   // ← Interface
  final AppLogger _logger;
  
  GossipRepositoryImpl(this._remote, this._local, this._logger);
  
  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    try {
      // Intenta remoto primero
      final models = await _remote.getGossips(query);
      
      // Cache en local
      await _local.cacheGossips(models);
      
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      _logger.w('Remote failed, trying cache', error: error);
      
      // Fallback a cache
      try {
        final cached = await _local.getCachedGossips();
        return Result.success(cached.map((m) => m.toEntity()).toList());
      } catch (cacheError) {
        return Result.failure(ErrorHandler.handleError(error));
      }
    }
  }
}

// Data: Implementaciones concretas (bajo nivel)
@injectable
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
  final SupabaseClient _supabase;
  // Implementación Supabase...
}

@injectable
class SharedPrefsGossipLocalDataSource implements GossipLocalDataSource {
  final SharedPreferences _prefs;
  // Implementación SharedPreferences...
}
```

**Por qué cumple DIP:**
- ✅ `GossipRepositoryImpl` depende de interfaces DataSource
- ✅ Puedo cambiar de Supabase a Firebase sin tocar Repository
- ✅ Puedo cambiar de SharedPrefs a Hive sin tocar Repository
- ✅ Tests usan Mocks fácilmente

---

### ❌ Anti-Pattern: Violando DIP

```dart
// ❌ MAL: UseCase depende de implementación concreta
@injectable
class CreateGossip {
  final GossipRepositoryImpl _repository; // ← Implementación concreta
  
  CreateGossip(this._repository);
  
  Future<Result<Failure, Gossip>> call(CreateGossipInput input) async {
    // ❌ Acoplado a Supabase
    return _repository.createWithImage(input, null);
  }
}

// ❌ MAL: Repository depende de Supabase directamente
class GossipRepositoryImpl {
  final SupabaseClient _supabase; // ← Implementación concreta
  
  Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
    // ❌ Acoplado a API específica de Supabase
    final response = await _supabase
        .from('gossips')
        .insert(input.toJson())
        .select()
        .single();
    
    return Result.success(GossipModel.fromJson(response).toEntity());
  }
}
```

**Problemas:**
- ❌ Cambiar de Supabase a Firebase requiere modificar Repository Y UseCase
- ❌ Tests difíciles (necesitas mockear Supabase directamente)
- ❌ Acoplamiento fuerte

---

### 🔧 Dependency Injection en Chismes

**Injectable + GetIt implementa DIP automáticamente:**

```dart
// 1. Registrar abstracciones
@module
abstract class GossipModule {
  // Repository
  @Singleton(as: GossipRepository) // ← Registra como interface
  GossipRepositoryImpl repository(
    GossipRemoteDataSource remote,
    GossipLocalDataSource local,
    AppLogger logger,
  ) => GossipRepositoryImpl(remote, local, logger);
}

// 2. DataSources se registran también como interfaces
@injectable
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
  // Implementación...
}

@injectable
class SharedPrefsGossipLocalDataSource implements GossipLocalDataSource {
  // Implementación...
}

// 3. GetIt resuelve dependencias automáticamente
final getIt = GetIt.instance;

// Regenerar inyecciones
// flutter pub run build_runner build --delete-conflicting-outputs

// 4. Uso en código
@injectable
class CreateGossip {
  final GossipRepository _repository; // ← GetIt inyecta implementación
  
  CreateGossip(this._repository); // ← Constructor injection
}

// 5. Obtener instancia
final useCase = getIt<CreateGossip>(); // ← Resuelve toda la cadena
```

---

### 🎯 Checklist DIP

- [ ] ¿Mis clases dependen de interfaces, NO implementaciones?
- [ ] ¿Uso `@Singleton(as: Interface)` en DI?
- [ ] ¿Repository recibe DataSource interface, NO concreto?
- [ ] ¿UseCase recibe Repository interface, NO concreto?
- [ ] ¿Controller recibe UseCase, NO Repository?
- [ ] ¿Puedo cambiar implementación sin modificar consumidores?

---

## 📊 Checklist de Validación

### Validación por Clase

Al escribir/revisar una clase:

```
[ ] SRP: ¿Una sola responsabilidad?
[ ] OCP: ¿Extensible sin modificación?
[ ] LSP: ¿Sustituible por interface?
[ ] ISP: ¿Interface pequeña y específica?
[ ] DIP: ¿Depende de abstracciones?
```

---

### Validación por Capa

#### Domain Layer

```
[ ] SRP: Entity/Validator/UseCase separados
[ ] OCP: Interfaces permiten extensión
[ ] LSP: Entities son Value Objects o Entities claros
[ ] ISP: Repository interfaces específicas
[ ] DIP: NO depende de Data o Presentation
```

#### Data Layer

```
[ ] SRP: DataSource/Repository/Model separados
[ ] OCP: Implementa interfaces de Domain
[ ] LSP: Repository intercambiable
[ ] ISP: DataSource Remote/Local separados
[ ] DIP: Depende de abstracciones DataSource
```

#### Presentation Layer

```
[ ] SRP: Controller/Screen/Widget separados
[ ] OCP: State extensible
[ ] LSP: Controllers intercambiables en tests
[ ] ISP: Controllers específicos por feature
[ ] DIP: Depende de UseCases (Domain), NO Data
```

---

## 🚨 Anti-Patterns Comunes

### 1. God Class (Viola SRP)

```dart
// ❌ MAL: Clase hace TODO
class GossipManager {
  Future<void> create() { /* valida + persiste + notifica */ }
  Future<void> validate() { /* validación */ }
  Future<void> save() { /* persistencia */ }
  Future<void> notify() { /* notificaciones */ }
}

// ✅ BIEN: Separar responsabilidades
class GossipValidator { /* solo valida */ }
class GossipRepository { /* solo persiste */ }
class GossipNotifier { /* solo notifica */ }
```

### 2. Tight Coupling (Viola DIP)

```dart
// ❌ MAL: Acoplado a implementación
class UseCase {
  final GossipRepositoryImpl _repo; // ← Concreto
}

// ✅ BIEN: Depende de abstracción
class UseCase {
  final GossipRepository _repo; // ← Interface
}
```

### 3. Fat Interface (Viola ISP)

```dart
// ❌ MAL: Interface obliga métodos no usados
abstract class Repository {
  Future<void> create();
  Future<void> update();
  Future<void> delete();
  Future<void> sync(); // ← No todos sincronizan
}

// ✅ BIEN: Interfaces segregadas
abstract class WriteRepository { /* create/update/delete */ }
abstract class SyncableRepository { /* sync */ }
```

---

## 📚 Referencias

- Clean Code (Robert C. Martin): https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882
- SOLID Principles: https://en.wikipedia.org/wiki/SOLID
- Dependency Injection in Flutter: https://pub.dev/packages/injectable

---

## 🎯 Resumen Ejecutivo

| Principio | Chismes | Evidencia |
|-----------|---------|-----------|
| **SRP** | ✅ 9/10 | Validator/Repository/UseCase separados |
| **OCP** | ✅ 8/10 | Interfaces + Factory Pattern |
| **LSP** | ✅ 9/10 | Repository/Failure intercambiables |
| **ISP** | ✅ 9/10 | Interfaces específicas por feature |
| **DIP** | ✅ 10/10 | Injectable/GetIt con abstracciones |

**Score SOLID:** **8.8/10** ✅

---

**Última actualización:** 2026-11-12  
**Versión:** 1.0  
**Mantenedor:** Alejo

**FIN DEL DOCUMENTO**
