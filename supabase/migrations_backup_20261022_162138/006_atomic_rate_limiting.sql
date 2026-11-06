-- =====================================================
-- MIGRACIÓN 006: Rate Limiting Atómico (Fix P0-04)
-- =====================================================
-- Descripción: Implementa rate limiting atómico para prevenir:
--   - Race conditions (requests concurrentes)
--   - Bypass por fallos de BD (fail-open)
--   - Spam por registro posterior al gossip
--
-- Estrategia: RPC que verifica + reserva slot en una transacción
--
-- Fecha: 2026-10-21
-- Autor: Alejo + Claude Code
-- =====================================================

-- =====================================================
-- FUNCIÓN: reserve_rate_limit_slot
-- =====================================================
-- Verifica límites de rate y reserva un slot ATÓMICAMENTE
--
-- Límites:
-- - 30 segundos de cooldown entre acciones
-- - 10 acciones por hora
-- - 100 acciones por día
--
-- Ventajas vs approach anterior:
-- 1. ✅ Atómico: Una sola transacción
-- 2. ✅ Lock por usuario: Previene race conditions
-- 3. ✅ Reserva ANTES: Slot ocupado antes de moderar
-- 4. ✅ Fail-closed: Si falla, rechaza (no permite bypass)
--
-- Retorna JSON:
-- {
--   "allowed": boolean,
--   "reason": string | null,
--   "retry_after": number | null,
--   "stats": {
--     "hourly_count": number,
--     "daily_count": number
--   }
-- }
CREATE OR REPLACE FUNCTION reserve_rate_limit_slot(
  p_user_id UUID,
  p_action_type TEXT DEFAULT 'create_gossip'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hourly_count INTEGER;
  v_daily_count INTEGER;
  v_last_action TIMESTAMPTZ;
  v_cooldown_seconds INTEGER;
  v_time_since_last NUMERIC;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- =====================================================
  -- PASO 1: Lock Advisory por Usuario
  -- =====================================================
  -- Este lock previene race conditions entre requests concurrentes
  -- del mismo usuario. Otros usuarios no se bloquean entre sí.
  --
  -- hashtext() convierte UUID a integer para pg_advisory_xact_lock
  -- _xact = lock se libera automáticamente al final de la transacción
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- =====================================================
  -- PASO 2: Verificar Cooldown (30 segundos)
  -- =====================================================
  SELECT created_at INTO v_last_action
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_last_action IS NOT NULL THEN
    v_time_since_last := EXTRACT(EPOCH FROM (v_now - v_last_action));
    v_cooldown_seconds := 30;

    IF v_time_since_last < v_cooldown_seconds THEN
      -- ❌ Cooldown violation
      RETURN json_build_object(
        'allowed', false,
        'reason', 'cooldown',
        'retry_after', (v_cooldown_seconds - v_time_since_last)::INTEGER,
        'message', format(
          'Debes esperar %s segundos antes de crear otro chisme',
          (v_cooldown_seconds - v_time_since_last)::INTEGER
        ),
        'stats', json_build_object(
          'seconds_since_last', v_time_since_last::INTEGER,
          'cooldown_required', v_cooldown_seconds
        )
      );
    END IF;
  END IF;

  -- =====================================================
  -- PASO 3: Verificar Límite por Hora (10 acciones)
  -- =====================================================
  SELECT COUNT(*) INTO v_hourly_count
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND created_at > v_now - INTERVAL '1 hour';

  IF v_hourly_count >= 10 THEN
    -- ❌ Hourly limit exceeded
    RETURN json_build_object(
      'allowed', false,
      'reason', 'hourly_limit',
      'retry_after', 3600,
      'message', 'Has alcanzado el límite de 10 chismes por hora. Intenta en 1 hora.',
      'stats', json_build_object(
        'hourly_count', v_hourly_count,
        'hourly_limit', 10
      )
    );
  END IF;

  -- =====================================================
  -- PASO 4: Verificar Límite por Día (100 acciones)
  -- =====================================================
  SELECT COUNT(*) INTO v_daily_count
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND created_at > v_now - INTERVAL '1 day';

  IF v_daily_count >= 100 THEN
    -- ❌ Daily limit exceeded
    RETURN json_build_object(
      'allowed', false,
      'reason', 'daily_limit',
      'retry_after', 86400,
      'message', 'Has alcanzado el límite de 100 chismes por día. Intenta mañana.',
      'stats', json_build_object(
        'daily_count', v_daily_count,
        'daily_limit', 100
      )
    );
  END IF;

  -- =====================================================
  -- PASO 5: ✅ Reservar Slot (INSERT AHORA)
  -- =====================================================
  -- IMPORTANTE: Insertar ANTES de moderar/crear gossip
  -- Esto previene bypass si moderación o inserción falla
  INSERT INTO rate_limits (user_id, action_type, created_at)
  VALUES (p_user_id, p_action_type, v_now);

  -- =====================================================
  -- PASO 6: Retornar Success
  -- =====================================================
  RETURN json_build_object(
    'allowed', true,
    'reason', NULL,
    'retry_after', NULL,
    'message', 'Rate limit check passed',
    'stats', json_build_object(
      'hourly_count', v_hourly_count + 1, -- +1 porque acabamos de insertar
      'daily_count', v_daily_count + 1,
      'hourly_remaining', 10 - (v_hourly_count + 1),
      'daily_remaining', 100 - (v_daily_count + 1)
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    -- Si algo falla, loguear y propagar error
    -- Esto causa que Edge Function rechace (fail-closed)
    RAISE EXCEPTION 'Rate limit check failed: %', SQLERRM;
END;
$$;

-- Grant para que Edge Functions puedan ejecutar
GRANT EXECUTE ON FUNCTION reserve_rate_limit_slot TO service_role;

-- =====================================================
-- FUNCIÓN: release_rate_limit_slot (Rollback)
-- =====================================================
-- Libera un slot reservado si la operación falla
-- Uso: Si moderación rechaza o inserción falla
CREATE OR REPLACE FUNCTION release_rate_limit_slot(
  p_user_id UUID,
  p_action_type TEXT DEFAULT 'create_gossip'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Eliminar el registro más reciente (el que acabamos de crear)
  DELETE FROM rate_limits
  WHERE id IN (
    SELECT id
    FROM rate_limits
    WHERE user_id = p_user_id
      AND action_type = p_action_type
    ORDER BY created_at DESC
    LIMIT 1
  );
END;
$$;

GRANT EXECUTE ON FUNCTION release_rate_limit_slot TO service_role;

-- =====================================================
-- FUNCIÓN: get_rate_limit_stats (Analytics)
-- =====================================================
-- Obtiene estadísticas de rate limiting de un usuario
CREATE OR REPLACE FUNCTION get_rate_limit_stats(
  p_user_id UUID,
  p_action_type TEXT DEFAULT 'create_gossip'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_hourly_count INTEGER;
  v_daily_count INTEGER;
  v_last_action TIMESTAMPTZ;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- Contar acciones por hora
  SELECT COUNT(*) INTO v_hourly_count
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND created_at > v_now - INTERVAL '1 hour';

  -- Contar acciones por día
  SELECT COUNT(*) INTO v_daily_count
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND created_at > v_now - INTERVAL '1 day';

  -- Última acción
  SELECT created_at INTO v_last_action
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
  ORDER BY created_at DESC
  LIMIT 1;

  RETURN json_build_object(
    'hourly', json_build_object(
      'count', v_hourly_count,
      'limit', 10,
      'remaining', 10 - v_hourly_count
    ),
    'daily', json_build_object(
      'count', v_daily_count,
      'limit', 100,
      'remaining', 100 - v_daily_count
    ),
    'cooldown', json_build_object(
      'last_action', v_last_action,
      'seconds_since', CASE
        WHEN v_last_action IS NOT NULL
        THEN EXTRACT(EPOCH FROM (v_now - v_last_action))::INTEGER
        ELSE NULL
      END,
      'required_seconds', 30
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_rate_limit_stats TO authenticated;

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON FUNCTION reserve_rate_limit_slot IS
'Verifica límites de rate y reserva un slot ATÓMICAMENTE. Usa pg_advisory_xact_lock para prevenir race conditions. Retorna JSON con allowed=true/false.';

COMMENT ON FUNCTION release_rate_limit_slot IS
'Libera un slot reservado si la operación posterior falla (ej: moderación rechaza). Elimina el registro más reciente del usuario.';

COMMENT ON FUNCTION get_rate_limit_stats IS
'Obtiene estadísticas actuales de rate limiting de un usuario. Retorna JSON con contadores y límites por hora/día.';

-- =====================================================
-- ÍNDICES ADICIONALES (Optimización)
-- =====================================================

-- Índice para queries de cooldown (last action)
-- Ya existe idx_rate_limits_user pero este es más específico
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_action_desc
  ON rate_limits (user_id, action_type, created_at DESC);

-- =====================================================
-- TESTS DE SEGURIDAD
-- =====================================================

-- Test 1: Usuario puede reservar slot cuando está dentro de límites
DO $$
DECLARE
  v_result JSON;
  v_test_user_id UUID := gen_random_uuid();
BEGIN
  -- Reservar slot
  SELECT reserve_rate_limit_slot(v_test_user_id, 'create_gossip')
  INTO v_result;

  -- Verificar que permitió
  IF (v_result->>'allowed')::boolean = true THEN
    RAISE NOTICE '✅ TEST 1 PASS: Slot reservado correctamente';
  ELSE
    RAISE EXCEPTION '❌ TEST 1 FAIL: No permitió reservar slot';
  END IF;

  -- Limpiar
  DELETE FROM rate_limits WHERE user_id = v_test_user_id;
END $$;

-- Test 2: Usuario no puede reservar si excede límite por hora
DO $$
DECLARE
  v_result JSON;
  v_test_user_id UUID := gen_random_uuid();
  v_i INTEGER;
BEGIN
  -- Insertar 10 acciones en la última hora
  FOR v_i IN 1..10 LOOP
    INSERT INTO rate_limits (user_id, action_type, created_at)
    VALUES (v_test_user_id, 'create_gossip', NOW() - INTERVAL '30 minutes');
  END LOOP;

  -- Intentar reservar slot #11
  SELECT reserve_rate_limit_slot(v_test_user_id, 'create_gossip')
  INTO v_result;

  -- Verificar que rechazó
  IF (v_result->>'allowed')::boolean = false
     AND (v_result->>'reason')::text = 'hourly_limit' THEN
    RAISE NOTICE '✅ TEST 2 PASS: Límite por hora funciona';
  ELSE
    RAISE EXCEPTION '❌ TEST 2 FAIL: Límite por hora no funciona';
  END IF;

  -- Limpiar
  DELETE FROM rate_limits WHERE user_id = v_test_user_id;
END $$;

-- Test 3: Cooldown funciona correctamente
DO $$
DECLARE
  v_result JSON;
  v_test_user_id UUID := gen_random_uuid();
BEGIN
  -- Insertar acción hace 10 segundos
  INSERT INTO rate_limits (user_id, action_type, created_at)
  VALUES (v_test_user_id, 'create_gossip', NOW() - INTERVAL '10 seconds');

  -- Intentar reservar slot (debería rechazar por cooldown)
  SELECT reserve_rate_limit_slot(v_test_user_id, 'create_gossip')
  INTO v_result;

  -- Verificar que rechazó
  IF (v_result->>'allowed')::boolean = false
     AND (v_result->>'reason')::text = 'cooldown' THEN
    RAISE NOTICE '✅ TEST 3 PASS: Cooldown funciona';
  ELSE
    RAISE EXCEPTION '❌ TEST 3 FAIL: Cooldown no funciona';
  END IF;

  -- Limpiar
  DELETE FROM rate_limits WHERE user_id = v_test_user_id;
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN
-- =====================================================
-- ✅ Migración 006 completada exitosamente
--
-- Funciones creadas:
--   - reserve_rate_limit_slot()  → Verificar + reservar atómicamente
--   - release_rate_limit_slot()  → Liberar slot si falla operación
--   - get_rate_limit_stats()     → Obtener estadísticas del usuario
--
-- Seguridad:
--   ✅ Fail-closed strategy (rechaza si falla)
--   ✅ Prevención de race conditions (pg_advisory_xact_lock)
--   ✅ Índices optimizados para performance
-- =====================================================
