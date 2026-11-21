-- =====================================================
-- 014: Eliminación de cuenta — registro anónimo de faltas
-- =====================================================
-- Flujo de la Edge Function delete-account:
--
--   1. get_account_deletion_media(): rutas de la media de sus chismes
--      (storage_path: fuente de verdad) y la que espera revisión en cuarentena. La función la borra con la
--      Storage API; lo que falle lo recoge cleanup-media (huérfana > 7 días).
--   2. delete_user_account(): en UNA transacción guarda el registro anónimo de
--      faltas (si tuvo alguna) y borra auth.users. Por ON DELETE CASCADE se
--      van chismes, perfil, reportes e historial en moderation_queue. Si algo
--      falla no queda nada a medias (ni registro duplicado al reintentar).
--
-- Registro anónimo: huella HMAC-SHA256 del email (la calcula la función con el
-- secret ACCOUNT_HASH_SECRET: sin él no se puede revertir ni probar emails
-- por diccionario) + conteo de rechazos por gravedad. Sin user_id, sin
-- contenido, sin motivos. Base de las sanciones: quien borra la cuenta y se
-- registra con el mismo email no vuelve "limpio".
--
-- Acceso: solo service_role (delete-account).
-- =====================================================

CREATE TABLE account_deletion_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- HMAC-SHA256 (hex) del email normalizado (trim + minúsculas)
  email_hash TEXT NOT NULL UNIQUE CHECK (email_hash ~ '^[0-9a-f]{64}$'),
  -- Rechazos de moderación por gravedad (acumulados si se repite)
  rejections_low INTEGER NOT NULL DEFAULT 0 CHECK (rejections_low >= 0),
  rejections_medium INTEGER NOT NULL DEFAULT 0 CHECK (rejections_medium >= 0),
  rejections_high INTEGER NOT NULL DEFAULT 0 CHECK (rejections_high >= 0),
  rejections_critical INTEGER NOT NULL DEFAULT 0 CHECK (rejections_critical >= 0),
  last_rejection_at TIMESTAMPTZ,
  deletion_count INTEGER NOT NULL DEFAULT 1 CHECK (deletion_count >= 1),
  first_deleted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_deleted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE account_deletion_records ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE account_deletion_records FROM anon, authenticated;
GRANT ALL ON TABLE account_deletion_records TO service_role;

COMMENT ON TABLE account_deletion_records IS
'Registro anónimo de faltas de cuentas eliminadas (huella HMAC del email + rechazos por gravedad). Solo si tuvo faltas. Solo backend (delete-account).';

-- =====================================================
-- get_account_deletion_media(): media a borrar (solo lectura)
-- =====================================================
CREATE OR REPLACE FUNCTION get_account_deletion_media(p_user_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    -- Rutas en los buckets públicos (images: full + thumb; audio)
    'image_paths', COALESCE((
      SELECT jsonb_agg(DISTINCT p)
      FROM gossips g,
           LATERAL unnest(ARRAY[g.storage_path, g.thumbnail_storage_path]) AS p
      WHERE g.created_by = p_user_id AND p IS NOT NULL
    ), '[]'::jsonb),
    'audio_paths', COALESCE((
      SELECT jsonb_agg(DISTINCT audio_storage_path)
      FROM gossips
      WHERE created_by = p_user_id AND audio_storage_path IS NOT NULL
    ), '[]'::jsonb),
    -- Media en cuarentena que espera revisión
    'image_quarantine_paths', COALESCE((
      SELECT jsonb_agg(DISTINCT image_quarantine_path)
      FROM moderation_queue
      WHERE content_author_id = p_user_id AND image_quarantine_path IS NOT NULL
    ), '[]'::jsonb),
    'audio_quarantine_paths', COALESCE((
      SELECT jsonb_agg(DISTINCT audio_quarantine_path)
      FROM moderation_queue
      WHERE content_author_id = p_user_id AND audio_quarantine_path IS NOT NULL
    ), '[]'::jsonb)
  );
$$;

REVOKE ALL ON FUNCTION get_account_deletion_media(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_account_deletion_media(UUID) TO service_role;

COMMENT ON FUNCTION get_account_deletion_media(UUID) IS
'delete-account: rutas de la media del usuario a borrar con la Storage API (buckets públicos y cuarentena). Solo service_role.';

-- =====================================================
-- delete_user_account(): registro de faltas + borrado (atómico)
-- =====================================================
-- Devuelve TRUE si se guardó el registro de faltas.
-- Sin huella (cuenta sin email) se borra igual, sin registro.
CREATE OR REPLACE FUNCTION delete_user_account(
  p_user_id UUID,
  p_email_hash TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_low INTEGER;
  v_medium INTEGER;
  v_high INTEGER;
  v_critical INTEGER;
  v_last TIMESTAMPTZ;
  v_recorded BOOLEAN := FALSE;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'p_user_id is required';
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE decision_severity = 'low'),
    COUNT(*) FILTER (WHERE decision_severity = 'medium'),
    COUNT(*) FILTER (WHERE decision_severity = 'high'),
    COUNT(*) FILTER (WHERE decision_severity = 'critical'),
    MAX(decided_at)
  INTO v_low, v_medium, v_high, v_critical, v_last
  FROM moderation_queue
  WHERE content_author_id = p_user_id AND status = 'rejected';

  IF v_low + v_medium + v_high + v_critical > 0 AND p_email_hash IS NOT NULL THEN
    INSERT INTO account_deletion_records AS r (
      email_hash, rejections_low, rejections_medium, rejections_high,
      rejections_critical, last_rejection_at
    )
    VALUES (p_email_hash, v_low, v_medium, v_high, v_critical, v_last)
    ON CONFLICT (email_hash) DO UPDATE SET
      rejections_low = r.rejections_low + EXCLUDED.rejections_low,
      rejections_medium = r.rejections_medium + EXCLUDED.rejections_medium,
      rejections_high = r.rejections_high + EXCLUDED.rejections_high,
      rejections_critical = r.rejections_critical + EXCLUDED.rejections_critical,
      last_rejection_at = GREATEST(r.last_rejection_at, EXCLUDED.last_rejection_at),
      deletion_count = r.deletion_count + 1,
      last_deleted_at = NOW();
    v_recorded := TRUE;
  END IF;

  -- Sin FK a auth.users (no cascada): se borran a mano
  DELETE FROM rate_limits WHERE user_id = p_user_id;

  -- Cascada: gossips, profiles, content_reports, moderation_queue (autor);
  -- SET NULL en error_logs, decided_by/reviewed_by/modified_by
  DELETE FROM auth.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user % not found', p_user_id;
  END IF;

  RETURN v_recorded;
END;
$$;

REVOKE ALL ON FUNCTION delete_user_account(UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION delete_user_account(UUID, TEXT) TO service_role;

COMMENT ON FUNCTION delete_user_account(UUID, TEXT) IS
'delete-account: guarda el registro anónimo de faltas (si las hay) y borra la cuenta en una transacción. Solo service_role.';
