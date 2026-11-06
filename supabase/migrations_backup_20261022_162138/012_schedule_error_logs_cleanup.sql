-- =====================================================
-- MIGRACIÓN 012: Scheduler para Limpieza de Error Logs
-- =====================================================
-- Descripción: Configura pg_cron para ejecutar clean_old_error_logs()
--   automáticamente cada semana
--
-- Retención: 90 días (definida en clean_old_error_logs)
-- Frecuencia: Cada domingo a las 3:00 AM UTC
--
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

-- Habilitar extensión pg_cron (si no está habilitada)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- =====================================================
-- SCHEDULER: Limpieza semanal de logs antiguos
-- =====================================================

-- Eliminar job existente si existe (para re-aplicar migración)
SELECT cron.unschedule('error-logs-cleanup')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'error-logs-cleanup'
);

-- Crear job: Ejecutar clean_old_error_logs() cada domingo a las 3 AM UTC
-- Mantiene solo logs de últimos 90 días
SELECT cron.schedule(
  'error-logs-cleanup',        -- Nombre del job
  '0 3 * * 0',                 -- Cron: "A las 3:00 AM todos los domingos"
  'SELECT clean_old_error_logs()'  -- SQL a ejecutar
);

COMMENT ON EXTENSION pg_cron IS
'Scheduler para ejecutar tareas periódicas (limpieza de logs)';

-- =====================================================
-- FUNCIÓN MEJORADA: Cleanup con logging
-- =====================================================

-- Actualizar función para retornar cantidad de logs eliminados
DROP FUNCTION IF EXISTS clean_old_error_logs();

CREATE OR REPLACE FUNCTION clean_old_error_logs()
RETURNS TABLE(deleted_count BIGINT) AS $$
DECLARE
  v_deleted_count BIGINT;
BEGIN
  -- Eliminar logs antiguos (>90 días)
  DELETE FROM public.error_logs
  WHERE created_at < NOW() - INTERVAL '90 days';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  -- Log del resultado
  RAISE NOTICE 'Cleaned % old error logs', v_deleted_count;

  RETURN QUERY SELECT v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION clean_old_error_logs IS
'Elimina logs de error mayores a 90 días. Retorna cantidad de logs eliminados.';

-- Grant para que pg_cron pueda ejecutar la función
GRANT EXECUTE ON FUNCTION clean_old_error_logs TO postgres;

-- =====================================================
-- ALERTAS: Configurar notificación si muchos logs
-- =====================================================

-- Función para verificar cantidad de logs recientes
-- (útil para alertas, ejecutar manualmente o con monitoring)
CREATE OR REPLACE FUNCTION check_error_log_rate()
RETURNS TABLE(
  last_hour_count BIGINT,
  last_day_count BIGINT,
  warning TEXT
) AS $$
DECLARE
  v_hour_count BIGINT;
  v_day_count BIGINT;
  v_warning TEXT := NULL;
BEGIN
  -- Contar logs en última hora
  SELECT COUNT(*) INTO v_hour_count
  FROM public.error_logs
  WHERE created_at > NOW() - INTERVAL '1 hour';

  -- Contar logs en último día
  SELECT COUNT(*) INTO v_day_count
  FROM public.error_logs
  WHERE created_at > NOW() - INTERVAL '1 day';

  -- Generar warning si hay muchos logs
  IF v_hour_count > 100 THEN
    v_warning := 'HIGH ERROR RATE: ' || v_hour_count || ' errors in last hour';
  ELSIF v_day_count > 1000 THEN
    v_warning := 'HIGH ERROR RATE: ' || v_day_count || ' errors in last day';
  END IF;

  RETURN QUERY SELECT v_hour_count, v_day_count, v_warning;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_error_log_rate IS
'Verifica tasa de errores reciente. Retorna warning si es muy alta.';

-- =====================================================
-- VISTAS: Para monitoreo fácil
-- =====================================================

