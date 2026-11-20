-- =====================================================
-- TEST DE SEGURIDAD: creación de gossips solo vía servidor
-- =====================================================
-- Verifica que un cliente (anon o authenticated) NO puede crear ni publicar
-- gossips saltándose la Edge Function moderate-gossip:
--   1. INSERT directo en gossips → bloqueado (anon y authenticated)
--   2. RPC upsert_gossip_idempotent → sin permiso (anon y authenticated)
--   3. RPC create_gossip_draft (legacy) → sin permiso
--   4. RPCs de rate limit → sin permiso
--   5. service_role (Edge Function) sí puede, e idempotencia funciona
--
-- Ejecutar (local):
--   docker exec -i supabase_db_<project_id> psql -U postgres -v ON_ERROR_STOP=1 \
--     < supabase/tests/001_gossip_creation_security_test.sql
-- Todo corre en una transacción con ROLLBACK: no deja datos.
-- Cualquier fallo aborta con RAISE EXCEPTION.
-- =====================================================

BEGIN;

-- Usuario real (gossips.created_by tiene FK a auth.users)
INSERT INTO auth.users (id, email, aud, role)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'security-test@test.local', 'authenticated', 'authenticated');

CREATE TEMP TABLE _t (user_id UUID, claims TEXT) ON COMMIT DROP;
INSERT INTO _t VALUES (
  'aaaaaaaa-0000-4000-8000-000000000001',
  '{"sub": "aaaaaaaa-0000-4000-8000-000000000001", "role": "authenticated"}'
);
GRANT SELECT ON _t TO anon, authenticated, service_role;

-- Helper: intenta un statement y exige que falle por permisos/RLS
CREATE OR REPLACE FUNCTION pg_temp.expect_denied(p_label TEXT, p_sql TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RAISE EXCEPTION '❌ % : NO fue bloqueado', p_label;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE '✅ % : bloqueado (%)', p_label, SQLERRM;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.expect_denied(TEXT, TEXT) TO anon, authenticated;

-- =====================================================
-- Ataques como anon y como authenticated
-- =====================================================
DO $$
DECLARE
  v_role TEXT;
  v_insert TEXT := $q$
    INSERT INTO gossips (subject, content, country_id, region_id, city_id,
      published_as, status, moderation_status, visibility, created_by)
    VALUES ('bypass', 'bypass', 'x', 'x', 'x', 'anonymous',
      'published', 'approved', 'public', 'aaaaaaaa-0000-4000-8000-000000000001')
  $q$;
  v_upsert TEXT := $q$
    SELECT upsert_gossip_idempotent(
      p_subject := 'bypass', p_content := 'bypass',
      p_country_id := 'x', p_region_id := 'x', p_city_id := 'x',
      p_published_as := 'profile', p_status := 'published',
      p_moderation_status := 'approved', p_visibility := 'public',
      p_created_by := 'aaaaaaaa-0000-4000-8000-000000000001',
      p_idempotency_key := gen_random_uuid())
  $q$;
  v_draft TEXT := $q$
    SELECT create_gossip_draft(
      p_subject := 'x', p_content := 'x', p_country_id := 'x',
      p_region_id := 'x', p_city_id := 'x', p_published_as := 'anonymous')
  $q$;
  v_reserve TEXT := $q$
    SELECT reserve_rate_limit_slot('aaaaaaaa-0000-4000-8000-000000000001', 'create_gossip')
  $q$;
  v_release TEXT := $q$
    SELECT release_rate_limit_slot('aaaaaaaa-0000-4000-8000-000000000001', 'create_gossip')
  $q$;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    IF v_role = 'anon' THEN
      PERFORM set_config('request.jwt.claims', '{"role": "anon"}', true);
    ELSE
      PERFORM set_config('request.jwt.claims', (SELECT claims FROM _t), true);
    END IF;
    EXECUTE format('SET LOCAL ROLE %I', v_role);

    PERFORM pg_temp.expect_denied(v_role || ' INSERT directo', v_insert);
    PERFORM pg_temp.expect_denied(v_role || ' upsert_gossip_idempotent', v_upsert);
    PERFORM pg_temp.expect_denied(v_role || ' create_gossip_draft', v_draft);
    PERFORM pg_temp.expect_denied(v_role || ' reserve_rate_limit_slot', v_reserve);
    PERFORM pg_temp.expect_denied(v_role || ' release_rate_limit_slot', v_release);

    RESET ROLE;
  END LOOP;
END $$;

-- Ningún ataque dejó filas
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM gossips WHERE created_by = 'aaaaaaaa-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION '❌ Se creó un gossip desde un cliente';
  END IF;
  RAISE NOTICE '✅ Ningún gossip creado desde clientes';
END $$;

-- =====================================================
-- service_role (Edge Function) sí puede, con idempotencia
-- =====================================================
SET LOCAL ROLE service_role;

DO $$
DECLARE
  v_key UUID := gen_random_uuid();
  v_r1 JSON;
  v_r2 JSON;
BEGIN
  SELECT upsert_gossip_idempotent(
    p_subject := 'Test servidor', p_content := 'Creado por la Edge Function',
    p_country_id := 'x', p_region_id := 'x', p_city_id := 'x',
    p_published_as := 'anonymous', p_status := 'draft',
    p_moderation_status := 'pending', p_visibility := 'private',
    p_created_by := (SELECT user_id FROM _t), p_idempotency_key := v_key
  ) INTO v_r1;

  SELECT upsert_gossip_idempotent(
    p_subject := 'Test servidor DUPLICADO', p_content := 'Reintento',
    p_country_id := 'x', p_region_id := 'x', p_city_id := 'x',
    p_published_as := 'anonymous', p_status := 'draft',
    p_moderation_status := 'pending', p_visibility := 'private',
    p_created_by := (SELECT user_id FROM _t), p_idempotency_key := v_key
  ) INTO v_r2;

  IF (v_r1->'gossip'->>'id') IS NULL THEN
    RAISE EXCEPTION '❌ service_role no pudo crear el gossip: %', v_r1;
  END IF;

  IF (v_r1->'gossip'->>'id') <> (v_r2->'gossip'->>'id')
     OR (v_r2->>'idempotent')::BOOLEAN IS NOT TRUE THEN
    RAISE EXCEPTION '❌ Idempotencia falló: % / %', v_r1, v_r2;
  END IF;

  IF (SELECT COUNT(*) FROM gossips WHERE idempotency_key = v_key) <> 1 THEN
    RAISE EXCEPTION '❌ Se crearon gossips duplicados con la misma key';
  END IF;

  RAISE NOTICE '✅ service_role crea gossips y la idempotencia evita duplicados';
END $$;

RESET ROLE;

DO $$ BEGIN RAISE NOTICE '✅ TODOS LOS TESTS DE SEGURIDAD PASARON'; END $$;

ROLLBACK;
