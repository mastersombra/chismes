-- =====================================================
-- MIGRACIÓN 004: Rate Limiting Completo
-- =====================================================
-- Descripción: Tabla + funciones atómicas de rate limiting
-- Límites: 30s cooldown, 10/hora, 100/día
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

-- =====================================================
-- TABLA: rate_limits
-- =====================================================
CREATE TABLE IF NOT EXISTS rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  action_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  ip_address INET,
  user_agent TEXT,

  CONSTRAINT rate_limits_action_type_check
    CHECK (action_type IN ('create_gossip', 'update_profile', 'create_comment', 'create_reaction'))
);

-- Índices
CREATE INDEX idx_rate_limits_user_action_time
  ON rate_limits (user_id, action_type, created_at DESC);

CREATE INDEX idx_rate_limits_user
  ON rate_limits (user_id, created_at DESC);

-- Comentarios
COMMENT ON TABLE rate_limits IS
  'Registra acciones de usuarios para implementar rate limiting y prevenir spam';

COMMENT ON INDEX idx_rate_limits_user_action_time IS
  'CRÍTICO para performance: permite queries COUNT rápidos por usuario+acción+tiempo';

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own rate limit records"
  ON rate_limits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Only backend can insert rate limits"
  ON rate_limits FOR INSERT
  WITH CHECK (false);

-- =====================================================
-- FUNCIÓN: reserve_rate_limit_slot (ATÓMICA)
-- =====================================================
-- Verifica límites + reserva slot en UNA transacción
-- Previene race conditions y bypass
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
  -- Lock advisory por usuario (previene race conditions)
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Verificar cooldown (30 segundos)
  SELECT created_at INTO v_last_action
  FROM rate_limits
  WHERE user_id = p_user_id AND action_type = p_action_type
  ORDER BY created_at DESC LIMIT 1;

  IF v_last_action IS NOT NULL THEN
    v_time_since_last := EXTRACT(EPOCH FROM (v_now - v_last_action));
    v_cooldown_seconds := 30;

    IF v_time_since_last < v_cooldown_seconds THEN
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

  -- Verificar límite por hora (10 acciones)
  SELECT COUNT(*) INTO v_hourly_count
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND created_at > v_now - INTERVAL '1 hour';

  IF v_hourly_count >= 10 THEN
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

  -- Verificar límite por día (100 acciones)
  SELECT COUNT(*) INTO v_daily_count
  FROM rate_limits
  WHERE user_id = p_user_id
    AND action_type = p_action_type
    AND created_at > v_now - INTERVAL '1 day';

  IF v_daily_count >= 100 THEN
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

  -- ✅ Reservar slot (INSERT AHORA)
  INSERT INTO rate_limits (user_id, action_type, created_at)
  VALUES (p_user_id, p_action_type, v_now);

  -- Retornar success
  RETURN json_build_object(
    'allowed', true,
    'reason', NULL,
    'retry_after', NULL,
    'message', 'Rate limit check passed',
    'stats', json_build_object(
      'hourly_count', v_hourly_count + 1,
      'daily_count', v_daily_count + 1,
      'hourly_remaining', 10 - (v_hourly_count + 1),
      'daily_remaining', 100 - (v_daily_count + 1)
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Rate limit check failed: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION reserve_rate_limit_slot TO service_role;

-- =====================================================
-- FUNCIÓN: release_rate_limit_slot (Rollback)
-- =====================================================
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
  DELETE FROM rate_limits
  WHERE id IN (
    SELECT id FROM rate_limits
    WHERE user_id = p_user_id
      AND action_type = p_action_type
    ORDER BY created_at DESC
    LIMIT 1
  );
END;
$$;

GRANT EXECUTE ON FUNCTION release_rate_limit_slot TO service_role;

-- =====================================================
-- FUNCIÓN: cleanup_old_rate_limits
-- =====================================================
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM rate_limits
  WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$;

COMMENT ON FUNCTION cleanup_old_rate_limits IS
  'Borra registros de rate_limits mayores a 7 días. Ejecutar diariamente via cron job.';

-- =====================================================
-- FIN MIGRACIÓN 004
-- =====================================================
