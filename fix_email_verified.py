#!/usr/bin/env python3
"""
Script para agregar emailVerified: true a constructores de User/UserModel
"""
import re
import sys
from pathlib import Path

def fix_user_constructors(content):
    """Agrega emailVerified: true a constructores User( o UserModel( si no lo tienen"""

    # Patrón para encontrar User( o UserModel( con sus argumentos
    # Busca casos donde hay 'email:' pero NO hay 'emailVerified:'
    pattern = r'(User(?:Model)?\s*\(\s*(?:[^)]*\n\s*)*?)(\s*email:\s*[^,\n]+,)(\s*(?:[^)]*\n\s*)*?\))'

    def replace_func(match):
        before = match.group(1)
        email_line = match.group(2)
        after = match.group(3)

        # Verificar si ya tiene emailVerified
        full_match = before + email_line + after
        if 'emailVerified:' in full_match:
            return full_match  # Ya lo tiene, no cambiar

        # Extraer la indentación de la línea email:
        indent_match = re.search(r'\n(\s*)email:', email_line)
        if indent_match:
            indent = indent_match.group(1)
        else:
            indent = '          '  # Indentación por defecto

        # Insertar emailVerified justo después de email
        new_content = before + email_line + f'\n{indent}emailVerified: true,' + after
        return new_content

    new_content = re.sub(pattern, replace_func, content, flags=re.MULTILINE | re.DOTALL)

    return new_content

def main():
    # Archivos a arreglar
    test_dir = Path('test/features/auth')
    test_files = list(test_dir.rglob('*_test.dart'))

    fixed_count = 0
    for test_file in test_files:
        try:
            content = test_file.read_text()
            original_content = content

            # Aplicar fix
            new_content = fix_user_constructors(content)

            if new_content != original_content:
                test_file.write_text(new_content)
                print(f"✅ Fixed: {test_file}")
                fixed_count += 1
            else:
                print(f"⏭️  Skipped: {test_file} (ya está correcto)")
        except Exception as e:
            print(f"❌ Error en {test_file}: {e}")

    print(f"\n🎉 Arreglados {fixed_count} archivos")

if __name__ == '__main__':
    main()
