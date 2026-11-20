# Tests SQL

Tests de regresión que corren contra un Supabase **local** con las migraciones
y el seed aplicados. Cada uno corre en una transacción con `ROLLBACK` y falla
(`RAISE EXCEPTION`) si algo no es lo esperado.

| Test | Qué verifica |
|---|---|
| `001_gossip_creation_security_test.sql` | Los clientes no pueden crear chismes saltándose la Edge Function |
| `002_popular_feed_test.sql` | Ranking del feed por anillos de cercanía, tendencia, relleno, paginación |
| `003_api_grants_test.sql` | Permisos de cada rol (`anon`, `authenticated`, `service_role`) en cada camino real |

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
