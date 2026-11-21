-- =====================================================
-- Test: eliminación de cuenta (014_account_deletion.sql)
-- =====================================================
-- A1: get_account_deletion_media devuelve la media pública y en cuarentena
-- A2: delete_user_account borra la cuenta y en cascada sus datos; los
--     chismes y decisiones de otros quedan
-- A3: con faltas guarda el registro anónimo (conteo por gravedad, sin user_id)
-- A4: sin faltas no guarda registro
-- A5: mismo email de nuevo → acumula en el mismo registro
-- A6: con faltas pero sin huella (sin email) → borra sin registro
-- A7: usuario inexistente → error (y la transacción no deja nada)
-- A8: clientes (anon, authenticated) no pueden ejecutar ni leer
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/006_account_deletion_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

SET LOCAL session_replication_role = replica; -- datos de prueba sin triggers
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-medellin','co-antioquia','CO','Medellín',6.25,-75.56);

-- U1 con faltas · U2 sin faltas · U3 con faltas, sin email · OT otro · MO moderador
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('a1000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u1@t.co'),
 ('a1000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u2@t.co'),
 ('a1000000-0000-4000-8000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated',NULL),
 ('a1000000-0000-4000-8000-0000000000ff','00000000-0000-0000-0000-000000000000','authenticated','authenticated','otro@t.co'),
 ('a1000000-0000-4000-8000-0000000000dd','00000000-0000-0000-0000-000000000000','authenticated','authenticated','mod@t.co');

INSERT INTO profiles (id, username) VALUES
 ('a1000000-0000-4000-8000-000000000001','u1_test'),
 ('a1000000-0000-4000-8000-0000000000ff','otro_test');

-- U1: publicado con imagen, rechazado (critical), rechazado (medium), en revisión con imagen en cuarentena
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility, storage_path, thumbnail_storage_path) VALUES
 ('b1000000-0000-4000-8000-000000000001','CO','co-antioquia','t-medellin','Con foto','x','profile','a1000000-0000-4000-8000-000000000001','published','approved','public',
  'gossips/full/b1_1.jpg','gossips/thumb/b1_1.jpg'),
 ('b1000000-0000-4000-8000-000000000002','CO','co-antioquia','t-medellin','Rechazado 1','x','profile','a1000000-0000-4000-8000-000000000001','hidden','rejected','public',NULL,NULL),
 ('b1000000-0000-4000-8000-000000000003','CO','co-antioquia','t-medellin','Rechazado 2','x','anonymous','a1000000-0000-4000-8000-000000000001','hidden','rejected','public',NULL,NULL),
 ('b1000000-0000-4000-8000-000000000004','CO','co-antioquia','t-medellin','En revision','x','anonymous','a1000000-0000-4000-8000-000000000001','draft','pending','public',NULL,NULL),
 ('b1000000-0000-4000-8000-000000000005','CO','co-antioquia','t-medellin','De U3','x','profile','a1000000-0000-4000-8000-000000000003','hidden','rejected','public',NULL,NULL),
 ('b1000000-0000-4000-8000-0000000000f1','CO','co-antioquia','t-medellin','De otro','x','profile','a1000000-0000-4000-8000-0000000000ff','published','approved','public',NULL,NULL);

INSERT INTO moderation_queue (gossip_id, content_author_id, source, status, decided_by, decided_at, decision_severity, decision_reason, image_quarantine_path) VALUES
 ('b1000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000001','reports','rejected','a1000000-0000-4000-8000-0000000000dd', now() - interval '2 days','critical','threat',NULL),
 ('b1000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000001','ai_review','rejected','a1000000-0000-4000-8000-0000000000dd', now() - interval '1 day','medium','insult',NULL),
 ('b1000000-0000-4000-8000-000000000004','a1000000-0000-4000-8000-000000000001','ai_review','pending',NULL,NULL,NULL,NULL,'quarantine/a1000000-0000-4000-8000-000000000001/k_1.jpg'),
 ('b1000000-0000-4000-8000-000000000005','a1000000-0000-4000-8000-000000000003','reports','rejected','a1000000-0000-4000-8000-0000000000dd', now(),'low','spam',NULL);

-- U1 reportó el chisme de otro; el otro reportó uno de U1
INSERT INTO content_reports (gossip_id, reported_by, reason) VALUES
 ('b1000000-0000-4000-8000-0000000000f1','a1000000-0000-4000-8000-000000000001','spam'),
 ('b1000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-0000000000ff','spam');

INSERT INTO rate_limits (user_id, action_type) VALUES
 ('a1000000-0000-4000-8000-000000000001','create_gossip');
