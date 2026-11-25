-- =====================================================
-- Test: seguidores, solicitudes y bloqueos (018_social_follows_blocks.sql)
-- =====================================================
-- S1: seguir cuenta pública → al instante; idempotente; no a sí mismo;
--     usuario inexistente → CS404
-- S2: cuenta privada → solicitud; aceptar crea el seguimiento; rechazar no;
--     solo el destinatario responde; cancelar (unfollow) borra la solicitud
-- S3: privada → pública acepta las pendientes
-- S4: quitar seguidor; dejar de seguir
-- S5: bloquear corta seguimiento y solicitudes en ambos sentidos; ninguno
--     puede volver a seguir; desbloquear no restaura nada
-- S6: public_gossips: autor visible solo en chismes con perfil (NULL en
--     anónimos, incluso los propios); con bloqueo (ambos sentidos) no se ven
--     los chismes con perfil del otro, pero SÍ sus anónimos
-- S7: cuenta privada: sus chismes con perfil solo para seguidores (feed
--     Popular, búsqueda, vista); los anónimos sí
-- S8: feed Siguiendo: solo chismes con perfil de quienes sigo, nunca
--     anónimos, paginación
-- S9: get_user_profile (contadores, relación, privada, bloqueos)
-- S10: listas de seguidores/seguidos (privada, bloqueos, paginación),
--      solicitudes y bloqueados
-- S11: search_users (prefijo, sin bloqueados ni yo, comodines literales)
-- S12: perfiles ocultos entre bloqueados (tabla profiles)
-- S13: sin acceso directo de clientes a las tablas; anon sin funciones;
--      helpers internos no expuestos
-- S14: borrar la cuenta borra seguimientos, solicitudes y bloqueos
-- S15: límite de seguimientos (moderation_settings): solo cuentan los nuevos;
--      superado → CS429; seguir/dejar de seguir en bucle también cuenta
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/010_social_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

-- A=ana B=beto C=caro D=dani (con triggers: crean profiles y user_settings)
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('a5000000-0000-4000-8000-00000000000a','00000000-0000-0000-0000-000000000000','authenticated','authenticated','ana@t.co'),
 ('a5000000-0000-4000-8000-00000000000b','00000000-0000-0000-0000-000000000000','authenticated','authenticated','beto@t.co'),
 ('a5000000-0000-4000-8000-00000000000c','00000000-0000-0000-0000-000000000000','authenticated','authenticated','caro@t.co'),
 ('a5000000-0000-4000-8000-00000000000d','00000000-0000-0000-0000-000000000000','authenticated','authenticated','dani@t.co');
UPDATE profiles SET username = 'ana_10', display_name = 'Ana Pérez', avatar_url = 'https://x/a.jpg' WHERE id = 'a5000000-0000-4000-8000-00000000000a';
UPDATE profiles SET username = 'beto', display_name = 'Beto' WHERE id = 'a5000000-0000-4000-8000-00000000000b';
UPDATE profiles SET username = 'caro', display_name = 'Carolina' WHERE id = 'a5000000-0000-4000-8000-00000000000c';
UPDATE profiles SET username = 'dani', display_name = 'Dani 100%' WHERE id = 'a5000000-0000-4000-8000-00000000000d';

-- Chismes publicados (sin triggers para fijar created_by/fechas)
SET LOCAL session_replication_role = replica;
INSERT INTO cities (id, region_id, country_id, name, lat, lon)
  VALUES ('t-social','co-antioquia','CO','Socialandia',6.25,-75.56) ON CONFLICT DO NOTHING;
