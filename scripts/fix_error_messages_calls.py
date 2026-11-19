#!/usr/bin/env python3
"""
Arregla llamadas a ErrorMessages.getMessage() para agregar context donde sea necesario
"""

import re
from pathlib import Path

def fix_error_messages_in_ui(file_path: Path):
    """Arregla ErrorMessages en archivos de UI (screens/widgets)"""
    content = file_path.read_text()
    original = content

    # Pattern: ErrorMessages.getMessage(xxx) → ErrorMessages.getMessage(context, xxx)
    # Solo si NO está en un controller/repository/service
    if '/presentation/screens/' in str(file_path) or '/presentation/widgets/' in str(file_path):
        content = re.sub(
            r'ErrorMessages\.getMessage\(([^)]+)\)',
            r'ErrorMessages.getMessage(context, \1)',
            content
        )
        content = re.sub(
            r'ErrorMessages\.getTitle\(([^)]+)\)',
            r'ErrorMessages.getTitle(context, \1)',
            content
        )

    if content != original:
        file_path.write_text(content)
        return True
    return False

def fix_error_messages_in_controllers(file_path: Path):
    """Arregla ErrorMessages en controllers/services (usa versión sin context)"""
    content = file_path.read_text()
    original = content

    # En controllers/services/repositories, usar getMessageEnglish para logs
    if any(x in str(file_path) for x in ['/controllers/', '/services/', '/repositories/', '/state/']):
        content = re.sub(
            r'ErrorMessages\.getMessage\(([^)]+)\)',
            r'ErrorMessages.getMessageEnglish(\1)',
            content
        )

    if content != original:
        file_path.write_text(content)
        return True
    return False

# Buscar archivos
lib_dir = Path('lib')
ui_files_fixed = 0
controller_files_fixed = 0

for dart_file in lib_dir.rglob('*.dart'):
    if '.g.dart' in str(dart_file):
        continue

    if fix_error_messages_in_ui(dart_file):
        ui_files_fixed += 1
        print(f"✓ UI: {dart_file}")
    elif fix_error_messages_in_controllers(dart_file):
        controller_files_fixed += 1
        print(f"✓ Controller: {dart_file}")

print(f"\n✅ {ui_files_fixed} archivos UI actualizados")
print(f"✅ {controller_files_fixed} archivos de lógica actualizados")
