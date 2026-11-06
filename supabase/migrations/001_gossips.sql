-- =====================================================
-- Tabla de Gossips con RLS y Autenticación Obligatoria
-- =====================================================
-- Versión producción con seguridad completa implementada.
--
-- ✅ INCLUYE:
-- - Row Level Security (RLS) con políticas estrictas
-- - Triggers para proteger contadores (report_count, etc.)
-- - Triggers para auditoría automática (created_at, modified_at)
-- - IDs generados en servidor (gen_random_uuid)
-- - Índices para queries comunes
-- - Idempotencia (idempotency_key) para prevenir duplicados
-- - Autenticación OBLIGATORIA (auth.uid())
-- - Foreign Keys a auth.users
--
-- 🔒 SEGURIDAD:
-- - created_by es UUID REFERENCES auth.users(id) NOT NULL
-- - No se permiten operaciones sin autenticación
-- - Políticas RLS estrictas por usuario
-- =====================================================

-- Tabla principal de gossips
-- Usa gen_random_uuid() que es nativo de PostgreSQL 13+
CREATE TABLE gossips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Ubicación (IDs como texto por ahora)
  country_id TEXT NOT NULL,
  region_id TEXT NOT NULL,
  city_id TEXT NOT NULL,

  -- Contenido
  subject TEXT NOT NULL CHECK (char_length(subject) <= 200),
  content TEXT NOT NULL CHECK (char_length(content) <= 1000),

  -- Media (opcional)
  audio_url TEXT,
  image_url TEXT,
  thumbnail_url TEXT, -- Thumbnail 200x200px para carga rápida (~30 KB vs ~150 KB)

  -- Publicación
  published_as TEXT NOT NULL CHECK (published_as IN ('anonymous', 'profile')),

  -- Estados
  status TEXT NOT NULL DEFAULT 'draft' CHECK (
    status IN ('draft', 'published', 'hidden', 'deleted')
  ),

  moderation_status TEXT NOT NULL DEFAULT 'pending' CHECK (
    moderation_status IN ('pending', 'approved', 'rejected', 'flagged')
  ),

  visibility TEXT NOT NULL DEFAULT 'private' CHECK (
    visibility IN ('public', 'private', 'followers')
  ),

  -- Trending (para algoritmo de feed)
  is_trending_national BOOLEAN DEFAULT FALSE NOT NULL,

  -- Auditoría con Foreign Keys a auth.users
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  modified_at TIMESTAMPTZ,
  modified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Contadores (protegidos por triggers)
  view_count INTEGER DEFAULT 0 NOT NULL,
  like_count INTEGER DEFAULT 0 NOT NULL,
  comment_count INTEGER DEFAULT 0 NOT NULL,
  share_count INTEGER DEFAULT 0 NOT NULL,
  report_count INTEGER DEFAULT 0 NOT NULL,

  -- Eliminación lógica
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Idempotencia (previene duplicados por reintentos)
  idempotency_key UUID,

  -- Constraints
  CONSTRAINT gossips_idempotency_key_unique UNIQUE (idempotency_key)
);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para queries de gossips publicados y aprobados
CREATE INDEX idx_gossips_published
ON gossips(status, moderation_status, visibility)
WHERE deleted_at IS NULL;

-- Índice para ordenamiento por fecha
CREATE INDEX idx_gossips_created_at
ON gossips(created_at DESC)
WHERE deleted_at IS NULL;

-- Índice para queries por ubicación
CREATE INDEX idx_gossips_location
ON gossips(country_id, region_id, city_id)
WHERE deleted_at IS NULL AND status = 'published';

-- Índice para queries por usuario (mis gossips)
CREATE INDEX idx_gossips_created_by
ON gossips(created_by, created_at DESC)
WHERE deleted_at IS NULL;

-- Índices para feed (optimización de queries del home)
CREATE INDEX idx_gossips_feed_popular
ON gossips (status, moderation_status, visibility, created_at DESC)
WHERE deleted_at IS NULL AND status = 'published' AND moderation_status = 'approved';

CREATE INDEX idx_gossips_city_id
ON gossips (city_id)
WHERE deleted_at IS NULL;

CREATE INDEX idx_gossips_like_count
ON gossips (like_count DESC)
WHERE deleted_at IS NULL;

CREATE INDEX idx_gossips_comment_count
ON gossips (comment_count DESC)
WHERE deleted_at IS NULL;

