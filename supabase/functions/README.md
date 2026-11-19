# Supabase Edge Functions

Funciones Deno que corren en Supabase. Cada carpeta es una función (`index.ts`).

## 📋 Funciones

| Función | Qué hace |
|---|---|
| `moderate-gossip` | Crea chismes: valida input, rate limit, modera y sube media a cuarentena. Escribe con el RPC `upsert_gossip_idempotent()` (la app nunca hace INSERT directo, ver `.claude/SECURITY.md`). |
| `report-gossip` | Permite reportar chismes inapropiados. |
| `delete-account` | Borra la cuenta del usuario y todos sus datos (GDPR). |
| `log-error` | Recibe logs de error de la app (autenticado, sanitiza el contexto). |
| `search-cities` | Autocomplete remoto de ciudades. |

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

## 🔐 Secrets

Las funciones reciben automáticamente `SUPABASE_URL`, `SUPABASE_ANON_KEY` y
`SUPABASE_SERVICE_ROLE_KEY`. Otros secrets: `supabase secrets set NOMBRE=valor`.

---

**Última actualización:** 2026-11-18
