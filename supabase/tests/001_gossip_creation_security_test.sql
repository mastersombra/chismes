-- =====================================================
-- TEST DE SEGURIDAD: Prevención de bypass de moderación
-- =====================================================
-- Este test verifica que:
-- 1. INSERT directo con anon key → FALLA (403)
-- 2. RPC create_gossip_draft() → FUNCIONA correctamente
-- 3. Estados son controlados por servidor (no cliente)

BEGIN;

-- =====================================================
-- TEST 1: INSERT directo debe FALLAR
-- =====================================================
-- Simular usuario anon intentando INSERT directo
SET LOCAL ROLE anon;
SET LOCAL request.jwt.claims TO '{"role": "anon"}';

DO $$
BEGIN
  -- Intentar INSERT directo (debe fallar)
  INSERT INTO gossips (
    subject,
    content,
    country_id,
    region_id,
    city_id,
    published_as,
    status,              -- Intento de bypass
    moderation_status,   -- Intento de bypass
    visibility,          -- Intento de bypass
    created_by
  ) VALUES (
    'Test bypass',
    'Este gossip intenta bypasear moderación',
    'COL',
    'ANT',
    'MED',
    'anonymous',
    'published',         -- ❌ Bypass intento
    'approved',          -- ❌ Bypass intento
    'public',            -- ❌ Bypass intento
    'fake-user-123'      -- ❌ Falsificación intento
  );

  -- Si llegamos aquí, el test FALLA
  RAISE EXCEPTION 'SECURITY BREACH: INSERT directo NO fue bloqueado!';

EXCEPTION
  WHEN insufficient_privilege OR check_violation THEN
    -- ✅ Correcto: INSERT fue bloqueado
    RAISE NOTICE 'TEST 1 PASSED: INSERT directo fue bloqueado correctamente';
  WHEN OTHERS THEN
    -- ❌ Error inesperado
    RAISE EXCEPTION 'TEST 1 FAILED: Error inesperado: %', SQLERRM;
END;
$$;

-- =====================================================
-- TEST 2: RPC debe funcionar correctamente
-- =====================================================
-- Simular usuario autenticado usando RPC
RESET ROLE;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "test-user-123", "role": "authenticated"}';

DO $$
DECLARE
  v_result JSON;
  v_gossip_id UUID;
  v_status TEXT;
  v_moderation_status TEXT;
  v_visibility TEXT;
  v_created_by TEXT;
BEGIN
  -- Llamar RPC para crear gossip
  SELECT create_gossip_draft(
    p_subject := 'Test RPC',
    p_content := 'Este gossip se crea correctamente vía RPC',
    p_country_id := 'COL',
    p_region_id := 'ANT',
    p_city_id := 'MED',
    p_published_as := 'anonymous',
    p_audio_url := NULL,
    p_image_url := NULL,
    p_idempotency_key := NULL
  ) INTO v_result;

  -- Extraer ID del resultado
  v_gossip_id := (v_result->>'id')::UUID;

  IF v_gossip_id IS NULL THEN
    RAISE EXCEPTION 'TEST 2 FAILED: RPC no retornó un ID válido';
  END IF;

  -- Verificar que el gossip existe en la DB
  SELECT status, moderation_status, visibility, created_by
  INTO v_status, v_moderation_status, v_visibility, v_created_by
  FROM gossips
  WHERE id = v_gossip_id;

  -- Verificar estados forzados por servidor
  IF v_status != 'draft' THEN
    RAISE EXCEPTION 'TEST 2 FAILED: status debería ser draft pero es: %', v_status;
  END IF;

  IF v_moderation_status != 'pending' THEN
    RAISE EXCEPTION 'TEST 2 FAILED: moderation_status debería ser pending pero es: %', v_moderation_status;
  END IF;

  IF v_visibility != 'private' THEN
    RAISE EXCEPTION 'TEST 2 FAILED: visibility debería ser private pero es: %', v_visibility;
  END IF;

  IF v_created_by != 'test-user-123' THEN
    RAISE EXCEPTION 'TEST 2 FAILED: created_by debería ser test-user-123 pero es: %', v_created_by;
  END IF;

  -- ✅ Todos los checks pasaron
  RAISE NOTICE 'TEST 2 PASSED: RPC funcionó correctamente y estados son controlados por servidor';

  -- Limpiar gossip de test
  DELETE FROM gossips WHERE id = v_gossip_id;

END;
$$;

