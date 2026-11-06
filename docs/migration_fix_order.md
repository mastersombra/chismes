# Fix: Orden de dependencias en migraciones

**Fecha:** 2026-10-25  
**Problema:** Error al aplicar `002_location.sql`  
**Estado:** ✅ Resuelto

---

## 🐛 Problema

Al aplicar las migraciones consolidadas, se obtenía este error:

```
Applying migration 002_location.sql...
ERROR: relation "profiles" does not exist (SQLSTATE 42P01)
At statement: 46
GRANT SELECT ON TABLE profiles TO authenticated
```

---

## 🔍 Causa

Durante la consolidación, la migración `011_fix_location_permissions.sql` contenía permisos tanto para:
- ✅ Tablas de location (countries, regions, cities)
- ❌ Tabla profiles

Al fusionar `011_fix_location_permissions.sql` → `002_location.sql`, los permisos de `profiles` quedaron en el archivo incorrecto.

**Problema de orden:**
```
001_gossips.sql         → OK
002_location.sql        → ❌ Intenta GRANT en profiles (no existe aún)
003_error_logs.sql      → OK
004_rate_limits.sql     → OK
005_profiles.sql        → ✅ Crea tabla profiles (demasiado tarde)
006_media_security.sql  → OK
```

---

## ✅ Solución

### 1. Mover GRANT de profiles

**Antes (incorrecto):**
```sql
-- 002_location.sql
GRANT SELECT ON TABLE countries TO authenticated;
GRANT SELECT ON TABLE profiles TO authenticated;  ← ❌ profiles no existe
```

**Después (correcto):**
```sql
-- 002_location.sql
GRANT SELECT ON TABLE countries TO authenticated;
-- (profiles movido a 005)

-- 005_profiles.sql
CREATE TABLE profiles (...);
-- ... políticas RLS ...
GRANT SELECT ON TABLE profiles TO authenticated;  ← ✅ Aquí corresponde
```

### 2. Archivos modificados

**`002_location.sql`:**
```diff
- GRANT SELECT ON TABLE profiles TO authenticated;
- GRANT SELECT ON TABLE profiles TO anon;
```

**`005_profiles.sql`:**
```diff
+ -- =====================================================
+ -- GRANT PERMISSIONS
+ -- =====================================================
+ GRANT SELECT ON TABLE profiles TO authenticated;
+ GRANT SELECT ON TABLE profiles TO anon;
```

---

## 🧪 Verificación

### Comando aplicado
```bash
supabase db push --linked
```

### Resultado
```
✅ Applying migration 002_location.sql...
✅ Applying migration 003_error_logs.sql...
✅ Applying migration 004_rate_limits.sql...
✅ Applying migration 005_profiles.sql...
✅ Applying migration 006_media_security.sql...
✅ Finished supabase db push.
```

---

## 📝 Lección aprendida

### Regla: Orden de dependencias

Cuando fusiones migraciones que incluyen permisos GRANT:

1. **Verificar dependencias:**
   - ¿La tabla ya existe en ese punto?
   - ¿Está en una migración anterior?

2. **Agrupar correctamente:**
   - Permisos de location → `002_location.sql`
   - Permisos de profiles → `005_profiles.sql`
   - Permisos de gossips → `001_gossips.sql`

3. **No mezclar temas:**
   - Cada migración debe ser autocontenida
   - No incluir permisos de tablas de otras migraciones

### Checklist al fusionar

- [ ] ¿Todas las tablas referenciadas existen en migraciones anteriores?
- [ ] ¿Los permisos GRANT están en la misma migración que CREATE TABLE?
- [ ] ¿Las funciones existen antes de GRANT EXECUTE?
- [ ] ¿El orden numérico respeta las dependencias?

---

## 🔄 Estado final

### Migraciones consolidadas (correcto)

```
001_gossips.sql          → Gossips + reports + idempotency
002_location.sql         → Location tables + permisos
003_error_logs.sql       → Error logs + cleanup
004_rate_limits.sql      → Rate limiting
005_profiles.sql         → Profiles + permisos ✅
006_media_security.sql   → Images + audio storage
```

### Dependencias respetadas

```
001 → (ninguna)
002 → (ninguna)
003 → (ninguna)
004 → (ninguna)
005 → auth.users (Supabase nativo)
006 → (ninguna)
```

---

## 🚀 Siguiente paso

Si necesitas hacer reset completo desde el raíz del proyecto:

```bash
cd /Users/alejo/Documents/Piloto/chismes
supabase db reset --linked
```

O usa el script (desde dentro de `supabase/`):

```bash
cd supabase
./reset-database.sh
```

---

**FIN DEL DOCUMENTO**
