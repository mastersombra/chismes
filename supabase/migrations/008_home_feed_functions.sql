-- =====================================================
-- Home Feed Functions
-- =====================================================
-- Funciones para el feed del home screen:
-- 0. feed_settings + helpers: pesos/umbrales editables sin deploy
-- 1. get_popular_feed: Feed principal por anillos de cercanía
-- 2. get_following_feed: Feed de personas que sigo
-- 3. check_new_gossips: Verificar nuevos chismes
--
-- Todas con soporte para cursor-based pagination (performance)
-- =====================================================

-- =====================================================
-- CONFIGURACIÓN DEL FEED: feed_settings
-- =====================================================
-- Pesos y umbrales del ranking, editables sin deploy ni release de la app
-- (SQL Editor o service_role). Si falta una clave, la función usa el default.
-- =====================================================

CREATE TABLE feed_settings (
  key TEXT PRIMARY KEY,
  value NUMERIC NOT NULL,
  description TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE feed_settings ENABLE ROW LEVEL SECURITY;

-- Lectura abierta: las funciones del feed son SECURITY INVOKER y la leen
-- con el rol del cliente. Sin políticas de escritura: solo service_role.
CREATE POLICY "Cualquiera puede leer feed_settings"
  ON feed_settings FOR SELECT
  USING (true);

-- GRANT explícito: el proyecto remoto NO da privilegios por defecto a los
-- roles de la API en tablas nuevas (solo TRUNCATE/REFERENCES/TRIGGER).
-- Sin esto get_popular_feed falla con "permission denied for table feed_settings".
GRANT SELECT ON TABLE feed_settings TO authenticated, service_role;

INSERT INTO feed_settings (key, value, description) VALUES
  ('weight_city', 100, 'Cercanía: mismo city_id que el usuario'),
  ('weight_region', 60, 'Cercanía: misma región (departamento) que el usuario'),
  ('weight_country', 25, 'Cercanía: mismo país que el usuario'),
  ('weight_global', 0, 'Cercanía: otro país'),
  ('trending_percentile', 0.95, 'Percentil de velocity (ventana reciente) desde el que un chisme es tendencia'),
  ('trending_window_hours', 48, 'Ventana en horas para calcular el percentil de tendencia'),
  ('trending_min_velocity', 2, 'Velocity mínima (interacciones ponderadas/hora) para ser tendencia; evita tendencias con 0 interacciones'),
  ('trending_bonus', 30, 'Puntos extra en el score para chismes en tendencia'),
  ('backfill_min_items', 20, 'Si hay menos chismes cercanos (país o más cerca) que esto, se rellena con chismes de otros países');

-- =====================================================
-- HELPERS DE RANKING
-- =====================================================

-- Interacciones ponderadas: likes*1 + comentarios*2 + compartidos*3
CREATE OR REPLACE FUNCTION feed_engagement(g gossips)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(g.like_count, 0) * 1.0
       + COALESCE(g.comment_count, 0) * 2.0
       + COALESCE(g.share_count, 0) * 3.0;
$$;

-- Edad en horas
CREATE OR REPLACE FUNCTION feed_age_hours(g gossips)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  SELECT GREATEST(EXTRACT(EPOCH FROM (NOW() - g.created_at)) / 3600.0, 0);
$$;

-- Velocity: interacciones ponderadas por hora (+2h para no premiar lo recién publicado)
CREATE OR REPLACE FUNCTION feed_velocity(g gossips)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  SELECT feed_engagement(g) / (feed_age_hours(g) + 2.0);
$$;

-- =====================================================
-- FUNCIÓN: get_popular_feed
-- =====================================================
-- Feed principal por "anillos de cercanía" + popularidad + frescura.
--
-- Cercanía (feed_settings): ciudad 100, región 60, país 25, otro país 0.
-- Ubicación opcional: la app manda ciudad/región/país si los tiene; sin
-- ciudad manda solo el país (región del teléfono). Sin nada: feed global.
--
-- Score (0-100 por componente):
--   40% cercanía
--   25% popularidad  = min(100, 20 * ln(1 + interacciones ponderadas))
--   20% velocity     = min(100, 25 * ln(1 + interacciones/hora))
--   15% frescura     = 100 / (1 + horas * 0.05)
--   + trending_bonus si es tendencia
-- (escala logarítmica: 100k likes no aplastan todo; 200 likes en otra
--  ciudad pueden superar un chisme local sin interacción)
--
-- Tendencia RELATIVA: velocity >= percentil 95 de la ventana reciente
-- (y >= trending_min_velocity). Funciona igual con 10 que con 10M usuarios.
--
-- Qué entra:
--   - Mi país, región o ciudad: siempre
--   - Otros países: solo si son tendencia
--   - Relleno: si hay menos de backfill_min_items cercanos (o el usuario no
--     tiene ninguna ubicación), entra todo, ordenado por score
--
-- Privacidad: created_by es NULL en chismes anónimos (salvo para su autor).
-- Paginación: cursor (score, id). Retorna JSON con data, has_more, next_cursor.
-- =====================================================

CREATE OR REPLACE FUNCTION get_popular_feed(
  user_city_id TEXT DEFAULT NULL,
  user_region_id TEXT DEFAULT NULL,
  user_country_id TEXT DEFAULT NULL,
  page_size INT DEFAULT 20,
  cursor_score NUMERIC DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  result_json JSON;
  w_city NUMERIC;
  w_region NUMERIC;
  w_country NUMERIC;
  w_global NUMERIC;
  trend_percentile NUMERIC;
  trend_window NUMERIC;
  trend_min NUMERIC;
  trend_bonus NUMERIC;
  backfill_min NUMERIC;
  trend_threshold NUMERIC;
  nearby_count INT;
  include_far BOOLEAN;
  has_location BOOLEAN :=
    user_city_id IS NOT NULL OR user_region_id IS NOT NULL OR user_country_id IS NOT NULL;
BEGIN
  -- 1. Configuración (default si falta la clave)
  SELECT
    COALESCE(MAX(value) FILTER (WHERE key = 'weight_city'), 100),
    COALESCE(MAX(value) FILTER (WHERE key = 'weight_region'), 60),
    COALESCE(MAX(value) FILTER (WHERE key = 'weight_country'), 25),
    COALESCE(MAX(value) FILTER (WHERE key = 'weight_global'), 0),
    COALESCE(MAX(value) FILTER (WHERE key = 'trending_percentile'), 0.95),
    COALESCE(MAX(value) FILTER (WHERE key = 'trending_window_hours'), 48),
    COALESCE(MAX(value) FILTER (WHERE key = 'trending_min_velocity'), 2),
    COALESCE(MAX(value) FILTER (WHERE key = 'trending_bonus'), 30),
    COALESCE(MAX(value) FILTER (WHERE key = 'backfill_min_items'), 20)
  INTO w_city, w_region, w_country, w_global,
       trend_percentile, trend_window, trend_min, trend_bonus, backfill_min
  FROM feed_settings;

  -- 2. Umbral de tendencia relativo (percentil de velocity reciente)
  SELECT GREATEST(
    COALESCE(
      percentile_cont(trend_percentile::DOUBLE PRECISION)
        WITHIN GROUP (ORDER BY feed_velocity(g)),
      0
    ),
    trend_min
  )
  INTO trend_threshold
  FROM gossips g
  WHERE
    g.status = 'published' AND
    g.moderation_status = 'approved' AND
    g.visibility = 'public' AND
    g.deleted_at IS NULL AND
    g.created_at > NOW() - make_interval(hours => trend_window::INT);

  -- 3. ¿Hay suficientes chismes cercanos? Si no, se rellena con lejanos
  IF has_location THEN
    SELECT COUNT(*)
    INTO nearby_count
    FROM gossips g
    WHERE
      g.status = 'published' AND
      g.moderation_status = 'approved' AND
      g.visibility = 'public' AND
      g.deleted_at IS NULL AND
      (g.city_id = user_city_id OR
       g.region_id = user_region_id OR
       g.country_id = user_country_id);
    include_far := nearby_count < backfill_min;
  ELSE
    include_far := TRUE;
  END IF;

  -- 4. Ranking + paginación
  WITH candidates AS (
    SELECT
      g.*,
      CASE
        WHEN user_city_id IS NOT NULL AND g.city_id = user_city_id THEN 'city'
        WHEN user_region_id IS NOT NULL AND g.region_id = user_region_id THEN 'region'
        WHEN user_country_id IS NOT NULL AND g.country_id = user_country_id THEN 'country'
        ELSE 'global'
      END AS proximity,
      feed_engagement(g) AS engagement,
      feed_velocity(g) AS velocity,
      feed_age_hours(g) AS age_hours
    FROM gossips g
    WHERE
      g.status = 'published' AND
      g.moderation_status = 'approved' AND
      g.visibility = 'public' AND
      g.deleted_at IS NULL
  ),
  ranked_gossips AS (
    SELECT
      c.*,
      (c.velocity >= trend_threshold) AS is_trending,
      (
        CASE c.proximity
          WHEN 'city' THEN w_city
          WHEN 'region' THEN w_region
          WHEN 'country' THEN w_country
          ELSE w_global
        END * 0.40 +
        LEAST(100, 20 * ln(1 + c.engagement)) * 0.25 +
        LEAST(100, 25 * ln(1 + c.velocity)) * 0.20 +
        (100.0 / (1.0 + c.age_hours * 0.05)) * 0.15 +
        CASE WHEN c.velocity >= trend_threshold THEN trend_bonus ELSE 0 END
      )::NUMERIC AS score_final
    FROM candidates c
    WHERE
      c.proximity <> 'global' OR
      c.velocity >= trend_threshold OR
      include_far
  ),
  paginated_gossips AS (
    SELECT rg.*
    FROM ranked_gossips rg
    WHERE
      (cursor_score IS NULL OR
       rg.score_final < cursor_score OR
       (rg.score_final = cursor_score AND rg.id > cursor_id))
    ORDER BY rg.score_final DESC, rg.id ASC
    LIMIT page_size + 1  -- +1 para detectar si hay más páginas
  )

  SELECT
    json_build_object(
      'data', COALESCE(json_agg(
        json_build_object(
          'id', pg.id,
          'subject', pg.subject,
          'content', pg.content,
          'country_id', pg.country_id,
          'region_id', pg.region_id,
          'city_id', pg.city_id,
          'city_name', ci.name,
          'created_at', pg.created_at,
          'likes', COALESCE(pg.like_count, 0),
          'comments', COALESCE(pg.comment_count, 0),
          'shares', COALESCE(pg.share_count, 0),
          'published_as', pg.published_as,
          -- Privacidad: no revelar el autor de un chisme anónimo
          'created_by', CASE
            WHEN pg.published_as = 'anonymous' AND pg.created_by IS DISTINCT FROM auth.uid()
              THEN NULL
            ELSE pg.created_by
          END,
          'image_url', pg.image_url,
          'score', pg.score_final,
          'proximity', pg.proximity,
          'is_from_my_city', CASE
            WHEN user_city_id IS NULL THEN NULL
            ELSE pg.city_id = user_city_id
          END,
          'is_trending', pg.is_trending
        )
        ORDER BY pg.score_final DESC, pg.id ASC
      ) FILTER (WHERE rn <= page_size), '[]'::json),
      'has_more', (SELECT COUNT(*) FROM paginated_gossips) > page_size,
      'next_cursor', CASE
        WHEN (SELECT COUNT(*) FROM paginated_gossips) > page_size THEN
          json_build_object(
            'score', (SELECT score_final FROM paginated_gossips ORDER BY score_final DESC, id ASC LIMIT 1 OFFSET page_size - 1),
            'id', (SELECT id FROM paginated_gossips ORDER BY score_final DESC, id ASC LIMIT 1 OFFSET page_size - 1)
          )
        ELSE NULL
      END
    ) INTO result_json
  FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY score_final DESC, id ASC) AS rn
    FROM paginated_gossips
  ) pg
  LEFT JOIN cities ci ON ci.id = pg.city_id;

  RETURN result_json;
