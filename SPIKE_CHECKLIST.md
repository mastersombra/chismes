# ✅ Checklist del Spike de Validación

Marca cada paso conforme lo completes:

## 🏗️ Setup de Supabase

- [ ] Organización creada en Supabase
- [ ] Proyecto `chismes-dev` creado
- [ ] Región: South America (São Paulo)
- [ ] Database password guardado en lugar seguro

## 📊 Base de Datos

- [ ] SQL Editor abierto en Supabase Dashboard
- [ ] Migración `001_create_gossips_table.sql` ejecutada
- [ ] Mensaje "Success. No rows returned" ✅
- [ ] Migración `002_insert_sample_data.sql` ejecutada
- [ ] Mensaje "Rows fetched: 3" ✅
- [ ] Tabla `gossips` visible en Table Editor
- [ ] 3 chismes de ejemplo visibles en la tabla

## 🔑 Credenciales

- [ ] Project URL copiado desde Settings > API
- [ ] Anon Key copiado (el largo que empieza con `eyJhbGc...`)
- [ ] Archivo `.env` creado en raíz del proyecto
- [ ] URL y Key pegados en `.env`
- [ ] Archivo `.env` NO está en git (verificar con `git status`)

## 💻 Código Flutter

- [ ] `flutter pub get` ejecutado sin errores
- [ ] Archivo `gossip_module.dart` editado: `_useSupabase = true`
- [ ] App ejecutándose con `flutter run`
- [ ] Sin errores en consola sobre Supabase

## 🧪 Pruebas de Integración

### Test 1: Leer chismes (GET)
- [ ] Pestaña "Inicio" abierta en la app
- [ ] 3 chismes visibles:
  - [ ] "Vieron a Shakira en El Poblado"
  - [ ] "Maluma grabando en La Candelaria"
  - [ ] "J Balvin en el aeropuerto"

### Test 2: Crear chisme (POST)
- [ ] Pestaña "Agregar" (➕) abierta
- [ ] Formulario llenado:
  - [ ] País: Colombia
  - [ ] Región: Antioquia
  - [ ] Ciudad: Medellín
  - [ ] Asunto: "Prueba desde Flutter"
  - [ ] Contenido: "Este chisme viene desde la app móvil"
- [ ] Botón "Publicar" presionado
- [ ] Diálogo de éxito apareció
- [ ] Sin errores en consola

### Test 3: Verificar en Supabase
- [ ] Supabase Dashboard > Table Editor > gossips abierto
- [ ] Tabla refrescada (F5 o botón refresh)
- [ ] Nuevo chisme visible con asunto "Prueba desde Flutter"
- [ ] Campos correctos:
  - [ ] `country_id = 'co'`
  - [ ] `city_id = 'medellin'`
  - [ ] `status = 'published'`
  - [ ] `created_at` tiene timestamp reciente

## 🎉 Validación Exitosa

- [ ] Los 3 tests pasaron ✅
- [ ] Arquitectura Clean funciona con Supabase ✅
- [ ] Listo para continuar con otros módulos ✅

## 🔄 Cleanup

- [ ] `gossip_module.dart` editado: `_useSupabase = false`
- [ ] App reiniciada
- [ ] Usando mocks de nuevo para desarrollo rápido

---

## 📝 Notas / Problemas encontrados

```
Escribe aquí cualquier problema que encontraste y cómo lo resolviste:




```

---

**Tiempo estimado**: 30-45 minutos  
**Fecha de inicio**: _________  
**Fecha de fin**: _________  
**Estado**: [ ] En progreso  [ ] Completado
