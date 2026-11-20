-- =====================================================
-- Test: GRANTs de la API (anon / authenticated / service_role)
-- =====================================================
-- El proyecto remoto NO da privilegios por defecto en tablas/funciones
-- nuevas: sin GRANT explícito todo falla con "permission denied". El Supabase
-- local SÍ los da, así que para que este test sea realista hay que correrlo
-- sobre una base local que imite al remoto (ver supabase/tests/README.md).
--
-- Recorre cada camino real de acceso con el rol que usa:
--   - app (authenticated): feed, búsquedas, location, perfil, reportes
--   - Edge Functions con service_role: log-error, report-gossip, delete-account
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
  PERFORM 1 FROM gossips LIMIT 1;
  PERFORM 1 FROM countries, regions, cities LIMIT 1;
  PERFORM 1 FROM feed_settings LIMIT 1;
  UPDATE profiles SET display_name = 'Test' WHERE id = auth.uid();
  -- report-gossip usa el JWT del usuario para crear/leer su reporte
  INSERT INTO gossip_reports (gossip_id, reported_by, reason)
    VALUES ('a0000000-0000-0000-0000-000000000001', auth.uid(), 'spam');
  PERFORM 1 FROM gossip_reports WHERE reported_by = auth.uid();
  RAISE NOTICE '✅ authenticated: feed, búsquedas, location, perfil y reportes';
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
  IF denied <> 4 THEN RAISE EXCEPTION 'authenticated tiene permisos de más (% de 4 bloqueados)', denied; END IF;
  RAISE NOTICE '✅ authenticated: bloqueado en gossips (INSERT), error_logs, rate_limits, feed_settings (UPDATE)';
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
  -- report-gossip (admin) + moderación
  UPDATE gossips SET report_count = report_count + 1 WHERE id = 'a0000000-0000-0000-0000-000000000001';
  PERFORM 1 FROM gossip_reports_summary LIMIT 1;
  -- delete-account
  DELETE FROM gossip_reports WHERE reported_by = '11111111-1111-1111-1111-111111111111';
  DELETE FROM rate_limits WHERE user_id = '11111111-1111-1111-1111-111111111111';
  UPDATE profiles SET display_name = NULL WHERE id = '11111111-1111-1111-1111-111111111111';
  DELETE FROM gossips WHERE created_by = '11111111-1111-1111-1111-111111111111';
  -- moderate-gossip (validación de ubicación)
  PERFORM 1 FROM countries, regions, cities LIMIT 1;
  RAISE NOTICE '✅ service_role: log-error, report-gossip, delete-account, moderate-gossip';
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
  IF denied <> 4 THEN RAISE EXCEPTION 'anon tiene permisos de más (% de 4 bloqueados)', denied; END IF;
  RAISE NOTICE '✅ anon: solo check_email_exists_and_confirmed';
END $$;

RESET ROLE;
DO $$ BEGIN RAISE NOTICE '✅ TODOS LOS TESTS DE GRANTS PASARON'; END $$;
ROLLBACK;
