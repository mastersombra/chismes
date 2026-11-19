-- =====================================================
-- 011: Limpieza de media con la Storage API (Edge Function + pg_cron)
-- =====================================================
-- Fecha: 2026-11-19
--
-- Antes: cleanup_quarantine_files(), cleanup_orphaned_images(),
-- cleanup_audio_quarantine_files() y cleanup_orphaned_audio() (006) hacían
-- DELETE FROM storage.objects. Eso borra la fila de metadata pero NO el archivo
-- (Supabase exige borrar con la Storage API), así que dejaba archivos
-- inaccesibles ocupando espacio. Además nunca se programaron.
--
-- Ahora:
--   1. get_media_cleanup_candidates() solo LISTA qué borrar (lectura).
--   2. La Edge Function cleanup-media borra con storage.remove().
--   3. Un job diario de pg_cron llama a la Edge Function vía pg_net.
--
-- Reglas (las mismas de 006):
--   - images-quarantine / audio-quarantine: archivos con más de 24 h
--     (nunca se movieron a público: moderación rechazada o proceso cortado).
--   - images / audio: archivos con más de 7 días que ningún gossip referencia
--     (storage_path, thumbnail_storage_path, audio_storage_path).
--
-- Requiere 3 secrets en Vault (NO van en el repo; ver supabase/functions/README.md):
--   project_url, anon_key, media_cleanup_secret
-- y el secret MEDIA_CLEANUP_SECRET en la Edge Function con el mismo valor.
-- Si faltan, el job corre pero la llamada falla (no borra nada).
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 1. Quitar las funciones que borraban solo la metadata
DROP FUNCTION IF EXISTS cleanup_quarantine_files();
DROP FUNCTION IF EXISTS cleanup_orphaned_images();
DROP FUNCTION IF EXISTS cleanup_audio_quarantine_files();
DROP FUNCTION IF EXISTS cleanup_orphaned_audio();

-- 2. Candidatos a borrar (solo lectura)
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
'Lista archivos de media a borrar (cuarentena >24 h, públicos huérfanos >7 días). '
'No borra nada: el borrado lo hace la Edge Function cleanup-media con la Storage API.';

REVOKE ALL ON FUNCTION get_media_cleanup_candidates(INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_media_cleanup_candidates(INTEGER) TO service_role;

-- 3. Programar la Edge Function a diario a las 4:00 AM UTC
--    (error-logs-cleanup: domingos 3:00; idempotency-keys-cleanup: 3:30)
SELECT cron.unschedule('media-cleanup')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'media-cleanup');

SELECT cron.schedule(
  'media-cleanup',
  '0 4 * * *',
  $job$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
           || '/functions/v1/cleanup-media',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'anon_key'),
      'x-cleanup-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'media_cleanup_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
  $job$
);

-- =====================================================
-- Verificación (manual)
-- =====================================================
-- SELECT jobname, schedule, active FROM cron.job;
--   → error-logs-cleanup, idempotency-keys-cleanup, media-cleanup
-- SELECT * FROM get_media_cleanup_candidates(10);   -- qué se borraría
-- SELECT status_code, content FROM net._http_response ORDER BY created DESC LIMIT 5;
--   → resultado de las últimas llamadas a la Edge Function
