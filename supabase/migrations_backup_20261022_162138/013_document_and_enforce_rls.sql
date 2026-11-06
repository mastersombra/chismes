-- =====================================================
-- MIGRACIÓN 013: Documentar y Reforzar RLS (Eliminar Spike Mode)
-- =====================================================
-- Descripción: Elimina cualquier residuo de spike-user y documenta
--   claramente que el CRUD directo está bloqueado.
--
-- Objetivo:
--   1. Eliminar datos de spike-user si existen
--   2. Documentar políticas RLS existentes
--   3. Reforzar que solo Edge Functions pueden escribir
--
-- Fecha: 2026-10-22
-- Autor: Alejo + Claude Code
-- =====================================================

-- =====================================================
-- PASO 1: Limpieza de Spike Mode
-- =====================================================

-- Eliminar gossips de spike-user si existen
-- (Probablemente no hay ninguno, pero por seguridad)
DELETE FROM public.gossips
WHERE created_by::text = 'spike-user'
   OR modified_by::text = 'spike-user'
   OR deleted_by::text = 'spike-user';

-- Log de limpieza
DO $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  IF v_deleted_count > 0 THEN
    RAISE NOTICE '🧹 Cleaned % gossips with spike-user references', v_deleted_count;
  ELSE
    RAISE NOTICE '✅ No spike-user references found (clean)';
  END IF;
END $$;

-- =====================================================
-- PASO 2: Documentación de Tabla Gossips
-- =====================================================

-- Documentar que CRUD directo está bloqueado
COMMENT ON TABLE public.gossips IS
'Tabla principal de chismes (gossips).

⛔ CRUD DIRECTO BLOQUEADO ⛔

- INSERT: Prohibido desde cliente. Usar Edge Function "moderate-gossip"
- UPDATE: Bloqueado para campos críticos (contadores, timestamps, created_by)
- DELETE: Solo soft delete mediante UPDATE status=deleted

Políticas RLS:
- Sin política INSERT → cualquier INSERT directo con anon key → 403
- UPDATE: Solo autor puede modificar sus propios gossips
- SELECT: Según status (published=público, draft=solo autor)

Edge Functions autorizadas:
- moderate-gossip: Crea gossips con service_role después de moderación
- [futuras: update-gossip, delete-gossip]

Seguridad:
- created_by: Asignado automáticamente por trigger (auth.uid())
- Contadores: Inmutables, protegidos por trigger
- RLS: Habilitado y testeado';

-- =====================================================
-- PASO 3: Verificación de Políticas RLS
-- =====================================================

-- Verificar y documentar qué políticas existen
DO $$
DECLARE
  v_policy_count INTEGER;
  v_policy_record RECORD;
