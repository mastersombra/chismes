# CLAUDE.md - Chismes App - Quick Reference

> **Quick reference del proyecto.** Este archivo se carga automáticamente al iniciar cada sesión de Claude Code. Contiene referencias esenciales y el índice a documentación detallada.

**Última actualización:** 2026-10-20  
**Versión:** 3.0 (Reorganizado)

---

## 👤 ROL Y CONTEXTO

**Actúa siempre como:**

> **Senior Flutter Engineer, Software Architect, Supabase Senior, Mobile App Reviewer**, especialista en **Clean Architecture, Dart, Flutter, testing, seguridad, escalabilidad**.

**Comportamiento esperado:**
- ✅ Siempre pregunta opciones cuando hay trade-offs (no decidas solo)
- ✅ Revisa archivos necesarios antes de implementar
- ✅ Propone soluciones pero deja elegir al usuario
- ✅ Explica el POR QUÉ de las decisiones técnicas
- ❌ NO implementes sin entender el contexto completo
- ❌ NO tomes decisiones arquitectónicas sin consultar

---

## 🧠 GRAFO DE CONOCIMIENTO

**Al iniciar esta sesión, un hook ejecutó automáticamente el análisis del proyecto.**

**Grafo disponible:** `tools/knowledge-graph/output/graph.json`

Si necesitas información sobre estructura, dependencias o impacto:
- Lee el grafo: `tools/knowledge-graph/output/graph.json`
- Contiene: nodos (archivos), edges (dependencias), stats del proyecto

**El grafo se regenera automáticamente cada sesión nueva.**

---

## 📐 ARQUITECTURA RÁPIDA

### Clean Architecture + Feature-First

```
lib/
├── core/                    # Código compartido transversal
│   ├── audit/              # Auditoría
│   ├── auth/               # Autenticación
│   ├── config/             # Configuración
│   ├── di/                 # DI (Injectable/GetIt)
│   ├── error/              # Error handling (Failure, Result)
│   ├── logging/            # ⭐ AppLogger, RemoteLogger
│   ├── media/              # Media services
│   ├── services/           # Services globales
│   ├── theme/              # ⭐ AppSpacing, AppColors, AppRadius
│   └── validation/         # ⭐ FormValidators
│
├── features/               # Features (módulos funcionales)
│   └── gossip/            # Feature principal
│       ├── data/          # Data Layer (DataSources, Models, Repositories)
│       ├── domain/        # Domain Layer (Entities, UseCases, Validators)
│       └── presentation/  # Presentation Layer (Controllers, Screens, Widgets)
│
└── shared/                # Código compartido (legacy)
```

**Flujo de Dependencias:**
```
Presentation ──> Domain ──> Data
```

**Reglas CRÍTICAS:**
1. Presentation depende de Domain (NUNCA de Data)
2. Domain define interfaces, Data las implementa
3. Repository SIEMPRE retorna `Result<Failure, Success>`
4. Features NO dependen entre sí (usar Core)

**Ver detalles completos:** → `.claude/ARCHITECTURE.md`

---

## 🎨 UI/UX ESENCIALES

### Portrait-Only 📱

App bloqueada en modo portrait (vertical). No landscape.

**Ver configuración:** → `.claude/UI_STANDARDS.md`

### AppSpacing ⭐ CRÍTICO

**NUNCA uses números mágicos para espaciado.**

```dart
import '../../../../core/theme/app_spacing.dart';

// Valores (múltiplos de 4)
AppSpacing.xs    // 4px
AppSpacing.sm    // 8px
AppSpacing.md    // 12px
AppSpacing.lg    // 16px (base)
AppSpacing.xl    // 24px
AppSpacing.xxl   // 32px
AppSpacing.xxxl  // 48px

// Uso
padding: const EdgeInsets.all(AppSpacing.lg)
const SizedBox(height: AppSpacing.md)
```

**❌ INCORRECTO:**
```dart
padding: const EdgeInsets.all(16)  // NO
const SizedBox(height: 12)         // NO
```

**Ver guía completa:** → `.claude/UI_STANDARDS.md`

### FormValidators ⭐

**Dos tipos de validación:**

| Tipo | Ubicación | Uso |
|------|-----------|-----|
| **FormValidators** | `core/validation/` | UI (TextFormField) |
| **Domain Validators** | `features/*/domain/validators/` | Business logic |

```dart
// ✅ FormValidators (UI)
TextFormField(
  validator: (v) => FormValidators.required(v, 'título'),
)

// ✅ Domain Validators (Business)
final validation = GossipValidator.validateSubject(input.subject);
if (validation != null) return Result.failure(validation);
```

