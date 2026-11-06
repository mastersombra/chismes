# 🚀 Guía de Setup del Spike de Validación Supabase

## ✅ Archivos ya creados

He preparado todo el código necesario. Ya tienes:

- ✅ `.env.example` - Template de configuración
- ✅ `.gitignore` actualizado (protege .env)
- ✅ `pubspec.yaml` con dependencias de Supabase
- ✅ `lib/core/config/supabase_config.dart` - Configuración
- ✅ `lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart` - Implementación
- ✅ `lib/features/gossip/di/gossip_module.dart` - Toggle mock/supabase
- ✅ `lib/main.dart` - Inicialización
- ✅ `supabase/migrations/` - Scripts SQL
- ✅ `supabase/README_SPIKE.md` - Instrucciones detalladas

## 📋 Pasos a seguir (30-45 minutos)

### PASO 1: Completar setup de Supabase (10 min)

1. **Termina de crear tu proyecto en Supabase**
   - Organización: Ya creada ✅
   - Proyecto: Créalo si no lo has hecho
   - Nombre: `chismes-dev`
   - Región: South America (São Paulo)
   - Database password: Guárdalo bien

2. **Espera ~2 minutos** mientras Supabase crea la infraestructura

### PASO 2: Ejecutar migraciones SQL (5 min)

1. Ve a tu proyecto en Supabase Dashboard
2. Click en **"SQL Editor"** en el menú lateral izquierdo
3. Click en **"New query"**
4. Abre el archivo `supabase/migrations/001_create_gossips_table.sql`
5. Copia TODO el contenido y pégalo en el editor SQL
6. Click en **"Run"** (botón ▶️ verde)
7. Debe decir "Success. No rows returned" ✅

8. Repite para el segundo archivo:
   - New query
   - Copia `supabase/migrations/002_insert_sample_data.sql`
   - Run
   - Debe decir "Rows fetched: 3" ✅

9. Verifica en **"Table Editor"** > tabla **"gossips"**
   - Debes ver 3 chismes de ejemplo

### PASO 3: Obtener credenciales (2 min)

1. Ve a **"Settings"** (engranaje ⚙️) > **"API"**
2. Copia dos cosas:

   **Project URL**:
   ```
   https://xxxxxxxxx.supabase.co
   ```

   **anon / public key** (la larga que empieza con `eyJhbGc...`):
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJz...
   ```

### PASO 4: Configurar .env (2 min)

1. En la raíz del proyecto, crea el archivo `.env`
2. Copia el contenido de `.env.example`
3. Reemplaza con tus credenciales reales:

```bash
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

⚠️ **IMPORTANTE**: El archivo `.env` NO se sube a git (ya está en .gitignore)

### PASO 5: Instalar dependencias (2 min)

```bash
flutter pub get
```

### PASO 6: Activar Supabase en el código (1 min)

Abre `lib/features/gossip/di/gossip_module.dart` y cambia:

```dart
static const bool _useSupabase = true; // ← Cambiar de false a true
```

### PASO 7: Ejecutar la app (2 min)

```bash
flutter run
```

### PASO 8: Probar la integración (5 min)

1. **Ver chismes existentes (READ)**
   - Ve a la pestaña "Inicio" en la app
   - Debes ver los 3 chismes de ejemplo de Supabase ✅

2. **Crear nuevo chisme (CREATE)**
   - Ve a la pestaña "Agregar" (➕)
   - Llena el formulario:
     - País: Colombia
     - Región: Antioquia
     - Ciudad: Medellín
     - Asunto: "Prueba desde Flutter"
     - Contenido: "Este chisme viene desde la app móvil"
   - Click en "Publicar"
   - Debe aparecer un diálogo de éxito ✅

3. **Verificar en Supabase Dashboard**
   - Ve a Table Editor > gossips
   - Refresca la tabla
   - Debes ver el nuevo chisme que acabas de crear ✅

## 🎉 ¡Spike exitoso!

Si completaste los 3 pasos de prueba, ¡tu arquitectura Clean está perfectamente integrada con Supabase!

### ✅ Qué acabas de validar:

1. Tu `GossipRepository` funciona con Supabase
2. Tu `GossipQuery` con filtros funciona
3. La conversión Entity ↔ DTO es correcta
4. Supabase puede leer y escribir datos desde Flutter
5. El toggle mock/supabase funciona perfectamente

## 🔄 Volver a desarrollo con mocks

Una vez validado, vuelve a usar mocks para desarrollo rápido:

1. Abre `lib/features/gossip/di/gossip_module.dart`
2. Cambia:
   ```dart
   static const bool _useSupabase = false; // ← Volver a false
   ```
3. Reinicia la app
4. Ahora estás usando mocks de nuevo (más rápido para desarrollo)

## 🐛 Troubleshooting

### Error: "Failed to load .env"
- Verifica que el archivo `.env` existe en la raíz del proyecto
- Verifica que está en `assets:` en `pubspec.yaml`
- Ejecuta `flutter clean && flutter pub get`

### Error: "Invalid JWT"
- Verifica que copiaste el ANON KEY completo (es muy largo)
- No copies el Service Role Key (ese es para backend)

### Error: "Table gossips does not exist"
- Ve a Supabase Dashboard > SQL Editor
- Ejecuta las migraciones SQL nuevamente

### No aparecen los chismes en la app
- Verifica que `_useSupabase = true` en gossip_module.dart
- Verifica la conexión a internet
- Mira los logs en la consola de Flutter
- Verifica en Supabase Dashboard que existen chismes con:
  - `status = 'published'`
  - `moderation_status = 'approved'`
  - `visibility = 'public'`

### Error al crear chisme
- Mira los logs en la consola de Flutter
- Ve a Supabase Dashboard > Logs > Database
- Busca errores de constraint (subject/content muy largos, etc.)

## 📞 ¿Necesitas ayuda?

Si te atoras en algún paso, avísame con:
1. En qué paso estás
2. Qué error ves (screenshot o logs)
3. Lo que intentaste hacer

¡Mucha suerte! 🚀
