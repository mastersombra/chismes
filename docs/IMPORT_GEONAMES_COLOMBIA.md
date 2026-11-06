# Importar Dataset Completo de Colombia (GeoNames)

**Objetivo:** Reemplazar 35 ciudades del seed → 1,100 municipios completos de Colombia.

---

## 📥 Paso 1: Descargar Dataset

```bash
cd ~/Downloads

# Descargar Colombia completo (~50 MB)
wget https://download.geonames.org/export/dump/CO.zip

# Descomprimir
unzip CO.zip

# Verificar
ls -lh CO.txt
# Resultado: ~50 MB, 23,000+ líneas
```

---

## 📊 Paso 2: Entender el Dataset

El archivo `CO.txt` es TSV (tab-separated) con estas columnas:

| Columna | Nombre | Ejemplo |
|---------|--------|---------|
| 0 | geonameid | 3688689 |
| 1 | name | Medellín |
| 2 | asciiname | Medellin |
| 4 | latitude | 6.25184 |
| 5 | longitude | -75.56359 |
| 6 | feature class | P (populated place) |
| 7 | feature code | PPLA (admin capital) |
| 10 | admin1 code | 02 (Antioquia) |
| 14 | population | 2533424 |
| 17 | timezone | America/Bogota |

**Feature codes importantes:**
- `PPLC` - Capital de país (Bogotá)
- `PPLA` - Capital de departamento (Medellín, Cali, ...)
- `PPLA2` - Capital de provincia
- `PPL` - Ciudad/municipio
- `PPLX` - Sección de ciudad

**Lo que NO queremos:**
- Veredas (población < 100)
- Montañas (feature class = T)
- Ríos (feature class = H)

---

## 🔧 Paso 3: Preparar Supabase

### A. Aplicar Migration de Tablas

```bash
cd /Users/alejo/Documents/Piloto/chismes

# Aplicar migration 003 (crea tablas countries, regions, cities)
supabase db reset --linked
```

### B. Ejecutar Seed Base (Países + Regiones)

Necesitamos primero los países y regiones (departamentos de Colombia).

**Ir a Supabase Dashboard → SQL Editor**

Ejecutar este SQL:

```sql
-- =====================================================
-- SEED: Países y Departamentos de Colombia
-- =====================================================

TRUNCATE TABLE cities CASCADE;
TRUNCATE TABLE regions CASCADE;
TRUNCATE TABLE countries CASCADE;

-- País: Colombia
INSERT INTO countries (id, code, name, local_name, capital, population, area_km2, phone_prefix, currency, languages, lat, lon) VALUES
('CO', 'CO', 'Colombia', 'Colombia', 'Bogotá', 51516562, 1141748, '+57', 'COP', ARRAY['es'], 4.570868, -74.297333);

-- Departamentos de Colombia (32 + Bogotá D.C.)
INSERT INTO regions (id, country_id, geoname_id, name, type, code, lat, lon) VALUES
('co-amazonas', 'CO', 3689982, 'Amazonas', 'department', '91', -1.4419, -71.6420),
('co-antioquia', 'CO', 3689815, 'Antioquia', 'department', '05', 6.2518, -75.5636),
('co-arauca', 'CO', 3689579, 'Arauca', 'department', '81', 7.0808, -70.7621),
('co-atlantico', 'CO', 3689560, 'Atlántico', 'department', '08', 10.9639, -74.7964),
('co-bolivar', 'CO', 3687669, 'Bolívar', 'department', '13', 8.6667, -74.0333),
('co-boyaca', 'CO', 3687318, 'Boyacá', 'department', '15', 5.4544, -73.3623),
('co-caldas', 'CO', 3686887, 'Caldas', 'department', '17', 5.2988, -75.2483),
('co-caqueta', 'CO', 3686590, 'Caquetá', 'department', '18', 0.8698, -73.8411),
('co-casanare', 'CO', 3686541, 'Casanare', 'department', '85', 5.7589, -71.5724),
('co-cauca', 'CO', 3687031, 'Cauca', 'department', '19', 2.4536, -76.6064),
('co-cesar', 'CO', 3685411, 'Cesar', 'department', '20', 9.3373, -73.6536),
('co-choco', 'CO', 3685084, 'Chocó', 'department', '27', 5.2533, -76.8190),
('co-cordoba', 'CO', 3686670, 'Córdoba', 'department', '23', 8.7479, -75.8814),
('co-cundinamarca', 'CO', 3686922, 'Cundinamarca', 'department', '25', 4.6097, -74.0817),
('co-guainia', 'CO', 3680656, 'Guainía', 'department', '94', 2.5833, -68.5167),
('co-guaviare', 'CO', 3680450, 'Guaviare', 'department', '95', 1.9089, -72.6861),
('co-huila', 'CO', 3680070, 'Huila', 'department', '41', 2.5358, -75.5277),
('co-la-guajira', 'CO', 3679170, 'La Guajira', 'department', '44', 11.3547, -72.5205),
('co-magdalena', 'CO', 3674885, 'Magdalena', 'department', '47', 10.4111, -74.4056),
('co-meta', 'CO', 3674453, 'Meta', 'department', '50', 3.8036, -73.0353),
('co-narino', 'CO', 3672486, 'Nariño', 'department', '52', 1.2136, -77.2811),
('co-norte-santander', 'CO', 3671916, 'Norte de Santander', 'department', '54', 7.9465, -72.8988),
('co-putumayo', 'CO', 3670644, 'Putumayo', 'department', '86', 0.4867, -75.5236),
('co-quindio', 'CO', 3670218, 'Quindío', 'department', '63', 4.4610, -75.6674),
('co-risaralda', 'CO', 3669705, 'Risaralda', 'department', '66', 4.8087, -75.6959),
('co-san-andres', 'CO', 3668605, 'San Andrés y Providencia', 'department', '88', 12.5847, -81.7006),
('co-santander', 'CO', 3671098, 'Santander', 'department', '68', 7.0000, -73.0000),
('co-sucre', 'CO', 3667670, 'Sucre', 'department', '70', 8.8139, -74.7236),
('co-tolima', 'CO', 3666639, 'Tolima', 'department', '73', 4.4389, -75.2322),
('co-valle', 'CO', 3666850, 'Valle del Cauca', 'department', '76', 3.4516, -76.5320),
('co-vaupes', 'CO', 3665952, 'Vaupés', 'department', '97', 0.8667, -70.8167),
('co-vichada', 'CO', 3665876, 'Vichada', 'department', '99', 4.4333, -69.2833),
('co-bogota', 'CO', 3688689, 'Bogotá D.C.', 'capital_district', '11', 4.6097, -74.0817);

-- Verificar
SELECT COUNT(*) FROM countries; -- Debe ser 1
SELECT COUNT(*) FROM regions;   -- Debe ser 33
```

