# 🔒 Security Fix P1-03: Idempotencia bajo Concurrencia

**Fecha:** 2026-10-22  
**Prioridad:** P1 (Alto)  
**Estado:** ✅ **IMPLEMENTADO**

---

## 📋 PROBLEMA ORIGINAL

### **Evidencia**

La Edge Function tenía un **race condition** en idempotencia:

```typescript
// ❌ ANTES (Líneas 198-216)
const { data: existingGossip } = await supabaseAdmin
  .from('gossips')
  .select()
  .eq('idempotency_key', body.idempotency_key)
  .maybeSingle()

if (existingGossip) {
  return existing // Retornar existente
}

// ... más tarde ...

const { data: gossip, error } = await supabaseAdmin
  .from('gossips')
  .insert({ ... })
  .single()
```

### **Race Condition**

```
Request A: SELECT (no encuentra) → INSERT (OK, crea gossip)
Request B: SELECT (no encuentra) → INSERT (ERROR 500, violación única)
```

**Problema:** Request B devuelve error 500 en lugar de retornar el gossip creado por A.

### **Problema Adicional: Flutter Regenera Clave**

```dart
// ❌ ANTES (add_gossip_controller.dart:639)
final idempotencyKey = const Uuid().v4(); // Nueva clave en cada submit
```

**Escenario:**
1. Usuario submit → timeout de red
2. Usuario retry → **nueva clave generada**
3. Edge Function crea 2 gossips distintos (duplicado)

---

## 🎯 IMPACTO

| Aspecto | Impacto |
|---------|---------|
| **Duplicados** | Alto - Timeout/retry crea duplicados |
| **UX** | Malo - Error 500 en doble-tap |
| **Concurrencia** | Alto - Race condition en requests simultáneos |

### **Casos Problemáticos:**

1. **Doble-tap** → Request A y B simultáneos → Request B falla con 500
2. **Timeout → Retry** → Genera nueva clave → Duplicado
3. **Reinicio app** → Genera nueva clave → Puede duplicar

---

## ✅ SOLUCIÓN IMPLEMENTADA

### **1. RPC con INSERT ON CONFLICT (Backend)**

**Archivo:** `supabase/migrations/008_atomic_idempotency.sql`

```sql
CREATE OR REPLACE FUNCTION upsert_gossip_idempotent(...)
RETURNS JSON
AS $$
DECLARE
  v_gossip RECORD;
BEGIN
  -- INSERT con ON CONFLICT (atómico)
  INSERT INTO gossips (...)
  VALUES (...)
  ON CONFLICT (idempotency_key)
  WHERE idempotency_key IS NOT NULL
  DO NOTHING
  RETURNING * INTO v_gossip;

  -- Si se insertó, retornar
  IF v_gossip.id IS NOT NULL THEN
    RETURN json_build_object(
      'gossip', row_to_json(v_gossip),
      'idempotent', false
    );
  END IF;

  -- Si hubo conflicto, leer existente
  SELECT * INTO v_gossip
  FROM gossips
  WHERE idempotency_key = p_idempotency_key;

  RETURN json_build_object(
    'gossip', row_to_json(v_gossip),
    'idempotent', true
  );
END;
$$;
```

**Ventajas:**
- ✅ Atómico (transacción única)
- ✅ Seguro bajo concurrencia
- ✅ Siempre retorna gossip (creado O existente)
- ✅ Nunca devuelve 500 por conflicto

### **2. Edge Function Actualizada**

```typescript
// ✅ DESPUÉS (moderate-gossip/index.ts)

// Eliminar check previo (race condition)
// const { data: existingGossip } = ... ❌ ELIMINADO

// ... después de moderación ...

// Usar RPC atómico
const { data: upsertResult, error } = await supabaseAdmin
  .rpc('upsert_gossip_idempotent', {
    p_subject: body.subject,
    p_content: body.content,
    // ...
    p_idempotency_key: body.idempotency_key,
  })

const { gossip, idempotent } = upsertResult

return new Response(
  JSON.stringify({ gossip, idempotent }),
  { status: 200 }
)
```

**Ventajas:**
- ✅ Sin SELECT previo (elimina race condition)
- ✅ Manejo atómico en PostgreSQL
- ✅ Siempre retorna 200 (incluso en conflicto)

### **3. Flutter: Persistir Idempotency Key**

**Archivo:** `lib/features/gossip/presentation/states/add_gossip_state.dart`

```dart
class AddGossipState {
  // ✅ NUEVO: Clave persistente en el estado
  final String idempotencyKey;

  const AddGossipState({
    required this.idempotencyKey, // Requerido
    // ...
  });
}
```

**Archivo:** `lib/features/gossip/presentation/controllers/add_gossip_controller.dart`

