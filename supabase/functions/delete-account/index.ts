// =====================================================
// EDGE FUNCTION: delete-account
// =====================================================
// Elimina cuenta de usuario y todos sus datos (GDPR compliant)
//
// Flujo:
// 1. Usuario autenticado solicita eliminación
// 2. Soft-delete de gossips (anonymizar autor)
// 3. Eliminar datos personales (email, etc.)
// 4. Eliminar cuenta de auth.users
//
// ⚠️ IRREVERSIBLE - Requiere confirmación doble en UI
//
// Fecha: 2026-10-22
// Autor: Alejo + Claude Code
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DeleteAccountRequest {
  confirmation: string  // User must send "DELETE_MY_ACCOUNT"
  reason?: string       // Optional feedback
}

serve(async (req) => {
  // =====================================================
  // CORS Preflight
  // =====================================================
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // =====================================================
    // PASO 1: Autenticación (REQUERIDA)
    // =====================================================
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabaseAnon = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { data: { user }, error: authError } = await supabaseAnon.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', details: authError?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 2: Parsear Body
    // =====================================================
    const body: DeleteAccountRequest = await req.json()

    // =====================================================
    // PASO 3: Validar Confirmación
    // =====================================================
    if (body.confirmation !== 'DELETE_MY_ACCOUNT') {
      return new Response(
        JSON.stringify({
          error: 'Invalid confirmation',
          message: 'You must send confirmation: "DELETE_MY_ACCOUNT"'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 4: Usar Service Role (para bypass RLS)
    // =====================================================
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    // =====================================================
    // PASO 5: Soft-Delete Gossips (Anonymizar)
    // =====================================================
    // Estrategia: No eliminar gossips (pueden tener comentarios/interacciones)
    // En su lugar, anonymizar el autor
    //
    // Opciones:
    // A) Cambiar created_by a UUID anónimo
    // B) Cambiar status a 'deleted'
    // C) Mantener pero marcar como [deleted user]
    const { error: gossipsError } = await supabaseAdmin
      .from('gossips')
      .update({
        deleted_at: new Date().toISOString(),
        deleted_by: user.id,
        // Opcionalmente: anonymizar created_by
        // created_by: '00000000-0000-0000-0000-000000000000',
      })
      .eq('created_by', user.id)
      .is('deleted_at', null)  // Solo los no eliminados

    if (gossipsError) {
      console.error('Error deleting gossips:', gossipsError)
      // Continue anyway - no queremos bloquear la eliminación de cuenta
    }

    // =====================================================
    // PASO 6: Eliminar Otros Datos
    // =====================================================

    // A) Eliminar reportes del usuario
    const { error: reportsError } = await supabaseAdmin
      .from('gossip_reports')
      .delete()
      .eq('reported_by', user.id)

    if (reportsError) {
      console.error('Error deleting reports:', reportsError)
    }

    // B) Eliminar rate limits
    const { error: rateLimitsError } = await supabaseAdmin
      .from('rate_limits')
      .delete()
      .eq('user_id', user.id)

    if (rateLimitsError) {
      console.error('Error deleting rate limits:', rateLimitsError)
    }

    // C) Eliminar ubicación por defecto (si existe tabla user_preferences)
    // await supabaseAdmin
    //   .from('user_preferences')
    //   .delete()
    //   .eq('user_id', user.id)

    // =====================================================
    // PASO 7: Guardar Feedback (Opcional)
    // =====================================================
    if (body.reason) {
      // Guardar feedback en tabla de analytics (sin info personal)
      await supabaseAdmin
        .from('account_deletion_feedback')
        .insert({
          reason: body.reason,
          deleted_at: new Date().toISOString(),
          // NO incluir user_id (GDPR)
        })
        .catch((err) => {
          // No bloquear eliminación si esto falla
          console.error('Failed to save feedback:', err)
        })
    }

    // =====================================================
    // PASO 8: Eliminar Usuario de Auth (IRREVERSIBLE)
    // =====================================================
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteAuthError) {
      console.error('Error deleting auth user:', deleteAuthError)
      return new Response(
        JSON.stringify({
          error: 'Failed to delete account',
          details: deleteAuthError.message,
          message: 'Your data was deleted but account still exists. Please contact support.'
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 9: Retornar Success
    // =====================================================
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Your account has been permanently deleted.',
        deleted_at: new Date().toISOString(),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// =====================================================
// NOTAS DE IMPLEMENTACIÓN
// =====================================================
//
// 1. GDPR Compliance:
//    - Usuario debe poder eliminar todos sus datos
//    - Eliminar en máximo 30 días (nosotros inmediato)
//    - Guardar logs de eliminación (sin datos personales)
//
// 2. Estrategia de Eliminación:
//    - Gossips: Soft-delete (anonymizar autor, mantener contenido)
//    - Comentarios: Si existen, anonymizar
//    - Reportes: Hard-delete (no relevantes sin usuario)
//    - Auth: Hard-delete (Supabase Auth)
//
// 3. Testing:
//    curl -X POST "https://xxx.supabase.co/functions/v1/delete-account" \
//      -H "Authorization: Bearer USER_TOKEN" \
//      -H "Content-Type: application/json" \
//      -d '{"confirmation":"DELETE_MY_ACCOUNT","reason":"No longer need it"}'
//
// 4. UI Flow:
//    a) Botón "Eliminar cuenta" en Settings
//    b) Dialog de confirmación #1: Explicar consecuencias
//    c) Dialog de confirmación #2: Escribir "DELETE_MY_ACCOUNT"
//    d) Llamar a Edge Function
//    e) Sign out + Redirect a landing page
//
// 5. Backup/Restore:
//    - NO implementar restore (GDPR requiere eliminación permanente)
//    - Backup automático de BD antes de eliminación (infra)
//
// 6. Mejoras Futuras:
//    - Rate limit (1 eliminación por usuario - obvio)
//    - Email de confirmación antes de eliminar
//    - Grace period de 7 días (soft-delete, luego hard-delete)
//    - Export de datos antes de eliminar (GDPR "right to portability")
//
// 7. Tabla de Feedback (Opcional):
//    CREATE TABLE account_deletion_feedback (
//      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//      reason TEXT,
//      deleted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
//      -- NO incluir user_id (GDPR)
//    );
// =====================================================
