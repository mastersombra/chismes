-- =====================================================
-- MIGRACIÓN 011: Agregar audio_storage_path a upsert_gossip_idempotent
-- =====================================================
-- Descripción: Actualiza RPC upsert_gossip_idempotent para soportar audio_storage_path
--
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

DROP FUNCTION IF EXISTS upsert_gossip_idempotent(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT);

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
'Crea gossip con idempotencia atómica usando INSERT ON CONFLICT. Soporta audio_storage_path.';

-- =====================================================
-- TEST DE VERIFICACIÓN
-- =====================================================

DO $$
DECLARE
  function_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc
    WHERE proname = 'upsert_gossip_idempotent'
  ) INTO function_exists;

  IF NOT function_exists THEN
    RAISE EXCEPTION '❌ TEST FAIL: Function upsert_gossip_idempotent not found';
  END IF;

  RAISE NOTICE '✅ TEST PASS: Function upsert_gossip_idempotent updated with audio_storage_path';
END $$;

-- =====================================================
-- RESUMEN DE MIGRACIÓN 011
-- =====================================================
-- ✅ RPC upsert_gossip_idempotent actualizado
-- ✅ Agregado parámetro p_audio_storage_path
-- ✅ Test pasando
-- =====================================================