INSERT INTO gossips (id, country_id, region_id, city_id, subject, content, published_as, created_by, status, moderation_status, visibility, created_at) VALUES
 ('a6000000-0000-4000-8000-0000000000b1','CO','co-antioquia','t-social','zq beto perfil 1','c','profile','a5000000-0000-4000-8000-00000000000b','published','approved','public', now() - interval '3 hours'),
 ('a6000000-0000-4000-8000-0000000000b2','CO','co-antioquia','t-social','zq beto perfil 2','c','profile','a5000000-0000-4000-8000-00000000000b','published','approved','public', now() - interval '2 hours'),
 ('a6000000-0000-4000-8000-0000000000b3','CO','co-antioquia','t-social','zq beto anonimo','c','anonymous','a5000000-0000-4000-8000-00000000000b','published','approved','public', now() - interval '1 hour'),
 ('a6000000-0000-4000-8000-0000000000b4','CO','co-antioquia','t-social','zq beto borrador','c','profile','a5000000-0000-4000-8000-00000000000b','draft','pending','private', now()),
 ('a6000000-0000-4000-8000-0000000000c1','CO','co-antioquia','t-social','zq caro perfil','c','profile','a5000000-0000-4000-8000-00000000000c','published','approved','public', now() - interval '30 minutes'),
 ('a6000000-0000-4000-8000-0000000000a1','CO','co-antioquia','t-social','zq ana anonimo','c','anonymous','a5000000-0000-4000-8000-00000000000a','published','approved','public', now() - interval '10 minutes');
SET LOCAL session_replication_role = origin;

-- Cambiar de usuario dentro del rol authenticated
CREATE FUNCTION pg_temp.as_user(u TEXT) RETURNS VOID LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
$$;
GRANT EXECUTE ON FUNCTION pg_temp.as_user(TEXT) TO authenticated;

SET LOCAL ROLE authenticated;

-- S1
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$
DECLARE
  r TEXT;
BEGIN
  r := follow_user('a5000000-0000-4000-8000-00000000000c');
  IF r <> 'following' THEN RAISE EXCEPTION 'S1: seguir pública devolvió %', r; END IF;
  r := follow_user('a5000000-0000-4000-8000-00000000000c');
  IF r <> 'following' THEN RAISE EXCEPTION 'S1: seguir dos veces devolvió %', r; END IF;

  BEGIN
    PERFORM follow_user(auth.uid());
    RAISE EXCEPTION 'S1: pudo seguirse a sí misma';
  EXCEPTION WHEN SQLSTATE 'CS400' THEN NULL;
  END;

  BEGIN
    PERFORM follow_user(gen_random_uuid());
    RAISE EXCEPTION 'S1: pudo seguir a un usuario inexistente';
  EXCEPTION WHEN SQLSTATE 'CS404' THEN NULL;
  END;
  RAISE NOTICE 'S1 ok';
END $$;

-- S2: beto pasa a privada (el dueño cambia su configuración)
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000b');
UPDATE user_settings SET privacy_level = 'private' WHERE user_id = auth.uid();

SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$
BEGIN
  IF follow_user('a5000000-0000-4000-8000-00000000000b') <> 'requested' THEN
    RAISE EXCEPTION 'S2: seguir privada no creó solicitud';
  END IF;
  IF (get_user_profile('a5000000-0000-4000-8000-00000000000b')->>'is_requested')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'S2: el perfil no muestra la solicitud';
  END IF;
  -- ana no puede aceptar su propia solicitud
  BEGIN
    PERFORM respond_follow_request('a5000000-0000-4000-8000-00000000000a', TRUE);
    RAISE EXCEPTION 'S2: aceptó una solicitud que no era para ella';
  EXCEPTION WHEN SQLSTATE 'CS404' THEN NULL;
  END;
END $$;

SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000c');
DO $$ BEGIN
  IF follow_user('a5000000-0000-4000-8000-00000000000b') <> 'requested' THEN
    RAISE EXCEPTION 'S2: caro no quedó en solicitud';
  END IF;
END $$;

SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
DO $$ BEGIN
  PERFORM follow_user('a5000000-0000-4000-8000-00000000000b');
  PERFORM unfollow_user('a5000000-0000-4000-8000-00000000000b'); -- cancela
END $$;

SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000b');
DO $$
DECLARE
  reqs JSON := get_follow_requests();
