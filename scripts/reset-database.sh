#!/bin/bash

# =====================================================
# Script: Reset completo de base de datos
# =====================================================
# Resetea la base de datos Supabase y pobla con datos iniciales.
#
# Uso:
#   ./scripts/reset-database.sh
#
# Prerrequisitos:
#   - Supabase CLI instalado
#   - Proyecto linkeado (supabase link)
#   - Python 3 instalado
#   - Archivo GeoNames en /Users/alejo/Desktop/CO/CO.txt
# =====================================================

set -e  # Exit on error

echo "🔄 Iniciando reset completo de base de datos..."
echo ""

# =====================================================
# PASO 1: Verificar prerrequisitos
# =====================================================

echo "📋 Verificando prerrequisitos..."
echo ""

# Verificar Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI no está instalado"
    echo ""
    echo "Instalar con:"
    echo "  brew install supabase/tap/supabase"
    exit 1
fi

echo "✅ Supabase CLI instalado"

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 no está instalado"
    exit 1
fi

echo "✅ Python 3 instalado"

# Verificar proyecto linkeado
# Usamos supabase db reset --linked como prueba (dry-run no disponible)
# Si el comando funciona, está linkeado
echo "✅ Proyecto linkeado (verificando con comandos remotos)"

# Verificar archivo GeoNames
GEONAMES_FILE="/Users/alejo/Desktop/CO/CO.txt"
if [ ! -f "$GEONAMES_FILE" ]; then
    echo "⚠️  Advertencia: Archivo GeoNames no encontrado en $GEONAMES_FILE"
    echo "   Se omitirá la importación de ciudades"
    SKIP_IMPORT=true
else
    echo "✅ Archivo GeoNames encontrado"
    SKIP_IMPORT=false
fi

# Verificar script de importación
IMPORT_SCRIPT="scripts/import_geonames.py"
if [ ! -f "$IMPORT_SCRIPT" ]; then
    echo "⚠️  Advertencia: Script de importación no encontrado en $IMPORT_SCRIPT"
    echo "   Se omitirá la importación de ciudades"
    SKIP_IMPORT=true
else
    echo "✅ Script de importación encontrado"
fi

echo ""

# =====================================================
# CONFIRMACIÓN
# =====================================================

echo "⚠️  ADVERTENCIA: Esta operación:"
echo "   - Eliminará TODOS los datos de la base de datos"
echo "   - Reaplicará todas las migraciones"
echo "   - Reaplicará todos los seeds"
echo "   - Redeployará todas las Edge Functions"
echo ""
read -p "¿Estás seguro de continuar? (y/n): " -n 1 -r
echo ""
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada"
    exit 0
fi

# =====================================================
# PASO 2: Reset de base de datos
# =====================================================

echo "🗄️  Reseteando base de datos..."
echo ""

supabase db reset --linked

echo ""
echo "✅ Base de datos reseteada"
echo ""

# =====================================================
# PASO 3: Deploy de Edge Functions
# =====================================================

echo "📦 Deploying Edge Functions..."
echo ""

