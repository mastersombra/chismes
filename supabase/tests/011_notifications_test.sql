-- =====================================================
-- Test: notificaciones in-app (019_notifications.sql)
-- =====================================================
-- N1: seguir cuenta pública → new_follower al seguido (no al que sigue)
-- N2: anti-spam: seguir/dejar en bucle no repite; pasado un día vuelve a
--     subir como no leída
-- N3: cuenta privada: solicitud → follow_request; aceptar borra el aviso,
--     avisa follow_accepted al que pidió y NO new_follower al que aceptó
-- N4: cancelar o rechazar la solicitud borra el aviso
-- N5: privada → pública: las pendientes avisan follow_accepted
-- N6: follow_notifications / notifications_enabled en FALSE → sin sociales
-- N7: bloquear borra los avisos entre ambos (los dos sentidos)
-- N8: decisión humana: rechazo con motivo (aunque apague las notificaciones),
--     aprobado de cola IA, aprobado tras ocultar por reportes; reportes sin
--     ocultar → sin aviso
-- N9: apelación aceptada / rechazada
-- N10: get_notifications (forma, autor, chisme, paginación, borrados y
--      bloqueados fuera), contador, marcar leídas (ids / todas / ajenas no)
-- N11: sin acceso directo a la tabla ni a los helpers; anon sin API
-- N12: borrar la cuenta borra sus avisos (como destinatario y como autor)
-- N13: retención de 90 días
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/011_notifications_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

-- A=ana B=beto C=caro D=dani M1/M2=moderadores
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('b5000000-0000-4000-8000-00000000000a','00000000-0000-0000-0000-000000000000','authenticated','authenticated','n_ana@t.co'),
 ('b5000000-0000-4000-8000-00000000000b','00000000-0000-0000-0000-000000000000','authenticated','authenticated','n_beto@t.co'),
 ('b5000000-0000-4000-8000-00000000000c','00000000-0000-0000-0000-000000000000','authenticated','authenticated','n_caro@t.co'),
 ('b5000000-0000-4000-8000-00000000000d','00000000-0000-0000-0000-000000000000','authenticated','authenticated','n_dani@t.co'),
 ('b5000000-0000-4000-8000-0000000000e1','00000000-0000-0000-0000-000000000000','authenticated','authenticated','n_mod1@t.co'),
 ('b5000000-0000-4000-8000-0000000000e2','00000000-0000-0000-0000-000000000000','authenticated','authenticated','n_mod2@t.co');
UPDATE profiles SET username = 'n_ana', display_name = 'Ana' WHERE id = 'b5000000-0000-4000-8000-00000000000a';
UPDATE profiles SET username = 'n_beto', display_name = 'Beto', avatar_url = 'https://x/b.jpg' WHERE id = 'b5000000-0000-4000-8000-00000000000b';
UPDATE profiles SET username = 'n_caro', display_name = 'Caro' WHERE id = 'b5000000-0000-4000-8000-00000000000c';
UPDATE profiles SET username = 'n_dani', display_name = 'Dani' WHERE id = 'b5000000-0000-4000-8000-00000000000d';
UPDATE user_settings SET privacy_level = 'private' WHERE user_id = 'b5000000-0000-4000-8000-00000000000c';

-- Chismes de ana en revisión (sin triggers para fijar autor/estado)
SET LOCAL session_replication_role = replica;
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-notif','co-antioquia','CO','Notilandia',6.25,-75.56) ON CONFLICT DO NOTHING;
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility) VALUES
 ('b6000000-0000-4000-8000-000000000001','CO','co-antioquia','t-notif','zn cola ia','c','anonymous','b5000000-0000-4000-8000-00000000000a','draft','pending','public'),
 ('b6000000-0000-4000-8000-000000000002','CO','co-antioquia','t-notif','zn reportado visible','c','profile','b5000000-0000-4000-8000-00000000000a','published','approved','public'),
 ('b6000000-0000-4000-8000-000000000003','CO','co-antioquia','t-notif','zn reportado oculto','c','profile','b5000000-0000-4000-8000-00000000000a','hidden','flagged','public'),
 ('b6000000-0000-4000-8000-000000000004','CO','co-antioquia','t-notif','zn a rechazar 1','c','profile','b5000000-0000-4000-8000-00000000000a','draft','pending','public'),
 ('b6000000-0000-4000-8000-000000000005','CO','co-antioquia','t-notif','zn a rechazar 2','c','profile','b5000000-0000-4000-8000-00000000000a','draft','pending','public');
SET LOCAL session_replication_role = origin;