-- =====================================================
-- TEST 3: RPC sin auth debe FALLAR
-- =====================================================
RESET ROLE;
SET LOCAL ROLE anon;
SET LOCAL request.jwt.claims TO '{"role": "anon"}'; -- Sin 'sub'

DO $$
DECLARE
  v_result JSON;
BEGIN
  -- Intentar RPC sin autenticación (debe fallar)
  SELECT create_gossip_draft(
    p_subject := 'Test sin auth',
    p_content := 'Este gossip intenta crearse sin autenticación',
    p_country_id := 'COL',
    p_region_id := 'ANT',
    p_city_id := 'MED',
    p_published_as := 'anonymous',
    p_audio_url := NULL,
    p_image_url := NULL,
    p_idempotency_key := NULL
  ) INTO v_result;

  -- Si llegamos aquí, el test FALLA
  RAISE EXCEPTION 'TEST 3 FAILED: RPC sin auth NO fue bloqueado!';

EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM LIKE '%Authentication required%' THEN
      -- ✅ Correcto: RPC rechazó usuario no autenticado
      RAISE NOTICE 'TEST 3 PASSED: RPC rechazó correctamente usuario sin auth';
    ELSE
      -- ❌ Error inesperado
      RAISE EXCEPTION 'TEST 3 FAILED: Error inesperado: %', SQLERRM;
    END IF;
END;
$$;

-- =====================================================
-- TEST 4: Idempotencia debe prevenir duplicados
-- =====================================================
RESET ROLE;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "test-user-456", "role": "authenticated"}';

DO $$
DECLARE
  v_result1 JSON;
  v_result2 JSON;
  v_gossip_id1 UUID;
  v_gossip_id2 UUID;
  v_is_duplicate BOOLEAN;
  v_idempotency_key UUID := gen_random_uuid();
BEGIN
  -- Primera llamada: crear gossip
  SELECT create_gossip_draft(
    p_subject := 'Test idempotencia',
    p_content := 'Primer intento',
    p_country_id := 'COL',
    p_region_id := 'ANT',
    p_city_id := 'MED',
    p_published_as := 'anonymous',
    p_audio_url := NULL,
    p_image_url := NULL,
    p_idempotency_key := v_idempotency_key
  ) INTO v_result1;

  v_gossip_id1 := (v_result1->>'id')::UUID;

  -- Segunda llamada: misma idempotency_key (debe retornar el mismo gossip)
  SELECT create_gossip_draft(
    p_subject := 'Test idempotencia DUPLICADO',
    p_content := 'Segundo intento (debería ser ignorado)',
    p_country_id := 'COL',
    p_region_id := 'ANT',
    p_city_id := 'MED',
    p_published_as := 'anonymous',
    p_audio_url := NULL,
    p_image_url := NULL,
    p_idempotency_key := v_idempotency_key
  ) INTO v_result2;

  v_gossip_id2 := (v_result2->>'id')::UUID;
  v_is_duplicate := (v_result2->>'is_duplicate')::BOOLEAN;

  -- Verificar que retornó el MISMO gossip
  IF v_gossip_id1 != v_gossip_id2 THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Idempotencia no funcionó. ID1: %, ID2: %', v_gossip_id1, v_gossip_id2;
  END IF;

  IF v_is_duplicate IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST 4 FAILED: is_duplicate debería ser true';
  END IF;

  -- Verificar que solo existe UN gossip en la DB
  IF (SELECT COUNT(*) FROM gossips WHERE id = v_gossip_id1) != 1 THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Se crearon múltiples gossips con la misma idempotency_key';
  END IF;

  -- ✅ Idempotencia funciona correctamente
  RAISE NOTICE 'TEST 4 PASSED: Idempotencia previene duplicados correctamente';

  -- Limpiar
  DELETE FROM gossips WHERE id = v_gossip_id1;

END;
$$;

-- =====================================================
-- RESUMEN
-- =====================================================
RAISE NOTICE '========================================';
RAISE NOTICE 'TODOS LOS TESTS DE SEGURIDAD PASARON ✅';
RAISE NOTICE '========================================';
RAISE NOTICE '1. INSERT directo → BLOQUEADO';
RAISE NOTICE '2. RPC create_gossip_draft() → FUNCIONA';
RAISE NOTICE '3. Estados controlados por servidor → OK';
RAISE NOTICE '4. Auth requerida → OK';
RAISE NOTICE '5. Idempotencia → OK';
RAISE NOTICE '========================================';

ROLLBACK;
