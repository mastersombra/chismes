-- =====================================================
-- MIGRACIÓN 009: Eliminar Trigger Costoso de Idempotencia (Fix P6-5)
-- =====================================================
-- Descripción: Elimina el trigger automático de limpieza de idempotency_key
--   que ejecuta UPDATE global en 10% de los inserts.
--
-- Problema:
--   - Trigger en AFTER INSERT ejecuta UPDATE WHERE created_at < NOW() - 24h
--   - Full table scan en 10% de inserts
--   - Causa contención y latencia en camino crítico de publicación
--   - WAL overhead innecesario
--
-- Solución:
--   - Eliminar trigger automático
--   - Mantener función cleanup_old_idempotency_keys() para uso manual
--   - Ejecutar limpieza con cron job / Edge Function programada (fuera del camino crítico)
--
-- Alternativa futura:
--   - Índice parcial: CREATE INDEX ON gossips(created_at) WHERE idempotency_key IS NOT NULL
--   - O usar pg_cron extension para limpieza programada
--
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

-- =====================================================
-- PASO 1: Eliminar trigger automático
-- =====================================================

DROP TRIGGER IF EXISTS gossips_cleanup_old_idempotency_keys ON gossips;

COMMENT ON FUNCTION cleanup_old_idempotency_keys() IS
'Limpia idempotency_key de gossips creados hace más de 24 horas.
⚠️ IMPORTANTE: Esta función NO se ejecuta automáticamente.
Debe ser llamada manualmente o mediante cron job / Edge Function programada.
Ejecutar fuera del camino crítico para evitar contención en inserts.';

-- =====================================================
-- PASO 2: Documentar cómo ejecutar la limpieza manualmente
-- =====================================================

-- La función cleanup_old_idempotency_keys() sigue disponible para uso manual:
--
-- Opción 1: Llamada manual (para testing)
-- SELECT cleanup_old_idempotency_keys();
--
-- Opción 2: Cron job (pg_cron extension)
-- SELECT cron.schedule('cleanup-idempotency', '0 3 * * *', $$
--   SELECT cleanup_old_idempotency_keys();
-- $$);
--
-- Opción 3: Edge Function programada (Supabase Cron)
-- deno run --allow-net edge-functions/cleanup-idempotency/index.ts
--
-- Recomendación: Ejecutar 1 vez al día en horario de baja demanda (3 AM).

-- =====================================================
-- PASO 3: Crear índice parcial para optimizar limpieza manual
-- =====================================================

-- Índice para acelerar la limpieza cuando se ejecute manualmente
-- Solo indexa filas con idempotency_key (< 5% del total estimado)
CREATE INDEX IF NOT EXISTS idx_gossips_idempotency_cleanup
ON gossips(created_at)
WHERE idempotency_key IS NOT NULL;

COMMENT ON INDEX idx_gossips_idempotency_cleanup IS
'Índice parcial para optimizar limpieza manual de idempotency_key.
Solo indexa filas con idempotency_key NOT NULL (~5% del total).
Reduce full table scan a index scan en cleanup_old_idempotency_keys().';

-- =====================================================
-- TESTS DE VERIFICACIÓN
-- =====================================================

-- Test 1: Trigger eliminado
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'gossips_cleanup_old_idempotency_keys'
  ) INTO trigger_exists;

  IF trigger_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Trigger still exists';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Trigger successfully removed';
END $$;

-- Test 2: Función manual sigue disponible
DO $$
DECLARE
  function_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc
    WHERE proname = 'cleanup_old_idempotency_keys'
  ) INTO function_exists;

  IF NOT function_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Function cleanup_old_idempotency_keys removed';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Function cleanup_old_idempotency_keys still available';
END $$;

-- Test 3: Índice parcial creado
DO $$
DECLARE
  index_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_gossips_idempotency_cleanup'
  ) INTO index_exists;

  IF NOT index_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Partial index not created';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Partial index created successfully';
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN 009
-- =====================================================
-- ✅ Trigger automático eliminado
-- ✅ Función manual preservada
-- ✅ Índice parcial creado para optimizar limpieza
-- ✅ Tests pasando
--
-- Beneficios:
--   1. Elimina contención en camino crítico de publicación
--   2. Reduce latencia P99 de inserts
--   3. Elimina WAL overhead innecesario
--   4. Limpieza manual más rápida con índice parcial
--
-- Acción requerida:
--   - Configurar cron job o Edge Function para ejecutar limpieza diaria
--   - Horario recomendado: 3 AM (baja demanda)
-- =====================================================
