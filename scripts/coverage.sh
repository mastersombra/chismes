#!/bin/bash

# Script para generar reporte de coverage
# Uso: ./scripts/coverage.sh [test_file]
#
# Ejemplos:
#   ./scripts/coverage.sh                          # Todos los tests
#   ./scripts/coverage.sh test/main_test.dart      # Test específico
#   ./scripts/coverage.sh test/features/gossip/    # Feature completo

set -e

# Determinar qué tests ejecutar
TEST_PATH="${1:-}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🧪 GENERADOR DE COVERAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$TEST_PATH" ]; then
    echo "📝 Ejecutando tests: $TEST_PATH"
else
    echo "📝 Ejecutando TODOS los tests"
fi

echo ""
echo "🧪 Ejecutando tests con coverage..."
if [ -n "$TEST_PATH" ]; then
    flutter test --coverage "$TEST_PATH" 2>&1 | tail -5
else
    flutter test --coverage 2>&1 | tail -5
fi

echo ""
echo "📊 Generando reporte HTML..."
genhtml coverage/lcov.info -o coverage/html --no-function-coverage 2>&1 | tail -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ✅ COVERAGE GENERADO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📂 Archivos generados:"
echo "   • coverage/lcov.info (datos raw)"
echo "   • coverage/html/index.html (reporte web)"
echo ""

echo "🌐 Abriendo reporte en navegador..."
open coverage/html/index.html

echo ""
echo "✨ ¡Listo! Revisa el reporte en tu navegador."
echo ""
