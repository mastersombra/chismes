# 🛠️ Scripts Útiles

Scripts de automatización para el proyecto Chismes.

---

## 📜 **Scripts Disponibles**

### **reset-database.sh** ⭐

Reset completo de la base de datos con importación de datos.

**Uso:**
```bash
./scripts/reset-database.sh
```

**Qué hace:**
1. ✅ Reset de base de datos (elimina todos los datos)
2. ✅ Reaplica todas las migraciones (001-009)
3. ✅ Ejecuta seeds (países iniciales)
4. ✅ Deploy de Edge Functions
5. ✅ Programa cron jobs (cleanup a las 3 AM)
6. ✅ Importa ciudades de GeoNames (Colombia, población ≥ 500)

**Cuándo usar:**
- Desarrollo: después de cambios en migraciones
- Testing: antes de tests de integración
- Setup inicial del proyecto

**Documentación completa:** `../SETUP_DATABASE.md`

---

### **import_geonames.py**

Importa ciudades desde archivos GeoNames a Supabase.

**Uso:**
```bash
python3 scripts/import_geonames.py \
  --country CO \
  --file /Users/alejo/Desktop/CO/CO.txt \
  --min-population 500
```

**Parámetros:**
- `--country`: Código ISO del país (ej: CO, BR, PE)
- `--file`: Ruta al archivo GeoNames
- `--min-population`: Población mínima (default: 0)

**Cuándo usar:**
- Lo ejecuta automáticamente `reset-database.sh`
- Puedes ejecutarlo manualmente para re-importar ciudades

---

## 🚀 **Quick Start**

### **Setup inicial completo**

```bash
# 1. Linkear proyecto (solo primera vez)
supabase link --project-ref <your-project-id>

# 2. Reset completo
./scripts/reset-database.sh
```

### **Reset rápido (desarrollo)**

```bash
# Durante desarrollo, después de cambiar migraciones
./scripts/reset-database.sh
```

---

## 📋 **Prerrequisitos**

### **Para reset-database.sh:**

- ✅ Supabase CLI instalado
- ✅ Python 3 instalado
- ✅ Proyecto linkeado
- ⚠️ Archivo GeoNames (opcional): `/Users/alejo/Desktop/CO/CO.txt`

### **Para import_geonames.py:**

- ✅ Python 3 instalado
- ✅ Archivo GeoNames descargado
- ✅ Variables de entorno configuradas (`.env`)

---

## 📥 **Descargar Archivos GeoNames**

```bash
# Descargar Colombia
wget http://download.geonames.org/export/dump/CO.zip
unzip CO.zip

# Mover a ubicación esperada
mkdir -p /Users/alejo/Desktop/CO
mv CO.txt /Users/alejo/Desktop/CO/CO.txt
```

**Otros países:**
- Brasil: `http://download.geonames.org/export/dump/BR.zip`
- Perú: `http://download.geonames.org/export/dump/PE.zip`
- Ecuador: `http://download.geonames.org/export/dump/EC.zip`

---

## 🔧 **Personalización**

### **Cambiar población mínima**

Editar `reset-database.sh` línea ~200:
```bash
--min-population 1000  # En lugar de 500
```

### **Cambiar ruta de GeoNames**

Editar `reset-database.sh` línea ~40:
```bash
GEONAMES_FILE="/tu/ruta/personalizada/CO.txt"
```

### **Omitir importación de ciudades**

El script detecta automáticamente si el archivo no existe y omite la importación.

---

## 🛠️ **Troubleshooting**

### **Script no ejecuta**

```bash
# Hacer ejecutable
chmod +x scripts/reset-database.sh
```

### **Archivo GeoNames no encontrado**

```
⚠️  Advertencia: Archivo GeoNames no encontrado
   Se omitirá la importación de ciudades
```

**Solución:**
1. Descargar archivo de GeoNames
2. Moverlo a `/Users/alejo/Desktop/CO/CO.txt`
3. O editar el script para usar tu ruta

### **Python no encuentra módulos**

```bash
# Instalar dependencias
pip3 install python-dotenv
```

---

## 📚 **Documentación**

- **Setup completo:** `../SETUP_DATABASE.md`
- **Refactor P6:** `../docs/REFACTOR_P6_FEED_PAGINATION_MEDIA.md`
- **Edge Functions:** `../supabase/functions/README.md`

---

**¿Dudas?** Lee `../SETUP_DATABASE.md` para documentación completa.
