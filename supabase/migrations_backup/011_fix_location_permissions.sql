-- =====================================================
-- Fix: Agregar permisos SELECT para authenticated
-- =====================================================
-- Bug: Las tablas de location tienen políticas RLS pero
-- faltan los GRANT para el rol authenticated.
--
-- Error: "permission denied for table countries"
-- Solución: GRANT SELECT para authenticated + anon
-- =====================================================

-- Otorgar permisos de lectura a usuarios autenticados
GRANT SELECT ON TABLE countries TO authenticated;
GRANT SELECT ON TABLE regions TO authenticated;
GRANT SELECT ON TABLE cities TO authenticated;

-- También para usuarios anónimos (si decides permitirlo en futuro)
GRANT SELECT ON TABLE countries TO anon;
GRANT SELECT ON TABLE regions TO anon;
GRANT SELECT ON TABLE cities TO anon;

-- Otorgar permisos de ejecución para las funciones de búsqueda
GRANT EXECUTE ON FUNCTION search_cities(TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION find_nearest_city(DECIMAL, DECIMAL, INTEGER) TO authenticated;

GRANT EXECUTE ON FUNCTION search_cities(TEXT, TEXT, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION find_nearest_city(DECIMAL, DECIMAL, INTEGER) TO anon;

-- =====================================================
-- Fix: Permisos para profiles table
-- =====================================================
-- Mismo problema: política RLS existe pero falta GRANT

GRANT SELECT ON TABLE profiles TO authenticated;
GRANT SELECT ON TABLE profiles TO anon;

-- =====================================================
-- COMENTARIO
-- =====================================================
COMMENT ON TABLE countries IS
'Catálogo público de países. Permisos: SELECT para todos (authenticated + anon).';

COMMENT ON TABLE regions IS
'Catálogo público de regiones. Permisos: SELECT para todos (authenticated + anon).';

COMMENT ON TABLE cities IS
'Catálogo público de ciudades. Permisos: SELECT para todos (authenticated + anon).';
