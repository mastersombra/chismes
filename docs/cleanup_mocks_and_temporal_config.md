# Limpieza: Mocks, Temporalidad y Configuración Pre-Producción

**Fecha:** 2026-10-22  
**Estado:** ✅ ANÁLISIS COMPLETADO  
**Objetivo:** Eliminar/documentar elementos temporales antes de producción

---

## 📋 ANÁLISIS DE ELEMENTOS

### 1. MockGossipRemoteDataSource

**Ubicación:** `lib/features/gossip/data/datasources/mock_gossip_data_source.dart`

**Estado Actual:** ✅ **YA DESACTIVADO**

**Evidencia:**
```dart
// Línea 19
// @Singleton(as: GossipRemoteDataSource) // ← DESACTIVADO: Usando Supabase
class MockGossipRemoteDataSource implements GossipRemoteDataSource {
```

**Verificación DI:**
```bash
grep -n "MockGossip" lib/core/di/injection_container.dart
# Resultado: (vacío) ✅ No está registrado
```

**Uso actual:**
- ❌ NO registrado en DI de producción
- ✅ Disponible solo para tests manuales
- ✅ Datos en memoria, no persisten

**Acción:** ✅ **NINGUNA** - Ya está correctamente aislado

**Recomendación:**
- Mantener para tests unitarios
- Agregar comentario de advertencia más visible

---

### 2. MockGossipLocalDataSource

**Ubicación:** `lib/features/gossip/data/datasources/mock_gossip_data_source.dart`

**Estado Actual:** ✅ **NUNCA REGISTRADO**

**Evidencia:**
```dart
// Línea 142
class MockGossipLocalDataSource implements GossipLocalDataSource {
  final Map<String, Map<String, dynamic>> _cache = {};
```

**Verificación DI:**
```bash
grep -n "MockGossip" lib/core/di/injection_container.dart
# Resultado: (vacío) ✅ No está registrado
```

**Uso actual:**
- ❌ NO registrado en DI
- ✅ Solo existe en archivo de mocks
- ✅ Se usa `SharedPrefsGossipLocalDataSource` en producción

**Acción:** ✅ **NINGUNA** - Correcto como está

---

### 3. MvpContentModerator

**Ubicación:** `lib/features/gossip/domain/services/mvp_content_moderator.dart`

**Estado Actual:** 🟡 **REGISTRADO PERO NO USADO EN PRODUCCIÓN**

**Evidencia:**
```dart
// injection_container.config.dart (generado)
() => _i110.MvpContentModerator(policy: gh<_i110.MvpModerationPolicy>()),
```

**Uso Real:**
- ✅ Edge Function `moderate-gossip` es la implementación activa
- 🟡 `MvpContentModerator` está registrado en DI pero NO se invoca desde cliente
- ✅ Cliente solo llama a Edge Function

**Flujo Real:**
```
Cliente → Edge Function → OpenAI Moderation API
                       ↓
                   Supabase Insert
```

**Problema:** El nombre `MvpContentModerator` puede confundir a desarrolladores futuros.

**Acción:** 🔧 **RENOMBRAR Y DOCUMENTAR**

---

### 4. spike-user y Políticas Permisivas

**Ubicación:** Múltiples archivos

#### 4.1 Referencias a spike-user

**Búsqueda:**
```bash
grep -r "spike-user" . --include="*.sql" --include="*.ts" --include="*.dart"
```

**Resultado:** ✅ **SOLO EN TESTS**

**Evidencia:**
```
test/security/edge_function_auth_test.dart     # Test que verifica NO aceptación
test/security/rls_policies_test.sql            # Test de limpieza
```

**Acción:** ✅ **NINGUNA** - Solo en tests como debe ser

---

#### 4.2 Políticas USING (true)

**Búsqueda:**
```bash
grep -n "USING (true)" supabase/migrations/*.sql
```

**Resultado:**

| Archivo | Línea | Política | Tabla | Operación | ¿Permisiva? |
|---------|-------|----------|-------|-----------|-------------|
| 002 | 246 | Países públicos | countries | SELECT | ✅ OK (read-only) |
| 002 | 247 | Regiones públicas | regions | SELECT | ✅ OK (read-only) |
| 002 | 248 | Ciudades públicas | cities | SELECT | ✅ OK (read-only) |
| 003 | 54 | Service role insert | error_logs | INSERT | ✅ OK (service_role only) |

