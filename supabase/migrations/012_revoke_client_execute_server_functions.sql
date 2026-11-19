-- =====================================================
-- 012: Quitar EXECUTE a anon/authenticated en funciones solo de servidor
-- =====================================================
-- Fecha: 2026-11-19
--
-- 🔴 Vulnerabilidad: en Postgres toda función nueva es ejecutable por PUBLIC, y
-- Supabase además da EXECUTE a anon y authenticated en el schema public.
-- Estas funciones son SECURITY DEFINER (corren como postgres, sin RLS) y nunca
-- tuvieron REVOKE, así que cualquiera con la anon key (empaquetada en la app)
-- podía llamarlas por /rest/v1/rpc/...
--
-- Verificado en local (2026-11-19), SIN iniciar sesión:
--   POST /rest/v1/rpc/upsert_gossip_idempotent
--     { p_status: 'published', p_moderation_status: 'approved',
--       p_visibility: 'public', p_created_by: <uuid de otro usuario>, ... }
--   → chisme publicado, aprobado y a nombre de otro usuario.
--   Se salta moderación, rate limit y autenticación.
--
-- Solo deben llamarlas la Edge Function (service_role), pg_cron (postgres) o
-- triggers (corren como el dueño de la función, no les afecta este REVOKE).
-- La app no llama a ninguna: crea chismes vía la Edge Function moderate-gossip.
-- =====================================================

-- Escritura de gossips con estados controlados por el llamador
REVOKE EXECUTE ON FUNCTION upsert_gossip_idempotent(
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID,
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT
) FROM PUBLIC, anon, authenticated;

-- RPC legacy: fuerza draft/pending/private, pero se salta el rate limit de la
-- Edge Function y la app ya no la usa.
REVOKE EXECUTE ON FUNCTION create_gossip_draft(
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID
) FROM PUBLIC, anon, authenticated;

-- Rate limiting: reserve permitía agotar el cupo de otro usuario y release,
-- liberar el propio para saltarse el límite.
REVOKE EXECUTE ON FUNCTION reserve_rate_limit_slot(UUID, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION release_rate_limit_slot(UUID, TEXT) FROM PUBLIC, anon, authenticated;

-- Mantenimiento (cron): cualquiera podía borrar error_logs o disparar limpiezas
REVOKE EXECUTE ON FUNCTION clean_old_error_logs() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION cleanup_old_idempotency_keys() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION cleanup_old_rate_limits() FROM PUBLIC, anon, authenticated;

-- Lectura de datos internos: estadísticas de error_logs y completitud de
-- perfiles de cualquier usuario
REVOKE EXECUTE ON FUNCTION check_error_log_rate() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION calculate_profile_completion(UUID) FROM PUBLIC, anon, authenticated;

-- service_role (Edge Functions) conserva acceso explícito
GRANT EXECUTE ON FUNCTION upsert_gossip_idempotent(
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID,
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT
) TO service_role;
GRANT EXECUTE ON FUNCTION create_gossip_draft(
  TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID
) TO service_role;
GRANT EXECUTE ON FUNCTION reserve_rate_limit_slot(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION release_rate_limit_slot(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION clean_old_error_logs() TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_idempotency_keys() TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_rate_limits() TO service_role;
GRANT EXECUTE ON FUNCTION check_error_log_rate() TO service_role;
GRANT EXECUTE ON FUNCTION calculate_profile_completion(UUID) TO service_role;

-- =====================================================
-- Verificación
-- =====================================================
DO $$
DECLARE
  v_exposed TEXT;
BEGIN
  SELECT string_agg(p.proname, ', ') INTO v_exposed
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname IN (
      'upsert_gossip_idempotent', 'create_gossip_draft',
      'reserve_rate_limit_slot', 'release_rate_limit_slot',
      'clean_old_error_logs', 'cleanup_old_idempotency_keys',
      'cleanup_old_rate_limits', 'check_error_log_rate',
      'calculate_profile_completion'
    )
    AND (
      has_function_privilege('anon', p.oid, 'EXECUTE')
      OR has_function_privilege('authenticated', p.oid, 'EXECUTE')
    );

  IF v_exposed IS NOT NULL THEN
    RAISE EXCEPTION '❌ Siguen expuestas a clientes: %', v_exposed;
  END IF;

  RAISE NOTICE '✅ Funciones de servidor sin EXECUTE para anon/authenticated';
END $$;
