#!/bin/bash

# Script para analizar y organizar fallos de tests

echo "═══════════════════════════════════════════════════════════════════"
echo "📊 REPORTE DE FALLOS DE TESTS - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Extraer resumen final
echo "📈 RESUMEN GENERAL:"
tail -5 test_output.log | grep -E "^\d{2}:\d{2} \+\d+ ~\d+ -\d+:"
echo ""

# Contar tests por estado
PASSED=$(tail -1 test_output.log | grep -oE '\+[0-9]+' | tr -d '+')
SKIPPED=$(tail -1 test_output.log | grep -oE '~[0-9]+' | tr -d '~')
FAILED=$(tail -1 test_output.log | grep -oE '\-[0-9]+' | tr -d '-')

echo "✅ Pasaron: $PASSED"
echo "⏭️  Saltados: $SKIPPED"
echo "❌ Fallaron: $FAILED"
echo ""

# Extraer tests fallidos únicos
echo "═══════════════════════════════════════════════════════════════════"
echo "❌ TESTS FALLIDOS (organizados por archivo):"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

grep "\[E\]" test_output.log | \
  sed 's/^.*: \/Users\/alejo\/Documents\/Piloto\/chismes\/test\///' | \
  sed 's/\[E\].*$//' | \
  sort | \
  awk -F': ' '{
    file = $1
    test = $2
    if (file != last_file) {
      if (last_file != "") print ""
      print "📁 " file
      print "----------------------------------------"
      last_file = file
      count = 1
    }
    printf "  %d. %s\n", count++, test
  }'

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "🔍 ERRORES MÁS COMUNES:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Identificar patrones de error
echo "Analizando patrones de error..."
grep -A 3 "╞════════════════════════════════════════════════════" test_output.log | \
  grep "The following" | \
  sort | uniq -c | sort -rn | head -10

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "💡 ANÁLISIS DE ERRORES PRINCIPALES:"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Buscar "Too many elements"
TOO_MANY=$(grep -c "Bad state: Too many elements" test_output.log)
echo "🔸 'Too many elements': $TOO_MANY ocurrencias"

# Buscar "exactly one matching candidate"
TOO_MANY_WIDGETS=$(grep -c "exactly one matching candidate" test_output.log)
echo "🔸 'exactly one matching candidate' (múltiples widgets): $TOO_MANY_WIDGETS ocurrencias"

# Buscar tipos de error más comunes
echo ""
echo "Tipos de excepciones más comunes:"
grep "The following" test_output.log | \
  sed 's/The following //' | \
  sed 's/ was thrown.*//' | \
  sort | uniq -c | sort -rn | head -5

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✨ REPORTE COMPLETO GENERADO"
echo "═══════════════════════════════════════════════════════════════════"
