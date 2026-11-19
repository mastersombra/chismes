# Arquitectura - Chismes App

> **Arquitectura detallada del proyecto.** Clean Architecture + Feature-First + DDD.

**Última actualización:** 2026-11-12  
**Versión:** 2.0 (Actualizado con Aggregate Roots)

---

## 📋 Índice

1. [Visión General](#visión-general)
2. [Estructura de Directorios](#estructura-de-directorios)
3. [Clean Architecture](#clean-architecture)
4. [Feature-First Organization](#feature-first-organization)
5. [Domain-Driven Design (DDD)](#domain-driven-design-ddd)
6. [Flujo de Datos](#flujo-de-datos)
7. [Dependency Rule](#dependency-rule)

---

## Visión General

Chismes usa **Clean Architecture** con **Feature-First** organization y conceptos de **DDD**.

### Principios Clave

1. **Clean Architecture:** Capas independientes (Presentation, Domain, Data)
2. **Feature-First:** Código organizado por features, no por tipo técnico
3. **DDD:** Bounded contexts, Entities, Value Objects, Aggregate Roots
4. **SOLID:** 5 principios aplicados consistentemente
5. **Testabilidad:** Cada capa testeable aisladamente

---

## Estructura de Directorios

```
lib/
├── core/                    # Código compartido transversal
│   ├── audit/              # Auditoría (Auditable interface)
│   ├── auth/               # Auth global (sin lógica de negocio)
│   ├── config/             # Configuración (env, constants)
│   ├── di/                 # Dependency Injection (Injectable/GetIt)
│   ├── error/              # Error handling (Failure, Result, ErrorHandler)
│   ├── logging/            # AppLogger, RemoteLogger
│   ├── media/              # Media services (ImageCompressor, Storage)
│   ├── result/             # Result<Failure, Success>
│   ├── services/           # Services globales (LocationService, DeepLinkService)
│   ├── theme/              # AppTheme, AppSpacing, AppColors, AppRadius
│   └── validation/         # FormValidators (UI validation)
│
├── features/               # Features (módulos funcionales)
│   ├── auth/              # Feature: Autenticación
│   │   ├── data/          # Data Layer
│   │   │   ├── datasources/     # SupabaseAuthDataSource
│   │   │   ├── models/          # UserModel (DTO)
│   │   │   └── repositories/    # AuthRepositoryImpl
│   │   ├── domain/        # Domain Layer
│   │   │   ├── entities/        # User (Entity)
│   │   │   ├── repositories/    # AuthRepository (interface)
│   │   │   ├── usecases/        # SignIn, SignUp, SignOut
│   │   │   └── validators/      # AuthValidator
│   │   └── presentation/  # Presentation Layer
│   │       ├── controllers/     # LoginController, SignupController
│   │       ├── screens/         # LoginScreen, SignupScreen
│   │       ├── state/           # AuthState
│   │       └── widgets/         # AuthGate, widgets específicos
│   │
│   ├── gossip/            # Feature: Gossip (CRUD, moderación)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── gossip_remote_data_source.dart (interface)
│   │   │   │   ├── supabase_gossip_remote_data_source.dart
│   │   │   │   ├── gossip_local_data_source.dart (interface)
│   │   │   │   └── shared_prefs_gossip_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── gossip_model.dart (DTO)
│   │   │   └── repositories/
│   │   │       └── gossip_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── gossip.dart (Aggregate Root)
│   │   │   │   ├── create_gossip_input.dart (DTO)
│   │   │   │   ├── gossip_query.dart (Value Object)
│   │   │   │   └── report_reason.dart (Value Object)
│   │   │   ├── repositories/
│   │   │   │   └── gossip_repository.dart (interface)
│   │   │   ├── usecases/
│   │   │   │   ├── create_gossip.dart
│   │   │   │   ├── get_gossips.dart
│   │   │   │   └── report_gossip.dart
│   │   │   └── validators/
│   │   │       └── gossip_validator.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── add_gossip_controller.dart
│   │       ├── screens/
│   │       │   └── add_gossip_screen.dart
│   │       └── widgets/
│   │           ├── gossip_card.dart
│   │           └── report_gossip_dialog.dart
│   │
│   ├── home/              # Feature: Feed principal
│   ├── location/          # Feature: Ubicaciones (país, región, ciudad)
│   └── search/            # Feature: Búsqueda de gossips
│
└── shared/                # Código compartido (legacy, minimizar uso)
    ├── data/              # Mock data (solo desarrollo)
    └── widgets/           # Widgets reutilizables (mover a core/widgets)

supabase/
├── migrations/            # Migraciones SQL (secuenciales)
│   ├── 001_gossips.sql
│   ├── 002_location.sql
│   ├── 003_error_logs.sql
│   └── ...
└── seed.sql              # Datos iniciales (países, regiones)
```

---

## Clean Architecture

### Las 3 Capas

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                  │  ← UI
│  (Screens, Widgets, Controllers, State)     │
└──────────────────┬──────────────────────────┘
                   │ depende de
┌──────────────────▼──────────────────────────┐
│           Domain Layer                       │  ← Business Logic
│  (Entities, UseCases, Repositories,         │
│   Validators, Value Objects)                │
└──────────────────┬──────────────────────────┘
                   │ depende de
┌──────────────────▼──────────────────────────┐
│            Data Layer                        │  ← Data Access
│  (Models, DataSources, RepositoryImpl)      │
└─────────────────────────────────────────────┘
```

---

### Presentation Layer

**Responsabilidad:** UI y coordinación de casos de uso.

**Contiene:**
- `screens/`: Pantallas (Scaffold, navigation)
- `widgets/`: Componentes UI específicos del feature
- `controllers/`: Estado UI (ChangeNotifier)
- `state/`: Modelos de estado (inmutables, Equatable)

**Reglas:**
- ✅ Depende de Domain (UseCases, Entities)
- ✅ NO depende de Data
- ✅ NO contiene lógica de negocio
- ✅ Controllers coordinan UseCases
- ❌ NO accede a repositories directamente

**Ejemplo:**

```dart
// Controller coordina UseCases
@injectable
class AddGossipController extends ChangeNotifier {
  final CreateGossip _createGossip; // ← UseCase
  
  Future<void> submit(CreateGossipInput input) async {
    _setState(state.copyWith(isLoading: true));
    
    // Delega a UseCase (NO a Repository)
    final result = await _createGossip(input: input);
    
    result.fold(
      onFailure: (failure) => _setState(...),
      onSuccess: (gossip) => _setState(...),
    );
  }
}
```

---

### Domain Layer

**Responsabilidad:** Lógica de negocio pura.

**Contiene:**
- `entities/`: Objetos de negocio (Gossip, User)
- `repositories/`: Interfaces (contratos)
- `usecases/`: Casos de uso (CreateGossip, GetGossips)
- `validators/`: Validación de negocio (NO UI)

**Reglas:**
- ✅ NO depende de nada (independiente)
- ✅ Define interfaces, Data las implementa
- ✅ Lógica de negocio centralizada
- ✅ Testeable sin UI ni DB
- ❌ NO importa de Presentation ni Data
- ❌ NO usa implementaciones concretas

**Ejemplo:**

```dart
// UseCase: Lógica de negocio
@injectable
class CreateGossip {
  final GossipRepository _repository; // ← Interface
  
  CreateGossip(this._repository);
  
  Future<Result<Failure, Gossip>> call(CreateGossipInput input) async {
    // 1. Validar (lógica de negocio)
    final validation = GossipValidator.validateInput(input);
    if (validation != null) {
      return Result.failure(validation);
    }
    
    // 2. Delegar a repository
    return _repository.createWithImage(input, null);
  }
}
```

---

### Data Layer

**Responsabilidad:** Acceso a datos (API, DB, Cache).

**Contiene:**
- `models/`: DTOs (Data Transfer Objects)
- `datasources/`: Acceso a datos (Supabase, SharedPrefs)
- `repositories/`: Implementaciones de interfaces Domain

**Reglas:**
- ✅ Implementa interfaces de Domain
- ✅ Convierte Models (DTO) → Entities (Domain)
- ✅ Puede lanzar excepciones (Repository las captura)
- ✅ DataSources NO retornan Result
- ❌ NO depende de Presentation

**Ejemplo:**

```dart
// Repository implementa interface Domain
@Singleton(as: GossipRepository)
class GossipRepositoryImpl implements GossipRepository {
  final GossipRemoteDataSource _remote;
  final GossipLocalDataSource _local;
  
  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    try {
      // 1. Obtener de remote (lanza excepciones)
      final models = await _remote.getGossips(query);
      
      // 2. Cache local
      await _local.cacheGossips(models);
      
      // 3. Convertir Model → Entity
      final entities = models.map((m) => m.toEntity()).toList();
      
      return Result.success(entities);
    } catch (error) {
      // 4. Fallback a cache
      try {
        final cached = await _local.getCachedGossips();
        return Result.success(cached.map((m) => m.toEntity()).toList());
      } catch (_) {
        // 5. Convertir exception → Failure
        return Result.failure(ErrorHandler.handleError(error));
      }
    }
  }
}
```

---

## Feature-First Organization

### Por Qué Feature-First

❌ **Layer-First (NO usar):**

```
lib/
├── controllers/
│   ├── gossip_controller.dart
│   ├── auth_controller.dart
│   └── location_controller.dart
├── models/
│   ├── gossip_model.dart
│   ├── user_model.dart
│   └── location_model.dart
└── screens/
    ├── home_screen.dart
    ├── login_screen.dart
    └── add_gossip_screen.dart
```

**Problemas:**
- ❌ Código de un feature disperso en 10 carpetas
- ❌ Difícil eliminar features
- ❌ Merge conflicts frecuentes
- ❌ No escala con equipos

---

✅ **Feature-First (Usar):**

```
lib/
├── features/
│   ├── gossip/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── auth/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── core/
```

**Ventajas:**
- ✅ Todo lo de gossip en `features/gossip/`
- ✅ Eliminar feature = eliminar carpeta
- ✅ Features independientes (menos merge conflicts)
- ✅ Escala con equipos grandes

---

### Reglas Feature-First

1. **Features NO dependen entre sí**
   - ❌ `gossip` NO importa de `auth`
   - ✅ Usar `core/` para código compartido

2. **Feature = Bounded Context**
   - Cada feature es un módulo independiente
   - Puede tener su propio lenguaje (ubiquitous language)

3. **Core = Transversal**
   - `core/error/`: Usado por todos
   - `core/logging/`: Usado por todos
   - `core/theme/`: Usado por todos

---

## Domain-Driven Design (DDD)

### Bounded Contexts

**Cada feature es un bounded context:**

| Feature | Bounded Context | Lenguaje |
|---------|----------------|----------|
| `gossip` | Gestión de chismes | Gossip, ModerationStatus, ReportReason |
| `auth` | Autenticación | User, SignIn, SignUp, EmailVerified |
| `location` | Ubicaciones | Country, Region, City |
| `home` | Feed principal | FeedType, FollowingTab, PopularTab |

**Reglas:**
- Cada contexto tiene su propio lenguaje
- NO compartir modelos entre contextos
- Comunicación via `core/` o eventos

---

### Entities

**Entity** = Objeto con identidad única (ID).

**Características:**
- Tiene `id` único
- Tiene lifecycle propio (creado, modificado, eliminado)
- Igualdad por `id`, NO por atributos

**Ejemplos en Chismes:**

```dart
// Gossip: Entity
class Gossip extends Equatable {
  final String id; // ← Identidad única
  final String subject;
  final String content;
  final GossipStatus status;
  final ModerationStatus moderationStatus;
  final DateTime createdAt;
  // ...
  
  @override
  List<Object?> get props => [id, ...]; // ← id en props
}

// User: Entity
class User extends Equatable {
  final String id; // ← Identidad única
  final String email;
  final bool emailVerified;
  // ...
  
  @override
  List<Object?> get props => [id, ...];
}
```

**Por qué son Entities:**
- ✅ Tienen `id` único
- ✅ Dos gossips con mismo contenido pero diferente `id` son distintos
- ✅ Tienen lifecycle (creado, modificado, eliminado)

---

### Value Objects

**Value Object** = Objeto sin identidad, definido por sus atributos.

**Características:**
- NO tiene `id`
- Inmutable
- Igualdad por valor (todos sus atributos)
- Parte de una Entity

**Ejemplos en Chismes:**

```dart
// ReportReason: Value Object
@immutable
class ReportReason extends Equatable {
  final ReportReasonType type;
  final String description;
  
  const ReportReason({required this.type, required this.description});
  
  @override
  List<Object?> get props => [type, description]; // ← Sin id
}

// GossipQuery: Value Object
@immutable
class GossipQuery extends Equatable {
  final String? cityId;
  final GossipStatus? status;
  final int limit;
  
  const GossipQuery({this.cityId, this.status, this.limit = 20});
  
  @override
  List<Object?> get props => [cityId, status, limit];
}
```

**Por qué son Value Objects:**
- ✅ NO tienen `id`
- ✅ Inmutables
- ✅ Igualdad por valor
- ✅ Parte de Entity (Gossip)

**Ver más:** → `.claude/PATTERNS.md#value-objects`

---

### Aggregate Roots

**Aggregate Root** = Entity que controla acceso a un grupo de objetos relacionados.

#### Concepto

Un **Aggregate** es un cluster de objetos de dominio tratado como una unidad. El **Aggregate Root** es la única entrada al aggregate.

**Reglas:**
1. Referencias externas solo al Root, nunca a hijos
2. Root garantiza invariantes del aggregate
3. Transacciones respetan límites del aggregate
4. Root se persiste/carga como unidad

---

#### ✅ Aggregate Root en Chismes: Gossip

**Estructura del Aggregate:**

```
Gossip (Aggregate Root)
├── id (identidad)
├── subject, content (atributos)
├── status, moderationStatus (atributos)
├── imageUrl, thumbnailUrl (Media - parte del aggregate)
├── countryId, regionId, cityId (Location - parte del aggregate)
├── reportedCount (contador - protegido por Root)
└── createdBy, createdAt (audit - parte del aggregate)
```

**Por qué Gossip es Aggregate Root:**

1. **Controla Media URLs:**
   - `imageUrl`, `thumbnailUrl`, `audioUrl` son parte de Gossip
   - NO existen independientemente
   - NO se accede a Media sin pasar por Gossip

2. **Garantiza Invariantes:**
   - Si `status = deleted`, entonces `deletedAt != null`
   - Si `moderationStatus = approved`, entonces `status = published`
   - `reportedCount` solo se modifica via método controlado

3. **Límite de Transacción:**
   - Crear Gossip + Upload Media = 1 transacción
   - Eliminar Gossip → Elimina Media asociado
   - TODO o NADA (atomicidad)

4. **Referencia Externa:**
   - ✅ `gossipId` para referenciar desde fuera
   - ❌ NO referenciar `imageUrl` directamente desde otro aggregate

---

#### Ejemplo: Crear Gossip con Media (Atómico)

**Edge Function (servidor):**

```sql
BEGIN; -- Iniciar transacción

-- 1. Validar y subir imagen a cuarentena
INSERT INTO storage.objects (bucket_id, name, ...) 
VALUES ('quarantine', 'image.jpg', ...);

-- 2. Validar contenido (IA moderación)
-- Si rechaza: ROLLBACK; (elimina imagen de cuarentena)

-- 3. Mover imagen a público
UPDATE storage.objects 
SET bucket_id = 'gossips' 
WHERE id = ...;

-- 4. Insertar gossip (Aggregate Root)
INSERT INTO gossips (
  id, subject, content, 
  image_url, thumbnail_url,  -- ← Media como parte del aggregate
  status, moderation_status, ...
) VALUES (...);

COMMIT; -- TODO exitoso
```

**Por qué es Aggregate:**
- ✅ Gossip + Media se crean/eliminan juntos
- ✅ Root garantiza: si `imageUrl` existe, archivo existe
- ✅ Transacción atómica
- ✅ NO archivos huérfanos

---

#### Ejemplo: Reportar Gossip (Root Protege Invariantes)

```dart
// Domain: UseCase
@injectable
class ReportGossip {
  final GossipRepository _repository;
  
  Future<Result<Failure, void>> call({
    required String gossipId,
    required ReportReason reason,
  }) async {
    // Repository garantiza invariantes del Aggregate
    return _repository.reportGossip(
      gossipId: gossipId,
      reason: reason,
    );
  }
}

// Data: Repository
class GossipRepositoryImpl implements GossipRepository {
  @override
  Future<Result<Failure, void>> reportGossip({
    required String gossipId,
    required ReportReason reason,
  }) async {
    // Edge Function garantiza:
    // 1. Incrementar reportedCount
    // 2. Si reportedCount >= 3 → moderationStatus = 'flagged'
    // 3. Si flagged → status = 'hidden'
    // TODO atómico, Gossip mantiene invariantes
    await _remote.reportGossip(gossipId, reason);
    return Result.success(null);
  }
}
```

**Invariante protegido por Root:**
- `reportedCount >= 3` → `moderationStatus = flagged`
- `moderationStatus = flagged` → `status = hidden`

**Root (Gossip) garantiza consistencia.**

---

#### ❌ Anti-Pattern: Acceso Directo a Hijos

```dart
// ❌ MAL: Acceder a Media sin pasar por Gossip
class MediaService {
  Future<void> deleteImage(String imageUrl) async {
    await _storage.delete(imageUrl);
    // ❌ Image eliminado pero Gossip.imageUrl sigue apuntando
    // ❌ Inconsistencia: Aggregate roto
  }
}

// ✅ BIEN: Eliminar via Aggregate Root
class DeleteGossip {
  Future<Result<Failure, void>> call(String gossipId) async {
    // Repository elimina Gossip + Media atómicamente
    return _repository.delete(gossipId);
  }
}
```

---

#### Reglas Aggregate Root en Chismes

1. **Gossip es Root:**
   - Media URLs son parte de Gossip
   - Location IDs son parte de Gossip
   - Audit fields son parte de Gossip

2. **Transacciones atómicas:**
   - Crear Gossip + Upload Media = 1 transacción
   - Eliminar Gossip → Cascade delete Media

3. **Referencias externas:**
   - ✅ Usar `gossipId` para referenciar
   - ❌ NO usar `imageUrl` directamente

4. **Invariantes:**
   - Root garantiza consistencia interna
   - Validación en UseCase + Repository

---

### Ubiquitous Language

**Cada feature tiene su lenguaje:**

#### Feature: Gossip

- `Gossip`: Chisme publicado por usuario
- `ModerationStatus`: Estado de moderación (pending, approved, rejected, flagged)
- `GossipStatus`: Estado de publicación (draft, published, hidden, deleted)
- `ReportReason`: Razón de reporte
- `PublishAs`: Publicar como anónimo o perfil

#### Feature: Auth

- `User`: Usuario del sistema
- `EmailVerified`: Email verificado o no
- `SignIn`: Iniciar sesión
- `SignUp`: Registrarse
- `OTP`: One-Time Password (código verificación)

**Ventaja:** Código legible sin necesidad de documentación.

---

## Flujo de Datos

### Crear Gossip (Ejemplo Completo)

```
1. User taps "Publicar"
   ↓
2. AddGossipScreen
   ↓ llama
3. AddGossipController.submit()
   ↓ llama
4. CreateGossip UseCase
   ↓ valida con
5. GossipValidator
   ↓ llama
6. GossipRepository (interface)
   ↓ implementada por
7. GossipRepositoryImpl
   ↓ llama
8. SupabaseGossipRemoteDataSource
   ↓ HTTP POST
9. Supabase Edge Function
   ↓ SQL INSERT
10. PostgreSQL Database
   ↓ retorna
11. GossipModel (DTO)
   ↓ convierte a
12. Gossip (Entity)
   ↓ retorna Result<Failure, Gossip>
13. Controller actualiza estado
   ↓ notifica
14. UI se reconstruye
```

---

### Leer Gossips (con Cache)

```
1. HomeScreen.initState()
   ↓
2. HomeTabController.loadGossips()
   ↓
3. GetGossips UseCase
   ↓
4. GossipRepository (interface)
   ↓
5. GossipRepositoryImpl
   ↓
6. try: SupabaseGossipRemoteDataSource
   ↓ SUCCESS → cache en
7. SharedPrefsGossipLocalDataSource
   ↓ retorna List<GossipModel>
   ↓
8. Repository convierte Model → Entity
   ↓
9. Result.success(List<Gossip>)
   ↓
10. Controller actualiza estado
    ↓
11. UI renderiza GossipCards

--- SI FALLA REMOTE ---

6. catch: SupabaseGossipRemoteDataSource
   ↓
7. fallback: SharedPrefsGossipLocalDataSource
   ↓ retorna cached List<GossipModel>
   ↓
8. Repository convierte Model → Entity
   ↓
9. Result.success(List<Gossip>) [from cache]
```

---

## Dependency Rule

### Regla de Oro

> **Dependencias SIEMPRE apuntan hacia adentro (hacia Domain).**

```
Presentation → Domain ← Data
```

**Permitido:**
- ✅ Presentation importa Domain
- ✅ Data implementa interfaces Domain
- ✅ Core importado por todos

**Prohibido:**
- ❌ Domain importa Presentation
- ❌ Domain importa Data
- ❌ Presentation importa Data (saltar Domain)

---

### Ejemplo: Imports

**✅ CORRECTO:**

```dart
// Presentation
import '../../domain/entities/gossip.dart';           // ✅ Presentation → Domain
import '../../domain/usecases/create_gossip.dart';    // ✅ Presentation → Domain
import '../../../../core/theme/app_spacing.dart';     // ✅ Presentation → Core

// Domain
import '../../../../core/result/result.dart';         // ✅ Domain → Core
import '../../../../core/error/failure.dart';         // ✅ Domain → Core

// Data
import '../../domain/entities/gossip.dart';           // ✅ Data → Domain
import '../../domain/repositories/gossip_repository.dart'; // ✅ Data → Domain
```

**❌ INCORRECTO:**

```dart
// Domain
import '../../presentation/controllers/gossip_controller.dart'; // ❌ Domain → Presentation

// Domain
import '../../data/models/gossip_model.dart';        // ❌ Domain → Data

// Presentation
import '../../data/repositories/gossip_repository_impl.dart'; // ❌ Presentation → Data
```

---

### Verificar Dependency Rule

```bash
# Verificar que Domain NO importa de Presentation
grep -r "import.*presentation" lib/features/*/domain/

# Verificar que Domain NO importa de Data
grep -r "import.*data" lib/features/*/domain/

# Ambos deben retornar vacío ✅
```

---

## Convenciones

### Archivos

```
snake_case.dart
add_gossip_controller.dart
gossip_repository_impl.dart
```

### Clases

```dart
PascalCase
GossipModel
AddGossipController
GossipRepositoryImpl
```

### Variables/Métodos

```dart
camelCase
getUserById()
_privateMethod()
```

### Constantes

```dart
const kMaxLength = 200;  // Globales con k
AppSpacing.lg             // Sin k (es clase)
```

---

## Anti-Patterns

### 1. God Class

```dart
// ❌ MAL: Clase hace TODO
class GossipManager {
  void validate() {}
  void save() {}
  void notify() {}
  void moderate() {}
}

// ✅ BIEN: Separar responsabilidades
class GossipValidator {}
class GossipRepository {}
class GossipNotifier {}
class GossipModerator {}
```

### 2. Anemic Domain

```dart
// ❌ MAL: Entities sin comportamiento
class Gossip {
  String id;
  String subject;
  // Solo getters/setters
}

// ✅ BIEN: Entities con comportamiento
class Gossip {
  final String id;
  final String subject;
  
  bool get isApproved => moderationStatus == ModerationStatus.approved;
  bool get isPublic => visibility == GossipVisibility.public;
}
```

### 3. Leaky Abstraction

```dart
// ❌ MAL: Repository expone detalles de implementación
abstract class GossipRepository {
  Future<SupabaseResponse> getGossips(); // ← Supabase en interface
}

// ✅ BIEN: Interface independiente de implementación
abstract class GossipRepository {
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);
}
```

---

## Recursos

- **Clean Architecture (Uncle Bob):** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **DDD (Eric Evans):** https://www.domainlanguage.com/ddd/
- **Feature-First:** https://codewithandrea.com/articles/flutter-project-structure/
- **Aggregate Pattern:** https://martinfowler.com/bliki/DDD_Aggregate.html

---

**Última actualización:** 2026-11-12  
**Versión:** 2.0 (Actualizado con Aggregate Roots)  
**Mantenedor:** Alejo

**FIN DEL DOCUMENTO**
