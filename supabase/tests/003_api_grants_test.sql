-- =====================================================
-- Test: GRANTs de la API (anon / authenticated / service_role)
-- =====================================================
-- El proyecto remoto NO da privilegios por defecto en tablas/funciones
-- nuevas: sin GRANT explícito todo falla con "permission denied". El Supabase
-- local SÍ los da, así que para que este test sea realista hay que correrlo
-- sobre una base local que imite al remoto (ver supabase/tests/README.md).
--
-- Recorre cada camino real de acceso con el rol que usa:
--   - app (authenticated): feed, búsquedas, location, leer perfil, configuración
--     (reportes: vía report-gossip; editar perfil: vía update-profile)
--   - Edge Functions con service_role: log-error, report-gossip, moderate-gossip,
--     moderation-review, cleanup-media, delete-account
--   - anon: check_email_exists_and_confirmed (login), nada más
-- Todo en una transacción con ROLLBACK.
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

SET LOCAL session_replication_role = replica; -- datos de prueba sin triggers
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-medellin','co-antioquia','CO','Medellín',6.25,-75.56);
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','a@t.co');
INSERT INTO profiles (id) VALUES ('11111111-1111-1111-1111-111111111111') ON CONFLICT DO NOTHING;
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility)
  VALUES ('a0000000-0000-0000-0000-000000000001','CO','co-antioquia','t-medellin','s','c','profile','11111111-1111-1111-1111-111111111111','published','approved','public');
SET LOCAL session_replication_role = origin;

-- ---------- authenticated (la app con sesión) ----------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',true);
DO $$
BEGIN
  PERFORM get_popular_feed('t-medellin','co-antioquia','CO');
  PERFORM get_following_feed('11111111-1111-1111-1111-111111111111'::uuid);
  PERFORM check_new_gossips('t-medellin', NULL, 'CO', now() - interval '1 day');
  PERFORM * FROM search_gossips('s');
  PERFORM * FROM search_cities('Med');
  PERFORM * FROM find_nearest_city(6.25, -75.56, 50);
  PERFORM check_email_exists_and_confirmed('a@t.co');
  PERFORM 1 FROM public_gossips LIMIT 1;
  PERFORM 1 FROM countries, regions, cities LIMIT 1;
  PERFORM 1 FROM feed_settings LIMIT 1;
  -- El perfil se edita solo vía update-profile (017); la configuración, directo
  PERFORM 1 FROM profiles WHERE id = auth.uid();
  UPDATE user_settings SET show_email = FALSE WHERE user_id = auth.uid();
  -- report-gossip usa el JWT del usuario solo para verificar que ve el chisme
  PERFORM 1 FROM public_gossips WHERE id = 'a0000000-0000-0000-0000-000000000001';
  RAISE NOTICE '✅ authenticated: feed, búsquedas, location, perfil y verificación de reporte';
END $$;

-- Lo que NO debe poder: escribir gossips directo ni leer logs/rate limits
DO $$
DECLARE denied INT := 0;
BEGIN
  BEGIN INSERT INTO gossips (country_id, region_id, city_id, subject, content, published_as, created_by)
        VALUES ('CO','co-antioquia','t-medellin','x','x','profile', auth.uid());
  EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM error_logs; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM rate_limits; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN UPDATE feed_settings SET value = 1; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM gossips; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  -- Moderación: solo backend
  BEGIN INSERT INTO content_reports (gossip_id, reported_by, reason)
        VALUES ('a0000000-0000-0000-0000-000000000001', auth.uid(), 'spam');
  EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM content_reports; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM moderation_queue; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM moderation_queue_items; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN UPDATE moderation_settings SET value = 1; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  -- Reglas de moderate-gossip: conocerlas ayuda a esquivarlas
  BEGIN PERFORM 1 FROM moderation_rules; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM enqueue_moderation('a0000000-0000-0000-0000-000000000001', 'ai_review', '{}');
  EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM apply_moderation_decision(gen_random_uuid(), 'approve', auth.uid());
  EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  -- Perfil: solo vía update-profile (017)
  BEGIN UPDATE profiles SET bio = 'x' WHERE id = auth.uid();
  EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  IF denied <> 14 THEN RAISE EXCEPTION 'authenticated tiene permisos de más (% de 14 bloqueados)', denied; END IF;
  RAISE NOTICE '✅ authenticated: bloqueado en gossips (INSERT y SELECT), error_logs, rate_limits, feed_settings (UPDATE), profiles (UPDATE) y toda la moderación';
END $$;

-- ---------- service_role (Edge Functions) ----------
RESET ROLE;
SET LOCAL ROLE service_role;
DO $$
BEGIN
  -- log-error
  INSERT INTO error_logs (level, message) VALUES ('error', 'test');
  PERFORM 1 FROM error_logs;
  PERFORM 1 FROM recent_errors, error_summary, users_with_most_errors LIMIT 1;
  -- report-gossip (crea el reporte con service_role)
  INSERT INTO content_reports (gossip_id, reported_by, reason)
    VALUES ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'spam');
  -- moderate-gossip (encola 'review') y moderation-review (lista y decide)
  PERFORM enqueue_moderation('a0000000-0000-0000-0000-000000000001', 'ai_review', ARRAY['potential_spam']);
  PERFORM 1 FROM moderation_queue_items LIMIT 1;
  PERFORM apply_moderation_decision(
    (SELECT id FROM moderation_queue WHERE status = 'pending' LIMIT 1), 'approve',
    '11111111-1111-1111-1111-111111111111');
  PERFORM 1 FROM moderation_settings;
  -- cleanup-media
  PERFORM * FROM get_media_cleanup_candidates(10);
  -- delete-account (el borrado en sí: delete_user_account, en 006)
  PERFORM get_account_deletion_media('11111111-1111-1111-1111-111111111111');
  PERFORM 1 FROM account_deletion_records;
  -- moderate-gossip (validación de ubicación y reglas de moderación)
  PERFORM 1 FROM countries, regions, cities LIMIT 1;
  PERFORM kind, target, action, min_score FROM moderation_rules WHERE enabled;
  RAISE NOTICE '✅ service_role: log-error, report-gossip, moderation-review, cleanup-media, delete-account, moderate-gossip';
END $$;

-- ---------- anon (sin sesión: solo pantalla de login) ----------
RESET ROLE;
SET LOCAL ROLE anon;
DO $$
DECLARE denied INT := 0;
BEGIN
  PERFORM check_email_exists_and_confirmed('a@t.co');
  BEGIN PERFORM 1 FROM gossips; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM profiles; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM error_logs; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM get_popular_feed(); EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM public_gossips; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM * FROM search_gossips(''); EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  BEGIN PERFORM 1 FROM moderation_rules; EXCEPTION WHEN insufficient_privilege THEN denied := denied + 1; END;
  IF denied <> 7 THEN RAISE EXCEPTION 'anon tiene permisos de más (% de 7 bloqueados)', denied; END IF;
  RAISE NOTICE '✅ anon: solo check_email_exists_and_confirmed';
END $$;

RESET ROLE;
DO $$ BEGIN RAISE NOTICE '✅ TODOS LOS TESTS DE GRANTS PASARON'; END $$;
ROLLBACK;
