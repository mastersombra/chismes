# Spike de Validación Supabase

## Objetivo

Validar que la arquitectura Clean de Flutter funciona perfectamente con Supabase antes de construir todos los módulos.

## Paso a paso

### 1. Ejecutar migraciones en Supabase

#### Opción A: SQL Editor (más rápido para spike)

1. Ve a tu proyecto en Supabase Dashboard
2. Click en "SQL Editor" en el menú lateral
3. Click en "New query"
4. Copia y pega el contenido de `migrations/001_create_gossips_table.sql`
5. Click en "Run" (▶️)
6. Verifica que la tabla se creó en "Table Editor"
7. Repite para `002_insert_sample_data.sql`

#### Opción B: Supabase CLI (opcional, para después)

```bash
# Instalar CLI
npm install -g supabase

# Login
supabase login

# Link al proyecto
supabase link --project-ref your-project-ref

# Aplicar migraciones
supabase db push
```

### 2. Verificar datos en Dashboard

1. Ve a "Table Editor" > "gossips"
2. Debes ver 3 chismes de ejemplo
3. Verifica que tienen:
   - ✅ ID (UUID)
   - ✅ subject, content
   - ✅ country_id, region_id, city_id
   - ✅ status = 'published'
   - ✅ created_at (timestamp)

### 3. Obtener credenciales

1. Ve a "Settings" > "API"
2. Copia:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon / public key**: `eyJhbGc...` (el key largo)

### 4. Configurar .env

Crea el archivo `.env` en la raíz del proyecto:

```bash
# .env
SUPABASE_URL=https://tu-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**⚠️ IMPORTANTE**: NO subas este archivo a git (ya está en .gitignore)

### 5. Probar desde Flutter

```bash
# Instalar dependencias
flutter pub get

# Ejecutar app
flutter run
```

## Queries de prueba en Supabase SQL Editor

```sql
-- Ver todos los chismes
SELECT * FROM gossips ORDER BY created_at DESC;

-- Ver chismes de Medellín
SELECT subject, content, created_at
FROM gossips
WHERE city_id = 'medellin'
ORDER BY created_at DESC;

-- Ver chismes anónimos
SELECT subject, published_as
FROM gossips
WHERE published_as = 'anonymous';

-- Contar chismes por ciudad
SELECT city_id, COUNT(*) as total
FROM gossips
GROUP BY city_id;
```

## Verificación exitosa ✅

El spike está completo cuando:

1. ✅ Tabla gossips creada en Supabase
2. ✅ Datos de ejemplo visibles en Dashboard
3. ✅ Flutter puede leer los 3 chismes
4. ✅ Flutter puede crear 1 chisme nuevo
5. ✅ El chisme nuevo aparece en Supabase Dashboard

## Rollback (si algo falla)

```sql
-- Eliminar la tabla y empezar de nuevo
DROP TABLE IF EXISTS gossips CASCADE;
```

Luego re-ejecuta `001_create_gossips_table.sql`

## Próximos pasos

Una vez validado:
- Volver a usar mocks para desarrollo rápido
- Construir otros módulos (perfil, búsqueda, feed)
- Integración completa cuando todo esté listo
