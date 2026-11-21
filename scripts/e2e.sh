#!/usr/bin/env bash
# =====================================================
# E2E de Edge Functions contra un Supabase LOCAL temporal
# =====================================================
# 1. Crea un proyecto Supabase temporal (fuera del repo) con las migraciones,
#    el seed y las Edge Functions del repo, imitando los privilegios del
#    remoto (sin GRANT por defecto: ver supabase/tests/README.md).
# 2. Levanta un OpenAI falso (supabase/tests/e2e/fake_openai.ts).
# 3. Sirve las funciones con `supabase functions serve`.
# 4. Corre los tests SQL (supabase/tests/0*.sql) y supabase/tests/e2e/*.test.ts
#    (Deno en Docker). SQL_TESTS=0 para saltar los SQL.
# 5. Apaga y borra todo, pase o falle.
#
# Requisitos: Docker y Supabase CLI. No toca el proyecto remoto.
# Uso:   ./scripts/e2e.sh            (KEEP=1 para dejarlo levantado al terminar)
# =====================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="chismes_e2e"
NETWORK="supabase_network_${PROJECT}"
OPENAI_CONTAINER="chismes-e2e-openai"
DENO_IMAGE="denoland/deno:2.1.4"
WORK="$(mktemp -d /tmp/chismes-e2e.XXXXXX)"
SERVE_LOG="$WORK/functions-serve.log"
SERVE_PID=""

log() { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }

cleanup() {
  local code=$?
  if [[ "${KEEP:-0}" == "1" ]]; then
    log "KEEP=1: queda levantado en $WORK (apagar: cd $WORK && supabase stop --no-backup)"
    exit $code
  fi
  log "Limpiando"
  [[ -n "$SERVE_PID" ]] && kill "$SERVE_PID" 2>/dev/null || true
  docker rm -f "$OPENAI_CONTAINER" >/dev/null 2>&1 || true
  (cd "$WORK" && supabase stop --no-backup >/dev/null 2>&1) || true
  if [[ $code -ne 0 && -f "$SERVE_LOG" ]]; then
    echo "--- últimas líneas de functions serve ---"
    tail -40 "$SERVE_LOG" || true
  fi
  rm -rf "$WORK"
  exit $code
}
trap cleanup EXIT

# ---------- 1. Proyecto temporal ----------
log "Proyecto temporal en $WORK"
cd "$WORK"
yes n | supabase init >/dev/null 2>&1 || true
sed -i.bak "s/^project_id = .*/project_id = \"${PROJECT}\"/" supabase/config.toml

mkdir -p supabase/migrations
cat > supabase/migrations/000_emulate_remote_privileges.sql <<'SQL'
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
SQL
cp "$REPO"/supabase/migrations/0*.sql supabase/migrations/
cp "$REPO/supabase/seed.sql" supabase/
rm -rf supabase/functions
cp -R "$REPO/supabase/functions" supabase/functions

log "Levantando Supabase local (puede tardar la primera vez)"
supabase start -x studio,imgproxy,realtime,logflare,vector,inbucket,mailpit,supavisor,postgres-meta >/dev/null

STATUS="$(supabase status -o json 2>/dev/null)"
json() { python3 -c "import json,sys; print(json.load(sys.stdin)['$1'])" <<<"$STATUS"; }
ANON_KEY="$(json ANON_KEY)"
SERVICE_KEY="$(json SERVICE_ROLE_KEY)"
HOST_API="$(json API_URL)"

# ---------- Tests SQL (antes de crear datos de prueba: cada uno hace ROLLBACK) ----------
if [[ "${SQL_TESTS:-1}" == "1" ]]; then
  for t in "$REPO"/supabase/tests/0*.sql; do
    log "SQL: $(basename "$t")"
    docker exec -i "supabase_db_${PROJECT}" psql -U postgres -q -v ON_ERROR_STOP=1 <"$t" >/dev/null
  done
fi

# Ciudad de prueba (el seed no trae ciudades: se importan de GeoNames)
docker exec -i "supabase_db_${PROJECT}" psql -U postgres -q -v ON_ERROR_STOP=1 <<'SQL'
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
VALUES ('e2e-city', 'co-antioquia', 'CO', 'Ciudad E2E', 6.25, -75.56)
ON CONFLICT (id) DO NOTHING;
SQL

# ---------- 2. OpenAI falso ----------
log "OpenAI falso"
docker rm -f "$OPENAI_CONTAINER" >/dev/null 2>&1 || true
docker run -d --rm --name "$OPENAI_CONTAINER" --network "$NETWORK" \
  -v "$REPO/supabase/tests/e2e:/e2e:ro" "$DENO_IMAGE" \
  run --allow-net --allow-env /e2e/fake_openai.ts >/dev/null

# ---------- 3. Edge Functions ----------
log "Sirviendo Edge Functions"
cat > "$WORK/e2e.env" <<ENV
OPENAI_API_KEY=sk-e2e-fake
OPENAI_MODERATION_URL=http://${OPENAI_CONTAINER}:8000/v1/moderations
MEDIA_CLEANUP_SECRET=e2e-secret
ACCOUNT_HASH_SECRET=e2e-hash-secret
ENV
supabase functions serve --env-file "$WORK/e2e.env" >"$SERVE_LOG" 2>&1 &
SERVE_PID=$!

for _ in $(seq 1 60); do
  code="$(curl -s -o /dev/null -w '%{http_code}' -X OPTIONS "$HOST_API/functions/v1/moderation-review" || true)"
  [[ "$code" == "200" ]] && break
  sleep 2
done
[[ "$code" == "200" ]] || { echo "Las Edge Functions no arrancaron"; exit 1; }

# ---------- 4. Tests ----------
log "Corriendo E2E"
docker run --rm --network "$NETWORK" \
  -v "$REPO/supabase/tests/e2e:/e2e:ro" -w /e2e \
  -e DENO_NO_UPDATE_CHECK=1 \
  -e E2E_API_URL="http://supabase_kong_${PROJECT}:8000" \
  -e E2E_ANON_KEY="$ANON_KEY" \
  -e E2E_SERVICE_KEY="$SERVICE_KEY" \
  -e E2E_FAKE_OPENAI_URL="http://${OPENAI_CONTAINER}:8000" \
  -e E2E_ACCOUNT_HASH_SECRET=e2e-hash-secret \
  -e E2E_COUNTRY_ID=CO -e E2E_REGION_ID=co-antioquia -e E2E_CITY_ID=e2e-city \
  "$DENO_IMAGE" test --allow-net --allow-env --no-lock /e2e/

log "✅ E2E OK"
