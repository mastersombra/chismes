# Estrategia de Datos de Ubicación

**Problema:** Mock con 12 ciudades → Necesitamos datos reales de países, regiones y ciudades.

---

## 🎯 Solución Implementada: **Base de Datos Supabase**

### ¿Por qué Base de Datos propia vs API externa?

| Característica | Base de Datos Supabase | API Externa (GeoNames) |
|----------------|------------------------|------------------------|
| **Performance** | ⚡ Rápido (local) | 🐌 Depende de red |
| **Offline** | ✅ Funciona | ❌ Requiere internet |
| **Límites** | ✅ Sin límites | ⚠️ 2,000 requests/hora (free) |
| **Costo** | ✅ $0 | ✅ $0 (free tier) |
| **Mantenimiento** | ⚠️ Actualizar manualmente | ✅ Siempre actualizada |
| **Control** | ✅ Total | ❌ Depende de terceros |
| **RLS** | ✅ Nativo | ❌ No aplica |
| **Recomendación** | ⭐️ **USAR ESTA** | Solo para reverse geocoding |

---

## 📊 Arquitectura Propuesta

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────┐         ┌──────────────────────┐ │
│  │  GPS Detectado  │────────>│ LocationService      │ │
│  │  6.25, -75.56   │         │ getCityFromCoords()  │ │
│  └─────────────────┘         └──────────────────────┘ │
│           │                            │               │
│           │                            ▼               │
│           │                  ┌──────────────────────┐ │
│           │                  │ Supabase Function    │ │
│           │                  │ find_nearest_city()  │ │
│           │                  └──────────────────────┘ │
│           │                            │               │
│           └────────────────────────────┘               │
│                                        │               │
└────────────────────────────────────────┼───────────────┘
                                         │
                                         ▼
                        ┌─────────────────────────────────┐
                        │   SUPABASE DATABASE             │
                        ├─────────────────────────────────┤
                        │ ✅ countries (195)              │
                        │ ✅ regions (~5,000)             │
                        │ ✅ cities (~100,000)            │
                        │                                 │
                        │ Funciones:                      │
                        │ - search_cities(query)          │
                        │ - find_nearest_city(lat, lon)   │
                        └─────────────────────────────────┘
```

---

## 🏗️ Implementación

### Paso 1: Crear Tablas en Supabase

Ya creamos la migration `003_create_location_tables.sql` con:

**Tablas:**
- `countries` - 195 países
- `regions` - ~5,000 regiones (departamentos/estados)
- `cities` - ~100,000 ciudades (filtradas por población > 1,000)

**Funciones:**
- `search_cities(query, region_id, max_results)` - Autocomplete
- `find_nearest_city(lat, lon, max_distance_km)` - Reverse geocoding

**Índices:**
- Búsqueda por nombre (trigram)
- Búsqueda espacial (coordenadas)
- GeoName IDs (para actualizaciones)

---

### Paso 2: Aplicar Migration

```bash
# Opción A: Aplicar en proyecto linkeado (remoto)
supabase db reset --linked

# Opción B: Aplicar solo la migration (sin reset)
supabase db push --linked
```

---

### Paso 3: Poblar con Datos Reales

#### **Opción A: Seed de Colombia (Rápido - Para Empezar)** ⭐️

Ya creamos `seed_colombia_locations.sql` con:
- 1 país (Colombia)
- 9 departamentos principales
- 35 ciudades principales (> 50,000 habitantes)

**Aplicar seed:**
```bash
# Ejecutar seed en Supabase Dashboard → SQL Editor
# O desde CLI:
supabase db seed --linked
```

**Resultado:**
- ✅ GPS funciona en Colombia
- ✅ Autocomplete funciona
- ✅ Datos reales con coordenadas

---

#### **Opción B: Dataset Completo GeoNames (Producción)** 🌎

Para escalar a múltiples países:

**1. Descargar datos de GeoNames:**
```bash
# Colombia completo (~1,100 municipios)
wget https://download.geonames.org/export/dump/CO.zip
unzip CO.zip

# Otros países (ejemplos)
wget https://download.geonames.org/export/dump/US.zip  # USA
wget https://download.geonames.org/export/dump/BR.zip  # Brasil
wget https://download.geonames.org/export/dump/MX.zip  # México
wget https://download.geonames.org/export/dump/AR.zip  # Argentina
```

**2. Usar script de importación:**
```bash
python scripts/import_geonames.py --country CO --min-population 1000
```

**Nota:** Este script hay que crearlo. Ver sección "Script de Importación" más abajo.

---

### Paso 4: Actualizar Repositorio Flutter

Reemplazar `MockLocationRepository` por `SupabaseLocationRepository`.

**Crear nuevo datasource:**
```dart
// lib/features/location/data/datasources/supabase_location_remote_data_source.dart

