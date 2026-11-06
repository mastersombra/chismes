-- =====================================================
-- MIGRACIÓN 010: Secure Audio Storage con Cuarentena
-- =====================================================
-- Descripción: Implementa arquitectura segura de 2 buckets para audio:
--   1. audio-quarantine (privado): Uploads iniciales, validación
--   2. audio (público): Solo archivos aprobados por moderación
--
-- Flujo de seguridad:
--   Upload → Cuarentena → Validar → Moderar →
--   Si aprueba: Mover a público
--   Si rechaza: Eliminar de cuarentena
--
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

-- =====================================================
-- BUCKET 1: Audio Cuarentena (Privado)
-- =====================================================
-- Archivos de audio recién subidos, aún no validados ni moderados

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio-quarantine',
  'audio-quarantine',
  false,  -- PRIVADO (solo service_role puede acceder)
  10485760,  -- 10 MB max (audio puede ser más pesado que imagen)
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a', 'audio/wav', 'audio/x-m4a']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Políticas: Solo service_role puede acceder
CREATE POLICY "Service role full access to audio quarantine"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'audio-quarantine'
  AND auth.jwt()->>'role' = 'service_role'
)
WITH CHECK (
  bucket_id = 'audio-quarantine'
  AND auth.jwt()->>'role' = 'service_role'
);

-- =====================================================
-- BUCKET 2: Audio Público (Solo archivos aprobados)
-- =====================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio',
  'audio',
  true,  -- PÚBLICO (URLs directas)
  10485760,  -- 10 MB max
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a', 'audio/wav', 'audio/x-m4a']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Cualquiera puede VER audios públicos
CREATE POLICY "Public can view approved audio"
ON storage.objects FOR SELECT
USING (bucket_id = 'audio');

-- Service role puede subir/eliminar (para mover desde cuarentena)
CREATE POLICY "Service role can manage public audio"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'audio'
  AND auth.jwt()->>'role' = 'service_role'
)
WITH CHECK (
  bucket_id = 'audio'
  AND auth.jwt()->>'role' = 'service_role'
);

-- =====================================================
-- TABLA GOSSIPS: Agregar audio_storage_path
-- =====================================================
-- audio_storage_path es la fuente de verdad (path canónico)
-- audio_url es derivado (puede regenerarse)

ALTER TABLE gossips ADD COLUMN IF NOT EXISTS audio_storage_path TEXT;

COMMENT ON COLUMN gossips.audio_storage_path IS
'Path canónico en storage (fuente de verdad). Formato: audio/gossips/{gossipId}_{timestamp}.mp3';

COMMENT ON COLUMN gossips.audio_url IS
'URL pública (derivada de audio_storage_path). Puede regenerarse.';

-- =====================================================
-- FUNCIÓN: Cleanup de cuarentena de audio
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_audio_quarantine_files()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER := 0;
  quarantine_record RECORD;
BEGIN
  -- Eliminar archivos en cuarentena mayores a 24 horas
  -- Estos son archivos que nunca fueron movidos a público
  -- (moderación rechazada o proceso interrumpido)

  FOR quarantine_record IN
    SELECT name
    FROM storage.objects
    WHERE bucket_id = 'audio-quarantine'
      AND created_at < NOW() - INTERVAL '24 hours'
  LOOP
    -- Eliminar archivo
    DELETE FROM storage.objects
    WHERE bucket_id = 'audio-quarantine'
      AND name = quarantine_record.name;

    deleted_count := deleted_count + 1;
  END LOOP;

  RAISE NOTICE 'Cleaned % audio files from quarantine', deleted_count;
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_audio_quarantine_files IS
'Limpia archivos de audio en cuarentena mayores a 24 horas. Ejecutar vía cron o manualmente.';

GRANT EXECUTE ON FUNCTION cleanup_audio_quarantine_files TO service_role;

-- =====================================================
-- FUNCIÓN: Cleanup de audios huérfanos
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_orphaned_audio()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER := 0;
  orphan_record RECORD;
BEGIN
  -- Encontrar audios en bucket público que no tienen gossip asociado
  -- y fueron creados hace más de 7 días

  FOR orphan_record IN
    SELECT o.name
    FROM storage.objects o
    WHERE o.bucket_id = 'audio'
      AND o.created_at < NOW() - INTERVAL '7 days'
      AND NOT EXISTS (
        SELECT 1 FROM gossips g
        WHERE g.audio_storage_path = o.name
      )
  LOOP
    -- Eliminar audio huérfano
    DELETE FROM storage.objects
    WHERE bucket_id = 'audio' AND name = orphan_record.name;

    deleted_count := deleted_count + 1;
  END LOOP;

  RAISE NOTICE 'Cleaned % orphaned audio files', deleted_count;
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_orphaned_audio IS
'Limpia audios públicos huérfanos (sin gossip asociado) mayores a 7 días.';

