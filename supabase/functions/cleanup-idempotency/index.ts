// ==================================================
// Edge Function: Limpieza programada de idempotency_key
// ==================================================
// Ejecuta cleanup_old_idempotency_keys() en horario controlado.
//
// Programar con:
// supabase functions schedule cleanup-idempotency --cron "0 3 * * *"
//
// Horario: 3 AM diario (baja demanda)
// ==================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

interface CleanupResult {
  cleaned: number
  timestamp: string
  duration_ms: number
  error?: string
}

Deno.serve(async (req: Request): Promise<Response> => {
  const startTime = Date.now()

  try {
    // Crear cliente con service_role (permisos admin)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    )

    // Ejecutar función de limpieza
    const { data, error } = await supabase.rpc('cleanup_old_idempotency_keys')

    if (error) {
      console.error('Cleanup failed:', error)
      const result: CleanupResult = {
        cleaned: 0,
        timestamp: new Date().toISOString(),
        duration_ms: Date.now() - startTime,
        error: error.message,
      }
      return new Response(JSON.stringify(result), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Log resultado
    console.log(`Cleanup completed: ${data} keys cleaned`)

    const result: CleanupResult = {
      cleaned: data as number,
      timestamp: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
    }

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Unexpected error:', err)
    const result: CleanupResult = {
      cleaned: 0,
      timestamp: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      error: err instanceof Error ? err.message : 'Unknown error',
    }
    return new Response(JSON.stringify(result), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

/* ==================================================
 * CONFIGURACIÓN:
 *
 * 1. Deploy:
 *    supabase functions deploy cleanup-idempotency
 *
 * 2. Programar (diario a las 3 AM UTC):
 *    supabase functions schedule cleanup-idempotency \
 *      --cron "0 3 * * *"
 *
 * 3. Verificar:
 *    supabase functions list
 *
 * 4. Logs:
 *    supabase functions logs cleanup-idempotency
 *
 * 5. Ejecutar manualmente (testing):
 *    curl -X POST https://<project>.supabase.co/functions/v1/cleanup-idempotency \
 *      -H "Authorization: Bearer <anon-key>"
 *
 * ==================================================
 * MONITOREO:
 *
 * Query para verificar acumulación:
 *
 * SELECT
 *   COUNT(*) FILTER (WHERE idempotency_key IS NOT NULL) AS with_key,
 *   COUNT(*) AS total,
 *   ROUND(100.0 * COUNT(*) FILTER (WHERE idempotency_key IS NOT NULL) / COUNT(*), 2) AS percentage
 * FROM gossips;
 *
 * Esperado: 1-5% con key (gossips de últimas 24h)
 * Si > 10% → limpieza no está ejecutándose
 * ==================================================
 */
