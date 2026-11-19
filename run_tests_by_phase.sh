#!/bin/bash

# Script para ejecutar tests por fase de corrección

set -e

PHASE=$1

if [ -z "$PHASE" ]; then
  echo "Uso: ./run_tests_by_phase.sh [fase]"
  echo ""
  echo "Fases disponibles:"
  echo "  1 - Errores Críticos (MaterialApp duplicado)"
  echo "  2 - Migración i18n (easy_localization → gen-l10n)"
  echo "  3 - Tests de Lógica (LocationManager, SearchScreen, etc.)"
  echo "  4 - Smoke Test"
  echo "  all - Todos los tests"
  echo ""
  exit 1
fi

echo "═══════════════════════════════════════════════════════════════════"
echo "🧪 Ejecutando Tests - Fase $PHASE"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

case $PHASE in
  1)
    echo "📋 FASE 1: Errores Críticos (MaterialApp duplicado)"
    echo "Archivos:"
    echo "  - test/main_test.dart"
    echo "  - test/main_additional_test.dart"
    echo ""

    flutter test test/main_test.dart test/main_additional_test.dart
    ;;

  2)
    echo "📋 FASE 2: Migración i18n"
    echo "Archivos:"
    echo "  - features/gossip/presentation/widgets/location_selector_test.dart"
    echo "  - features/gossip/presentation/widgets/city_autocomplete_test.dart"
    echo "  - features/gossip/presentation/widgets/city_autocomplete_optimized_test.dart"
    echo "  - features/gossip/presentation/widgets/report_gossip_dialog_test.dart"
    echo "  - features/gossip/presentation/widgets/submit_button_test.dart"
    echo "  - features/auth/domain/validators/auth_validator_security_test.dart"
    echo ""

    flutter test \
      test/features/gossip/presentation/widgets/location_selector_test.dart \
      test/features/gossip/presentation/widgets/city_autocomplete_test.dart \
      test/features/gossip/presentation/widgets/city_autocomplete_optimized_test.dart \
      test/features/gossip/presentation/widgets/report_gossip_dialog_test.dart \
      test/features/gossip/presentation/widgets/submit_button_test.dart \
      test/features/auth/domain/validators/auth_validator_security_test.dart
    ;;

  3)
    echo "📋 FASE 3: Tests de Lógica"
    echo "Archivos:"
    echo "  - features/location/presentation/managers/location_manager_test.dart"
    echo "  - features/search/presentation/screens/search_screen_test.dart"
    echo "  - features/home/presentation/screens/main_navigation_screen_test.dart"
    echo ""

    flutter test \
      test/features/location/presentation/managers/location_manager_test.dart \
      test/features/search/presentation/screens/search_screen_test.dart \
      test/features/home/presentation/screens/main_navigation_screen_test.dart
    ;;

  4)
    echo "📋 FASE 4: Smoke Test"
    echo "Archivo:"
    echo "  - test/widget_test.dart"
    echo ""

    flutter test test/widget_test.dart
    ;;

  all)
    echo "📋 Ejecutando TODOS los tests"
    echo ""

    flutter test
    ;;

  *)
    echo "❌ Fase inválida: $PHASE"
    echo "Usa: 1, 2, 3, 4, o all"
    exit 1
    ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✅ Tests de Fase $PHASE completados"
echo "═══════════════════════════════════════════════════════════════════"