SET LOCAL session_replication_role = origin;

-- La Edge Function llama como service_role (SET LOCAL ROLE en cada bloque);
-- se verifica como postgres (service_role no lee auth.users)
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);

-- ---------- A1: media a borrar ----------
DO $$
DECLARE m JSONB;
BEGIN
  SET LOCAL ROLE service_role;
  m := get_account_deletion_media('a1000000-0000-4000-8000-000000000001');
  IF jsonb_array_length(m->'image_paths') <> 2
     OR NOT (m->'image_paths') ? 'gossips/full/b1_1.jpg'
     OR NOT (m->'image_paths') ? 'gossips/thumb/b1_1.jpg'
     OR m->'audio_paths' <> '[]'::jsonb THEN
    RAISE EXCEPTION 'A1 FALLÓ: image_paths = %', m->'image_paths';
  END IF;
  IF m->'image_quarantine_paths' <> '["quarantine/a1000000-0000-4000-8000-000000000001/k_1.jpg"]'::jsonb
     OR m->'audio_quarantine_paths' <> '[]'::jsonb THEN
    RAISE EXCEPTION 'A1 FALLÓ: cuarentena = %', m;
  END IF;
  m := get_account_deletion_media('a1000000-0000-4000-8000-000000000002');
  RESET ROLE;
  IF m <> '{"image_paths": [], "audio_paths": [], "image_quarantine_paths": [], "audio_quarantine_paths": []}'::jsonb THEN
    RAISE EXCEPTION 'A1 FALLÓ: usuario sin media = %', m;
  END IF;
  RAISE NOTICE '✅ A1 media a borrar';
END $$;

-- ---------- A2 + A3: borrar U1 (con faltas) ----------
DO $$
DECLARE
  recorded BOOLEAN;
  r account_deletion_records%ROWTYPE;
