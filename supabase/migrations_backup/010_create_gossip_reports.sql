-- =====================================================
-- Migration: 014_create_gossip_reports.sql
-- Description: Crea tabla para reportes de contenido inapropiado
-- Author: Claude Code
-- Date: 2026-10-22
-- =====================================================
--
-- **Feature:** Sistema de reportes GDPR-compliant
--
-- **Cambios:**
-- 1. Tabla gossip_reports con constraint de duplicados
-- 2. Check constraint para razones válidas
-- 3. RLS policies para protección de privacidad
-- 4. Índices para queries eficientes
-- 5. Función para auto-incrementar report_count
--
-- **Razones de reporte válidas:**
-- - spam: Contenido spam o repetitivo
-- - harassment: Acoso o bullying
-- - violence: Contenido violento
-- - sexual_content: Contenido sexual inapropiado
-- - misinformation: Desinformación o fake news
-- - other: Otra razón
--
-- **Threshold:** 3 reportes únicos → auto-increment gossip.report_count
-- =====================================================

-- =====================================================
-- 1. Crear tabla gossip_reports
-- =====================================================

CREATE TABLE IF NOT EXISTS public.gossip_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gossip_id UUID NOT NULL REFERENCES public.gossips(id) ON DELETE CASCADE,
  reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),

  -- Constraints
  CONSTRAINT gossip_reports_reason_check CHECK (
    reason IN ('spam', 'harassment', 'violence', 'sexual_content', 'misinformation', 'other')
  ),
  CONSTRAINT gossip_reports_status_check CHECK (
    status IN ('pending', 'reviewed', 'dismissed', 'actioned')
  ),

  -- Prevenir duplicados: un usuario solo puede reportar un gossip una vez
  CONSTRAINT gossip_reports_unique_user_gossip UNIQUE (gossip_id, reported_by)
);

-- =====================================================
-- 2. Índices para performance
-- =====================================================

-- Índice para buscar reportes de un gossip específico
CREATE INDEX IF NOT EXISTS idx_gossip_reports_gossip_id
  ON public.gossip_reports(gossip_id);

-- Índice para buscar reportes pendientes
CREATE INDEX IF NOT EXISTS idx_gossip_reports_status_created
  ON public.gossip_reports(status, created_at DESC);

-- Índice para buscar reportes por razón (análisis)
CREATE INDEX IF NOT EXISTS idx_gossip_reports_reason
  ON public.gossip_reports(reason);

-- =====================================================
-- 3. RLS Policies
-- =====================================================

-- Habilitar RLS
ALTER TABLE public.gossip_reports ENABLE ROW LEVEL SECURITY;

-- Policy: Usuarios pueden crear reportes
CREATE POLICY "Users can create reports"
  ON public.gossip_reports
  FOR INSERT
  WITH CHECK (auth.uid() = reported_by);

-- Policy: Usuarios pueden ver sus propios reportes
CREATE POLICY "Users can view own reports"
  ON public.gossip_reports
  FOR SELECT
  USING (auth.uid() = reported_by);

-- Policy: Solo service_role puede actualizar reportes (moderación)
-- (No crear policy SELECT para moderadores - usar service_role)

-- =====================================================
-- 4. Función para auto-incrementar report_count
-- =====================================================

CREATE OR REPLACE FUNCTION increment_gossip_report_count()
RETURNS TRIGGER AS $$
DECLARE
  unique_reports_count INTEGER;
  threshold INTEGER := 3; -- Threshold para auto-increment
BEGIN
  -- Contar reportes únicos (distintos usuarios) para este gossip
  SELECT COUNT(DISTINCT reported_by)
  INTO unique_reports_count
  FROM public.gossip_reports
  WHERE gossip_id = NEW.gossip_id
    AND status = 'pending';

  -- Si alcanza el threshold, incrementar report_count en gossips
  IF unique_reports_count >= threshold THEN
    UPDATE public.gossips
    SET
      report_count = report_count + 1,
      moderation_status = 'flagged'
    WHERE id = NEW.gossip_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. Trigger para auto-incrementar
-- =====================================================

CREATE TRIGGER trigger_increment_gossip_report_count
  AFTER INSERT ON public.gossip_reports
  FOR EACH ROW
  EXECUTE FUNCTION increment_gossip_report_count();

-- =====================================================
-- 6. Comentarios de documentación
-- =====================================================

COMMENT ON TABLE public.gossip_reports IS
'Reportes de contenido inapropiado.
- Usuarios reportan gossips con razón específica
- Un usuario solo puede reportar un gossip una vez (constraint)
- Threshold: 3 reportes únicos → auto-increment gossip.report_count
- GDPR compliant: reportes se eliminan si se elimina el gossip (CASCADE)';

COMMENT ON COLUMN public.gossip_reports.reason IS
'Razón del reporte: spam, harassment, violence, sexual_content, misinformation, other';

COMMENT ON COLUMN public.gossip_reports.status IS
'Estado del reporte: pending, reviewed, dismissed, actioned';

COMMENT ON COLUMN public.gossip_reports.details IS
'Detalles adicionales del reporte (opcional)';

-- =====================================================
-- 7. Vista para análisis de reportes (moderadores)
-- =====================================================

CREATE OR REPLACE VIEW gossip_reports_summary AS
SELECT
  g.id AS gossip_id,
  g.subject,
  g.status AS gossip_status,
  g.moderation_status,
  g.report_count,
  COUNT(DISTINCT gr.reported_by) AS unique_reporters,
  COUNT(*) AS total_reports,
  array_agg(DISTINCT gr.reason) AS reported_reasons,
  MIN(gr.created_at) AS first_reported_at,
  MAX(gr.created_at) AS last_reported_at
FROM public.gossips g
INNER JOIN public.gossip_reports gr ON g.id = gr.gossip_id
WHERE gr.status = 'pending'
GROUP BY g.id, g.subject, g.status, g.moderation_status, g.report_count
ORDER BY unique_reporters DESC, last_reported_at DESC;

COMMENT ON VIEW gossip_reports_summary IS
'Vista de análisis de reportes para moderadores.
- Agrupa reportes por gossip
- Muestra razones, reportadores únicos, timestamps
- Solo reportes pendientes
- Ordenado por número de reportadores (más críticos primero)';

-- =====================================================
-- FIN DE MIGRACIÓN 014
-- =====================================================
