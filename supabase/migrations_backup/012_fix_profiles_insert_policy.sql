-- =====================================================
-- Fix: Permitir INSERT en profiles para usuarios autenticados
-- =====================================================
--
-- PROBLEMA:
-- La política "profiles_insert_system_only" bloqueaba todos los INSERTs.
-- El trigger handle_new_user() debería crear perfiles automáticamente,
-- pero en algunos casos (OAuth, testing, etc.) puede fallar.
--
-- SOLUCIÓN:
-- Permitir que usuarios autenticados inserten su propio perfil.
-- El trigger sigue funcionando como backup.
--
-- =====================================================

-- Eliminar política restrictiva anterior
DROP POLICY IF EXISTS "profiles_insert_system_only" ON profiles;

-- Nueva política: Usuarios autenticados pueden insertar su propio perfil
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (
    auth.uid() = id  -- Solo puede insertar con su propio ID
  );

-- =====================================================
-- Verificación: Asegurar que el trigger sigue activo
-- =====================================================

-- El trigger handle_new_user() ya existe (migración 005)
-- Solo verificamos que siga existente

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'on_auth_user_created'
  ) THEN
    RAISE EXCEPTION 'Trigger on_auth_user_created no existe. Verificar migración 005.';
  END IF;
END $$;

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON POLICY "profiles_insert_own" ON profiles IS
  'Usuarios autenticados pueden insertar su propio perfil. El trigger handle_new_user() lo crea automáticamente, pero esta política permite creación manual si el trigger falla.';