**Análisis:**

1. **Países/Regiones/Ciudades:** ✅ **CORRECTO**
   - Solo lectura (SELECT)
   - Datos públicos (catálogos)
   - Sin riesgo de seguridad

2. **Error Logs:** ✅ **CORRECTO**
   - Solo INSERT
   - Solo para `service_role`
   - Edge Function usa esto

**Acción:** ✅ **NINGUNA** - Políticas correctas

---

### 5. Selectores de Imagen/Audio

#### 5.1 Selector de Imagen

**Estado Actual:** ✅ **IMPLEMENTADO Y FUNCIONAL**

**Evidencia:**
```dart
// add_gossip_screen.dart:159-165
ImagePickerWidget(
  imageUrl: imageUrl,
  isUploading: isUploading,
  onPickFromCamera: widget.controller.pickImageFromCamera,
  onPickFromGallery: widget.controller.pickImageFromGallery,
  onRemove: widget.controller.removeImage,
)
```

**Dependencia:** ✅ `image_picker: ^1.0.7` agregada (recién implementado)

**Flujo completo:**
- ✅ Usuario selecciona imagen
- ✅ Compresión local (800x800, JPEG 75%)
- ✅ Upload a `image-quarantine`
- ✅ Edge Function valida MIME
- ✅ Moderación con OpenAI
- ✅ Move a `image` bucket si aprobado

**Acción:** ✅ **NINGUNA** - Flujo seguro implementado

---

#### 5.2 Selector de Audio

**Búsqueda:**
```bash
find lib/features/gossip/presentation/widgets -name "*audio*"
# Resultado: (vacío) ✅

grep -rn "audio" lib/features/gossip/presentation/screens/add_gossip_screen.dart
# Resultado: (vacío) ✅
```

**Estado Actual:** ✅ **NO EXPUESTO EN UI**

**Evidencia:**
- ❌ No hay widgets de audio picker
- ❌ No hay referencias en `add_gossip_screen.dart`
- ✅ Backend soporta audio (Edge Function + quarantine)
- ✅ Controller tiene métodos pero no expuestos

**Acción:** ✅ **NINGUNA** - Correcto ocultar hasta implementar completo

---

### 6. .env con SERVICE_ROLE_KEY

**Ubicación:** `.env`

**Estado Actual:** ✅ **LIMPIO - NO CONTIENE SERVICE_ROLE**

**Evidencia:**
```bash
# .env (líneas 10-20)
# ⛔ NO incluir SERVICE_ROLE_KEY en aplicaciones móviles
# La service role bypasea RLS y debe usarse SOLO en:
#   - Edge Functions (Supabase Secrets)
#   - Scripts de backend/CLI
#   - CI/CD (variables de entorno seguras)
```

**Contenido actual:**
```env
SUPABASE_URL=https://njqamqcsldpmtbiqwbwo.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...  # ✅ Solo anon key (respeta RLS)
```

**Acción:** ✅ **NINGUNA** - Ya está seguro

**Verificación adicional:**
```bash
grep -i "service.*role" .env
# Resultado: Solo comentarios de advertencia ✅
```

---

## 🚨 ACCIONES REQUERIDAS

### 🔧 Acción 1: Renombrar MvpContentModerator (P2 - Opcional)

**Problema:** Nombre confuso, sugiere que es la implementación activa.

**Solución:**

**Opción A (Recomendada):** Agregar documentación clara
```dart
/// ⚠️ FALLBACK LOCAL - NO USADO EN PRODUCCIÓN
///
/// Este moderador se mantiene como:
/// 1. Fallback si Edge Function falla (edge case)
/// 2. Tests unitarios
/// 3. Desarrollo local sin backend
///
/// **PRODUCCIÓN USA:** Edge Function `moderate-gossip` con OpenAI Moderation API
///
/// **NO CONFUNDIR:** Este NO es el moderador activo.
/// Ver: supabase/functions/moderate-gossip/index.ts
class MvpContentModerator implements ContentModerator {
```