INSERT INTO moderation_queue (id, gossip_id, content_author_id, source, auto_hidden) VALUES
 ('b7000000-0000-4000-8000-000000000001','b6000000-0000-4000-8000-000000000001','b5000000-0000-4000-8000-00000000000a','ai_review', FALSE),
 ('b7000000-0000-4000-8000-000000000002','b6000000-0000-4000-8000-000000000002','b5000000-0000-4000-8000-00000000000a','reports', FALSE),
 ('b7000000-0000-4000-8000-000000000003','b6000000-0000-4000-8000-000000000003','b5000000-0000-4000-8000-00000000000a','reports', TRUE),
 ('b7000000-0000-4000-8000-000000000004','b6000000-0000-4000-8000-000000000004','b5000000-0000-4000-8000-00000000000a','ai_unavailable', FALSE),
 ('b7000000-0000-4000-8000-000000000005','b6000000-0000-4000-8000-000000000005','b5000000-0000-4000-8000-00000000000a','ai_review', FALSE);

CREATE FUNCTION pg_temp.as_user(u TEXT) RETURNS VOID LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
$$;
GRANT EXECUTE ON FUNCTION pg_temp.as_user(TEXT) TO authenticated;

-- Cuenta avisos (como postgres: lee la tabla directo)
CREATE FUNCTION pg_temp.n(u TEXT, t TEXT, actor TEXT DEFAULT NULL) RETURNS INT LANGUAGE sql AS $$
  SELECT COUNT(*)::INT FROM notifications
  WHERE user_id = u::uuid AND type = t AND (actor IS NULL OR actor_id = actor::uuid);
$$;

SET LOCAL ROLE authenticated;

-- N1
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000b');
SELECT follow_user('b5000000-0000-4000-8000-00000000000a');
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000a', 'new_follower', 'b5000000-0000-4000-8000-00000000000b') <> 1 THEN
    RAISE EXCEPTION 'N1: ana no recibió new_follower';
  END IF;
  IF EXISTS (SELECT 1 FROM notifications WHERE user_id = 'b5000000-0000-4000-8000-00000000000b') THEN
    RAISE EXCEPTION 'N1: el que sigue recibió un aviso';
  END IF;
  RAISE NOTICE 'N1 ok';
END $$;

-- N2
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000b');
SELECT unfollow_user('b5000000-0000-4000-8000-00000000000a');
SELECT follow_user('b5000000-0000-4000-8000-00000000000a');
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000a', 'new_follower') <> 1 THEN
    RAISE EXCEPTION 'N2: el bucle seguir/dejar repitió el aviso';
  END IF;
  UPDATE notifications SET created_at = NOW() - INTERVAL '2 days', read_at = NOW() - INTERVAL '2 days'
  WHERE user_id = 'b5000000-0000-4000-8000-00000000000a' AND type = 'new_follower';
END $$;
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000b');
SELECT unfollow_user('b5000000-0000-4000-8000-00000000000a');
SELECT follow_user('b5000000-0000-4000-8000-00000000000a');
RESET ROLE;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM notifications
    WHERE user_id = 'b5000000-0000-4000-8000-00000000000a' AND type = 'new_follower'
      AND read_at IS NULL AND created_at > NOW() - INTERVAL '1 minute') THEN
    RAISE EXCEPTION 'N2: pasado un día no volvió a subir como no leída';
  END IF;
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000a', 'new_follower') <> 1 THEN
    RAISE EXCEPTION 'N2: duplicó en vez de subir';
  END IF;
  RAISE NOTICE 'N2 ok';
END $$;

-- N3: ana pide seguir a caro (privada); caro acepta
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000a');
SELECT follow_user('b5000000-0000-4000-8000-00000000000c');
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'follow_request', 'b5000000-0000-4000-8000-00000000000a') <> 1 THEN
    RAISE EXCEPTION 'N3: caro no recibió follow_request';
  END IF;
END $$;
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000c');
SELECT respond_follow_request('b5000000-0000-4000-8000-00000000000a', TRUE);
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'follow_request') <> 0 THEN
    RAISE EXCEPTION 'N3: el aviso de solicitud siguió tras aceptarla';
  END IF;
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'new_follower') <> 0 THEN
    RAISE EXCEPTION 'N3: la que aceptó recibió new_follower';
  END IF;
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000a', 'follow_accepted', 'b5000000-0000-4000-8000-00000000000c') <> 1 THEN
    RAISE EXCEPTION 'N3: ana no recibió follow_accepted';
  END IF;
  RAISE NOTICE 'N3 ok';
END $$;