BEGIN
  IF json_array_length(reqs) <> 2 THEN
    RAISE EXCEPTION 'S2: beto ve % solicitudes (esperaba 2: la de dani se canceló)', json_array_length(reqs);
  END IF;
  IF reqs->0->'user'->>'username' IS NULL THEN
    RAISE EXCEPTION 'S2: la solicitud no trae los datos del usuario';
  END IF;
  PERFORM respond_follow_request('a5000000-0000-4000-8000-00000000000a', TRUE);
  PERFORM respond_follow_request('a5000000-0000-4000-8000-00000000000c', FALSE);
  IF json_array_length(get_follow_requests()) <> 0 THEN
    RAISE EXCEPTION 'S2: quedaron solicitudes tras responder';
  END IF;
  IF (get_user_profile(auth.uid())->>'followers_count')::int <> 1 THEN
    RAISE EXCEPTION 'S2: beto debería tener 1 seguidor (ana)';
  END IF;
  RAISE NOTICE 'S2 ok';
END $$;

-- S3: dani pide, beto vuelve a pública → dani lo sigue
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
SELECT follow_user('a5000000-0000-4000-8000-00000000000b');
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000b');
UPDATE user_settings SET privacy_level = 'public' WHERE user_id = auth.uid();
DO $$ BEGIN
  IF (get_user_profile(auth.uid())->>'followers_count')::int <> 2 THEN
    RAISE EXCEPTION 'S3: al volver pública no se aceptó la solicitud pendiente';
  END IF;
  IF json_array_length(get_follow_requests()) <> 0 THEN
    RAISE EXCEPTION 'S3: quedaron solicitudes';
  END IF;
  RAISE NOTICE 'S3 ok';
END $$;

-- S4: beto quita a dani; dani ya no lo sigue. Dani sigue a beto de nuevo y
-- deja de seguirlo.
DO $$ BEGIN
  PERFORM remove_follower('a5000000-0000-4000-8000-00000000000d');
  IF (get_user_profile(auth.uid())->>'followers_count')::int <> 1 THEN
    RAISE EXCEPTION 'S4: quitar seguidor no funcionó';
  END IF;
END $$;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
DO $$ BEGIN
  PERFORM follow_user('a5000000-0000-4000-8000-00000000000b');
  PERFORM unfollow_user('a5000000-0000-4000-8000-00000000000b');
  IF (get_user_profile('a5000000-0000-4000-8000-00000000000b')->>'is_following')::boolean THEN
    RAISE EXCEPTION 'S4: dejar de seguir no funcionó';
  END IF;
  RAISE NOTICE 'S4 ok';
END $$;

-- Estado: ana → caro, ana → beto
-- S5: caro sigue a ana; ana bloquea a caro
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000c');
SELECT follow_user('a5000000-0000-4000-8000-00000000000a');
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$ BEGIN
  PERFORM block_user('a5000000-0000-4000-8000-00000000000c');
  PERFORM block_user('a5000000-0000-4000-8000-00000000000c'); -- idempotente
  IF (get_user_profile(auth.uid())->>'followers_count')::int <> 0
     OR (get_user_profile(auth.uid())->>'following_count')::int <> 1 THEN
    RAISE EXCEPTION 'S5: el bloqueo no cortó el seguimiento en ambos sentidos';
  END IF;
  BEGIN
    PERFORM follow_user('a5000000-0000-4000-8000-00000000000c');
    RAISE EXCEPTION 'S5: pudo seguir a quien bloqueó';
  EXCEPTION WHEN SQLSTATE 'CS404' THEN NULL;
  END;
  BEGIN
    PERFORM block_user(auth.uid());
    RAISE EXCEPTION 'S5: pudo bloquearse a sí misma';
  EXCEPTION WHEN SQLSTATE 'CS400' THEN NULL;
  END;
END $$;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000c');
DO $$ BEGIN
  BEGIN
    PERFORM follow_user('a5000000-0000-4000-8000-00000000000a');
    RAISE EXCEPTION 'S5: la bloqueada pudo volver a seguir';
  EXCEPTION WHEN SQLSTATE 'CS404' THEN NULL;
  END;
  RAISE NOTICE 'S5 ok (bloqueo)';
END $$;

