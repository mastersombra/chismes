-- =====================================================
-- Tabla de Profiles (User Profiles)
-- =====================================================
-- Tabla complementaria a auth.users para datos de perfil público.
--
-- ✅ INCLUYE:
-- - Relación 1:1 con auth.users
-- - Username único (validación)
-- - Registro progresivo (profile_completed flag)
-- - Trigger automático para crear profile al registrar usuario
-- - Row Level Security (RLS) con políticas
-- - Índices para búsquedas
--
-- 🔒 SEGURIDAD:
-- - RLS habilitado
-- - Solo el dueño puede actualizar su perfil
-- - Todos pueden leer perfiles públicos
-- - Username único y validado
-- =====================================================

-- Tabla de perfiles de usuario
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Identidad
  username TEXT UNIQUE CHECK (
    username IS NULL OR (
      char_length(username) >= 3 AND
      char_length(username) <= 30 AND
      username ~ '^[a-z0-9_]+$'  -- Solo minúsculas, números y guión bajo
    )
  ),
  display_name TEXT CHECK (
    display_name IS NULL OR (
      char_length(display_name) >= 1 AND
      char_length(display_name) <= 50
    )
  ),

  -- Visual
  avatar_url TEXT,
  bio TEXT CHECK (
    bio IS NULL OR char_length(bio) <= 160
  ),

  -- Progreso de perfil
  profile_completed BOOLEAN DEFAULT FALSE,

  -- Metadatos
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para búsqueda por username (case-insensitive)
CREATE INDEX idx_profiles_username_lower
ON profiles(LOWER(username));

-- Índice para perfiles completos
CREATE INDEX idx_profiles_completed
ON profiles(profile_completed)
WHERE profile_completed = TRUE;

-- =====================================================
-- FUNCIÓN: Auto-crear profile al registrar usuario
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, profile_completed)
  VALUES (
    NEW.id,
    NULL,  -- Username se configura después
    COALESCE(NEW.raw_user_meta_data->>'display_name', NULL),
    FALSE
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER: Ejecutar handle_new_user al crear usuario
-- =====================================================

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- FUNCIÓN: Actualizar updated_at automáticamente
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER: Actualizar updated_at en cada UPDATE
-- =====================================================

CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden leer perfiles públicos
CREATE POLICY "profiles_select_all"
  ON profiles FOR SELECT
  USING (TRUE);

-- Política: Solo el dueño puede actualizar su perfil
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Política: Solo el sistema puede insertar (via trigger)
-- Los usuarios NO pueden insertar directamente
CREATE POLICY "profiles_insert_system_only"
  ON profiles FOR INSERT
  WITH CHECK (FALSE);  -- Nadie puede insertar manualmente

-- Política: Solo el dueño puede eliminar su perfil
CREATE POLICY "profiles_delete_own"
  ON profiles FOR DELETE
  USING (auth.uid() = id);

-- =====================================================
-- FUNCIÓN: Validar username disponible
-- =====================================================

CREATE OR REPLACE FUNCTION public.is_username_available(check_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE LOWER(username) = LOWER(check_username)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCIÓN: Calcular completitud de perfil
-- =====================================================

CREATE OR REPLACE FUNCTION public.calculate_profile_completion(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  completion_percentage INTEGER := 0;
  profile_record RECORD;
BEGIN
  SELECT * INTO profile_record FROM profiles WHERE id = user_id;

  IF profile_record IS NULL THEN
    RETURN 0;
  END IF;

  -- Email siempre existe (viene de auth.users) = 25%
  completion_percentage := 25;

  -- Username = 25%
  IF profile_record.username IS NOT NULL THEN
    completion_percentage := completion_percentage + 25;
  END IF;

  -- Display name = 25%
  IF profile_record.display_name IS NOT NULL THEN
    completion_percentage := completion_percentage + 25;
  END IF;

  -- Avatar = 25%
  IF profile_record.avatar_url IS NOT NULL THEN
    completion_percentage := completion_percentage + 25;
  END IF;

  RETURN completion_percentage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGER: Auto-actualizar profile_completed flag
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_profile_completed()
RETURNS TRIGGER AS $$
BEGIN
  -- Perfil se considera completo si tiene username y display_name
  NEW.profile_completed := (
    NEW.username IS NOT NULL AND
    NEW.display_name IS NOT NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_completion_check
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_profile_completed();

-- =====================================================
-- COMENTARIOS (Documentación de columnas)
-- =====================================================

COMMENT ON TABLE profiles IS 'Perfiles públicos de usuarios, complementa auth.users';
COMMENT ON COLUMN profiles.id IS 'FK a auth.users(id), relación 1:1';
COMMENT ON COLUMN profiles.username IS 'Username único, 3-30 chars, solo [a-z0-9_]';
COMMENT ON COLUMN profiles.display_name IS 'Nombre a mostrar, 1-50 chars';
COMMENT ON COLUMN profiles.avatar_url IS 'URL de avatar (Supabase Storage)';
COMMENT ON COLUMN profiles.bio IS 'Biografía corta, max 160 chars';
COMMENT ON COLUMN profiles.profile_completed IS 'Flag automático: username + display_name completos';

-- =====================================================
-- DATOS DE PRUEBA (Solo para desarrollo)
-- =====================================================

-- Nota: En producción, los profiles se crean automáticamente
-- via trigger al registrar usuarios con auth.signUp()
