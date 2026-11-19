#!/usr/bin/env python3
"""
Convierte archivos JSON de easy_localization a formato ARB de Flutter gen-l10n

Características:
- Aplana estructura anidada (gossip.add_screen.title → gossipAddScreenTitle)
- Detecta placeholders {param} y genera metadata
- Preserva descripción y contexto para traductores
- Genera archivos app_es.arb y app_en.arb

Uso:
    python3 scripts/json_to_arb.py
"""

import json
import re
from pathlib import Path
from typing import Dict, Any, List, Tuple


def flatten_json(data: Dict[str, Any], prefix: str = '') -> Dict[str, str]:
    """
    Aplana estructura JSON anidada a flat dict

    Ejemplo:
        {"auth": {"login": {"title": "Sign In"}}}
        → {"auth.login.title": "Sign In"}
    """
    result = {}
    for key, value in data.items():
        full_key = f"{prefix}.{key}" if prefix else key

        if isinstance(value, dict):
            result.update(flatten_json(value, full_key))
        elif isinstance(value, str):
            result[full_key] = value
        else:
            print(f"⚠️  Ignorando tipo no soportado: {full_key} = {type(value)}")

    return result


def dot_case_to_camel_case(dot_key: str) -> str:
    """
    Convierte dot.case a camelCase

    Ejemplos:
        auth.login.title → authLoginTitle
        gossip.add_screen.submit_button → gossipAddScreenSubmitButton
    """
    parts = dot_key.replace('_', '.').split('.')
    return parts[0] + ''.join(word.capitalize() for word in parts[1:])


def extract_placeholders(text: str) -> List[str]:
    """
    Extrae placeholders {param} del texto

    Ejemplo:
        "Welcome, {userName}" → ["userName"]
        "Popular in {city}" → ["city"]
    """
    return re.findall(r'\{(\w+)\}', text)


def create_arb_entry(key: str, value: str) -> Tuple[str, Any]:
    """
    Crea entrada ARB con metadata si tiene placeholders

    Returns:
        (camelCaseKey, value) o (camelCaseKey, value) + (@camelCaseKey, metadata)
    """
    camel_key = dot_case_to_camel_case(key)
    placeholders = extract_placeholders(value)

    entries = {camel_key: value}

    if placeholders:
        metadata = {
            "description": f"Translated from: {key}",
            "placeholders": {}
        }

        for placeholder in placeholders:
            metadata["placeholders"][placeholder] = {
                "type": "String",
                "example": placeholder.upper()
            }

        entries[f"@{camel_key}"] = metadata

    return entries


def json_to_arb(json_path: Path, arb_path: Path, locale: str):
    """
    Convierte JSON de easy_localization a ARB de gen-l10n
    """
    print(f"\n📄 Convirtiendo: {json_path.name} → {arb_path.name}")

    # Cargar JSON
    with open(json_path, 'r', encoding='utf-8') as f:
        json_data = json.load(f)

    # Aplanar estructura
    flat_data = flatten_json(json_data)
    print(f"   ✓ {len(flat_data)} keys encontradas")

    # Crear ARB
    arb_data = {
        "@@locale": locale,
        "@@context": "chismes_app"
    }

    # Convertir cada key
    placeholders_count = 0
    for dot_key, value in sorted(flat_data.items()):
        entries = create_arb_entry(dot_key, value)
        arb_data.update(entries)

        if len(entries) > 1:  # Tiene metadata
            placeholders_count += 1

    # Guardar ARB
    with open(arb_path, 'w', encoding='utf-8') as f:
        json.dump(arb_data, f, ensure_ascii=False, indent=2)

    print(f"   ✓ {len(arb_data)} entries generadas")
    print(f"   ✓ {placeholders_count} keys con placeholders")
    print(f"   ✓ Guardado en: {arb_path}")


def main():
    """Script principal"""
    print("=" * 70)
    print("🔄 JSON → ARB Converter")
    print("=" * 70)

    # Paths
    project_root = Path(__file__).parent.parent
    translations_dir = project_root / "assets" / "translations"
    l10n_dir = project_root / "lib" / "l10n"

    # Verificar directorios
    if not translations_dir.exists():
        print(f"❌ Error: {translations_dir} no existe")
        return

    l10n_dir.mkdir(exist_ok=True)

    # Convertir ambos idiomas
    conversions = [
        (translations_dir / "es.json", l10n_dir / "app_es.arb", "es"),
        (translations_dir / "en.json", l10n_dir / "app_en.arb", "en"),
    ]

    for json_path, arb_path, locale in conversions:
        if not json_path.exists():
            print(f"⚠️  Saltando: {json_path} no existe")
            continue

        json_to_arb(json_path, arb_path, locale)

    print("\n" + "=" * 70)
    print("✅ Conversión completada")
    print("=" * 70)
    print("\n📋 Próximos pasos:")
    print("   1. Revisar archivos generados en lib/l10n/")
    print("   2. Ejecutar: flutter gen-l10n")
    print("   3. Verificar: .dart_tool/flutter_gen/gen_l10n/")


if __name__ == "__main__":
    main()
