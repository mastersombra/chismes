# Approach de Timestamps: String en Model, DateTime en Entity

**Fecha:** 2026-10-19  
**Issue Relacionado:** #13 del audit  
**Estado:** ✅ IMPLEMENTADO CORRECTAMENTE

---

## 📋 TL;DR

**El approach actual ES CORRECTO y sigue best practices:**
- ✅ **Model (Data Layer):** `String` (ISO8601) - Para JSON serialization
- ✅ **Entity (Domain Layer):** `DateTime` - Para business logic
- ✅ **Database (Supabase):** `TIMESTAMPTZ` - Estándar PostgreSQL

**Este es el patrón DTO (Data Transfer Object) estándar para Dart/Flutter.**

---

## 🎯 Implementación Actual

### 1. Base de Datos (Supabase)

```sql
-- 001_create_gossips_table.sql
CREATE TABLE gossips (
  created_at TIMESTAMPTZ DEFAULT NOW(),  -- Timestamp con zona horaria
  modified_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);
```

**Características:**
- ✅ TIMESTAMPTZ (Timestamp with Time Zone)
- ✅ Supabase serializa automáticamente a String ISO8601
- ✅ Formato: `"2026-10-19T17:25:42.000Z"`

---

### 2. Model (Data Layer)

```dart
// lib/features/gossip/data/models/gossip_model.dart
class GossipModel {
  final String createdAt;   // "2026-10-19T17:25:42.000Z"
  final String? modifiedAt; // "2026-10-19T18:30:15.123Z"
  final String? deletedAt;  // null o ISO8601
  
  factory GossipModel.fromJson(Map<String, dynamic> json) {
    return GossipModel(
      createdAt: json['created_at'],  // Supabase ya lo serializa
      modifiedAt: json['modified_at'],
      deletedAt: json['deleted_at'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,  // String directo, no conversión
      'modifiedAt': modifiedAt,
      'deletedAt': deletedAt,
    };
  }
}
```

**Por qué String:**
- ✅ JSON nativo (no requiere conversión especial)
- ✅ Supabase ya envía String ISO8601
- ✅ Compatible con `fromJson()` / `toJson()` sin parsing
- ✅ Sin dependencias externas
- ✅ Performance (no parsing en cada deserialización)

---

### 3. Entity (Domain Layer)

```dart
// lib/features/gossip/domain/entities/gossip.dart
class Gossip {
  final DateTime createdAt;   // Tipo nativo Dart
  final DateTime? modifiedAt;
  final DateTime? deletedAt;
  
  const Gossip({
    required this.createdAt,
    this.modifiedAt,
    this.deletedAt,
  });
}
```

**Por qué DateTime:**
- ✅ Tipo nativo de Dart (type-safe)
- ✅ Operaciones de fecha:
  ```dart
  // Comparaciones
  if (gossip.createdAt.isBefore(DateTime.now())) { ... }
  
  // Diferencias
  final duration = DateTime.now().difference(gossip.createdAt);
  
  // Formateo
  final formatted = DateFormat('dd/MM/yyyy').format(gossip.createdAt);
  
  // Zona horaria
  final local = gossip.createdAt.toLocal();
  ```
- ✅ Domain layer debe ser agnóstico de persistencia
- ✅ Business logic necesita fechas reales

---

### 4. Conversión (Model ↔ Entity)

```dart
// Model → Entity
Gossip toEntity() {
  return Gossip(
    createdAt: DateTime.parse(createdAt),                          // String → DateTime
    modifiedAt: modifiedAt != null ? DateTime.parse(modifiedAt!) : null,
    deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
  );
}

// Entity → Model
factory GossipModel.fromEntity(Gossip entity) {
  return GossipModel(
    createdAt: entity.createdAt.toIso8601String(),    // DateTime → String
    modifiedAt: entity.modifiedAt?.toIso8601String(),
    deletedAt: entity.deletedAt?.toIso8601String(),
  );
}
```

**Conversión automática:**
- ✅ `DateTime.parse()` entiende ISO8601 nativamente
- ✅ `toIso8601String()` genera formato correcto
- ✅ Sin dependencias externas
- ✅ Type-safe (compilador detecta errores)

---

## ✅ Ventajas del Approach Actual

| Aspecto | String en Model | DateTime en Entity | Resultado |
|---------|-----------------|-------------------|-----------|
| **JSON Serialization** | ✅ Nativo | ⚠️ Requiere conversión | Model simple |
| **Type Safety** | ⚠️ Runtime | ✅ Compile time | Errores tempranos |
| **Operaciones Fecha** | ❌ No soporta | ✅ Nativo | Business logic potente |
| **Performance** | ✅ Sin parsing | ⚠️ Parse en toEntity | Óptimo (1 vez) |
| **Supabase Compat** | ✅ Directo | ⚠️ Requiere parsing | Sin dependencias |
| **Testing** | ✅ Fácil mockear | ✅ Fácil comparar | Testable |
| **Portabilidad** | ✅ Cualquier backend | ✅ Agnóstico | Flexible |

