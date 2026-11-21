-- =====================================================
-- 013: Moderación — reportes, cola de revisión humana y configuración
-- =====================================================
-- Principio: toda decisión de moderación en el servidor.
--
-- Genérico por tipo de contenido: cada reporte / entrada de la cola apunta a
-- UN contenido con una columna de referencia por tipo y la regla "exactamente
-- una" (num_nonnulls = 1). Hoy: gossip_id. Al agregar comentarios: agregar
-- comment_id (FK a comments ON DELETE CASCADE), ampliar los CHECK, los índices
-- únicos parciales y el trigger. Lo demás (umbral, cola, decisiones) se reusa.
--
-- Piezas:
--   1. moderation_settings: umbrales editables sin despliegue (dashboard)
--  1b. moderation_rules: reglas de contenido de moderate-gossip (términos,
--      umbrales de IA, reglas fijas on/off), editables sin despliegue
--   2. content_reports: reportes de usuarios (solo backend escribe/lee)
--   3. moderation_queue: cola de revisión humana + historial de decisiones
--      (guarda autor, gravedad y motivo: base para sanciones futuras)
--   4. Trigger de reportes: umbral relativo + protección de lo popular +
--      cuentas nuevas no cuentan → cola (y auto-ocultar si corresponde)
--   5. enqueue_moderation(): moderate-gossip encola los veredictos 'review'
--   6. apply_moderation_decision(): moderation-review aplica aprobar/rechazar
--   7. moderation_queue_items: vista para listar la cola (backend)
--   8. get_media_cleanup_candidates(): no borra la media de lo pendiente
--
-- Acceso: anon/authenticated NO tienen ningún privilegio aquí. Los usuarios
-- reportan vía report-gossip; los moderadores (app_metadata.role =
-- 'moderator') deciden vía moderation-review. Ambas usan service_role.
-- =====================================================

-- =====================================================
-- 1. CONFIGURACIÓN (editable sin despliegue)
-- =====================================================

CREATE TABLE moderation_settings (
  key TEXT PRIMARY KEY,
  value NUMERIC NOT NULL,
  description TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE moderation_settings ENABLE ROW LEVEL SECURITY;
-- Sin políticas: solo service_role/postgres (dashboard). Las funciones de
-- abajo son SECURITY DEFINER y la leen como su dueño.
REVOKE ALL ON TABLE moderation_settings FROM anon, authenticated;
GRANT ALL ON TABLE moderation_settings TO service_role;

INSERT INTO moderation_settings (key, value, description) VALUES
  ('report_min_count', 3,
   'Reportes mínimos (de usuarios distintos y con cuenta no nueva) para mandar un contenido a la cola'),
  ('report_ratio', 0.02,
   'Además del mínimo, para auto-ocultar los reportes deben ser >= este % de las interacciones (likes+comentarios+compartidos). 0.02 = 2%'),
  ('report_popular_interactions', 500,
   'Desde estas interacciones el contenido es "popular": los reportes nunca lo ocultan solos, va a la cola con prioridad alta'),
  ('report_min_account_age_hours', 24,
   'Los reportes de cuentas con menos de estas horas no cuentan para el umbral (anti cuentas creadas para hundir)');

COMMENT ON TABLE moderation_settings IS
'Umbrales de moderación. Editar desde el dashboard (Table Editor); aplica al siguiente reporte, sin desplegar.';

-- =====================================================
-- 1b. REGLAS DE MODERACIÓN DE CONTENIDO (moderate-gossip)
-- =====================================================
-- moderate-gossip las lee en cada publicación: un cambio aplica al siguiente
-- chisme, sin desplegar ni sacar versión de la app. Si no puede leerlas, el
-- chisme va a revisión (fail-closed), nunca se publica solo.
--
-- Cada fila: "si <target> coincide → <action>". Si varias coinciden, gana
-- reject. Tipos:
--   term        palabra o frase. Se compara normalizada (minúsculas, sin
--               tildes, leet 0→o 1→i 3→e 4→a 5→s) y como palabra completa.
--   ai_category categoría de OpenAI con puntaje >= min_score. Solo endurece:
--               lo que OpenAI marca (flagged) se rechaza siempre.
--   builtin     regla fija del código; aquí se elige su acción o se apaga
--               (enabled = false): credible_threat, personal_data, spam.
-- Las regex viven en el código a propósito: una regex editable mal escrita
-- puede colgar la función o dejar de moderar.

CREATE TABLE moderation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind TEXT NOT NULL CHECK (kind IN ('term', 'ai_category', 'builtin')),
  target TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('review', 'reject')),
  min_score NUMERIC,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Un typo no puede dejar una regla que nunca coincide sin que nadie lo note
  CONSTRAINT moderation_rules_valid_target CHECK (
    (kind = 'term' AND char_length(btrim(target)) BETWEEN 2 AND 100)
    OR (kind = 'builtin' AND target IN ('credible_threat', 'personal_data', 'spam'))
    OR (kind = 'ai_category' AND target IN (
      'harassment', 'harassment/threatening', 'hate', 'hate/threatening',
      'illicit', 'illicit/violent', 'self-harm', 'self-harm/intent',
      'self-harm/instructions', 'sexual', 'sexual/minors', 'violence',
      'violence/graphic'
    ))
  ),
  -- min_score solo (y siempre) en ai_category, entre 0 y 1
  CONSTRAINT moderation_rules_valid_score CHECK (
    (kind = 'ai_category' AND min_score IS NOT NULL AND min_score > 0 AND min_score <= 1)
    OR (kind <> 'ai_category' AND min_score IS NULL)
  )
);

