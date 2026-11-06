-- Tabla para persistir logs de errores en producción
-- Permite diagnosticar problemas de usuarios sin acceso a consola

-- Habilitar extensión para generar UUIDs
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Crear tabla error_logs
CREATE TABLE IF NOT EXISTS public.error_logs (
  -- Identificación
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Nivel de severidad
  level TEXT NOT NULL CHECK (level IN ('debug', 'info', 'warning', 'error', 'fatal')),

  -- Información del error
  message TEXT NOT NULL,
  error_type TEXT,           -- Ejemplo: "ValidationException", "NetworkException"
  stack_trace TEXT,

  -- Contexto del usuario
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Contexto del dispositivo
  device_info JSONB,         -- { os, osVersion, device, appVersion, locale }

  -- Contexto adicional
  context JSONB,             -- Datos extra: { cityId, gossipId, operation, etc }

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Índices para queries comunes
CREATE INDEX idx_error_logs_level ON public.error_logs(level);
CREATE INDEX idx_error_logs_created_at ON public.error_logs(created_at DESC);
CREATE INDEX idx_error_logs_user_id ON public.error_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_error_logs_error_type ON public.error_logs(error_type) WHERE error_type IS NOT NULL;

-- Índice GIN para búsquedas en JSONB
CREATE INDEX idx_error_logs_device_info ON public.error_logs USING GIN(device_info);
CREATE INDEX idx_error_logs_context ON public.error_logs USING GIN(context);

-- RLS: Solo backend/admin puede escribir
-- Los usuarios NO pueden leer/escribir directamente (solo el backend lo hace con service_role key)
ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Solo service_role puede insertar
-- Nota: En Flutter, el logging se hará con service_role key (no anon key)
-- o mediante una Cloud Function que reciba el log y lo inserte
CREATE POLICY "Service role can insert error_logs"
  ON public.error_logs
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Policy: Admin puede leer todos los logs
CREATE POLICY "Admin can read all error_logs"
  ON public.error_logs
  FOR SELECT
  TO authenticated
  USING (
    -- Solo admins pueden leer (ajustar según tu lógica de permisos)
    -- Por ahora, solo service_role puede leer
    false
  );

-- Función para limpiar logs antiguos (ejecutar periódicamente)
-- Mantener solo últimos 90 días
CREATE OR REPLACE FUNCTION clean_old_error_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM public.error_logs
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentarios para documentación
COMMENT ON TABLE public.error_logs IS 'Logs de errores de la aplicación para diagnóstico en producción';
COMMENT ON COLUMN public.error_logs.level IS 'Nivel de severidad: debug, info, warning, error, fatal';
COMMENT ON COLUMN public.error_logs.message IS 'Mensaje descriptivo del log';
COMMENT ON COLUMN public.error_logs.error_type IS 'Tipo de excepción (ej: ValidationException)';
COMMENT ON COLUMN public.error_logs.stack_trace IS 'Stack trace completo del error';
COMMENT ON COLUMN public.error_logs.user_id IS 'Usuario que experimentó el error (puede ser null si no autenticado)';
COMMENT ON COLUMN public.error_logs.device_info IS 'Información del dispositivo: { os, osVersion, device, appVersion }';
COMMENT ON COLUMN public.error_logs.context IS 'Contexto adicional específico del error: { operation, entityId, etc }';

-- Ejemplo de uso para queries:
--
-- Ver últimos errores:
-- SELECT * FROM error_logs ORDER BY created_at DESC LIMIT 50;
--
-- Errores por tipo:
-- SELECT error_type, COUNT(*) as count
-- FROM error_logs
-- WHERE level = 'error'
-- GROUP BY error_type
-- ORDER BY count DESC;
--
-- Errores de un usuario:
-- SELECT * FROM error_logs WHERE user_id = 'uuid-del-usuario';
--
-- Errores en iOS:
-- SELECT * FROM error_logs WHERE device_info->>'os' = 'iOS';
--
-- Limpiar logs antiguos (ejecutar manualmente o con cron):
-- SELECT clean_old_error_logs();
