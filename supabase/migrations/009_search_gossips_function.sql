-- =====================================================
-- Función RPC para búsqueda full-text de gossips
-- =====================================================
-- Permite buscar gossips por texto en subject y content
-- desde el cliente, optimizando la transferencia de datos.
--
-- **Uso desde cliente:**
-- supabase.rpc('search_gossips', { search_query: 'amor' })
--
-- **Performance:**
-- - Búsqueda con ILIKE (case-insensitive)
-- - Solo retorna resultados coincidentes
-- - Limitado a 100 resultados máximo
-- - Ordenado por relevancia: subject > content
-- =====================================================

CREATE OR REPLACE FUNCTION search_gossips(
  search_query TEXT,
  city_filter TEXT DEFAULT NULL,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  country_id TEXT,
  region_id TEXT,
  city_id TEXT,
  subject TEXT,
  content TEXT,
  audio_url TEXT,
  image_url TEXT,
  thumbnail_url TEXT,
  published_as TEXT,
  status TEXT,
  moderation_status TEXT,
  visibility TEXT,
  is_trending_national BOOLEAN,
  created_by UUID,
  created_at TIMESTAMPTZ,
  modified_at TIMESTAMPTZ,
  modified_by UUID,
  view_count INTEGER,
  like_count INTEGER,
  comment_count INTEGER,
  share_count INTEGER,
  report_count INTEGER,
  deleted_at TIMESTAMPTZ,
  deleted_by UUID
) AS $$
BEGIN
  RETURN QUERY
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
    g.created_by,
    g.created_at,
    g.modified_at,
    g.modified_by,
    g.view_count,
    g.like_count,
    g.comment_count,
    g.share_count,
    g.report_count,
    g.deleted_at,
    g.deleted_by
  FROM gossips g
  WHERE
    -- Solo gossips publicados y aprobados
    g.status = 'published'
    AND g.moderation_status = 'approved'
    AND g.visibility = 'public'
    AND g.deleted_at IS NULL
    -- Búsqueda en subject y content (case-insensitive)
    AND (
      g.subject ILIKE '%' || search_query || '%'
      OR g.content ILIKE '%' || search_query || '%'
    )
    -- Filtro opcional por ciudad
    AND (city_filter IS NULL OR g.city_id = city_filter)
  ORDER BY
    -- Priorizar coincidencias en subject
    CASE
      WHEN g.subject ILIKE '%' || search_query || '%' THEN 1
      ELSE 2
    END,
    -- Luego por fecha (más recientes primero)
    g.created_at DESC
  LIMIT LEAST(result_limit, 100); -- Máximo 100 resultados
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =====================================================
-- COMENTARIOS Y PERMISOS
-- =====================================================

COMMENT ON FUNCTION search_gossips IS
'Busca gossips por texto en subject y content.
Retorna máximo 100 resultados ordenados por relevancia y fecha.
Filtro opcional por ciudad.';

-- Permitir acceso anónimo (los gossips públicos son accesibles)
GRANT EXECUTE ON FUNCTION search_gossips TO anon, authenticated;

-- =====================================================
-- EJEMPLO DE USO
-- =====================================================
-- Búsqueda simple:
-- SELECT * FROM search_gossips('amor');
--
-- Búsqueda con límite:
-- SELECT * FROM search_gossips('trabajo', NULL, 10);
--
-- Búsqueda filtrada por ciudad:
-- SELECT * FROM search_gossips('amor', 'bogota', 20);
