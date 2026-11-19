#!/bin/bash

# Script para migrar logs de español a inglés
# Uso: ./tools/migrate_logs_to_english.sh

echo "🔄 Migrando logs a inglés..."

# Array de reemplazos: español → inglés
declare -A replacements=(
  # Acciones
  ["'Cargando"]="'Loading"
  ["'Creando"]="'Creating"
  ["'Actualizando"]="'Updating"
  ["'Eliminando"]="'Deleting"
  ["'Verificando"]="'Verifying"
  ["'Enviando"]="'Sending"
  ["'Recibido"]="'Received"
  ["'Guardando"]="'Saving"
  ["'Buscando"]="'Searching"

  # Estados
  ["'Éxito"]="'Success"
  ["'Exitoso"]="'Successful"
  ["'Falló"]="'Failed"
  ["'Error"]="'Error"

  # Objetos comunes
  ["'países'"]="'countries'"
  ["'regiones'"]="'regions'"
  ["'ciudades'"]="'cities'"
  ["'ubicación'"]="'location'"
  ["'servicio'"]="'service'"
  ["'permisos'"]="'permissions'"
  ["'información'"]="'information'"
  ["'imagen'"]="'image'"

  # Frases comunes
  ["Error al "]="Error "
  ["Error en "]="Error in "
  ["Error obteniendo"]="Error getting"
  ["Error guardando"]="Error saving"
  ["Error cargando"]="Error loading"
  ["Error eliminando"]="Error removing"
  ["Error recibiendo"]="Error receiving"
  ["Error seleccionando"]="Error selecting"

  # Deep links
  ["Deep link recibido"]="Deep link received"
  ["Deep link inicial"]="Initial deep link"
  ["Deep link sin"]="Deep link without"
  ["Esquema no soportado"]="Unsupported scheme"
  ["Tipo de deep link no soportado"]="Unsupported deep link type"
  ["Navegando a"]="Navigating to"

  # Ubicación
  ["Servicio de ubicación deshabilitado"]="Location service disabled"
  ["Permisos de ubicación denegados"]="Location permissions denied"
  ["Permisos de ubicación denegados permanentemente"]="Location permissions permanently denied"
  ["No se encontró información de ubicación"]="Location information not found"
  ["Información de ubicación incompleta"]="Incomplete location information"
  ["ubicación por defecto"]="default location"
  ["reverse geocoding"]="reverse geocoding"

  # Estados
  ["Ciudad seleccionada"]="City selected"
  ["Imagen seleccionada"]="Image selected"
  ["Países cargados"]="Countries loaded"

  # Otros
  ["✅ "]=""
  ["🗺️ "]=""
  ["🏙️ "]=""
  ["📍 "]=""
  ["📥 "]=""
  ["⚠️ "]=""
)

# Iterar sobre archivos Dart
find lib/ -name "*.dart" -type f | while read -r file; do
  echo "  Procesando: $file"

  # Aplicar reemplazos
  for spanish in "${!replacements[@]}"; do
    english="${replacements[$spanish]}"
    sed -i '' "s|$spanish|$english|g" "$file"
  done
done

echo "✅ Migración completada"
echo ""
echo "🔍 Verificando logs restantes en español..."
remaining=$(grep -rn "_logger\.[diwef](" lib/ --include="*.dart" | grep -E "'[A-ZÁÉÍÓÚÑ]|'[a-záéíóúñ]" | grep -v test | grep -v "// " | wc -l | tr -d ' ')
echo "   Logs en español restantes: $remaining"

if [ "$remaining" -gt 0 ]; then
  echo ""
  echo "📋 Logs que requieren revisión manual:"
  grep -rn "_logger\.[diwef](" lib/ --include="*.dart" | grep -E "'[A-ZÁÉÍÓÚÑ]|'[a-záéíóúñ]" | grep -v test | grep -v "// " | head -20
fi