-- S6: ana bloqueó a caro
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000c1') THEN
    RAISE EXCEPTION 'S6: ana ve el chisme con perfil de caro (bloqueada)';
  END IF;
  IF (SELECT author_username FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000b1') <> 'beto'
     OR (SELECT author_display_name FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000b1') <> 'Beto' THEN
    RAISE EXCEPTION 'S6: el chisme con perfil no trae el autor';
  END IF;
  IF (SELECT author_username FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000b3') IS NOT NULL
     OR (SELECT created_by FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000b3') IS NOT NULL THEN
    RAISE EXCEPTION 'S6: un anónimo ajeno revela el autor';
  END IF;
  IF (SELECT author_username FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000a1') IS NOT NULL THEN
    RAISE EXCEPTION 'S6: el anónimo propio muestra autor';
  END IF;
  IF EXISTS (SELECT 1 FROM search_gossips('zq caro')) THEN
    RAISE EXCEPTION 'S6: la búsqueda muestra el chisme con perfil de la bloqueada';
  END IF;
  IF EXISTS (
    SELECT 1 FROM json_array_elements(get_popular_feed('t-social','co-antioquia','CO', 50)->'data') e
    WHERE e->>'id' = 'a6000000-0000-4000-8000-0000000000c1'
  ) THEN
    RAISE EXCEPTION 'S6: el feed Popular muestra el chisme de la bloqueada';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM json_array_elements(get_popular_feed('t-social','co-antioquia','CO', 50)->'data') e
    WHERE e->>'id' = 'a6000000-0000-4000-8000-0000000000b1' AND e->>'author_username' = 'beto'
  ) THEN
    RAISE EXCEPTION 'S6: el feed Popular no trae el autor';
  END IF;
END $$;
-- La bloqueada tampoco ve los chismes con perfil de ana... pero sí su anónimo
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000c');
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000a1') THEN
    RAISE EXCEPTION 'S6: filtrar el anónimo de ana revelaría la autora';
  END IF;
  RAISE NOTICE 'S6 ok';
END $$;

-- S7: beto privada otra vez. Ana lo sigue; dani no.
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000b');
UPDATE user_settings SET privacy_level = 'private' WHERE user_id = auth.uid();
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public_gossips WHERE id IN ('a6000000-0000-4000-8000-0000000000b1','a6000000-0000-4000-8000-0000000000b2')) THEN
    RAISE EXCEPTION 'S7: un no seguidor ve chismes con perfil de una cuenta privada';
  END IF;
  IF EXISTS (SELECT 1 FROM search_gossips('zq beto perfil')) THEN
    RAISE EXCEPTION 'S7: la búsqueda muestra chismes de una cuenta privada';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000b3') THEN
    RAISE EXCEPTION 'S7: el anónimo de la cuenta privada desapareció (revelaría el autor)';
  END IF;
  IF (get_user_profile('a5000000-0000-4000-8000-00000000000b')->>'can_view_content')::boolean
     OR get_user_profile('a5000000-0000-4000-8000-00000000000b')->>'gossips_count' IS NOT NULL THEN
    RAISE EXCEPTION 'S7: el perfil privado muestra contenido a un no seguidor';
  END IF;
  IF (get_user_gossips('a5000000-0000-4000-8000-00000000000b')->'data')::text <> '[]' THEN
    RAISE EXCEPTION 'S7: get_user_gossips muestra chismes de una privada';
  END IF;
  BEGIN
    PERFORM get_follow_list('a5000000-0000-4000-8000-00000000000b', 'followers');
    RAISE EXCEPTION 'S7: un no seguidor ve la lista de seguidores de una privada';
  EXCEPTION WHEN SQLSTATE 'CS404' THEN NULL;
  END;
END $$;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$ BEGIN
  IF (SELECT COUNT(*) FROM public_gossips WHERE id IN ('a6000000-0000-4000-8000-0000000000b1','a6000000-0000-4000-8000-0000000000b2')) <> 2 THEN
    RAISE EXCEPTION 'S7: la seguidora no ve los chismes de la cuenta privada';
  END IF;
  RAISE NOTICE 'S7 ok';
END $$;

-- S8: feed Siguiendo de ana (sigue a beto; caro bloqueada)
DO $$
DECLARE
  p1 JSON := get_following_feed(1);
  p2 JSON;
  ids TEXT[];
BEGIN
  SELECT array_agg(e->>'id') INTO ids FROM json_array_elements(get_following_feed(50)->'data') e;
  IF ids IS DISTINCT FROM ARRAY['a6000000-0000-4000-8000-0000000000b2','a6000000-0000-4000-8000-0000000000b1'] THEN
    RAISE EXCEPTION 'S8: feed Siguiendo = % (esperaba los 2 con perfil de beto, sin anónimo ni borrador)', ids;
  END IF;
  IF (p1->>'has_more')::boolean IS NOT TRUE OR p1->'next_cursor' IS NULL THEN
    RAISE EXCEPTION 'S8: paginación sin has_more/next_cursor';
  END IF;
  p2 := get_following_feed(1, (p1->'next_cursor'->>'created_at')::timestamptz, (p1->'next_cursor'->>'id')::uuid);
  IF p2->'data'->0->>'id' <> 'a6000000-0000-4000-8000-0000000000b1' OR (p2->>'has_more')::boolean THEN
    RAISE EXCEPTION 'S8: segunda página incorrecta: %', p2;
  END IF;
  IF p1->'data'->0->>'author_username' <> 'beto' THEN
    RAISE EXCEPTION 'S8: el feed Siguiendo no trae el autor';
  END IF;
  RAISE NOTICE 'S8 ok';
END $$;

-- S9: perfiles vistos por ana
DO $$
DECLARE
  pb JSON := get_user_profile('a5000000-0000-4000-8000-00000000000b');
  pc JSON := get_user_profile('a5000000-0000-4000-8000-00000000000c');
BEGIN
  IF (pb->>'is_private')::boolean IS NOT TRUE OR (pb->>'is_following')::boolean IS NOT TRUE
     OR (pb->>'can_view_content')::boolean IS NOT TRUE OR (pb->>'gossips_count')::int <> 2
     OR (pb->>'is_me')::boolean THEN
    RAISE EXCEPTION 'S9: perfil de beto incorrecto: %', pb;
  END IF;
  IF (pc->>'has_blocked')::boolean IS NOT TRUE OR pc->>'bio' IS NOT NULL OR (pc::jsonb ? 'followers_count') THEN
    RAISE EXCEPTION 'S9: perfil bloqueado muestra de más: %', pc;
  END IF;
  IF get_user_profile(gen_random_uuid()) IS NOT NULL THEN
    RAISE EXCEPTION 'S9: perfil inexistente no es NULL';
  END IF;
END $$;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000c');
DO $$ BEGIN
  IF get_user_profile('a5000000-0000-4000-8000-00000000000a') IS NOT NULL THEN
    RAISE EXCEPTION 'S9: la bloqueada ve el perfil de quien la bloqueó';
  END IF;
  RAISE NOTICE 'S9 ok';
END $$;

-- S10: listas. Dani y caro siguen a ana... caro está bloqueada (no puede).
-- dani → ana, beto → ana (beto privada no afecta seguir a ana, que es pública)
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
SELECT follow_user('a5000000-0000-4000-8000-00000000000a');
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000b');
SELECT follow_user('a5000000-0000-4000-8000-00000000000a');
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
DO $$
DECLARE
  l1 JSON := get_follow_list('a5000000-0000-4000-8000-00000000000a', 'followers', 1);
  l2 JSON;
  everyone JSON := get_follow_list('a5000000-0000-4000-8000-00000000000a', 'followers');
BEGIN
  IF json_array_length(everyone->'data') <> 2 THEN
    RAISE EXCEPTION 'S10: ana debería tener 2 seguidores: %', everyone;
  END IF;
  IF (l1->>'has_more')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'S10: paginación de la lista sin has_more';
  END IF;
  l2 := get_follow_list('a5000000-0000-4000-8000-00000000000a', 'followers', 1,
    (l1->'next_cursor'->>'created_at')::timestamptz, (l1->'next_cursor'->>'id')::uuid);
  IF json_array_length(l2->'data') <> 1 OR l2->'data'->0->>'id' = l1->'data'->0->>'id' THEN
    RAISE EXCEPTION 'S10: segunda página repetida o vacía';
  END IF;
  IF json_array_length(get_follow_list('a5000000-0000-4000-8000-00000000000a', 'following')->'data') <> 1 THEN
    RAISE EXCEPTION 'S10: ana sigue a 1 (beto)';
  END IF;
  BEGIN
    PERFORM get_follow_list('a5000000-0000-4000-8000-00000000000a', 'amigos');
    RAISE EXCEPTION 'S10: aceptó un tipo de lista inválido';
  EXCEPTION WHEN SQLSTATE 'CS400' THEN NULL;
  END;
END $$;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$
DECLARE
  b JSON := get_blocked_users();
BEGIN
  IF json_array_length(b) <> 1 OR b->0->>'username' <> 'caro' THEN
    RAISE EXCEPTION 'S10: bloqueados de ana = %', b;
  END IF;
  RAISE NOTICE 'S10 ok';
END $$;

-- S11: búsqueda de usuarios (ana)
DO $$
DECLARE
  r JSON;
BEGIN
  r := search_users('@be');
  IF json_array_length(r) <> 1 OR r->0->>'username' <> 'beto' OR (r->0->>'is_following')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'S11: buscar @be = %', r;
  END IF;
  IF json_array_length(search_users('caro')) <> 0 THEN
    RAISE EXCEPTION 'S11: la búsqueda muestra a una bloqueada';
  END IF;
  IF json_array_length(search_users('ana')) <> 0 THEN
    RAISE EXCEPTION 'S11: la búsqueda me incluye a mí';
  END IF;
  IF json_array_length(search_users('a')) <> 0 THEN
    RAISE EXCEPTION 'S11: buscó con 1 carácter';
  END IF;
  -- '%' y '_' son literales: '0%' solo coincide con 'Dani 100%'
  r := search_users('0%');
  IF json_array_length(r) <> 1 OR r->0->>'username' <> 'dani' THEN
    RAISE EXCEPTION 'S11: comodín %% no literal: %', r;
  END IF;
  IF json_array_length(search_users('__')) <> 0 THEN
    RAISE EXCEPTION 'S11: comodín _ no literal';
  END IF;
  RAISE NOTICE 'S11 ok';
END $$;

-- S12: profiles entre bloqueados
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM profiles WHERE id = 'a5000000-0000-4000-8000-00000000000c') THEN
    RAISE EXCEPTION 'S12: ana lee el perfil de la bloqueada en profiles';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'S12: ana no lee su propio perfil';
  END IF;
END $$;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000c');
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM profiles WHERE id = 'a5000000-0000-4000-8000-00000000000a') THEN
    RAISE EXCEPTION 'S12: la bloqueada lee el perfil de quien la bloqueó';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = 'a5000000-0000-4000-8000-00000000000b') THEN
    RAISE EXCEPTION 'S12: caro no lee perfiles no bloqueados';
  END IF;
  RAISE NOTICE 'S12 ok';
