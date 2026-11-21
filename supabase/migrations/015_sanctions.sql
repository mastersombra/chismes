-- =====================================================
-- 015: Sanciones, apelaciones y reincidentes
-- =====================================================
-- Faltas = rechazos humanos (moderation_queue.status = 'rejected') no anulados
-- por una apelación, más las heredadas de una cuenta eliminada con el mismo
-- email. Los rechazos automáticos de la IA NO cuentan (falsos positivos).
--
-- Puntos por gravedad (moderation_settings): leve 1 · media 2 · alta 4 ·
-- crítica = suspensión directa. Los puntos vencen a los strike_expiry_days.
--
-- Cada falta genera su sanción según los puntos vigentes en ESE momento
-- (incluida ella):
--   crítica o >= suspension_points   → suspensión INDEFINIDA (solo la levanta
--                                       una apelación aceptada)
--   >= restriction_long_points        → no publicar/reportar restriction_long_hours
--   >= restriction_short_points       → no publicar/reportar restriction_short_hours
--   menos                             → advertencia (sin bloqueo)
--
-- Las sanciones NO se guardan: se calculan del historial en cada consulta
-- (get_user_sanction_status). Así no se desincronizan y anular una falta
-- recalcula todo sola. Cambiar un umbral en moderation_settings también
-- aplica al historial (a propósito: un umbral corregido corrige a todos).
--
-- Una sanción bloquea publicar (moderate-gossip) y reportar (report-gossip).
-- El usuario sigue pudiendo leer, ver su estado, apelar y eliminar su cuenta.
--
-- Apelaciones: una por rechazo, dentro de appeal_window_days. Aceptada →
-- la falta se anula (overturned_at) y el texto del chisme se republica (su
-- media se borró al rechazarlo). Rechazada → la falta sigue.
--
-- Reincidentes: la base no tiene ACCOUNT_HASH_SECRET, así que la huella del
-- email la calcula el servidor (Edge Functions) y llama a
-- claim_inherited_strikes() la primera vez que el usuario publica, reporta o
-- abre su estado. Las faltas heredadas cuentan como UNA falta en la fecha de
-- la última. Si incluían una crítica → suspensión (no apelable: el contenido
-- se borró con la cuenta).
--
-- Acceso: solo service_role (moderate-gossip, report-gossip, account-status,
-- moderation-review, delete-account).
-- =====================================================

-- =====================================================
-- 1. CONFIGURACIÓN
-- =====================================================

INSERT INTO moderation_settings (key, value, description) VALUES
  ('strike_points_low', 1, 'Puntos de una falta de gravedad leve'),
  ('strike_points_medium', 2, 'Puntos de una falta de gravedad media'),
  ('strike_points_high', 4, 'Puntos de una falta de gravedad alta (la crítica suspende directo)'),
  ('strike_expiry_days', 90, 'Días hasta que los puntos de una falta vencen'),
  ('restriction_short_points', 3, 'Desde estos puntos vigentes: restricción corta para publicar y reportar'),
  ('restriction_short_hours', 24, 'Duración de la restricción corta (horas)'),
  ('restriction_long_points', 6, 'Desde estos puntos vigentes: restricción larga'),
  ('restriction_long_hours', 168, 'Duración de la restricción larga (horas). 168 = 7 días'),
  ('suspension_points', 10, 'Desde estos puntos vigentes: suspensión indefinida (solo la levanta una apelación)'),
  ('appeal_window_days', 14, 'Días para apelar un rechazo desde la decisión'),
  ('appeal_different_moderator', 0, '1 = la apelación la debe revisar un moderador distinto al que rechazó. 0 = cualquiera (equipo de una persona)')
ON CONFLICT (key) DO NOTHING;

-- Lectura con valor por defecto (si alguien borra una fila, no se rompe)
CREATE OR REPLACE FUNCTION moderation_setting(p_key TEXT, p_default NUMERIC)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE((SELECT value FROM public.moderation_settings WHERE key = p_key), p_default);
$$;

REVOKE ALL ON FUNCTION moderation_setting(TEXT, NUMERIC) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION moderation_setting(TEXT, NUMERIC) TO service_role;

-- =====================================================
-- 2. FALTAS ANULADAS (apelación aceptada)
-- =====================================================

ALTER TABLE moderation_queue
  ADD COLUMN overturned_at TIMESTAMPTZ,
  ADD COLUMN overturned_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD CONSTRAINT moderation_queue_overturn_only_rejected CHECK (
    overturned_at IS NULL OR status = 'rejected'
  );