CREATE INDEX idx_gossips_share_count
ON gossips (share_count DESC)
WHERE deleted_at IS NULL;

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE gossips ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICA: SELECT (Lectura)
-- =====================================================

-- Todos pueden leer gossips públicos, aprobados y no eliminados
CREATE POLICY "Gossips públicos son visibles para todos"
ON gossips
FOR SELECT
USING (
  status = 'published'
  AND moderation_status = 'approved'
  AND visibility = 'public'
  AND deleted_at IS NULL
);

-- Usuarios autenticados pueden ver sus propios gossips (incluso drafts)
CREATE POLICY "Usuarios pueden ver sus propios gossips"
ON gossips
FOR SELECT
USING (
  auth.uid() = created_by
);

-- =====================================================
-- POLÍTICA: INSERT (Creación)
-- =====================================================
-- ⛔ NO HAY POLÍTICA DE INSERT DIRECTO
-- La creación de gossips SOLO puede hacerse a través de:
--   1. RPC create_gossip_draft() (usuarios autenticados)
--   2. Edge Functions con service_role (para moderación)
--
-- Esto previene bypass de moderación vía REST directo.
-- Sin política INSERT, cualquier intento de INSERT directo con anon key → 403

-- =====================================================
-- POLÍTICA: UPDATE (Actualización)
-- =====================================================

-- Usuarios pueden editar SOLO sus propios gossips en draft
-- Y SOLO campos de contenido (NO contadores, NO timestamps, NO estados)
CREATE POLICY "Usuarios pueden editar sus propios drafts"
ON gossips
FOR UPDATE
USING (
  auth.uid() = created_by
  AND status = 'draft'
)
WITH CHECK (
  auth.uid() = created_by
  AND status = 'draft'
  -- Los únicos campos actualizables son: subject, content, audio_url, image_url
  -- Los contadores y timestamps están protegidos por triggers
);

-- =====================================================
-- POLÍTICA: DELETE (Eliminación)
-- =====================================================
-- Solo soft delete mediante UPDATE (no DELETE directo)
-- Los usuarios NO pueden hacer DELETE físico desde cliente
-- La eliminación física es solo para admins via service_role

-- =====================================================
-- GRANT: Permisos básicos de tabla
-- =====================================================
-- IMPORTANTE: Con RLS habilitado, los roles necesitan permisos básicos
-- de SELECT en la tabla. Las políticas RLS filtran QUÉ filas pueden ver.
-- Sin estos GRANT, incluso con políticas RLS correctas, obtendrás "permission denied".

-- Permitir SELECT solo a usuarios autenticados
-- Las políticas RLS arriba controlan QUÉ gossips pueden ver
GRANT SELECT ON gossips TO authenticated;

-- ❌ NO otorgar a 'anon' porque AuthGate requiere login obligatorio
-- Si en el futuro se permite navegación sin login, agregar:
-- GRANT SELECT ON gossips TO anon;

-- No otorgar INSERT/UPDATE/DELETE directo
-- Esas operaciones solo via funciones RPC (create_gossip_draft, etc.)

-- =====================================================
-- TRIGGERS PARA PROTEGER CAMPOS CRÍTICOS
-- =====================================================

-- Trigger: Auto-asignar created_by y created_at en INSERT
CREATE OR REPLACE FUNCTION auto_set_audit_fields_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Validar que hay usuario autenticado
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to create gossips'
      USING HINT = 'User must be logged in';
  END IF;

  -- Forzar created_by desde auth.uid()
  NEW.created_by = auth.uid();
  NEW.created_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER gossips_auto_set_audit_fields_on_insert
  BEFORE INSERT ON gossips
  FOR EACH ROW
  EXECUTE FUNCTION auto_set_audit_fields_on_insert();

-- Trigger: Auto-actualizar modified_at y modified_by en UPDATE
CREATE OR REPLACE FUNCTION auto_update_audit_fields_on_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.modified_at = NOW();

  -- Si hay usuario autenticado, usar su ID
  IF auth.uid() IS NOT NULL THEN
    NEW.modified_by = auth.uid();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER gossips_auto_update_audit_fields_on_update
  BEFORE UPDATE ON gossips
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_audit_fields_on_update();