**Opción B:** Renombrar
```dart
// Antes
class MvpContentModerator implements ContentModerator {

// Después
class LocalFallbackContentModerator implements ContentModerator {
// o
class TestContentModerator implements ContentModerator {
```

**Estimación:** 30 minutos

**Prioridad:** 🟡 P2 (mejora de claridad, no bloquea producción)

---

### 📝 Acción 2: Documentar que Mocks NO están en DI (P2 - Opcional)

**Agregar comentario en archivo de mocks:**

```dart
/// ⚠️ IMPORTANTE: NO REGISTRADO EN DI DE PRODUCCIÓN
///
/// Este mock NO está activo en la app. Solo se usa para:
/// - Tests unitarios (con mockito)
/// - Desarrollo aislado de módulos
///
/// **Producción usa:** SupabaseGossipRemoteDataSource
/// Ver: lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart
///
/// Para activar mock (solo desarrollo):
/// 1. Descomentar @Singleton aquí
/// 2. Comentar @Singleton en supabase_gossip_remote_data_source.dart
/// 3. Regenerar DI: flutter pub run build_runner build
// @Singleton(as: GossipRemoteDataSource) // ← DESACTIVADO
class MockGossipRemoteDataSource implements GossipRemoteDataSource {
```

**Estimación:** 10 minutos

**Prioridad:** 🟡 P2 (documentación, no crítico)

---

### ✅ Acción 3: Crear Checklist Pre-Producción (P1 - Recomendado)

**Crear archivo:** `docs/PRE_PRODUCTION_CHECKLIST.md`

```markdown
# Checklist Pre-Producción

## Seguridad

- [x] .env NO contiene SERVICE_ROLE_KEY
- [x] Mocks NO registrados en DI de producción
- [x] RLS habilitado en todas las tablas
- [x] Edge Functions usan autenticación obligatoria
- [ ] Rotar SUPABASE_ANON_KEY antes de lanzamiento público
- [ ] Crear usuarios de producción (no test)

## Código

- [x] MockGossipRemoteDataSource desactivado
- [x] MockGossipLocalDataSource no registrado
- [x] Audio picker NO expuesto (backend listo pero UI oculta)
- [ ] Eliminar logs de debug (TODO: búsqueda de debugPrint)
- [ ] Eliminar comentarios de spike/temporal (TODO: búsqueda)

## Tests

- [ ] Tests E2E de golden paths (ver TESTING_ROADMAP.md)
- [ ] Tests de RLS (ver TESTING_ROADMAP.md)
- [ ] Tests de Edge Functions (ver TESTING_ROADMAP.md)

## Configuración

- [ ] Variables de entorno en Supabase Dashboard configuradas
- [ ] OpenAI API key configurada en Supabase Secrets
- [ ] Rate limits de producción configurados
- [ ] Backups automáticos habilitados

## Documentación

- [x] CLAUDE.md actualizado
- [x] TESTING_ROADMAP.md creado
- [ ] API documentation (futuro)
- [ ] Guía de deployment (futuro)
```

**Estimación:** 20 minutos

**Prioridad:** 🟡 P1 (recomendado para organización)

---

## 📊 RESUMEN EJECUTIVO

### Estado Actual: ✅ BUENO

| Elemento | Estado | Riesgo | Acción |
|----------|--------|--------|--------|
| MockGossipRemoteDataSource | ✅ Desactivado | 🟢 Ninguno | Ninguna |
| MockGossipLocalDataSource | ✅ No registrado | 🟢 Ninguno | Ninguna |
| MvpContentModerator | 🟡 Registrado pero no usado | 🟡 Confusión | Documentar |
| spike-user | ✅ Solo en tests | 🟢 Ninguno | Ninguna |
| Políticas USING (true) | ✅ Solo read-only público | 🟢 Ninguno | Ninguna |
| Selector imagen | ✅ Implementado seguro | 🟢 Ninguno | Ninguna |
| Selector audio | ✅ Oculto (backend listo) | 🟢 Ninguno | Ninguna |
| .env SERVICE_ROLE | ✅ No presente | 🟢 Ninguno | Ninguna |

