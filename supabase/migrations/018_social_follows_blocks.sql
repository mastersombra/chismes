-- =====================================================
-- 018: Seguidores, solicitudes, bloqueos y autor visible
-- =====================================================
-- 1. SEGUIR: libre para cuentas públicas; si `user_settings.privacy_level`
--    es 'private', se crea una solicitud que el dueño acepta o rechaza. Al
--    volver la cuenta pública, las solicitudes pendientes se aceptan solas.
--
-- 2. BLOQUEAR: corta el seguimiento y las solicitudes en ambos sentidos e
--    impide volver a seguir. Ninguno de los dos ve el perfil ni los chismes
--    CON PERFIL del otro. Los anónimos NO se filtran: ocultarlos dejaría
--    deducir quién los escribió.
--
-- 3. CUENTA PRIVADA: sus chismes con perfil solo los ven sus seguidores (y
--    ella). Su perfil muestra nombre, foto, bio y contadores; las listas de
--    seguidores/seguidos y sus chismes, solo a seguidores.
--
-- 4. AUTOR: `public_gossips` agrega @usuario, nombre y foto del autor SOLO
--    en chismes publicados con perfil (NULL en anónimos, incluso los propios).
--
-- 5. ACCESO: los clientes no leen ni escriben las tablas nuevas. Todo pasa
--    por funciones SECURITY DEFINER que usan auth.uid() (nunca un user_id
--    que mande el cliente).
--
-- 6. LÍMITE ANTI-SPAM: seguir/solicitar cuenta en `rate_limits`
--    (action_type 'follow_user'), solo cuando se crea un seguimiento o una
--    solicitud nueva. Límites en moderation_settings (follow_hourly_limit,
--    follow_daily_limit). Superado → SQLSTATE CS429.
--
-- Eliminación de cuenta: todo se borra en cascada con auth.users.
-- =====================================================

INSERT INTO moderation_settings (key, value, description) VALUES
  ('follow_hourly_limit', 60, 'Máximo de seguimientos/solicitudes nuevos por usuario por hora'),
  ('follow_daily_limit', 300, 'Máximo de seguimientos/solicitudes nuevos por usuario por día')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- 1. TABLAS
-- =====================================================

CREATE TABLE user_follows (
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id <> following_id)
);

CREATE INDEX idx_user_follows_following ON user_follows (following_id, created_at DESC);
CREATE INDEX idx_user_follows_follower_created ON user_follows (follower_id, created_at DESC);

COMMENT ON TABLE user_follows IS
  'Quién sigue a quién. Solo se escribe con follow_user / respond_follow_request / unfollow_user / remove_follower / block_user';

CREATE TABLE follow_requests (
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (requester_id, target_id),
  CHECK (requester_id <> target_id)
);

CREATE INDEX idx_follow_requests_target ON follow_requests (target_id, created_at DESC);

COMMENT ON TABLE follow_requests IS
  'Solicitudes pendientes para seguir cuentas privadas. Se borran al aceptar, rechazar o cancelar';

