-- =====================================================
-- Test: reportes, umbral y cola de revisión (013_moderation.sql)
-- =====================================================
-- Umbral (B): mínimo de reportes, cuentas nuevas no cuentan, umbral relativo
-- a las interacciones, lo popular no se oculta solo, configurable en tabla.
-- Cola (D): encolar veredictos 'review', media pendiente protegida de la
-- limpieza, aprobar/rechazar atómico, reportes resueltos, historial.
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/005_moderation_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

SET LOCAL session_replication_role = replica; -- datos de prueba sin triggers
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-medellin','co-antioquia','CO','Medellín',6.25,-75.56);

-- Autor + 6 cuentas antiguas (R1..R6) + 1 cuenta nueva (N1)
INSERT INTO auth.users (id, instance_id, aud, role, email, created_at) VALUES
 ('a0000000-0000-4000-8000-00000000000a','00000000-0000-0000-0000-000000000000','authenticated','authenticated','autor@t.co', now() - interval '30 days'),
 ('e0000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','r1@t.co', now() - interval '10 days'),
 ('e0000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','r2@t.co', now() - interval '10 days'),
 ('e0000000-0000-4000-8000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','r3@t.co', now() - interval '10 days'),
 ('e0000000-0000-4000-8000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','r4@t.co', now() - interval '10 days'),
 ('e0000000-0000-4000-8000-000000000005','00000000-0000-0000-0000-000000000000','authenticated','authenticated','r5@t.co', now() - interval '10 days'),
 ('e0000000-0000-4000-8000-000000000006','00000000-0000-0000-0000-000000000000','authenticated','authenticated','r6@t.co', now() - interval '10 days'),
 ('e0000000-0000-4000-8000-0000000000aa','00000000-0000-0000-0000-000000000000','authenticated','authenticated','nueva@t.co', now() - interval '1 hour'),
 ('d0000000-0000-4000-8000-00000000000d','00000000-0000-0000-0000-000000000000','authenticated','authenticated','mod@t.co', now() - interval '30 days');

-- G1 normal (0 interacciones) · G2 popular (600) · G3 mediano (300 → umbral 6)
-- G4 draft en revisión con imagen · G5 borrado por su autor
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility, like_count) VALUES
 ('c0000000-0000-4000-8000-000000000001','CO','co-antioquia','t-medellin','Normal','x','anonymous','a0000000-0000-4000-8000-00000000000a','published','approved','public',0),
 ('c0000000-0000-4000-8000-000000000002','CO','co-antioquia','t-medellin','Messi','x','profile','a0000000-0000-4000-8000-00000000000a','published','approved','public',600),
 ('c0000000-0000-4000-8000-000000000003','CO','co-antioquia','t-medellin','Mediano','x','profile','a0000000-0000-4000-8000-00000000000a','published','approved','public',300),
 ('c0000000-0000-4000-8000-000000000004','CO','co-antioquia','t-medellin','En revision','x','anonymous','a0000000-0000-4000-8000-00000000000a','draft','pending','public',0),
 ('c0000000-0000-4000-8000-000000000005','CO','co-antioquia','t-medellin','Borrado','x','profile','a0000000-0000-4000-8000-00000000000a','deleted','pending','public',0);
UPDATE gossips SET deleted_at = now() WHERE id = 'c0000000-0000-4000-8000-000000000005';

-- Archivos en cuarentena viejos (>24 h): uno de G4 (pendiente) y uno huérfano
INSERT INTO storage.objects (bucket_id, name, created_at) VALUES
 ('images-quarantine', 'quarantine/autor/g4.jpg', now() - interval '3 days'),
 ('images-quarantine', 'quarantine/autor/huerfano.jpg', now() - interval '3 days');
SET LOCAL session_replication_role = origin;

-- Las Edge Functions operan con service_role
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);

