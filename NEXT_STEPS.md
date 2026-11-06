# ✅ COMPLETADO: Migration 003 Aplicada

La migration de tablas de ubicación se aplicó correctamente en Supabase.

---

## 🎯 Siguiente Paso: Ejecutar Seed (2 minutos)

### Opción 1: Desde Supabase Dashboard (RECOMENDADO)

1. **Ir a SQL Editor:**
   https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/sql

2. **Abrir archivo seed:**
   ```bash
   open /Users/alejo/Documents/Piloto/chismes/supabase/seed_colombia_locations.sql
   ```

3. **Copiar TODO el contenido** (Cmd+A, Cmd+C)

4. **Pegar en SQL Editor** y click **"Run"**

5. **Verificar output:**
   ```
   ✅ Seed completado:
      - Países: 1
      - Regiones: 9
      - Ciudades: 35
   ```

---

### Opción 2: Desde Terminal (Alternativa)

Si tienes `psql` instalado:

```bash
# Ver la connection string
supabase db remote show --linked

# Ejecutar seed
psql "tu_connection_string" < supabase/seed_colombia_locations.sql
```

---

## 📋 Después del Seed

### 1. Verificar Datos en Supabase

Ir a: https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/editor

**Verificar tablas:**
- `countries`: 1 registro ✅
- `regions`: 9 registros ✅
- `cities`: 35 ciudades ✅

---

### 2. Importar Dataset Completo (1,143 ciudades)

```bash
cd /Users/alejo/Documents/Piloto/chismes

# Activar virtual environment
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r scripts/requirements.txt

# IMPORTANTE: Agregar a .env
echo "SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key" >> .env

# Importar ciudades
python scripts/import_geonames.py \
  --country CO \
  --file /Users/alejo/Desktop/CO \
  --min-population 500
```

**¿Dónde encontrar Service Role Key?**
- https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/settings/api
- Copiar "service_role" key (NO la anon key)

---

### 3. Probar en Flutter

```bash
flutter clean
flutter pub get
flutter run
```

**Configurar GPS en emulador:**
- Android: Menu `⋮` → Location → `6.2518, -75.5636` (Medellín)
- iOS: Debug → Location → Custom Location → `6.2518, -75.5636`

**Resultado esperado:**
```
Abrir "Crear Chisme"
  ↓
Esperar 3-5 segundos
  ↓
Debe mostrar: [📍 Medellín, Antioquia] [Cambiar] ✅
```

---

## 🐛 Si algo falla

### Error al ejecutar seed

**Síntoma:** Error de sintaxis o foreign key

**Solución:**
- Verificar que migration 003 se aplicó correctamente
- Verificar que tablas existen: `countries`, `regions`, `cities`

---

### Script Python falla

**Error:** "País 'CO' no existe"

**Causa:** No ejecutaste el seed de países/regiones

**Solución:** Ejecutar seed primero (Paso 1 arriba)

---

**Error:** "Service role key not found"

**Causa:** Falta en `.env`

**Solución:** Agregar `SUPABASE_SERVICE_ROLE_KEY=...` al archivo `.env`

---

## 📚 Documentación

- `docs/SETUP_LOCATION_REPOSITORY.md` - Guía completa paso a paso
- `docs/IMPORT_GEONAMES_COLOMBIA.md` - Detalles de importación
- `docs/LOCATION_DATA_STRATEGY.md` - Estrategia general

---

## ✅ Checklist

- [x] Migration 003 aplicada
- [ ] Seed ejecutado (países + regiones + 35 ciudades)
- [ ] Dataset completo importado (1,143 ciudades)
- [ ] Probado en Flutter

---

**Siguiente acción:** Ejecutar seed desde Supabase Dashboard
