// =====================================================
// EDGE FUNCTION: search-cities
// =====================================================
// Búsqueda de ciudades con autocomplete remoto
//
// Motivación:
// - Filtrado local en memoria no escala con 10,000+ ciudades
// - Permite búsqueda eficiente con índices de BD
// - Reduce payload al cliente (solo resultados relevantes)
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

interface SearchCitiesRequest {
  q: string           // Query string (ej: "Med")
  region_id: string   // ID de región para filtrar
  limit?: number      // Máximo de resultados (default: 10)
}

interface City {
  id: string
  name: string
  region_id: string
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
    // PASO 1: Parsear Request
    // =====================================================
    const url = new URL(req.url)
    const q = url.searchParams.get('q')
    const regionId = url.searchParams.get('region_id')
    const limitParam = url.searchParams.get('limit')
    const limit = limitParam ? parseInt(limitParam, 10) : 10

    // =====================================================
    // PASO 2: Validaciones
    // =====================================================
    if (!q || q.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Query parameter "q" is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (!regionId) {
      return new Response(
        JSON.stringify({ error: 'Query parameter "region_id" is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Validar límite
    if (limit < 1 || limit > 50) {
      return new Response(
        JSON.stringify({ error: 'Limit must be between 1 and 50' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Validar longitud de query (mínimo 2 caracteres)
    if (q.trim().length < 2) {
      return new Response(
        JSON.stringify({
          cities: [],
          meta: {
            query: q,
            region_id: regionId,
            count: 0,
            message: 'Query too short (minimum 2 characters)'
          }
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // =====================================================
    // PASO 3: Crear Cliente Supabase (con anon key)
    // =====================================================
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    const supabase = createClient(supabaseUrl, supabaseAnonKey)

    // =====================================================
    // PASO 4: Búsqueda en BD
    // =====================================================
    // Usar ILIKE para case-insensitive search
    // Pattern: "query%" para búsqueda por prefijo (más eficiente con índice)
    const searchPattern = `${q.trim()}%`

    const { data: cities, error: dbError } = await supabase
      .from('location_cities')
      .select('id, name, region_id')
      .eq('region_id', regionId)
      .ilike('name', searchPattern)
      .order('name', { ascending: true })
      .limit(limit)

    if (dbError) {
      console.error('Database error:', dbError)
      return new Response(
        JSON.stringify({
          error: 'Database error',
          details: dbError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // =====================================================
    // PASO 5: Retornar Resultados
    // =====================================================
    return new Response(
      JSON.stringify({
        cities: cities || [],
        meta: {
          query: q,
          region_id: regionId,
          count: (cities || []).length,
          limit: limit,
        }
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
// 1. Índice Recomendado:
//    CREATE INDEX idx_cities_region_name
//    ON location_cities(region_id, name);
//
// 2. Performance:
//    - ILIKE con pattern "query%" usa índice B-tree
//    - Evitar patterns "%query%" (no usa índice)
//    - Limit de 50 máximo previene queries costosas
//
// 3. Rate Limiting:
//    - Cliente debe implementar debounce (300ms)
//    - Considerar rate limit en API Gateway si hay abuso
//
// 4. Testing:
//    curl "https://xxx.supabase.co/functions/v1/search-cities?q=Med&region_id=ANT&limit=10" \
//      -H "Authorization: Bearer ANON_KEY"
//
// 5. Mejoras Futuras (si es necesario):
//    - Full-text search con ts_vector
//    - Fuzzy matching (Levenshtein distance)
//    - Cache con Redis
//    - Búsqueda por múltiples regiones
// =====================================================