END $$;

-- S5 (cont.): desbloquear no restaura nada
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000a');
DO $$ BEGIN
  PERFORM unblock_user('a5000000-0000-4000-8000-00000000000c');
  IF (get_user_profile('a5000000-0000-4000-8000-00000000000c')->>'is_followed_by')::boolean THEN
    RAISE EXCEPTION 'S5: desbloquear restauró el seguimiento';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public_gossips WHERE id = 'a6000000-0000-4000-8000-0000000000c1') THEN
    RAISE EXCEPTION 'S5: tras desbloquear no ve el chisme';
  END IF;
  RAISE NOTICE 'S5 ok (desbloqueo)';
END $$;

-- S13
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['user_follows','follow_requests','user_blocks'] LOOP
    BEGIN
      EXECUTE format('SELECT 1 FROM %I', t);
      RAISE EXCEPTION 'S13: authenticated lee %', t;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
    BEGIN
      EXECUTE format('DELETE FROM %I', t);
      RAISE EXCEPTION 'S13: authenticated borra en %', t;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
  END LOOP;
  BEGIN
    INSERT INTO user_follows (follower_id, following_id)
    VALUES ('a5000000-0000-4000-8000-00000000000c', 'a5000000-0000-4000-8000-00000000000a');
    RAISE EXCEPTION 'S13: authenticated insertó un seguimiento ajeno';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM users_blocked('a5000000-0000-4000-8000-00000000000b', 'a5000000-0000-4000-8000-00000000000c');
    RAISE EXCEPTION 'S13: users_blocked expuesto (bloqueos entre terceros)';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM can_view_user_content('a5000000-0000-4000-8000-00000000000d', 'a5000000-0000-4000-8000-00000000000b');
    RAISE EXCEPTION 'S13: can_view_user_content expuesto (relaciones entre terceros)';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
  BEGIN
    PERFORM follow_user('a5000000-0000-4000-8000-00000000000a');
    RAISE EXCEPTION 'S13: anon ejecutó follow_user';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM search_users('beto');
    RAISE EXCEPTION 'S13: anon ejecutó search_users';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'S13 ok';