CREATE INDEX idx_moderation_queue_author_rejected
  ON moderation_queue (content_author_id, decided_at)
  WHERE status = 'rejected' AND overturned_at IS NULL;

-- =====================================================
-- 3. FALTAS HEREDADAS (reincidentes)
-- =====================================================
-- Una fila por usuario = ya se revisó (aunque no herede nada): la huella se
-- busca una sola vez por cuenta.

CREATE TABLE inherited_strikes (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
  has_critical BOOLEAN NOT NULL DEFAULT FALSE,
  last_rejection_at TIMESTAMPTZ,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE inherited_strikes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE inherited_strikes FROM anon, authenticated;
GRANT ALL ON TABLE inherited_strikes TO service_role;

COMMENT ON TABLE inherited_strikes IS
'Faltas heredadas de una cuenta eliminada con el mismo email (account_deletion_records). Una fila = ya revisado. Solo backend.';

-- Idempotente: si ya se revisó, no hace nada. Devuelve TRUE si heredó faltas.
-- Sin huella (sin email o sin secret) no marca como revisado: se reintenta.
CREATE OR REPLACE FUNCTION claim_inherited_strikes(p_user_id UUID, p_email_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r public.account_deletion_records%ROWTYPE;
  v_points INTEGER;
BEGIN
  IF p_user_id IS NULL OR p_email_hash IS NULL THEN
    RETURN FALSE;
  END IF;
  IF EXISTS (SELECT 1 FROM public.inherited_strikes WHERE user_id = p_user_id) THEN
    RETURN FALSE;
  END IF;

  SELECT * INTO r FROM public.account_deletion_records WHERE email_hash = p_email_hash;

  IF NOT FOUND THEN
    INSERT INTO public.inherited_strikes (user_id) VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN FALSE;
  END IF;

  v_points :=
      r.rejections_low * public.moderation_setting('strike_points_low', 1)
    + r.rejections_medium * public.moderation_setting('strike_points_medium', 2)
    + r.rejections_high * public.moderation_setting('strike_points_high', 4);

  INSERT INTO public.inherited_strikes (user_id, points, has_critical, last_rejection_at)
  VALUES (p_user_id, v_points, r.rejections_critical > 0, r.last_rejection_at)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN v_points > 0 OR r.rejections_critical > 0;
END;
$$;

REVOKE ALL ON FUNCTION claim_inherited_strikes(UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION claim_inherited_strikes(UUID, TEXT) TO service_role;

-- =====================================================
-- 4. FALTAS Y SANCIÓN DE CADA UNA
-- =====================================================
-- Una fila por falta (propias no anuladas + heredadas), con los puntos
-- vigentes al momento de la falta y la sanción que generó.

CREATE OR REPLACE FUNCTION get_user_strikes(p_user_id UUID)
RETURNS TABLE (
  queue_id UUID,           -- NULL en la falta heredada
  severity TEXT,           -- 'inherited' en la heredada
  points INTEGER,
  occurred_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  points_at_time INTEGER,
  sanction TEXT,           -- warning | restriction | suspension
  sanction_ends_at TIMESTAMPTZ  -- NULL: advertencia o suspensión indefinida
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH s AS (
    SELECT
      public.moderation_setting('strike_points_low', 1) AS p_low,
      public.moderation_setting('strike_points_medium', 2) AS p_medium,
      public.moderation_setting('strike_points_high', 4) AS p_high,
      make_interval(days => public.moderation_setting('strike_expiry_days', 90)::INTEGER) AS expiry,
      public.moderation_setting('restriction_short_points', 3) AS short_points,
      make_interval(hours => public.moderation_setting('restriction_short_hours', 24)::INTEGER) AS short_len,
      public.moderation_setting('restriction_long_points', 6) AS long_points,
      make_interval(hours => public.moderation_setting('restriction_long_hours', 168)::INTEGER) AS long_len,
      public.moderation_setting('suspension_points', 10) AS susp_points
  ),
  events AS (
    SELECT
      q.id AS queue_id,
      q.decision_severity AS severity,
      (CASE q.decision_severity
        WHEN 'low' THEN s.p_low
        WHEN 'medium' THEN s.p_medium
        WHEN 'high' THEN s.p_high
        ELSE s.susp_points
      END)::INTEGER AS points,
      q.decision_severity = 'critical' AS critical,
      q.decided_at AS occurred_at
    FROM public.moderation_queue q, s
    WHERE q.content_author_id = p_user_id
      AND q.status = 'rejected'
      AND q.overturned_at IS NULL
    UNION ALL
    SELECT
      NULL, 'inherited', i.points, i.has_critical, i.last_rejection_at
    FROM public.inherited_strikes i
    WHERE i.user_id = p_user_id
      AND i.last_rejection_at IS NOT NULL
      AND (i.points > 0 OR i.has_critical)
  ),
  scored AS (
    SELECT
      e.*,
      (SELECT COALESCE(SUM(e2.points), 0)::INTEGER
         FROM events e2
        WHERE e2.occurred_at <= e.occurred_at
          AND e2.occurred_at > e.occurred_at - s.expiry) AS points_at_time
    FROM events e, s
  )
  SELECT
    sc.queue_id,
    sc.severity,
    sc.points,
    sc.occurred_at,
    sc.occurred_at + s.expiry,
    sc.points_at_time,
    CASE
      WHEN sc.critical OR sc.points_at_time >= s.susp_points THEN 'suspension'
      WHEN sc.points_at_time >= s.short_points THEN 'restriction'
      ELSE 'warning'
    END,
    CASE
      WHEN sc.critical OR sc.points_at_time >= s.susp_points THEN NULL
      WHEN sc.points_at_time >= s.long_points THEN sc.occurred_at + s.long_len
      WHEN sc.points_at_time >= s.short_points THEN sc.occurred_at + s.short_len
      ELSE NULL
    END
  FROM scored sc, s
  ORDER BY sc.occurred_at DESC;
$$;

REVOKE ALL ON FUNCTION get_user_strikes(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_user_strikes(UUID) TO service_role;

-- =====================================================
-- 5. ESTADO ACTUAL DEL USUARIO
-- =====================================================
-- { state: 'ok'|'restricted'|'suspended', restricted_until, active_points,
--   strike_count, thresholds: {...}, expiry_days }

CREATE OR REPLACE FUNCTION get_user_sanction_status(p_user_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH st AS (
    SELECT * FROM public.get_user_strikes(p_user_id)
  ),
  agg AS (
    SELECT
      bool_or(sanction = 'suspension') AS suspended,
      max(sanction_ends_at) FILTER (WHERE sanction = 'restriction' AND sanction_ends_at > NOW()) AS until,
      COALESCE(SUM(points) FILTER (WHERE expires_at > NOW()), 0)::INTEGER AS active_points,
      COUNT(*) FILTER (WHERE expires_at > NOW())::INTEGER AS strike_count
    FROM st
  )
  SELECT jsonb_build_object(
    'state', CASE
      WHEN COALESCE(a.suspended, FALSE) THEN 'suspended'
      WHEN a.until IS NOT NULL THEN 'restricted'
      ELSE 'ok'
    END,
    'restricted_until', CASE WHEN COALESCE(a.suspended, FALSE) THEN NULL ELSE a.until END,
    'active_points', a.active_points,
    'strike_count', a.strike_count,
    'expiry_days', public.moderation_setting('strike_expiry_days', 90)::INTEGER,
    'thresholds', jsonb_build_object(
      'restriction_short', public.moderation_setting('restriction_short_points', 3)::INTEGER,
      'restriction_long', public.moderation_setting('restriction_long_points', 6)::INTEGER,
      'suspension', public.moderation_setting('suspension_points', 10)::INTEGER
    )
  )
  FROM agg a;
$$;

REVOKE ALL ON FUNCTION get_user_sanction_status(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_user_sanction_status(UUID) TO service_role;

-- =====================================================
-- 6. APELACIONES
-- =====================================================

CREATE TABLE moderation_appeals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Una apelación por rechazo
  queue_id UUID NOT NULL UNIQUE REFERENCES moderation_queue(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL CHECK (char_length(btrim(message)) BETWEEN 10 AND 1000),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  decided_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  decided_at TIMESTAMPTZ,
  -- Nota interna del moderador (el usuario no la ve)
  decision_note TEXT CHECK (char_length(decision_note) <= 1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT moderation_appeals_decided_when_closed CHECK ((status = 'pending') = (decided_at IS NULL))
);

CREATE INDEX idx_moderation_appeals_pending ON moderation_appeals (created_at) WHERE status = 'pending';
CREATE INDEX idx_moderation_appeals_user ON moderation_appeals (user_id);

ALTER TABLE moderation_appeals ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE moderation_appeals FROM anon, authenticated;
GRANT ALL ON TABLE moderation_appeals TO service_role;

COMMENT ON TABLE moderation_appeals IS
'Apelaciones de rechazos (una por rechazo). Solo backend (account-status crea, moderation-review decide).';

-- ---------- Crear (account-status) ----------
-- Errores: appeal_target_not_found (P0002; no existe o no es del usuario),
-- appeal_window_closed (55000), appeal_already_exists (23505),
-- invalid_appeal_message (22023)
CREATE OR REPLACE FUNCTION submit_appeal(p_user_id UUID, p_queue_id UUID, p_message TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_item public.moderation_queue%ROWTYPE;
  v_message TEXT := btrim(COALESCE(p_message, ''));
  v_appeal public.moderation_appeals%ROWTYPE;
BEGIN
  IF char_length(v_message) NOT BETWEEN 10 AND 1000 THEN
    RAISE EXCEPTION 'invalid_appeal_message' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_item FROM public.moderation_queue
  WHERE id = p_queue_id AND content_author_id = p_user_id AND status = 'rejected'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'appeal_target_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.moderation_appeals WHERE queue_id = p_queue_id) THEN
    RAISE EXCEPTION 'appeal_already_exists' USING ERRCODE = '23505';
  END IF;

  IF v_item.overturned_at IS NOT NULL
     OR v_item.decided_at < NOW() - make_interval(days => public.moderation_setting('appeal_window_days', 14)::INTEGER) THEN
    RAISE EXCEPTION 'appeal_window_closed' USING ERRCODE = '55000';
  END IF;

  INSERT INTO public.moderation_appeals (queue_id, user_id, message)
  VALUES (p_queue_id, p_user_id, v_message)
  RETURNING * INTO v_appeal;

  RETURN to_jsonb(v_appeal);
END;
$$;

REVOKE ALL ON FUNCTION submit_appeal(UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION submit_appeal(UUID, UUID, TEXT) TO service_role;

-- ---------- Decidir (moderation-review) ----------
-- accept → anula la falta y republica el texto del chisme (si su autor no lo
--          eliminó). La media no vuelve: se borró al rechazar.
-- reject → la falta sigue.
-- Errores: invalid_decision (22023), appeal_not_found (P0002),
-- appeal_already_decided (55000), appeal_same_moderator (42501)
CREATE OR REPLACE FUNCTION decide_appeal(
  p_appeal_id UUID,
  p_decision TEXT,
  p_moderator_id UUID,
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_appeal public.moderation_appeals%ROWTYPE;
  v_item public.moderation_queue%ROWTYPE;
BEGIN
  IF p_decision NOT IN ('accept', 'reject') THEN
    RAISE EXCEPTION 'invalid_decision' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_appeal FROM public.moderation_appeals WHERE id = p_appeal_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'appeal_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF v_appeal.status <> 'pending' THEN
    RAISE EXCEPTION 'appeal_already_decided' USING ERRCODE = '55000';
  END IF;

  SELECT * INTO v_item FROM public.moderation_queue WHERE id = v_appeal.queue_id FOR UPDATE;

  IF public.moderation_setting('appeal_different_moderator', 0) = 1
     AND v_item.decided_by = p_moderator_id THEN
    RAISE EXCEPTION 'appeal_same_moderator' USING ERRCODE = '42501';
  END IF;

  IF p_decision = 'accept' THEN
    UPDATE public.moderation_queue
    SET overturned_at = NOW(), overturned_by = p_moderator_id, updated_at = NOW()
    WHERE id = v_item.id;

    UPDATE public.gossips
    SET status = 'published', moderation_status = 'approved'
    WHERE id = v_item.gossip_id
      AND deleted_at IS NULL
      AND status <> 'deleted';
  END IF;

  UPDATE public.moderation_appeals SET
    status = CASE p_decision WHEN 'accept' THEN 'accepted' ELSE 'rejected' END,
    decided_by = p_moderator_id,
    decided_at = NOW(),
    decision_note = NULLIF(btrim(COALESCE(p_note, '')), '')
  WHERE id = p_appeal_id
  RETURNING * INTO v_appeal;

  RETURN to_jsonb(v_appeal);
END;
$$;

REVOKE ALL ON FUNCTION decide_appeal(UUID, TEXT, UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION decide_appeal(UUID, TEXT, UUID, TEXT) TO service_role;

-- ---------- Vista para el panel (moderation-review) ----------
CREATE VIEW moderation_appeal_items AS
SELECT
  a.id,
  a.queue_id,
  a.user_id,
  a.message,
  a.status,
  a.decided_by,
  a.decided_at,
  a.decision_note,
  a.created_at,
  p.username AS author_username,
  p.display_name AS author_display_name,
  g.id AS gossip_id,
  g.subject,
  g.content,
  g.published_as,
  g.status AS gossip_status,
  q.source AS original_source,
  q.reasons AS original_reasons,
  q.report_count AS original_report_count,
  q.decided_by AS original_decided_by,
  q.decided_at AS original_decided_at,
  q.decision_severity AS original_severity,
  q.decision_reason AS original_reason,
  q.decision_note AS original_note
FROM moderation_appeals a
JOIN moderation_queue q ON q.id = a.queue_id
JOIN gossips g ON g.id = q.gossip_id
LEFT JOIN profiles p ON p.id = a.user_id;

REVOKE ALL ON TABLE moderation_appeal_items FROM anon, authenticated;
GRANT SELECT ON TABLE moderation_appeal_items TO service_role;

-- =====================================================
-- 7. ESTADO DE LA CUENTA (account-status)
-- =====================================================
-- Lo que ve el usuario: su estado + sus rechazos (con su apelación). Sin
-- notas internas ni quién decidió.

CREATE OR REPLACE FUNCTION get_account_status(p_user_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.get_user_sanction_status(p_user_id) || jsonb_build_object(
    'appeal_window_days', public.moderation_setting('appeal_window_days', 14)::INTEGER,
    'inherited', (
      SELECT jsonb_build_object(
        'points', st.points,
        'occurred_at', st.occurred_at,
        'expires_at', st.expires_at,
        'sanction', st.sanction
      )
      FROM public.get_user_strikes(p_user_id) st
      WHERE st.severity = 'inherited'
    ),
    'rejections', COALESCE((
      SELECT jsonb_agg(r ORDER BY (r->>'decided_at') DESC)
      FROM (
        SELECT jsonb_build_object(
          'queue_id', q.id,
          'gossip_id', q.gossip_id,
          'subject', g.subject,
          'content', g.content,
          'severity', q.decision_severity,
          'reason', q.decision_reason,
          'decided_at', q.decided_at,
          'overturned', q.overturned_at IS NOT NULL,
          'points', st.points,
          'expires_at', COALESCE(st.expires_at,
            q.decided_at + make_interval(days => public.moderation_setting('strike_expiry_days', 90)::INTEGER)),
          'sanction', st.sanction,
          'sanction_ends_at', st.sanction_ends_at,
          'appeal_deadline', q.decided_at + make_interval(days => public.moderation_setting('appeal_window_days', 14)::INTEGER),
          'can_appeal', a.id IS NULL
            AND q.overturned_at IS NULL
            AND q.decided_at >= NOW() - make_interval(days => public.moderation_setting('appeal_window_days', 14)::INTEGER),
          'appeal', CASE WHEN a.id IS NULL THEN NULL ELSE jsonb_build_object(
            'id', a.id,
            'status', a.status,
            'message', a.message,
            'created_at', a.created_at,
            'decided_at', a.decided_at
          ) END
        ) AS r
        FROM public.moderation_queue q
        JOIN public.gossips g ON g.id = q.gossip_id
        LEFT JOIN public.moderation_appeals a ON a.queue_id = q.id
        LEFT JOIN public.get_user_strikes(p_user_id) st ON st.queue_id = q.id
        WHERE q.content_author_id = p_user_id
          AND q.status = 'rejected'
        ORDER BY q.decided_at DESC
        LIMIT 50
      ) x
    ), '[]'::jsonb)
  );
$$;

REVOKE ALL ON FUNCTION get_account_status(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_account_status(UUID) TO service_role;

-- =====================================================
-- 8. ELIMINACIÓN DE CUENTA: no contar faltas anuladas
-- =====================================================
-- Igual que en 014, pero excluye los rechazos anulados por apelación.

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
  WHERE content_author_id = p_user_id
    AND status = 'rejected'
    AND overturned_at IS NULL;

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

  DELETE FROM rate_limits WHERE user_id = p_user_id;

  -- Cascada: además de lo de 014, moderation_appeals e inherited_strikes
  DELETE FROM auth.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user % not found', p_user_id;
  END IF;

  RETURN v_recorded;
END;
$$;

REVOKE ALL ON FUNCTION delete_user_account(UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION delete_user_account(UUID, TEXT) TO service_role;