-- N4: dani pide y cancela; beto pide y caro rechaza
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000d');
SELECT follow_user('b5000000-0000-4000-8000-00000000000c');
SELECT unfollow_user('b5000000-0000-4000-8000-00000000000c');
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000b');
SELECT follow_user('b5000000-0000-4000-8000-00000000000c');
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000c');
SELECT respond_follow_request('b5000000-0000-4000-8000-00000000000b', FALSE);
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'follow_request') <> 0 THEN
    RAISE EXCEPTION 'N4: quedó un aviso de solicitud cancelada o rechazada';
  END IF;
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000b', 'follow_accepted') <> 0 THEN
    RAISE EXCEPTION 'N4: rechazar avisó follow_accepted';
  END IF;
  RAISE NOTICE 'N4 ok';
END $$;

-- N5: dani vuelve a pedir; caro pasa a pública
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000d');
SELECT follow_user('b5000000-0000-4000-8000-00000000000c');
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000c');
UPDATE user_settings SET privacy_level = 'public' WHERE user_id = 'b5000000-0000-4000-8000-00000000000c';
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000d', 'follow_accepted', 'b5000000-0000-4000-8000-00000000000c') <> 1 THEN
    RAISE EXCEPTION 'N5: pasar a pública no avisó follow_accepted';
  END IF;
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'follow_request') <> 0
     OR pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'new_follower') <> 0 THEN
    RAISE EXCEPTION 'N5: avisos de más para caro';
  END IF;
  RAISE NOTICE 'N5 ok';
END $$;

-- N6: ana apaga follow_notifications → dani la sigue sin aviso;
--     caro apaga notifications_enabled → dani... (ya la sigue) beto la sigue sin aviso
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000a');
UPDATE user_settings SET follow_notifications = FALSE WHERE user_id = 'b5000000-0000-4000-8000-00000000000a';
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000c');
UPDATE user_settings SET notifications_enabled = FALSE WHERE user_id = 'b5000000-0000-4000-8000-00000000000c';
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000d');
SELECT follow_user('b5000000-0000-4000-8000-00000000000a');
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000b');
SELECT follow_user('b5000000-0000-4000-8000-00000000000c');
RESET ROLE;
DO $$ BEGIN
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000a', 'new_follower', 'b5000000-0000-4000-8000-00000000000d') <> 0 THEN
    RAISE EXCEPTION 'N6: follow_notifications FALSE no se respetó';
  END IF;
  IF pg_temp.n('b5000000-0000-4000-8000-00000000000c', 'new_follower') <> 0 THEN
    RAISE EXCEPTION 'N6: notifications_enabled FALSE no se respetó';
  END IF;
  RAISE NOTICE 'N6 ok';
END $$;

-- N7: ana bloquea a beto → se borra el new_follower de beto (y viceversa)
SET LOCAL session_replication_role = replica;
INSERT INTO notifications (user_id, type, actor_id) VALUES
  ('b5000000-0000-4000-8000-00000000000b', 'follow_accepted', 'b5000000-0000-4000-8000-00000000000a');
SET LOCAL session_replication_role = origin;
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000a');
SELECT block_user('b5000000-0000-4000-8000-00000000000b');
RESET ROLE;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM notifications
    WHERE (user_id = 'b5000000-0000-4000-8000-00000000000a' AND actor_id = 'b5000000-0000-4000-8000-00000000000b')
       OR (user_id = 'b5000000-0000-4000-8000-00000000000b' AND actor_id = 'b5000000-0000-4000-8000-00000000000a')) THEN
    RAISE EXCEPTION 'N7: quedaron avisos entre bloqueados';
  END IF;
  RAISE NOTICE 'N7 ok';
END $$;

