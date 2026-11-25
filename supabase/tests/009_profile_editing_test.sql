-- =====================================================
-- Test: edición de perfil y configuración (017_profile_editing.sql)
-- =====================================================
-- E1: los clientes no escriben en profiles (ni el dueño); sí leen
-- E2: elegir el @usuario por primera vez es libre y no inicia el plazo
-- E3: cambiarlo inicia el plazo; otro cambio dentro del plazo → P0010 con la
--     fecha en DETAIL (también para service_role)
-- E4: el plazo sale de moderation_settings; pasado el plazo se puede
-- E5: nadie fija username_changed_at a mano (ni para saltarse el límite)
-- E6: cambiar otros campos no toca el plazo
-- E7: user_settings se crea al registrarse; el dueño la lee y cambia solo
--     las preferencias; no ve ni cambia la de otro; anon nada
-- E8: privacy_level inválido → rechazado
-- E9: borrar la cuenta borra su configuración
-- E10: bucket avatars público, 2 MB, solo imágenes
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/009_profile_editing_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

-- Con triggers: crean profiles (005) y user_settings (017)
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('d1000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','e1@t.co'),
 ('d1000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','e2@t.co');

-- E1
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"d1000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
DO $$
BEGIN
  PERFORM 1 FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001';

  BEGIN
    UPDATE profiles SET bio = 'sin moderar' WHERE id = auth.uid();
    RAISE EXCEPTION 'E1: el dueño pudo escribir su perfil directo';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    UPDATE profiles SET avatar_url = 'https://evil.example/x.png' WHERE id = auth.uid();
    RAISE EXCEPTION 'E1: el dueño pudo poner cualquier avatar_url';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    DELETE FROM profiles WHERE id = auth.uid();
    RAISE EXCEPTION 'E1: el dueño pudo borrar su perfil directo';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    INSERT INTO profiles (id) VALUES (gen_random_uuid());
    RAISE EXCEPTION 'E1: authenticated pudo insertar perfiles';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'E1 ok';
END $$;
RESET ROLE;

