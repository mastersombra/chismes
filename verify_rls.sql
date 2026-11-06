-- Verificar estado de RLS en la tabla gossips
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'gossips';

-- Ver las políticas activas
SELECT * FROM pg_policies WHERE tablename = 'gossips';
