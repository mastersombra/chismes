# Supabase Edge Functions

Funciones Deno que corren en Supabase. Cada carpeta es una función (`index.ts`).

## 📋 Funciones

| Función | Qué hace |
|---|---|
| `moderate-gossip` | Crea chismes: valida input, rate limit, modera texto e imagen (`moderation.ts`) y sube media a cuarentena; el veredicto `review` va a la cola con la ruta de su media. Escribe con el RPC `upsert_gossip_idempotent()` (la app nunca hace INSERT directo, ver `.claude/SECURITY.md`). |
| `report-gossip` | Reporta un chisme visible (no el propio). Guarda en `content_reports`; el umbral (cola + auto-ocultar) lo aplica un trigger con los valores de `moderation_settings`. |
| `moderation-review` | Cola de revisión humana, **solo moderadores** (`app_metadata.role = 'moderator'`). `list` (paginado con `limit`/`offset`; pendientes por prioridad y antigüedad, historial por decisión más reciente; con URL firmada de la media en cuarentena y nombre del autor) y `decide` (aprobar publica la media; rechazar oculta y exige gravedad). La usa el panel de moderación de la app (`lib/features/moderation`). Ver "Moderadores". |
| `delete-account` | Borra la cuenta del usuario y todos sus datos (GDPR). |
| `log-error` | Recibe logs de error de la app (autenticado, sanitiza el contexto). |
| `search-cities` | Autocomplete remoto de ciudades. |
| `cleanup-media` | Borra con la Storage API la media en cuarentena (>24 h) y la pública huérfana (>7 días). La llama solo el job pg_cron `media-cleanup`; exige el header `x-cleanup-secret`. |

> **Limpieza de idempotency keys:** no es una Edge Function. La hace el job de
> pg_cron `idempotency-keys-cleanup` (diario 3:30 UTC), que llama a
> `cleanup_old_idempotency_keys()` (`supabase/migrations/010_idempotency_cleanup_cron.sql`).
> La función `cleanup-idempotency` se eliminó el 2026-11-18 por redundante.

---

## 🚀 Setup

```bash
brew install supabase/tap/supabase   # si no está instalado
supabase login
supabase link --project-ref <your-project-id>
```

## 📦 Deploy

```bash
supabase functions deploy moderate-gossip      # una función
supabase functions deploy moderate-gossip --debug
supabase functions deploy                      # todas
```

`scripts/reset-database.sh` despliega todas las carpetas de este directorio.

## 🔍 Logs y pruebas manuales

```bash
supabase functions list
supabase functions logs moderate-gossip --tail
```

La CLI **no** tiene `functions invoke` ni `functions schedule`. Para probar una
función, usar curl con un JWT de usuario (las funciones exigen autenticación):

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/<funcion> \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

## ⏰ Tareas programadas

Se programan con **pg_cron** dentro de una migración (ver `003_error_logs.sql`,
job `error-logs-cleanup`), no desde la CLI. Para llamar a una Edge Function desde
un cron: Dashboard → Integrations → Cron, o `pg_cron` + `net.http_post` con la key
guardada en Vault (nunca commitear keys).

```sql
SELECT jobname, schedule, active FROM cron.job;   -- ver jobs
SELECT cron.unschedule('<jobname>');              -- quitar uno
```

### Limpieza de media (`media-cleanup`, migración 011)

Setup único por proyecto (los valores **nunca** van al repo):

```bash
# 1. Generar un secret y guardarlo en la función
SECRET=$(openssl rand -hex 32)
supabase secrets set MEDIA_CLEANUP_SECRET=$SECRET
supabase functions deploy cleanup-media
```

```sql
-- 2. Mismos valores en Vault (SQL Editor del Dashboard)
SELECT vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
SELECT vault.create_secret('<anon key>', 'anon_key');
SELECT vault.create_secret('<el mismo SECRET>', 'media_cleanup_secret');
```

Verificar: ejecutar a mano el comando del job (`SELECT command FROM cron.job
WHERE jobname = 'media-cleanup'`) y revisar
`SELECT status_code, content FROM net._http_response ORDER BY created DESC LIMIT 1;`
→ `200` con `{"success":true,...}`. `SELECT * FROM get_media_cleanup_candidates(10);`
muestra qué se borraría.

## 🛡️ Moderadores

Un moderador es un usuario con `app_metadata.role = 'moderator'`. Solo el
equipo puede asignarlo (el usuario no puede escribir su `app_metadata`):

- **Dashboard:** Authentication → Users → el usuario → editar *Raw app meta data* → `{"role": "moderator"}`
- **Script (service role):** `PUT /auth/v1/admin/users/<id>` con `{"app_metadata": {"role": "moderator"}}`

`moderation-review` lee el rol del servidor en cada llamada (`auth.getUser()`),
así que asignarlo o quitarlo aplica **de inmediato**, sin volver a iniciar
sesión. (El JWT también lo trae, pero solo después de refrescar la sesión: no
usar el claim del JWT para autorizar.) Para quitarlo, borrar la clave `role`.

Umbrales de reportes: tabla `moderation_settings`; reglas de contenido de
`moderate-gossip` (términos, umbrales de IA, reglas fijas on/off): tabla
`moderation_rules` (ambas en Table Editor, sin desplegar; ver
`moderate-gossip/README.md`). Código
compartido de media: `_shared/media.ts`. Tests (Deno):

```bash
docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
  deno test moderate-gossip/moderation.test.ts moderation-review/logic.test.ts
```

---

## 🔐 Secrets

Las funciones reciben automáticamente `SUPABASE_URL`, `SUPABASE_ANON_KEY` y
`SUPABASE_SERVICE_ROLE_KEY`. Otros secrets: `supabase secrets set NOMBRE=valor`.

---

**Última actualización:** 2026-11-19
