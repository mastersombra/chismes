-- =====================================================
-- Tests de Seguridad: Políticas RLS
-- =====================================================
-- Verifica que las políticas RLS funcionan correctamente
-- después del fix P0-03 (eliminación de spike-user)
--
-- Ejecutar en Supabase Dashboard SQL Editor:
-- 1. Copia todo este archivo
-- 2. Pégalo en SQL Editor
-- 3. Click "Run"
--
-- Todos los tests deben PASAR ✅
-- =====================================================

BEGIN;

-- Setup: Crear usuarios de prueba
-- NOTA: Esto usa funciones de auth que solo funcionan con service_role
-- En Dashboard, estos usuarios deben existir previamente

-- Variables de prueba (reemplazar con UUIDs reales)
DO $$
DECLARE
  user_a_id UUID := '00000000-0000-0000-0000-000000000001'::UUID;
  user_b_id UUID := '00000000-0000-0000-0000-000000000002'::UUID;
  test_passed BOOLEAN;
  test_count INTEGER := 0;
  passed_count INTEGER := 0;
BEGIN
  RAISE NOTICE '🧪 Iniciando tests de políticas RLS...';
  RAISE NOTICE '';

  -- =====================================================
  -- TEST 1: Usuario A no puede ver drafts de Usuario B
  -- =====================================================
  RAISE NOTICE '📝 TEST 1: Aislamiento de drafts entre usuarios';

  -- Insertar draft del Usuario B (como admin)
  INSERT INTO gossips (
    id,
    subject,
    content,
    country_id,
    region_id,
    city_id,
    published_as,
    status,
    moderation_status,
    visibility,
    created_by
  ) VALUES (
    gen_random_uuid(),
    'Draft secreto de B',
    'Contenido privado',
    'CO',
    '34',
    '3688689',
    'anonymous',
    'draft',
    'pending',
    'private',
    user_b_id
  );

  -- Intentar leer como Usuario A
  SET LOCAL request.jwt.claims = json_build_object('sub', user_a_id)::text;

  SELECT NOT EXISTS (
    SELECT 1 FROM gossips
    WHERE created_by = user_b_id
      AND status = 'draft'
  ) INTO test_passed;

  test_count := test_count + 1;
  IF test_passed THEN
    passed_count := passed_count + 1;
    RAISE NOTICE '   ✅ PASS: Usuario A no puede ver drafts de B';
  ELSE
    RAISE NOTICE '   ❌ FAIL: Usuario A puede ver drafts de B (vulnerabilidad)';
  END IF;

  -- =====================================================
  -- TEST 2: Usuario A puede ver sus propios drafts
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '📝 TEST 2: Usuario puede ver sus propios drafts';

  -- Insertar draft del Usuario A
  INSERT INTO gossips (
    id,
    subject,
    content,
    country_id,
    region_id,
    city_id,
    published_as,
    status,
    moderation_status,
    visibility,
    created_by
  ) VALUES (
    gen_random_uuid(),
    'Mi draft',
    'Mi contenido',
    'CO',
    '34',
    '3688689',
    'anonymous',
    'draft',
    'pending',
    'private',
    user_a_id
  );

  -- Leer como Usuario A
  SET LOCAL request.jwt.claims = json_build_object('sub', user_a_id)::text;

  SELECT EXISTS (
    SELECT 1 FROM gossips
    WHERE created_by = user_a_id
      AND status = 'draft'
  ) INTO test_passed;

  test_count := test_count + 1;
  IF test_passed THEN
    passed_count := passed_count + 1;
    RAISE NOTICE '   ✅ PASS: Usuario A puede ver sus propios drafts';
  ELSE
    RAISE NOTICE '   ❌ FAIL: Usuario A no puede ver sus propios drafts (bug)';
  END IF;

  -- =====================================================
  -- TEST 3: Gossips públicos visibles para todos
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '📝 TEST 3: Gossips públicos visibles sin autenticación';

  -- Insertar gossip público
  INSERT INTO gossips (
    id,
    subject,
    content,
    country_id,
    region_id,
    city_id,
    published_as,
    status,
    moderation_status,
    visibility,
    created_by
  ) VALUES (
    gen_random_uuid(),
    'Gossip público',
    'Visible para todos',
    'CO',
    '34',
    '3688689',
    'anonymous',
    'published',
    'approved',
    'public',
    user_a_id
  );

  -- Leer sin autenticación (anon)
  SET LOCAL request.jwt.claims = NULL;

  SELECT EXISTS (
    SELECT 1 FROM gossips
    WHERE status = 'published'
      AND moderation_status = 'approved'
      AND visibility = 'public'
  ) INTO test_passed;

  test_count := test_count + 1;
  IF test_passed THEN
    passed_count := passed_count + 1;
    RAISE NOTICE '   ✅ PASS: Gossips públicos son visibles para todos';
  ELSE
    RAISE NOTICE '   ❌ FAIL: Gossips públicos no son visibles (bug)';
  END IF;

  -- =====================================================
  -- TEST 4: No existen gossips con spike-user
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '📝 TEST 4: No existen referencias a spike-user';

  SELECT NOT EXISTS (
    SELECT 1 FROM gossips
    WHERE created_by::text = 'spike-user'
       OR modified_by::text = 'spike-user'
       OR deleted_by::text = 'spike-user'
  ) INTO test_passed;

  test_count := test_count + 1;
  IF test_passed THEN
    passed_count := passed_count + 1;
    RAISE NOTICE '   ✅ PASS: No hay referencias a spike-user';
  ELSE
    RAISE NOTICE '   ❌ FAIL: Existen referencias a spike-user (no limpiado)';
  END IF;

  -- =====================================================
  -- TEST 5: created_by debe ser UUID válido
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '📝 TEST 5: Todos los created_by son UUID válidos';

  SELECT NOT EXISTS (
    SELECT 1 FROM gossips
    WHERE created_by IS NULL
  ) INTO test_passed;

  test_count := test_count + 1;
  IF test_passed THEN
    passed_count := passed_count + 1;
    RAISE NOTICE '   ✅ PASS: Todos los created_by son UUID válidos';
  ELSE
    RAISE NOTICE '   ❌ FAIL: Existen created_by NULL (bug)';
  END IF;

  -- =====================================================
  -- TEST 6: INSERT directo falla sin política
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '📝 TEST 6: INSERT directo desde cliente falla';

  -- Intentar INSERT como anon (sin service_role)
  SET LOCAL request.jwt.claims = json_build_object('sub', user_a_id)::text;
  SET LOCAL role = 'anon';

  BEGIN
    INSERT INTO gossips (
      subject,
      content,
      country_id,
      region_id,
      city_id,
      published_as,
      created_by
    ) VALUES (
      'Intento malicioso',
      'Bypass moderación',
      'CO',
      '34',
      '3688689',
      'anonymous',
      user_a_id
    );

    -- Si llegó aquí, el INSERT pasó (MAL)
    test_passed := FALSE;
    RAISE NOTICE '   ❌ FAIL: INSERT directo permitido (vulnerabilidad)';

  EXCEPTION WHEN insufficient_privilege THEN
    -- Se esperaba este error (BIEN)
    test_passed := TRUE;
    RAISE NOTICE '   ✅ PASS: INSERT directo bloqueado correctamente';
  END;

  test_count := test_count + 1;
  IF test_passed THEN
    passed_count := passed_count + 1;
  END IF;

  -- =====================================================
  -- TEST 7: Usuario no puede modificar created_by
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '📝 TEST 7: Usuario no puede falsificar created_by';

  DECLARE
    test_gossip_id UUID;
  BEGIN
    -- Crear gossip como Usuario A
    INSERT INTO gossips (
      id,
      subject,
      content,
      country_id,
      region_id,
      city_id,
      published_as,
      status,
      created_by
    ) VALUES (
      gen_random_uuid(),
      'Test',
      'Test',
      'CO',
      '34',
      '3688689',
      'anonymous',
      'draft',
      user_a_id
    ) RETURNING id INTO test_gossip_id;

    -- Intentar cambiar created_by a Usuario B
    SET LOCAL request.jwt.claims = json_build_object('sub', user_a_id)::text;

    UPDATE gossips
    SET created_by = user_b_id
    WHERE id = test_gossip_id;

    -- Verificar que created_by NO cambió (protegido por trigger)
    SELECT created_by = user_a_id
    FROM gossips
    WHERE id = test_gossip_id
    INTO test_passed;

    test_count := test_count + 1;
    IF test_passed THEN
      passed_count := passed_count + 1;
      RAISE NOTICE '   ✅ PASS: created_by protegido por trigger';
    ELSE
      RAISE NOTICE '   ❌ FAIL: created_by puede ser modificado (vulnerabilidad)';
    END IF;
  END;

  -- =====================================================
  -- RESUMEN
  -- =====================================================
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
  RAISE NOTICE '📊 RESUMEN DE TESTS';
  RAISE NOTICE '================================================';
  RAISE NOTICE 'Total:   % tests', test_count;
  RAISE NOTICE 'Pasados: % tests ✅', passed_count;
  RAISE NOTICE 'Fallidos: % tests ❌', (test_count - passed_count);
  RAISE NOTICE '';

  IF passed_count = test_count THEN
    RAISE NOTICE '🎉 TODOS LOS TESTS PASARON';
    RAISE NOTICE '✅ El fix P0-03 está funcionando correctamente';
  ELSE
    RAISE NOTICE '⚠️ ALGUNOS TESTS FALLARON';
    RAISE NOTICE '❌ Revisar políticas RLS y triggers';
  END IF;

  RAISE NOTICE '================================================';

END $$;

ROLLBACK;

-- =====================================================
-- NOTAS DE USO
-- =====================================================
-- Este script usa ROLLBACK al final para no dejar datos de prueba.
--
-- Para ejecutar estos tests necesitas:
-- 1. Tener usuarios creados en auth.users
-- 2. Reemplazar los UUIDs de prueba con UUIDs reales
-- 3. Ejecutar con privilegios de service_role (Dashboard SQL Editor)
--
-- IMPORTANTE: No ejecutar en producción sin backup.
-- =====================================================