-- E2: primera elección (como service_role, igual que update-profile)
SET LOCAL ROLE service_role;
UPDATE profiles SET username = 'e1_primero' WHERE id = 'd1000000-0000-4000-8000-000000000001';
DO $$
BEGIN
  IF (SELECT username_changed_at FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001') IS NOT NULL THEN
    RAISE EXCEPTION 'E2: la primera elección inició el plazo';
  END IF;
  RAISE NOTICE 'E2 ok';
END $$;

-- E3: cambio → plazo; segundo cambio dentro del plazo → error
UPDATE profiles SET username = 'e1_segundo' WHERE id = 'd1000000-0000-4000-8000-000000000001';
DO $$
DECLARE
  v_detail TEXT;
BEGIN
  IF (SELECT username_changed_at FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001')
     < now() - interval '1 minute' THEN
    RAISE EXCEPTION 'E3: el cambio no registró la fecha';
  END IF;

  BEGIN
    UPDATE profiles SET username = 'e1_tercero' WHERE id = 'd1000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'E3: permitió un segundo cambio dentro del plazo';
  EXCEPTION WHEN SQLSTATE 'P0010' THEN
    GET STACKED DIAGNOSTICS v_detail = PG_EXCEPTION_DETAIL;
  END;
  IF v_detail::timestamptz < now() + interval '29 days' THEN
    RAISE EXCEPTION 'E3: DETAIL no trae la fecha de disponibilidad (%)', v_detail;
  END IF;
  RAISE NOTICE 'E3 ok';
END $$;

-- E4: plazo configurable; pasado el plazo se puede
RESET ROLE;
UPDATE moderation_settings SET value = 0 WHERE key = 'username_change_cooldown_days';
SET LOCAL ROLE service_role;
UPDATE profiles SET username = 'e1_tercero' WHERE id = 'd1000000-0000-4000-8000-000000000001';
RESET ROLE;
UPDATE moderation_settings SET value = 30 WHERE key = 'username_change_cooldown_days';
DO $$
BEGIN
  IF (SELECT username FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001') <> 'e1_tercero' THEN
    RAISE EXCEPTION 'E4: con plazo 0 no permitió el cambio';
  END IF;
  RAISE NOTICE 'E4 ok';
END $$;

-- E5: no se puede fijar la fecha a mano
SET LOCAL ROLE service_role;
UPDATE profiles SET username_changed_at = now() - interval '1 year'
WHERE id = 'd1000000-0000-4000-8000-000000000001';
DO $$
BEGIN
  IF (SELECT username_changed_at FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001')
     < now() - interval '1 day' THEN
    RAISE EXCEPTION 'E5: se pudo mover la fecha del último cambio';
  END IF;

  BEGIN
    UPDATE profiles SET username = 'e1_cuarto', username_changed_at = now() - interval '1 year'
    WHERE id = 'd1000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'E5: fijar la fecha en el mismo UPDATE saltó el límite';
  EXCEPTION WHEN SQLSTATE 'P0010' THEN NULL;
  END;
  RAISE NOTICE 'E5 ok';
END $$;

-- E6: otros campos no tocan el plazo
DO $$
DECLARE
  v_before TIMESTAMPTZ;
BEGIN
  SELECT username_changed_at INTO v_before FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001';
  UPDATE profiles SET bio = 'nueva bio', display_name = 'E1' WHERE id = 'd1000000-0000-4000-8000-000000000001';
  IF (SELECT username_changed_at FROM profiles WHERE id = 'd1000000-0000-4000-8000-000000000001')
     IS DISTINCT FROM v_before THEN
    RAISE EXCEPTION 'E6: cambiar la bio movió el plazo del @usuario';
  END IF;
  RAISE NOTICE 'E6 ok';
END $$;
RESET ROLE;

-- E7: user_settings
DO $$
BEGIN
  IF (SELECT count(*) FROM user_settings
      WHERE user_id IN ('d1000000-0000-4000-8000-000000000001','d1000000-0000-4000-8000-000000000002')) <> 2 THEN
    RAISE EXCEPTION 'E7: no se creó la configuración al registrarse';
  END IF;
  IF (SELECT privacy_level FROM user_settings WHERE user_id = 'd1000000-0000-4000-8000-000000000001') <> 'public'
     OR (SELECT show_email FROM user_settings WHERE user_id = 'd1000000-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION 'E7: valores por defecto incorrectos';
  END IF;
END $$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"d1000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
DO $$
DECLARE
  v_rows INT;
BEGIN
  UPDATE user_settings SET privacy_level = 'private', push_notifications = FALSE
  WHERE user_id = auth.uid();
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'E7: el dueño no pudo cambiar su configuración'; END IF;

  IF (SELECT count(*) FROM user_settings) <> 1 THEN
    RAISE EXCEPTION 'E7: el usuario ve configuraciones ajenas';
  END IF;

  UPDATE user_settings SET privacy_level = 'private'
  WHERE user_id = 'd1000000-0000-4000-8000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'E7: cambió la configuración de otro usuario'; END IF;

  BEGIN
    UPDATE user_settings SET user_id = 'd1000000-0000-4000-8000-000000000002' WHERE user_id = auth.uid();
    RAISE EXCEPTION 'E7: pudo cambiar el user_id de su configuración';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    INSERT INTO user_settings (user_id) VALUES (gen_random_uuid());
    RAISE EXCEPTION 'E7: pudo insertar configuraciones';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    DELETE FROM user_settings WHERE user_id = auth.uid();
    RAISE EXCEPTION 'E7: pudo borrar su configuración';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- E8
  BEGIN
    UPDATE user_settings SET privacy_level = 'todos' WHERE user_id = auth.uid();
    RAISE EXCEPTION 'E8: aceptó un privacy_level inválido';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE 'E7/E8 authenticated ok';
END $$;
RESET ROLE;

SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims','{"role":"anon"}',true);
DO $$
BEGIN
  BEGIN
    PERFORM 1 FROM user_settings;
    RAISE EXCEPTION 'E7: anon pudo leer configuraciones';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'E7 anon ok';
END $$;
RESET ROLE;

DO $$
BEGIN
  IF (SELECT privacy_level FROM user_settings WHERE user_id = 'd1000000-0000-4000-8000-000000000001') <> 'private'
     OR (SELECT push_notifications FROM user_settings WHERE user_id = 'd1000000-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION 'E7: el cambio del dueño no se guardó';
  END IF;
  IF (SELECT privacy_level FROM user_settings WHERE user_id = 'd1000000-0000-4000-8000-000000000002') <> 'public' THEN
    RAISE EXCEPTION 'E7: se tocó la configuración de otro usuario';
  END IF;
END $$;

-- E9
DELETE FROM auth.users WHERE id = 'd1000000-0000-4000-8000-000000000002';
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM user_settings WHERE user_id = 'd1000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'E9: quedó la configuración de la cuenta borrada';
  END IF;
  RAISE NOTICE 'E9 ok';
END $$;

-- E10
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets
    WHERE id = 'avatars' AND public AND file_size_limit = 2097152
      AND allowed_mime_types @> ARRAY['image/jpeg','image/png','image/webp']
      AND NOT allowed_mime_types && ARRAY['image/svg+xml','image/gif']
  ) THEN
    RAISE EXCEPTION 'E10: bucket avatars mal configurado';
  END IF;
  RAISE NOTICE 'E10 ok';
END $$;

ROLLBACK;