**Ambos son necesarios:** FormValidators → UX, Domain Validators → Seguridad

**Ver guía completa:** → `.claude/UI_STANDARDS.md`

---

## 🗄️ SUPABASE ESENCIAL

### Nomenclatura

```sql
-- Tablas: snake_case, plural
gossips
location_countries

-- Columnas: snake_case
created_at
country_id

-- Timestamps: SIEMPRE TIMESTAMPTZ
created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
```

**En Dart:**
```dart
// Model (Data) - match DB
final String created_at;   // snake_case

// Entity (Domain) - Dart convention
final DateTime createdAt;  // camelCase

// Conversión en Model.toEntity()
createdAt: DateTime.parse(created_at),
```

### Migraciones vs Seeds

| Tipo | Archivo | Contenido | Cuándo |
|------|---------|-----------|--------|
| **Migraciones** | `migrations/*.sql` | DDL (CREATE, ALTER) | Secuencial (001, 002...) |
| **Seeds** | `seed.sql` | DML (INSERT países) | Después migraciones |

```bash
# Aplicar todo (dev)
supabase db reset --linked

# Nueva migración
supabase migration new descriptive_name
```

**Ver detalles completos:** → `.claude/SUPABASE.md`

---

## 📝 NAMING CONVENTIONS

```dart
// Archivos
snake_case.dart
add_gossip_controller.dart

// Clases
PascalCase
GossipModel, Gossip, GossipRepository

// Variables/Métodos
camelCase
getUserById(), _privateMethod()

// Constantes
const kMaxLength = 200;  // Globales con k
AppSpacing.lg            // Sin k (es clase)

// Enums
enum GossipStatus { draft, published }
```

---

## 🏗️ PATRONES ESENCIALES

### Repository Pattern

```dart
// Domain: Interface
abstract class GossipRepository {
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);
}

// Data: Implementation
@Singleton(as: GossipRepository)
class GossipRepositoryImpl implements GossipRepository {
  // Cache strategy: write-through, fallback
}
```

### Result Pattern ⭐

**NUNCA lanzar excepciones desde repositories.**

```dart
// ✅ CORRECTO
Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
  try {
    final model = await remoteDataSource.create(input);
    return Result.success(model.toEntity());
  } catch (error) {
    return Result.failure(ErrorHandler.handleError(error));
  }
}

// Uso
result.fold(
  onFailure: (failure) => _handleError(failure),
  onSuccess: (gossip) => _handleSuccess(gossip),
);
```

### Dependency Injection

```dart
// Registro
@injectable
class MyService {}

@singleton
class MySingleton {}

@Singleton(as: MyInterface)
class MyImplementation implements MyInterface {}

// Uso
final service = getIt<MyService>();

// Regenerar
flutter pub run build_runner build --delete-conflicting-outputs
```

**Ver patrones completos:** → `.claude/PATTERNS.md`

---

## 🎯 DECISIONES ARQUITECTÓNICAS (ADRs)

### ADR-001: Clean Architecture + Feature-First
**Por qué:** Escalabilidad, testabilidad, mantenibilidad

### ADR-002: Result Pattern (vs Exceptions)
**Por qué:** Errores explícitos, type-safe, errores son flujo normal en móviles

### ADR-003: String Simple para Media URLs
**Por qué:** MVP simple, `MediaReference` complejo es overkill

### ADR-004: Supabase (vs Firebase)
**Por qué:** PostgreSQL nativo, RLS, costos ($2-4k vs $35-45k con 4-5M usuarios)

### ADR-005: Sequential Migrations
**Por qué:** Equipo pequeño, más legible

### ADR-006: AppLogger + Supabase (vs Sentry)
**Por qué:** Control de datos, $0 adicional

### ADR-007: Injectable/GetIt (vs Provider/Riverpod)
**Por qué:** DI puro, testable

### ADR-008: SharedPreferences Cache
**Por qué:** Simple, suficiente para ~100 gossips

---

## 📸 MEDIA STRATEGY

| Aspecto | Especificación |
|---------|----------------|
| Resolución | 800×800 px |
| Formato | JPEG |
| Calidad | 75% |
| Tamaño | 100-150 KB (max 300 KB) |

**Compresión automática con `flutter_image_compress`**

---

## 🛡️ MODERACIÓN

### Estados

| Campo | Valores |
|-------|---------|
| status | `draft`, `published`, `hidden`, `deleted` |
| moderationStatus | `pending`, `approved`, `rejected`, `flagged` |
| visibility | `public`, `private`, `followers` |

