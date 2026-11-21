// =====================================================
// EDGE FUNCTION: account-status
// =====================================================
// Estado de la cuenta del usuario autenticado (sanciones y apelaciones,
// 015_sanctions.sql). Cualquier usuario, solo sobre sí mismo.
//
// POST {} | { action: 'status' }
//   → { status: { state, restricted_until, active_points, strike_count,
//                 expiry_days, thresholds, appeal_window_days, inherited,
//                 rejections: [...] } }
//   Sin notas internas ni quién decidió.
//
// POST { action: 'appeal', queue_id, message (10-1000) }
//   → 201 { appeal }. Una por rechazo, dentro del plazo.
//   404 not_found · 409 appeal_already_exists | appeal_window_closed · 400
//
// Antes de responder revisa si es reincidente (claim_inherited_strikes):
// requiere ACCOUNT_HASH_SECRET (sin él no hereda, pero responde igual).
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { loadSanctionStatus } from '../_shared/sanctions.ts'
import { appealErrorResponse, parseAccountStatusRequest } from './logic.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseUser = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return json({ error: 'Unauthorized' }, 401)
    }

    let rawBody: unknown = null
    const text = await req.text()
    if (text.trim().length > 0) {
      try {
        rawBody = JSON.parse(text)
      } catch {
        return json({ error: 'Invalid JSON in request body' }, 400)
      }
    }
    const parsed = parseAccountStatusRequest(rawBody)
    if (!parsed.ok) {
      return json({ error: parsed.error, field: parsed.field, code: 'validation_error' }, 400)
    }

    const supabaseAdmin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)

    // Revisa reincidencia (idempotente) antes de leer o apelar
    const sanction = await loadSanctionStatus(supabaseAdmin, user, Deno.env.get('ACCOUNT_HASH_SECRET'))
    if (!sanction) {
      return json({ error: 'Failed to load account status' }, 500)
    }

    if (parsed.value.action === 'status') {
      const { data, error } = await supabaseAdmin.rpc('get_account_status', { p_user_id: user.id })
      if (error || !data) {
        console.error('❌ get_account_status failed:', error)
        return json({ error: 'Failed to load account status' }, 500)
      }
      return json({ status: data })
    }

    const { data: appeal, error: appealError } = await supabaseAdmin.rpc('submit_appeal', {
      p_user_id: user.id,
      p_queue_id: parsed.value.queueId,
      p_message: parsed.value.message,
    })
    if (appealError) {
      const mapped = appealErrorResponse(appealError.message ?? '')
      if (mapped.status === 500) console.error('❌ submit_appeal failed:', appealError)
      return json({ error: 'Appeal not created', code: mapped.code }, mapped.status)
    }

    console.log(`📨 Appeal ${appeal.id} for queue item ${parsed.value.queueId}`)
    return json({ appeal }, 201)
  } catch (error) {
    console.error('❌ Error in account-status:', error)
    return json({ error: 'Internal server error' }, 500)
  }
})