END;
$$;

-- Comentario
COMMENT ON FUNCTION get_popular_feed IS
'Feed principal por anillos de cercanía (ciudad/región/país) + popularidad + frescura, con tendencia relativa y relleno. Pesos en feed_settings. Paginación cursor-based.';

-- =====================================================
-- FUNCIÓN: get_following_feed
-- =====================================================
-- Feed de chismes de personas que sigo
-- Ordenado por fecha (más recientes primero)
-- Paginación: Cursor-based (created_at, id)
-- =====================================================

CREATE OR REPLACE FUNCTION get_following_feed(
  current_user_id UUID,
  page_size INT DEFAULT 20,
  cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  result_json JSON;
BEGIN
  WITH paginated_gossips AS (
    SELECT
      g.id,
      g.subject,
      g.content,
      g.city_id,
      g.created_at,
      COALESCE(g.like_count, 0) AS likes,
      COALESCE(g.comment_count, 0) AS comments,
      COALESCE(g.share_count, 0) AS shares,
      g.published_as,
      -- Privacidad: no revelar el autor de un chisme anónimo
      CASE
        WHEN g.published_as = 'anonymous' AND g.created_by IS DISTINCT FROM auth.uid()
          THEN NULL
        ELSE g.created_by
      END AS created_by,
      g.image_url,
      0::NUMERIC AS score,  -- No usamos score en Following
      TRUE AS is_from_my_city,  -- Placeholder
      FALSE AS is_trending  -- Placeholder
    FROM gossips g
    WHERE
      g.status = 'published' AND
      g.moderation_status = 'approved' AND
      (g.visibility = 'public' OR g.visibility = 'followers') AND
      g.deleted_at IS NULL AND
      -- TODO: Filtrar por usuarios que sigo (requiere tabla user_follows)
      -- Por ahora retorna vacío para evitar errores
      FALSE
      AND
      -- Paginación con cursor (created_at, id)
      (cursor_created_at IS NULL OR
       g.created_at < cursor_created_at OR
       (g.created_at = cursor_created_at AND g.id > cursor_id))
    ORDER BY g.created_at DESC, g.id ASC
    LIMIT page_size + 1
  )

  SELECT
    json_build_object(
      'data', COALESCE(json_agg(
        json_build_object(
          'id', pg.id,
          'subject', pg.subject,
          'content', pg.content,
          'city_id', pg.city_id,
          'created_at', pg.created_at,
          'likes', pg.likes,
          'comments', pg.comments,
          'shares', pg.shares,
          'published_as', pg.published_as,
          'created_by', pg.created_by,
          'image_url', pg.image_url,
          'score', pg.score,
          'is_from_my_city', pg.is_from_my_city,
          'is_trending', pg.is_trending
        )
      ) FILTER (WHERE rn <= page_size), '[]'::json),
      'has_more', (SELECT COUNT(*) FROM paginated_gossips) > page_size,
      'next_cursor', CASE
        WHEN (SELECT COUNT(*) FROM paginated_gossips) > page_size THEN
          json_build_object(
            'created_at', (SELECT created_at FROM paginated_gossips ORDER BY created_at DESC, id ASC LIMIT 1 OFFSET page_size - 1),
            'id', (SELECT id FROM paginated_gossips ORDER BY created_at DESC, id ASC LIMIT 1 OFFSET page_size - 1)
          )
        ELSE NULL
      END
    ) INTO result_json
  FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY created_at DESC, id ASC) as rn
    FROM paginated_gossips
  ) pg;

  RETURN result_json;
