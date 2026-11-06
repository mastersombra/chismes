-- =====================================================
-- MIGRACIÓN 007: Secure Media Storage con Cuarentena
-- =====================================================
-- Descripción: Implementa arquitectura segura de 2 buckets:
--   1. images-quarantine (privado): Uploads iniciales, validación
--   2. images (público): Solo archivos aprobados por moderación
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
-- BUCKET 1: Cuarentena (Privado)
-- =====================================================
-- Archivos recién subidos, aún no validados ni moderados

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'images-quarantine',
  'images-quarantine',
  false,  -- PRIVADO (solo service_role puede acceder)
  5242880,  -- 5 MB max
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Políticas: Solo service_role puede acceder
CREATE POLICY "Service role full access to quarantine"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'images-quarantine'
  AND auth.jwt()->>'role' = 'service_role'
)
WITH CHECK (
  bucket_id = 'images-quarantine'
  AND auth.jwt()->>'role' = 'service_role'
);

-- =====================================================
-- BUCKET 2: Público (Solo archivos aprobados)
-- =====================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'images',
  'images',
  true,  -- PÚBLICO (URLs directas)
  5242880,  -- 5 MB max
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Cualquiera puede VER imágenes públicas
CREATE POLICY "Public can view approved images"
ON storage.objects FOR SELECT
USING (bucket_id = 'images');

-- Service role puede subir/eliminar (para mover desde cuarentena)
CREATE POLICY "Service role can manage public images"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'images'
  AND auth.jwt()->>'role' = 'service_role'
)
WITH CHECK (
  bucket_id = 'images'
  AND auth.jwt()->>'role' = 'service_role'
);

-- =====================================================
-- TABLA GOSSIPS: Agregar storage_path
-- =====================================================
-- storage_path es la fuente de verdad (path canónico)
-- image_url es derivado (puede regenerarse)

ALTER TABLE gossips ADD COLUMN IF NOT EXISTS storage_path TEXT;
ALTER TABLE gossips ADD COLUMN IF NOT EXISTS thumbnail_storage_path TEXT;

COMMENT ON COLUMN gossips.storage_path IS
'Path canónico en storage (fuente de verdad). Formato: images/gossips/full/{gossipId}_{timestamp}.jpg';

COMMENT ON COLUMN gossips.thumbnail_storage_path IS
'Path canónico del thumbnail. Formato: images/gossips/thumb/{gossipId}_{timestamp}.jpg';

COMMENT ON COLUMN gossips.image_url IS
'URL pública (derivada de storage_path). Puede regenerarse.';

COMMENT ON COLUMN gossips.thumbnail_url IS
'URL pública del thumbnail (derivada de thumbnail_storage_path).';

-- =====================================================
-- FUNCIÓN: Cleanup de cuarentena
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_quarantine_files()
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
    WHERE bucket_id = 'images-quarantine'
      AND created_at < NOW() - INTERVAL '24 hours'
  LOOP
    -- Eliminar archivo
    DELETE FROM storage.objects
    WHERE bucket_id = 'images-quarantine'
      AND name = quarantine_record.name;

    deleted_count := deleted_count + 1;
  END LOOP;

  RAISE NOTICE 'Cleaned % files from quarantine', deleted_count;
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_quarantine_files IS
'Limpia archivos en cuarentena mayores a 24 horas. Ejecutar vía cron o manualmente.';

GRANT EXECUTE ON FUNCTION cleanup_quarantine_files TO service_role;

-- =====================================================
-- FUNCIÓN: Cleanup de imágenes huérfanas
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_orphaned_images()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER := 0;
  orphan_record RECORD;
BEGIN
  -- Encontrar imágenes en bucket público que no tienen gossip asociado
  -- y fueron creadas hace más de 7 días

  FOR orphan_record IN
    SELECT o.name
    FROM storage.objects o
    WHERE o.bucket_id = 'images'
      AND o.created_at < NOW() - INTERVAL '7 days'
      AND NOT EXISTS (
        SELECT 1 FROM gossips g
        WHERE g.storage_path = o.name
           OR g.thumbnail_storage_path = o.name
      )
  LOOP
    -- Eliminar imagen huérfana
    DELETE FROM storage.objects
    WHERE bucket_id = 'images' AND name = orphan_record.name;

    deleted_count := deleted_count + 1;
  END LOOP;

  RAISE NOTICE 'Cleaned % orphaned images', deleted_count;
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_orphaned_images IS
'Limpia imágenes públicas huérfanas (sin gossip asociado) mayores a 7 días.';

GRANT EXECUTE ON FUNCTION cleanup_orphaned_images TO service_role;

-- =====================================================
-- POLÍTICA RLS: UPDATE de media en gossips
-- =====================================================

-- Drop política restrictiva anterior
DROP POLICY IF EXISTS "Usuarios pueden editar sus propios drafts" ON gossips;
DROP POLICY IF EXISTS "Usuarios pueden editar sus gossips" ON gossips;

-- Nueva política: UPDATE solo en drafts
-- (La Edge Function usa service_role, no necesita esta política)
CREATE POLICY "Usuarios pueden editar drafts"
ON gossips
FOR UPDATE
USING (
  auth.uid() = created_by
  AND status = 'draft'
)
WITH CHECK (
  auth.uid() = created_by
  AND status = 'draft'
);

-- =====================================================
-- TESTS DE VERIFICACIÓN
-- =====================================================

-- Test 1: Ambos buckets existen
DO $$
DECLARE
  quarantine_exists BOOLEAN;
  public_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'images-quarantine')
  INTO quarantine_exists;

  SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'images')
  INTO public_exists;

  IF NOT quarantine_exists OR NOT public_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Buckets no creados';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Ambos buckets existen';
END $$;

-- Test 2: Cuarentena es privado, images es público
DO $$
DECLARE
  quarantine_public BOOLEAN;
  images_public BOOLEAN;
BEGIN
  SELECT public FROM storage.buckets WHERE id = 'images-quarantine'
  INTO quarantine_public;

  SELECT public FROM storage.buckets WHERE id = 'images'
  INTO images_public;

  IF quarantine_public OR NOT images_public THEN
    RAISE EXCEPTION '❌ TEST FAIL: Configuración de privacidad incorrecta';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Privacidad correcta (quarantine:private, images:public)';
END $$;

-- Test 3: Columnas storage_path agregadas
DO $$
DECLARE
  column_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'gossips'
      AND column_name = 'storage_path'
  ) INTO column_exists;

  IF NOT column_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Columna storage_path no existe';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Columnas storage_path agregadas';
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN 007
-- =====================================================
-- ✅ Bucket 'images-quarantine' (privado) creado
-- ✅ Bucket 'images' (público) creado
-- ✅ Políticas de seguridad configuradas
-- ✅ Columnas storage_path agregadas a gossips
-- ✅ Funciones de cleanup creadas
-- ✅ Tests pasando
--
-- Flujo de seguridad:
--   1. Upload → Cuarentena (privado)
--   2. Validar MIME + dimensiones
--   3. Moderar contenido
--   4. Aprobar → Mover a público + INSERT gossip
--   5. Rechazar → Eliminar de cuarentena
-- =====================================================