-- N8: decisiones (ana con notifications_enabled FALSE: igual le llegan)
UPDATE user_settings SET notifications_enabled = FALSE WHERE user_id = 'b5000000-0000-4000-8000-00000000000a';
SELECT apply_moderation_decision('b7000000-0000-4000-8000-000000000001', 'approve', 'b5000000-0000-4000-8000-0000000000e1');
SELECT apply_moderation_decision('b7000000-0000-4000-8000-000000000002', 'approve', 'b5000000-0000-4000-8000-0000000000e1');
SELECT apply_moderation_decision('b7000000-0000-4000-8000-000000000003', 'approve', 'b5000000-0000-4000-8000-0000000000e1');
SELECT apply_moderation_decision('b7000000-0000-4000-8000-000000000004', 'reject', 'b5000000-0000-4000-8000-0000000000e1', 'high', 'harassment', 'nota interna');
SELECT apply_moderation_decision('b7000000-0000-4000-8000-000000000005', 'reject', 'b5000000-0000-4000-8000-0000000000e1', 'low', 'spam', NULL);
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM notifications WHERE user_id = 'b5000000-0000-4000-8000-00000000000a'
    AND type = 'gossip_approved' AND gossip_id = 'b6000000-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION 'N8: aprobar de la cola IA no avisó';
  END IF;
  IF EXISTS (SELECT 1 FROM notifications WHERE gossip_id = 'b6000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'N8: aprobar un reportado no oculto avisó';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM notifications WHERE type = 'gossip_approved'
    AND gossip_id = 'b6000000-0000-4000-8000-000000000003') THEN
    RAISE EXCEPTION 'N8: restaurar un oculto por reportes no avisó';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM notifications WHERE type = 'gossip_rejected'
    AND gossip_id = 'b6000000-0000-4000-8000-000000000004' AND reason = 'harassment') THEN
    RAISE EXCEPTION 'N8: rechazo sin aviso o sin motivo';
  END IF;
  IF EXISTS (SELECT 1 FROM notifications WHERE reason = 'nota interna') THEN
    RAISE EXCEPTION 'N8: se filtró la nota interna';
  END IF;
  RAISE NOTICE 'N8 ok';
END $$;

-- N9: apelaciones (decide otro moderador)
DO $$
DECLARE
  a JSONB;
BEGIN
  a := submit_appeal('b5000000-0000-4000-8000-00000000000a', 'b7000000-0000-4000-8000-000000000004', 'No era acoso, pido revisión');
  PERFORM decide_appeal((a->>'id')::uuid, 'accept', 'b5000000-0000-4000-8000-0000000000e2', 'nota interna');
  a := submit_appeal('b5000000-0000-4000-8000-00000000000a', 'b7000000-0000-4000-8000-000000000005', 'No era spam, pido revisión');
  PERFORM decide_appeal((a->>'id')::uuid, 'reject', 'b5000000-0000-4000-8000-0000000000e2', NULL);
  IF NOT EXISTS (SELECT 1 FROM notifications WHERE type = 'appeal_accepted'
    AND user_id = 'b5000000-0000-4000-8000-00000000000a' AND gossip_id = 'b6000000-0000-4000-8000-000000000004') THEN
    RAISE EXCEPTION 'N9: apelación aceptada sin aviso';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM notifications WHERE type = 'appeal_rejected'
    AND gossip_id = 'b6000000-0000-4000-8000-000000000005') THEN
    RAISE EXCEPTION 'N9: apelación rechazada sin aviso';
  END IF;
  RAISE NOTICE 'N9 ok';
END $$;

-- N10: API de lectura. Ana tiene: follow_accepted de caro (N3), 2 aprobados,
-- 2 rechazos, 2 apelaciones (N8/N9); los de beto se borraron al bloquearlo
-- Un aviso de dani (no bloqueado) y uno de un chisme borrado
INSERT INTO notifications (user_id, type, actor_id, created_at) VALUES
  ('b5000000-0000-4000-8000-00000000000a', 'new_follower', 'b5000000-0000-4000-8000-00000000000d', NOW() + INTERVAL '1 second');
UPDATE gossips SET status = 'deleted', deleted_at = NOW() WHERE id = 'b6000000-0000-4000-8000-000000000005';
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000a');
DO $$
DECLARE
  p JSON;
  p2 JSON;
  total INT;
  first JSON;
  ids UUID[];