-- Vista: Errores recientes (últimas 24h)
CREATE OR REPLACE VIEW recent_errors AS
SELECT
  id,
  level,
  message,
  error_type,
  user_id,
  device_info->>'os' as os,
  device_info->>'appVersion' as app_version,
  context,
  created_at
FROM public.error_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

COMMENT ON VIEW recent_errors IS
'Errores de las últimas 24 horas (vista simplificada para dashboard)';

-- Vista: Resumen de errores por tipo (últimos 7 días)
CREATE OR REPLACE VIEW error_summary AS
SELECT
  error_type,
  level,
  COUNT(*) as count,
  MAX(created_at) as last_occurrence
FROM public.error_logs
WHERE created_at > NOW() - INTERVAL '7 days'
  AND error_type IS NOT NULL
GROUP BY error_type, level
ORDER BY count DESC;

COMMENT ON VIEW error_summary IS
'Resumen de errores por tipo (últimos 7 días) para identificar patrones';

-- Vista: Usuarios con más errores (últimos 7 días)
CREATE OR REPLACE VIEW users_with_most_errors AS
SELECT
  user_id,
  COUNT(*) as error_count,
  MAX(created_at) as last_error
FROM public.error_logs
WHERE created_at > NOW() - INTERVAL '7 days'
  AND user_id IS NOT NULL
GROUP BY user_id
ORDER BY error_count DESC
LIMIT 20;

COMMENT ON VIEW users_with_most_errors IS
'Top 20 usuarios con más errores (últimos 7 días) para identificar problemas específicos';

-- =====================================================
-- TESTS DE VERIFICACIÓN
-- =====================================================

-- Test 1: pg_cron está habilitado
DO $$
DECLARE
  extension_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) INTO extension_exists;

  IF NOT extension_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: pg_cron not enabled';
  END IF;

  RAISE NOTICE '✅ TEST PASS: pg_cron enabled';
END $$;

-- Test 2: Job de limpieza existe
DO $$
DECLARE
  job_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM cron.job WHERE jobname = 'error-logs-cleanup'
  ) INTO job_exists;

  IF NOT job_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: error-logs-cleanup job not found';
  END IF;

  RAISE NOTICE '✅ TEST PASS: error-logs-cleanup job exists';
END $$;

-- Test 3: Función clean_old_error_logs existe y funciona
DO $$
DECLARE
  result_count BIGINT;
BEGIN
  SELECT deleted_count INTO result_count
  FROM clean_old_error_logs();

  RAISE NOTICE '✅ TEST PASS: clean_old_error_logs executed (deleted: %)', result_count;
END $$;

-- Test 4: Vistas existen
DO $$
DECLARE
  views_exist BOOLEAN;
BEGIN
  SELECT (
    SELECT COUNT(*) FROM information_schema.views
    WHERE table_schema = 'public'
      AND table_name IN ('recent_errors', 'error_summary', 'users_with_most_errors')
  ) = 3 INTO views_exist;

  IF NOT views_exist THEN
    RAISE EXCEPTION '❌ TEST FAIL: Monitoring views not created';
  END IF;

  RAISE NOTICE '✅ TEST PASS: All monitoring views exist';
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN 012
-- =====================================================
-- ✅ pg_cron habilitado
-- ✅ Job 'error-logs-cleanup' programado (domingos 3 AM UTC)
-- ✅ Función clean_old_error_logs mejorada (retorna count)
-- ✅ Función check_error_log_rate (alertas)
-- ✅ Vistas de monitoreo (recent_errors, error_summary, users_with_most_errors)
-- ✅ Tests pasando
--
-- Monitoreo:
--   SELECT * FROM recent_errors;
--   SELECT * FROM error_summary;
--   SELECT * FROM users_with_most_errors;
--   SELECT * FROM check_error_log_rate();
--
-- Manual cleanup:
--   SELECT * FROM clean_old_error_logs();
--
-- Ver jobs programados:
--   SELECT * FROM cron.job;
-- =====================================================