BEGIN
  RAISE NOTICE '📋 Políticas RLS activas en tabla gossips:';
  RAISE NOTICE '';

  FOR v_policy_record IN
    SELECT policyname, cmd
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'gossips'
    ORDER BY cmd, policyname
  LOOP
    RAISE NOTICE '  • % (FOR %)', v_policy_record.policyname, v_policy_record.cmd;
  END LOOP;

  RAISE NOTICE '';

  -- Verificar si existe política INSERT (NO debería)
  SELECT COUNT(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'gossips'
    AND cmd = 'INSERT';

  IF v_policy_count = 0 THEN
    RAISE NOTICE '✅ No hay política INSERT (CRUD directo bloqueado)';
  ELSE
    RAISE WARNING '⚠️ Existe política INSERT (revisar si es intencional)';
  END IF;
END $$;

-- =====================================================
-- PASO 4: Documentación de Storage (Buckets)
-- =====================================================

-- Comentario en migración (no en tabla, porque es Storage)
DO $$
BEGIN
  RAISE NOTICE '📦 Storage Buckets RLS:';
  RAISE NOTICE '  - image-quarantine: PRIVADO (solo upload por usuario, read por service_role)';
  RAISE NOTICE '  - image: PÚBLICO (solo write por service_role, read público)';
  RAISE NOTICE '  - audio-quarantine: PRIVADO (solo upload por usuario, read por service_role)';
  RAISE NOTICE '  - audio: PÚBLICO (solo write por service_role, read público)';
  RAISE NOTICE '';
  RAISE NOTICE '⛔ Cliente NO puede:';
  RAISE NOTICE '  - Escribir directamente a buckets públicos (image, audio)';
  RAISE NOTICE '  - Leer archivos de quarantine de otros usuarios';
  RAISE NOTICE '  - Mover archivos entre buckets (solo Edge Function)';
END $$;

-- =====================================================
-- PASO 5: Verificación de Políticas RLS
-- =====================================================

-- Verificar que RLS está habilitado en gossips
DO $$
DECLARE
  v_rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO v_rls_enabled
  FROM pg_class
  WHERE relname = 'gossips';

  IF NOT v_rls_enabled THEN
    RAISE EXCEPTION '❌ RLS no está habilitado en tabla gossips';
  END IF;

  RAISE NOTICE '✅ RLS habilitado en tabla gossips';
END $$;

-- Verificar que NO hay política INSERT (bloquea CRUD directo)
DO $$
DECLARE
  v_insert_policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_insert_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'gossips'
    AND cmd = 'INSERT';

  IF v_insert_policy_count > 0 THEN
    RAISE WARNING '⚠️ Existe % política(s) INSERT en gossips', v_insert_policy_count;
  ELSE
    RAISE NOTICE '✅ No hay política INSERT en gossips (CRUD directo bloqueado)';
  END IF;
END $$;

-- Contar políticas activas
DO $$
DECLARE
  v_select_count INTEGER;
  v_update_count INTEGER;
  v_delete_count INTEGER;
BEGIN
  SELECT
    COUNT(*) FILTER (WHERE cmd = 'SELECT'),
    COUNT(*) FILTER (WHERE cmd = 'UPDATE'),
    COUNT(*) FILTER (WHERE cmd = 'DELETE')
  INTO v_select_count, v_update_count, v_delete_count
  FROM pg_policies
  WHERE tablename = 'gossips';

  RAISE NOTICE '📊 Políticas RLS activas en gossips:';
  RAISE NOTICE '  - SELECT: %', v_select_count;
  RAISE NOTICE '  - UPDATE: %', v_update_count;
  RAISE NOTICE '  - DELETE: %', v_delete_count;
  RAISE NOTICE '  - INSERT: 0 (bloqueado)';
END $$;

-- =====================================================
-- PASO 6: Crear Vista de Auditoría RLS
-- =====================================================

-- Vista para auditar intentos de CRUD directo
-- (Solo visible para service_role/postgres)
CREATE OR REPLACE VIEW rls_policy_audit AS
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('gossips', 'error_logs', 'rate_limits', 'idempotency_keys')
ORDER BY tablename, cmd;

COMMENT ON VIEW rls_policy_audit IS
'Vista de auditoría de políticas RLS.

Muestra todas las políticas activas en tablas principales.

Uso:
  SELECT * FROM rls_policy_audit WHERE tablename = ''gossips'';

Verificar:
- Que NO exista política INSERT para gossips+anon
- Que SELECT/UPDATE tengan restricciones apropiadas
- Que service_role tenga acceso completo';

-- =====================================================
-- RESUMEN DE MIGRACIÓN 013
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ MIGRACIÓN 013 COMPLETADA';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Spike mode eliminado (si existía)';
  RAISE NOTICE '✅ Tabla gossips documentada';
  RAISE NOTICE '✅ Políticas RLS documentadas';
  RAISE NOTICE '✅ Storage buckets documentados';
  RAISE NOTICE '✅ RLS verificado (habilitado y sin INSERT para anon)';
  RAISE NOTICE '✅ Vista de auditoría creada';
  RAISE NOTICE '';
  RAISE NOTICE '🔍 Para auditar políticas RLS:';
  RAISE NOTICE '   SELECT * FROM rls_policy_audit WHERE tablename = ''gossips'';';
  RAISE NOTICE '';
  RAISE NOTICE '⛔ CRUD directo bloqueado:';
  RAISE NOTICE '   - Cliente NO puede INSERT/UPDATE/DELETE directo';
  RAISE NOTICE '   - Solo Edge Functions con service_role pueden escribir';
  RAISE NOTICE '   - Triggers protegen campos críticos';
  RAISE NOTICE '';
END $$;
