#!/usr/bin/env python3
"""
Migra código de easy_localization (.tr()) a gen-l10n (context.l10n)

Características:
- Convierte 'key.name'.tr() → context.l10n.keyName
- Convierte 'key'.tr(namedArgs: {...}) → context.l10n.key(value)
- Maneja imports: elimina easy_localization, agrega l10n.dart
- Preserva formato y comentarios

Uso:
    python3 scripts/migrate_tr_to_l10n.py [--dry-run] [--file path]
"""

import re
import argparse
from pathlib import Path
from typing import List, Tuple, Dict


def dot_case_to_camel_case(dot_key: str) -> str:
    """
    Convierte dot.case a camelCase

    Ejemplos:
        auth.login.title → authLoginTitle
        gossip.add_screen.submit_button → gossipAddScreenSubmitButton
    """
    parts = dot_key.replace('_', '.').split('.')
    return parts[0] + ''.join(word.capitalize() for word in parts[1:])


def extract_tr_call_simple(match: re.Match) -> str:
    """
    Convierte 'key'.tr() → context.l10n.keyName

    Input: Match de 'something.key.name'.tr()
    Output: context.l10n.somethingKeyName
    """
    key = match.group(1)
    camel_key = dot_case_to_camel_case(key)
    return f"context.l10n.{camel_key}"


def extract_tr_call_with_args(match: re.Match) -> str:
    """
    Convierte 'key'.tr(namedArgs: {'param': value}) → context.l10n.key(value)

    Input: 'home.popular.in_city'.tr(namedArgs: {'city': cityName})
    Output: context.l10n.homePopularInCity(cityName)
    """
    key = match.group(1)
    args_str = match.group(2)

    camel_key = dot_case_to_camel_case(key)

    # Extraer el valor del argumento
    # Patrón: {'param': value} → value
    value_match = re.search(r"'(\w+)':\s*([^}]+)", args_str)
    if value_match:
        value = value_match.group(2).strip()
        return f"context.l10n.{camel_key}({value})"
    else:
        # Fallback si no se puede extraer
        return f"context.l10n.{camel_key} /* TODO: fix args: {args_str} */"


def migrate_file_content(content: str) -> Tuple[str, Dict[str, int]]:
    """
    Migra el contenido de un archivo Dart

    Returns:
        (new_content, stats)
    """
    stats = {
        'tr_simple': 0,
        'tr_with_args': 0,
        'imports_removed': 0,
        'imports_added': 0,
    }

    original = content

    # 1. Reemplazar .tr() con argumentos
    def replace_tr_with_args(match):
        stats['tr_with_args'] += 1
        return extract_tr_call_with_args(match)

    content = re.sub(
        r"'([^']+)'\.tr\(namedArgs:\s*\{([^}]+)\}\)",
        replace_tr_with_args,
        content
    )

    # 2. Reemplazar .tr() simples
    def replace_tr_simple(match):
        stats['tr_simple'] += 1
        return extract_tr_call_simple(match)

    content = re.sub(
        r"'([a-z_\.]+)'\.tr\(\)",
        replace_tr_simple,
        content
    )

    # 3. Remover import de easy_localization
    if "import 'package:easy_localization/easy_localization.dart';" in content:
        content = content.replace(
            "import 'package:easy_localization/easy_localization.dart';",
            ""
        )
        stats['imports_removed'] += 1

    # 4. Agregar import de l10n si hubo cambios y no existe
    if stats['tr_simple'] + stats['tr_with_args'] > 0:
        if "import" in content and "import '../../core/l10n/l10n.dart';" not in content:
            # Encontrar la última línea de import
            imports = re.findall(r"^import .*?;$", content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                # Determinar la ruta relativa correcta basada en la ubicación del archivo
                # Por ahora usar una ruta genérica, el IDE la ajustará
                l10n_import = "import 'package:chismes/core/l10n/l10n.dart';"
                content = content.replace(
                    last_import,
                    f"{last_import}\n{l10n_import}"
                )
                stats['imports_added'] += 1

    # 5. Limpiar líneas vacías extras
    content = re.sub(r'\n\n\n+', '\n\n', content)

    return content, stats


def migrate_file(file_path: Path, dry_run: bool = False) -> Tuple[bool, Dict[str, int]]:
    """
    Migra un archivo Dart

    Returns:
        (changed, stats)
    """
    try:
        content = file_path.read_text(encoding='utf-8')
        new_content, stats = migrate_file_content(content)

        changed = content != new_content

        if changed and not dry_run:
            file_path.write_text(new_content, encoding='utf-8')

        return changed, stats
    except Exception as e:
        print(f"❌ Error procesando {file_path}: {e}")
        return False, {}


def main():
    parser = argparse.ArgumentParser(
        description='Migra código de easy_localization a gen-l10n'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Mostrar cambios sin aplicarlos'
    )
    parser.add_argument(
        '--file',
        type=str,
        help='Migrar un archivo específico (opcional)'
    )
    args = parser.parse_args()

    print("=" * 70)
    print("🔄 Migración: easy_localization → gen-l10n")
    print("=" * 70)

    if args.dry_run:
        print("⚠️  Modo DRY RUN: No se aplicarán cambios\n")

    project_root = Path(__file__).parent.parent
    lib_dir = project_root / "lib"

    # Buscar archivos Dart
    if args.file:
        dart_files = [Path(args.file)]
    else:
        dart_files = list(lib_dir.rglob("*.dart"))

    print(f"📄 Procesando {len(dart_files)} archivos...\n")

    total_stats = {
        'files_changed': 0,
        'tr_simple': 0,
        'tr_with_args': 0,
        'imports_removed': 0,
        'imports_added': 0,
    }

    for dart_file in dart_files:
        # Ignorar archivos generados
        if '.g.dart' in str(dart_file) or '.freezed.dart' in str(dart_file):
            continue

        # Ignorar archivos de l10n generados
        if 'app_localizations' in str(dart_file):
            continue

        changed, stats = migrate_file(dart_file, dry_run=args.dry_run)

        if changed:
            total_stats['files_changed'] += 1
            total_stats['tr_simple'] += stats.get('tr_simple', 0)
            total_stats['tr_with_args'] += stats.get('tr_with_args', 0)
            total_stats['imports_removed'] += stats.get('imports_removed', 0)
            total_stats['imports_added'] += stats.get('imports_added', 0)

            emoji = "🔍" if args.dry_run else "✓"
            print(f"{emoji} {dart_file.relative_to(project_root)}")
            if stats.get('tr_simple', 0) > 0:
                print(f"    - {stats['tr_simple']} .tr() simples")
            if stats.get('tr_with_args', 0) > 0:
                print(f"    - {stats['tr_with_args']} .tr() con argumentos")

    print("\n" + "=" * 70)
    print("📊 Resumen")
    print("=" * 70)
    print(f"Archivos modificados: {total_stats['files_changed']}")
    print(f".tr() simples:        {total_stats['tr_simple']}")
    print(f".tr() con args:       {total_stats['tr_with_args']}")
    print(f"Imports removidos:    {total_stats['imports_removed']}")
    print(f"Imports agregados:    {total_stats['imports_added']}")

    if args.dry_run:
        print("\n⚠️  DRY RUN: ejecuta sin --dry-run para aplicar cambios")
    else:
        print("\n✅ Migración completada")
        print("\n📋 Próximos pasos:")
        print("   1. Ejecutar: flutter analyze")
        print("   2. Ajustar imports si es necesario")
        print("   3. Ejecutar tests: flutter test")


if __name__ == "__main__":
    main()
