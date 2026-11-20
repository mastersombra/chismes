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

-- **Privacidad:** lee de public_gossips (autor oculto en anónimos) y corre
-- con los permisos del usuario (SECURITY INVOKER). Retorna las mismas
-- columnas que la vista: nada de modified_by/deleted_by/report_count.
CREATE OR REPLACE FUNCTION search_gossips(
  search_query TEXT,
  city_filter TEXT DEFAULT NULL,
  result_limit INTEGER DEFAULT 20
)
RETURNS SETOF public_gossips
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT g.*
  FROM public_gossips g
  WHERE
    -- Solo gossips publicados y aprobados (la vista también incluye
    -- los drafts propios; aquí no se buscan)
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
$$;

-- =====================================================
-- COMENTARIOS Y PERMISOS
-- =====================================================

COMMENT ON FUNCTION search_gossips IS
'Busca gossips por texto en subject y content (lee public_gossips).
Retorna máximo 100 resultados ordenados por relevancia y fecha.
Filtro opcional por ciudad.';

-- Solo usuarios autenticados (AuthGate exige login). ❌ NO a anon.
REVOKE EXECUTE ON FUNCTION search_gossips FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION search_gossips TO authenticated;

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
