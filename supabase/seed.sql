-- =====================================================
-- SEED: Datos Maestros - Colombia
-- =====================================================
-- Contiene país y regiones (departamentos)
-- Las ciudades se poblan con script Python
-- =====================================================

-- =====================================================
-- PAÍSES: América Latina + España + USA
-- =====================================================
-- Datos maestros iniciales para la app
-- Más países se pueden agregar después según necesidad
-- =====================================================

INSERT INTO countries (id, code, name, local_name, capital, population, phone_prefix, currency, languages, lat, lon) VALUES
-- Colombia (país principal MVP)
('CO', 'CO', 'Colombia', 'Colombia', 'Bogotá', 51049000, '+57', 'COP', ARRAY['es'], 4.570868, -74.297333),

-- Otros países América Latina
('MX', 'MX', 'Mexico', 'México', 'Ciudad de México', 128932000, '+52', 'MXN', ARRAY['es'], 23.634501, -102.552784),
('AR', 'AR', 'Argentina', 'Argentina', 'Buenos Aires', 45195777, '+54', 'ARS', ARRAY['es'], -38.416097, -63.616672),
('CL', 'CL', 'Chile', 'Chile', 'Santiago', 19116209, '+56', 'CLP', ARRAY['es'], -35.675147, -71.542969),
('PE', 'PE', 'Peru', 'Perú', 'Lima', 32971846, '+51', 'PEN', ARRAY['es'], -9.189967, -75.015152),
('VE', 'VE', 'Venezuela', 'Venezuela', 'Caracas', 28435943, '+58', 'VES', ARRAY['es'], 6.42375, -66.58973),
('EC', 'EC', 'Ecuador', 'Ecuador', 'Quito', 17643060, '+593', 'USD', ARRAY['es'], -1.831239, -78.183406),
('BO', 'BO', 'Bolivia', 'Bolivia', 'Sucre', 11673029, '+591', 'BOB', ARRAY['es', 'qu', 'ay'], -16.290154, -63.588653),

-- España (hispanohablantes)
('ES', 'ES', 'Spain', 'España', 'Madrid', 47351567, '+34', 'EUR', ARRAY['es', 'ca', 'gl', 'eu'], 40.463667, -3.74922),

-- Estados Unidos (expatriados)
('US', 'US', 'United States', 'United States', 'Washington, D.C.', 331449281, '+1', 'USD', ARRAY['en'], 37.09024, -95.712891)

ON CONFLICT (id) DO NOTHING;  -- Idempotente (no falla si ya existen)

-- =====================================================
-- REGIONES: 33 Departamentos + Bogotá D.C.
-- =====================================================
-- Códigos admin1_code de GeoNames (NO son códigos DANE)
-- Estos códigos coinciden con el campo admin1_code del archivo CO.txt
-- =====================================================

INSERT INTO regions (id, country_id, geoname_id, name, type, code) VALUES
-- Departamentos (orden alfabético)
('co-amazonas', 'CO', 3689982, 'Amazonas', 'department', '01'),
('co-antioquia', 'CO', 3689815, 'Antioquia', 'department', '02'),
('co-arauca', 'CO', 3689797, 'Arauca', 'department', '03'),
('co-atlantico', 'CO', 3689560, 'Atlántico', 'department', '04'),
('co-bolivar', 'CO', 3687029, 'Bolívar', 'department', '05'),
('co-boyaca', 'CO', 3686883, 'Boyacá', 'department', '06'),
('co-caldas', 'CO', 3686636, 'Caldas', 'department', '07'),
('co-caqueta', 'CO', 3686513, 'Caquetá', 'department', '08'),
('co-casanare', 'CO', 3686470, 'Casanare', 'department', '09'),
('co-cauca', 'CO', 3686451, 'Cauca', 'department', '10'),
('co-cesar', 'CO', 3686261, 'Cesar', 'department', '11'),
('co-choco', 'CO', 3686170, 'Chocó', 'department', '12'),
('co-cordoba', 'CO', 3685964, 'Córdoba', 'department', '13'),
('co-cundinamarca', 'CO', 3685895, 'Cundinamarca', 'department', '25'),
('co-guainia', 'CO', 3681652, 'Guainía', 'department', '14'),
('co-guaviare', 'CO', 3681344, 'Guaviare', 'department', '15'),
('co-huila', 'CO', 3680656, 'Huila', 'department', '16'),
('co-la-guajira', 'CO', 3680387, 'La Guajira', 'department', '17'),
('co-magdalena', 'CO', 3675812, 'Magdalena', 'department', '18'),
('co-meta', 'CO', 3674453, 'Meta', 'department', '19'),
('co-narino', 'CO', 3672486, 'Nariño', 'department', '20'),
('co-norte-de-santander', 'CO', 3672112, 'Norte de Santander', 'department', '21'),
('co-putumayo', 'CO', 3670880, 'Putumayo', 'department', '22'),
('co-quindio', 'CO', 3670689, 'Quindío', 'department', '23'),
('co-risaralda', 'CO', 3670419, 'Risaralda', 'department', '24'),
('co-san-andres-y-providencia', 'CO', 3668605, 'San Andrés y Providencia', 'department', '26'),
('co-santander', 'CO', 3668285, 'Santander', 'department', '27'),
('co-sucre', 'CO', 3667672, 'Sucre', 'department', '28'),
('co-tolima', 'CO', 3667418, 'Tolima', 'department', '29'),
('co-valle-del-cauca', 'CO', 3666646, 'Valle del Cauca', 'department', '30'),
('co-vaupes', 'CO', 3666576, 'Vaupés', 'department', '31'),
('co-vichada', 'CO', 3666570, 'Vichada', 'department', '32'),

-- Distrito Capital
('co-bogota', 'CO', 3688689, 'Bogotá D.C.', 'district', '34')

ON CONFLICT (id) DO NOTHING;  -- Idempotente (no falla si ya existen)

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

DO $$
DECLARE
  country_count INTEGER;
  region_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO country_count FROM countries;
  SELECT COUNT(*) INTO region_count FROM regions;

  RAISE NOTICE '';
  RAISE NOTICE '✅ Seed completado:';
  RAISE NOTICE '   - Países: %', country_count;
  RAISE NOTICE '   - Regiones: %', region_count;
  RAISE NOTICE '   - Ciudades: 0 (se importan con script Python)';
  RAISE NOTICE '';
END $$;
