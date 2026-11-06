# Máquina de Estados del Gossip

⚠️ **IMPORTANTE**: Definir la máquina de estados antes de producción para evitar combinaciones ambiguas.

## Enums Actualizados (MVP)

### GossipStatus
- `draft` - Creado, motor automático revisando
- `published` - Publicado (visible según visibility)
- `hidden` - Oculto (corrección pendiente o rechazado)
- `deleted` - Eliminado (soft delete, se conserva en BD)

### ModerationStatus
- `pending` - Pendiente de revisión automática
- `approved` - Aprobado (por motor automático o moderador manual)
- `rejected` - Rechazado (por motor automático o moderador manual)
- `flagged` - Reportado por usuarios

## Combinaciones Válidas (MVP)

|| GossipStatus | ModerationStatus | Significado | ¿Válido? |
||--------------|------------------|-------------|----------|
|| `draft` | `pending` | Creado, motor automático revisando | ✅ Sí |
|| `draft` | `rejected` | Motor detectó problema, usuario debe corregir | ✅ Sí |
|| `published` | `approved` | Publicado y aprobado | ✅ Sí |
|| `hidden` | `flagged` | Reportado por usuarios, oculto para corrección | ✅ Sí |
|| `hidden` | `rejected` | Rechazado por moderación (auto o manual) | ✅ Sí |
|| `deleted` | `cualquiera` | Eliminado (soft delete), estado de moderación irrelevante | ✅ Sí |
|| `published` | `pending` | ❌ Contradictorio (no puede estar publicado sin aprobación) | ❌ No |
|| `published` | `rejected` | ❌ Contradictorio (no puede estar publicado si fue rechazado) | ❌ No |
|| `published` | `flagged` | ❌ Contradictorio (si está flag, debería estar hidden) | ❌ No |
|| `draft` | `approved` | ❌ Contradictorio (si está aprobado, debería estar published) | ❌ No |
|| `draft` | `flagged` | ❌ Contradictorio (si está flag, debería estar hidden) | ❌ No |
|| `hidden` | `pending` | ❌ Contradictorio (si está pending, debería estar en draft) | ❌ No |
|| `hidden` | `approved` | ❌ Contradictorio (si está aprobado, debería estar published) | ❌ No |
|| `deleted` | `pending` | ❌ Contradictorio (si está pending, no debería estar eliminado) | ❌ No |

## Transiciones Permitidas

### Flujo Normal de Creación
```
Usuario crea chisme
  ↓
draft + pending
  ↓
[motor automático revisa]
  ↓
published + approved (si motor aprueba)
  ↓
draft + rejected (si motor detecta problema)
  ↓
[usuario corrige]
  ↓
draft + pending (revisa de nuevo)
```

### Flujo de Reportes (Combinado: 3+ denuncias OR ratio > 5% OR categoría severa)
```
published + approved
  ↓
[usuarios reportan]
  ↓
Si (reportedCount >= 3 OR reportedCount/viewCount > 0.05 OR categoría severa)
  ↓
hidden + flagged
  ↓
[moderador humano revisa]
  ↓
Si es reporte falso:
  ↓
published + approved (restaura)
  ↓
Si es reporte verdadero (categoría menor):
  ↓
[usuario puede editar y reenviar]
  ↓
draft + pending (revisión automática)
  ↓
Si es reporte verdadero (categoría severa):
  ↓
deleted + flagged (elimina sin opción de editar)
  ↓
[incrementa incidentCount del usuario]
```

### Flujo de Eliminación (Soft Delete)
```
[cualquier estado]
  ↓
deleted + [mantiene moderationStatus anterior]
  ↓
[se conserva en BD para auditoría]
```

## Reglas de Negocio

### 1. Solo el Backend Controla Transiciones
- El cliente NO puede cambiar `status` directamente
- El cliente NO puede cambiar `moderationStatus` directamente
- Cloud Functions o Security Rules controlan las transiciones

### 2. Estrategia de Reportes (Opción D: Combinada)
Activar revisión si CUALQUIERA de estas condiciones se cumple:
- **3+ denuncias totales** (reportedCount >= 3)
- **Ratio denuncias/vistas > 5%** (reportedCount / viewCount > 0.05)
- **Categoría de reporte es severa** (credibleThreat, sexualContentInvolvingMinors, potentialSelfHarm)