GRANT EXECUTE ON FUNCTION cleanup_orphaned_audio TO service_role;

-- =====================================================
-- ACTUALIZAR RPC create_gossip_draft
-- =====================================================
-- Agregar parámetros para storage_path (fuente de verdad)

DROP FUNCTION IF EXISTS create_gossip_draft(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID);

CREATE OR REPLACE FUNCTION create_gossip_draft(
  p_subject TEXT,
  p_content TEXT,
  p_country_id TEXT,
  p_region_id TEXT,
  p_city_id TEXT,
  p_published_as TEXT,
  p_audio_url TEXT DEFAULT NULL,
  p_audio_storage_path TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_storage_path TEXT DEFAULT NULL,
  p_thumbnail_storage_path TEXT DEFAULT NULL,
  p_idempotency_key UUID DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER
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
        'message', 'Gossip already exists (duplicate idempotency key)'
      );
    END IF;
  END IF;

  -- =====================================================
  -- PASO 3: Validar campos requeridos
  -- =====================================================
  IF p_subject IS NULL OR LENGTH(TRIM(p_subject)) = 0 THEN
    RAISE EXCEPTION 'Subject is required';
  END IF;

  IF p_content IS NULL OR LENGTH(TRIM(p_content)) = 0 THEN
    RAISE EXCEPTION 'Content is required';
  END IF;

  IF p_published_as NOT IN ('anonymous', 'profile') THEN
    RAISE EXCEPTION 'Invalid published_as value. Must be "anonymous" or "profile"';
  END IF;

  -- =====================================================
  -- PASO 4: Crear gossip
  -- =====================================================
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
    storage_path,
    thumbnail_storage_path,
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
    p_audio_storage_path,
    p_image_url,
    p_storage_path,
    p_thumbnail_storage_path,
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

GRANT EXECUTE ON FUNCTION create_gossip_draft TO authenticated;

COMMENT ON FUNCTION create_gossip_draft IS
'Crea un gossip en estado draft. Parámetros storage_path son fuente de verdad.';

-- =====================================================
-- TESTS DE VERIFICACIÓN
-- =====================================================

-- Test 1: Ambos buckets de audio existen
DO $$
DECLARE
  quarantine_exists BOOLEAN;
  public_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'audio-quarantine')
  INTO quarantine_exists;

  SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'audio')
  INTO public_exists;

  IF NOT quarantine_exists OR NOT public_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Audio buckets no creados';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Ambos buckets de audio existen';
END $$;

-- Test 2: Cuarentena es privado, audio es público
DO $$
DECLARE
  quarantine_public BOOLEAN;
  audio_public BOOLEAN;
BEGIN
  SELECT public FROM storage.buckets WHERE id = 'audio-quarantine'
  INTO quarantine_public;

  SELECT public FROM storage.buckets WHERE id = 'audio'
  INTO audio_public;

  IF quarantine_public OR NOT audio_public THEN
    RAISE EXCEPTION '❌ TEST FAIL: Configuración de privacidad incorrecta';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Privacidad correcta (audio-quarantine:private, audio:public)';
END $$;

-- Test 3: Columna audio_storage_path agregada
DO $$
DECLARE
  column_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'gossips'
      AND column_name = 'audio_storage_path'
  ) INTO column_exists;

  IF NOT column_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Columna audio_storage_path no existe';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Columna audio_storage_path agregada';
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN 010
-- =====================================================
-- ✅ Bucket 'audio-quarantine' (privado) creado
-- ✅ Bucket 'audio' (público) creado
-- ✅ Políticas de seguridad configuradas
-- ✅ Columna audio_storage_path agregada a gossips
-- ✅ Funciones de cleanup creadas
-- ✅ RPC create_gossip_draft actualizado
-- ✅ Tests pasando
--
-- Flujo de seguridad:
--   1. Upload → Cuarentena (privado)
--   2. Validar MIME + duración/tamaño
--   3. Moderar contenido
--   4. Aprobar → Mover a público + INSERT gossip
--   5. Rechazar → Eliminar de cuarentena
-- =====================================================
