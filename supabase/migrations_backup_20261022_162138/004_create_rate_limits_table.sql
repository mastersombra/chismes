-- =============================================================================
-- MIGRACIÓN 005: Tabla de Rate Limiting
-- =============================================================================
-- Descripción: Tabla dedicada para controlar límites de acciones por usuario
-- Fecha: 2026-10-19
-- Autor: Alejo + Claude Code
-- =============================================================================

-- ✅ Tabla rate_limits
CREATE TABLE IF NOT EXISTS rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- ✅ Nativo de PostgreSQL 13+
  user_id UUID NOT NULL,
  action_type TEXT NOT NULL, -- 'create_gossip', 'update_profile', etc.
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Metadata adicional (opcional, para analytics)
  ip_address INET, -- IP del request (si está disponible)
  user_agent TEXT, -- User agent (si está disponible)

  -- Constraints
  CONSTRAINT rate_limits_action_type_check
    CHECK (action_type IN ('create_gossip', 'update_profile', 'create_comment', 'create_reaction'))
);

-- ✅ Índices para queries rápidos
-- Este índice es CRÍTICO para performance de rate limiting
CREATE INDEX idx_rate_limits_user_action_time
  ON rate_limits (user_id, action_type, created_at DESC);

-- Índice adicional para queries por usuario (ver historial)
CREATE INDEX idx_rate_limits_user
  ON rate_limits (user_id, created_at DESC);

-- ✅ Comentarios de documentación
COMMENT ON TABLE rate_limits IS
  'Registra acciones de usuarios para implementar rate limiting y prevenir spam';

COMMENT ON COLUMN rate_limits.action_type IS
  'Tipo de acción: create_gossip, update_profile, create_comment, create_reaction';

COMMENT ON COLUMN rate_limits.created_at IS
  'Timestamp de la acción (UTC). Usado para calcular límites por hora/día';

COMMENT ON INDEX idx_rate_limits_user_action_time IS
  'CRÍTICO para performance: permite queries COUNT rápidos por usuario+acción+tiempo';

-- ✅ RLS (Row Level Security)
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios pueden ver solo sus propios registros
CREATE POLICY "Users can view own rate limit records"
  ON rate_limits
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Solo el backend puede insertar (via service_role)
-- Los usuarios NO pueden insertar directamente
CREATE POLICY "Only backend can insert rate limits"
  ON rate_limits
  FOR INSERT
  WITH CHECK (false); -- Bloquea inserts desde cliente

-- ✅ Función de limpieza automática (borrar registros viejos >7 días)
-- Esto previene crecimiento infinito de la tabla
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

-- ✅ Trigger opcional: Limpieza automática cada 1000 inserts
-- (Alternativa a cron job manual)
CREATE OR REPLACE FUNCTION trigger_cleanup_rate_limits()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Ejecutar limpieza probabilística (1% de chance por insert)
  IF random() < 0.01 THEN
    PERFORM cleanup_old_rate_limits();
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER rate_limits_cleanup_trigger
  AFTER INSERT ON rate_limits
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_cleanup_rate_limits();

-- =============================================================================
-- QUERIES DE EJEMPLO (Para testing)
-- =============================================================================

-- Ver rate limits de un usuario en última hora
-- SELECT COUNT(*) FROM rate_limits
-- WHERE user_id = 'xxx'
--   AND action_type = 'create_gossip'
--   AND created_at >= NOW() - INTERVAL '1 hour';

-- Ver rate limits de un usuario en último día
-- SELECT COUNT(*) FROM rate_limits
-- WHERE user_id = 'xxx'
--   AND action_type = 'create_gossip'
--   AND created_at >= NOW() - INTERVAL '1 day';

-- Ver último registro (para cooldown)
-- SELECT created_at FROM rate_limits
-- WHERE user_id = 'xxx'
--   AND action_type = 'create_gossip'
-- ORDER BY created_at DESC
-- LIMIT 1;

-- =============================================================================
-- FIN MIGRACIÓN 005
-- =============================================================================