-- Sin duplicados: un término/categoría por acción; un builtin una sola vez
CREATE UNIQUE INDEX moderation_rules_unique_rule
  ON moderation_rules (kind, lower(btrim(target)), action)
  WHERE kind <> 'builtin';
CREATE UNIQUE INDEX moderation_rules_unique_builtin
  ON moderation_rules (target)
  WHERE kind = 'builtin';

CREATE OR REPLACE FUNCTION touch_moderation_rules_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER moderation_rules_touch_updated_at
  BEFORE UPDATE ON moderation_rules
  FOR EACH ROW EXECUTE FUNCTION touch_moderation_rules_updated_at();

REVOKE EXECUTE ON FUNCTION touch_moderation_rules_updated_at() FROM PUBLIC, anon, authenticated;

ALTER TABLE moderation_rules ENABLE ROW LEVEL SECURITY;
-- Sin políticas: solo service_role (moderate-gossip) y el dashboard. Los
-- clientes no pueden leerlas: conocer la lista ayuda a esquivarla.
REVOKE ALL ON TABLE moderation_rules FROM anon, authenticated;
GRANT ALL ON TABLE moderation_rules TO service_role;

-- Reglas iniciales: el mismo comportamiento que tenía el código
INSERT INTO moderation_rules (kind, target, action, note) VALUES
  ('builtin', 'credible_threat', 'reject', 'Amenaza explícita ("te voy a matar"): rechazo sin llamar a la IA'),
  ('builtin', 'personal_data', 'review', 'Email o celular colombiano en el texto'),
  ('builtin', 'spam', 'review', 'Links o letras repetidas (aaaaaaa)'),
  ('term', 'gonorrea', 'review', 'Grosería'),
  ('term', 'hijueputa', 'review', 'Grosería'),
  ('term', 'malparido', 'review', 'Grosería'),
  ('term', 'marica', 'review', 'Grosería (también uso coloquial)'),
  ('term', 'perra', 'review', 'Grosería'),
  ('term', 'puta', 'review', 'Grosería');

COMMENT ON TABLE moderation_rules IS
'Reglas de moderate-gossip (términos, umbrales de IA, reglas fijas on/off). Editar desde el dashboard; aplica al siguiente chisme. Ejemplo de umbral: (ai_category, harassment, review, min_score 0.3).';

-- =====================================================
-- 2. REPORTES DE CONTENIDO
-- =====================================================

CREATE TABLE content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Contenido reportado: exactamente una referencia (ver cabecera)
  gossip_id UUID REFERENCES gossips(id) ON DELETE CASCADE,

  reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (
    reason IN ('spam', 'harassment', 'violence', 'sexual_content', 'misinformation', 'other')
  ),
  details TEXT CHECK (char_length(details) <= 500),

  -- pending: cuenta para el umbral · dismissed: moderador lo descartó
  -- (contenido aprobado) · actioned: moderador actuó (contenido rechazado)
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'dismissed', 'actioned')
  ),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  CONSTRAINT content_reports_exactly_one_target CHECK (num_nonnulls(gossip_id) = 1)
);

