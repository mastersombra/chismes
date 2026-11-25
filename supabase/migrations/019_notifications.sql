-- =====================================================
-- 019: Notificaciones dentro de la app
-- =====================================================
-- 1. QUÉ AVISA (las crean triggers en el servidor; nunca el cliente):
--    Sociales (respetan user_settings.notifications_enabled Y
--    follow_notifications):
--      new_follower     alguien empezó a seguirme
--      follow_request   alguien pidió seguirme (cuenta privada). Se borra
--                       cuando la solicitud se acepta, rechaza o cancela
--      follow_accepted  aceptaron mi solicitud (también al pasar a pública)
--    De la cuenta (llegan SIEMPRE, aunque apague las notificaciones):
--      gossip_approved  un moderador aprobó mi chisme que esperaba revisión
--                       (IA en duda / IA caída) o que ocultaron los reportes.
--                       Si los reportes no lo ocultaron, no se avisa (el
--                       autor ni se enteró)
--      gossip_rejected  un moderador rechazó mi chisme (lleva el motivo)
--      appeal_accepted / appeal_rejected  resolvieron mi apelación
--    El rechazo automático de la IA no notifica: ya se muestra al publicar.
--
-- 2. ANTI-SPAM: una sola notificación social por (destinatario, tipo,
--    autor). Seguir/dejar de seguir en bucle no repite el aviso; pasado un
--    día, vuelve a subir como no leída.
--
-- 3. BLOQUEOS: las notificaciones entre usuarios bloqueados se borran al
--    bloquear y nunca se listan ni cuentan.
--
-- 4. ACCESO: los clientes no tocan la tabla. Leen con get_notifications /
--    get_unread_notifications_count y marcan con mark_notifications_read
--    (todas con auth.uid()).
--
-- 5. RETENCIÓN: pg_cron borra las de más de 90 días (diario, 3:45 AM UTC).
--
-- Eliminación de cuenta: se borran en cascada (como destinatario y autor).
-- =====================================================

-- =====================================================
-- 1. TABLA
-- =====================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'new_follower', 'follow_request', 'follow_accepted',
    'gossip_approved', 'gossip_rejected',
    'appeal_accepted', 'appeal_rejected'
  )),
  -- Quién la provocó (solo en las sociales)
  actor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Chisme propio afectado (solo en las de moderación)
  gossip_id UUID REFERENCES gossips(id) ON DELETE CASCADE,
  -- Código del motivo predefinido del rechazo (nunca la nota interna)
  reason TEXT CHECK (char_length(reason) <= 100),
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT notifications_actor_on_social CHECK (
    (type IN ('new_follower', 'follow_request', 'follow_accepted')) = (actor_id IS NOT NULL)
  ),
  CONSTRAINT notifications_gossip_on_moderation CHECK (
    (type IN ('new_follower', 'follow_request', 'follow_accepted')) = (gossip_id IS NULL)
  )
);

COMMENT ON TABLE notifications IS
  'Notificaciones in-app. Las crean triggers; el dueño las lee y marca vía RPC (sin acceso directo)';

-- Anti-spam de las sociales (ver cabecera)
CREATE UNIQUE INDEX uq_notifications_social
  ON notifications (user_id, type, actor_id)
  WHERE actor_id IS NOT NULL;

CREATE INDEX idx_notifications_user_created ON notifications (user_id, created_at DESC, id DESC);
CREATE INDEX idx_notifications_unread ON notifications (user_id) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_actor ON notifications (actor_id) WHERE actor_id IS NOT NULL;
CREATE INDEX idx_notifications_created ON notifications (created_at);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE notifications FROM anon, authenticated;
GRANT ALL ON TABLE notifications TO service_role;

-- =====================================================
-- 2. HELPERS INTERNOS
-- =====================================================

