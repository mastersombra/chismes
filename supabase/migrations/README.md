# Migraciones de Base de Datos

**Última consolidación:** 2026-10-25  
**Total de migraciones:** 10

---

## 📋 Migraciones actuales

### 001_gossips.sql
**Contenido consolidado:**
- ✅ Tabla `gossips` (principal; **no legible por clientes**)
- ✅ Vista `public_gossips`: única lectura de chismes para la app (oculta el autor de los anónimos)
- ✅ Idempotencia atómica (fix race condition)
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
- ✅ Políticas de storage: solo `service_role` escribe; los buckets públicos sirven por URL pública pero no se pueden listar (sin política SELECT para clientes). Regresión: `supabase/tests/e2e/storage_rls_e2e.test.ts`
- ✅ Funciones de validación
- ✅ Proceso de 2 pasos: quarantine → production
- ✅ Límites de tamaño y formato

**Fusionó:**
- `006_secure_media_quarantine.sql` (images)
- `008_secure_audio.sql` (audio)

---

### 007–009
- `007_check_email_exists.sql`: RPC `check_email_exists_and_confirmed`
- `008_home_feed_functions.sql`: feed de Home. `get_popular_feed` por anillos de cercanía (ciudad 100 / región 60 / país 25 / otro país 0) + popularidad + frescura, tendencia relativa (percentil 95 de interacciones/hora en 48 h) y relleno cuando hay pocos chismes cercanos. Pesos y umbrales en la tabla `feed_settings` (editable sin deploy). También `get_following_feed` y `check_new_gossips`. Los feeds leen la vista `public_gossips` (definida en 001), que oculta `created_by` en chismes anónimos. Test: `supabase/tests/002_popular_feed_test.sql`
- `009_search_gossips_function.sql`: RPC `search_gossips` (SECURITY INVOKER sobre `public_gossips`, solo `authenticated`). Test de privacidad: `supabase/tests/004_anonymous_author_privacy_test.sql`

---

### 010_idempotency_cleanup_cron.sql
- ✅ Quita el trigger `gossips_cleanup_old_idempotency_keys` (UPDATE dentro de los inserts)
- ✅ Job pg_cron `idempotency-keys-cleanup` (diario 3:30 UTC) → `SELECT cleanup_old_idempotency_keys()`

### 011_media_cleanup_storage_api.sql
- ✅ Borra las 4 funciones `cleanup_*` de 006 (hacían `DELETE FROM storage.objects`: quitaban la metadata pero dejaban el archivo)
- ✅ `get_media_cleanup_candidates()` vive en 013 (excluye la media pendiente de revisión)
- ✅ Job pg_cron `media-cleanup` (diario 4:00 UTC) → Edge Function `cleanup-media` vía `net.http_post`
- ⚠️ Requiere secrets en Vault y en la función: ver `supabase/functions/README.md` → "Limpieza de media"

### 012_revoke_client_execute_server_functions.sql
- 🔴 Fix de seguridad: quita EXECUTE a `anon`/`authenticated` en 9 funciones SECURITY DEFINER solo de servidor (`upsert_gossip_idempotent`, `create_gossip_draft`, rate limit, limpiezas, `check_error_log_rate`, `calculate_profile_completion`)
- Antes, sin login se podía publicar un chisme aprobado a nombre de otro usuario vía `/rest/v1/rpc/upsert_gossip_idempotent`
- Regresión: `supabase/tests/001_gossip_creation_security_test.sql`

### 013_moderation.sql
- ✅ `moderation_settings`: umbrales de reportes editables desde el dashboard (sin desplegar)
- ✅ `moderation_rules`: reglas de contenido de `moderate-gossip` (términos, umbrales por categoría de la IA, reglas fijas on/off), editables sin desplegar; CHECK contra typos; sin acceso de clientes
- ✅ `content_reports`: reportes genéricos (hoy `gossip_id`; a futuro `comment_id`) con la regla "exactamente una referencia"; reemplaza a `gossip_reports`
- ✅ `moderation_queue`: cola de revisión humana + historial (autor, gravedad, motivo: base de sanciones futuras); media pendiente protegida de la limpieza
- ✅ Trigger de reportes: mínimo de reportes, cuentas nuevas no cuentan, umbral relativo a las interacciones, lo popular no se oculta solo
- ✅ RPCs solo `service_role`: `enqueue_moderation()` (moderate-gossip), `apply_moderation_decision()` (moderation-review; al rechazar desvincula la media pública y devuelve sus rutas en `removed_media` para borrarla); vista `moderation_queue_items`
- ✅ En 001: `protect_critical_fields` es `SECURITY INVOKER` y protege solo ante clientes directos (antes revertía en silencio el UPDATE del trigger de reportes)
- Tests: `supabase/tests/005_moderation_test.sql`