### 3. Feedback del Motor Automático
- **NO informar detalles específicos** al usuario
- Mensaje genérico: "Tu chisme no cumple con nuestras normas de comunidad"
- Razonamiento: Evitar enseñar a evadir los filtros

### 4. Contenido Severo vs Menor
**Categorías severas (eliminación inmediata):**
- credibleThreat
- sexualContentInvolvingMinors
- potentialSelfHarm

**Categorías menores (permite corrección):**
- potentialProfanity
- potentialHarassment
- potentialSpam

### 5. Tracking de Usuario (MVP: Opción A)
```dart
// En documento de usuario en Firestore
{
  "incidentCount": 3,              // Total de incidentes severos
  "lastIncidentAt": "2026-09-28T10:00:00Z",
  "suspended": false,
  "suspendedAt": null
}
```

**Evolución futura:** Si se detecta patrón de abuso, migrar a Opción C (contador + historial en colección separada).

### 6. Contador de Vistas (MVP: Opción A)
```dart
// En Gossip entity
final int viewCount; // Nuevo campo
```

**Implementación:**
- Cloud Function incrementa `viewCount` atómicamente
- Firestore Security Rules prohiben escritura directa del cliente
- No distingue usuarios únicos (suficiente para MVP)

**Evolución futura:** Si se detecta abuso de refrescos, migrar a tracking por usuario único.

### 7. Soft Delete
- Los chismes NUNCA se borran físicamente de la BD
- Solo cambian a estado `deleted`
- Se conservan para:
  - Auditoría de contenido
  - Revisión de historial de usuario
  - Investigación de patrones de abuso
  - Apelaciones

### 8. Validación de Combinaciones
En backend, validar que las combinaciones sean válidas antes de permitir escritura:

```javascript
// Firestore Security Rules o Cloud Functions
allow write: if (
  (request.resource.data.status == 'draft' && request.resource.data.moderationStatus == 'pending') ||
  (request.resource.data.status == 'draft' && request.resource.data.moderationStatus == 'rejected') ||
  (request.resource.data.status == 'published' && request.resource.data.moderationStatus == 'approved') ||
  (request.resource.data.status == 'hidden' && request.resource.data.moderationStatus == 'flagged') ||
  (request.resource.data.status == 'hidden' && request.resource.data.moderationStatus == 'rejected') ||
  (request.resource.data.status == 'deleted')
);
```

## Implementación en Dart

### Validador de Estados

```dart
class GossipStateMachine {
  /// Valida si una combinación de status y moderationStatus es válida
  static bool isValidCombination(GossipStatus status, ModerationStatus moderationStatus) {
    // Combinaciones válidas como set de tuples
    final validCombinations = {
      (GossipStatus.draft, ModerationStatus.pending),
      (GossipStatus.draft, ModerationStatus.rejected),
      (GossipStatus.published, ModerationStatus.approved),
      (GossipStatus.hidden, ModerationStatus.flagged),
      (GossipStatus.hidden, ModerationStatus.rejected),
    };

    // deleted puede tener cualquier moderationStatus
    if (status == GossipStatus.deleted) {
      return true;
    }

    return validCombinations.contains((status, moderationStatus));
  }

  /// Valida si una transición es permitida
  static bool isValidTransition(
    GossipStatus fromStatus,
    ModerationStatus fromModeration,
    GossipStatus toStatus,
    ModerationStatus toModeration,
  ) {
    // Solo backend debe permitir transiciones
    // Cliente no puede cambiar status o moderationStatus directamente
    return false;
  }

  /// Valida si debe activarse revisión por reportes
  static bool shouldTriggerModerationReview({
    required int reportedCount,
    required int viewCount,
    required ModerationReason? reportCategory,
  }) {
    // Opción D: Combinada
    final hasEnoughReports = reportedCount >= 3;
    final hasHighRatio = viewCount > 0 && (reportedCount / viewCount) > 0.05;
    final isSevereCategory = _isSevereCategory(reportCategory);

    return hasEnoughReports || hasHighRatio || isSevereCategory;
  }

  /// Determina si una categoría es severa (eliminación inmediata)
  static bool isSevereCategory(ModerationReason category) {
    return _isSevereCategory(category);
  }

  static bool _isSevereCategory(ModerationReason? category) {
    if (category == null) return false;

    const severeCategories = {
      ModerationReason.credibleThreat,
      ModerationReason.sexualContentInvolvingMinors,
      ModerationReason.potentialSelfHarm,
    };

    return severeCategories.contains(category);
  }
}
```

