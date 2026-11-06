# 🔄 Reset Database - Recrear Tablas con RLS

## ⚠️ ADVERTENCIA
Este proceso **ELIMINA TODOS LOS DATOS** de la base de datos.  
Solo ejecutar en entorno de desarrollo/testing.

---

## 📋 Qué se agregó

Las migraciones ahora incluyen:

### 1️⃣ Row Level Security (RLS)
- ✅ Usuarios pueden leer gossips públicos y aprobados
- ✅ Usuarios pueden ver sus propios gossips (incluso drafts)
- ✅ Usuarios autenticados pueden crear gossips
- ✅ Solo se pueden editar gossips propios en estado draft

### 2️⃣ Triggers de Protección
- ✅ `set_created_by()` - Auto-asigna created_by y created_at
- ✅ `set_modified_at()` - Auto-actualiza modified_at y modified_by
- ✅ `protect_counters()` - **BLOQUEA modificación de contadores desde cliente**

### 3️⃣ Campos Protegidos
Los siguientes campos **NO SE PUEDEN MODIFICAR** desde Flutter:
- `report_count`, `view_count`, `like_count`, `comment_count`
- `status`, `moderation_status`
- `created_at`, `created_by`
- `deleted_at`, `deleted_by`

Solo **Edge Functions con service_role** pueden modificar estos campos.

---

## 🚀 Cómo Recrear las Tablas

### Opción A: Supabase Dashboard (Recomendado)

1. **Ve a SQL Editor:**
   - https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/sql/new

2. **Eliminar tabla existente:**
   ```sql
   DROP TABLE IF EXISTS gossips CASCADE;
   ```
   Click **Run**

3. **Copiar migración unificada:**
   - Abre: `supabase/migrations/001_create_gossips_table.sql`
   - Copia TODO el contenido (incluye tabla + RLS + triggers + thumbnail_url)

4. **Ejecutar migración:**
   - Pega en SQL Editor
   - Click **Run**

5. **(Opcional) Datos de prueba:**
   - Abre: `supabase/migrations/002_insert_sample_data.sql`
   - Copia y ejecuta en SQL Editor

6. **Verificar:**
   ```sql
   -- Ver políticas RLS
   SELECT * FROM pg_policies WHERE tablename = 'gossips';
   
   -- Ver triggers
   SELECT tgname FROM pg_trigger WHERE tgrelid = 'gossips'::regclass;
   
   -- Ver campos
   SELECT column_name, data_type FROM information_schema.columns 
   WHERE table_name = 'gossips' ORDER BY ordinal_position;
   ```

---

### Opción B: Supabase CLI

```bash
# 1. Conectar a proyecto
supabase link --project-ref njqamqcsldpmtbiqwbwo

# 2. Reiniciar base de datos (ELIMINA TODO)
supabase db reset

# 3. Las migraciones se ejecutan automáticamente
```

---

## ✅ Verificar Protección de Contadores

### Test 1: Intentar modificar contador desde cliente

**En Flutter (debe fallar):**
```dart
// Esto NO debe funcionar - el trigger revierte el cambio
await supabase
  .from('gossips')
  .update({'report_count': 999})
  .eq('id', 'algun-id');
```

**Resultado esperado:** El `report_count` NO cambia (trigger lo protege)

---

### Test 2: Incrementar desde Edge Function

**Crear Edge Function: `increment-report`**

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const { gossipId } = await req.json()

  // Usar service_role (bypass RLS)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // ← service_role
  )

  // Incrementar contador (SOLO funciona con service_role)
  const { data, error } = await supabase
    .from('gossips')
    .update({ report_count: supabase.rpc('gossips.report_count + 1') })
    .eq('id', gossipId)
    .select()
    .single()

  return new Response(JSON.stringify({ data, error }))
})
```

---

## 📊 Verificar Políticas RLS

```sql
-- Ver todas las políticas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'gossips';
```

**Deberías ver:**
- `Gossips públicos son visibles para todos` (SELECT)
- `Usuarios pueden ver sus propios gossips` (SELECT)
- `Usuarios autenticados pueden crear gossips` (INSERT)
- `Usuarios pueden editar sus propios drafts` (UPDATE)

---

## 🔍 Verificar Triggers

```sql
-- Ver triggers activos
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'gossips';
```

**Deberías ver:**
- `gossips_set_created_by` (BEFORE INSERT)
- `gossips_set_modified_at` (BEFORE UPDATE)
- `gossips_protect_counters` (BEFORE INSERT OR UPDATE)

---

## 🧪 Test Completo

Después de recrear las tablas:

```bash
# 1. Correr app Flutter
flutter run

# 2. Crear un gossip normal
# ✅ Debe funcionar - se crea con report_count=0

# 3. En Supabase Dashboard, intentar modificar manualmente:
UPDATE gossips SET report_count = 999 WHERE id = 'tu-gossip-id';

# 4. Verificar que NO se modificó (trigger lo protegió)
SELECT report_count FROM gossips WHERE id = 'tu-gossip-id';
-- Debe seguir en 0 (o valor original)
```

---

## 🚨 Troubleshooting

### Error: "new row violates row-level security policy"

**Causa:** Las políticas RLS están bloqueando la operación

**Solución:** 
- Verificar que el usuario esté autenticado
- En modo spike, verificar que `created_by = 'spike-user'`

### Error: "permission denied for table gossips"

**Causa:** RLS está habilitado pero no hay políticas que permitan la operación

**Solución:**
```sql
-- Ver si RLS está habilitado
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'gossips';

-- Si está habilitado (t), verificar políticas
SELECT * FROM pg_policies WHERE tablename = 'gossips';
```

### Los contadores SÍ se modifican desde cliente

**Causa:** El trigger no está funcionando

**Solución:**
```sql
-- Verificar que el trigger existe
SELECT * FROM pg_trigger WHERE tgname = 'gossips_protect_counters';

-- Verificar la función
\df protect_counters
```

---

## 📚 Referencias

- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/trigger-definition.html)
- [PostgreSQL Policies](https://www.postgresql.org/docs/current/sql-createpolicy.html)

---

## ✅ Checklist Post-Reset

- [ ] Tabla `gossips` recreada
- [ ] 4 políticas RLS activas
- [ ] 3 triggers activos
- [ ] Extensión `uuid-ossp` habilitada
- [ ] Test: Crear gossip desde Flutter (debe funcionar)
- [ ] Test: Intentar modificar contador (debe fallar/revertirse)
- [ ] Datos de prueba insertados (migración 002)