-- Un usuario reporta cada contenido una sola vez
CREATE UNIQUE INDEX content_reports_unique_gossip_reporter
  ON content_reports (gossip_id, reported_by) WHERE gossip_id IS NOT NULL;

CREATE INDEX idx_content_reports_gossip_pending
  ON content_reports (gossip_id) WHERE status = 'pending';

CREATE INDEX idx_content_reports_reported_by ON content_reports (reported_by);

ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE content_reports FROM anon, authenticated;
GRANT ALL ON TABLE content_reports TO service_role;

COMMENT ON TABLE content_reports IS
'Reportes de usuarios. Una fila = un contenido (exactamente una columna de referencia). Solo backend (report-gossip).';

-- =====================================================
-- 3. COLA DE REVISIÓN HUMANA
-- =====================================================

CREATE TABLE moderation_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Contenido en revisión: exactamente una referencia (ver cabecera)
  gossip_id UUID REFERENCES gossips(id) ON DELETE CASCADE,

  -- Autor del contenido (para sanciones futuras)
  content_author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- ai_review: la IA/reglas dijeron "revisar" · ai_unavailable: sin veredicto
  -- de la IA o sin reglas (fail-closed) · reports: llegó al umbral de reportes
  source TEXT NOT NULL CHECK (source IN ('ai_review', 'ai_unavailable', 'reports')),
  reasons TEXT[] NOT NULL DEFAULT '{}',
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal', 'high')),
  report_count INTEGER NOT NULL DEFAULT 0,
  -- TRUE si los reportes lo ocultaron automáticamente (aprobar lo restaura)
  auto_hidden BOOLEAN NOT NULL DEFAULT FALSE,

  -- Media que espera aprobación (cleanup-media no la borra mientras esté pendiente)
  image_quarantine_path TEXT,
  audio_quarantine_path TEXT,

  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  decided_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  decided_at TIMESTAMPTZ,
  decision_severity TEXT CHECK (decision_severity IN ('low', 'medium', 'high', 'critical')),
  decision_reason TEXT CHECK (char_length(decision_reason) <= 100),
  decision_note TEXT CHECK (char_length(decision_note) <= 1000),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT moderation_queue_exactly_one_target CHECK (num_nonnulls(gossip_id) = 1),
  CONSTRAINT moderation_queue_decided_when_closed CHECK ((status = 'pending') = (decided_at IS NULL)),
  -- Rechazar exige gravedad (base de las sanciones); aprobar no lleva
  CONSTRAINT moderation_queue_severity_on_reject CHECK (
    (status = 'rejected') = (decision_severity IS NOT NULL)
  )
);

-- Un contenido tiene a lo sumo una entrada pendiente
CREATE UNIQUE INDEX moderation_queue_one_pending_gossip
  ON moderation_queue (gossip_id) WHERE status = 'pending' AND gossip_id IS NOT NULL;

CREATE INDEX idx_moderation_queue_pending
  ON moderation_queue (priority, created_at) WHERE status = 'pending';

CREATE INDEX idx_moderation_queue_author ON moderation_queue (content_author_id);

ALTER TABLE moderation_queue ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE moderation_queue FROM anon, authenticated;
GRANT ALL ON TABLE moderation_queue TO service_role;

COMMENT ON TABLE moderation_queue IS
'Cola de revisión humana e historial de decisiones (autor, gravedad, motivo). Solo backend (moderate-gossip, report-gossip, moderation-review).';

-- =====================================================
-- 4. TRIGGER DE REPORTES (umbral)
-- =====================================================
-- Cuentan los reportes 'pending' de cuentas con antigüedad suficiente.
--   eligible >= report_min_count                → entra a la cola
--   y además NO popular y eligible >= umbral    → se oculta (status 'hidden')
--   umbral = max(report_min_count, ceil(interacciones * report_ratio))
--   popular (interacciones >= report_popular_interactions) → prioridad alta,
--   nunca se oculta solo.
-- report_count del chisme = total de reportes recibidos (informativo).
-- Cuando un moderador decide, los reportes dejan de estar 'pending': el
-- conteo vuelve a empezar para reportes nuevos.