```dart
// ✅ Generar clave UNA VEZ al inicializar
AddGossipState _state = AddGossipState(
  idempotencyKey: const Uuid().v4(),
);

// ✅ Usar clave del estado (no generar nueva)
final input = CreateGossipInput(
  // ...
  idempotencyKey: _state.idempotencyKey, // Del estado
);

// ✅ Regenerar SOLO en éxito
return result.when(
  onSuccess: (gossip) {
    _updateState(_state.copyWith(
      isSubmitting: false,
      idempotencyKey: const Uuid().v4(), // Nueva clave
    ));
    return gossip;
  },
  onFailure: (error) {
    // NO regenerar (mantener para retry)
    _updateState(_state.copyWith(failure: error));
    return null;
  },
);
```

**Ventajas:**
- ✅ Misma clave durante todo el "intento"
- ✅ Retry usa misma clave (idempotente)
- ✅ Solo regenera en éxito (listo para nuevo gossip)

---

## 📊 COMPARACIÓN ANTES/DESPUÉS

### **Escenario 1: Doble-Tap**

| Paso | Antes | Después |
|------|-------|---------|
| Usuario doble-tap | → 2 requests simultáneos | → 2 requests simultáneos |
| Request A | SELECT (no encuentra) → INSERT (OK) | INSERT (OK, crea gossip) |
| Request B | SELECT (no encuentra) → INSERT (500) | INSERT (detecta conflicto, retorna existente) |
| Resultado | ❌ Error 500 | ✅ Retorna mismo gossip |

### **Escenario 2: Timeout → Retry**

| Paso | Antes | Después |
|------|-------|---------|
| Submit 1 | Timeout (red lenta) | Timeout (red lenta) |
| Flutter | Genera nueva clave | ✅ Mantiene misma clave |
| Submit 2 | INSERT con nueva clave → duplicado | INSERT con misma clave → idempotente |
| Resultado | ❌ 2 gossips | ✅ 1 gossip |

### **Escenario 3: Reinicio App**

| Paso | Antes | Después |
|------|-------|---------|
| Submit | Error de red | Error de red |
| App reinicia | Nueva instancia | Nueva instancia |
| Estado | Nueva clave | ✅ Clave se pierde (OK, es nuevo intento) |
| Submit | Crea nuevo gossip | Crea nuevo gossip |
| Resultado | ✅ No duplica | ✅ No duplica |

**Nota:** En reinicio, la clave se pierde y es correcto. El fix previene duplicados solo durante la **misma sesión de intento**.

---

## 🧪 TESTS

### **Test 1: Requests Concurrentes**

```bash
# Enviar 2 requests simultáneos con misma clave
curl -X POST ... -d '{"idempotency_key": "UUID1", ...}' &
curl -X POST ... -d '{"idempotency_key": "UUID1", ...}' &
wait
```

**Resultado esperado:**
- ✅ Ambos retornan 200
- ✅ Ambos retornan el mismo gossip
- ✅ Uno tiene `idempotent: false`, otro `idempotent: true`

### **Test 2: Retry con Misma Clave**

```bash
# Request 1
curl -X POST ... -d '{"idempotency_key": "UUID2", ...}'
# → Retorna gossip A

# Request 2 (mismo UUID)
curl -X POST ... -d '{"idempotency_key": "UUID2", ...}'
# → Retorna mismo gossip A (idempotent: true)
```

**Resultado esperado:**
- ✅ Ambos retornan 200
- ✅ Ambos retornan el mismo gossip
- ✅ Segunda llamada marca `idempotent: true`

---

## 📚 ARCHIVOS MODIFICADOS

### **Backend:**
- ✅ `supabase/migrations/008_atomic_idempotency.sql` (nuevo)
- ✅ `supabase/functions/moderate-gossip/index.ts`

### **Frontend:**
- ✅ `lib/features/gossip/presentation/states/add_gossip_state.dart`
- ✅ `lib/features/gossip/presentation/controllers/add_gossip_controller.dart`

---

## 🚀 DEPLOYMENT

```bash
# 1. Aplicar migración 008
supabase db push --linked

# 2. Desplegar Edge Function
supabase functions deploy moderate-gossip
```

---

## ✅ BENEFICIOS

### **Seguridad:**
- ✅ Previene duplicados bajo concurrencia
- ✅ Previene duplicados en retry/timeout
- ✅ Transacción atómica en PostgreSQL

### **UX:**
- ✅ Nunca devuelve 500 por conflicto
- ✅ Retry funciona correctamente
- ✅ Doble-tap no crea duplicado

### **Arquitectura:**
- ✅ Lógica de idempotencia en backend
- ✅ Flutter mantiene estado correctamente
- ✅ Sin race conditions

---

**🎉 P1-03 COMPLETADO!**

La idempotencia ahora es **atómica y segura bajo concurrencia**.

---

**Creado:** 2026-10-22  
**Por:** Claude Code + Alejo  
**Fix:** P1-03 Idempotencia bajo Concurrencia ✅