END;
$$;

-- Comentario
COMMENT ON FUNCTION get_following_feed IS
'Feed de chismes de personas que sigo. Ordenado cronológicamente inverso.';

-- =====================================================
-- FUNCIÓN: check_new_gossips
-- =====================================================
-- Cuenta chismes nuevos desde un timestamp para el banner "X nuevos chismes".
-- Cuenta solo los cercanos (mi ciudad, región o país); sin ubicación, todos.
-- Las tendencias de otros países no disparan el banner (aparecen al recargar).
-- =====================================================

CREATE OR REPLACE FUNCTION check_new_gossips(
  user_city_id TEXT DEFAULT NULL,
  user_region_id TEXT DEFAULT NULL,
  user_country_id TEXT DEFAULT NULL,
  since_timestamp TIMESTAMPTZ DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  new_count INT;
  has_location BOOLEAN :=
    user_city_id IS NOT NULL OR user_region_id IS NOT NULL OR user_country_id IS NOT NULL;
BEGIN
  SELECT COUNT(*)
  INTO new_count
  FROM gossips g
  WHERE
    g.status = 'published' AND
    g.moderation_status = 'approved' AND
    g.visibility = 'public' AND
    g.deleted_at IS NULL AND
    g.created_at > since_timestamp AND
    (
      NOT has_location OR
      g.city_id = user_city_id OR
      g.region_id = user_region_id OR
      g.country_id = user_country_id
    );

  RETURN new_count;
END;
$$;

-- Comentario
COMMENT ON FUNCTION check_new_gossips IS
'Cuenta chismes nuevos cercanos (ciudad/región/país) desde un timestamp. Para banner de actualización.';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================
-- Permitir que usuarios autenticados llamen estas funciones

GRANT EXECUTE ON FUNCTION get_popular_feed TO authenticated;
GRANT EXECUTE ON FUNCTION get_following_feed TO authenticated;
GRANT EXECUTE ON FUNCTION check_new_gossips TO authenticated;
GRANT EXECUTE ON FUNCTION feed_engagement(gossips) TO authenticated;
GRANT EXECUTE ON FUNCTION feed_age_hours(gossips) TO authenticated;
GRANT EXECUTE ON FUNCTION feed_velocity(gossips) TO authenticated;

-- ❌ NO otorgar a 'anon' porque AuthGate requiere login obligatorio
-- Si en el futuro se permite navegación sin login, agregar:
-- GRANT EXECUTE ON FUNCTION get_popular_feed TO anon;
-- GRANT EXECUTE ON FUNCTION check_new_gossips TO anon;