CREATE OR REPLACE FUNCTION handle_content_report()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  s_min NUMERIC;
  s_ratio NUMERIC;
  s_popular NUMERIC;
  s_age_hours NUMERIC;
  v_gossip public.gossips%ROWTYPE;
  v_total INT;
  v_eligible INT;
  v_reasons TEXT[];
  v_interactions INT;
  v_popular BOOLEAN;
  v_hide BOOLEAN;
BEGIN
  IF NEW.gossip_id IS NULL THEN
    RETURN NEW;  -- Otros tipos de contenido (futuro)
  END IF;

  SELECT
    COALESCE(MAX(value) FILTER (WHERE key = 'report_min_count'), 3),
    COALESCE(MAX(value) FILTER (WHERE key = 'report_ratio'), 0.02),
    COALESCE(MAX(value) FILTER (WHERE key = 'report_popular_interactions'), 500),
    COALESCE(MAX(value) FILTER (WHERE key = 'report_min_account_age_hours'), 24)
  INTO s_min, s_ratio, s_popular, s_age_hours
  FROM public.moderation_settings;

  -- Bloquear la fila: reportes simultáneos del mismo chisme se serializan
  SELECT * INTO v_gossip FROM public.gossips WHERE id = NEW.gossip_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*) INTO v_total
  FROM public.content_reports r
  WHERE r.gossip_id = NEW.gossip_id;

  SELECT
    COUNT(*),
    COALESCE(array_agg(DISTINCT r.reason ORDER BY r.reason), '{}')
  INTO v_eligible, v_reasons
  FROM public.content_reports r
  JOIN auth.users u ON u.id = r.reported_by
  WHERE r.gossip_id = NEW.gossip_id
    AND r.status = 'pending'
    AND u.created_at <= NOW() - make_interval(hours => s_age_hours::INT);

  UPDATE public.gossips SET report_count = v_total WHERE id = NEW.gossip_id;

  IF v_eligible < s_min THEN
    RETURN NEW;
  END IF;

  v_interactions := COALESCE(v_gossip.like_count, 0)
                  + COALESCE(v_gossip.comment_count, 0)
                  + COALESCE(v_gossip.share_count, 0);
  v_popular := v_interactions >= s_popular;
  v_hide := NOT v_popular
            AND v_gossip.status = 'published'
            AND v_eligible >= GREATEST(s_min, CEIL(v_interactions * s_ratio));

  INSERT INTO public.moderation_queue (
    gossip_id, content_author_id, source, reasons, priority, report_count, auto_hidden
  ) VALUES (
    NEW.gossip_id, v_gossip.created_by, 'reports', v_reasons,
    CASE WHEN v_popular THEN 'high' ELSE 'normal' END, v_eligible, v_hide
  )
  ON CONFLICT (gossip_id) WHERE status = 'pending' AND gossip_id IS NOT NULL
  DO UPDATE SET
    reasons = EXCLUDED.reasons,
    report_count = EXCLUDED.report_count,
    priority = EXCLUDED.priority,
    auto_hidden = public.moderation_queue.auto_hidden OR EXCLUDED.auto_hidden,
    updated_at = NOW();

  IF v_hide THEN
    UPDATE public.gossips
    SET status = 'hidden', moderation_status = 'flagged'
    WHERE id = NEW.gossip_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER content_reports_after_insert
  AFTER INSERT ON content_reports
  FOR EACH ROW
  EXECUTE FUNCTION handle_content_report();

REVOKE ALL ON FUNCTION handle_content_report() FROM PUBLIC, anon, authenticated;

-- =====================================================
-- 5. ENCOLAR VEREDICTOS 'review' (moderate-gossip)
-- =====================================================

