# Migraciones de Base de Datos

**Última consolidación:** 2026-10-25  
**Total de migraciones:** 10

---

## 📋 Migraciones actuales

### 001_gossips.sql
**Contenido consolidado:**
- ✅ Tabla `gossips` (principal)
- ✅ Idempotencia atómica (fix race condition)
- ✅ Tabla `gossip_reports` (reportes de contenido)
- ✅ RLS policies completas
- ✅ Rate limiting integrado
- ✅ Triggers y funciones

**Fusionó:**
- `001_create_gossips_table.sql`
- `007_atomic_idempotency.sql`
- `010_create_gossip_reports.sql`

---

### 002_location.sql
**Contenido consolidado:**
- ✅ Tablas de ubicación (countries, regions, cities)
- ✅ Datos semilla de GeoNames
- ✅ RLS policies
- ✅ Permisos GRANT para authenticated
- ✅ Índices de búsqueda

**Fusionó:**
- `002_create_location_tables.sql`
- `011_fix_location_permissions.sql`

---

### 003_error_logs.sql
**Contenido consolidado:**
- ✅ Tabla `error_logs`
- ✅ Función `log_error()`
- ✅ Función `clean_old_error_logs()`
- ✅ Scheduler pg_cron (limpieza semanal automática)
- ✅ RLS policies

**Fusionó:**
- `003_create_error_logs.sql`
- `009_schedule_error_logs_cleanup.sql`

---

### 004_rate_limits.sql
**Contenido:**
- ✅ Tabla `rate_limits`
- ✅ Funciones atómicas de rate limiting
- ✅ Cooldown de 30s
- ✅ Límites: 10/hora, 100/día
- ✅ RLS policies

**Sin fusiones** (migración única)

---

### 005_profiles.sql
**Contenido consolidado:**
- ✅ Tabla `profiles`
- ✅ Relación 1:1 con `auth.users`
- ✅ Trigger automático al crear usuario
- ✅ RLS policies (incluye fix de INSERT)
- ✅ Funciones helper (username availability, completion)

**Fusionó:**
- `005_create_profiles_table.sql`
- `012_fix_profiles_insert_policy.sql`

---

### 006_media_security.sql
**Contenido consolidado:**
- ✅ Buckets de cuarentena (images + audio)
- ✅ Políticas de storage seguras
- ✅ Funciones de validación
- ✅ Proceso de 2 pasos: quarantine → production
- ✅ Límites de tamaño y formato

**Fusionó:**
- `006_secure_media_quarantine.sql` (images)
- `008_secure_audio.sql` (audio)

---

### 007–009
- `007_check_email_exists.sql`: RPC `check_email_exists_and_confirmed`
- `008_home_feed_functions.sql`: funciones del feed de Home
- `009_search_gossips_function.sql`: RPC `search_gossips`

---

### 010_idempotency_cleanup_cron.sql
- ✅ Quita el trigger `gossips_cleanup_old_idempotency_keys` (UPDATE dentro de los inserts)
- ✅ Job pg_cron `idempotency-keys-cleanup` (diario 3:30 UTC) → `SELECT cleanup_old_idempotency_keys()`

### 011_media_cleanup_storage_api.sql
- ✅ Borra las 4 funciones `cleanup_*` de 006 (hacían `DELETE FROM storage.objects`: quitaban la metadata pero dejaban el archivo)
- ✅ RPC `get_media_cleanup_candidates()` (solo `service_role`): cuarentena >24 h y públicos huérfanos >7 días
- ✅ Job pg_cron `media-cleanup` (diario 4:00 UTC) → Edge Function `cleanup-media` vía `net.http_post`
- ⚠️ Requiere secrets en Vault y en la función: ver `supabase/functions/README.md` → "Limpieza de media"

### 012_revoke_client_execute_server_functions.sql
- 🔴 Fix de seguridad: quita EXECUTE a `anon`/`authenticated` en 9 funciones SECURITY DEFINER solo de servidor (`upsert_gossip_idempotent`, `create_gossip_draft`, rate limit, limpiezas, `check_error_log_rate`, `calculate_profile_completion`)
- Antes, sin login se podía publicar un chisme aprobado a nombre de otro usuario vía `/rest/v1/rpc/upsert_gossip_idempotent`
- Regresión: `supabase/tests/001_gossip_creation_security_test.sql`

---

## 🔄 Cómo usar

### Reset completo (desarrollo)

```bash
cd supabase
./reset-database.sh
```

### Aplicar solo nuevas migraciones