---

## 🐍 Paso 4: Importar Ciudades con Script Python

### A. Instalar Dependencias

```bash
cd /Users/alejo/Documents/Piloto/chismes

# Crear virtual environment
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r scripts/requirements.txt
```

### B. Configurar .env

Agregar al archivo `.env`:

```bash
# Ya deberías tener esto:
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key

# Agregar esto (necesario para el script):
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key
```

**¿Dónde encontrar Service Role Key?**
- Supabase Dashboard → Settings → API
- Copiar "service_role" key (NO la anon key)

⚠️ **IMPORTANTE:** Service role key bypasea RLS. NO la expongas en el cliente Flutter.

---

### C. Ejecutar Script de Importación

```bash
# Asegúrate de que CO.txt esté en ~/Downloads
ls -lh ~/Downloads/CO.txt

# Ejecutar importación
python scripts/import_geonames.py \
  --country CO \
  --file ~/Downloads/CO.txt \
  --min-population 500

# Output esperado:
# 📊 Estadísticas:
#    Total ciudades: 1,143
#    Población promedio: 42,156
#    Ciudad más grande: Bogotá (7,743,955)
#
# ✅ Encontradas 33 regiones para CO
#
# 📥 Insertando 1,143 ciudades...
#    ✅ Lote 1: 1000 ciudades
#    ✅ Lote 2: 143 ciudades
#
# ✅ Importación completada:
#    Insertadas: 1,143
#    Errores: 0
```

**Parámetros:**
- `--country CO`: Código del país
- `--file ~/Downloads/CO.txt`: Ruta al archivo
- `--min-population 500`: Solo ciudades con > 500 habitantes (elimina veredas)

**Puedes ajustar el filtro:**
- `--min-population 1000` → ~850 ciudades (municipios grandes)
- `--min-population 5000` → ~200 ciudades (ciudades principales)
- `--min-population 0` → ~23,000 lugares (incluye veredas)

---

## ✅ Paso 5: Verificar Importación

### En Supabase Dashboard

Ir a **Table Editor**:

```
countries: 1 registro
regions:   33 registros
cities:    1,143 registros
```

### En SQL Editor

```sql
-- Ver estadísticas
SELECT 
  r.name AS departamento,
  COUNT(c.id) AS ciudades,
  SUM(c.population) AS poblacion_total
FROM regions r
LEFT JOIN cities c ON r.id = c.region_id
WHERE r.country_id = 'CO'
GROUP BY r.id, r.name
ORDER BY COUNT(c.id) DESC;

-- Top 10 ciudades
SELECT name, population, region_id 
FROM cities 
WHERE country_id = 'CO'
ORDER BY population DESC 
LIMIT 10;
```

### En Flutter

```bash
flutter run

# Configurar emulador con coordenadas de tu ciudad:
# Medellín: 6.2518, -75.5636
# Bogotá: 4.6097, -74.0817
# Cali: 3.4516, -76.5320

# Abrir "Crear Chisme"
# → Debe auto-detectar tu ciudad correctamente
```

---

## 🐛 Troubleshooting

### Error: "País 'CO' no existe"

**Causa:** No ejecutaste el seed de países/regiones.

**Solución:**
```sql
-- Ejecutar en SQL Editor el SQL del Paso 3.B
```

---

### Error: "Región no mapeada"

**Causa:** El código admin1 del archivo no coincide con el código en la tabla regions.

**Ejemplo:**
- Archivo: `admin1_code = '05'` (Antioquia)
- Tabla: `regions.code = '05'` ✅

**Solución:** Verificar que los códigos coincidan:
```sql
SELECT id, code, name FROM regions WHERE country_id = 'CO';
```

---

### Ciudades duplicadas

**Causa:** GeoNames tiene múltiples registros para la misma ciudad (diferentes feature codes).

**Solución:** El script usa `upsert` con `on_conflict='geoname_id'`, así que solo se guarda una versión.

---

## 📊 Resultado Final

| Antes | Después |
|-------|---------|
| 12 ciudades mock | 1,143 municipios reales |
| Solo ciudades grandes | Todas las poblaciones > 500 hab |
| Sin coordenadas reales | Coordenadas GPS precisas |
| GPS no funciona | GPS funciona en toda Colombia |

---

## 🚀 Próximo Paso

Después de importar los datos, necesitas crear **SupabaseLocationRepository** para que Flutter lea de la base de datos real.

Ver: `docs/SUPABASE_LOCATION_REPOSITORY_IMPLEMENTATION.md` (próximo documento)