CREATE OR REPLACE FUNCTION enqueue_moderation(
  p_gossip_id UUID,
  p_source TEXT,
  p_reasons TEXT[],
  p_image_quarantine_path TEXT DEFAULT NULL,
  p_audio_quarantine_path TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_author UUID;
  v_id UUID;
BEGIN
  SELECT created_by INTO v_author FROM public.gossips WHERE id = p_gossip_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'gossip_not_found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.moderation_queue (
    gossip_id, content_author_id, source, reasons,
    image_quarantine_path, audio_quarantine_path
  ) VALUES (
    p_gossip_id, v_author, p_source, COALESCE(p_reasons, '{}'),
    p_image_quarantine_path, p_audio_quarantine_path
  )
  -- Reintento idempotente de moderate-gossip: ya está en la cola
  ON CONFLICT (gossip_id) WHERE status = 'pending' AND gossip_id IS NOT NULL
  DO NOTHING
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION enqueue_moderation(UUID, TEXT, TEXT[], TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION enqueue_moderation(UUID, TEXT, TEXT[], TEXT, TEXT) TO service_role;

-- =====================================================
-- 6. APLICAR DECISIÓN DE UN MODERADOR (moderation-review)
-- =====================================================
-- Atómico: chisme + reportes + cola. La media ya fue copiada a los buckets
-- públicos por moderation-review (al aprobar) y llega en p_media.
--   approve → publicado+aprobado (restaura lo auto-ocultado), media pública,
--             reportes 'dismissed'
--   reject  → oculto+rechazado (el texto no se borra: queda para apelación),
--             reportes 'actioned', gravedad obligatoria. La media PÚBLICA se
--             desvincula (sin esto su URL seguiría sirviendo el archivo para
--             siempre) y sus rutas vuelven en 'removed_media' para que
--             moderation-review las borre; si ese borrado falla, quedan
--             huérfanas y cleanup-media las borra (> 7 días).
-- Un chisme eliminado por su autor no se vuelve a publicar.

CREATE OR REPLACE FUNCTION apply_moderation_decision(
  p_queue_id UUID,
  p_decision TEXT,
  p_moderator_id UUID,
  p_severity TEXT DEFAULT NULL,
  p_reason TEXT DEFAULT NULL,
  p_note TEXT DEFAULT NULL,
  p_media JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_item public.moderation_queue%ROWTYPE;
  v_removed JSONB := '{}'::JSONB;
BEGIN
  IF p_decision NOT IN ('approve', 'reject') THEN
    RAISE EXCEPTION 'invalid_decision' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_item FROM public.moderation_queue WHERE id = p_queue_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'queue_item_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF v_item.status <> 'pending' THEN
    RAISE EXCEPTION 'queue_item_already_decided' USING ERRCODE = '55000';
  END IF;

  IF p_decision = 'approve' THEN
    UPDATE public.gossips SET
      status = 'published',
      moderation_status = 'approved',
      image_url = COALESCE(p_media->>'image_url', image_url),
      thumbnail_url = COALESCE(p_media->>'thumbnail_url', thumbnail_url),
      storage_path = COALESCE(p_media->>'storage_path', storage_path),
      thumbnail_storage_path = COALESCE(p_media->>'thumbnail_storage_path', thumbnail_storage_path),
      audio_url = COALESCE(p_media->>'audio_url', audio_url),
      audio_storage_path = COALESCE(p_media->>'audio_storage_path', audio_storage_path)
    WHERE id = v_item.gossip_id
      AND deleted_at IS NULL
      AND status <> 'deleted';

    UPDATE public.content_reports
    SET status = 'dismissed', reviewed_at = NOW(), reviewed_by = p_moderator_id
    WHERE gossip_id = v_item.gossip_id AND status = 'pending';
  ELSE
    -- Rutas públicas antes de desvincularlas (bloqueo de fila: sin carreras)
    SELECT jsonb_strip_nulls(jsonb_build_object(
      'images', NULLIF(array_remove(ARRAY[g.storage_path, g.thumbnail_storage_path], NULL), '{}'),
      'audio', NULLIF(array_remove(ARRAY[g.audio_storage_path], NULL), '{}')
    ))
    INTO v_removed
    FROM public.gossips g
    WHERE g.id = v_item.gossip_id
    FOR UPDATE;

    UPDATE public.gossips SET
      status = CASE WHEN status = 'deleted' THEN status ELSE 'hidden' END,
      moderation_status = CASE WHEN status = 'deleted' THEN moderation_status ELSE 'rejected' END,
      image_url = NULL,
      thumbnail_url = NULL,
      storage_path = NULL,
      thumbnail_storage_path = NULL,
      audio_url = NULL,
      audio_storage_path = NULL
    WHERE id = v_item.gossip_id;

    UPDATE public.content_reports
    SET status = 'actioned', reviewed_at = NOW(), reviewed_by = p_moderator_id
    WHERE gossip_id = v_item.gossip_id AND status = 'pending';
  END IF;

  UPDATE public.moderation_queue SET
    status = CASE p_decision WHEN 'approve' THEN 'approved' ELSE 'rejected' END,
    decided_by = p_moderator_id,
    decided_at = NOW(),
    decision_severity = CASE p_decision WHEN 'reject' THEN p_severity END,
    decision_reason = p_reason,
    decision_note = p_note,
    updated_at = NOW()
  WHERE id = p_queue_id
  RETURNING * INTO v_item;

  RETURN to_jsonb(v_item) || jsonb_build_object('removed_media', COALESCE(v_removed, '{}'::JSONB));
END;
$$;

REVOKE ALL ON FUNCTION apply_moderation_decision(UUID, TEXT, UUID, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION apply_moderation_decision(UUID, TEXT, UUID, TEXT, TEXT, TEXT, JSONB) TO service_role;

-- =====================================================
-- 7. VISTA PARA LISTAR LA COLA (moderation-review)
-- =====================================================
-- Con el contenido y el autor REAL (también de anónimos): solo el equipo de
-- moderación lo ve. Excluye pendientes cuyo chisme ya fue eliminado.

CREATE VIEW moderation_queue_items AS
SELECT
  q.*,
  p.username AS author_username,
  p.display_name AS author_display_name,
  g.subject,
  g.content,
  g.published_as,
  g.status AS gossip_status,
  g.moderation_status AS gossip_moderation_status,
  g.country_id,
  g.region_id,
  g.city_id,
  g.image_url,
  g.audio_url,
  g.like_count + g.comment_count + g.share_count AS interactions,
  g.created_at AS content_created_at
FROM moderation_queue q
JOIN gossips g ON g.id = q.gossip_id
LEFT JOIN profiles p ON p.id = q.content_author_id
WHERE NOT (q.status = 'pending' AND (g.deleted_at IS NOT NULL OR g.status = 'deleted'));

REVOKE ALL ON TABLE moderation_queue_items FROM anon, authenticated;
GRANT SELECT ON TABLE moderation_queue_items TO service_role;

-- =====================================================
-- 8. LIMPIEZA DE MEDIA (antes en 011)
-- =====================================================
-- Candidatos a borrar (solo lectura; borra cleanup-media con la Storage API):
--   - cuarentena > 24 h, SALVO la media de entradas pendientes en la cola
--   - públicos > 7 días que ningún gossip referencia

CREATE OR REPLACE FUNCTION get_media_cleanup_candidates(p_limit INTEGER DEFAULT 1000)
RETURNS TABLE (bucket_id TEXT, name TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT o.bucket_id, o.name
  FROM storage.objects o
  WHERE o.name NOT LIKE '%.emptyFolderPlaceholder'
    AND (
      (
        o.bucket_id IN ('images-quarantine', 'audio-quarantine')
        AND o.created_at < NOW() - INTERVAL '24 hours'
        AND NOT EXISTS (
          SELECT 1 FROM public.moderation_queue q
          WHERE q.status = 'pending'
            AND (
              (o.bucket_id = 'images-quarantine' AND q.image_quarantine_path = o.name)
              OR (o.bucket_id = 'audio-quarantine' AND q.audio_quarantine_path = o.name)
            )
        )
      )
      OR (
        o.bucket_id = 'images'
        AND o.created_at < NOW() - INTERVAL '7 days'
        AND NOT EXISTS (
          SELECT 1 FROM public.gossips g
          WHERE g.storage_path = o.name
             OR g.thumbnail_storage_path = o.name
        )
      )
      OR (
        o.bucket_id = 'audio'
        AND o.created_at < NOW() - INTERVAL '7 days'
        AND NOT EXISTS (
          SELECT 1 FROM public.gossips g
          WHERE g.audio_storage_path = o.name
        )
      )
    )
  ORDER BY o.created_at
  LIMIT LEAST(GREATEST(p_limit, 1), 1000);
$$;

COMMENT ON FUNCTION get_media_cleanup_candidates IS
'Lista archivos de media a borrar (cuarentena >24 h salvo la pendiente de revisión, públicos huérfanos >7 días). '
'No borra nada: el borrado lo hace la Edge Function cleanup-media con la Storage API.';

REVOKE ALL ON FUNCTION get_media_cleanup_candidates(INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_media_cleanup_candidates(INTEGER) TO service_role;
