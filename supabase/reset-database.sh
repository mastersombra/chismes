#!/bin/bash

# =====================================================
# Reset Database Script
# =====================================================
# Resetea completamente la base de datos Supabase
# aplicando todas las migraciones desde cero.
#
# ⚠️  ADVERTENCIA: Esto elimina TODOS los datos
# ⚠️  Solo usar en desarrollo
#
# Uso:
#   ./reset-database.sh
# =====================================================

set -e  # Exit on error

echo ""
echo "=========================================="
echo "  🔄 RESET DATABASE"
echo "=========================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "migrations" ]; then
  echo "❌ Error: Directorio 'migrations' no encontrado"
  echo "   Ejecuta este script desde: supabase/"
  exit 1
fi

# Confirmar con el usuario
echo "⚠️  ADVERTENCIA: Esto eliminará TODOS los datos"
echo ""
echo "Migraciones que se aplicarán:"
ls -1 migrations/*.sql | while read file; do
  echo "  ✓ $(basename "$file")"
done
echo ""
read -p "¿Estás seguro? (escribe 'yes' para continuar): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Cancelado por el usuario"
  exit 0
fi

echo ""
echo "🗑️  Reseteando base de datos..."
echo ""

# Reset database (elimina todo y aplica migraciones)
supabase db reset --linked

echo ""
echo "📦 Cargando datos seed..."
echo ""

# Cargar seeds
if [ -f "seed.sql" ]; then
  echo "  → Cargando seed.sql (países y regiones)..."
  supabase db query --linked -f seed.sql > /dev/null 2>&1
fi

if [ -f "seed_cities_simple.sql" ]; then
  echo "  → Cargando seed_cities_simple.sql (ciudades)..."
  supabase db query --linked -f seed_cities_simple.sql > /dev/null 2>&1
fi

echo ""
echo "=========================================="
echo "  ✅ DATABASE RESET COMPLETADO"
echo "=========================================="
echo ""
echo "La base de datos ha sido reseteada con:"
echo "  • $(ls -1 migrations/*.sql | wc -l | tr -d ' ') migraciones aplicadas"
echo "  • Seeds aplicados (países, regiones, ciudades)"
echo "  • Esquema limpio recreado"
echo ""
echo "Siguiente paso:"
echo "  1. Probar la app: flutter run"
echo ""
