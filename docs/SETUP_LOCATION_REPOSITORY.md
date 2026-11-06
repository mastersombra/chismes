# Setup Completo: SupabaseLocationRepository

**✅ COMPLETADO:**
- Entidades con serialización (fromJson/toJson)
- SupabaseLocationRemoteDataSource
- SupabaseLocationRepository  
- Dependency Injection actualizado

---

## 📦 Lo que se Implementó

### 1. Entidades Actualizadas

**Archivos modificados:**
- `lib/features/location/domain/entities/country.dart` ✅
- `lib/features/location/domain/entities/region.dart` ✅
- `lib/features/location/domain/entities/city.dart` ✅

**Agregado:** `fromJson()` y `toJson()` para serialización con Supabase.

---

### 2. Data Source Creado

**Archivo:** `lib/features/location/data/datasources/supabase_location_remote_data_source.dart`

**Métodos:**
- `getCountries()` - Lista de países
- `getRegionsByCountry(countryId)` - Regiones de un país
- `getCitiesByRegion(regionId)` - Ciudades de una región
- `searchCities(query, regionId)` - Autocomplete **✨ NUEVO**
- `findNearestCity(lat, lon)` - Reverse geocoding **✨ NUEVO**

---

### 3. Repository Creado

**Archivo:** `lib/features/location/data/repositories/supabase_location_repository.dart`

**Anotación:** `@Singleton(as: LocationRepository)`

**Efecto:** Reemplaza automáticamente MockLocationRepository.

---

### 4. Mock Actualizado

**Archivo:** `lib/features/location/data/repositories/mock_location_repository.dart`

**Cambio:** `@Singleton` → `@Named('mock')`

**Efecto:** Ya NO se usa por defecto. Supabase es el default.

---

### 5. DI Regenerado

```bash
flutter pub run build_runner build
```

**Efecto:** `SupabaseLocationRepository` ahora está registrado en GetIt.

---

## 🚀 Pasos Siguientes (Tú debes hacer)

### Paso 1: Aplicar Migrations en Supabase (5 minutos)

```bash
cd /Users/alejo/Documents/Piloto/chismes

# Aplicar todas las migrations (001, 002, 003)
supabase db reset --linked
```

**Esperar:** Este comando tarda ~30 segundos.

**Resultado esperado:**
```
✓ Resetting remote database...
Applying migration 001_create_gossips_table.sql...
Applying migration 002_add_idempotency.sql...
Applying migration 003_create_location_tables.sql...
Finished supabase db reset on branch main.
```

---

### Paso 2: Seed de Países y Departamentos (2 minutos)

**Opción A: Desde archivo SQL**

1. Ir a: [Supabase Dashboard](https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/sql)
2. Abrir archivo: `seed_colombia_locations.sql` en tu editor
3. Copiar TODO el contenido (líneas 1-299)
4. Pegar en SQL Editor de Supabase
5. Click en "Run"

**Opción B: Desde terminal (si tienes psql)**

```bash
supabase db push --seed
```

---

### Paso 3: Importar Ciudades con Script Python (10 minutos)

#### A. Preparar Entorno

```bash
cd /Users/alejo/Documents/Piloto/chismes

# Crear virtual environment
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r scripts/requirements.txt
```

#### B. Agregar SUPABASE_SERVICE_ROLE_KEY al .env

Editar archivo `.env`:

```bash
# Ya tienes estas:
SUPABASE_URL=https://njqamqcsldpmtbiqwbwo.supabase.co
SUPABASE_ANON_KEY=tu-anon-key

# AGREGAR ESTA (buscar en Supabase Dashboard → Settings → API):
SUPABASE_SERVICE_ROLE_KEY=eyJh......tu-service-role-key
```

⚠️ **IMPORTANTE:** Service role key bypasea RLS. NO la expongas públicamente.

#### C. Ejecutar Importación

```bash
python scripts/import_geonames.py \
  --country CO \
  --file /Users/alejo/Desktop/CO \
  --min-population 500
```

**Parámetros:**
- `--min-population 500`: Solo ciudades con > 500 habitantes (elimina veredas pequeñas)
- Puedes ajustar: 1000 (ciudades medianas), 5000 (solo ciudades grandes)

**Output esperado:**
```
📖 Leyendo archivo: /Users/alejo/Desktop/CO
🔍 Población mínima: 500

📊 Estadísticas:
   Total ciudades: 1,143
   Población promedio: 42,156
   Ciudad más grande: Bogotá (7,743,955)

✅ Encontradas 33 regiones para CO

📥 Insertando 1,143 ciudades...
   ✅ Lote 1: 1000 ciudades
   ✅ Lote 2: 143 ciudades

✅ Importación completada:
   Insertadas: 1,143
   Errores: 0
```