### Flujo

```
Usuario crea → draft+pending → [Motor IA] → 
  ✅ approved+published 
  ❌ flagged/rejected+hidden
```

**Ver flujo completo:** → `docs/moderation_mvp.md`

---

## 📊 LOGGING ⭐

### Uso

```dart
@injectable
class MyService {
  final AppLogger _logger;
  
  MyService(this._logger);
  
  Future<void> operate() async {
    _logger.i('Operation started');
    
    try {
      // Logic
      _logger.i('Success', context: {'id': result.id});
    } catch (error, stackTrace) {
      _logger.e('Failed',
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'operate'},
      );
    }
  }
}
```

### Niveles

```dart
_logger.d('Debug');      // Solo desarrollo
_logger.i('Info');       // Info general
_logger.w('Warning');    // Situación anormal
_logger.e('Error');      // Error → persiste en Supabase
_logger.f('Fatal');      // Fatal → persiste en Supabase
```

**Persistencia:** `error` y `fatal` → Supabase `error_logs`

**Ver implementación:** → `docs/implementation_logging_observability.md`

---

## ⚠️ ERROR HANDLING

```dart
// Repository/UseCase SIEMPRE retorna Result
Future<Result<Failure, T>> method() async {
  try {
    // Logic
    return Result.success(data);
  } catch (error) {
    return Result.failure(ErrorHandler.handleError(error));
  }
}
```

**Ver patrones:** → `.claude/PATTERNS.md`

---

## 🔐 SECURITY

### Secrets (.env)

```bash
# .env (NUNCA commitear)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
# SUPABASE_SERVICE_ROLE_KEY solo backend

# .gitignore (verificar)
.env
.env.*
```

### Validación

**SIEMPRE dos capas:**
1. FormValidators (UI)
2. Domain Validators (Business)

### SQL Injection

```dart
// ✅ CORRECTO: Supabase sanitiza
await supabase.from('gossips').select().eq('id', userId)

// ❌ INCORRECTO: Concatenación
final query = "SELECT * FROM gossips WHERE id = '$userId'";  // NO
```

### RLS

**SIEMPRE habilitar RLS:**

```sql
ALTER TABLE gossips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "policy_name"
  ON gossips FOR SELECT
  USING (status = 'published');
```

**Ver guía completa:** → `.claude/SECURITY.md`

---

## 🧪 TESTING

### ⚠️ REGLA CRÍTICA

**Tests NO modifican código de producción.**

```
❌ MAL: Cambiar código de producción para pasar tests
✅ BIEN: Adaptar tests al código existente
```

### Pattern AAA

```dart
test('debe retornar gossips', () async {
  // Arrange
  when(mockRemote.get()).thenAnswer((_) async => [model]);
  
  // Act
  final result = await repository.get();
  
  // Assert
  expect(result.isSuccess, isTrue);
  verify(mockRemote.get()).called(1);
});
```

### Coverage

**Estado:** ✅ **78.9%** (1,865 / 2,363 líneas)  
**Tests:** 1,897 tests totales  
**Objetivo:** Mantener >75% en nuevas features

```bash
# Generar coverage
flutter test --coverage

# Ver HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Ver standards completos:** → `.claude/TESTING.md`

---

## 🛠️ COMANDOS RÁPIDOS

### Development
```bash
flutter run
flutter clean && flutter pub get
```

### Testing
```bash
flutter test
flutter test --coverage
```

### Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Supabase
```bash
supabase db reset --linked
supabase migration new name
```

**Ver todos los comandos:** → `.claude/WORKFLOWS.md`

---

## 📚 ÍNDICE MAESTRO

### Documentación Principal (.claude/)

| Archivo | Contenido |
|---------|-----------|
| **ARCHITECTURE.md** | Arquitectura detallada, capas, features |
| **PATTERNS.md** | Repository, Result, DI, Controllers |
| **TESTING.md** | Standards, AAA, Mocks, Coverage |
| **UI_STANDARDS.md** | AppSpacing, FormValidators, Portrait-only |
| **SECURITY.md** | Secrets, Validación, RLS, SQL injection |
| **SUPABASE.md** | Backend, migraciones, RLS, nomenclatura |
| **WORKFLOWS.md** | Agregar feature/migración, comandos |

### Documentación Específica (docs/)

| Archivo | Contenido |
|---------|-----------|
| `audit_add_gossip_module.md` | Feature gossip completo (referencia) |
| `moderation_mvp.md` | Sistema de moderación |
| `LOCATION_FEATURE_IMPLEMENTATION.md` | Feature location |
| `implementation_logging_observability.md` | Sistema de logging |
| `implementation_persistent_cache.md` | Cache local |

---

## 🚀 FEATURES STATUS

### Implementados ✅
- Gossip (CRUD, moderación, cache)
- Location (GPS, autocomplete)
- Logging (estructurado + Supabase)
- Error Handling (Result pattern)
- Cache (SharedPreferences)

### En Desarrollo 🚧
- Auth (login básico)
- Home (feed básico)
- Search (simple)

### Pendientes 📋
- Comments
- Reactions
- Profile completo
- Notifications
- Audio upload

---

## ❗ ANTI-PATTERNS

```dart
// ❌ NO usar print() o debugPrint()
print('Debug');  // Usar _logger.d()

