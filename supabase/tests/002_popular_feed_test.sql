-- =====================================================
-- Test: get_popular_feed / check_new_gossips (anillos de cercanía)
-- =====================================================
-- Escenarios: usuario en Medellín, solo país, sin ubicación, relleno,
-- tendencia relativa, paginación y autor anónimo oculto.
-- Imprime los resultados y falla (RAISE) si el ranking no es el esperado.
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/002_popular_feed_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;
-- Ubicaciones de prueba
INSERT INTO regions (id, country_id, name, type) VALUES ('es-madrid','ES','Madrid','community') ON CONFLICT DO NOTHING;
INSERT INTO cities (id, region_id, country_id, name, lat, lon) VALUES
 ('t-medellin','co-antioquia','CO','Medellín',6.25,-75.56),
 ('t-envigado','co-antioquia','CO','Envigado',6.17,-75.59),
 ('t-pasto','co-narino','CO','Pasto',1.21,-77.28),
 ('t-madrid','es-madrid','ES','Madrid',40.4,-3.7),
 ('t-bogota','co-cundinamarca','CO','Bogotá',4.7,-74.07);
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','a@t.co'),
 ('22222222-2222-2222-2222-222222222222','00000000-0000-0000-0000-000000000000','authenticated','authenticated','b@t.co');

-- Chismes (autor 1111; uno anónimo). Triggers off: fuerzan likes=0 y created_at=now()
SET LOCAL session_replication_role = replica;
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility, like_count, comment_count, share_count, created_at) VALUES
 ('a0000000-0000-0000-0000-000000000001','CO','co-antioquia','t-medellin','Medellin sin likes','x','anonymous','11111111-1111-1111-1111-111111111111','published','approved','public',0,0,0, now()-interval '1 hour'),
 ('a0000000-0000-0000-0000-000000000002','CO','co-antioquia','t-medellin','Medellin 20 likes','x','profile','11111111-1111-1111-1111-111111111111','published','approved','public',20,0,0, now()-interval '5 hours'),
 ('a0000000-0000-0000-0000-000000000003','CO','co-antioquia','t-envigado','Envigado','x','profile','11111111-1111-1111-1111-111111111111','published','approved','public',0,0,0, now()-interval '2 hours'),
 ('a0000000-0000-0000-0000-000000000004','CO','co-narino','t-pasto','Senora de Pasto','x','profile','11111111-1111-1111-1111-111111111111','published','approved','public',0,0,0, now()-interval '2 hours'),
 ('a0000000-0000-0000-0000-000000000005','ES','es-madrid','t-madrid','Boda de Shakira','x','profile','11111111-1111-1111-1111-111111111111','published','approved','public',5000,800,300, now()-interval '6 hours'),
 ('a0000000-0000-0000-0000-000000000006','ES','es-madrid','t-madrid','Madrid aburrido','x','profile','11111111-1111-1111-1111-111111111111','published','approved','public',1,0,0, now()-interval '3 hours'),
 ('a0000000-0000-0000-0000-000000000007','CO','co-antioquia','t-medellin','Medellin pendiente','x','profile','11111111-1111-1111-1111-111111111111','draft','pending','public',0,0,0, now());

SET LOCAL session_replication_role = origin;
-- Como usuario 2222 (no autor)
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',true);

\echo '=== 1. Usuario en Medellin (backfill activo: <20 cercanos) ==='
SELECT d->>'subject' AS subject, d->>'proximity' AS prox, d->>'city_name' AS city, d->>'is_trending' AS trend, round((d->>'score')::numeric,1) AS score, d->>'created_by' IS NULL AS author_hidden
FROM json_array_elements(get_popular_feed('t-medellin','co-antioquia','CO')->'data') d;

\echo '=== 2. Sin relleno (backfill_min_items=0): sale Madrid aburrido, Shakira se queda por tendencia ==='
RESET ROLE;
UPDATE feed_settings SET value = 0 WHERE key = 'backfill_min_items';
SET LOCAL ROLE authenticated;
SELECT d->>'subject' AS subject, d->>'proximity' AS prox, d->>'is_trending' AS trend
FROM json_array_elements(get_popular_feed('t-medellin','co-antioquia','CO')->'data') d;

