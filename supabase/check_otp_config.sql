-- Query para verificar configuración de OTP en Supabase
-- Ejecutar en: Supabase Dashboard → SQL Editor → New Query

-- 1. Ver configuración de Auth
SELECT * FROM auth.config;

-- 2. Ver variables de entorno relacionadas con OTP
-- (Nota: esto puede no funcionar en hosted Supabase, pero vale la pena intentar)
SHOW ALL;

-- 3. Ver la versión de GoTrue (indirectamente)
SELECT current_setting('app.settings.jwt_secret', true) as jwt_configured;

-- 4. Ver configuración de OTP desde pg_settings (si está disponible)
SELECT name, setting, unit, context, source
FROM pg_settings
WHERE name LIKE '%otp%' OR name LIKE '%token%';
