-- =====================================================
-- 017: Edición de perfil segura + configuración del usuario
-- =====================================================
-- 1. PERFIL: los clientes ya NO escriben en `profiles`. Antes podían poner
--    cualquier texto en bio/display_name y cualquier URL en avatar_url, sin
--    validar ni moderar. Ahora toda escritura pasa por la Edge Function
--    `update-profile` (service_role): valida, aplica sanciones, modera texto
--    y foto (fail-closed) y sube la foto al bucket `avatars`.
--
-- 2. @USUARIO: se puede cambiar una vez cada `username_change_cooldown_days`
--    (moderation_settings, 30 por defecto). Elegirlo por primera vez (alta
--    del perfil) no cuenta. Lo garantiza un trigger: aplica también a
--    service_role, así que ningún camino se lo salta.
--
-- 3. CONFIGURACIÓN: `user_settings` (notificaciones, nivel de privacidad,
--    mostrar email, mostrar actividad). No es contenido público ni se modera:
--    el dueño la lee y la cambia directo (RLS). Idioma y tema son locales
--    del teléfono y no viven aquí.
--
-- 4. AVATARS: bucket público (la foto se ve por su URL), solo escribe
--    service_role. Ruta: {user_id}/{timestamp}.{ext}. delete-account borra la
--    carpeta del usuario.
-- =====================================================

-- =====================================================
-- 1. PERFIL: columnas nuevas y fin de la escritura directa
-- =====================================================

ALTER TABLE profiles
  ADD COLUMN username_changed_at TIMESTAMPTZ,
  ADD COLUMN avatar_path TEXT;

COMMENT ON COLUMN profiles.username_changed_at IS
  'Último cambio de @usuario (NULL = nunca cambiado tras elegirlo). Lo pone el trigger';
COMMENT ON COLUMN profiles.avatar_path IS
  'Ruta de la foto en el bucket avatars ({user_id}/...). La escribe update-profile';

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON profiles;
REVOKE INSERT, UPDATE, DELETE ON TABLE profiles FROM anon, authenticated;
GRANT ALL ON TABLE profiles TO service_role;

INSERT INTO moderation_settings (key, value, description) VALUES
  ('username_change_cooldown_days', 30, 'Días mínimos entre dos cambios de @usuario (elegirlo por primera vez no cuenta)')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- 2. LÍMITE DE CAMBIO DE @USUARIO
-- =====================================================
-- Error con SQLSTATE propio para que update-profile lo distinga.

CREATE OR REPLACE FUNCTION public.enforce_username_change_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_days NUMERIC;
BEGIN
  IF NEW.username IS NOT DISTINCT FROM OLD.username THEN
    -- Nadie fija la fecha a mano (ni para saltarse el límite)
    NEW.username_changed_at := OLD.username_changed_at;
    RETURN NEW;
  END IF;

  -- Primera elección (alta del perfil): libre y sin iniciar el plazo
  IF OLD.username IS NULL THEN
    NEW.username_changed_at := OLD.username_changed_at;
    RETURN NEW;
  END IF;

  v_days := moderation_setting('username_change_cooldown_days', 30);
  IF OLD.username_changed_at IS NOT NULL
     AND OLD.username_changed_at > NOW() - make_interval(days => v_days::INT) THEN
    RAISE EXCEPTION 'username_cooldown'
      USING ERRCODE = 'P0010',
            DETAIL = (OLD.username_changed_at + make_interval(days => v_days::INT))::TEXT;
  END IF;

  NEW.username_changed_at := NOW();
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_username_change_cooldown() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER on_profile_username_change
  BEFORE UPDATE OF username, username_changed_at ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_username_change_cooldown();

-- =====================================================
-- 3. CONFIGURACIÓN DEL USUARIO
-- =====================================================

CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  comments_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  likes_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  follow_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  privacy_level TEXT NOT NULL DEFAULT 'public'
    CHECK (privacy_level IN ('public', 'private')),
  show_email BOOLEAN NOT NULL DEFAULT FALSE,
  show_activity BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE user_settings IS
  'Preferencias del usuario (una fila por usuario, creada al registrarse). El dueño la lee y la cambia';

CREATE TRIGGER on_user_settings_updated
  BEFORE UPDATE ON user_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE user_settings FROM anon, authenticated;
-- Sin INSERT/DELETE para clientes: la fila la crea el trigger y se borra con
-- la cuenta. UPDATE solo de las preferencias (no de user_id ni updated_at).
GRANT SELECT ON TABLE user_settings TO authenticated;
GRANT UPDATE (
  notifications_enabled, push_notifications, email_notifications,
  comments_notifications, likes_notifications, follow_notifications,
  privacy_level, show_email, show_activity
) ON TABLE user_settings TO authenticated;
GRANT ALL ON TABLE user_settings TO service_role;

CREATE POLICY "user_settings_select_own"
  ON user_settings FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_settings_update_own"
  ON user_settings FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.create_user_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_settings (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.create_user_settings() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER on_auth_user_created_settings
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_user_settings();

-- Usuarios que ya existían
INSERT INTO user_settings (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- 4. BUCKET DE FOTOS DE PERFIL
-- =====================================================
-- Sin políticas para clientes: ni suben ni listan (la foto se ve por su URL
-- pública). service_role ignora RLS. Regresión: storage_rls_e2e.test.ts

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  2097152,  -- 2 MB (la app sube ~50 KB: 400×400 JPEG)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
