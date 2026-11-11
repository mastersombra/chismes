#!/bin/bash

echo "🔍 Analizando TODOS los tests fallidos..."
echo ""

# Ejecutar tests y capturar output
echo "Ejecutando flutter test..."
flutter test --reporter expanded 2>&1 > /tmp/test_full_output.log

echo ""
echo "📊 ANÁLISIS COMPLETO"
echo "===================="
echo ""

# Contar tests
total=$(grep -c "^[0-9][0-9]:[0-9][0-9]" /tmp/test_full_output.log || echo "0")
passed=$(grep -o "\+[0-9]\+" /tmp/test_full_output.log | tail -1 | tr -d '+')
skipped=$(grep -o "~[0-9]\+" /tmp/test_full_output.log | tail -1 | tr -d '~')
failed=$(grep -o "\-[0-9]\+" /tmp/test_full_output.log | tail -1 | tr -d '-')

echo "Total procesados: ~$total líneas"
echo "Tests pasando: $passed"
echo "Tests skipped: $skipped"
echo "Tests fallando: $failed"
echo ""

# Encontrar tests con [E]
echo "❌ Tests marcados con [E]:"
echo "========================="
grep "\[E\]" /tmp/test_full_output.log | grep "test/" | sed 's/.*\(test\/.*\):\(.*\)\[E\]/  - \1: \2/'
echo ""

# Encontrar excepciones
echo "⚠️  Total de excepciones:"
echo "======================="
exceptions=$(grep -c "EXCEPTION CAUGHT" /tmp/test_full_output.log)
echo "  $exceptions excepciones detectadas"
echo ""

# Encontrar "Test failed"
echo "💥 Tests con 'Test failed':"
echo "=========================="
grep -B5 "Test failed" /tmp/test_full_output.log | grep "test/" | sort -u
echo ""

echo "✅ Análisis completo guardado en: /tmp/test_full_output.log"