```bash
supabase db push --linked
```

### Ver diferencias

```bash
supabase db diff --linked
```

---

## 📝 Crear nueva migración

```bash
supabase migration new descriptive_name
```

Luego edita el archivo SQL generado en `migrations/`.

---

## ⚠️ Reglas de migraciones

### ✅ DO

- **Nombres descriptivos:** `003_feature_name.sql`
- **Idempotentes:** Usar `CREATE ... IF NOT EXISTS`
- **Documentadas:** Comentarios claros al inicio
- **Testeadas:** Probar localmente antes de aplicar
- **Consolidar en desarrollo:** Fusionar migraciones relacionadas

### ❌ DON'T

- **No editar migraciones aplicadas** en producción
- **No aplicar manualmente** en producción (usar `supabase db push`)
- **No saltarse números** en secuencia
- **No tener migraciones vacías**

---

## 🗂️ Backup de migraciones originales

Las migraciones originales (pre-consolidación) están en:
```
supabase/migrations_backup/
```

Contiene las 12 migraciones originales por si necesitas referencia histórica.

### Nombres anteriores → archivo actual

Los docs de `docs/` (reportes históricos) citan nombres previos a la
consolidación. Equivalencia:

| Nombre citado en docs | Hoy está en |
|---|---|
| `001_create_gossips_table`, `001_gossips_merged`, `002_add_idempotency`, `007_atomic_idempotency`, `008_atomic_idempotency`, `010_create_gossip_reports`, `011_add_audio_storage_path_to_upsert` | `001_gossips.sql` |
| `002_create_location_tables`, `003_create_location_tables`, `002_location_search_functions`, `011_fix_location_permissions` | `002_location.sql` |
| `003_create_error_logs`, `004_create_error_logs`, `019_create_error_logs`, `009_schedule_error_logs_cleanup`, `012_schedule_error_logs_cleanup` | `003_error_logs.sql` |
| `004_create_rate_limits_table`, `005_create_rate_limits_table`, `006_atomic_rate_limiting` | `004_rate_limits.sql` |
| `005_create_profiles_table`, `006_create_profiles_table`, `006_add_user_avatar_column`, `012_fix_profiles_insert_policy` | `005_profiles.sql` |
| `006_secure_media_quarantine`, `007_secure_media_quarantine`, `007_secure_media_storage`, `008_secure_audio`, `010_secure_audio_quarantine` | `006_media_security.sql` |
| `009_remove_idempotency_cleanup_trigger` (nunca existió con ese nombre) | `010_idempotency_cleanup_cron.sql` |
| `002_insert_sample_data` | Eliminado (P0-03), sin equivalente |

Los números de línea citados en esos docs (`archivo.sql:11`) ya no aplican.

---

## 📊 Estado del esquema

### Tablas principales
- `gossips` - Publicaciones de usuarios
- `gossip_reports` - Reportes de contenido
- `profiles` - Perfiles de usuarios
- `location_countries` - Países
- `location_regions` - Regiones/estados
- `location_cities` - Ciudades
- `error_logs` - Logs de errores
- `rate_limits` - Control de límites

### Storage buckets
- `images-quarantine` - Imágenes pre-validación (privado)
- `images` - Imágenes validadas (público)
- `audio-quarantine` - Audio pre-validación (privado)
- `audio` - Audio validado (público)

### Funciones principales
- `check_cooldown()` - Rate limiting de cooldown
- `check_hourly_limit()` - Rate limiting por hora
- `check_daily_limit()` - Rate limiting por día
- `log_error()` - Registrar errores
- `clean_old_error_logs()` - Limpiar logs antiguos
- `is_username_available()` - Verificar username
- `calculate_profile_completion()` - % completitud perfil

### Triggers activos
- `on_auth_user_created` - Crear profile al registrar usuario
- `on_profile_updated` - Actualizar updated_at
- `on_profile_completion_check` - Calcular profile_completed

### Schedulers (pg_cron)
- `error-logs-cleanup`: limpieza de error_logs (domingos 3:00 UTC)
- `idempotency-keys-cleanup`: idempotency keys >24 h (diario 3:30 UTC)
- `media-cleanup`: media huérfana y cuarentena vía Edge Function `cleanup-media` (diario 4:00 UTC)

---

## 🔗 Referencias

- [Supabase Migrations](https://supabase.com/docs/guides/cli/managing-environments)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don%27t_Do_This)
- [RLS Security](https://supabase.com/docs/guides/auth/row-level-security)

---

**FIN DEL DOCUMENTO**
