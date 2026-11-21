-- =====================================================
-- Test: sanciones, apelaciones y reincidentes (015_sanctions.sql)
-- =====================================================
-- S1: sin faltas → ok
-- S2: una leve → advertencia, sin bloqueo
-- S3: leve + media (3 pts) → restricción de 24 h
-- S4: restricción ya cumplida → ok (los puntos siguen vigentes)
-- S5: alta + media (6 pts) → restricción de 7 días
-- S6: crítica → suspensión indefinida
-- S7: puntos vencidos no cuentan; la suspensión por puntos no vence
-- S8: umbrales editables en moderation_settings
-- P1: apelar: dueño, mensaje, plazo, duplicado
-- P2: aceptar → falta anulada, texto republicado, sanción recalculada
-- P3: rechazar → la falta sigue; no se decide dos veces
-- P4: appeal_different_moderator = 1 → el mismo moderador no decide
-- P5: get_account_status: estado + rechazos + apelación, sin notas internas
-- H1: claim_inherited_strikes sin registro → revisado, sin faltas, idempotente
-- H2: heredadas recientes → restricción; con crítica → suspensión
-- D1: delete_user_account no cuenta faltas anuladas
-- G1: clientes (anon, authenticated) no ejecutan ni leen nada de esto
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/007_sanctions_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

SET LOCAL session_replication_role = replica; -- datos de prueba sin triggers
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-medellin','co-antioquia','CO','Medellín',6.25,-75.56);

-- U1..U7 usuarios con distintos historiales · MO / M2 moderadores
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('c7000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u1@t.co'),
 ('c7000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u2@t.co'),
 ('c7000000-0000-4000-8000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u3@t.co'),
 ('c7000000-0000-4000-8000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u4@t.co'),
 ('c7000000-0000-4000-8000-000000000005','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u5@t.co'),
 ('c7000000-0000-4000-8000-000000000006','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u6@t.co'),
 ('c7000000-0000-4000-8000-000000000007','00000000-0000-0000-0000-000000000000','authenticated','authenticated','u7@t.co'),
 ('c7000000-0000-4000-8000-0000000000dd','00000000-0000-0000-0000-000000000000','authenticated','authenticated','mod@t.co'),
 ('c7000000-0000-4000-8000-0000000000de','00000000-0000-0000-0000-000000000000','authenticated','authenticated','mod2@t.co');

INSERT INTO profiles (id, username) VALUES
 ('c7000000-0000-4000-8000-000000000003','u3_test');

-- Un chisme oculto por cada rechazo: d7..0XY (X = usuario, Y = n.º)
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility)
SELECT g.id::uuid, 'CO','co-antioquia','t-medellin', 'Rechazado ' || g.n, 'texto ' || g.n, 'profile', g.author::uuid, 'hidden','rejected','public'
FROM (VALUES
  ('d7000000-0000-4000-8000-000000000021','c7000000-0000-4000-8000-000000000002','21'),
  ('d7000000-0000-4000-8000-000000000031','c7000000-0000-4000-8000-000000000003','31'),
  ('d7000000-0000-4000-8000-000000000032','c7000000-0000-4000-8000-000000000003','32'),
  ('d7000000-0000-4000-8000-000000000041','c7000000-0000-4000-8000-000000000004','41'),
  ('d7000000-0000-4000-8000-000000000042','c7000000-0000-4000-8000-000000000004','42'),
  ('d7000000-0000-4000-8000-000000000051','c7000000-0000-4000-8000-000000000005','51'),
  ('d7000000-0000-4000-8000-000000000052','c7000000-0000-4000-8000-000000000005','52'),
  ('d7000000-0000-4000-8000-000000000061','c7000000-0000-4000-8000-000000000006','61'),
  ('d7000000-0000-4000-8000-000000000071','c7000000-0000-4000-8000-000000000007','71'),
  ('d7000000-0000-4000-8000-000000000072','c7000000-0000-4000-8000-000000000007','72'),
  ('d7000000-0000-4000-8000-000000000073','c7000000-0000-4000-8000-000000000007','73')
) AS g(id, author, n);