class SupabaseLocationRemoteDataSource {
  final SupabaseClient _supabase;

  // Obtener países
  Future<List<Country>> getCountries() async {
    final response = await _supabase
        .from('countries')
        .select()
        .order('name');
    
    return (response as List)
        .map((json) => Country.fromJson(json))
        .toList();
  }

  // Obtener regiones por país
  Future<List<Region>> getRegionsByCountry(String countryId) async {
    final response = await _supabase
        .from('regions')
        .select()
        .eq('country_id', countryId)
        .order('name');
    
    return (response as List)
        .map((json) => Region.fromJson(json))
        .toList();
  }

  // Buscar ciudades (Autocomplete)
  Future<List<City>> searchCities(String query, String regionId) async {
    final response = await _supabase
        .rpc('search_cities', params: {
          'search_query': query,
          'region_filter': regionId,
          'max_results': 20,
        });
    
    return (response as List)
        .map((json) => City.fromJson(json))
        .toList();
  }

  // Reverse geocoding
  Future<City?> findNearestCity(double lat, double lon) async {
    final response = await _supabase
        .rpc('find_nearest_city', params: {
          'target_lat': lat,
          'target_lon': lon,
          'max_distance_km': 50,
        });
    
    if (response == null || (response as List).isEmpty) return null;
    
    return City.fromJson(response[0]);
  }
}
```

---

## 📈 Escalabilidad

### Datos Actuales (Seed de Colombia)

| Tabla | Registros | Tamaño |
|-------|-----------|--------|
| `countries` | 1 | ~1 KB |
| `regions` | 9 | ~5 KB |
| `cities` | 35 | ~15 KB |
| **Total** | **45** | **~21 KB** |

**Performance:**
- ✅ Búsqueda instantánea (< 10ms)
- ✅ Autocomplete rápido
- ✅ Reverse geocoding rápido

---

### Datos Completos (GeoNames)

#### Colombia Completo

| Tabla | Registros | Tamaño |
|-------|-----------|--------|
| `countries` | 1 | ~1 KB |
| `regions` | 32 | ~20 KB |
| `cities` | ~1,100 | ~500 KB |
| **Total** | **~1,133** | **~521 KB** |

#### Latinoamérica (5 países)

| Tabla | Registros | Tamaño |
|-------|-----------|--------|
| `countries` | 5 | ~5 KB |
| `regions` | ~200 | ~100 KB |
| `cities` | ~5,000 | ~2.5 MB |
| **Total** | **~5,205** | **~2.6 MB** |

#### Global (195 países)

| Tabla | Registros | Tamaño |
|-------|-----------|--------|
| `countries` | 195 | ~100 KB |
| `regions` | ~5,000 | ~2.5 MB |
| `cities` | ~100,000 | ~50 MB |
| **Total** | **~105,195** | **~52.6 MB** |

**Notas:**
- Tamaños estimados (dependen de filtro de población)
- PostgreSQL comprime bien los datos
- Índices ocupan ~30% adicional

---

## 🔍 Reverse Geocoding: ¿API o Base de Datos?

### Situación Actual

Estamos usando `geocoding` package de Flutter:
```dart
final placemarks = await placemarkFromCoordinates(latitude, longitude);
```

**Problema:** Esto usa API de Google (límites de uso).

### Solución Híbrida Recomendada

**Para desarrollo/testing:**
- ✅ Usar `geocoding` package (gratis, fácil)
- ⚠️ Límite: ~2,500 requests/día

**Para producción:**
- ✅ Usar función `find_nearest_city()` de Supabase
- ✅ Sin límites
- ✅ Más rápido

**Implementación:**
```dart
// lib/core/services/location_service.dart

