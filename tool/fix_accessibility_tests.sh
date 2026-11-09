#!/bin/bash
# Script para arreglar tests de accesibilidad que usan CompactLocationSelector
# sin inicializar EasyLocalization

echo "🔧 Arreglando tests de accesibilidad..."

# Archivos a arreglar
FILES=(
  "test/accessibility/narrow_width_test.dart"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✓ Procesando $file"

    # Agregar import si no existe
    if ! grep -q "import '../helpers/widget_test_wrapper.dart';" "$file"; then
      # Buscar la última línea de imports y agregar después
      sed -i '' "/^import/a\\
import '../helpers/widget_test_wrapper.dart';\\
" "$file"
    fi

  else
    echo "  ⚠️  Archivo no encontrado: $file"
  fi
done

echo "✅ Script completado"
echo ""
echo "⚠️  NOTA: Este script solo agrega el import."
echo "   Los tests individuales deben actualizarse manualmente para usar pumpWidgetWithI18n()"