### Riesgos Identificados: 🟢 NINGUNO CRÍTICO

**Hallazgos positivos:**
- ✅ Mocks correctamente aislados (NO en DI)
- ✅ .env limpio (sin service_role)
- ✅ spike-user solo en tests
- ✅ Políticas RLS restrictivas (solo catálogos públicos)
- ✅ Audio no expuesto hasta implementación completa
- ✅ Image picker implementado con flujo seguro

**Mejoras opcionales (P2):**
- 🟡 Renombrar `MvpContentModerator` a `LocalFallbackContentModerator`
- 🟡 Agregar más comentarios de advertencia en mocks
- 🟡 Crear checklist pre-producción formal

---

## 🎯 RECOMENDACIONES

### Para Producción Inmediata

✅ **El proyecto está limpio** - No hay bloqueadores relacionados con mocks o configuración temporal.

**Acciones críticas YA COMPLETADAS:**
- ✅ Mocks desactivados
- ✅ .env seguro
- ✅ Selectores apropiados (imagen sí, audio no)
- ✅ Edge Functions activas

---

### Para Post-Lanzamiento

🟡 **Mejoras de claridad (P2):**

1. **Documentación mejorada** (30 min total)
   - Comentarios más visibles en mocks
   - Renombrar `MvpContentModerator`
   - Checklist pre-producción

2. **Limpieza de código** (2 horas)
   - Buscar y eliminar `debugPrint` innecesarios
   - Eliminar comentarios de "TODO: spike"
   - Consolidar documentación

3. **Rotación de secrets** (antes de beta pública)
   - Rotar `SUPABASE_ANON_KEY`
   - Crear usuarios de producción
   - Configurar backups

---

## 📚 REFERENCIAS

### Archivos Relevantes

**Mocks:**
- `lib/features/gossip/data/datasources/mock_gossip_data_source.dart`
- `lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart`

**DI:**
- `lib/core/di/injection_container.dart`
- `lib/core/di/injection_container.config.dart` (generado)

**Moderación:**
- `lib/features/gossip/domain/services/mvp_content_moderator.dart`
- `supabase/functions/moderate-gossip/index.ts`

**Tests de seguridad:**
- `test/security/edge_function_auth_test.dart`
- `test/security/rls_policies_test.sql`

**Configuración:**
- `.env`
- `.env.example`
- `.gitignore`

---

## 🔍 VERIFICACIÓN ADICIONAL

### Comandos de Auditoría

```bash
# Verificar que mocks NO están en DI
grep -r "MockGossip" lib/core/di/

# Verificar .env limpio
grep -i "service_role" .env

# Verificar spike-user solo en tests
grep -r "spike-user" lib/

# Verificar políticas permisivas
grep -n "USING (true)" supabase/migrations/*.sql

# Verificar audio no expuesto
grep -r "audio.*picker" lib/features/gossip/presentation/

# Listar todos los @Singleton activos
grep -r "@Singleton" lib/ --include="*.dart" | grep -v "^//"
```

**Resultados esperados:**
- MockGossip: (vacío) ✅
- service_role en .env: Solo comentarios ✅
- spike-user en lib/: (vacío) ✅
- USING (true): Solo catálogos read-only ✅
- audio picker: (vacío) ✅

---

## ✅ CONCLUSIÓN

**Estado:** 🟢 **PRODUCCIÓN-READY RESPECTO A MOCKS Y CONFIG**

El análisis muestra que:
1. **Mocks están correctamente aislados** (no en DI de producción)
2. **Configuración es segura** (sin service_role en .env)
3. **Políticas RLS son apropiadas** (restrictivas, solo catálogos públicos)
4. **UI apropiada** (imagen sí, audio no hasta implementación completa)
5. **Edge Functions activas** (no se usa moderación local)

**No hay bloqueadores relacionados con mocks o configuración temporal.**

Las mejoras sugeridas (renombrar, documentar) son **P2 (opcional)** y no bloquean el lanzamiento.

---

**FIN DEL DOCUMENTO**

**Última actualización:** 2026-10-22  
**Próxima revisión:** Antes de beta pública  
**Mantenedor:** Alejo
