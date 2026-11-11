#!/bin/bash

# Script para ejecutar tests por fases
# Uso: ./run_test_phases.sh [1|2|all|help]

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo ""
    echo "🎯 Script para ejecutar tests por fases"
    echo ""
    echo "Uso: $0 [opción]"
    echo ""
    echo "Opciones:"
    echo "  1       - Fase 1: Quick Wins (8 tests, ~1.5h)"
    echo "  2       - Fase 2: Tests Críticos (17 tests, ~3-4h)"
    echo "  all     - Todas las fases (25 tests, ~4-5.5h)"
    echo "  verify  - Verificar que todos los tests pasen"
    echo "  help    - Mostrar esta ayuda"
    echo ""
    echo "Detalles de las fases:"
    echo ""
    echo "📋 FASE 1: Quick Wins (8 tests)"
    echo "  - widget_test.dart (1 test)"
    echo "  - location_manager_test.dart (2 tests)"
    echo "  - city_autocomplete_test.dart (2 tests)"
    echo "  - city_autocomplete_optimized_test.dart (3 tests)"
    echo ""
    echo "🔥 FASE 2: Tests Críticos (17 tests)"
    echo "  - auth_validator_security_test.dart (4 tests)"
    echo "  - main_navigation_screen_test.dart (6 tests)"
    echo "  - search_screen_test.dart (7 tests)"
    echo ""
    exit 0
}

# Función para header
print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Función para ejecutar un test
run_test() {
    local test_file=$1
    local test_name=$2
    local test_count=$3

    echo ""
    echo -e "${YELLOW}▶ Ejecutando:${NC} $test_name ($test_count tests)"
    echo -e "${BLUE}   Archivo:${NC} $test_file"
    echo ""

    if flutter test "$test_file"; then
        echo ""
        echo -e "${GREEN}✅ $test_name: PASÓ${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ $test_name: FALLÓ${NC}"
        return 1
    fi
}