// ❌ NO lanzar excepciones desde repositories
throw Exception();  // Usar Result.failure()

// ❌ NO números mágicos de espaciado
padding: EdgeInsets.all(16);  // Usar AppSpacing.lg

// ❌ NO validaciones inline
validator: (v) { if (v == null) ... }  // Usar FormValidators

// ❌ NO hardcodear strings/secrets
const key = 'sk-xxx';  // Usar .env
```

---

## 🎓 ONBOARDING CHECKLIST

Para nuevas sesiones:

- [ ] Leer este CLAUDE.md (10 min)
- [ ] Revisar `.claude/ARCHITECTURE.md`
- [ ] Revisar `.claude/PATTERNS.md`
- [ ] Ejecutar `flutter test`
- [ ] Revisar feature gossip (referencia)
- [ ] Familiarizarse con Result pattern
- [ ] Familiarizarse con AppSpacing
- [ ] Configurar .env

---

## 📊 MÉTRICAS

**Última actualización:** 2026-10-20

```
Archivos Dart:        ~80
Features:             4 (gossip, location, home, search)
Tests:                1,897 (1,846 pasando)
Coverage:             78.9%
Líneas de código:     ~8,000
Migraciones:          4
```

---

## 🔄 QUICK FLOWS

### Agregar Feature

1. Crear estructura: `data/`, `domain/`, `presentation/`
2. Domain primero (Entities, Repository interface, UseCases)
3. Data (Models, DataSources, Repository impl)
4. Presentation (State, Controller, Screens)
5. Regenerar DI: `flutter pub run build_runner build`
6. Tests

**Ver guía detallada:** → `.claude/WORKFLOWS.md`

### Agregar Migración

1. Crear: `supabase/migrations/{number}_name.sql`
2. Escribir SQL (CREATE, RLS policies)
3. Aplicar: `supabase db reset --linked`

**Ver guía detallada:** → `.claude/WORKFLOWS.md`

### Agregar Logging

```dart
@injectable
class MyService {
  final AppLogger _logger;
  
  MyService(this._logger);
  
  _logger.i('Operation', context: {'key': 'value'});
}
```

**Ver guía detallada:** → `.claude/WORKFLOWS.md`

---

## 📞 AYUDA

### Cuando Necesites Ayuda

1. **Lee este CLAUDE.md** primero
2. **Busca en `.claude/`** archivos específicos
3. **Busca en `docs/`** documentación detallada
4. **Mira ejemplos** en feature gossip (referencia)
5. **Pregunta al usuario** para decisiones técnicas

### Recursos Externos

- Flutter: https://flutter.dev/docs
- Supabase: https://supabase.com/docs
- Injectable: https://pub.dev/packages/injectable
- Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html

---

**Última actualización:** 2026-10-20  
**Versión:** 3.0 (Reorganizado - Compacto)  
**Mantenedor:** Alejo

---

## 🎯 CÓMO USAR ESTA DOCUMENTACIÓN

**Este archivo (CLAUDE.md)** es tu punto de entrada. Contiene:
- ✅ Quick reference de conceptos esenciales
- ✅ Índice maestro a documentación detallada
- ✅ Anti-patterns y reglas críticas

**Para detalles completos:**
- Arquitectura → `.claude/ARCHITECTURE.md`
- Patrones → `.claude/PATTERNS.md`
- Testing → `.claude/TESTING.md`
- UI/UX → `.claude/UI_STANDARDS.md`
- Seguridad → `.claude/SECURITY.md`
- Supabase → `.claude/SUPABASE.md`
- Workflows → `.claude/WORKFLOWS.md`

**FIN DEL DOCUMENTO**
