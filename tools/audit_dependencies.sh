#!/bin/bash

################################################################################
# Dependency Rule Audit Script - Chismes App
################################################################################
#
# Verifica que se cumpla la Dependency Rule de Clean Architecture:
#
# REGLAS:
#   ✅ Presentation → Domain (PERMITIDO)
#   ✅ Data → Domain (PERMITIDO)
#   ✅ Cualquiera → Core (PERMITIDO)
#   ❌ Domain → Presentation (VIOLACIÓN)
#   ❌ Domain → Data (VIOLACIÓN)
#   ❌ Presentation → Data (VIOLACIÓN - debe pasar por Domain)
#
# USAGE:
#   ./tools/audit_dependencies.sh
#   ./tools/audit_dependencies.sh --verbose
#   ./tools/audit_dependencies.sh --json
#
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
VIOLATIONS=0
WARNINGS=0
TOTAL_FILES=0

# Options
VERBOSE=false
JSON_OUTPUT=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--verbose] [--json] [--help]"
      echo ""
      echo "Options:"
      echo "  --verbose    Show all checked files"
      echo "  --json       Output results as JSON"
      echo "  --help       Show this help message"
      exit 0
      ;;
  esac
done

# Check if we're in project root
if [ ! -d "lib" ]; then
  echo -e "${RED}Error: Must run from project root (where lib/ exists)${NC}"
  exit 1
fi

# JSON output structure
if [ "$JSON_OUTPUT" = true ]; then
  echo '{'
  echo '  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",'
  echo '  "violations": ['
fi

