# Tests SQL

Tests de regresión que corren contra un Supabase **local** con las migraciones
y el seed aplicados. Cada uno corre en una transacción con `ROLLBACK` y falla
(`RAISE EXCEPTION`) si algo no es lo esperado.

| Test | Qué verifica |
|---|---|
| `001_gossip_creation_security_test.sql` | Los clientes no pueden crear chismes saltándose la Edge Function |
| `002_popular_feed_test.sql` | Ranking del feed por anillos de cercanía, tendencia, relleno, paginación |
| `003_api_grants_test.sql` | Permisos de cada rol (`anon`, `authenticated`, `service_role`) en cada camino real |
| `004_anonymous_author_privacy_test.sql` | Nadie salvo el autor y `service_role` ve el autor de un chisme anónimo (tabla, vista, filtros, búsqueda, feed) |
| `005_moderation_test.sql` | Umbral de reportes (mínimo, cuentas nuevas, relativo, popular, configurable), cola de revisión (encolar, media protegida, aprobar/rechazar, historial) y reglas de contenido (`moderation_rules`: validación, duplicados) |

## 🔁 E2E de Edge Functions (`e2e/`)

`./scripts/e2e.sh` levanta un Supabase local temporal (migraciones + seed +
Edge Functions del repo, imitando los privilegios del remoto), un OpenAI
falso (`e2e/fake_openai.ts`) y corre `e2e/edge_functions_e2e.test.ts` con
requests HTTP reales. Al terminar apaga y borra todo (`KEEP=1` para dejarlo
levantado). No toca el proyecto remoto. Tarda ~1–2 min.

| Grupo | Qué verifica |
|---|---|
| Auth | Sin token / token inválido / anon key → 401; usuario normal en `moderation-review` → 403; moderador → 200 |
| Validación | Campos vacíos o largos, enum, UUID, ciudad inexistente, JSON inválido → 400; cooldown → 429; idempotencia sin duplicados |
| Moderación | Limpio → publicado y visible; marcado → 400; IA caída → cola `ai_unavailable`; términos y umbrales de `moderation_rules` (editables en caliente) |
| Media | Imagen → bucket público y cuarentena vacía (OpenAI recibe data URL); PDF disfrazado y >5 MB → 400; imagen marcada → borrada de cuarentena; en revisión queda en cuarentena y al aprobar se publica |
| Reportes y cola | Propio / motivo / inexistente / duplicado; 3 reportes → cola; rechazar exige gravedad, oculta y no se decide dos veces; historial y paginación |

El OpenAI falso responde según marcadores en el texto: `[[ai:down]]`,
`[[ai:flag=<cat>]]`, `[[ai:flag-image=<cat>]]`, `[[ai:score=<cat>:<n>]]`.
`moderate-gossip` lo usa por la variable `OPENAI_MODERATION_URL`, que **solo**
se define en el E2E (nunca en el remoto).

Correrlo antes de desplegar Edge Functions o migraciones.

## ⚠️ Imitar los privilegios del remoto

El proyecto remoto **no** da privilegios por defecto a los roles de la API en
tablas/funciones nuevas; el Supabase local **sí**. Si se prueba sin imitarlo,
una tabla sin `GRANT` pasa en local y falla en producción con
`permission denied for table ...`.

Antes de las migraciones, aplicar en la base de prueba (no va en el repo):

```sql
-- 000_emulate_remote_privileges.sql (SOLO en el directorio temporal de prueba)
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
```

## Cómo correrlos

```bash
# Directorio temporal fuera del repo
mkdir -p /tmp/sbtest && cd /tmp/sbtest && supabase init
mkdir -p supabase/migrations
# (crear aquí 000_emulate_remote_privileges.sql con el bloque de arriba)
cp <repo>/supabase/migrations/0*.sql supabase/migrations/
cp <repo>/supabase/seed.sql supabase/
supabase start -x studio,imgproxy,realtime,edge-runtime,logflare,vector,inbucket,mailpit,supavisor,postgres-meta

for t in <repo>/supabase/tests/0*.sql; do
  docker exec -i supabase_db_<project_id> psql -U postgres -q < "$t"
done

supabase stop --no-backup && rm -rf /tmp/sbtest
```
