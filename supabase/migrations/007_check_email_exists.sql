-- =====================================================
-- Función RPC: Verificar si un email existe y está confirmado
-- =====================================================
-- Esta función permite verificar desde el cliente si un email
-- ya está registrado y confirmado, sin exponer datos sensibles.
--
-- Retorna:
-- - true: Email existe y está confirmado (no permitir registro)
-- - false: Email no existe O existe pero no está confirmado (permitir registro/reenvío)
--
-- SEGURIDAD: Esta función es pública pero solo retorna boolean,
-- no expone información sensible de usuarios.
-- =====================================================

CREATE OR REPLACE FUNCTION public.check_email_exists_and_confirmed(
  email_to_check TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  email_confirmed TIMESTAMPTZ;
BEGIN
  -- Buscar el email en auth.users y obtener email_confirmed_at
  SELECT email_confirmed_at INTO email_confirmed
  FROM auth.users
  WHERE email = email_to_check;

  -- Retornar true solo si el email existe Y está confirmado
  RETURN email_confirmed IS NOT NULL;
END;
$$;

-- =====================================================
-- PERMISOS
-- =====================================================

-- Permitir que usuarios autenticados y anónimos llamen a esta función
GRANT EXECUTE ON FUNCTION public.check_email_exists_and_confirmed(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.check_email_exists_and_confirmed(TEXT) TO authenticated;

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON FUNCTION public.check_email_exists_and_confirmed IS
'Verifica si un email existe y está confirmado. Retorna true si está registrado y confirmado, false en caso contrario. Usada para prevenir registros duplicados en la UI.';