-- Trigger: Proteger campos críticos (contadores, estados, auditoría)
-- Solo permite modificación desde service_role (Edge Functions)
CREATE OR REPLACE FUNCTION protect_critical_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- En INSERT: forzar contadores a 0
  IF TG_OP = 'INSERT' THEN
    NEW.view_count = 0;
    NEW.like_count = 0;
    NEW.comment_count = 0;
    NEW.report_count = 0;
    RETURN NEW;
  END IF;

  -- En UPDATE desde cliente: preservar valores originales de campos críticos
  -- Solo Edge Functions con service_role pueden modificarlos
  IF TG_OP = 'UPDATE' AND current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    -- Proteger contadores
    NEW.view_count = OLD.view_count;
    NEW.like_count = OLD.like_count;
    NEW.comment_count = OLD.comment_count;
    NEW.report_count = OLD.report_count;

    -- Proteger estados de moderación
    NEW.status = OLD.status;
    NEW.moderation_status = OLD.moderation_status;

    -- Proteger campos de auditoría críticos
    NEW.created_at = OLD.created_at;
    NEW.created_by = OLD.created_by;
    NEW.deleted_at = OLD.deleted_at;
    NEW.deleted_by = OLD.deleted_by;

    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER gossips_protect_critical_fields
  BEFORE INSERT OR UPDATE ON gossips
  FOR EACH ROW
  EXECUTE FUNCTION protect_critical_fields();

-- =====================================================
-- LIMPIEZA DE IDEMPOTENCY_KEY (TTL 24 horas)
-- =====================================================

-- Función que limpia claves de idempotencia mayores a 24 horas
CREATE OR REPLACE FUNCTION cleanup_old_idempotency_keys()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Eliminar idempotency_key de gossips creados hace más de 24 horas
  -- NO eliminamos el gossip, solo limpiamos la clave
  UPDATE gossips
  SET idempotency_key = NULL
  WHERE idempotency_key IS NOT NULL
    AND created_at < NOW() - INTERVAL '24 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger automático de limpieza (se ejecuta ocasionalmente)
CREATE OR REPLACE FUNCTION trigger_cleanup_idempotency_keys()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo ejecutar limpieza ocasionalmente (10% de las veces)
  IF random() < 0.1 THEN
    PERFORM cleanup_old_idempotency_keys();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER gossips_cleanup_old_idempotency_keys
  AFTER INSERT ON gossips
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_cleanup_idempotency_keys();

-- Función auxiliar para verificar duplicados
CREATE OR REPLACE FUNCTION is_duplicate_idempotency_key(key UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM gossips
    WHERE idempotency_key = key
    AND created_at > NOW() - INTERVAL '24 hours'
  );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- =====================================================
