#!/bin/bash

# Script para monitorear progreso de cobertura de tests
# Uso: ./tools/coverage_progress.sh [feature]

set -e

COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'

echo -e "${COLOR_BOLD}${COLOR_CYAN}"
echo "================================================================================"
echo "                     ANÁLISIS DE COBERTURA DE TESTS"
echo "================================================================================"
echo -e "${COLOR_RESET}"

# Función para mostrar barra de progreso
progress_bar() {
    local coverage=$1
    local width=50
    local filled=$(printf "%.0f" $(echo "$coverage * $width / 100" | bc -l))
    local empty=$((width - filled))

    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %.1f%%\n" "$coverage"
}

# Generar coverage
echo -e "${COLOR_BLUE}📊 Generando reporte de cobertura...${COLOR_RESET}"
flutter test --coverage > /dev/null 2>&1 || {
    echo -e "${COLOR_RED}❌ Error al ejecutar tests${COLOR_RESET}"
    exit 1
}

# Analizar coverage global
echo ""
echo -e "${COLOR_BOLD}📈 COBERTURA GLOBAL${COLOR_RESET}"
echo "--------------------------------------------------------------------------------"
lcov --summary coverage/lcov.info 2>&1 | grep "lines" | while read -r line; do
    coverage=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | sed 's/%//')
    lines=$(echo "$line" | grep -oE '[0-9]+ of [0-9]+')
    echo -n "   Líneas: "
    progress_bar "$coverage"
    echo "   ($lines líneas)"
done

# Si se especifica una feature, analizar solo esa
FEATURE=${1:-}

if [ -n "$FEATURE" ]; then
    echo ""
    echo -e "${COLOR_BOLD}🎯 COBERTURA DE FEATURE: ${FEATURE}${COLOR_RESET}"
    echo "--------------------------------------------------------------------------------"

    lcov --extract coverage/lcov.info "lib/features/${FEATURE}/*" -o coverage/temp_${FEATURE}.info 2>/dev/null || {
        echo -e "${COLOR_RED}❌ Feature '${FEATURE}' no encontrada${COLOR_RESET}"
        exit 1
    }

    lcov --summary coverage/temp_${FEATURE}.info 2>&1 | grep "lines" | while read -r line; do
        coverage=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | sed 's/%//')
        lines=$(echo "$line" | grep -oE '[0-9]+ of [0-9]+')
        echo -n "   Líneas: "
        progress_bar "$coverage"
        echo "   ($lines líneas)"
    done

    rm -f coverage/temp_${FEATURE}.info
else
    # Analizar todas las features
    echo ""
    echo -e "${COLOR_BOLD}📊 COBERTURA POR FEATURE${COLOR_RESET}"
    echo "--------------------------------------------------------------------------------"

    for feature in gossip auth home profile location search; do
        if [ -d "lib/features/$feature" ]; then
            lcov --extract coverage/lcov.info "lib/features/${feature}/*" -o coverage/temp_${feature}.info 2>/dev/null

            if [ -s coverage/temp_${feature}.info ]; then
                coverage=$(lcov --summary coverage/temp_${feature}.info 2>&1 | grep "lines" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | sed 's/%//')
                lines=$(lcov --summary coverage/temp_${feature}.info 2>&1 | grep "lines" | grep -oE '[0-9]+ of [0-9]+')

                # Colorear según nivel
                if (( $(echo "$coverage >= 80" | bc -l) )); then
                    color=$COLOR_GREEN
                    status="✅"
                elif (( $(echo "$coverage >= 50" | bc -l) )); then
                    color=$COLOR_YELLOW
                    status="🟡"
                else
                    color=$COLOR_RED
                    status="🔴"
                fi

                echo -e "\n   ${status} ${COLOR_BOLD}${feature}${COLOR_RESET}"
                echo -n "      "
                echo -e "${color}$(progress_bar "$coverage")${COLOR_RESET}"
                echo "      ($lines líneas)"
            fi

            rm -f coverage/temp_${feature}.info
        fi
    done