BEGIN
  total := get_unread_notifications_count();
  -- dani + caro + 2 aprobados + rechazo 004 + apelación 004 (los del 005 borrado no)
  IF total <> 6 THEN RAISE EXCEPTION 'N10: contador % (esperado 6)', total; END IF;

  p := get_notifications(3);
  IF json_array_length(p->'data') <> 3 OR NOT (p->>'has_more')::boolean THEN
    RAISE EXCEPTION 'N10: primera página mal: %', p;
  END IF;
  first := p->'data'->0;
  IF first->>'type' <> 'new_follower' OR first->'actor'->>'username' <> 'n_dani'
     OR (first->>'is_read')::boolean OR (first->'gossip')::text <> 'null' THEN
    RAISE EXCEPTION 'N10: forma del aviso social mal: %', first;
  END IF;

  p2 := get_notifications(3, (p->'next_cursor'->>'created_at')::timestamptz, (p->'next_cursor'->>'id')::uuid);
  IF json_array_length(p2->'data') <> 3 OR (p2->>'has_more')::boolean THEN
    RAISE EXCEPTION 'N10: segunda página mal: %', p2;
  END IF;
  IF EXISTS (
    SELECT 1 FROM json_array_elements((p->'data')::json) e WHERE e->>'id' IN
      (SELECT x->>'id' FROM json_array_elements((p2->'data')::json) x)) THEN
    RAISE EXCEPTION 'N10: páginas repetidas';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM (
      SELECT json_array_elements(p->'data') AS e
      UNION ALL SELECT json_array_elements(p2->'data')
    ) x
    WHERE e->>'type' = 'gossip_rejected' AND e->'gossip'->>'subject' = 'zn a rechazar 1'
      AND e->>'reason' = 'harassment' AND (e->'actor')::text = 'null') THEN
    RAISE EXCEPTION 'N10: falta el rechazo con chisme y motivo';
  END IF;

  -- Marcar uno (ajenos no se tocan)
  SELECT array_agg(id) INTO ids FROM (
    SELECT (e->>'id')::uuid AS id FROM json_array_elements((p->'data')::json) e LIMIT 1) s;
  IF mark_notifications_read(ids || '00000000-0000-4000-8000-000000000000'::uuid) <> 1 THEN
    RAISE EXCEPTION 'N10: marcar por id';
  END IF;
  IF get_unread_notifications_count() <> 5 THEN RAISE EXCEPTION 'N10: contador tras marcar uno'; END IF;
  IF (get_notifications(1)->'data'->0->>'is_read')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'N10: is_read no cambió';
  END IF;
  PERFORM mark_notifications_read();
  IF get_unread_notifications_count() <> 0 THEN RAISE EXCEPTION 'N10: marcar todas'; END IF;
  RAISE NOTICE 'N10 ok';
END $$;

-- Los de otros no se marcan
SELECT pg_temp.as_user('b5000000-0000-4000-8000-00000000000d');
DO $$ BEGIN
  IF get_unread_notifications_count() <> 1 THEN
    RAISE EXCEPTION 'N10: dani debería tener 1 sin leer (follow_accepted)';
  END IF;
END $$;

-- N11: acceso
DO $$ BEGIN
  BEGIN
    PERFORM 1 FROM notifications;
    RAISE EXCEPTION 'N11: authenticated lee la tabla';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    INSERT INTO notifications (user_id, type, actor_id)
    VALUES (auth.uid(), 'new_follower', 'b5000000-0000-4000-8000-00000000000a');
    RAISE EXCEPTION 'N11: authenticated escribe la tabla';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM notify_account(auth.uid(), 'gossip_approved', 'b6000000-0000-4000-8000-000000000001');
    RAISE EXCEPTION 'N11: notify_account expuesto';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM notify_social(auth.uid(), 'new_follower', 'b5000000-0000-4000-8000-00000000000a');
    RAISE EXCEPTION 'N11: notify_social expuesto';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM cleanup_old_notifications();
    RAISE EXCEPTION 'N11: cleanup expuesto';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
  BEGIN
    PERFORM get_unread_notifications_count();
    RAISE EXCEPTION 'N11: anon llama la API';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM get_notifications();
    RAISE EXCEPTION 'N11: anon lista';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM mark_notifications_read();
    RAISE EXCEPTION 'N11: anon marca';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'N11 ok';
END $$;
RESET ROLE;

-- N12: borrar a dani (autor de un aviso de ana y destinataria de otro)
DELETE FROM auth.users WHERE id = 'b5000000-0000-4000-8000-00000000000d';
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM notifications WHERE 'b5000000-0000-4000-8000-00000000000d' IN (user_id, actor_id)) THEN
    RAISE EXCEPTION 'N12: quedaron avisos de la cuenta borrada';
  END IF;
  RAISE NOTICE 'N12 ok';
END $$;

-- N13: retención
UPDATE notifications SET created_at = NOW() - INTERVAL '91 days'
WHERE gossip_id = 'b6000000-0000-4000-8000-000000000001';
DO $$
DECLARE
  before INT;
BEGIN
  SELECT COUNT(*) INTO before FROM notifications;
  IF cleanup_old_notifications() <> 1 THEN RAISE EXCEPTION 'N13: no borró el viejo'; END IF;
  IF (SELECT COUNT(*) FROM notifications) <> before - 1 THEN RAISE EXCEPTION 'N13: borró de más'; END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'notifications-cleanup') THEN
    RAISE EXCEPTION 'N13: job de pg_cron no programado';
  END IF;
  RAISE NOTICE 'N13 ok';
END $$;

ROLLBACK;