END $$;
RESET ROLE;

-- S15: límite por hora = lo que dani ya usó en este test + 2
RESET ROLE;
UPDATE moderation_settings SET value = 2 + (
  SELECT COUNT(*) FROM rate_limits
  WHERE user_id = 'a5000000-0000-4000-8000-00000000000d' AND action_type = 'follow_user'
) WHERE key = 'follow_hourly_limit';
SET LOCAL ROLE authenticated;
SELECT pg_temp.as_user('a5000000-0000-4000-8000-00000000000d');
DO $$
BEGIN
  -- Repetir un seguimiento existente (ana) no gasta cupo
  PERFORM follow_user('a5000000-0000-4000-8000-00000000000a');
  PERFORM follow_user('a5000000-0000-4000-8000-00000000000a');
  -- Bucle seguir / dejar de seguir a caro: gasta los 2 cupos que quedan
  PERFORM follow_user('a5000000-0000-4000-8000-00000000000c');
  PERFORM unfollow_user('a5000000-0000-4000-8000-00000000000c');
  PERFORM follow_user('a5000000-0000-4000-8000-00000000000c');
  PERFORM unfollow_user('a5000000-0000-4000-8000-00000000000c');
  BEGIN
    PERFORM follow_user('a5000000-0000-4000-8000-00000000000c');
    RAISE EXCEPTION 'S15: superó el límite por hora';
  EXCEPTION WHEN SQLSTATE 'CS429' THEN NULL;
  END;
  IF (get_user_profile('a5000000-0000-4000-8000-00000000000c')->>'is_following')::boolean THEN
    RAISE EXCEPTION 'S15: el seguimiento rechazado quedó guardado';
  END IF;
  BEGIN
    INSERT INTO rate_limits (user_id, action_type) VALUES (auth.uid(), 'follow_user');
    RAISE EXCEPTION 'S15: el cliente escribió en rate_limits';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM reserve_follow_slot(auth.uid());
    RAISE EXCEPTION 'S15: reserve_follow_slot expuesto';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'S15 ok';
END $$;
RESET ROLE;

-- S14: borrar a beto (sigue a ana; ana lo sigue)
DELETE FROM auth.users WHERE id = 'a5000000-0000-4000-8000-00000000000b';
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM user_follows WHERE 'a5000000-0000-4000-8000-00000000000b' IN (follower_id, following_id))
     OR EXISTS (SELECT 1 FROM follow_requests WHERE 'a5000000-0000-4000-8000-00000000000b' IN (requester_id, target_id))
     OR EXISTS (SELECT 1 FROM user_blocks WHERE 'a5000000-0000-4000-8000-00000000000b' IN (blocker_id, blocked_id)) THEN
    RAISE EXCEPTION 'S14: quedaron relaciones de la cuenta borrada';
  END IF;
  RAISE NOTICE 'S14 ok';
END $$;

ROLLBACK;
