-- =====================================================
-- QUICK RESET: Ejecuta esto en Supabase SQL Editor
-- =====================================================
-- https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/sql/new
--
-- ⚠️ ADVERTENCIA: Esto ELIMINA la tabla gossips y todos los datos
-- Solo ejecutar en desarrollo/testing
-- =====================================================

-- 1. Eliminar tabla existente (si existe)
DROP TABLE IF EXISTS gossips CASCADE;

-- 2. Copia y pega el contenido completo de:
--    supabase/migrations/001_create_gossips_table.sql
--    (incluye: tabla, RLS, triggers, thumbnail_url)
--
-- 3. (Opcional) Datos de prueba:
--    supabase/migrations/002_insert_sample_data.sql
--
-- O ejecuta directamente con CLI:
--    supabase db reset