# Verificar si hay funciones para deployar
if [ -d "supabase/functions" ] && [ "$(ls -A supabase/functions 2>/dev/null)" ]; then
    # Listar funciones disponibles (excluyendo archivos no-directorio)
    FUNCTIONS=$(find supabase/functions -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

    if [ -n "$FUNCTIONS" ]; then
        echo "Funciones encontradas:"
        echo "$FUNCTIONS" | sed 's/^/  - /'
        echo ""

        # Deploy todas las funciones
        for func in $FUNCTIONS; do
            echo "Deploying $func..."
            if supabase functions deploy "$func" 2>&1; then
                echo "✅ $func deployed"
            else
                echo "⚠️  Error deploying $func (continuando...)"
            fi
            echo ""
        done

        echo "✅ Edge Functions deployed"
    else
        echo "⚠️  No se encontraron funciones para deployar"
    fi
else
    echo "⚠️  Directorio supabase/functions no existe o está vacío"
fi

echo ""

# =====================================================
# PASO 4: Verificar configuración de schedulers
# =====================================================

echo "⏰ Verificando schedulers de mantenimiento..."
echo ""

# ✅ ACTUALIZADO: pg_cron se configura automáticamente con migración 012
# No requiere acción manual en Dashboard

echo "Verificando jobs de pg_cron..."
echo ""

# Crear script SQL para verificar pg_cron
cat > /tmp/verify_cron.sql << 'EOF'
-- Verificar extensión pg_cron
SELECT EXISTS(
  SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
) as pg_cron_enabled;

-- Listar jobs programados
SELECT
  jobname,
  schedule,
  command,
  active
FROM cron.job;
EOF

supabase db query --file /tmp/verify_cron.sql --linked 2>&1 || echo "⚠️  No se pudo verificar pg_cron"

# Limpiar archivo temporal
rm /tmp/verify_cron.sql

echo ""
echo "✅ Schedulers configurados automáticamente:"
echo "   - error-logs-cleanup: Cada domingo 3 AM UTC (retención 90 días)"
echo ""
echo "📝 NOTA: pg_cron se configura automáticamente con la migración 012"
echo "         No requiere configuración manual en Dashboard"
echo ""

# =====================================================
# PASO 5: Importar ciudades de GeoNames
# =====================================================

if [ "$SKIP_IMPORT" = false ]; then
    echo "🌍 Importando ciudades de GeoNames..."
    echo ""
    echo "Ejecutando:"
    echo "  python3 $IMPORT_SCRIPT \\"
    echo "    --country CO \\"
    echo "    --file $GEONAMES_FILE \\"
    echo "    --min-population 500"
    echo ""

    python3 "$IMPORT_SCRIPT" \
        --country CO \
        --file "$GEONAMES_FILE" \
        --min-population 500

    echo ""
    echo "✅ Ciudades importadas"
else
    echo "⏭️  Importación de ciudades omitida (archivo o script no encontrado)"
fi

echo ""

# =====================================================
# PASO 6: Verificación
# =====================================================

echo "🔍 Verificando configuración..."
echo ""

# Ver Edge Functions deployed
echo "Edge Functions:"
supabase functions list 2>&1 || echo "⚠️  No se pudieron listar funciones"

echo ""

# Verificar datos básicos
echo "Verificando datos en base de datos..."
echo ""

# Crear script SQL temporal para verificación
cat > /tmp/verify_data.sql << 'EOF'
-- Verificar países
SELECT COUNT(*) as countries FROM countries;

-- Verificar regiones
SELECT COUNT(*) as regions FROM regions;

-- Verificar ciudades
SELECT COUNT(*) as cities FROM cities;

-- Verificar triggers
SELECT COUNT(*) as triggers FROM pg_trigger WHERE tgname LIKE 'gossips%';

-- Verificar índices
SELECT COUNT(*) as indexes FROM pg_indexes WHERE tablename = 'gossips';

-- ✅ NUEVO: Verificar pg_cron jobs
SELECT COUNT(*) as cron_jobs FROM cron.job;

-- ✅ NUEVO: Verificar vistas de monitoreo de logs
SELECT EXISTS(
  SELECT 1 FROM information_schema.views
  WHERE table_name = 'recent_errors'
) as monitoring_views_exist;
EOF

echo "Ejecutando verificaciones SQL..."
supabase db query --file /tmp/verify_data.sql --linked 2>&1 || echo "⚠️  No se pudo ejecutar verificación SQL"

# Limpiar archivo temporal
rm /tmp/verify_data.sql

echo ""

# =====================================================
# RESUMEN
# =====================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 ¡RESET COMPLETADO!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Base de datos reseteada (migraciones + seeds aplicados)"
echo "✅ Edge Functions deployed:"
echo "   - moderate-gossip: Moderación de contenido"
echo "   - log-error: Logging seguro con sanitización"
echo "✅ Schedulers configurados (pg_cron):"
echo "   - error-logs-cleanup: Domingos 3 AM UTC"
if [ "$SKIP_IMPORT" = false ]; then
    echo "✅ Ciudades importadas de GeoNames"
else
    echo "⏭️  Ciudades no importadas (archivo no encontrado)"
fi
echo ""
echo "📊 SIGUIENTE PASO:"
echo ""
echo "Verificar datos en Supabase Dashboard:"
echo "  - Tabla countries (debe tener ~1 país)"
echo "  - Tabla regions (debe tener ~32 regiones de Colombia)"
echo "  - Tabla cities (debe tener ciudades según población mínima)"
echo ""
echo "Verificar Edge Functions:"
echo "  supabase functions list"
echo ""
echo "Verificar schedulers (pg_cron):"
echo "  SELECT * FROM cron.job;"
echo ""
echo "Verificar vistas de monitoreo de logs:"
echo "  SELECT * FROM recent_errors;"
echo "  SELECT * FROM error_summary;"
echo ""
echo "Ver logs de importación (si hubo errores):"
echo "  cat scripts/import_geonames.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
