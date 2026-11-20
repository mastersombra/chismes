-- =====================================================
-- Test: privacidad del autor de chismes anónimos
-- =====================================================
-- Nadie salvo el propio autor y el equipo administrador (service_role)
-- puede saber quién publicó un chisme anónimo, por ningún camino de la API:
-- tabla directa, vista public_gossips, filtros, search_gossips, feed.
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados (imitando
-- los privilegios del remoto, ver README):
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/004_anonymous_author_privacy_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

SET LOCAL session_replication_role = replica; -- datos de prueba sin triggers
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-medellin','co-antioquia','CO','Medellín',6.25,-75.56);
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','autor@t.co'),
 ('22222222-2222-2222-2222-222222222222','00000000-0000-0000-0000-000000000000','authenticated','authenticated','otro@t.co');
-- Autor 1111: un anónimo publicado, uno con perfil publicado, un borrador anónimo
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, modified_by, status, moderation_status, visibility) VALUES
 ('b0000000-0000-0000-0000-000000000001','CO','co-antioquia','t-medellin','Secreto anonimo','x','anonymous','11111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111','published','approved','public'),
 ('b0000000-0000-0000-0000-000000000002','CO','co-antioquia','t-medellin','Con perfil','x','profile','11111111-1111-1111-1111-111111111111',NULL,'published','approved','public'),
 ('b0000000-0000-0000-0000-000000000003','CO','co-antioquia','t-medellin','Borrador anonimo','x','anonymous','11111111-1111-1111-1111-111111111111',NULL,'draft','pending','public');
SET LOCAL session_replication_role = origin;

-- ---------- La vista no expone columnas internas ----------
DO $$
DECLARE leaked TEXT;
BEGIN
  SELECT string_agg(column_name, ', ') INTO leaked
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'public_gossips'
    AND column_name IN ('modified_by','deleted_by','report_count','idempotency_key',
                        'storage_path','thumbnail_storage_path','audio_storage_path');
  IF leaked IS NOT NULL THEN
    RAISE EXCEPTION 'public_gossips expone columnas internas: %', leaked;
  END IF;
  RAISE NOTICE '✅ public_gossips no expone modified_by/deleted_by/report_count/idempotency_key/storage paths';
END $$;

-- ---------- Otro usuario (2222) ----------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',true);
DO $$
DECLARE
  v_author UUID;
  v_count INT;
  v_feed JSON;
BEGIN
  -- 1. La tabla no es legible
  BEGIN
    PERFORM created_by FROM gossips;
    RAISE EXCEPTION 'authenticated puede leer la tabla gossips';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- 2. La vista oculta el autor del anónimo y muestra el del chisme con perfil
  SELECT created_by INTO v_author FROM public_gossips WHERE id = 'b0000000-0000-0000-0000-000000000001';
  IF NOT FOUND THEN RAISE EXCEPTION 'el chisme anónimo publicado no es visible'; END IF;
  IF v_author IS NOT NULL THEN RAISE EXCEPTION 'public_gossips revela el autor de un anónimo'; END IF;
  SELECT created_by INTO v_author FROM public_gossips WHERE id = 'b0000000-0000-0000-0000-000000000002';
  IF v_author IS DISTINCT FROM '11111111-1111-1111-1111-111111111111' THEN
    RAISE EXCEPTION 'public_gossips no muestra el autor de un chisme con perfil';
  END IF;

  -- 3. Filtrar por autor no encuentra sus anónimos
  SELECT COUNT(*) INTO v_count FROM public_gossips
  WHERE created_by = '11111111-1111-1111-1111-111111111111' AND published_as = 'anonymous';
  IF v_count <> 0 THEN RAISE EXCEPTION 'filtrar por created_by des-anonimiza (% filas)', v_count; END IF;

  -- 4. Borradores ajenos no son visibles
  IF EXISTS (SELECT 1 FROM public_gossips WHERE id = 'b0000000-0000-0000-0000-000000000003') THEN
    RAISE EXCEPTION 'un borrador ajeno es visible';
  END IF;

  -- 5. search_gossips (búsqueda vacía = todo) no revela autores anónimos
  IF EXISTS (SELECT 1 FROM search_gossips('') s
             WHERE s.published_as = 'anonymous' AND s.created_by IS NOT NULL) THEN
    RAISE EXCEPTION 'search_gossips revela el autor de un anónimo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM search_gossips('Secreto')) THEN
    RAISE EXCEPTION 'search_gossips no encuentra el chisme anónimo';
  END IF;

  -- 6. El feed tampoco
  v_feed := get_popular_feed('t-medellin','co-antioquia','CO');
  IF EXISTS (SELECT 1 FROM json_array_elements(v_feed->'data') e
             WHERE e->>'published_as' = 'anonymous' AND e->>'created_by' IS NOT NULL) THEN
    RAISE EXCEPTION 'get_popular_feed revela el autor de un anónimo';
  END IF;

  RAISE NOTICE '✅ otro usuario: ni tabla, ni vista, ni filtros, ni búsqueda, ni feed revelan al autor';
END $$;

-- ---------- El propio autor (1111) ----------
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',true);
DO $$
DECLARE v_count INT;
BEGIN
  -- Ve sus anónimos con su autoría (perfil, conteo) y sus borradores
  SELECT COUNT(*) INTO v_count FROM public_gossips
  WHERE created_by = '11111111-1111-1111-1111-111111111111' AND status <> 'deleted';
  IF v_count <> 3 THEN RAISE EXCEPTION 'el autor ve % de sus 3 chismes', v_count; END IF;
  RAISE NOTICE '✅ autor: ve sus 3 chismes (incluidos anónimos y borrador)';
END $$;

-- ---------- Equipo administrador (service_role) ----------
RESET ROLE;
SET LOCAL ROLE service_role;
DO $$
BEGIN
  IF (SELECT created_by FROM gossips WHERE id = 'b0000000-0000-0000-0000-000000000001')
     IS DISTINCT FROM '11111111-1111-1111-1111-111111111111' THEN
    RAISE EXCEPTION 'service_role no ve el autor real';
  END IF;
  RAISE NOTICE '✅ service_role: ve el autor real en la tabla';
END $$;

-- ---------- anon (sin sesión) ----------
RESET ROLE;
SET LOCAL ROLE anon;
DO $$
DECLARE denied INT := 0;
BEGIN
  BEGIN PERFORM 1 FROM gossips; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM public_gossips; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM * FROM search_gossips(''); EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  IF denied <> 3 THEN RAISE EXCEPTION 'anon puede leer chismes (% de 3 bloqueados)', denied; END IF;
  RAISE NOTICE '✅ anon: sin acceso a tabla, vista ni búsqueda';
END $$;

RESET ROLE;
DO $$ BEGIN RAISE NOTICE '✅ TODOS LOS TESTS DE PRIVACIDAD PASARON'; END $$;
ROLLBACK;