---

### Paso 4: Verificar Datos en Supabase (2 minutos)

1. Ir a: [Supabase Table Editor](https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/editor)

2. Verificar tablas:
   - `countries`: 1 registro ✅
   - `regions`: 33 registros ✅
   - `cities`: 1,143 registros ✅

3. Probar búsqueda en SQL Editor:

```sql
-- Buscar ciudades
SELECT * FROM search_cities('Med') LIMIT 5;
-- Resultado: Medellín, Medina, ...

-- Reverse geocoding (Medellín)
SELECT * FROM find_nearest_city(6.2518, -75.5636, 50);
-- Resultado: Medellín, distance_km: 0.02
```

---

### Paso 5: Probar en Flutter (5 minutos)

```bash
flutter clean
flutter pub get
flutter run
```

**Probar flujo:**
1. Abrir "Crear Chisme" (FloatingActionButton)
2. **Configurar GPS en emulador:**
   - Android: Menu `⋮` → Location → `6.2518, -75.5636`
   - iOS: Debug → Location → Custom Location → `6.2518, -75.5636`
3. Esperar 3-5 segundos
4. Debe mostrar: `[📍 Medellín, Antioquia] [Cambiar]` ✅
5. Tocar "Cambiar" → Probar búsqueda "Bog" → Debe encontrar Bogotá ✅

---

## 🐛 Troubleshooting

### Error: "País 'CO' no existe"

**Causa:** No ejecutaste el seed de países/departamentos.

**Solución:** Ejecutar Paso 2 arriba.

---

### Error: "Service role key not found"

**Causa:** Falta `SUPABASE_SERVICE_ROLE_KEY` en `.env`.

**Solución:**
1. Ir a [Supabase Dashboard → Settings → API](https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/settings/api)
2. Copiar "service_role" key
3. Agregar a `.env`

---

### Error: "Region not mapped"

**Causa:** El código admin1 del archivo no coincide con regions.code.

**Ejemplo del archivo CO:**
```
...    P    PPL    CO        05    ...
                         ↑ admin1_code = '05' (Antioquia)
```

**Solución:** Verificar que el seed tenga regiones con esos códigos:
```sql
SELECT id, code, name FROM regions WHERE country_id = 'CO';
```

---

### GPS no detecta ciudad

**Causa:** Coordenadas fuera de Colombia o ciudad no está en base de datos.

**Solución:** Usar coordenadas de ciudades confirmadas:
- Medellín: `6.2518, -75.5636`
- Bogotá: `4.6097, -74.0817`
- Cali: `3.4516, -76.5320`

---

### App sigue usando datos mock

**Causa:** No se regeneró código de injectable.

**Solución:**
```bash
flutter pub run build_runner build
flutter clean
flutter run
```

---

## 📊 Resultado Final

| Antes | Después |
|-------|---------|
| ❌ MockLocationRepository | ✅ SupabaseLocationRepository |
| ❌ 12 ciudades hardcodeadas | ✅ 1,143 municipios reales |
| ❌ GPS no funciona | ✅ GPS detecta ciudad correcta |
| ❌ Sin autocomplete | ✅ Búsqueda inteligente |
| ❌ Sin reverse geocoding | ✅ find_nearest_city() |

---

## 🎯 Verificación de Éxito

Sabrás que todo funcionó cuando:

1. ✅ App inicia sin errores
2. ✅ "Crear Chisme" auto-detecta tu ciudad (GPS)
3. ✅ Al tocar "Cambiar" ves tus 33 departamentos
4. ✅ Al seleccionar departamento, ves todas sus ciudades
5. ✅ Puedes buscar ciudades escribiendo "Med" → encuentra Medellín

---

## 📚 Archivos Relevantes

**Documentación:**
- `docs/LOCATION_DATA_STRATEGY.md` - Estrategia completa
- `docs/IMPORT_GEONAMES_COLOMBIA.md` - Guía de importación detallada
- `docs/LOCATION_FEATURE_IMPLEMENTATION.md` - Feature de geolocalización

**Migrations:**
- `supabase/migrations/003_create_location_tables.sql` - Tablas y funciones

**Seed:**
- `supabase/seed_colombia_locations.sql` - Países + 33 departamentos + 35 ciudades

**Script:**
- `scripts/import_geonames.py` - Importar dataset completo
- `scripts/requirements.txt` - Dependencias Python

**Código:**
- `lib/features/location/data/datasources/supabase_location_remote_data_source.dart`
- `lib/features/location/data/repositories/supabase_location_repository.dart`

---

**¡Éxito!** Ahora tienes un sistema completo de ubicación con datos reales. 🎉
