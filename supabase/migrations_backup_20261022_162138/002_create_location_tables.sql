-- =====================================================
-- Tablas de Ubicación (Países, Regiones, Ciudades)
-- =====================================================
-- Datos reales de GeoNames (https://www.geonames.org/)
--
-- Estrategia:
-- 1. Países: ~195 (todos)
-- 2. Regiones: ~5,000 (departamentos/estados)
-- 3. Ciudades: ~100,000+ (filtradas por población mínima)
--
-- Filtrado de ciudades:
-- - Colombia: Solo municipios (feature_code = 'PPLA', 'PPLA2', 'PPL')
-- - Población mínima: 1,000 habitantes
-- - Esto reduce de 10M → 100K ciudades globales
-- =====================================================

-- =====================================================
-- EXTENSIONES (DEBEN IR PRIMERO)
-- =====================================================

-- Para búsqueda por similaridad de texto (autocomplete)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Para cálculos de distancia geográfica (reverse geocoding)
-- IMPORTANTE: cube debe instalarse antes de earthdistance
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- =====================================================
-- TABLA: countries
-- =====================================================

CREATE TABLE countries (
  id TEXT PRIMARY KEY,              -- Código ISO (ej: 'CO', 'US', 'BR')
  code TEXT NOT NULL UNIQUE,        -- Código ISO (mismo que id)
  name TEXT NOT NULL,               -- Nombre (ej: 'Colombia')
  local_name TEXT,                  -- Nombre local (ej: 'Colombia')
  capital TEXT,                     -- Capital (ej: 'Bogotá')
  population BIGINT,                -- Población total
  area_km2 DECIMAL,                 -- Área en km²
  phone_prefix TEXT,                -- Código telefónico (ej: '+57')
  currency TEXT,                    -- Moneda (ej: 'COP')
  languages TEXT[],                 -- Idiomas (ej: ['es'])
  lat DECIMAL(9,6),                 -- Latitud centro del país
  lon DECIMAL(9,6),                 -- Longitud centro del país
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_countries_code ON countries(code);
CREATE INDEX idx_countries_name ON countries(name);

-- Comentario
COMMENT ON TABLE countries IS
'Catálogo de países. Fuente: GeoNames + REST Countries API. Actualizar anualmente.';

-- =====================================================
-- TABLA: regions
-- =====================================================

CREATE TABLE regions (
  id TEXT PRIMARY KEY,              -- geonameid o código (ej: 'co-antioquia', '05')
  country_id TEXT NOT NULL REFERENCES countries(id),
  geoname_id INTEGER UNIQUE,        -- ID de GeoNames (para actualizaciones)
  name TEXT NOT NULL,               -- Nombre (ej: 'Antioquia')
  type TEXT NOT NULL,               -- Tipo: 'department', 'state', 'province'
  code TEXT,                        -- Código local (ej: '05' para Antioquia)
  population BIGINT,                -- Población
  lat DECIMAL(9,6),                 -- Latitud centro de la región
  lon DECIMAL(9,6),                 -- Longitud centro de la región
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_regions_country_id ON regions(country_id);
CREATE INDEX idx_regions_name ON regions(name);
CREATE INDEX idx_regions_geoname_id ON regions(geoname_id);

-- Comentario
COMMENT ON TABLE regions IS
'Regiones/departamentos/estados. Fuente: GeoNames. Admin Level 1.';

-- =====================================================
-- TABLA: cities
-- =====================================================

CREATE TABLE cities (
  id TEXT PRIMARY KEY,              -- geonameid o código (ej: '3688689', 'co-bogota')
  region_id TEXT NOT NULL REFERENCES regions(id),
  country_id TEXT NOT NULL REFERENCES countries(id),
  geoname_id INTEGER UNIQUE,        -- ID de GeoNames
  name TEXT NOT NULL,               -- Nombre (ej: 'Medellín')
  ascii_name TEXT,                  -- Nombre ASCII (sin acentos, para búsqueda)
  alternate_names TEXT[],           -- Nombres alternativos
  feature_code TEXT,                -- Código de tipo (PPLA, PPL, etc.)
  population INTEGER,               -- Población
  elevation INTEGER,                -- Elevación en metros
  timezone TEXT,                    -- Zona horaria (ej: 'America/Bogota')
  lat DECIMAL(9,6) NOT NULL,        -- Latitud (para reverse geocoding)
  lon DECIMAL(9,6) NOT NULL,        -- Longitud (para reverse geocoding)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices importantes
CREATE INDEX idx_cities_region_id ON cities(region_id);
CREATE INDEX idx_cities_country_id ON cities(country_id);
CREATE INDEX idx_cities_name ON cities(name);
CREATE INDEX idx_cities_ascii_name ON cities(ascii_name);
CREATE INDEX idx_cities_geoname_id ON cities(geoname_id);

-- Índice espacial para reverse geocoding (búsqueda por coordenadas)
-- Permite encontrar ciudad más cercana a lat/lon rápidamente
CREATE INDEX idx_cities_location ON cities USING GIST (
  ll_to_earth(lat::float, lon::float)
);

-- Índice para búsqueda de texto completo
CREATE INDEX idx_cities_name_trgm ON cities USING GIN (name gin_trgm_ops);
CREATE INDEX idx_cities_ascii_name_trgm ON cities USING GIN (ascii_name gin_trgm_ops);

-- Comentario
COMMENT ON TABLE cities IS
'Catálogo de ciudades. Fuente: GeoNames. Filtradas: población > 1,000 habitantes.';

-- =====================================================
-- FUNCIÓN: Buscar ciudades por nombre (Autocomplete)
-- =====================================================

CREATE OR REPLACE FUNCTION search_cities(
  search_query TEXT,
  region_filter TEXT DEFAULT NULL,
  max_results INTEGER DEFAULT 20
)
RETURNS TABLE (
  id TEXT,
  name TEXT,
  region_id TEXT,
  region_name TEXT,
  country_id TEXT,
  country_name TEXT,
  population INTEGER,
  lat DECIMAL,
  lon DECIMAL,
  similarity REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.region_id,
    r.name AS region_name,
    c.country_id,
    co.name AS country_name,
    c.population,
    c.lat,
    c.lon,
    similarity(c.name, search_query) AS similarity
  FROM cities c
  JOIN regions r ON c.region_id = r.id
  JOIN countries co ON c.country_id = co.id
  WHERE
    (region_filter IS NULL OR c.region_id = region_filter)
    AND (
      c.name ILIKE search_query || '%'          -- Empieza con
      OR c.ascii_name ILIKE search_query || '%' -- Empieza con (sin acentos)
      OR c.name ILIKE '%' || search_query || '%' -- Contiene
    )
  ORDER BY
    -- Prioridad: 1) Empieza con, 2) Población, 3) Similaridad
    CASE WHEN c.name ILIKE search_query || '%' THEN 1 ELSE 2 END,
    c.population DESC NULLS LAST,
    similarity(c.name, search_query) DESC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Comentario
COMMENT ON FUNCTION search_cities(TEXT, TEXT, INTEGER) IS
'Busca ciudades por nombre (autocomplete). Prioriza: 1) Coincidencia exacta al inicio, 2) Población, 3) Similitud.';

-- =====================================================
-- FUNCIÓN: Encontrar ciudad más cercana (Reverse Geocoding)
-- =====================================================

CREATE OR REPLACE FUNCTION find_nearest_city(
  target_lat DECIMAL,
  target_lon DECIMAL,
  max_distance_km INTEGER DEFAULT 50
)
RETURNS TABLE (
  id TEXT,
  name TEXT,
  region_id TEXT,
  region_name TEXT,
  country_id TEXT,
  country_name TEXT,
  distance_km REAL,
  lat DECIMAL,
  lon DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.region_id,
    r.name AS region_name,
    c.country_id,
    co.name AS country_name,
    (earth_distance(
      ll_to_earth(c.lat::float, c.lon::float),
      ll_to_earth(target_lat::float, target_lon::float)
    ) / 1000)::REAL AS distance_km,
    c.lat,
    c.lon
  FROM cities c
  JOIN regions r ON c.region_id = r.id
  JOIN countries co ON c.country_id = co.id
  WHERE
    earth_box(ll_to_earth(target_lat::float, target_lon::float), max_distance_km * 1000) @>
    ll_to_earth(c.lat::float, c.lon::float)
  ORDER BY
    earth_distance(
      ll_to_earth(c.lat::float, c.lon::float),
      ll_to_earth(target_lat::float, target_lon::float)
    )
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Comentario
COMMENT ON FUNCTION find_nearest_city(DECIMAL, DECIMAL, INTEGER) IS
'Encuentra la ciudad más cercana a coordenadas GPS. Max 50km de distancia por defecto.';

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================

-- Habilitar RLS
ALTER TABLE countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;

-- Políticas: Todos pueden leer (datos públicos)
CREATE POLICY "Países públicos" ON countries FOR SELECT USING (true);
CREATE POLICY "Regiones públicas" ON regions FOR SELECT USING (true);
CREATE POLICY "Ciudades públicas" ON cities FOR SELECT USING (true);

-- =====================================================
-- PERMISOS: service_role (Para importación de datos)
-- =====================================================

-- Otorgar permisos completos al rol service_role
-- Necesario para que scripts Python puedan insertar datos
GRANT ALL ON TABLE countries TO service_role;
GRANT ALL ON TABLE regions TO service_role;
GRANT ALL ON TABLE cities TO service_role;
GRANT USAGE ON SCHEMA public TO service_role;

-- =====================================================
-- RESUMEN
-- =====================================================
-- ✅ Tablas: countries, regions, cities
-- ✅ Índices: Nombre, GeoName ID, Coordenadas
-- ✅ Extensiones: pg_trgm (búsqueda), earthdistance (geo)
-- ✅ Funciones: search_cities(), find_nearest_city()
-- ✅ RLS: Habilitado, lectura pública
--
-- SIGUIENTES PASOS:
-- 1. Poblar con datos reales (seed o script Python)
-- 2. Actualizar repositorio Flutter para usar estas tablas
-- 3. Reemplazar MockLocationRepository con SupabaseLocationRepository
