// =====================================================
// EDGE FUNCTION: report-gossip
// =====================================================
// Permite a usuarios reportar gossips inapropiados
//
// Flujo:
// 1. Usuario autenticado reporta un chisme que puede ver (public_gossips)
// 2. Se crea el reporte en `content_reports` (service_role: los clientes no
//    tienen acceso a la tabla)
// 3. El trigger de content_reports aplica el umbral (013_moderation.sql):
//    cola de revisión y, si corresponde, auto-ocultar. Umbrales en
//    moderation_settings.
// 4. Moderadores deciden con moderation-review
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

interface ReportGossipRequest {
  gossip_id: string
  reason: 'spam' | 'harassment' | 'violence' | 'sexual_content' | 'misinformation' | 'other'
  details?: string  // Opcional, max 500 caracteres
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
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', details: authError?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 2: Parsear Body
    // =====================================================
    const body: ReportGossipRequest = await req.json()

    // =====================================================
    // PASO 3: Validaciones
    // =====================================================
    if (!body.gossip_id || typeof body.gossip_id !== 'string') {
      return new Response(
        JSON.stringify({ error: 'gossip_id is required and must be a string' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const validReasons = ['spam', 'harassment', 'violence', 'sexual_content', 'misinformation', 'other']
    if (!body.reason || !validReasons.includes(body.reason)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid reason',
          valid_reasons: validReasons
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (body.details && body.details.length > 500) {
      return new Response(
        JSON.stringify({ error: 'details must be 500 characters or less' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 4: Verificar que el chisme existe y el usuario puede verlo
    // =====================================================
    // Con el JWT del usuario: solo se reporta lo visible para él.
    // (public_gossips muestra created_by solo si es del propio usuario o
    // si el chisme no es anónimo: alcanza para detectar el propio.)
    const { data: gossip, error: gossipError } = await supabase
      .from('public_gossips')
      .select('id, created_by')
      .eq('id', body.gossip_id)
      .maybeSingle()

    if (gossipError || !gossip) {
      return new Response(
        JSON.stringify({ error: 'Gossip not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // No se reporta lo propio (sumaría a su propio umbral)
    if (gossip.created_by === user.id) {
      return new Response(
        JSON.stringify({ error: 'You cannot report your own gossip' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 5: Crear reporte (el trigger aplica el umbral)
    // =====================================================
    const supabaseAdmin = createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: report, error: reportError } = await supabaseAdmin
      .from('content_reports')
      .insert({
        gossip_id: body.gossip_id,
        reason: body.reason,
        details: body.details || null,
        reported_by: user.id,
      })
      .select('id, gossip_id, reason, status, created_at')
      .single()

    if (reportError) {
      // Índice único (gossip_id, reported_by): ya lo había reportado
      if (reportError.code === '23505') {
        return new Response(
          JSON.stringify({ error: 'You have already reported this gossip' }),
          { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      console.error('Error creating report:', reportError)
      return new Response(
        JSON.stringify({ error: 'Failed to create report' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // =====================================================
    // PASO 6: Retornar Success
    // =====================================================
    return new Response(
      JSON.stringify({
        success: true,
        report: {
          id: report.id,
          gossip_id: report.gossip_id,
          reason: report.reason,
          status: report.status,
          created_at: report.created_at,
        },
        message: 'Report submitted successfully. Our moderators will review it.',
      }),
      {
        status: 201,
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
// 1. Crear tabla gossip_reports:
//    CREATE TABLE gossip_reports (
//      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//      gossip_id UUID NOT NULL REFERENCES gossips(id),
//      reported_by UUID NOT NULL REFERENCES auth.users(id),
//      reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'violence', 'sexual_content', 'misinformation', 'other')),
//      details TEXT CHECK (length(details) <= 500),
//      status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
//      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
//      UNIQUE(gossip_id, reported_by)  -- Prevenir reportes duplicados
//    );
//
// 2. RLS Policies:
//    - Users can INSERT their own reports
//    - Users can READ their own reports
//    - Moderators can READ/UPDATE all reports
//
// 3. Rate Limiting:
//    - 1 reporte por gossip por usuario (UNIQUE constraint)
//    - Considerar rate limit global (10 reportes/hora por usuario)
//
// 4. Testing:
//    curl -X POST "https://xxx.supabase.co/functions/v1/report-gossip" \
//      -H "Authorization: Bearer USER_TOKEN" \
//      -H "Content-Type: application/json" \
//      -d '{"gossip_id":"xxx","reason":"spam","details":"This is spam"}'
//
// 5. Mejoras Futuras:
//    - Notificar a moderadores (Slack, email)
//    - Auto-hide gossip si reports > 10
//    - ML model para detectar reportes falsos
// =====================================================