BEGIN
  SET LOCAL ROLE service_role;
  recorded := delete_user_account('a1000000-0000-4000-8000-000000000001', repeat('a', 64));
  RESET ROLE;
  IF recorded IS NOT TRUE THEN RAISE EXCEPTION 'A3 FALLÓ: no informó el registro'; END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE id = 'a1000000-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION 'A2 FALLÓ: el usuario sigue en auth.users';
  END IF;
  IF EXISTS (SELECT 1 FROM gossips WHERE created_by = 'a1000000-0000-4000-8000-000000000001')
     OR EXISTS (SELECT 1 FROM profiles WHERE id = 'a1000000-0000-4000-8000-000000000001')
     OR EXISTS (SELECT 1 FROM moderation_queue WHERE content_author_id = 'a1000000-0000-4000-8000-000000000001')
     OR EXISTS (SELECT 1 FROM content_reports WHERE reported_by = 'a1000000-0000-4000-8000-000000000001')
     OR EXISTS (SELECT 1 FROM content_reports WHERE gossip_id = 'b1000000-0000-4000-8000-000000000001')
     OR EXISTS (SELECT 1 FROM rate_limits WHERE user_id = 'a1000000-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION 'A2 FALLÓ: quedaron datos del usuario';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM gossips WHERE id = 'b1000000-0000-4000-8000-0000000000f1')
     OR NOT EXISTS (SELECT 1 FROM profiles WHERE id = 'a1000000-0000-4000-8000-0000000000ff')
     OR NOT EXISTS (SELECT 1 FROM moderation_queue WHERE content_author_id = 'a1000000-0000-4000-8000-000000000003') THEN
    RAISE EXCEPTION 'A2 FALLÓ: se borraron datos de otros usuarios';
  END IF;

  SELECT * INTO r FROM account_deletion_records WHERE email_hash = repeat('a', 64);
  IF r.id IS NULL OR r.rejections_critical <> 1 OR r.rejections_medium <> 1
     OR r.rejections_low <> 0 OR r.rejections_high <> 0 OR r.deletion_count <> 1
     OR r.last_rejection_at IS NULL THEN
    RAISE EXCEPTION 'A3 FALLÓ: registro = %', row_to_json(r);
  END IF;
  RAISE NOTICE '✅ A2 cuenta y datos borrados; datos de otros intactos';
  RAISE NOTICE '✅ A3 registro anónimo con faltas por gravedad';
END $$;

-- ---------- A4: sin faltas no hay registro ----------
DO $$
DECLARE recorded BOOLEAN;
BEGIN
  SET LOCAL ROLE service_role;
  recorded := delete_user_account('a1000000-0000-4000-8000-000000000002', repeat('b', 64));
  RESET ROLE;
  IF recorded THEN
    RAISE EXCEPTION 'A4 FALLÓ: informó registro sin faltas';
  END IF;
  IF EXISTS (SELECT 1 FROM account_deletion_records WHERE email_hash = repeat('b', 64))
     OR EXISTS (SELECT 1 FROM auth.users WHERE id = 'a1000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'A4 FALLÓ';
  END IF;
  RAISE NOTICE '✅ A4 sin faltas no se guarda nada';
END $$;

-- ---------- A5: mismo email otra vez → acumula ----------
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('a1000000-0000-4000-8000-000000000011','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u1@t.co');
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility) VALUES
 ('b1000000-0000-4000-8000-000000000011','CO','co-antioquia','t-medellin','Reincide','x','profile','a1000000-0000-4000-8000-000000000011','hidden','rejected','public');
INSERT INTO moderation_queue (gossip_id, content_author_id, source, status, decided_by, decided_at, decision_severity, decision_reason) VALUES
 ('b1000000-0000-4000-8000-000000000011','a1000000-0000-4000-8000-000000000011','reports','rejected','a1000000-0000-4000-8000-0000000000dd', now(),'high','harassment');
SET LOCAL session_replication_role = origin;

DO $$
DECLARE r account_deletion_records%ROWTYPE;
BEGIN
  SET LOCAL ROLE service_role;
  PERFORM delete_user_account('a1000000-0000-4000-8000-000000000011', repeat('a', 64));
  RESET ROLE;
  SELECT * INTO r FROM account_deletion_records WHERE email_hash = repeat('a', 64);
  IF r.rejections_critical <> 1 OR r.rejections_medium <> 1 OR r.rejections_high <> 1
     OR r.deletion_count <> 2 OR (SELECT count(*) FROM account_deletion_records) <> 1 THEN
    RAISE EXCEPTION 'A5 FALLÓ: registro = %', row_to_json(r);
  END IF;
  RAISE NOTICE '✅ A5 reincidencia acumula en el mismo registro';
END $$;

-- ---------- A6: con faltas pero sin huella ----------
DO $$
DECLARE recorded BOOLEAN;
BEGIN
  SET LOCAL ROLE service_role;
  recorded := delete_user_account('a1000000-0000-4000-8000-000000000003', NULL);
  RESET ROLE;
  IF recorded THEN
    RAISE EXCEPTION 'A6 FALLÓ: informó registro sin huella';
  END IF;
  IF EXISTS (SELECT 1 FROM auth.users WHERE id = 'a1000000-0000-4000-8000-000000000003')
     OR (SELECT count(*) FROM account_deletion_records) <> 1 THEN
    RAISE EXCEPTION 'A6 FALLÓ';
  END IF;
  RAISE NOTICE '✅ A6 sin email se borra sin registro';
END $$;

-- ---------- A7: usuario inexistente ----------
DO $$
DECLARE failed BOOLEAN := FALSE;
BEGIN
  SET LOCAL ROLE service_role;
  BEGIN
    PERFORM delete_user_account(gen_random_uuid(), repeat('c', 64));
  EXCEPTION WHEN OTHERS THEN failed := TRUE;
  END;
  RESET ROLE;
  IF NOT failed OR EXISTS (SELECT 1 FROM account_deletion_records WHERE email_hash = repeat('c', 64)) THEN
    RAISE EXCEPTION 'A7 FALLÓ';
  END IF;
  RAISE NOTICE '✅ A7 usuario inexistente → error sin efectos';
END $$;

-- ---------- A8: clientes sin acceso ----------
DO $$
DECLARE
  r TEXT;
  denied INTEGER;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    EXECUTE format('SET LOCAL ROLE %I', r);
    denied := 0;
    BEGIN PERFORM 1 FROM account_deletion_records; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
    BEGIN PERFORM get_account_deletion_media('a1000000-0000-4000-8000-0000000000ff'); EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
    BEGIN PERFORM delete_user_account('a1000000-0000-4000-8000-0000000000ff', NULL); EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
    RESET ROLE;
    IF denied <> 3 THEN RAISE EXCEPTION 'A8 FALLÓ: % tiene acceso (% de 3 denegados)', r, denied; END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = 'a1000000-0000-4000-8000-0000000000ff') THEN
    RAISE EXCEPTION 'A8 FALLÓ: un cliente borró una cuenta';
  END IF;
  RAISE NOTICE '✅ A8 anon/authenticated sin acceso';
END $$;

DO $$ BEGIN RAISE NOTICE '✅ TODOS LOS TESTS DE ELIMINACIÓN DE CUENTA PASARON'; END $$;
ROLLBACK;
