# Fix P0-02: Bypass de moderación por REST directo

## 🚨 Problema Original

**Vulnerabilidad:** Cliente podía bypasear la moderación haciendo INSERT directo a la tabla `gossips` usando REST API + anon key.

```bash
# ❌ ANTES: Ataque posible
curl https://xxx.supabase.co/rest/v1/gossips \
  -H "Authorization: Bearer anon_key" \
  -d '{
    "subject": "Spam",
    "content": "Contenido malicioso",
    "status": "published",           # Bypass moderación
    "moderation_status": "approved", # Bypass moderación
    "visibility": "public"           # Visible inmediatamente
  }'
```

**Evidencia:**
- `001_create_gossips_table.sql:135-142` tenía política `WITH CHECK (true)` - permitía cualquier INSERT
- Trigger solo forzaba contadores a 0, NO validaba estados
- Cliente conoce URL + anon key por diseño

---

## ✅ Solución Implementada

### **Opción 2: RPC Obligatorio (la más segura)**

**Cambios realizados:**

1. **Eliminada política INSERT permisiva**
   - Ahora NO hay política de INSERT para usuarios
   - Solo `service_role` puede insertar directamente

2. **Creada función RPC `create_gossip_draft()`**
   - Único punto de entrada para creación
   - Valida autenticación (`auth.uid()`)
   - Previene duplicados (idempotency_key)
   - Fuerza estados seguros (draft, pending, private)
   - Fuerza `created_by` desde auth (no falsificable)

3. **Actualizado cliente Flutter**
   - Cambió de Edge Function a RPC
   - Mismo flujo para el usuario
   - Más seguro server-side

---

## 📋 Archivos Modificados

### 1. `supabase/migrations/001_create_gossips_table.sql`

**Antes:**
```sql
CREATE POLICY "Usuarios autenticados pueden crear gossips"
ON gossips
FOR INSERT
WITH CHECK (true); -- ❌ Permisivo
```

**Después:**
```sql
-- ⛔ NO HAY POLÍTICA DE INSERT
-- Creación SOLO vía RPC create_gossip_draft()
```

**Agregado:**
- Función `create_gossip_draft()` (líneas ~320-450)
- Validaciones de auth, idempotencia, campos obligatorios
- Grant para `authenticated` role

### 2. `lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart`

**Antes:**
```dart
final response = await _supabase.functions.invoke('moderate-gossip', ...);
```

**Después:**
```dart
final response = await _supabase.rpc('create_gossip_draft',
  params: {
    'p_subject': input.subject,
    'p_content': input.content,
    // ... otros params
  },
);
```

### 3. `supabase/tests/001_gossip_creation_security_test.sql` (NUEVO)

Tests de seguridad que verifican:
- ✅ INSERT directo → FALLA (403)
- ✅ RPC create_gossip_draft() → FUNCIONA
- ✅ Estados controlados por servidor
- ✅ Auth requerida
- ✅ Idempotencia previene duplicados

---

## 🧪 Cómo Probar

### **Paso 1: Resetear database**

```bash
cd supabase
supabase db reset --linked
```

Esto aplica la migración actualizada.

### **Paso 2: Ejecutar tests de seguridad**

```bash
psql <connection_string> -f tests/001_gossip_creation_security_test.sql
```

**Output esperado:**
```
NOTICE:  TEST 1 PASSED: INSERT directo fue bloqueado correctamente
NOTICE:  TEST 2 PASSED: RPC funcionó correctamente y estados son controlados por servidor
NOTICE:  TEST 3 PASSED: RPC rechazó correctamente usuario sin auth
NOTICE:  TEST 4 PASSED: Idempotencia previene duplicados correctamente
NOTICE:  ========================================
NOTICE:  TODOS LOS TESTS DE SEGURIDAD PASARON ✅
NOTICE:  ========================================
```

### **Paso 3: Probar desde Flutter**

```bash
flutter test
flutter run
```

1. Crear un gossip desde la app
2. Verificar que se crea correctamente
3. Verificar en Supabase Dashboard que:
   - `status = 'draft'`
   - `moderation_status = 'pending'`
   - `visibility = 'private'`
   - `created_by = <tu_user_id>`

### **Paso 4: Intentar bypass (debe fallar)**

```bash
# Intentar INSERT directo con anon key
curl https://njqamqcsldpmtbiqwbwo.supabase.co/rest/v1/gossips \
  -H "Authorization: Bearer <anon_key>" \
  -H "apikey: <anon_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Test bypass",
    "content": "Intento de bypass",
    "status": "published",
    "moderation_status": "approved",
    "visibility": "public"
  }'
```

**Respuesta esperada:**
```json
{
  "code": "42501",
  "message": "new row violates row-level security policy for table \"gossips\""
}
```

✅ **Bypass BLOQUEADO correctamente**

---

## 🔐 Beneficios de Seguridad

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Punto de entrada** | REST directo | Solo RPC |
| **Control de estados** | Cliente decide | Servidor fuerza |
| **Validación auth** | Opcional | Obligatoria |
| **Idempotencia** | Solo en Edge Function | En RPC server-side |
| **Falsificación de `created_by`** | Posible | Imposible |
| **Bypass de moderación** | Posible | Imposible |

---

## 📝 Notas de Implementación

### **Moderación (Pendiente)**

La moderación ahora debe ejecutarse **después** de la creación:

**Opciones:**
1. **Trigger asíncrono** en PostgreSQL (después de INSERT)
2. **Edge Function scheduled** (ejecuta cada X minutos)
3. **Background job** (Supabase Realtime + worker)

**Flujo propuesto:**
```
1. Cliente → RPC create_gossip_draft()
2. RPC → Inserta gossip (draft, pending, private)
3. Trigger/Job → Ejecuta moderación (reglas + OpenAI)
4. Si aprobado → UPDATE (published, approved, public)
5. Si rechazado → UPDATE (draft, rejected, private)
```

### **Edge Function moderate-gossip**

La Edge Function existente (`moderate-gossip`) **ya NO se usa** para creación.

**Opciones:**
- Convertirla en una función de moderación que se ejecute después
- Eliminarla si no es necesaria
- Mantenerla como backup/alternativa

---

## ✅ Checklist de Deployment

- [ ] Aplicar migración: `supabase db reset --linked`
- [ ] Ejecutar tests de seguridad: `psql -f tests/001_gossip_creation_security_test.sql`
- [ ] Verificar que tests Flutter pasan: `flutter test`
- [ ] Probar creación desde app: `flutter run`
- [ ] Intentar bypass con curl → debe fallar
- [ ] Documentar en SECURITY.md
- [ ] Actualizar ADR si existe
- [ ] (Futuro) Implementar moderación asíncrona

---

## 🔗 Referencias

- **ADR:** (Agregar link a ADR cuando se documente)
- **Issue:** P0-02 - Se puede bypasear la moderación por REST directo
- **Fecha:** 2026-10-20
- **Autor:** Claude Code (via Alejo)