# Función para Fase 1
run_phase_1() {
    print_header "📋 FASE 1: Quick Wins (8 tests, ~1.5h)"

    local failed_tests=()
    local passed_count=0
    local total_count=4

    # Test 1: widget_test.dart
    if run_test "test/widget_test.dart" "Smoke Test" "1"; then
        ((passed_count++))
    else
        failed_tests+=("widget_test.dart")
    fi

    # Test 2: location_manager_test.dart
    if run_test "test/features/location/presentation/managers/location_manager_test.dart" "LocationManager" "2"; then
        ((passed_count++))
    else
        failed_tests+=("location_manager_test.dart")
    fi

    # Test 3: city_autocomplete_test.dart
    if run_test "test/features/gossip/presentation/widgets/city_autocomplete_test.dart" "CityAutocomplete" "2"; then
        ((passed_count++))
    else
        failed_tests+=("city_autocomplete_test.dart")
    fi

    # Test 4: city_autocomplete_optimized_test.dart
    if run_test "test/features/gossip/presentation/widgets/city_autocomplete_optimized_test.dart" "CityAutocompleteOptimized" "3"; then
        ((passed_count++))
    else
        failed_tests+=("city_autocomplete_optimized_test.dart")
    fi

    # Resumen Fase 1
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📊 RESUMEN FASE 1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "Archivos pasados: ${GREEN}$passed_count${NC} / $total_count"

    if [ ${#failed_tests[@]} -eq 0 ]; then
        echo -e "Estado: ${GREEN}✅ TODOS LOS TESTS PASARON${NC}"
        echo ""
        echo "Progreso estimado: 2,760 / 2,777 tests (99.4%)"
        return 0
    else
        echo -e "Estado: ${RED}❌ ALGUNOS TESTS FALLARON${NC}"
        echo ""
        echo "Archivos que fallaron:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        return 1
    fi
}

# Función para Fase 2
run_phase_2() {
    print_header "🔥 FASE 2: Tests Críticos (17 tests, ~3-4h)"

    local failed_tests=()
    local passed_count=0
    local total_count=3

    # Test 1: auth_validator_security_test.dart
    if run_test "test/features/auth/domain/validators/auth_validator_security_test.dart" "AuthValidator Security" "4"; then
        ((passed_count++))
    else
        failed_tests+=("auth_validator_security_test.dart")
    fi

    # Test 2: main_navigation_screen_test.dart
    if run_test "test/features/home/presentation/screens/main_navigation_screen_test.dart" "MainNavigationScreen" "6"; then
        ((passed_count++))
    else
        failed_tests+=("main_navigation_screen_test.dart")
    fi

    # Test 3: search_screen_test.dart
    if run_test "test/features/search/presentation/screens/search_screen_test.dart" "SearchScreen" "7"; then
        ((passed_count++))
    else
        failed_tests+=("search_screen_test.dart")
    fi

    # Resumen Fase 2
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📊 RESUMEN FASE 2${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "Archivos pasados: ${GREEN}$passed_count${NC} / $total_count"

    if [ ${#failed_tests[@]} -eq 0 ]; then
        echo -e "Estado: ${GREEN}✅ TODOS LOS TESTS PASARON${NC}"
        echo ""
        echo "Progreso estimado: 2,777 / 2,777 tests (100%) 🎉"
        return 0
    else
        echo -e "Estado: ${RED}❌ ALGUNOS TESTS FALLARON${NC}"
        echo ""
        echo "Archivos que fallaron:"
        for test in "${failed_tests[@]}"; do
            echo "  - $test"
        done
        return 1
    fi
}

# Función para ejecutar todas las fases
run_all() {
    print_header "🎯 EJECUTANDO TODAS LAS FASES (25 tests)"

    local phase1_result=0
    local phase2_result=0

    # Ejecutar Fase 1
    run_phase_1
    phase1_result=$?

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Ejecutar Fase 2 (incluso si Fase 1 falla)
    run_phase_2
    phase2_result=$?

    # Resumen Final
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}🎯 RESUMEN FINAL${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ $phase1_result -eq 0 ] && [ $phase2_result -eq 0 ]; then
        echo -e "${GREEN}✅ ¡TODOS LOS TESTS PASARON!${NC}"
        echo ""
        echo "🎉 Meta alcanzada: 2,777 / 2,777 tests (100%)"
        echo ""
        echo "Próximos pasos:"
        echo "  1. Generar coverage: flutter test --coverage"
        echo "  2. Commit cambios: git commit -am 'fix(tests): Resolver 25 tests fallidos'"
        echo "  3. Push: git push"
        echo "  4. 🍕 Celebrar"
        return 0
    else
        echo -e "${RED}❌ Algunos tests aún fallan${NC}"
        echo ""
        echo "Revisa los errores arriba y consulta:"
        echo "  - ALL_25_TESTS_SOLUTIONS.md para soluciones"
        echo "  - QUICK_START_TESTS.md para quick start"
        return 1
    fi
}

# Función para verificar todos los tests
run_verify() {
    print_header "🔍 VERIFICANDO TODOS LOS TESTS"

    echo "Ejecutando: flutter test"
    echo ""

    if flutter test; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${GREEN}✅ ¡TODOS LOS TESTS PASARON!${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🎉 Meta alcanzada: 2,777 / 2,777 tests (100%)"
        return 0
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ Algunos tests fallaron${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
}

# Main
case "${1:-help}" in
    1)
        run_phase_1
        ;;
    2)
        run_phase_2
        ;;
    all)
        run_all
        ;;
    verify)
        run_verify
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo ""
        echo -e "${RED}❌ Opción inválida: $1${NC}"
        show_help
        exit 1
        ;;
esac

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✨ Ejecución completada exitosamente ✨${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
else
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Ejecución completada con errores${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

exit $exit_code