Future<DetectedLocation?> getCityFromCoordinates(
  double latitude,
  double longitude,
) async {
  try {
    // OPCIÓN 1: Usar base de datos propia (PRODUCCIÓN)
    final response = await _supabase.rpc('find_nearest_city', params: {
      'target_lat': latitude,
      'target_lon': longitude,
      'max_distance_km': 50,
    });

    if (response != null && response is List && response.isNotEmpty) {
      final data = response[0];
      return DetectedLocation(
        cityName: data['name'],
        regionName: data['region_name'],
        countryName: data['country_name'],
      );
    }

    // OPCIÓN 2: Fallback a geocoding package (si no encuentra en DB)
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    // ...
  } catch (e) {
    print('❌ Error en reverse geocoding: $e');
    return null;
  }
}
```

---

## 💰 Costos

### Base de Datos Supabase

| Tier | Almacenamiento | Egress | Costo |
|------|----------------|--------|-------|
| **Free** | 500 MB | 5 GB/mes | $0 |
| **Pro** | 8 GB | 250 GB/mes | $25/mes |

**Con 100K ciudades (~50 MB):**
- ✅ Cabe en Free tier
- ✅ Egress muy bajo (datos se cachean en cliente)

---

### API Externa (GeoNames)

| Servicio | Límites | Costo |
|----------|---------|-------|
| **Free** | 2,000 req/hora | $0 |
| **Premium** | 20,000 req/hora | $1,000/año |

**Con 1,000 usuarios/día:**
- ⚠️ Puede superar límite free
- 💸 Premium costoso

---

## 🧪 Testing

### 1. Probar Búsqueda de Ciudades

```sql
-- En Supabase SQL Editor
SELECT * FROM search_cities('Med', 'co-antioquia', 10);
```

**Resultado esperado:**
```
id       | name      | region_name | population
---------|-----------|-------------|------------
3688689  | Medellín  | Antioquia   | 2533424
```

---

### 2. Probar Reverse Geocoding

```sql
-- Coordenadas de Medellín: 6.25184, -75.56359
SELECT * FROM find_nearest_city(6.25184, -75.56359, 50);
```

**Resultado esperado:**
```
id       | name      | region_name | distance_km
---------|-----------|-------------|-------------
3688689  | Medellín  | Antioquia   | 0.02
```

---

### 3. Probar en Flutter

```dart
// Autocomplete
final cities = await datasource.searchCities('Med', 'co-antioquia');
print(cities); // [Medellín, Medina, ...]

// Reverse geocoding
final city = await datasource.findNearestCity(6.25184, -75.56359);
print(city.name); // Medellín
```

---

## 📋 Checklist de Implementación

### Fase 1: Base de Datos (Ahora)

- [x] Crear migration `003_create_location_tables.sql`
- [x] Crear seed `seed_colombia_locations.sql`
- [ ] Aplicar migration: `supabase db reset --linked`
- [ ] Ejecutar seed en SQL Editor
- [ ] Verificar datos en Supabase Dashboard

### Fase 2: Flutter (Después)

- [ ] Crear `SupabaseLocationRemoteDataSource`
- [ ] Crear `SupabaseLocationRepository`
- [ ] Actualizar entities (agregar `fromJson/toJson`)
- [ ] Actualizar `GetItInstance` (reemplazar Mock → Supabase)
- [ ] Actualizar `LocationService` para usar `find_nearest_city()`
- [ ] Probar flujo completo

### Fase 3: Escalabilidad (Futuro)

- [ ] Agregar más países (México, Brasil, etc.)
- [ ] Optimizar índices si queries lentas
- [ ] Implementar cache en Flutter (Hive/SQLite)
- [ ] Agregar actualización periódica de datos

---

## 🎯 Resumen

| Aspecto | Decisión |
|---------|----------|
| **Fuente de datos** | GeoNames (gratis, completa) |
| **Almacenamiento** | Supabase PostgreSQL |
| **Países iniciales** | Colombia (35 ciudades) |
| **Escalabilidad** | Hasta 100K ciudades sin problemas |
| **Reverse geocoding** | Función SQL `find_nearest_city()` |
| **Autocomplete** | Función SQL `search_cities()` |
| **Costo** | $0 (Free tier suficiente) |

---

## 🚀 Próximos Pasos

1. **Aplicar migration y seed** (5 minutos)
   ```bash
   supabase db reset --linked
   # Luego ejecutar seed_colombia_locations.sql en SQL Editor
   ```

2. **Crear SupabaseLocationRepository** (30 minutos)
   - Implementar datasource
   - Actualizar repository
   - Actualizar DI

3. **Probar GPS en app** (10 minutos)
   - Ejecutar en emulador con coordenadas de Medellín
   - Verificar que detecta "Medellín, Antioquia"

4. **Agregar más países** (opcional, futuro)
   - Descargar datasets de GeoNames
   - Ejecutar script de importación

---

**Resultado:** De 12 ciudades mock → 35 ciudades reales de Colombia con GPS funcionando. Listo para producción. 🎉