CREATE TABLE user_blocks (
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

CREATE INDEX idx_user_blocks_blocked ON user_blocks (blocked_id);

COMMENT ON TABLE user_blocks IS
  'Bloqueos. Afecta a ambos: ninguno ve el perfil ni los chismes con perfil del otro';

ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE follow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;
-- Sin políticas: los clientes no acceden directo (solo vía funciones).
REVOKE ALL ON TABLE user_follows, follow_requests, user_blocks FROM anon, authenticated;
GRANT ALL ON TABLE user_follows, follow_requests, user_blocks TO service_role;

-- =====================================================
-- 2. HELPERS
-- =====================================================

-- ¿Hay un bloqueo (en cualquier sentido) entre a y b?
CREATE OR REPLACE FUNCTION public.users_blocked(a UUID, b UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_blocks
    WHERE (blocker_id = a AND blocked_id = b)
       OR (blocker_id = b AND blocked_id = a)
  );
$$;

REVOKE ALL ON FUNCTION public.users_blocked(UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.users_blocked(UUID, UUID) TO service_role;

-- Para la política de `profiles` (corre como el usuario): solo compara con
-- auth.uid(), así no sirve para consultar bloqueos entre terceros.
CREATE OR REPLACE FUNCTION public.is_blocked_with_me(other UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL
     AND other IS DISTINCT FROM auth.uid()
     AND public.users_blocked(auth.uid(), other);
$$;

REVOKE ALL ON FUNCTION public.is_blocked_with_me(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_blocked_with_me(UUID) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.is_private_account(p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT privacy_level = 'private' FROM user_settings WHERE user_id = p_user),
    FALSE
  );
$$;

REVOKE ALL ON FUNCTION public.is_private_account(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_private_account(UUID) TO service_role;

-- ¿Puede `viewer` ver el contenido (chismes con perfil, listas) de `owner`?
CREATE OR REPLACE FUNCTION public.can_view_user_content(viewer UUID, owner UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT viewer = owner OR (
    NOT public.users_blocked(viewer, owner)
    AND (
      NOT public.is_private_account(owner)
      OR EXISTS (
        SELECT 1 FROM user_follows
        WHERE follower_id = viewer AND following_id = owner
      )
    )
  );
$$;

REVOKE ALL ON FUNCTION public.can_view_user_content(UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_view_user_content(UUID, UUID) TO service_role;

-- Versión para la vista public_gossips: las funciones de una vista se
-- ejecutan con los permisos de quien consulta, así que necesita EXECUTE para
-- authenticated. Solo responde por auth.uid(): no sirve para averiguar
-- bloqueos o seguimientos entre terceros.
CREATE OR REPLACE FUNCTION public.can_i_view_user_content(owner UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL AND public.can_view_user_content(auth.uid(), owner);
$$;

REVOKE ALL ON FUNCTION public.can_i_view_user_content(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_i_view_user_content(UUID) TO authenticated, service_role;

-- Datos públicos de un usuario para listas (JSON).
CREATE OR REPLACE FUNCTION public.social_user_json(p_user UUID, p_viewer UUID)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT json_build_object(
    'id', p.id,
    'username', p.username,
    'display_name', p.display_name,
    'avatar_url', p.avatar_url,
    'is_following', EXISTS (
      SELECT 1 FROM user_follows f
      WHERE f.follower_id = p_viewer AND f.following_id = p.id
    )
  )
  FROM profiles p
  WHERE p.id = p_user;
$$;

REVOKE ALL ON FUNCTION public.social_user_json(UUID, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.social_user_json(UUID, UUID) TO service_role;

-- =====================================================
-- 3. PERFILES: ocultos entre usuarios bloqueados
-- =====================================================

DROP POLICY IF EXISTS "profiles_select_all" ON profiles;

CREATE POLICY "profiles_select_not_blocked"
  ON profiles FOR SELECT
  USING (NOT public.is_blocked_with_me(id));

-- =====================================================
-- 4. public_gossips: autor visible + bloqueos + cuentas privadas
-- =====================================================
-- Mismas columnas que en 001 (en el mismo orden) + las del autor al final.
-- Reglas extra para chismes AJENOS publicados con perfil:
--   - no se ven si hay bloqueo entre autor y lector
--   - si el autor tiene cuenta privada, solo los ven sus seguidores
-- Los anónimos no pasan por esas reglas (no revelan al autor).

CREATE OR REPLACE VIEW public_gossips
WITH (security_invoker = false, security_barrier = true)
AS
SELECT
  g.id,
  g.country_id,
  g.region_id,
  g.city_id,
  g.subject,
  g.content,
  g.audio_url,
  g.image_url,
  g.thumbnail_url,
  g.published_as,
  g.status,
  g.moderation_status,
  g.visibility,
  g.is_trending_national,
  CASE
    WHEN g.published_as = 'anonymous' AND g.created_by IS DISTINCT FROM auth.uid()
      THEN NULL
    ELSE g.created_by
  END AS created_by,
  g.created_at,
  g.modified_at,
  g.view_count,
  g.like_count,
  g.comment_count,
  g.share_count,
  g.deleted_at,
  p.username AS author_username,
  p.display_name AS author_display_name,
  p.avatar_url AS author_avatar_url
FROM gossips g
LEFT JOIN profiles p
  ON g.published_as = 'profile' AND p.id = g.created_by
WHERE
  g.created_by = auth.uid()
  OR (
    g.status = 'published'
    AND g.moderation_status = 'approved'
    AND g.visibility = 'public'
    AND g.deleted_at IS NULL
    AND (
      g.published_as = 'anonymous'
      OR public.can_i_view_user_content(g.created_by)
    )
  );

COMMENT ON VIEW public_gossips IS
'Lectura de chismes para clientes. Oculta el autor de los anónimos (salvo para su autor), agrega autor (@usuario, nombre, foto) solo en chismes con perfil, y filtra chismes con perfil de usuarios bloqueados o de cuentas privadas que no sigo. La tabla gossips no es accesible para anon/authenticated.';

REVOKE ALL ON TABLE public_gossips FROM anon, authenticated;
GRANT SELECT ON TABLE public_gossips TO authenticated, service_role;

-- =====================================================
-- 5. ACCIONES
-- =====================================================

-- Reserva un cupo de 'follow_user' o lanza CS429 (DETAIL: 'hourly'|'daily').
-- Lock por usuario: dos llamadas simultáneas no superan el límite.
CREATE OR REPLACE FUNCTION public.reserve_follow_slot(p_user UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hourly NUMERIC;
  v_daily NUMERIC;
BEGIN
  SELECT
    COALESCE(MAX(value) FILTER (WHERE key = 'follow_hourly_limit'), 60),
    COALESCE(MAX(value) FILTER (WHERE key = 'follow_daily_limit'), 300)
  INTO v_hourly, v_daily
  FROM moderation_settings;

  PERFORM pg_advisory_xact_lock(hashtext('follow_user:' || p_user::text));

  IF (SELECT COUNT(*) FROM rate_limits
      WHERE user_id = p_user AND action_type = 'follow_user'
        AND created_at > NOW() - INTERVAL '1 hour') >= v_hourly THEN
    RAISE EXCEPTION 'follow_rate_limited' USING ERRCODE = 'CS429', DETAIL = 'hourly';
  END IF;
  IF (SELECT COUNT(*) FROM rate_limits
      WHERE user_id = p_user AND action_type = 'follow_user'
        AND created_at > NOW() - INTERVAL '1 day') >= v_daily THEN
    RAISE EXCEPTION 'follow_rate_limited' USING ERRCODE = 'CS429', DETAIL = 'daily';
  END IF;

  INSERT INTO rate_limits (user_id, action_type) VALUES (p_user, 'follow_user');
END;
$$;

REVOKE ALL ON FUNCTION public.reserve_follow_slot(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_follow_slot(UUID) TO service_role;
-- Errores con SQLSTATE propio para que la app los distinga:
--   CS401 sin sesión · CS400 consigo mismo · CS404 usuario no disponible
--   (no existe o hay bloqueo: no se distingue a propósito) · CS429 límite
--   de seguimientos (DETAIL 'hourly' | 'daily')

-- Seguir: 'following' (cuenta pública o ya lo seguía) | 'requested' (privada)
CREATE OR REPLACE FUNCTION public.follow_user(p_target UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  IF p_target IS NULL OR p_target = v_me THEN
    RAISE EXCEPTION 'cannot_follow_self' USING ERRCODE = 'CS400';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_target)
     OR public.users_blocked(v_me, p_target) THEN
    RAISE EXCEPTION 'user_not_available' USING ERRCODE = 'CS404';
  END IF;

  IF EXISTS (SELECT 1 FROM user_follows WHERE follower_id = v_me AND following_id = p_target) THEN
    RETURN 'following';
  END IF;

  IF public.is_private_account(p_target) THEN
    IF EXISTS (SELECT 1 FROM follow_requests WHERE requester_id = v_me AND target_id = p_target) THEN
      RETURN 'requested';
    END IF;
    PERFORM public.reserve_follow_slot(v_me);
    INSERT INTO follow_requests (requester_id, target_id)
    VALUES (v_me, p_target)
    ON CONFLICT DO NOTHING;
    RETURN 'requested';
  END IF;

  PERFORM public.reserve_follow_slot(v_me);
  INSERT INTO user_follows (follower_id, following_id)
  VALUES (v_me, p_target)
  ON CONFLICT DO NOTHING;
  RETURN 'following';
END;
$$;

-- Dejar de seguir (también cancela una solicitud pendiente)
CREATE OR REPLACE FUNCTION public.unfollow_user(p_target UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  DELETE FROM user_follows WHERE follower_id = v_me AND following_id = p_target;
  DELETE FROM follow_requests WHERE requester_id = v_me AND target_id = p_target;
END;
$$;

-- Aceptar o rechazar una solicitud que me hicieron
CREATE OR REPLACE FUNCTION public.respond_follow_request(p_requester UUID, p_accept BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;

  DELETE FROM follow_requests WHERE requester_id = p_requester AND target_id = v_me;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request_not_found' USING ERRCODE = 'CS404';
  END IF;

  IF p_accept AND NOT public.users_blocked(v_me, p_requester) THEN
    INSERT INTO user_follows (follower_id, following_id)
    VALUES (p_requester, v_me)
    ON CONFLICT DO NOTHING;
  END IF;
END;
$$;

-- Quitar a alguien de mis seguidores
CREATE OR REPLACE FUNCTION public.remove_follower(p_follower UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  DELETE FROM user_follows WHERE follower_id = p_follower AND following_id = v_me;
END;
$$;

-- Bloquear: corta seguimiento y solicitudes en ambos sentidos
CREATE OR REPLACE FUNCTION public.block_user(p_target UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  IF p_target IS NULL OR p_target = v_me THEN
    RAISE EXCEPTION 'cannot_block_self' USING ERRCODE = 'CS400';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_target) THEN
    RAISE EXCEPTION 'user_not_available' USING ERRCODE = 'CS404';
  END IF;

  INSERT INTO user_blocks (blocker_id, blocked_id)
  VALUES (v_me, p_target)
  ON CONFLICT DO NOTHING;

  DELETE FROM user_follows
  WHERE (follower_id = v_me AND following_id = p_target)
     OR (follower_id = p_target AND following_id = v_me);
  DELETE FROM follow_requests
  WHERE (requester_id = v_me AND target_id = p_target)
     OR (requester_id = p_target AND target_id = v_me);
END;
$$;

CREATE OR REPLACE FUNCTION public.unblock_user(p_target UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  DELETE FROM user_blocks WHERE blocker_id = v_me AND blocked_id = p_target;
END;
$$;

-- =====================================================
-- 6. LECTURAS
-- =====================================================

-- Perfil de un usuario visto por mí. NULL si no existe o si ÉL me bloqueó.
-- Si YO lo bloqueé: solo id/@usuario/nombre/foto + has_blocked (para poder
-- desbloquear), sin bio ni contadores.
CREATE OR REPLACE FUNCTION public.get_user_profile(p_user UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_profile profiles%ROWTYPE;
  v_is_private BOOLEAN;
  v_blocked_by_me BOOLEAN;
  v_can_view BOOLEAN;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;

  SELECT * INTO v_profile FROM profiles WHERE id = p_user;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM user_blocks WHERE blocker_id = p_user AND blocked_id = v_me) THEN
    RETURN NULL;
  END IF;

  v_blocked_by_me := EXISTS (
    SELECT 1 FROM user_blocks WHERE blocker_id = v_me AND blocked_id = p_user
  );

  IF v_blocked_by_me THEN
    RETURN json_build_object(
      'id', v_profile.id,
      'username', v_profile.username,
      'display_name', v_profile.display_name,
      'avatar_url', v_profile.avatar_url,
      'has_blocked', TRUE
    );
  END IF;

  v_is_private := public.is_private_account(p_user);
  v_can_view := public.can_view_user_content(v_me, p_user);

  RETURN json_build_object(
    'id', v_profile.id,
    'username', v_profile.username,
    'display_name', v_profile.display_name,
    'avatar_url', v_profile.avatar_url,
    'bio', v_profile.bio,
    'is_me', p_user = v_me,
    'is_private', v_is_private,
    'can_view_content', v_can_view,
    'has_blocked', FALSE,
    'is_following', EXISTS (
      SELECT 1 FROM user_follows WHERE follower_id = v_me AND following_id = p_user
    ),
    'is_followed_by', EXISTS (
      SELECT 1 FROM user_follows WHERE follower_id = p_user AND following_id = v_me
    ),
    'is_requested', EXISTS (
      SELECT 1 FROM follow_requests WHERE requester_id = v_me AND target_id = p_user
    ),
    'followers_count', (SELECT COUNT(*) FROM user_follows WHERE following_id = p_user),
    'following_count', (SELECT COUNT(*) FROM user_follows WHERE follower_id = p_user),
    -- Chismes con perfil publicados (nunca cuenta anónimos)
    'gossips_count', CASE WHEN v_can_view THEN (
      SELECT COUNT(*) FROM gossips g
      WHERE g.created_by = p_user
        AND g.published_as = 'profile'
        AND g.status = 'published'
        AND g.moderation_status = 'approved'
        AND g.visibility = 'public'
        AND g.deleted_at IS NULL
    ) ELSE NULL END
  );
END;
$$;

-- Seguidores / seguidos de un usuario. Cursor: (created_at, id).
-- Requiere poder ver su contenido (ver can_view_user_content). Omite a los
-- usuarios con los que YO tengo un bloqueo.
CREATE OR REPLACE FUNCTION public.get_follow_list(
  p_user UUID,
  p_kind TEXT,                       -- 'followers' | 'following'
  page_size INT DEFAULT 30,
  cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_size INT := LEAST(GREATEST(COALESCE(page_size, 30), 1), 100);
  v_rows JSON;
  v_has_more BOOLEAN;
  v_last_created_at TIMESTAMPTZ;
  v_last_id UUID;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  IF p_kind NOT IN ('followers', 'following') THEN
    RAISE EXCEPTION 'invalid_kind' USING ERRCODE = 'CS400';
  END IF;
  IF NOT public.can_view_user_content(v_me, p_user) THEN
    RAISE EXCEPTION 'user_not_available' USING ERRCODE = 'CS404';
  END IF;

  WITH page AS (
    SELECT x.user_id, x.created_at
    FROM (
      SELECT
        CASE WHEN p_kind = 'followers' THEN f.follower_id ELSE f.following_id END AS user_id,
        f.created_at
      FROM user_follows f
      WHERE (p_kind = 'followers' AND f.following_id = p_user)
         OR (p_kind = 'following' AND f.follower_id = p_user)
    ) x
    WHERE NOT public.users_blocked(v_me, x.user_id)
      AND (cursor_created_at IS NULL
           OR x.created_at < cursor_created_at
           OR (x.created_at = cursor_created_at AND x.user_id > cursor_id))
    ORDER BY x.created_at DESC, x.user_id ASC
    LIMIT v_size + 1
  ),
  numbered AS (
    SELECT page.*, ROW_NUMBER() OVER (ORDER BY created_at DESC, user_id ASC) AS rn
    FROM page
  )
  SELECT
    COALESCE(json_agg(public.social_user_json(n.user_id, v_me) ORDER BY n.rn)
      FILTER (WHERE n.rn <= v_size), '[]'::json),
    COUNT(*) > v_size,
    MAX(n.created_at) FILTER (WHERE n.rn = v_size),
    (array_agg(n.user_id) FILTER (WHERE n.rn = v_size))[1]
  INTO v_rows, v_has_more, v_last_created_at, v_last_id
  FROM numbered n;

  RETURN json_build_object(
    'data', v_rows,
    'has_more', v_has_more,
    'next_cursor', CASE WHEN v_has_more THEN
      json_build_object('created_at', v_last_created_at, 'id', v_last_id)
    ELSE NULL END
  );
END;
$$;

-- Solicitudes que me hicieron (más recientes primero, máx. 100)
CREATE OR REPLACE FUNCTION public.get_follow_requests()
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  RETURN (
    SELECT COALESCE(json_agg(
      json_build_object(
        'user', public.social_user_json(r.requester_id, v_me),
        'created_at', r.created_at
      ) ORDER BY r.created_at DESC
    ), '[]'::json)
    FROM (
      SELECT * FROM follow_requests
      WHERE target_id = v_me
      ORDER BY created_at DESC
      LIMIT 100
    ) r
  );
END;
$$;

-- Usuarios que bloqueé (para desbloquear)
CREATE OR REPLACE FUNCTION public.get_blocked_users()
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  RETURN (
    SELECT COALESCE(json_agg(
      json_build_object(
        'id', p.id,
        'username', p.username,
        'display_name', p.display_name,
        'avatar_url', p.avatar_url,
        'is_following', FALSE
      ) ORDER BY b.created_at DESC
    ), '[]'::json)
    FROM user_blocks b
    JOIN profiles p ON p.id = b.blocked_id
    WHERE b.blocker_id = v_me
  );
END;
$$;

-- Buscar usuarios por @usuario o nombre (mín. 2 caracteres, máx. 50
-- resultados). Omite bloqueados (ambos sentidos) y a mí. Coincidencias que
-- empiezan por el texto primero.
CREATE OR REPLACE FUNCTION public.search_users(search_query TEXT, result_limit INT DEFAULT 20)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_q TEXT;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;

  -- Comodines de LIKE escapados: el texto se busca literal
  v_q := lower(trim(both FROM COALESCE(search_query, '')));
  v_q := ltrim(v_q, '@');
  IF char_length(v_q) < 2 THEN
    RETURN '[]'::json;
  END IF;
  v_q := replace(replace(replace(v_q, '\', '\\'), '%', '\%'), '_', '\_');

  RETURN (
    SELECT COALESCE(json_agg(public.social_user_json(u.id, v_me) ORDER BY u.rank, u.username), '[]'::json)
    FROM (
      SELECT p.id, p.username,
        CASE
          WHEN lower(p.username) LIKE v_q || '%' THEN 1
          WHEN lower(p.display_name) LIKE v_q || '%' THEN 2
          ELSE 3
        END AS rank
      FROM profiles p
      WHERE p.id <> v_me
        AND p.username IS NOT NULL
        AND (lower(p.username) LIKE '%' || v_q || '%'
             OR lower(p.display_name) LIKE '%' || v_q || '%')
        AND NOT public.users_blocked(v_me, p.id)
      ORDER BY rank, p.username
      LIMIT LEAST(GREATEST(COALESCE(result_limit, 20), 1), 50)
    ) u
  );
END;
$$;

-- =====================================================
-- 7. FEEDS
-- =====================================================

-- Página cronológica (created_at DESC, id ASC) de chismes CON PERFIL
-- publicados, con el mismo JSON que el feed Popular (data, has_more,
-- next_cursor). p_author = un usuario, o NULL = los que sigo.
-- SECURITY INVOKER: lee public_gossips con los permisos del usuario (respeta
-- bloqueos y cuentas privadas). Nunca incluye anónimos.
CREATE OR REPLACE FUNCTION public.profile_gossips_page(
  p_author UUID,
  page_size INT,
  cursor_created_at TIMESTAMPTZ,
  cursor_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_size INT := LEAST(GREATEST(COALESCE(page_size, 20), 1), 50);
  result_json JSON;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;

  WITH page AS (
    SELECT g.*
    FROM public_gossips g
    WHERE g.published_as = 'profile'
      AND g.status = 'published'
      AND g.moderation_status = 'approved'
      AND g.visibility = 'public'
      AND g.deleted_at IS NULL
      AND (
        (p_author IS NOT NULL AND g.created_by = p_author)
        OR (p_author IS NULL AND g.created_by IN (SELECT public.my_following_ids()))
      )
      AND (cursor_created_at IS NULL
           OR g.created_at < cursor_created_at
           OR (g.created_at = cursor_created_at AND g.id > cursor_id))
    ORDER BY g.created_at DESC, g.id ASC
    LIMIT v_size + 1
  ),
  numbered AS (
    SELECT page.*, ROW_NUMBER() OVER (ORDER BY created_at DESC, id ASC) AS rn
    FROM page
  )
  SELECT json_build_object(
    'data', COALESCE(json_agg(
      json_build_object(
        'id', n.id,
        'subject', n.subject,
        'content', n.content,
        'country_id', n.country_id,
        'region_id', n.region_id,
        'city_id', n.city_id,
        'city_name', ci.name,
        'created_at', n.created_at,
        'likes', COALESCE(n.like_count, 0),
        'comments', COALESCE(n.comment_count, 0),
        'shares', COALESCE(n.share_count, 0),
        'published_as', n.published_as,
        'created_by', n.created_by,
        'author_username', n.author_username,
        'author_display_name', n.author_display_name,
        'author_avatar_url', n.author_avatar_url,
        'image_url', n.image_url,
        'score', 0,
        'is_from_my_city', NULL,
        'is_trending', FALSE
      ) ORDER BY n.rn
    ) FILTER (WHERE n.rn <= v_size), '[]'::json),
    'has_more', COUNT(*) > v_size,
    'next_cursor', CASE
      WHEN COUNT(*) > v_size THEN json_build_object(
        'created_at', MAX(n.created_at) FILTER (WHERE n.rn = v_size),
        'id', (array_agg(n.id) FILTER (WHERE n.rn = v_size))[1]
      )
      ELSE NULL
    END
  ) INTO result_json
  FROM numbered n
  LEFT JOIN cities ci ON ci.id = n.city_id;

  RETURN result_json;
END;
$$;

-- A quién sigo (para profile_gossips_page, que corre como el usuario)
CREATE OR REPLACE FUNCTION public.my_following_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT following_id FROM user_follows WHERE follower_id = auth.uid();
$$;

-- Chismes con perfil de un usuario (su pantalla de perfil)
CREATE OR REPLACE FUNCTION public.get_user_gossips(
  p_user UUID,
  page_size INT DEFAULT 20,
  cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT CASE WHEN p_user IS NULL THEN NULL
    ELSE public.profile_gossips_page(p_user, page_size, cursor_created_at, cursor_id)
  END;
$$;

-- Feed "Siguiendo": chismes con perfil de quienes sigo, más recientes
-- primero. NUNCA anónimos: seguir a alguien no puede revelar sus anónimos.
-- Reemplaza la versión de 008, que recibía el user_id del cliente.
CREATE OR REPLACE FUNCTION public.get_following_feed(
  page_size INT DEFAULT 20,
  cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT public.profile_gossips_page(NULL, page_size, cursor_created_at, cursor_id);
$$;

-- =====================================================
-- 8. PRIVADA → PÚBLICA: aceptar solicitudes pendientes
-- =====================================================

CREATE OR REPLACE FUNCTION public.accept_pending_requests_on_public()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.privacy_level = 'private' AND NEW.privacy_level = 'public' THEN
    INSERT INTO user_follows (follower_id, following_id, created_at)
    SELECT r.requester_id, r.target_id, NOW()
    FROM follow_requests r
    WHERE r.target_id = NEW.user_id
      AND NOT public.users_blocked(r.requester_id, r.target_id)
    ON CONFLICT DO NOTHING;
    DELETE FROM follow_requests WHERE target_id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_pending_requests_on_public() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER on_privacy_level_public
  AFTER UPDATE OF privacy_level ON user_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.accept_pending_requests_on_public();

-- =====================================================
-- 9. PERMISOS DE LAS FUNCIONES DE LA API
-- =====================================================

DO $$
DECLARE
  fn TEXT;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'public.follow_user(UUID)',
    'public.unfollow_user(UUID)',
    'public.respond_follow_request(UUID, BOOLEAN)',
    'public.remove_follower(UUID)',
    'public.block_user(UUID)',
    'public.unblock_user(UUID)',
    'public.get_user_profile(UUID)',
    'public.get_follow_list(UUID, TEXT, INT, TIMESTAMPTZ, UUID)',
    'public.get_follow_requests()',
    'public.get_blocked_users()',
    'public.search_users(TEXT, INT)',
    'public.get_user_gossips(UUID, INT, TIMESTAMPTZ, UUID)',
    'public.get_following_feed(INT, TIMESTAMPTZ, UUID)',
    'public.my_following_ids()',
    'public.profile_gossips_page(UUID, INT, TIMESTAMPTZ, UUID)'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role', fn);
  END LOOP;
END;
$$;