### 014_account_deletion.sql
- ✅ `account_deletion_records`: registro anónimo de faltas de cuentas eliminadas (huella HMAC del email + rechazos por gravedad; sin user_id ni contenido). Solo si tuvo faltas; si vuelve a pasar con el mismo email, acumula
- ✅ `get_account_deletion_media()`: rutas de la media del usuario (buckets públicos + cuarentena) para borrarla con la Storage API
- ✅ `delete_user_account()`: en una transacción guarda el registro y borra `auth.users` (cascada: chismes, perfil, reportes, cola) y `rate_limits` (sin FK)
- ✅ Solo `service_role` (Edge Function `delete-account`); requiere el secret `ACCOUNT_HASH_SECRET`
- Tests: `supabase/tests/006_account_deletion_test.sql`, E2E `supabase/tests/e2e/delete_account_e2e.test.ts`

### 015_sanctions.sql
- ✅ Sanciones por puntos: falta = rechazo humano no anulado (los automáticos de la IA no cuentan). Leve 1 · media 2 · alta 4 · crítica suspende directo; vencen a los 90 días. 3 pts → 24 h sin publicar/reportar, 6 → 7 días, 10 → suspensión indefinida (solo la levanta una apelación). Todo en `moderation_settings`
- ✅ No se guardan: `get_user_strikes()` / `get_user_sanction_status()` las calculan del historial (anular una falta o cambiar un umbral recalcula solo)
- ✅ `moderation_appeals`: una apelación por rechazo, dentro de 14 días. `submit_appeal()` / `decide_appeal()` (aceptar anula la falta con `moderation_queue.overturned_at` y republica el texto); `appeal_different_moderator` (0 por defecto) exige otro moderador. Vista `moderation_appeal_items`
- ✅ Reincidentes: `inherited_strikes` + `claim_inherited_strikes()` (la huella la calcula el servidor con `ACCOUNT_HASH_SECRET`); `get_account_status()` para la app
- ✅ `delete_user_account()` redefinida: no cuenta faltas anuladas
- ✅ Solo `service_role` (moderate-gossip, report-gossip, account-status, moderation-review)
- Tests: `supabase/tests/007_sanctions_test.sql`, E2E `supabase/tests/e2e/sanctions_e2e.test.ts`

### 016_policy_acceptances.sql
- ✅ `legal_documents`: versión vigente de la Política de privacidad y los Términos de uso (debe coincidir con el encabezado de `assets/legal/*.md`; un test de Flutter lo verifica). Lectura pública
- ✅ `policy_acceptances`: qué versión aceptó cada usuario y cuándo (prueba para GDPR). La escribe un trigger en `auth.users` al crear la cuenta (email, Google o Apple), nunca el cliente; el usuario lee solo las suyas; se borra en cascada al eliminar la cuenta
- Al cambiar una política: subir la versión en los `.md` (es y en) y `UPDATE legal_documents` en una migración nueva
- Tests: `supabase/tests/008_policy_acceptances_test.sql`

### 017_profile_editing.sql
- ✅ Los clientes ya no escriben en `profiles` (antes: bio/nombre sin moderar y cualquier `avatar_url`). Toda edición pasa por la Edge Function `update-profile`
- ✅ `username_changed_at` + trigger `enforce_username_change_cooldown`: el @usuario se cambia una vez cada `username_change_cooldown_days` (30, en `moderation_settings`); la primera elección no cuenta; aplica también a `service_role` (SQLSTATE `P0010`)
- ✅ `user_settings`: notificaciones, nivel de privacidad, mostrar email/actividad. Fila creada al registrarse (y para los usuarios existentes); el dueño la lee y cambia solo las preferencias (GRANT por columna); se borra con la cuenta
- ✅ Bucket público `avatars` (2 MB, JPEG/PNG/WebP), solo escribe `service_role`; `delete-account` vacía `avatars/{user_id}/`
- Tests: `supabase/tests/009_profile_editing_test.sql`, E2E `supabase/tests/e2e/update_profile_e2e.test.ts` y `storage_rls_e2e.test.ts`

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
- `content_reports` - Reportes de contenido (genéricos)
- `moderation_queue` - Cola de revisión humana e historial de decisiones
- `moderation_settings` - Umbrales de moderación (editables)
- `moderation_rules` - Reglas de contenido de `moderate-gossip` (editables)
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