-- ---------- B1: bajo el mínimo no pasa nada; cuentas nuevas no cuentan ----------
INSERT INTO content_reports (gossip_id, reported_by, reason) VALUES
 ('c0000000-0000-4000-8000-000000000001','e0000000-0000-4000-8000-000000000001','harassment'),
 ('c0000000-0000-4000-8000-000000000001','e0000000-0000-4000-8000-000000000002','spam'),
 ('c0000000-0000-4000-8000-000000000001','e0000000-0000-4000-8000-0000000000aa','harassment');
DO $$
DECLARE g gossips%ROWTYPE;
BEGIN
  SELECT * INTO g FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000001';
  IF g.report_count <> 3 THEN RAISE EXCEPTION 'B1: report_count = % (esperado 3)', g.report_count; END IF;
  IF g.status <> 'published' THEN RAISE EXCEPTION 'B1: se ocultó con 2 reportes válidos'; END IF;
  IF EXISTS (SELECT 1 FROM moderation_queue WHERE gossip_id = g.id) THEN
    RAISE EXCEPTION 'B1: entró a la cola con 2 reportes válidos (la cuenta nueva no cuenta)';
  END IF;
  RAISE NOTICE '✅ B1: 2 válidos + 1 de cuenta nueva → nada (report_count = 3)';
END $$;

-- ---------- B2: tercer reporte válido → cola + auto-ocultar ----------
INSERT INTO content_reports (gossip_id, reported_by, reason) VALUES
 ('c0000000-0000-4000-8000-000000000001','e0000000-0000-4000-8000-000000000003','harassment');
DO $$
DECLARE g gossips%ROWTYPE; q moderation_queue%ROWTYPE;
BEGIN
  SELECT * INTO g FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000001';
  SELECT * INTO q FROM moderation_queue WHERE gossip_id = g.id AND status = 'pending';
  IF g.status <> 'hidden' OR g.moderation_status <> 'flagged' THEN
    RAISE EXCEPTION 'B2: no se ocultó (status %, moderation %)', g.status, g.moderation_status;
  END IF;
  IF g.modified_by IS NOT NULL THEN RAISE EXCEPTION 'B2: modified_by quedó con un usuario'; END IF;
  IF q.id IS NULL OR q.source <> 'reports' OR q.priority <> 'normal' OR NOT q.auto_hidden
     OR q.report_count <> 3 OR q.content_author_id <> g.created_by
     OR q.reasons <> ARRAY['harassment','spam'] THEN
    RAISE EXCEPTION 'B2: entrada de cola incorrecta: %', row_to_json(q);
  END IF;
  RAISE NOTICE '✅ B2: 3 válidos → cola (normal, auto_hidden, autor, motivos) y oculto';
END $$;

-- ---------- B3: lo popular no se oculta solo, va con prioridad alta ----------
INSERT INTO content_reports (gossip_id, reported_by, reason) VALUES
 ('c0000000-0000-4000-8000-000000000002','e0000000-0000-4000-8000-000000000001','spam'),
 ('c0000000-0000-4000-8000-000000000002','e0000000-0000-4000-8000-000000000002','spam'),
 ('c0000000-0000-4000-8000-000000000002','e0000000-0000-4000-8000-000000000003','spam');
DO $$
BEGIN
  IF (SELECT status FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000002') <> 'published' THEN
    RAISE EXCEPTION 'B3: se ocultó un chisme popular';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000002'
                 AND status = 'pending' AND priority = 'high' AND NOT auto_hidden) THEN
    RAISE EXCEPTION 'B3: el popular no entró a la cola con prioridad alta';
  END IF;
  RAISE NOTICE '✅ B3: popular (600) con 3 reportes → cola prioridad alta, sigue visible';
END $$;

-- ---------- B4: umbral relativo (300 interacciones × 2% = 6) ----------
INSERT INTO content_reports (gossip_id, reported_by, reason)
SELECT 'c0000000-0000-4000-8000-000000000003', u, 'misinformation'
FROM unnest(ARRAY['e0000000-0000-4000-8000-000000000001','e0000000-0000-4000-8000-000000000002',
                  'e0000000-0000-4000-8000-000000000003']::uuid[]) u;