-- U2: leve hoy · U3: leve + media hace 1 h (3 pts) · U4: leve + media hace 3 días
-- U5: alta + media hace 1 día (6 pts) · U6: crítica hace 200 días
-- U7: leve hace 100 días (vencida) + alta x2 hace 120/100 días... ver S7
INSERT INTO moderation_queue (id, gossip_id, content_author_id, source, status, decided_by, decided_at, decision_severity, decision_reason, decision_note) VALUES
 ('e7000000-0000-4000-8000-000000000021','d7000000-0000-4000-8000-000000000021','c7000000-0000-4000-8000-000000000002','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now(),'low','spam','nota interna U2'),
 ('e7000000-0000-4000-8000-000000000031','d7000000-0000-4000-8000-000000000031','c7000000-0000-4000-8000-000000000003','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '2 hours','low','spam',NULL),
 ('e7000000-0000-4000-8000-000000000032','d7000000-0000-4000-8000-000000000032','c7000000-0000-4000-8000-000000000003','ai_review','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '1 hour','medium','insult','nota interna U3'),
 ('e7000000-0000-4000-8000-000000000041','d7000000-0000-4000-8000-000000000041','c7000000-0000-4000-8000-000000000004','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '3 days 1 hour','low','spam',NULL),
 ('e7000000-0000-4000-8000-000000000042','d7000000-0000-4000-8000-000000000042','c7000000-0000-4000-8000-000000000004','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '3 days','medium','insult',NULL),
 ('e7000000-0000-4000-8000-000000000051','d7000000-0000-4000-8000-000000000051','c7000000-0000-4000-8000-000000000005','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '1 day 1 hour','high','harassment',NULL),
 ('e7000000-0000-4000-8000-000000000052','d7000000-0000-4000-8000-000000000052','c7000000-0000-4000-8000-000000000005','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '1 day','medium','insult',NULL),
 ('e7000000-0000-4000-8000-000000000061','d7000000-0000-4000-8000-000000000061','c7000000-0000-4000-8000-000000000006','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '200 days','critical','threat',NULL),
 -- U7: alta + alta + media en 10 días (10 pts → suspensión) hace ~100 días: vencidas pero la suspensión sigue
 ('e7000000-0000-4000-8000-000000000071','d7000000-0000-4000-8000-000000000071','c7000000-0000-4000-8000-000000000007','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '110 days','high','harassment',NULL),
 ('e7000000-0000-4000-8000-000000000072','d7000000-0000-4000-8000-000000000072','c7000000-0000-4000-8000-000000000007','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '105 days','high','harassment',NULL),
 ('e7000000-0000-4000-8000-000000000073','d7000000-0000-4000-8000-000000000073','c7000000-0000-4000-8000-000000000007','reports','rejected','c7000000-0000-4000-8000-0000000000dd', now() - interval '100 days','medium','insult',NULL);
SET LOCAL session_replication_role = origin;

SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);

-- Helper de lectura (como service_role, igual que las Edge Functions)
CREATE FUNCTION pg_temp.st(u TEXT) RETURNS JSONB LANGUAGE sql AS
$$ SELECT get_user_sanction_status(u::uuid) $$;
GRANT EXECUTE ON FUNCTION pg_temp.st(TEXT) TO service_role;

-- ---------- S1–S6 ----------
DO $$
DECLARE s JSONB;
BEGIN
  SET LOCAL ROLE service_role;

  s := pg_temp.st('c7000000-0000-4000-8000-000000000001');
  IF s->>'state' <> 'ok' OR (s->>'active_points')::int <> 0 OR (s->>'strike_count')::int <> 0 THEN
    RAISE EXCEPTION 'S1 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S1 sin faltas → ok';

  s := pg_temp.st('c7000000-0000-4000-8000-000000000002');
  IF s->>'state' <> 'ok' OR (s->>'active_points')::int <> 1
     OR (SELECT sanction FROM get_user_strikes('c7000000-0000-4000-8000-000000000002')) <> 'warning' THEN
    RAISE EXCEPTION 'S2 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S2 una leve → advertencia sin bloqueo';

  s := pg_temp.st('c7000000-0000-4000-8000-000000000003');
  IF s->>'state' <> 'restricted' OR (s->>'active_points')::int <> 3
     OR abs(extract(epoch FROM (s->>'restricted_until')::timestamptz - (now() + interval '23 hours'))) > 5 THEN
    RAISE EXCEPTION 'S3 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S3 3 puntos → restricción 24 h';

  s := pg_temp.st('c7000000-0000-4000-8000-000000000004');
  IF s->>'state' <> 'ok' OR (s->>'active_points')::int <> 3 OR s->'restricted_until' <> 'null'::jsonb THEN
    RAISE EXCEPTION 'S4 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S4 restricción cumplida → ok (puntos vigentes)';

  s := pg_temp.st('c7000000-0000-4000-8000-000000000005');
  IF s->>'state' <> 'restricted' OR (s->>'active_points')::int <> 6
     OR abs(extract(epoch FROM (s->>'restricted_until')::timestamptz - (now() + interval '6 days'))) > 5 THEN
    RAISE EXCEPTION 'S5 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S5 6 puntos → restricción 7 días';

  s := pg_temp.st('c7000000-0000-4000-8000-000000000006');
  IF s->>'state' <> 'suspended' OR s->'restricted_until' <> 'null'::jsonb
     OR (s->>'active_points')::int <> 0 THEN
    RAISE EXCEPTION 'S6 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S6 crítica (aun vencida) → suspensión indefinida';
  RESET ROLE;
END $$;

-- ---------- S7: vencimiento ----------
DO $$
DECLARE s JSONB; n INTEGER;
BEGIN
  SET LOCAL ROLE service_role;
  s := pg_temp.st('c7000000-0000-4000-8000-000000000007');
  SELECT count(*) INTO n FROM get_user_strikes('c7000000-0000-4000-8000-000000000007') WHERE sanction = 'suspension';
  IF s->>'state' <> 'suspended' OR (s->>'active_points')::int <> 0 OR n <> 1 THEN
    RAISE EXCEPTION 'S7 FALLÓ: % (suspensiones %)', s, n;
  END IF;
  -- Los puntos de la primera alta (hace 110 días) seguían vigentes a los 100
  IF (SELECT points_at_time FROM get_user_strikes('c7000000-0000-4000-8000-000000000007')
      WHERE queue_id = 'e7000000-0000-4000-8000-000000000073') <> 10 THEN
    RAISE EXCEPTION 'S7 FALLÓ: points_at_time';
  END IF;
  RAISE NOTICE '✅ S7 puntos vencidos no cuentan; la suspensión no vence';
  RESET ROLE;
END $$;

-- ---------- S8: umbrales editables ----------
DO $$
DECLARE s JSONB;
BEGIN
  UPDATE moderation_settings SET value = 1 WHERE key = 'restriction_short_points';
  SET LOCAL ROLE service_role;
  s := pg_temp.st('c7000000-0000-4000-8000-000000000002');
  RESET ROLE;
  UPDATE moderation_settings SET value = 3 WHERE key = 'restriction_short_points';
  IF s->>'state' <> 'restricted' OR (s->'thresholds'->>'restriction_short')::int <> 1 THEN
    RAISE EXCEPTION 'S8 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ S8 umbral editado aplica al historial';
END $$;

-- ---------- P1: crear apelación ----------
DO $$
DECLARE code TEXT; a JSONB;
BEGIN
  SET LOCAL ROLE service_role;

  -- Ajeno: U2 apela un rechazo de U3
  BEGIN
    PERFORM submit_appeal('c7000000-0000-4000-8000-000000000002', 'e7000000-0000-4000-8000-000000000032', 'No era un insulto, era un chiste');
    RAISE EXCEPTION 'P1 FALLÓ: apeló lo ajeno';
  EXCEPTION WHEN no_data_found THEN NULL;
  END;

  -- Mensaje corto
  BEGIN
    PERFORM submit_appeal('c7000000-0000-4000-8000-000000000003', 'e7000000-0000-4000-8000-000000000032', '  corto  ');
    RAISE EXCEPTION 'P1 FALLÓ: mensaje corto';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  -- Fuera de plazo (U4: hace 3 días · plazo 14 → ok; U6: hace 200 días → cerrado)
  BEGIN
    PERFORM submit_appeal('c7000000-0000-4000-8000-000000000006', 'e7000000-0000-4000-8000-000000000061', 'Fue un malentendido, pido revisión');
    RAISE EXCEPTION 'P1 FALLÓ: fuera de plazo';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;

  a := submit_appeal('c7000000-0000-4000-8000-000000000003', 'e7000000-0000-4000-8000-000000000032', '  No era un insulto, era un chiste  ');
  IF a->>'status' <> 'pending' OR a->>'message' <> 'No era un insulto, era un chiste' THEN
    RAISE EXCEPTION 'P1 FALLÓ: %', a;
  END IF;

  -- Duplicado
  BEGIN
    PERFORM submit_appeal('c7000000-0000-4000-8000-000000000003', 'e7000000-0000-4000-8000-000000000032', 'Otra vez la misma apelación');
    RAISE EXCEPTION 'P1 FALLÓ: duplicado';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  -- U5 apela su media (para P3)
  PERFORM submit_appeal('c7000000-0000-4000-8000-000000000005', 'e7000000-0000-4000-8000-000000000052', 'No insulté a nadie, revisen por favor');
  RAISE NOTICE '✅ P1 apelar: dueño, mensaje, plazo, duplicado';
  RESET ROLE;
END $$;

-- ---------- P2: aceptar ----------
DO $$
DECLARE a JSONB; s JSONB; ap_id UUID;
BEGIN
  SELECT id INTO ap_id FROM moderation_appeals WHERE queue_id = 'e7000000-0000-4000-8000-000000000032';
  SET LOCAL ROLE service_role;
  a := decide_appeal(ap_id, 'accept', 'c7000000-0000-4000-8000-0000000000dd', '  tenía razón  ');
  s := pg_temp.st('c7000000-0000-4000-8000-000000000003');
  RESET ROLE;

  IF a->>'status' <> 'accepted' OR a->>'decision_note' <> 'tenía razón' OR a->>'decided_at' IS NULL THEN
    RAISE EXCEPTION 'P2 FALLÓ: apelación %', a;
  END IF;
  IF (SELECT overturned_at IS NULL OR overturned_by IS DISTINCT FROM 'c7000000-0000-4000-8000-0000000000dd'
      FROM moderation_queue WHERE id = 'e7000000-0000-4000-8000-000000000032') THEN
    RAISE EXCEPTION 'P2 FALLÓ: falta no anulada';
  END IF;
  IF (SELECT status <> 'published' OR moderation_status <> 'approved'
      FROM gossips WHERE id = 'd7000000-0000-4000-8000-000000000032') THEN
    RAISE EXCEPTION 'P2 FALLÓ: chisme no republicado';
  END IF;
  IF s->>'state' <> 'ok' OR (s->>'active_points')::int <> 1 THEN
    RAISE EXCEPTION 'P2 FALLÓ: estado %', s;
  END IF;
  RAISE NOTICE '✅ P2 aceptar → falta anulada, texto republicado, restricción levantada';
END $$;

-- ---------- P3: rechazar ----------
DO $$
DECLARE a JSONB; s JSONB; ap_id UUID;
BEGIN
  SELECT id INTO ap_id FROM moderation_appeals WHERE queue_id = 'e7000000-0000-4000-8000-000000000052';
  SET LOCAL ROLE service_role;
  a := decide_appeal(ap_id, 'reject', 'c7000000-0000-4000-8000-0000000000dd', NULL);
  s := pg_temp.st('c7000000-0000-4000-8000-000000000005');

  BEGIN
    PERFORM decide_appeal(ap_id, 'accept', 'c7000000-0000-4000-8000-0000000000dd', NULL);
    RAISE EXCEPTION 'P3 FALLÓ: se decidió dos veces';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
  BEGIN
    PERFORM decide_appeal(gen_random_uuid(), 'accept', 'c7000000-0000-4000-8000-0000000000dd', NULL);
    RAISE EXCEPTION 'P3 FALLÓ: inexistente';
  EXCEPTION WHEN no_data_found THEN NULL;
  END;
  BEGIN
    PERFORM decide_appeal(ap_id, 'maybe', 'c7000000-0000-4000-8000-0000000000dd', NULL);
    RAISE EXCEPTION 'P3 FALLÓ: decisión inválida';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  RESET ROLE;

  IF a->>'status' <> 'rejected' OR s->>'state' <> 'restricted'
     OR (SELECT status FROM gossips WHERE id = 'd7000000-0000-4000-8000-000000000052') <> 'hidden' THEN
    RAISE EXCEPTION 'P3 FALLÓ: % / %', a, s;
  END IF;
  RAISE NOTICE '✅ P3 rechazar → la falta sigue; no se decide dos veces';
END $$;

-- ---------- P4: moderador distinto ----------
DO $$
DECLARE ap_id UUID; a JSONB;
BEGIN
  UPDATE moderation_settings SET value = 1 WHERE key = 'appeal_different_moderator';
  SET LOCAL ROLE service_role;
  a := submit_appeal('c7000000-0000-4000-8000-000000000004', 'e7000000-0000-4000-8000-000000000042', 'Pido revisión de este rechazo');
  ap_id := (a->>'id')::uuid;
  BEGIN
    PERFORM decide_appeal(ap_id, 'accept', 'c7000000-0000-4000-8000-0000000000dd', NULL);
    RAISE EXCEPTION 'P4 FALLÓ: decidió el mismo moderador';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  a := decide_appeal(ap_id, 'accept', 'c7000000-0000-4000-8000-0000000000de', NULL);
  RESET ROLE;
  UPDATE moderation_settings SET value = 0 WHERE key = 'appeal_different_moderator';
  IF a->>'status' <> 'accepted' THEN
    RAISE EXCEPTION 'P4 FALLÓ: %', a;
  END IF;
  RAISE NOTICE '✅ P4 con appeal_different_moderator = 1 decide otro moderador';
END $$;

-- ---------- P5: estado de la cuenta ----------
DO $$
DECLARE s JSONB; r JSONB;
BEGIN
  SET LOCAL ROLE service_role;
  s := get_account_status('c7000000-0000-4000-8000-000000000003');
  RESET ROLE;

  IF jsonb_array_length(s->'rejections') <> 2 OR s->>'state' <> 'ok'
     OR (s->>'appeal_window_days')::int <> 14 OR s->'inherited' <> 'null'::jsonb THEN
    RAISE EXCEPTION 'P5 FALLÓ: %', s;
  END IF;
  -- Más reciente primero: la media anulada con su apelación aceptada
  r := s->'rejections'->0;
  IF r->>'queue_id' <> 'e7000000-0000-4000-8000-000000000032'
     OR NOT (r->>'overturned')::boolean OR (r->>'can_appeal')::boolean
     OR r->'appeal'->>'status' <> 'accepted' OR r->>'subject' <> 'Rechazado 32' THEN
    RAISE EXCEPTION 'P5 FALLÓ: rechazo anulado %', r;
  END IF;
  r := s->'rejections'->1;
  IF NOT (r->>'can_appeal')::boolean OR r->'appeal' <> 'null'::jsonb
     OR r->>'sanction' <> 'warning' OR (r->>'points')::int <> 1 THEN
    RAISE EXCEPTION 'P5 FALLÓ: rechazo vigente %', r;
  END IF;
  IF s::text LIKE '%nota interna%' OR s::text LIKE '%decided_by%' THEN
    RAISE EXCEPTION 'P5 FALLÓ: expone notas internas o moderador';
  END IF;
  RAISE NOTICE '✅ P5 estado de la cuenta sin datos internos';
END $$;

-- ---------- H1 / H2: reincidentes ----------
DO $$
DECLARE s JSONB; inherited BOOLEAN;
BEGIN
  INSERT INTO account_deletion_records (email_hash, rejections_medium, rejections_high, last_rejection_at)
    VALUES (repeat('a', 64), 1, 1, now() - interval '1 day');
  INSERT INTO account_deletion_records (email_hash, rejections_critical, last_rejection_at)
    VALUES (repeat('b', 64), 1, now() - interval '300 days');

  SET LOCAL ROLE service_role;
  -- H1: sin registro → revisado sin faltas; idempotente; sin huella no marca
  IF claim_inherited_strikes('c7000000-0000-4000-8000-000000000001', repeat('f', 64))
     OR claim_inherited_strikes('c7000000-0000-4000-8000-000000000002', NULL) THEN
    RAISE EXCEPTION 'H1 FALLÓ: heredó sin registro';
  END IF;
  -- Aunque luego aparezca un registro con esa huella, ya se revisó
  IF claim_inherited_strikes('c7000000-0000-4000-8000-000000000001', repeat('a', 64)) THEN
    RAISE EXCEPTION 'H1 FALLÓ: no es idempotente';
  END IF;
  s := pg_temp.st('c7000000-0000-4000-8000-000000000001');
  RESET ROLE;
  IF s->>'state' <> 'ok'
     OR NOT EXISTS (SELECT 1 FROM inherited_strikes WHERE user_id = 'c7000000-0000-4000-8000-000000000001' AND points = 0)
     OR EXISTS (SELECT 1 FROM inherited_strikes WHERE user_id = 'c7000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'H1 FALLÓ: %', s;
  END IF;
  RAISE NOTICE '✅ H1 sin registro → revisado sin faltas, idempotente';

  -- H2: media + alta hace 1 día = 6 pts → restricción 7 días
  DELETE FROM inherited_strikes WHERE user_id = 'c7000000-0000-4000-8000-000000000001';
  SET LOCAL ROLE service_role;
  inherited := claim_inherited_strikes('c7000000-0000-4000-8000-000000000001', repeat('a', 64));
  s := pg_temp.st('c7000000-0000-4000-8000-000000000001');
  IF NOT inherited OR s->>'state' <> 'restricted' OR (s->>'active_points')::int <> 6
     OR (get_account_status('c7000000-0000-4000-8000-000000000001')->'inherited'->>'points')::int <> 6 THEN
    RAISE EXCEPTION 'H2 FALLÓ: %', s;
  END IF;
  -- Crítica vieja → suspensión
  inherited := claim_inherited_strikes('c7000000-0000-4000-8000-000000000003', repeat('b', 64));
  s := pg_temp.st('c7000000-0000-4000-8000-000000000003');
  RESET ROLE;
  IF NOT inherited OR s->>'state' <> 'suspended' THEN
    RAISE EXCEPTION 'H2 FALLÓ: crítica %', s;
  END IF;
  RAISE NOTICE '✅ H2 heredadas → restricción; con crítica → suspensión';
END $$;

-- ---------- D1: eliminar cuenta no cuenta lo anulado ----------
DO $$
DECLARE r account_deletion_records%ROWTYPE;
BEGIN
  -- U4: leve vigente + media anulada (P4)
  SET LOCAL ROLE service_role;
  PERFORM delete_user_account('c7000000-0000-4000-8000-000000000004', repeat('d', 64));
  RESET ROLE;
  SELECT * INTO r FROM account_deletion_records WHERE email_hash = repeat('d', 64);
  IF r.rejections_low <> 1 OR r.rejections_medium <> 0
     OR EXISTS (SELECT 1 FROM moderation_appeals WHERE user_id = 'c7000000-0000-4000-8000-000000000004') THEN
    RAISE EXCEPTION 'D1 FALLÓ: %', row_to_json(r);
  END IF;
  RAISE NOTICE '✅ D1 eliminar cuenta no cuenta faltas anuladas (y borra sus apelaciones)';
END $$;

-- ---------- G1: sin acceso de clientes ----------
DO $$
DECLARE
  role_name TEXT;
  fn TEXT;
BEGIN
  FOREACH role_name IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    FOREACH fn IN ARRAY ARRAY[
      'moderation_setting(text,numeric)',
      'claim_inherited_strikes(uuid,text)',
      'get_user_strikes(uuid)',
      'get_user_sanction_status(uuid)',
      'submit_appeal(uuid,uuid,text)',
      'decide_appeal(uuid,text,uuid,text)',
      'get_account_status(uuid)'
    ] LOOP
      IF has_function_privilege(role_name, fn, 'EXECUTE') THEN
        RAISE EXCEPTION 'G1 FALLÓ: % puede ejecutar %', role_name, fn;
      END IF;
    END LOOP;
    FOREACH fn IN ARRAY ARRAY['inherited_strikes', 'moderation_appeals', 'moderation_appeal_items'] LOOP
      IF has_table_privilege(role_name, fn, 'SELECT')
         OR has_table_privilege(role_name, fn, 'INSERT')
         OR has_table_privilege(role_name, fn, 'UPDATE') THEN
        RAISE EXCEPTION 'G1 FALLÓ: % accede a %', role_name, fn;
      END IF;
    END LOOP;
  END LOOP;
  RAISE NOTICE '✅ G1 clientes sin acceso';
END $$;

ROLLBACK;
