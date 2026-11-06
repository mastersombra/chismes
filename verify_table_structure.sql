-- Ver la estructura completa de la tabla gossips
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'gossips'
ORDER BY ordinal_position;

-- Ver los checks/constraints
SELECT
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'gossips';