fi

# Top archivos sin cobertura
echo ""
echo -e "${COLOR_BOLD}🔴 TOP 10 ARCHIVOS SIN COBERTURA${COLOR_RESET}"
echo "--------------------------------------------------------------------------------"

cat coverage/lcov.info | awk '
    /^SF:/ { file = substr($0, 4) }
    /^LH:/ { hit = substr($0, 4) }
    /^LF:/ {
        found = substr($0, 4)
        if (found > 0 && hit == 0) {
            # Extraer solo el nombre del archivo
            n = split(file, parts, "/")
            filename = parts[n]
            print found "\t" filename "\t" file
        }
    }
' | sort -rn | head -10 | nl | while read -r num lines filename fullpath; do
    echo "   ${num}. ${filename} (${lines} líneas)"
    echo "      ${fullpath}"
done

# Top archivos con baja cobertura
echo ""
echo -e "${COLOR_BOLD}🟡 TOP 10 ARCHIVOS CON BAJA COBERTURA (<50%)${COLOR_RESET}"
echo "--------------------------------------------------------------------------------"

cat coverage/lcov.info | awk '
    /^SF:/ { file = substr($0, 4) }
    /^LH:/ { hit = substr($0, 4) }
    /^LF:/ {
        found = substr($0, 4)
        if (found > 0 && hit > 0) {
            coverage = (hit / found) * 100
            if (coverage < 50) {
                n = split(file, parts, "/")
                filename = parts[n]
                printf "%.1f\t%d\t%d\t%s\t%s\n", coverage, hit, found, filename, file
            }
        }
    }
' | sort -n | head -10 | nl | while read -r num cov hit total filename fullpath; do
    echo "   ${num}. ${filename} (${cov}% - ${hit}/${total} líneas)"
done

# Progreso hacia meta de 90%
echo ""
echo -e "${COLOR_BOLD}🎯 PROGRESO HACIA META DE 90%${COLOR_RESET}"
echo "--------------------------------------------------------------------------------"

total_lines=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oE '[0-9]+ lines' | tail -1 | grep -oE '[0-9]+')
covered_lines=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oE '[0-9]+ of' | grep -oE '[0-9]+')
current_coverage=$(echo "scale=1; $covered_lines * 100 / $total_lines" | bc)
target_lines=$(echo "$total_lines * 0.90 / 1" | bc)
gap=$((target_lines - covered_lines))

echo "   Líneas totales:          $total_lines"
echo "   Líneas cubiertas:        $covered_lines (${current_coverage}%)"
echo "   Meta 90%:                $target_lines líneas"
echo ""
if [ $gap -gt 0 ]; then
    echo -e "   ${COLOR_YELLOW}Faltan: $gap líneas adicionales${COLOR_RESET}"

    # Calcular sesiones estimadas (asumiendo ~350 líneas por sesión)
    sessions=$(echo "scale=0; ($gap + 349) / 350" | bc)
    echo "   Sesiones estimadas: ~$sessions sesiones"
else
    echo -e "   ${COLOR_GREEN}✅ Meta alcanzada!${COLOR_RESET}"
fi

# Generar HTML report
echo ""
echo -e "${COLOR_BLUE}📄 Generando reporte HTML...${COLOR_RESET}"
genhtml coverage/lcov.info -o coverage/html > /dev/null 2>&1

echo -e "${COLOR_GREEN}✅ Reporte HTML generado en: coverage/html/index.html${COLOR_RESET}"
echo ""
echo -e "${COLOR_CYAN}Comandos útiles:${COLOR_RESET}"
echo "   open coverage/html/index.html          # Ver reporte HTML"
echo "   ./tools/coverage_progress.sh gossip    # Ver cobertura de feature específica"
echo "   flutter test test/features/home        # Ejecutar tests de una feature"

echo ""
echo "================================================================================"