### Validadoren GossipValidator

```dart
class GossipValidator {
  static ValidationFailure? validateStatusCombination({
    required GossipStatus gossipStatus,
    required ModerationStatus moderationStatus,
  }) {
    if (!GossipStateMachine.isValidCombination(gossipStatus, moderationStatus)) {
      return ValidationFailure(
        code: ErrorCode.invalidStatusCombination,
        fieldErrors: {
          'status': 'Invalid combination: $gossipStatus + $moderationStatus',
        },
      );
    }

    return null;
  }
}
```

## Cambios en Entities

### Gossip Entity (Agregar campos)

```dart
class Gossip extends Equatable implements Auditable {
  // ... campos existentes ...

  final GossipStatus status;
  final ModerationStatus moderationStatus;
  final int reportedCount;
  final int viewCount; // NUEVO: contador de vistas para ratio de reportes

  const Gossip({
    // ... campos existentes ...
    required this.status,
    required this.moderationStatus,
    this.reportedCount = 0,
    this.viewCount = 0, // NUEVO
    // ... campos existentes ...
  });

  @override
  List<Object?> get props => [
    // ... props existentes ...
    status,
    moderationStatus,
    reportedCount,
    viewCount, // NUEVO
    // ... props existentes ...
  ];
}
```

### GossipModel (Agregar campos)

```dart
class GossipModel {
  // ... campos existentes ...
  final String status;
  final String moderationStatus;
  final int reportedCount;
  final int viewCount; // NUEVO

  const GossipModel({
    // ... campos existentes ...
    required this.status,
    required this.moderationStatus,
    this.reportedCount = 0,
    this.viewCount = 0, // NUEVO
    // ... campos existentes ...
  });

  factory GossipModel.fromJson(Map<String, dynamic> json) {
    // ... validación existente ...
    return GossipModel(
      // ... campos existentes ...
      status: status,
      moderationStatus: moderationStatus,
      reportedCount: reportedCount as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0, // NUEVO
      // ... campos existentes ...
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ... campos existentes ...
      'status': status,
      'moderationStatus': moderationStatus,
      'reportedCount': reportedCount,
      'viewCount': viewCount, // NUEVO
      // ... campos existentes ...
    };
  }

  Gossip toEntity() {
    return Gossip(
      // ... mapeo existente ...
      status: GossipStatus.values.firstWhere(/* ... */),
      moderationStatus: ModerationStatus.values.firstWhere(/* ... */),
      reportedCount: reportedCount,
      viewCount: viewCount, // NUEVO
      // ... mapeo existente ...
    );
  }
}
```

## Backend Implementation (Supabase)


### Estado Actual del Proyecto

El proyecto usa **Supabase** como backend:

- **RLS Policies:** Controlan acceso y permisos a nivel de base de datos
- **Database Triggers:** Manejan timestamps automáticos (created_at, modified_at)
- **Moderación:** Implementada con OpenAI Moderation API
- **Edge Functions:** Futuras para lógica de negocio compleja

Ver `CLAUDE.md` y `/supabase/migrations/` para detalles de implementación.

## Resumen

- **Combinaciones válidas**: Solo 6 combinaciones específicas son válidas (deleted es flexible)
- **Transiciones**: Controladas exclusivamente por backend (RLS + triggers)
- **Validación**: Implementar en RLS Policies y Database Triggers
- **Cliente**: Solo puede crear (inicia en `draft` + `pending`)
- **Backend**: Controla todas las transiciones de estado
- **Reportes**: Estrategia combinada (3+ denuncias OR ratio > 5% OR categoría severa)
- **Tracking usuario**: MVP usa contador simple en documento de usuario
- **Vistas**: MVP usa contador simple en Gossip
- **Soft delete**: Los chismes nunca se borran físicamente
- **Feedback**: Motor automático NO da detalles específicos

**IMPORTANTE**: No dejar que dos enums independientes permitan cientos de combinaciones ambiguas. Definir y validar explícitamente las combinaciones válidas.