# Header
if [ "$JSON_OUTPUT" = false ]; then
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}   Dependency Rule Audit - Chismes App${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
fi

################################################################################
# FUNCTION: Check file for violations
################################################################################
check_file() {
  local file=$1
  local layer=""
  local feature=""

  # Determine layer and feature
  if [[ $file =~ lib/features/([^/]+)/domain/ ]]; then
    layer="domain"
    feature="${BASH_REMATCH[1]}"
  elif [[ $file =~ lib/features/([^/]+)/presentation/ ]]; then
    layer="presentation"
    feature="${BASH_REMATCH[1]}"
  elif [[ $file =~ lib/features/([^/]+)/data/ ]]; then
    layer="data"
    feature="${BASH_REMATCH[1]}"
  elif [[ $file =~ lib/core/ ]]; then
    layer="core"
    feature="core"
  else
    return 0  # Skip files not in feature structure
  fi

  TOTAL_FILES=$((TOTAL_FILES + 1))

  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Checking:${NC} $file (layer: $layer, feature: $feature)"
  fi

  # Read imports from file
  while IFS= read -r line; do
    # Skip if not an import
    [[ $line =~ ^import ]] || continue

    # Extract import path
    import_path=$(echo "$line" | sed -n "s/^import ['\"]\\([^'\"]*\\)['\"].*/\\1/p")

    # Skip package imports (dart:, package:)
    [[ $import_path =~ ^(dart:|package:) ]] && continue

    # RULE 1: Domain cannot import from Presentation
    if [ "$layer" = "domain" ]; then
      if [[ $import_path =~ /presentation/ ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        if [ "$JSON_OUTPUT" = true ]; then
          [ $VIOLATIONS -gt 1 ] && echo ','
          echo '    {'
          echo '      "type": "CRITICAL",'
          echo '      "rule": "Domain → Presentation",'
          echo '      "file": "'$file'",'
          echo '      "import": "'$import_path'",'
          echo '      "message": "Domain layer cannot depend on Presentation layer"'
          echo -n '    }'
        else
          echo -e "${RED}❌ VIOLATION:${NC} Domain → Presentation"
          echo -e "   File:   $file"
          echo -e "   Import: $import_path"
          echo ""
        fi
      fi

      # RULE 2: Domain cannot import from Data
      if [[ $import_path =~ /data/ ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        if [ "$JSON_OUTPUT" = true ]; then
          [ $VIOLATIONS -gt 1 ] && echo ','
          echo '    {'
          echo '      "type": "CRITICAL",'
          echo '      "rule": "Domain → Data",'
          echo '      "file": "'$file'",'
          echo '      "import": "'$import_path'",'
          echo '      "message": "Domain layer cannot depend on Data layer"'
          echo -n '    }'
        else
          echo -e "${RED}❌ VIOLATION:${NC} Domain → Data"
          echo -e "   File:   $file"
          echo -e "   Import: $import_path"
          echo ""
        fi
      fi
    fi

    # RULE 3: Presentation cannot import from Data (should go through Domain)
    if [ "$layer" = "presentation" ]; then
      if [[ $import_path =~ /data/ ]]; then
        # Exception: Can import models for display (DTO), but not repositories/datasources
        if [[ $import_path =~ /(repositories|datasources)/ ]]; then
          VIOLATIONS=$((VIOLATIONS + 1))
          if [ "$JSON_OUTPUT" = true ]; then
            [ $VIOLATIONS -gt 1 ] && echo ','
            echo '    {'
            echo '      "type": "CRITICAL",'
            echo '      "rule": "Presentation → Data",'
            echo '      "file": "'$file'",'
            echo '      "import": "'$import_path'",'
            echo '      "message": "Presentation should depend on Domain interfaces, not Data implementations"'
            echo -n '    }'
          else
            echo -e "${RED}❌ VIOLATION:${NC} Presentation → Data (Repository/DataSource)"
            echo -e "   File:   $file"
            echo -e "   Import: $import_path"
            echo -e "   ${YELLOW}Fix:${NC} Use Domain interface instead"
            echo ""
          fi
        elif [[ $import_path =~ /models/ ]]; then
          # Warning: Presentation importing Models is a code smell
          WARNINGS=$((WARNINGS + 1))
          if [ "$JSON_OUTPUT" = false ]; then
            echo -e "${YELLOW}⚠️  WARNING:${NC} Presentation → Data Model"
            echo -e "   File:   $file"
            echo -e "   Import: $import_path"
            echo -e "   ${YELLOW}Note:${NC} Presentation should use Domain Entities, not Data Models"
            echo ""
          fi
        fi
      fi
    fi

    # RULE 4: Features should not depend on each other
    if [[ $import_path =~ lib/features/([^/]+)/ ]]; then
      import_feature="${BASH_REMATCH[1]}"
      if [ "$feature" != "core" ] && [ "$feature" != "$import_feature" ]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        if [ "$JSON_OUTPUT" = true ]; then
          [ $VIOLATIONS -gt 1 ] && echo ','
          echo '    {'
          echo '      "type": "CRITICAL",'
          echo '      "rule": "Feature Independence",'
          echo '      "file": "'$file'",'
          echo '      "import": "'$import_path'",'
          echo '      "message": "Feature '$feature' cannot depend on feature '$import_feature'. Use core/ for shared code"'
          echo -n '    }'
        else
          echo -e "${RED}❌ VIOLATION:${NC} Feature Dependency"
          echo -e "   File:   $file"
          echo -e "   Import: $import_path"
          echo -e "   ${YELLOW}Fix:${NC} Move shared code to core/"
          echo ""
        fi
      fi
    fi

  done < "$file"
}

################################################################################
# MAIN: Scan all Dart files
################################################################################

# Find all .dart files (exclude generated files)
while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find lib/features -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" -print0)

# Check core files too
if [ -d "lib/core" ]; then
  while IFS= read -r -d '' file; do
    check_file "$file"
  done < <(find lib/core -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" -print0)
fi

################################################################################
# SUMMARY
################################################################################

if [ "$JSON_OUTPUT" = true ]; then
  echo ''
  echo '  ],'
  echo '  "summary": {'
  echo '    "totalFiles": '$TOTAL_FILES','
  echo '    "violations": '$VIOLATIONS','
  echo '    "warnings": '$WARNINGS','
  echo '    "status": "'$([ $VIOLATIONS -eq 0 ] && echo "PASS" || echo "FAIL")'"'
  echo '  }'
  echo '}'
else
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}   Summary${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "Files checked:     $TOTAL_FILES"
  echo -e "Violations:        ${RED}$VIOLATIONS${NC}"
  echo -e "Warnings:          ${YELLOW}$WARNINGS${NC}"
  echo ""

  if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✅ PASS: No dependency violations found!${NC}"
    echo ""
    echo -e "${GREEN}Clean Architecture Dependency Rule: 100% compliant${NC}"
    echo -e "${GREEN}Score: 10/10${NC}"
  else
    echo -e "${RED}❌ FAIL: $VIOLATIONS dependency violations found${NC}"
    echo ""
    echo -e "${YELLOW}Fix these violations to maintain Clean Architecture${NC}"
    echo -e "${YELLOW}Score: 7-8/10 (violations reduce score)${NC}"
  fi

  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
  echo ""
fi

# Exit with error if violations found
exit $VIOLATIONS
