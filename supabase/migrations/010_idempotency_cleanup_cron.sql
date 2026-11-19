-- =====================================================
-- 010: Limpieza de idempotency keys con pg_cron (sin trigger)
-- =====================================================
-- Fecha: 2026-11-18
--
-- Antes: el trigger gossips_cleanup_old_idempotency_keys (001_gossips.sql)
-- ejecutaba cleanup_old_idempotency_keys() dentro de la transacción de ~10% de
-- los INSERT en gossips. Ese UPDATE masivo compite por locks con los inserts
-- (contención a escala; ver docs/ANALYSIS_P6_IDEMPOTENCY_OPTIONS.md).
-- La Edge Function cleanup-idempotency hacía lo mismo pero nunca se programó.
--
-- Ahora: un job diario de pg_cron llama a la función SQL directamente.
-- Sin Edge Function, sin HTTP, sin keys, y fuera del camino de los inserts.
--
-- La deduplicación NO depende de esta limpieza: las keys siguen siendo únicas;
-- esto solo libera keys con más de 24 h.
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 1. Quitar el trigger (y su función wrapper) del camino de los inserts
DROP TRIGGER IF EXISTS gossips_cleanup_old_idempotency_keys ON gossips;
DROP FUNCTION IF EXISTS trigger_cleanup_idempotency_keys();

-- 2. Programar la limpieza diaria a las 3:30 AM UTC
--    (error-logs-cleanup corre domingos 3:00 AM; se evita solaparlos)
SELECT cron.unschedule('idempotency-keys-cleanup')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'idempotency-keys-cleanup'
);

SELECT cron.schedule(
  'idempotency-keys-cleanup',
  '30 3 * * *',
  'SELECT cleanup_old_idempotency_keys()'
);

-- =====================================================
-- Verificación (manual)
-- =====================================================
-- SELECT jobname, schedule, active FROM cron.job;
--   → debe listar error-logs-cleanup e idempotency-keys-cleanup
-- SELECT tgname FROM pg_trigger WHERE tgname = 'gossips_cleanup_old_idempotency_keys';
--   → 0 filas
-- SELECT cleanup_old_idempotency_keys();   -- ejecutar a mano, retorna filas limpiadas
