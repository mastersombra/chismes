-- =====================================================
-- Home Feed Functions
-- =====================================================
-- Funciones para el feed del home screen:
-- 1. get_popular_feed: Feed principal con algoritmo de ranking
-- 2. get_following_feed: Feed de personas que sigo
-- 3. check_new_gossips: Verificar nuevos chismes
--
-- Todas con soporte para cursor-based pagination (performance)
-- =====================================================

-- =====================================================
-- FUNCIÓN: get_popular_feed
-- =====================================================
-- Feed principal con algoritmo de ranking multi-factor
--
-- Algoritmo (pesos):
-- - 40% Ciudad (local=100, trending=50, otras=20)
-- - 30% Interacciones (likes*1 + comments*2 + shares*3)
-- - 20% Velocity (interacciones / horas desde publicación)
-- - 10% Decay (penalización por antigüedad)
--
-- Paginación: Cursor-based (score, id)
-- Retorna: JSON con data, has_more, next_cursor
-- =====================================================

CREATE OR REPLACE FUNCTION get_popular_feed(
  user_city_id TEXT DEFAULT NULL,
  page_size INT DEFAULT 20,
  cursor_score NUMERIC DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  result_json JSON;
  gossips_data JSON;
  has_more_pages BOOLEAN;
  next_cursor_data JSON;
BEGIN
  -- Obtener chismes con ranking
  WITH ranked_gossips AS (
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
      g.created_by,
      g.image_url,

      -- Score de ciudad
      CASE
        WHEN g.city_id = user_city_id THEN 100
        WHEN g.is_trending_national THEN 50
        ELSE 20
      END AS score_ciudad,

      -- Score de interacciones
      (
        COALESCE(g.like_count, 0) * 1.0 +
        COALESCE(g.comment_count, 0) * 2.0 +
        COALESCE(g.share_count, 0) * 3.0
      ) AS score_interacciones,

      -- Score de velocity (trending)
      (
        COALESCE(g.like_count, 0) +
        COALESCE(g.comment_count, 0) +
        COALESCE(g.share_count, 0)
      ) / (EXTRACT(EPOCH FROM (NOW() - g.created_at)) / 3600 + 1) AS score_velocity,

      -- Score de decay (frescura)
      1.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - g.created_at)) / 3600) * 0.05) AS score_decay,

      -- Score final (40/30/20/10)
      (
        CASE
          WHEN g.city_id = user_city_id THEN 100
          WHEN g.is_trending_national THEN 50
          ELSE 20
        END * 0.4 +
        (
          COALESCE(g.like_count, 0) * 1.0 +
          COALESCE(g.comment_count, 0) * 2.0 +
          COALESCE(g.share_count, 0) * 3.0
        ) * 0.3 +
        (
          (COALESCE(g.like_count, 0) + COALESCE(g.comment_count, 0) + COALESCE(g.share_count, 0)) /
          (EXTRACT(EPOCH FROM (NOW() - g.created_at)) / 3600 + 1)
        ) * 0.2 +
        (1.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - g.created_at)) / 3600) * 0.05)) * 0.1
      ) AS score_final,

      -- Metadata
      (g.city_id = user_city_id) AS is_from_my_city,
      (
        COALESCE(g.like_count, 0) > 1000 OR
        COALESCE(g.comment_count, 0) > 200 OR
        COALESCE(g.share_count, 0) > 100
      ) AS is_trending

    FROM gossips g
    WHERE
      g.status = 'published' AND
      g.moderation_status = 'approved' AND
      g.visibility = 'public' AND
      g.deleted_at IS NULL AND
      -- Filtro: Chismes de mi ciudad SIEMPRE aparecen
      -- Chismes de otras ciudades solo si son virales
      (
        g.city_id = user_city_id OR
        user_city_id IS NULL OR
        COALESCE(g.like_count, 0) > 1000 OR
        COALESCE(g.comment_count, 0) > 200 OR
        COALESCE(g.share_count, 0) > 100 OR
        (COALESCE(g.like_count, 0) + COALESCE(g.comment_count, 0) + COALESCE(g.share_count, 0)) > 500
      )
  ),
  paginated_gossips AS (
    SELECT
      rg.id,
      rg.subject,
      rg.content,
      rg.city_id,
      rg.created_at,
      rg.likes,
      rg.comments,
      rg.shares,
      rg.published_as,
      rg.created_by,
      rg.image_url,
      rg.score_final,
      rg.is_from_my_city,
      rg.is_trending
    FROM ranked_gossips rg
    WHERE
      -- Paginación con cursor (score, id)
      (cursor_score IS NULL OR
       rg.score_final < cursor_score OR
       (rg.score_final = cursor_score AND rg.id > cursor_id))
    ORDER BY rg.score_final DESC, rg.id ASC
    LIMIT page_size + 1  -- +1 para detectar si hay más páginas
  )

  -- Construir respuesta JSON
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
          'score', pg.score_final,
          'is_from_my_city', pg.is_from_my_city,
          'is_trending', pg.is_trending
        )
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
    SELECT *, ROW_NUMBER() OVER (ORDER BY score_final DESC, id ASC) as rn
    FROM paginated_gossips
  ) pg;

  RETURN result_json;
END;
$$;

-- Comentario
COMMENT ON FUNCTION get_popular_feed IS
'Feed principal con algoritmo de ranking multi-factor. Paginación cursor-based.';

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
      g.created_by,
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
-- Verifica cuántos chismes nuevos hay desde un timestamp
-- Usado para el banner "X nuevos chismes"
-- =====================================================

CREATE OR REPLACE FUNCTION check_new_gossips(
  user_city_id TEXT DEFAULT NULL,
  since_timestamp TIMESTAMPTZ DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  new_count INT;
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
      g.city_id = user_city_id OR
      user_city_id IS NULL OR
      COALESCE(g.like_count, 0) > 1000 OR
      COALESCE(g.comment_count, 0) > 200 OR
      COALESCE(g.share_count, 0) > 100
    );

  RETURN new_count;
END;
$$;

-- Comentario
COMMENT ON FUNCTION check_new_gossips IS
'Cuenta cuántos chismes nuevos hay desde un timestamp. Para banner de actualización.';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================
-- Permitir que usuarios autenticados llamen estas funciones

GRANT EXECUTE ON FUNCTION get_popular_feed TO authenticated;
GRANT EXECUTE ON FUNCTION get_following_feed TO authenticated;
GRANT EXECUTE ON FUNCTION check_new_gossips TO authenticated;

-- ❌ NO otorgar a 'anon' porque AuthGate requiere login obligatorio
-- Si en el futuro se permite navegación sin login, agregar:
-- GRANT EXECUTE ON FUNCTION get_popular_feed TO anon;
-- GRANT EXECUTE ON FUNCTION check_new_gossips TO anon;
