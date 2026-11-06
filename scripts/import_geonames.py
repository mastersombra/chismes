#!/usr/bin/env python3
"""
Script para importar datos de GeoNames a Supabase

Uso:
    python import_geonames.py --country CO --file /path/to/CO.txt --min-population 500

Descargar datos de GeoNames:
    wget https://download.geonames.org/export/dump/CO.zip
    unzip CO.zip

Requiere:
    pip install requests python-dotenv
"""

import os
import sys
import argparse
import csv
import json
from pathlib import Path
from dotenv import load_dotenv
import requests

# Cargar variables de entorno
# Intenta .env.local primero (para scripts admin), luego .env (fallback)
load_dotenv('.env.local')  # Service role para scripts
if not os.getenv('SUPABASE_SERVICE_ROLE_KEY'):
    load_dotenv()  # Fallback a .env

# Configuración de Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # Service role para bypass RLS

# Feature codes de GeoNames
# https://www.geonames.org/export/codes.html
CITY_FEATURE_CODES = {
    'PPLC',  # Capital de país
    'PPLA',  # Capital de región/estado
    'PPLA2', # Capital de provincia
    'PPLA3', # Capital de distrito
    'PPLA4', # Capital de municipio
    'PPL',   # Población/ciudad
    'PPLX',  # Sección de población
}

def supabase_request(endpoint: str, method: str = 'GET', data: dict = None, params: dict = None):
    """
    Hace una petición a la API REST de Supabase
    """
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"

    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
    }

    if method == 'POST':
        headers['Prefer'] = 'resolution=merge-duplicates,return=minimal'

    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, params=params)
        elif method == 'POST':
            response = requests.post(url, headers=headers, json=data)

        response.raise_for_status()

        if method == 'GET':
            return response.json()
        else:
            return True

    except requests.exceptions.RequestException as e:
        print(f"❌ Error en request: {e}")
        if hasattr(e.response, 'text'):
            print(f"   Detalle: {e.response.text}")
        raise

def parse_geonames_file(file_path: str, min_population: int = 0):
    """
    Parsea archivo de GeoNames (formato TSV)

    Columnas:
    0:  geonameid
    1:  name
    2:  asciiname
    3:  alternatenames
    4:  latitude
    5:  longitude
    6:  feature class
    7:  feature code
    8:  country code
    9:  cc2
    10: admin1 code
    11: admin2 code
    12: admin3 code
    13: admin4 code
    14: population
    15: elevation
    16: dem
    17: timezone
    18: modification date
    """
    cities = []

    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter='\t')

        for row in reader:
            if len(row) < 19:
                continue

            feature_code = row[7]
            population = int(row[14]) if row[14] else 0

            # Filtrar solo ciudades con población mínima
            if feature_code not in CITY_FEATURE_CODES:
                continue

            if population < min_population:
                continue

            city = {
                'geoname_id': int(row[0]),
                'name': row[1],
                'ascii_name': row[2],
                'alternate_names': row[3].split(',') if row[3] else [],
                'latitude': float(row[4]),
                'longitude': float(row[5]),
                'feature_code': feature_code,
                'country_code': row[8],
                'admin1_code': row[10],
                'population': population,
                'elevation': int(row[15]) if row[15] else None,
                'timezone': row[17],
            }

            cities.append(city)

    return cities

