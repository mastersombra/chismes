# 🔄 Setup: Reset Completo de Base de Datos

Script automatizado para resetear la base de datos, deployar Edge Functions y poblar datos iniciales.

**Tiempo estimado:** 5-10 minutos

---

## 🚀 **EJECUCIÓN RÁPIDA**

```bash
./scripts/reset-database.sh
```

---

## 📋 **QUÉ HACE EL SCRIPT**

### **1. Verificación de prerrequisitos**
- ✅ Supabase CLI instalado
- ✅ Python 3 instalado
- ✅ Proyecto linkeado
- ✅ Archivo GeoNames disponible
- ✅ Script de importación disponible

### **2. Reset de base de datos**
```bash
supabase db reset --linked
```
- Elimina TODOS los datos actuales
- Reaplica todas las migraciones (001-009)
- Ejecuta seeds (países iniciales)

### **3. Deploy de Edge Functions**
- Encuentra todas las funciones en `supabase/functions/`
- Deploy automático de cada una
- Ejemplo: `cleanup-idempotency`

### **4. Configuración de cron (manual)**
- Script muestra instrucciones
- **Se debe configurar desde Dashboard** (la CLI no lo soporta aún)
- Ver: `CONFIGURE_CRON.md` para pasos detallados

### **5. Importación de ciudades de GeoNames**
```bash
python3 scripts/import_geonames.py \
  --country CO \
  --file /Users/alejo/Desktop/CO/CO.txt \
  --min-population 500
```
- Importa ciudades de Colombia
- Población mínima: 500 habitantes
- Incluye regiones automáticamente

---

## 📁 **PRERREQUISITOS**

### **1. Archivo GeoNames**

**Ubicación esperada:** `/Users/alejo/Desktop/CO/CO.txt`

**Si no lo tienes:**
```bash
# Descargar desde GeoNames
wget http://download.geonames.org/export/dump/CO.zip

# Extraer
unzip CO.zip

# Mover a ubicación esperada
mv CO.txt /Users/alejo/Desktop/CO/CO.txt
```

**O cambiar ruta en el script:**
```bash
# Editar scripts/reset-database.sh línea ~40
GEONAMES_FILE="/tu/ruta/personalizada/CO.txt"
```

### **2. Script de importación**

**Ubicación:** `scripts/import_geonames.py`

**Verificar que existe:**
```bash
ls -lh scripts/import_geonames.py
```

### **3. Supabase linkeado**

```bash
# Verificar
cat .supabase/config.toml

# Si no está linkeado
supabase link --project-ref <your-project-id>
```

---

## ⚠️ **ADVERTENCIA**

Este script **ELIMINA TODOS LOS DATOS** de la base de datos:
- ❌ Todos los gossips
- ❌ Todas las ubicaciones existentes
- ❌ Todos los perfiles
- ❌ Todos los logs

**Úsalo solo en:**
- ✅ Desarrollo local
- ✅ Testing
- ✅ Reset después de cambios en migraciones
- ❌ **NUNCA en producción**

---

## 📊 **SALIDA ESPERADA**

```
🔄 Iniciando reset completo de base de datos...

📋 Verificando prerrequisitos...
✅ Supabase CLI instalado
✅ Python 3 instalado
✅ Proyecto linkeado
✅ Archivo GeoNames encontrado
✅ Script de importación encontrado

⚠️  ADVERTENCIA: Esta operación:
   - Eliminará TODOS los datos de la base de datos
   - Reaplicará todas las migraciones
   - Reaplicará todos los seeds
   - Redeployará todas las Edge Functions

¿Estás seguro de continuar? (y/n): y

🗄️  Reseteando base de datos...
Applying migration 001_create_gossips_table.sql...
Applying migration 002_create_location_tables.sql...
...
Applying migration 009_remove_idempotency_cleanup_trigger.sql...
Seeding data...
✅ Base de datos reseteada

📦 Deploying Edge Functions...
Funciones encontradas:
  - cleanup-idempotency

Deploying cleanup-idempotency...
✅ cleanup-idempotency deployed

⏰ Configuración de cron para Edge Functions...
✅ cleanup-idempotency deployed correctamente

📝 ACCIÓN REQUERIDA: Programar cron desde Dashboard

   1. Ve a: https://supabase.com/dashboard/...
   2. Selecciona 'cleanup-idempotency'
   3. Configura cron: 0 3 * * *
   
   Ver guía completa en: CONFIGURE_CRON.md

🌍 Importando ciudades de GeoNames...
Ejecutando:
  python3 scripts/import_geonames.py \
    --country CO \
    --file /Users/alejo/Desktop/CO/CO.txt \
    --min-population 500

Processing: CO.txt
  Filtering cities with population >= 500
  Found 1,234 cities matching criteria
  Importing to Supabase...
  [####################] 1,234/1,234 cities imported
✅ Ciudades importadas

🔍 Verificando configuración...
Edge Functions:
NAME                 CRON           LAST DEPLOYED
cleanup-idempotency  0 3 * * *      2026-10-22 03:00 UTC

Verificando datos en base de datos...
countries: 1
regions: 32
cities: 1234
triggers: 4
indexes: 8

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 ¡RESET COMPLETADO!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Base de datos reseteada (migraciones + seeds aplicados)
✅ Edge Functions deployed
✅ Ciudades importadas de GeoNames
```

---

## 🔍 **VERIFICACIÓN POST-RESET**

### **1. Verificar países**

```sql
SELECT * FROM location_countries;
```

**Esperado:** 1 país (Colombia)

### **2. Verificar regiones**

```sql
SELECT COUNT(*) FROM location_regions;
SELECT * FROM location_regions ORDER BY name LIMIT 5;
```