-- ¿Quiere avisos sociales? (sin fila de settings → sí, como los defaults)
CREATE OR REPLACE FUNCTION public.wants_social_notifications(p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT s.notifications_enabled AND s.follow_notifications
     FROM user_settings s WHERE s.user_id = p_user),
    TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.notify_social(p_user UUID, p_type TEXT, p_actor UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user IS NULL OR p_actor IS NULL OR p_user = p_actor
     OR NOT public.wants_social_notifications(p_user)
     OR public.users_blocked(p_user, p_actor) THEN
    RETURN;
  END IF;

  INSERT INTO notifications (user_id, type, actor_id)
  VALUES (p_user, p_type, p_actor)
  ON CONFLICT (user_id, type, actor_id) WHERE actor_id IS NOT NULL
  DO UPDATE SET created_at = NOW(), read_at = NULL
  WHERE notifications.created_at < NOW() - INTERVAL '1 day';
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_account(
  p_user UUID, p_type TEXT, p_gossip UUID, p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user IS NULL OR p_gossip IS NULL THEN
    RETURN;
  END IF;
  INSERT INTO notifications (user_id, type, gossip_id, reason)
  VALUES (p_user, p_type, p_gossip, p_reason);
END;
$$;

-- =====================================================
-- 3. TRIGGERS
-- =====================================================

-- Seguimiento nuevo. Si lo creó el seguido (aceptó la solicitud o pasó su
-- cuenta a pública), avisa al que pidió; si no, avisa al seguido.
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT DISTINCT FROM NEW.following_id THEN
    PERFORM public.notify_social(NEW.follower_id, 'follow_accepted', NEW.following_id);
  ELSE
    PERFORM public.notify_social(NEW.following_id, 'new_follower', NEW.follower_id);
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER on_user_follow_notify
  AFTER INSERT ON user_follows
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_follow();

CREATE OR REPLACE FUNCTION public.notify_on_follow_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.notify_social(NEW.target_id, 'follow_request', NEW.requester_id);
  ELSE
    -- Aceptada, rechazada o cancelada: el aviso ya no sirve
    DELETE FROM notifications
    WHERE user_id = OLD.target_id AND type = 'follow_request' AND actor_id = OLD.requester_id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER on_follow_request_notify
  AFTER INSERT OR DELETE ON follow_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_follow_request();

CREATE OR REPLACE FUNCTION public.clear_notifications_on_block()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM notifications
  WHERE (user_id = NEW.blocker_id AND actor_id = NEW.blocked_id)
     OR (user_id = NEW.blocked_id AND actor_id = NEW.blocker_id);
  RETURN NULL;
END;
$$;

CREATE TRIGGER on_user_block_clear_notifications
  AFTER INSERT ON user_blocks
  FOR EACH ROW
  EXECUTE FUNCTION public.clear_notifications_on_block();

-- Decisión humana en la cola (apply_moderation_decision)
CREATE OR REPLACE FUNCTION public.notify_on_moderation_decision()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'pending' AND NEW.status IN ('approved', 'rejected') THEN
    IF NEW.status = 'rejected' THEN
      PERFORM public.notify_account(NEW.content_author_id, 'gossip_rejected', NEW.gossip_id, NEW.decision_reason);
    ELSIF NEW.source <> 'reports' OR NEW.auto_hidden THEN
      PERFORM public.notify_account(NEW.content_author_id, 'gossip_approved', NEW.gossip_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER on_moderation_decision_notify
  AFTER UPDATE OF status ON moderation_queue
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_moderation_decision();

-- Apelación resuelta (decide_appeal)
CREATE OR REPLACE FUNCTION public.notify_on_appeal_decision()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'pending' AND NEW.status IN ('accepted', 'rejected') THEN
    PERFORM public.notify_account(
      NEW.user_id,
      CASE NEW.status WHEN 'accepted' THEN 'appeal_accepted' ELSE 'appeal_rejected' END,
      (SELECT q.gossip_id FROM moderation_queue q WHERE q.id = NEW.queue_id)
    );
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER on_appeal_decision_notify
  AFTER UPDATE OF status ON moderation_appeals
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_appeal_decision();

-- =====================================================
-- 4. API (auth.uid())
-- =====================================================

-- Página de notificaciones (más recientes primero, keyset)
CREATE OR REPLACE FUNCTION public.get_notifications(
  page_size INT DEFAULT 30,
  cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  cursor_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_size INT := LEAST(GREATEST(COALESCE(page_size, 30), 1), 100);
  v_rows JSON;
  v_has_more BOOLEAN;
  v_last_created_at TIMESTAMPTZ;
  v_last_id UUID;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;

  WITH page AS (
    SELECT n.*
    FROM notifications n
    LEFT JOIN gossips g ON g.id = n.gossip_id
    WHERE n.user_id = v_me
      AND (n.actor_id IS NULL OR NOT public.users_blocked(v_me, n.actor_id))
      AND (n.gossip_id IS NULL OR (g.deleted_at IS NULL AND g.status <> 'deleted'))
      AND (cursor_created_at IS NULL
           OR n.created_at < cursor_created_at
           OR (n.created_at = cursor_created_at AND n.id < cursor_id))
    ORDER BY n.created_at DESC, n.id DESC
    LIMIT v_size + 1
  ),
  numbered AS (
    SELECT page.*, ROW_NUMBER() OVER (ORDER BY created_at DESC, id DESC) AS rn
    FROM page
  )
  SELECT
    COALESCE(json_agg(json_build_object(
      'id', n.id,
      'type', n.type,
      'created_at', n.created_at,
      'is_read', n.read_at IS NOT NULL,
      'actor', CASE WHEN n.actor_id IS NOT NULL THEN public.social_user_json(n.actor_id, v_me) END,
      'gossip', CASE WHEN n.gossip_id IS NOT NULL THEN
        (SELECT json_build_object('id', g.id, 'subject', g.subject) FROM gossips g WHERE g.id = n.gossip_id)
      END,
      'reason', n.reason
    ) ORDER BY n.rn) FILTER (WHERE n.rn <= v_size), '[]'::json),
    COUNT(*) > v_size,
    MAX(n.created_at) FILTER (WHERE n.rn = v_size),
    (array_agg(n.id) FILTER (WHERE n.rn = v_size))[1]
  INTO v_rows, v_has_more, v_last_created_at, v_last_id
  FROM numbered n;

  RETURN json_build_object(
    'data', v_rows,
    'has_more', v_has_more,
    'next_cursor', CASE WHEN v_has_more THEN
      json_build_object('created_at', v_last_created_at, 'id', v_last_id)
    ELSE NULL END
  );
END;
$$;

-- Contador del badge (máx. 100: la app muestra "99+")
CREATE OR REPLACE FUNCTION public.get_unread_notifications_count()
RETURNS INT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  RETURN (
    SELECT COUNT(*)::INT FROM (
      SELECT 1
      FROM notifications n
      LEFT JOIN gossips g ON g.id = n.gossip_id
      WHERE n.user_id = v_me
        AND n.read_at IS NULL
        AND (n.actor_id IS NULL OR NOT public.users_blocked(v_me, n.actor_id))
        AND (n.gossip_id IS NULL OR (g.deleted_at IS NULL AND g.status <> 'deleted'))
      LIMIT 100
    ) x
  );
END;
$$;

-- Marcar como leídas: las indicadas o, sin ids, todas. Devuelve cuántas.
CREATE OR REPLACE FUNCTION public.mark_notifications_read(p_ids UUID[] DEFAULT NULL)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_count INT;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = 'CS401';
  END IF;
  UPDATE notifications
  SET read_at = NOW()
  WHERE user_id = v_me
    AND read_at IS NULL
    AND (p_ids IS NULL OR id = ANY (p_ids));
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- =====================================================
-- 5. RETENCIÓN (pg_cron)
-- =====================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '90 days';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

SELECT cron.unschedule('notifications-cleanup')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'notifications-cleanup');

SELECT cron.schedule(
  'notifications-cleanup',
  '45 3 * * *',
  'SELECT public.cleanup_old_notifications()'
);

-- =====================================================
-- 6. PERMISOS
-- =====================================================

DO $$
DECLARE
  fn TEXT;
BEGIN
  -- Internas: ni clientes ni API
  FOREACH fn IN ARRAY ARRAY[
    'public.wants_social_notifications(UUID)',
    'public.notify_social(UUID, TEXT, UUID)',
    'public.notify_account(UUID, TEXT, UUID, TEXT)',
    'public.notify_on_follow()',
    'public.notify_on_follow_request()',
    'public.clear_notifications_on_block()',
    'public.notify_on_moderation_decision()',
    'public.notify_on_appeal_decision()'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', fn);
  END LOOP;

  EXECUTE 'REVOKE ALL ON FUNCTION public.cleanup_old_notifications() FROM PUBLIC, anon, authenticated';
  EXECUTE 'GRANT EXECUTE ON FUNCTION public.cleanup_old_notifications() TO service_role';

  -- API para usuarios con sesión
  FOREACH fn IN ARRAY ARRAY[
    'public.get_notifications(INT, TIMESTAMPTZ, UUID)',
    'public.get_unread_notifications_count()',
    'public.mark_notifications_read(UUID[])'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role', fn);
  END LOOP;
END;
$$;