def import_to_supabase(cities: list, country_code: str, dry_run: bool = False):
    """
    Importa ciudades a Supabase usando API REST
    """
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("❌ Error: SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY no encontradas")
        print("   Este script requiere service role key para insertar datos masivamente.")
        print("   ")
        print("   Crea un archivo .env.local (ya está en .gitignore):")
        print("   ")
        print("   SUPABASE_URL=https://xxx.supabase.co")
        print("   SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...")
        print("   ")
        print("   ⚠️  .env.local NO se empaqueta en tu app - es solo para scripts locales")
        sys.exit(1)

    print(f"\n📊 Estadísticas:")
    print(f"   Total ciudades: {len(cities):,}")
    if cities:
        avg_pop = sum(c['population'] for c in cities) / len(cities)
        max_city = max(cities, key=lambda c: c['population'])
        print(f"   Población promedio: {avg_pop:,.0f}")
        print(f"   Ciudad más grande: {max_city['name']} ({max_city['population']:,})")

    if dry_run:
        print("\n🔍 Modo DRY RUN - No se insertarán datos")
        return

    # Verificar que el país existe
    print(f"\n🔍 Verificando país '{country_code}'...")
    countries = supabase_request('countries', params={'id': f'eq.{country_code}', 'select': 'id'})
    if not countries:
        print(f"❌ Error: País '{country_code}' no existe en la tabla countries")
        print("   Primero ejecuta: supabase db reset --linked")
        sys.exit(1)

    # Mapear admin1_code a region_id
    print(f"🔍 Cargando regiones de {country_code}...")
    regions = supabase_request('regions', params={
        'country_id': f'eq.{country_code}',
        'select': 'id,code,geoname_id'
    })

    region_map = {r['code']: r['id'] for r in regions if r.get('code')}

    # Mapear códigos alternativos de GeoNames (Colombia tiene códigos duplicados)
    # Estos códigos apuntan a los mismos departamentos
    alternative_codes = {
        '33': '25',  # Cundinamarca
        '35': '05',  # Bolívar
        '36': '06',  # Boyacá
        '37': '07',  # Caldas
        '38': '18',  # Magdalena
    }

    # Agregar mappings alternativos
    for alt_code, main_code in alternative_codes.items():
        if main_code in region_map:
            region_map[alt_code] = region_map[main_code]

    print(f"✅ Encontradas {len(region_map)} regiones para {country_code}")

    if len(region_map) == 0:
        print(f"❌ Error: No hay regiones para {country_code}")
        print("   Primero ejecuta: supabase db reset --linked")
        sys.exit(1)

    # Preparar datos para inserción
    records = []
    skipped = 0

    for city in cities:
        region_id = region_map.get(city['admin1_code'])

        if not region_id:
            skipped += 1
            continue

        record = {
            'id': str(city['geoname_id']),
            'region_id': region_id,
            'country_id': country_code,
            'geoname_id': city['geoname_id'],
            'name': city['name'],
            'ascii_name': city['ascii_name'],
            'alternate_names': city['alternate_names'][:10],  # Limitar a 10
            'feature_code': city['feature_code'],
            'population': city['population'],
            'elevation': city['elevation'],
            'timezone': city['timezone'],
            'lat': city['latitude'],
            'lon': city['longitude'],
        }

        records.append(record)

    print(f"\n📥 Insertando {len(records):,} ciudades...")
    if skipped > 0:
        print(f"   ⚠️  Omitidas: {skipped} (sin región mapeada)")

    # Insertar en lotes de 1000 (límite de Supabase)
    batch_size = 1000
    inserted = 0
    errors = 0

    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]

        try:
            supabase_request('cities', method='POST', data=batch)
            inserted += len(batch)
            print(f"   ✅ Lote {i//batch_size + 1}: {len(batch)} ciudades")
        except Exception as e:
            errors += len(batch)
            print(f"   ❌ Error en lote {i//batch_size + 1}: {e}")

    print(f"\n✅ Importación completada:")
    print(f"   Insertadas: {inserted:,}")
    if errors > 0:
        print(f"   Errores: {errors}")

def main():
    parser = argparse.ArgumentParser(description='Importar datos de GeoNames a Supabase')
    parser.add_argument('--country', required=True, help='Código de país (ej: CO, US, BR)')
    parser.add_argument('--file', required=True, help='Ruta completa al archivo GeoNames (ej: /path/to/CO.txt)')
    parser.add_argument('--min-population', type=int, default=500, help='Población mínima (default: 500)')
    parser.add_argument('--dry-run', action='store_true', help='Modo dry run (no inserta datos)')

    args = parser.parse_args()

    # Verificar que el archivo existe
    if not os.path.exists(args.file):
        print(f"❌ Error: Archivo '{args.file}' no encontrado")
        print(f"\nDescargar datos de GeoNames:")
        print(f"   wget https://download.geonames.org/export/dump/{args.country}.zip")
        print(f"   unzip {args.country}.zip")
        sys.exit(1)

    print(f"📖 Leyendo archivo: {args.file}")
    print(f"🔍 Población mínima: {args.min_population:,}")

    cities = parse_geonames_file(args.file, args.min_population)

    if not cities:
        print("❌ No se encontraron ciudades que cumplan los criterios")
        sys.exit(1)

    import_to_supabase(cities, args.country, dry_run=args.dry_run)

if __name__ == '__main__':
    main()
