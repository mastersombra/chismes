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
| `006_account_deletion_test.sql` | Eliminación de cuenta: media a borrar, borrado en cascada sin tocar datos de otros, registro anónimo de faltas (solo con faltas, acumula por email, sin email no guarda), usuario inexistente, sin acceso de clientes |
| `007_sanctions_test.sql` | Sanciones (advertencia, restricción 24 h / 7 días, suspensión, vencimiento, umbrales editables), apelaciones (dueño, plazo, duplicado, aceptar anula y republica, otro moderador), estado de la cuenta sin datos internos, reincidentes, eliminación sin faltas anuladas, sin acceso de clientes |
| `008_policy_acceptances_test.sql` | Al crear un usuario se registran las versiones vigentes de las políticas; una versión nueva aplica solo a usuarios nuevos; cada usuario lee solo sus aceptaciones y nadie las escribe desde la API; borrado en cascada; formato de versión |
| `009_profile_editing_test.sql` | Clientes sin escritura en `profiles`; límite de cambio de @usuario (primera elección libre, plazo, configurable, fecha no manipulable, otros campos no lo tocan); `user_settings` (creada al registrarse, solo el dueño y solo preferencias, CHECK, cascada); bucket `avatars` |

## 🔁 E2E de Edge Functions (`e2e/`)

`./scripts/e2e.sh` levanta un Supabase local temporal (migraciones + seed +
Edge Functions del repo, imitando los privilegios del remoto), un OpenAI
falso (`e2e/fake_openai.ts`) y corre `e2e/*.test.ts` con
requests HTTP reales. Al terminar apaga y borra todo (`KEEP=1` para dejarlo
levantado). No toca el proyecto remoto. Tarda ~1–2 min.

| Grupo | Qué verifica |
|---|---|
| Auth | Sin token / token inválido / anon key → 401; usuario normal en `moderation-review` → 403; moderador → 200 |
| Validación | Campos vacíos o largos, enum, UUID, ciudad inexistente, JSON inválido → 400; cooldown → 429; idempotencia sin duplicados |
| Moderación | Limpio → publicado y visible; marcado → 400; IA caída → cola `ai_unavailable`; términos y umbrales de `moderation_rules` (editables en caliente) |
| Media | Imagen → bucket público y cuarentena vacía (OpenAI recibe data URL); PDF disfrazado y >5 MB → 400; imagen marcada → borrada de cuarentena; en revisión queda en cuarentena y al aprobar se publica |
| Reportes y cola | Propio / motivo / inexistente / duplicado; 3 reportes → cola; rechazar exige gravedad, oculta y no se decide dos veces; historial y paginación |
| Eliminar cuenta (`delete_account_e2e.test.ts`) | Sin usuario → 401; sin confirmación → 400 y la cuenta sigue; borra auth, chismes, perfil y media (pública y cuarentena); con faltas guarda el registro anónimo por gravedad; el token viejo deja de servir |
| Storage (`storage_rls_e2e.test.ts`) | Acceso directo de clientes (anon y usuario) a los 5 buckets (incluido `avatars`): no escriben, mueven, copian, borran ni listan; la cuarentena no se lee ni se firma; lo público se ve solo por URL; nadie administra buckets |
| Sanciones (`sanctions_e2e.test.ts`) | `account-status` (auth, estado); rechazo alto → no publica ni reporta (403); apelar (validación, ajeno, duplicado), el panel la lista, aceptar → desbloquea y republica; leve → advertencia; reincidente con crítica que elimina la cuenta y vuelve con el mismo email → sigue suspendido |
| Perfil (`update_profile_e2e.test.ts`) | Auth y validación; la app no escribe `profiles` directo; sin cambios no gasta límite; texto marcado o con datos personales → 400; IA caída → 503 sin cola; @usuario duplicado y plazo de 30 días; foto (formato real, sube a `avatars`, borra la anterior, quitar); foto marcada → nada se sube; con sanción no cambia texto ni foto pero sí borra; `user_settings` directa del dueño; eliminar la cuenta borra la foto |

El OpenAI falso responde según marcadores en el texto: `[[ai:down]]`,
`[[ai:flag=<cat>]]`, `[[ai:flag-image=<cat>]]`, `[[ai:score=<cat>:<n>]]`.
`moderate-gossip` lo usa por la variable `OPENAI_MODERATION_URL`, que **solo**
se define en el E2E (nunca en el remoto).

Antes del E2E, el script corre también los tests SQL de esta carpeta
(`SQL_TESTS=0` para saltarlos): un solo comando valida migraciones, permisos
y funciones.

**CI:** `.github/workflows/backend.yml` corre los tests unitarios de Deno y
`./scripts/e2e.sh` en cada PR/push a `main` que toque `supabase/**`.

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