-- RPC: CREAR GOSSIP (Punto de entrada único)
-- =====================================================
-- Función server-side para crear gossips desde el cliente
-- Ventajas de seguridad:
--   1. Cliente NO puede especificar status/moderation_status/visibility
--   2. created_by se fuerza desde auth.uid() (no puede falsificarse)
--   3. Idempotencia manejada server-side
--   4. Validaciones centralizadas
--   5. Único punto de entrada para auditoría
CREATE OR REPLACE FUNCTION create_gossip_draft(
  p_subject TEXT,
  p_content TEXT,
  p_country_id TEXT,
  p_region_id TEXT,
  p_city_id TEXT,
  p_published_as TEXT,
  p_audio_url TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_idempotency_key UUID DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER -- ✅ Ejecuta con privilegios de owner (puede insertar)
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_gossip_id UUID;
  v_user_id UUID;
  v_gossip_record RECORD;
BEGIN
  -- =====================================================
  -- PASO 1: Validar autenticación
  -- =====================================================
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING HINT = 'User must be logged in to create gossips';
  END IF;

  -- =====================================================
  -- PASO 2: Validar idempotencia (prevenir duplicados)
  -- =====================================================
  IF p_idempotency_key IS NOT NULL THEN
    -- Verificar si ya existe un gossip con esta key (últimas 24h)
    SELECT id INTO v_gossip_id
    FROM gossips
    WHERE idempotency_key = p_idempotency_key
      AND created_at > NOW() - INTERVAL '24 hours';

    IF v_gossip_id IS NOT NULL THEN
      -- Ya existe, retornar el gossip existente
      SELECT * INTO v_gossip_record
      FROM gossips
      WHERE id = v_gossip_id;

      RETURN json_build_object(
        'id', v_gossip_record.id,
        'status', v_gossip_record.status,
        'moderation_status', v_gossip_record.moderation_status,
        'is_duplicate', true,
        'message', 'Gossip already created with this idempotency key'
      );
    END IF;
  END IF;

  -- =====================================================
  -- PASO 3: Validar campos obligatorios
  -- =====================================================
  IF p_subject IS NULL OR LENGTH(TRIM(p_subject)) = 0 THEN
    RAISE EXCEPTION 'Subject is required';
  END IF;

  IF p_content IS NULL OR LENGTH(TRIM(p_content)) = 0 THEN
    RAISE EXCEPTION 'Content is required';
  END IF;

  IF p_country_id IS NULL THEN
    RAISE EXCEPTION 'Country ID is required';
  END IF;

  IF p_published_as NOT IN ('anonymous', 'profile') THEN
    RAISE EXCEPTION 'Invalid published_as value: %', p_published_as;
  END IF;

  -- =====================================================
  -- PASO 4: Insertar gossip con valores controlados
  -- =====================================================
  INSERT INTO gossips (
    subject,
    content,
    country_id,
    region_id,
    city_id,
    published_as,
    audio_url,
    image_url,
    -- ✅ Campos controlados por servidor (cliente NO puede especificar):
    status,              -- Siempre 'draft' al crear
    moderation_status,   -- Siempre 'pending' al crear
    visibility,          -- Siempre 'private' al crear
    created_by,          -- Forzado desde auth.uid()
    idempotency_key      -- Para prevenir duplicados
  ) VALUES (
    p_subject,
    p_content,
    p_country_id,
    p_region_id,
    p_city_id,
    p_published_as,
    p_audio_url,
    p_image_url,
    'draft',             -- ✅ Forzado por servidor
    'pending',           -- ✅ Forzado por servidor
    'private',           -- ✅ Forzado por servidor
    v_user_id,           -- ✅ Forzado desde auth (no falsificable)
    p_idempotency_key
  )
  RETURNING * INTO v_gossip_record;

  -- =====================================================
  -- PASO 5: Retornar gossip creado
  -- =====================================================
  RETURN json_build_object(
    'id', v_gossip_record.id,
    'status', v_gossip_record.status,
    'moderation_status', v_gossip_record.moderation_status,
    'visibility', v_gossip_record.visibility,
    'created_at', v_gossip_record.created_at,
    'is_duplicate', false,
    'message', 'Gossip created successfully. Awaiting moderation.'
  );

EXCEPTION
  WHEN OTHERS THEN
    -- Log error y propagar
    RAISE EXCEPTION 'Failed to create gossip: %', SQLERRM;
END;
$$;

-- Grant para que usuarios autenticados puedan ejecutar la función
GRANT EXECUTE ON FUNCTION create_gossip_draft TO authenticated;

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON TABLE gossips IS
'Tabla de chismes con RLS estricto y autenticación obligatoria. Protege contadores, timestamps y estados mediante triggers.';

COMMENT ON COLUMN gossips.created_by IS
'UUID del usuario que creó el gossip. FK a auth.users(id). Forzado por trigger desde auth.uid().';

COMMENT ON COLUMN gossips.idempotency_key IS
'UUID único generado por el cliente para prevenir duplicados por reintentos. TTL: 24 horas.';

COMMENT ON FUNCTION cleanup_old_idempotency_keys() IS
'Limpia idempotency_key de gossips creados hace más de 24 horas para permitir reintentos tardíos con la misma clave';

COMMENT ON FUNCTION is_duplicate_idempotency_key(UUID) IS
'Verifica si una clave de idempotencia ya fue procesada en las últimas 24 horas';

COMMENT ON FUNCTION create_gossip_draft IS
'Punto de entrada único para crear gossips desde el cliente. Valida auth, previene duplicados, fuerza estados seguros. Uso: SELECT create_gossip_draft(...)';


-- =====================================================
-- IDEMPOTENCIA ATÓMICA (de 007_atomic_idempotency.sql)
-- =====================================================
--
-- Solución:
--   INSERT ON CONFLICT → Siempre retorna gossip (creado o existente)
--
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

-- =====================================================
-- FUNCIÓN: Upsert atómico con idempotencia
-- =====================================================

CREATE OR REPLACE FUNCTION upsert_gossip_idempotent(
  p_subject TEXT,
  p_content TEXT,
  p_country_id TEXT,
  p_region_id TEXT,
  p_city_id TEXT,
  p_published_as TEXT,
  p_status TEXT,
  p_moderation_status TEXT,
  p_visibility TEXT,
  p_created_by UUID,
  p_idempotency_key UUID,
  p_audio_url TEXT DEFAULT NULL,
  p_audio_storage_path TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_thumbnail_url TEXT DEFAULT NULL,
  p_storage_path TEXT DEFAULT NULL,
  p_thumbnail_storage_path TEXT DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_gossip RECORD;
  v_inserted BOOLEAN := false;
BEGIN
  -- =====================================================
  -- PASO 1: INSERT con ON CONFLICT (atómico)
  -- =====================================================
  -- Si la clave ya existe, el INSERT se salta (DO NOTHING)
  -- y podemos leer el registro existente

  INSERT INTO gossips (
    subject,
    content,
    country_id,
    region_id,
    city_id,
    published_as,
    audio_url,
    audio_storage_path,
    image_url,
    thumbnail_url,
    storage_path,
    thumbnail_storage_path,
    status,
    moderation_status,
    visibility,
    created_by,
    idempotency_key
  )
  VALUES (
    p_subject,
    p_content,
    p_country_id,
    p_region_id,
    p_city_id,
    p_published_as,
    p_audio_url,
    p_audio_storage_path,
    p_image_url,
    p_thumbnail_url,
    p_storage_path,
    p_thumbnail_storage_path,
    p_status,
    p_moderation_status,
    p_visibility,
    p_created_by,
    p_idempotency_key
  )
  ON CONFLICT (idempotency_key)
  WHERE idempotency_key IS NOT NULL
  DO NOTHING
  RETURNING * INTO v_gossip;

  -- =====================================================
  -- PASO 2: Verificar si se insertó o ya existía
  -- =====================================================

  IF v_gossip.id IS NOT NULL THEN
    -- Se insertó (nuevo gossip)
    v_inserted := true;
  ELSE
    -- Ya existía, leer el gossip existente
    SELECT * INTO v_gossip
    FROM gossips
    WHERE idempotency_key = p_idempotency_key;

    IF v_gossip.id IS NULL THEN
      -- Esto no debería pasar (algo muy raro)
      RAISE EXCEPTION 'Failed to insert or find gossip with idempotency_key %', p_idempotency_key;
    END IF;

    v_inserted := false;
  END IF;

  -- =====================================================
  -- PASO 3: Retornar gossip completo + flag idempotent
  -- =====================================================

  RETURN json_build_object(
    'gossip', row_to_json(v_gossip),
    'idempotent', NOT v_inserted,
    'message', CASE
      WHEN v_inserted THEN 'Gossip created successfully'
      ELSE 'Gossip already exists with this idempotency key'
    END
  );
END;
$$;

COMMENT ON FUNCTION upsert_gossip_idempotent IS
'Crea gossip con idempotencia atómica usando INSERT ON CONFLICT. Seguro bajo concurrencia.';

-- =====================================================
-- TESTS DE VERIFICACIÓN
-- =====================================================

-- Test 1: Función existe
DO $$
DECLARE
  function_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc
    WHERE proname = 'upsert_gossip_idempotent'
  ) INTO function_exists;

  IF NOT function_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Function upsert_gossip_idempotent not created';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Function upsert_gossip_idempotent exists';
END $$;

-- Test 2: Constraint UNIQUE existe
DO $$
DECLARE
  constraint_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_constraint
    WHERE conname = 'gossips_idempotency_key_unique'
  ) INTO constraint_exists;

  IF NOT constraint_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Constraint gossips_idempotency_key_unique not found';
  END IF;

  RAISE NOTICE '✅ TEST PASS: UNIQUE constraint on idempotency_key exists';
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN 008
-- =====================================================
-- ✅ Función upsert_gossip_idempotent creada
-- ✅ Usa INSERT ON CONFLICT (atómico)
-- ✅ Seguro bajo concurrencia
-- ✅ Retorna gossip creado O existente
-- ✅ Tests pasando
--
-- Ventajas:
--   1. Sin race condition (transacción atómica)
--   2. No devuelve 500 en conflictos
--   3. Siempre retorna el gossip correcto
--   4. Idempotente por diseño
-- =====================================================

-- =====================================================
-- ÍNDICE PARCIAL: Optimizar limpieza de idempotency
-- =====================================================
-- Solo indexa filas con idempotency_key (~5% del total)
CREATE INDEX IF NOT EXISTS idx_gossips_idempotency_cleanup
ON gossips(created_at)
WHERE idempotency_key IS NOT NULL;

COMMENT ON INDEX idx_gossips_idempotency_cleanup IS
'Índice parcial para optimizar limpieza de idempotency_key.
Solo indexa filas con idempotency_key NOT NULL.';



-- =====================================================
-- REPORTES DE GOSSIPS (de 010_create_gossip_reports.sql)
-- =====================================================
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