**Esperado:** ~32 departamentos de Colombia

### **3. Verificar ciudades**

```sql
SELECT COUNT(*) FROM location_cities;
SELECT * FROM location_cities ORDER BY population DESC LIMIT 10;
```

**Esperado:** Número de ciudades según población mínima (ej: 1,234 con min 500)

**Top ciudades:**
- Bogotá
- Medellín
- Cali
- Barranquilla
- Cartagena
- ...

### **4. Verificar Edge Functions**

```bash
supabase functions list
```

**Esperado:**
```
NAME                 CRON           LAST DEPLOYED
cleanup-idempotency  0 3 * * *      2026-10-22 03:00 UTC
```

### **5. Verificar trigger eliminado**

```sql
SELECT * FROM pg_trigger WHERE tgname = 'gossips_cleanup_old_idempotency_keys';
```

**Esperado:** 0 rows (trigger eliminado por migración 009)

### **6. Verificar índice parcial creado**

```sql
SELECT * FROM pg_indexes WHERE indexname = 'idx_gossips_idempotency_cleanup';
```

**Esperado:** 1 row (índice creado por migración 009)

---

## 🛠️ **TROUBLESHOOTING**

### **Problema: Archivo GeoNames no encontrado**

```
⚠️  Advertencia: Archivo GeoNames no encontrado en /Users/alejo/Desktop/CO/CO.txt
   Se omitirá la importación de ciudades
```

**Solución:**
1. Descargar archivo de GeoNames
2. Moverlo a la ruta esperada
3. O editar el script para usar tu ruta

### **Problema: Script de importación no encontrado**

```
⚠️  Advertencia: Script de importación no encontrado en scripts/import_geonames.py
   Se omitirá la importación de ciudades
```

**Solución:**
Verificar que el script existe:
```bash
ls -lh scripts/import_geonames.py
```

### **Problema: Error al deployar Edge Function**

```
⚠️  Error deploying cleanup-idempotency (continuando...)
```

**Solución:**
1. Verificar que el archivo existe: `supabase/functions/cleanup-idempotency/index.ts`
2. Verificar sintaxis TypeScript
3. Ver logs: `supabase functions logs cleanup-idempotency`

### **Problema: Error de permisos**

```
Error: permission denied
```

**Solución:**
```bash
chmod +x scripts/reset-database.sh
```

### **Problema: No está linkeado**

```
❌ Error: Proyecto no está linkeado
```

**Solución:**
```bash
supabase link --project-ref <your-project-id>
```

---

## 🔧 **OPCIONES DE PERSONALIZACIÓN**

### **Cambiar población mínima**

Editar línea ~200 del script:
```bash
python3 "$IMPORT_SCRIPT" \
    --country CO \
    --file "$GEONAMES_FILE" \
    --min-population 1000  # ← Cambiar aquí (default: 500)
```

**Ejemplos:**
- `--min-population 0` → Todas las ciudades (~5,000)
- `--min-population 500` → Ciudades medianas+ (~1,200)
- `--min-population 5000` → Ciudades grandes (~200)
- `--min-population 50000` → Ciudades principales (~30)

### **Cambiar archivo GeoNames**

Editar línea ~40 del script:
```bash
GEONAMES_FILE="/tu/ruta/personalizada/CO.txt"
```

### **Omitir importación de ciudades**

Si no tienes el archivo o no quieres importar:
```bash
# El script detecta automáticamente y omite si:
# - No existe el archivo GeoNames
# - No existe el script de importación
```

### **Cambiar horario de limpieza**

Editar línea ~180 del script:
```bash
supabase functions schedule cleanup-idempotency --cron "0 2 * * *"  # 2 AM
```

---

## 📚 **ARCHIVOS RELACIONADOS**

- **Script principal:** `scripts/reset-database.sh`
- **Script de importación:** `scripts/import_geonames.py`
- **Migraciones:** `supabase/migrations/*.sql`
- **Seeds:** `supabase/seed.sql`
- **Edge Functions:** `supabase/functions/*/index.ts`

---

## 📖 **DOCUMENTACIÓN ADICIONAL**

- **Refactor P6:** `docs/REFACTOR_P6_FEED_PAGINATION_MEDIA.md`
- **Análisis idempotency:** `docs/ANALYSIS_P6_IDEMPOTENCY_OPTIONS.md`
- **Edge Functions:** `supabase/functions/README.md`

---

## ✅ **CHECKLIST**

Antes de ejecutar el script:

- [ ] Backup de datos importantes (si es necesario)
- [ ] Supabase CLI instalado y actualizado
- [ ] Python 3 instalado
- [ ] Proyecto linkeado (`supabase link`)
- [ ] Archivo GeoNames descargado (opcional)
- [ ] Script ejecutable (`chmod +x scripts/reset-database.sh`)

Después de ejecutar:

- [ ] Verificar países (1 país)
- [ ] Verificar regiones (~32 regiones)
- [ ] Verificar ciudades (según población mínima)
- [ ] Verificar Edge Functions programadas
- [ ] Verificar trigger eliminado
- [ ] Verificar índice parcial creado

---

## 🎯 **USO TÍPICO**

```bash
# Desarrollo diario: reset rápido después de cambios en migraciones
./scripts/reset-database.sh

# Testing: reset antes de ejecutar tests de integración
./scripts/reset-database.sh && flutter test test/integration/

# CI/CD: reset en pipeline
./scripts/reset-database.sh --non-interactive  # (próxima versión)
```

---

**¡Listo para resetear la base de datos! 🚀**

```bash
./scripts/reset-database.sh
```