DO $$
BEGIN
  IF (SELECT status FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000003') <> 'published' THEN
    RAISE EXCEPTION 'B4: se ocultó con 3 de 6';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000003'
                 AND status = 'pending' AND NOT auto_hidden) THEN
    RAISE EXCEPTION 'B4: con 3 reportes debía entrar a la cola sin ocultarse';
  END IF;
END $$;
INSERT INTO content_reports (gossip_id, reported_by, reason)
SELECT 'c0000000-0000-4000-8000-000000000003', u, 'misinformation'
FROM unnest(ARRAY['e0000000-0000-4000-8000-000000000004','e0000000-0000-4000-8000-000000000005',
                  'e0000000-0000-4000-8000-000000000006']::uuid[]) u;
DO $$
BEGIN
  IF (SELECT status FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000003') <> 'hidden' THEN
    RAISE EXCEPTION 'B4: no se ocultó con 6 de 6';
  END IF;
  IF (SELECT COUNT(*) FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000003') <> 1 THEN
    RAISE EXCEPTION 'B4: duplicó la entrada de cola';
  END IF;
  IF NOT (SELECT auto_hidden FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000003') THEN
    RAISE EXCEPTION 'B4: auto_hidden no se actualizó';
  END IF;
  RAISE NOTICE '✅ B4: 300 interacciones → 3 reportes encola sin ocultar, 6 oculta (una sola entrada)';
END $$;

-- ---------- B5: configurable sin despliegue ----------
UPDATE moderation_settings SET value = 1 WHERE key = 'report_popular_interactions';
DO $$
DECLARE v NUMERIC;
BEGIN
  SELECT value INTO v FROM moderation_settings WHERE key = 'report_popular_interactions';
  IF v <> 1 THEN RAISE EXCEPTION 'B5: no se pudo editar moderation_settings'; END IF;
  RAISE NOTICE '✅ B5: moderation_settings editable por el backend/dashboard';
END $$;
UPDATE moderation_settings SET value = 500 WHERE key = 'report_popular_interactions';

-- ---------- D1: encolar veredicto 'review' (idempotente) ----------
DO $$
DECLARE v1 UUID; v2 UUID;
BEGIN
  v1 := enqueue_moderation('c0000000-0000-4000-8000-000000000004', 'ai_unavailable',
                           ARRAY['moderation_unavailable'], 'quarantine/autor/g4.jpg', NULL);
  v2 := enqueue_moderation('c0000000-0000-4000-8000-000000000004', 'ai_unavailable',
                           ARRAY['moderation_unavailable'], 'quarantine/autor/otro.jpg', NULL);
  IF v1 IS NULL OR v2 IS NOT NULL THEN RAISE EXCEPTION 'D1: enqueue no es idempotente (%, %)', v1, v2; END IF;
  IF (SELECT image_quarantine_path FROM moderation_queue WHERE id = v1) <> 'quarantine/autor/g4.jpg' THEN
    RAISE EXCEPTION 'D1: el reintento pisó la ruta de la media';
  END IF;
  RAISE NOTICE '✅ D1: enqueue_moderation encola una vez y conserva la ruta de la media';
END $$;

-- ---------- D2: la limpieza no borra la media pendiente ----------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM get_media_cleanup_candidates(1000) WHERE name = 'quarantine/autor/g4.jpg') THEN
    RAISE EXCEPTION 'D2: la limpieza borraría la media de un chisme pendiente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM get_media_cleanup_candidates(1000) WHERE name = 'quarantine/autor/huerfano.jpg') THEN
    RAISE EXCEPTION 'D2: la limpieza dejó de borrar la cuarentena huérfana';
  END IF;
  RAISE NOTICE '✅ D2: cleanup excluye la media pendiente y sigue borrando la huérfana';
END $$;

-- ---------- D3: listar ----------
DO $$
DECLARE v_first moderation_queue_items%ROWTYPE;
BEGIN
  SELECT * INTO v_first FROM moderation_queue_items WHERE status = 'pending'
  ORDER BY priority, created_at LIMIT 1;
  IF v_first.gossip_id <> 'c0000000-0000-4000-8000-000000000002' THEN
    RAISE EXCEPTION 'D3: la prioridad alta no sale primero';
  END IF;
  -- El moderador ve el autor real, también de anónimos
  IF (SELECT content_author_id FROM moderation_queue_items
      WHERE gossip_id = 'c0000000-0000-4000-8000-000000000001') <> 'a0000000-0000-4000-8000-00000000000a' THEN
    RAISE EXCEPTION 'D3: el moderador no ve el autor del anónimo';
  END IF;
  -- ... y su nombre de perfil (para el panel de moderación)
  INSERT INTO profiles (id, display_name) VALUES ('a0000000-0000-4000-8000-00000000000a', 'Autor Test')
    ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
  IF (SELECT author_display_name FROM moderation_queue_items
      WHERE gossip_id = 'c0000000-0000-4000-8000-000000000001') IS DISTINCT FROM 'Autor Test' THEN
    RAISE EXCEPTION 'D3: la vista no trae el nombre del autor';
  END IF;
  RAISE NOTICE '✅ D3: moderation_queue_items: prioridad alta primero, autor real y su nombre visibles al equipo';
END $$;

-- ---------- D4: aprobar restaura lo auto-ocultado y descarta reportes ----------
DO $$
DECLARE v JSONB; g gossips%ROWTYPE;
BEGIN
  v := apply_moderation_decision(
    (SELECT id FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000001' AND status = 'pending'),
    'approve', 'd0000000-0000-4000-8000-00000000000d', NULL, 'falso_positivo', 'Reportes coordinados');
  SELECT * INTO g FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000001';
  IF g.status <> 'published' OR g.moderation_status <> 'approved' THEN
    RAISE EXCEPTION 'D4: no se restauró (status %, moderation %)', g.status, g.moderation_status;
  END IF;
  IF EXISTS (SELECT 1 FROM content_reports WHERE gossip_id = g.id AND status <> 'dismissed') THEN
    RAISE EXCEPTION 'D4: quedaron reportes sin descartar';
  END IF;
  IF v->>'status' <> 'approved' OR v->>'decided_by' <> 'd0000000-0000-4000-8000-00000000000d'
     OR v->>'decision_severity' IS NOT NULL OR v->>'decision_reason' <> 'falso_positivo' THEN
    RAISE EXCEPTION 'D4: decisión mal registrada: %', v;
  END IF;
  RAISE NOTICE '✅ D4: aprobar → publicado, reportes descartados, decisión registrada';
END $$;

-- Reportes nuevos tras la decisión: el conteo vuelve a empezar
INSERT INTO content_reports (gossip_id, reported_by, reason) VALUES
 ('c0000000-0000-4000-8000-000000000001','e0000000-0000-4000-8000-000000000004','spam');
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000001' AND status = 'pending')
     OR (SELECT status FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000001') <> 'published' THEN
    RAISE EXCEPTION 'D4b: un reporte nuevo reabrió la cola/ocultó (los descartados no cuentan)';
  END IF;
  RAISE NOTICE '✅ D4b: tras la decisión, los reportes descartados no cuentan para el umbral';
END $$;

-- ---------- D5: rechazar exige gravedad ----------
DO $$
BEGIN
  BEGIN
    PERFORM apply_moderation_decision(
      (SELECT id FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000004' AND status = 'pending'),
      'reject', 'd0000000-0000-4000-8000-00000000000d');
    RAISE EXCEPTION 'D5: rechazó sin gravedad';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE '✅ D5: rechazar sin gravedad → error';
END $$;

-- ---------- D6: rechazar oculta (no borra) y registra gravedad ----------
DO $$
DECLARE v_id UUID; g gossips%ROWTYPE; q moderation_queue%ROWTYPE;
BEGIN
  SELECT id INTO v_id FROM moderation_queue
  WHERE gossip_id = 'c0000000-0000-4000-8000-000000000003' AND status = 'pending';
  PERFORM apply_moderation_decision(v_id, 'reject', 'd0000000-0000-4000-8000-00000000000d', 'high', 'desinformacion');
  SELECT * INTO g FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000003';
  SELECT * INTO q FROM moderation_queue WHERE id = v_id;
  IF g.status <> 'hidden' OR g.moderation_status <> 'rejected' THEN
    RAISE EXCEPTION 'D6: no quedó oculto+rechazado';
  END IF;
  IF EXISTS (SELECT 1 FROM content_reports WHERE gossip_id = g.id AND status <> 'actioned') THEN
    RAISE EXCEPTION 'D6: quedaron reportes sin atender';
  END IF;
  IF q.decision_severity <> 'high' OR q.status <> 'rejected' THEN
    RAISE EXCEPTION 'D6: gravedad/estado no registrados';
  END IF;
  -- Decidir dos veces
  BEGIN
    PERFORM apply_moderation_decision(v_id, 'approve', 'd0000000-0000-4000-8000-00000000000d');
    RAISE EXCEPTION 'D6: permitió decidir dos veces';
  EXCEPTION WHEN SQLSTATE '55000' THEN NULL;
  END;
  RAISE NOTICE '✅ D6: rechazar → oculto (no borrado), reportes atendidos, gravedad; no se decide dos veces';
END $$;

-- ---------- D7: aprobar publica la media ----------
DO $$
DECLARE g gossips%ROWTYPE;
BEGIN
  PERFORM apply_moderation_decision(
    (SELECT id FROM moderation_queue WHERE gossip_id = 'c0000000-0000-4000-8000-000000000004' AND status = 'pending'),
    'approve', 'd0000000-0000-4000-8000-00000000000d', NULL, NULL, NULL,
    jsonb_build_object('image_url', 'https://cdn/full.jpg', 'thumbnail_url', 'https://cdn/thumb.jpg',
                       'storage_path', 'gossips/full/x.jpg', 'thumbnail_storage_path', 'gossips/thumb/x.jpg'));
  SELECT * INTO g FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000004';
  IF g.status <> 'published' OR g.image_url <> 'https://cdn/full.jpg' OR g.storage_path <> 'gossips/full/x.jpg'
     OR g.thumbnail_storage_path <> 'gossips/thumb/x.jpg' THEN
    RAISE EXCEPTION 'D7: no se publicó con su media: %', row_to_json(g);
  END IF;
  RAISE NOTICE '✅ D7: aprobar un draft en revisión → publicado con su media';
END $$;

-- ---------- D8: un chisme borrado por su autor no se republica ----------
DO $$
DECLARE v_id UUID;
BEGIN
  v_id := enqueue_moderation('c0000000-0000-4000-8000-000000000005', 'ai_review', ARRAY['potential_spam']);
  IF EXISTS (SELECT 1 FROM moderation_queue_items WHERE id = v_id) THEN
    RAISE EXCEPTION 'D8: la lista muestra un pendiente de un chisme borrado';
  END IF;
  PERFORM apply_moderation_decision(v_id, 'approve', 'd0000000-0000-4000-8000-00000000000d');
  IF (SELECT status FROM gossips WHERE id = 'c0000000-0000-4000-8000-000000000005') <> 'deleted' THEN
    RAISE EXCEPTION 'D8: se republicó un chisme borrado';
  END IF;
  RAISE NOTICE '✅ D8: chisme borrado: fuera de la lista y no se republica';
END $$;

-- ---------- "Exactamente una" referencia ----------
DO $$
BEGIN
  BEGIN
    INSERT INTO content_reports (gossip_id, reported_by, reason)
      VALUES (NULL, 'e0000000-0000-4000-8000-000000000001', 'spam');
    RAISE EXCEPTION 'reporte sin contenido aceptado';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO content_reports (gossip_id, reported_by, reason)
      VALUES ('c0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000001', 'spam');
    RAISE EXCEPTION 'reporte duplicado aceptado';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  RAISE NOTICE '✅ content_reports: exactamente un contenido por reporte y uno por usuario';
END $$;

-- ---------- Reglas de contenido (moderation_rules) ----------
RESET ROLE;
DO $$
DECLARE
  v_count INT;
  v_after TIMESTAMPTZ;
BEGIN
  SELECT COUNT(*) INTO v_count FROM moderation_rules WHERE enabled;
  IF v_count <> 9 THEN RAISE EXCEPTION 'R1: se esperaban 9 reglas iniciales, hay %', v_count; END IF;
  RAISE NOTICE '✅ R1: reglas iniciales (3 fijas + 6 términos)';

  -- Umbral de IA válido y editable
  INSERT INTO moderation_rules (kind, target, action, min_score)
    VALUES ('ai_category', 'harassment', 'review', 0.3);
  INSERT INTO moderation_rules (kind, target, action, min_score)
    VALUES ('ai_category', 'harassment', 'reject', 0.7);
  RAISE NOTICE '✅ R2: umbral review y reject en la misma categoría';

  -- Lo que un typo no debe poder dejar
  BEGIN
    INSERT INTO moderation_rules (kind, target, action, min_score) VALUES ('ai_category', 'acoso', 'review', 0.3);
    RAISE EXCEPTION 'R3: categoría de IA inexistente aceptada';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action) VALUES ('ai_category', 'hate', 'review');
    RAISE EXCEPTION 'R3: umbral sin min_score aceptado';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action, min_score) VALUES ('ai_category', 'hate', 'review', 1.5);
    RAISE EXCEPTION 'R3: min_score > 1 aceptado';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action, min_score) VALUES ('term', 'sapo', 'review', 0.5);
    RAISE EXCEPTION 'R3: término con min_score aceptado';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action) VALUES ('term', ' x ', 'review');
    RAISE EXCEPTION 'R3: término de 1 letra aceptado';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action) VALUES ('builtin', 'regex_libre', 'review');
    RAISE EXCEPTION 'R3: regla fija inexistente aceptada';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action) VALUES ('term', 'sapo', 'publish');
    RAISE EXCEPTION 'R3: acción inválida aceptada';
  EXCEPTION WHEN check_violation THEN NULL; END;
  RAISE NOTICE '✅ R3: categorías, puntajes, términos, reglas fijas y acciones validados';

  -- Duplicados: mismo término (sin importar mayúsculas/espacios) y acción; regla fija dos veces
  BEGIN
    INSERT INTO moderation_rules (kind, target, action) VALUES ('term', ' Malparido', 'review');
    RAISE EXCEPTION 'R4: término duplicado aceptado';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN
    INSERT INTO moderation_rules (kind, target, action) VALUES ('builtin', 'spam', 'reject');
    RAISE EXCEPTION 'R4: regla fija duplicada aceptada';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  RAISE NOTICE '✅ R4: sin reglas duplicadas';

  -- updated_at lo pone el trigger: aunque el UPDATE intente otra fecha
  UPDATE moderation_rules SET enabled = FALSE, updated_at = NOW() - interval '1 day'
    WHERE target = 'spam';
  SELECT updated_at INTO v_after FROM moderation_rules WHERE target = 'spam';
  IF v_after <> NOW() THEN RAISE EXCEPTION 'R5: updated_at no lo puso el trigger (%)', v_after; END IF;
  RAISE NOTICE '✅ R5: apagar una regla fija actualiza updated_at';
END $$;

RESET ROLE;
DO $$ BEGIN RAISE NOTICE '✅ TODOS LOS TESTS DE MODERACIÓN PASARON'; END $$;
ROLLBACK;
