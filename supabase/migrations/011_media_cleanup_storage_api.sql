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
--   1. get_media_cleanup_candidates() solo LISTA qué borrar (lectura;
--      definida en 013_moderation.sql).
--   2. La Edge Function cleanup-media borra con storage.remove().
--   3. Un job diario de pg_cron llama a la Edge Function vía pg_net.
--
-- Reglas (las mismas de 006):
--   - images-quarantine / audio-quarantine: archivos con más de 24 h
--     (nunca se movieron a público: moderación rechazada o proceso cortado),
--     salvo la media de chismes pendientes en la cola de revisión (013).
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

-- 2. Candidatos a borrar: get_media_cleanup_candidates() está en
--    013_moderation.sql, porque excluye la media en cuarentena de los
--    chismes pendientes en la cola de revisión (tabla creada en 013).
--    El job de abajo solo la invoca al ejecutarse.

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