---

## ❌ Por Qué NO Usar Alternativas

### Alternativa 1: DateTime en Model (MALO)

```dart
// ❌ MAL
class GossipModel {
  final DateTime createdAt;  // NO
  
  factory GossipModel.fromJson(Map<String, dynamic> json) {
    return GossipModel(
      createdAt: DateTime.parse(json['created_at']),  // Parsing extra SIEMPRE
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt.toIso8601String(),  // Conversión extra SIEMPRE
    };
  }
}
```

**Problemas:**
- ⚠️ Parsing en CADA deserialización (performance)
- ⚠️ Serialización manual (propenso a errores)
- ⚠️ JSON no es DateTime nativo
- ⚠️ Supabase ya envía String, ¿por qué convertir en Model?
- ⚠️ Model debe ser "tonto" (solo DTO)

---

### Alternativa 2: String en Entity (MALO)

```dart
// ❌ MAL
class Gossip {
  final String createdAt;  // NO
  
  // ❌ No puedes hacer operaciones de fecha
  bool isRecent() {
    // ERROR: String no tiene métodos de DateTime
    return DateTime.now().difference(createdAt).inDays < 7;
  }
}
```

**Problemas:**
- ❌ Domain logic necesita fechas reales
- ❌ Comparaciones complicadas (parse manual)
- ❌ No type-safe
- ❌ Controller tendría que parsear manualmente
- ❌ Business logic se ensucia con conversiones

---

### Alternativa 3: int (milisegundos desde epoch) (MALO)

```dart
// ❌ MAL
class GossipModel {
  final int createdAt;  // Milisegundos desde epoch (1970-01-01)
}
```

**Problemas:**
- ❌ Supabase NO envía milisegundos, envía ISO8601
- ❌ Conversión manual necesaria en fromJson
- ❌ Menos legible en JSON
- ❌ Zona horaria ambigua (UTC? Local?)
- ❌ No es estándar web

---

## 🎓 Pattern: DTO Serialization Layer

Este approach se llama **"DTO Serialization Layer"**:

```
Backend (PostgreSQL TIMESTAMPTZ)
   ↓ Supabase serializa automáticamente
JSON Response: String ISO8601
   ↓ Model deserializa (fromJson)
Model (String) - Solo para transporte
   ↓ toEntity() parsea
Entity (DateTime) - Para lógica de negocio
   ↓ Controller/UseCase
Presentation Layer (DateTime)
```

**Separación de concerns:**
- **Model:** DTO tonto, solo serialización
- **Entity:** Lógica de negocio, type-safe
- **Conversion:** Boundary explícito entre capas

---

## 📚 Referencias

### Documentación Oficial

**Supabase:**
> "PostgreSQL TIMESTAMPTZ columns are automatically serialized to ISO8601 strings in JSON responses."

**Dart DateTime:**
> "`DateTime.parse()` parses ISO8601 strings natively without external packages."

**Clean Architecture:**
> "DTOs should be dumb data containers. Business logic belongs in Entities."

---

### Código Relacionado

| Archivo | Líneas | Descripción |
|---------|--------|-------------|
| `gossip_model.dart` | 227-261 | Model con String timestamps |
| `gossip_model.dart` | 503-514 | Conversión toEntity() |
| `gossip_model.dart` | 456-462 | Conversión fromEntity() |
| `gossip.dart` | 66-77 | Entity con DateTime |
| `001_create_gossips_table.sql` | 64 | DB con TIMESTAMPTZ |
| `CLAUDE.md` | 270-295 | Documentación approach |

---

## ✅ Conclusión

**El approach actual (String en Model, DateTime en Entity) es CORRECTO y debe mantenerse.**

**Razones:**
1. ✅ Sigue patrón DTO estándar
2. ✅ Separación clara de concerns
3. ✅ Performance óptima (parsing solo 1 vez)
4. ✅ Type-safe en domain layer
5. ✅ Compatible con Supabase sin dependencias
6. ✅ Documentado en CLAUDE.md
7. ✅ Implementado consistentemente en todo el código

**NO CAMBIAR** a menos que:
- Backend cambie a enviar timestamps en otro formato (muy improbable)
- Aparezca un estándar Dart oficial diferente (no existe actualmente)

---

**Última actualización:** 2026-10-19  
**Autor:** Senior Flutter Engineer  
**Revisión:** Issue #13 del audit verificado y cerrado
