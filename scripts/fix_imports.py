#!/usr/bin/env python3
"""
Arregla imports del viejo AppLocalizations al nuevo
"""

import re
from pathlib import Path

def fix_imports(file_path: Path):
    """Reemplaza imports viejos por nuevos"""
    content = file_path.read_text()
    original = content

    # Reemplazar import del viejo AppLocalizations
    content = re.sub(
        r"import ['\"].*?/core/localization/app_localizations\.dart['\"];",
        "import 'package:chismes/core/l10n/l10n.dart';",
        content
    )

    # Agregar import si usa AppLocalizations pero no lo tiene
    if 'AppLocalizations' in content and "import 'package:chismes/core/l10n/l10n.dart';" not in content:
        # Buscar último import
        imports = list(re.finditer(r"^import .*?;$", content, re.MULTILINE))
        if imports:
            last_import = imports[-1]
            insert_pos = last_import.end()
            content = content[:insert_pos] + "\nimport 'package:chismes/core/l10n/l10n.dart';" + content[insert_pos:]

    if content != original:
        file_path.write_text(content)
        return True
    return False

# Fix all dart files
lib_dir = Path('lib')
count = 0

for dart_file in lib_dir.rglob('*.dart'):
    if '.g.dart' in str(dart_file) or 'app_localizations' in str(dart_file):
        continue

    if fix_imports(dart_file):
        count += 1
        print(f"✓ {dart_file}")

print(f"\n✅ {count} archivos actualizados")