\echo '=== 3. Solo país (sin ciudad, region del telefono CO) ==='
SELECT d->>'subject' AS subject, d->>'proximity' AS prox, d->>'is_from_my_city' AS mycity
FROM json_array_elements(get_popular_feed(NULL,NULL,'CO')->'data') d;

\echo '=== 4. Sin ubicacion: global ==='
SELECT count(*) AS total FROM json_array_elements(get_popular_feed()->'data');

\echo '=== 5. Paginacion page_size=2 ==='
SELECT (get_popular_feed('t-medellin','co-antioquia','CO',2))->'has_more' AS has_more,
       (get_popular_feed('t-medellin','co-antioquia','CO',2))->'next_cursor' AS cursor;
WITH p1 AS (SELECT get_popular_feed('t-medellin','co-antioquia','CO',2) j)
SELECT d->>'subject' AS page2 FROM p1, json_array_elements(get_popular_feed('t-medellin','co-antioquia','CO',2,((p1.j->'next_cursor'->>'score'))::numeric,((p1.j->'next_cursor'->>'id'))::uuid)->'data') d;

\echo '=== 6. check_new_gossips (ultimas 4h): Medellin+region+pais / solo pais / global ==='
SELECT check_new_gossips('t-medellin','co-antioquia','CO', now()-interval '4 hours') AS cercanos,
       check_new_gossips(NULL,NULL,'ES', now()-interval '4 hours') AS espana,
       check_new_gossips(NULL,NULL,NULL, now()-interval '4 hours') AS global;


\echo '=== Asserts ==='
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',true);
DO $$
DECLARE
  medellin TEXT[];
  pais TEXT[];
BEGIN
  -- Con relleno desactivado (backfill_min_items = 0 desde el escenario 2)
  SELECT array_agg(d->>'subject') INTO medellin
  FROM json_array_elements(get_popular_feed('t-medellin','co-antioquia','CO')->'data') d;
  IF medellin <> ARRAY['Boda de Shakira','Medellin 20 likes','Medellin sin likes','Envigado','Senora de Pasto'] THEN
    RAISE EXCEPTION 'Orden inesperado (Medellín): %', medellin;
  END IF;

  SELECT array_agg(d->>'subject') INTO pais
  FROM json_array_elements(get_popular_feed(NULL,NULL,'CO')->'data') d;
  IF 'Madrid aburrido' = ANY(pais) OR NOT 'Boda de Shakira' = ANY(pais) OR array_length(pais,1) <> 5 THEN
    RAISE EXCEPTION 'Feed solo-país inesperado: %', pais;
  END IF;

  IF (SELECT count(*) FROM json_array_elements(get_popular_feed()->'data')) <> 6 THEN
    RAISE EXCEPTION 'Feed global debería tener los 6 publicados';
  END IF;

  IF EXISTS (SELECT 1 FROM json_array_elements(get_popular_feed()->'data') d
             WHERE d->>'published_as' = 'anonymous' AND d->>'created_by' IS NOT NULL) THEN
    RAISE EXCEPTION 'created_by expuesto en chisme anónimo';
  END IF;

  IF check_new_gossips('t-medellin','co-antioquia','CO', now()-interval '4 hours') <> 3 THEN
    RAISE EXCEPTION 'check_new_gossips cercanos inesperado';
  END IF;

  RAISE NOTICE '✅ TODOS LOS TESTS DEL FEED PASARON';
END $$;

\echo '=== 7. Autor ve su anonimo con created_by ==='
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',true);
SELECT d->>'subject', d->>'created_by' IS NOT NULL AS author_visible
FROM json_array_elements(get_popular_feed('t-medellin')->'data') d WHERE d->>'subject' = 'Medellin sin likes';

\echo '=== 8. authenticated no puede escribir feed_settings ==='
RESET ROLE;
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  UPDATE feed_settings SET value = 999 WHERE key = 'weight_city';
  IF (SELECT value FROM feed_settings WHERE key='weight_city') = 999 THEN RAISE EXCEPTION 'authenticated pudo escribir feed_settings'; END IF;
  RAISE NOTICE 'OK: update sin efecto (RLS)';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK: sin privilegio de escritura';
END $$;
ROLLBACK;
