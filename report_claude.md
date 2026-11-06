# 📋 TAREAS PENDIENTES: CHISMES APP

**Fecha de actualización:** 16 de octubre de 2026  
**Estado:** Spike Supabase completado ✅ | Mock activo para desarrollo  
**Siguiente fase:** Desarrollo de módulos restantes

---

## ✅ PROGRESO COMPLETADO

### Arquitectura y Código
- ✅ Clean Architecture implementada correctamente
- ✅ Dependency Injection con get_it + injectable
- ✅ Desacoplamiento: callback `onSuccess` en lugar de GlobalKey
- ✅ Tests implementados (gossip_validator, state_machine, controller, repository, model)
- ✅ AppSpacing para espaciado consistente
- ✅ Manejo de errores robusto con Result type
- ✅ Estado inmutable con Equatable

### Backend
- ✅ Spike de validación Supabase exitoso
- ✅ Mapeo snake_case ↔ camelCase en GossipModel
- ✅ Arquitectura preparada para cambiar de mock a backend real

---

## 📊 ESTADO DE MOCKS (Post-Spike Supabase)

| Mock | Ubicación | Estado Actual | ¿Listo para Producción? | Acción Necesaria |
|------|-----------|---------------|------------------------|------------------|
| **MockGossipRemoteDataSource** | `mock_gossip_data_source.dart` | ✅ **REEMPLAZADO** por `SupabaseGossipRemoteDataSource` | ✅ Sí (spike funcional) | Solo activar cuando termines otros módulos |
| **MockGossipLocalDataSource** | `mock_gossip_data_source.dart` | ❌ **AÚN ES MOCK** | ❌ No | Implementar con Hive/SQLite para caché offline |
| **MockLocationRepository** | `mock_location_repository.dart` | ❌ **AÚN ES MOCK** | ⚠️ Depende | Decidir: ¿Supabase o JSON local? |
| **TimestampIdGenerator** | `core/id/timestamp_id_generator.dart` | ✅ **YA NO SE USA** con Supabase | ✅ Sí | Supabase auto-genera IDs (uuid_generate_v4()) |
| **MvpContentModerator** | `domain/services/mvp_content_moderator.dart` | ⚠️ **NO SE USA** en Supabase (hardcoded 'approved') | ❌ No | Mover a backend (SQL trigger o Edge Function) |

### Detalles de Cada Mock

#### 1. MockGossipRemoteDataSource ✅ RESUELTO
**Estado:** Implementado y validado con `SupabaseGossipRemoteDataSource`. Actualmente comentado para continuar desarrollo con mock, pero 100% funcional.

```dart
// Spike completado - listo para activar
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
  @override
  Future<GossipModel> create(CreateGossipInput input) async {
    final response = await _supabase
        .from('gossips')
        .insert({...})
        .select()
        .single();
    return GossipModel.fromJson(response);
  }
}
```

**Pendiente para producción:**
- Reemplazar `'spike-user'` por auth real
- Agregar moderación backend
- Habilitar RLS

---

#### 2. MockGossipLocalDataSource ❌ PENDIENTE
**Estado:** Sigue siendo mock en memoria (se borra al cerrar app).

**¿Necesario?**
- ✅ **SÍ** si quieres modo offline
- ❌ **NO** si solo trabajas online

**Si decides implementarlo:**
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

```dart
@Singleton(as: GossipLocalDataSource)
class HiveGossipLocalDataSource implements GossipLocalDataSource {
  final Box<GossipModel> _box;
  
  @override
  Future<List<GossipModel>> getAll() async => _box.values.toList();
  
  @override
  Future<void> saveAll(List<GossipModel> gossips) async {
    await _box.clear();
    await _box.addAll(gossips);
  }
}
```

**Prioridad:** 🟡 Media (solo si necesitas offline)  
**Tiempo estimado:** 2-3 horas

---

#### 3. MockLocationRepository ⚠️ DECISIÓN PENDIENTE
**Estado:** Países, regiones y ciudades hardcodeados en código.

**Opción A: JSON Local** ⭐ RECOMENDADO
- ✅ Gratis, rápido, sin conexión
- ❌ Actualizaciones requieren nueva versión

```dart
// assets/data/locations.json
@Singleton(as: LocationRepository)
class JsonLocationRepository implements LocationRepository {
  @override
  Future<List<Country>> getCountries() async {
    final jsonString = await rootBundle.loadString('assets/data/locations.json');
    final data = jsonDecode(jsonString);
    return (data['countries'] as List).map((j) => Country.fromJson(j)).toList();
  }
}
```

**Opción B: Supabase**
- ✅ Actualizaciones dinámicas
- ❌ Requiere conexión

**Recomendación:** Opción A (JSON local) porque ubicaciones no cambian frecuentemente.

**Prioridad:** 🟢 Baja (funciona bien como mock)  
**Tiempo estimado:** 1-2 horas

---

#### 4. TimestampIdGenerator ✅ RESUELTO
**Estado:** Ya no se necesita. Supabase genera IDs automáticamente.

```sql
CREATE TABLE gossips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- ✅ Auto-generado
  ...
);
```

**No requiere acción.** ✅

---

#### 5. MvpContentModerator ⚠️ PENDIENTE CRÍTICO
**Problema:** En el spike actual, el cliente decide si el contenido es aprobado:

```dart
// ❌ INSEGURO - Cliente controla moderación
final data = {
  'status': 'published',
  'moderation_status': 'approved', // ← Hardcodeado
};
```

**Solución A: SQL Trigger** (moderación simple con palabras prohibidas)
```sql
CREATE OR REPLACE FUNCTION moderate_gossip()
RETURNS TRIGGER AS $$
DECLARE
  banned_words TEXT[] := ARRAY['palabra1', 'palabra2'];
  word TEXT;
BEGIN
  FOREACH word IN ARRAY banned_words
  LOOP
    IF (NEW.subject || ' ' || NEW.content) ILIKE '%' || word || '%' THEN
      NEW.moderation_status := 'rejected';
      NEW.status := 'rejected';
      RETURN NEW;
    END IF;
  END LOOP;
  
  NEW.moderation_status := 'approved';
  NEW.status := 'published';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gossip_moderation_trigger
BEFORE INSERT ON gossips
FOR EACH ROW
EXECUTE FUNCTION moderate_gossip();
```

**Solución B: Edge Function con IA** (moderación avanzada con OpenAI)
```typescript
// supabase/functions/moderate-content/index.ts
import { OpenAI } from 'openai'

serve(async (req) => {
  const { subject, content } = await req.json()
  
  const openai = new OpenAI({ apiKey: OPENAI_API_KEY })
  const response = await openai.moderations.create({
    input: `${subject}\n${content}`
  })
  
  const result = response.results[0]
  
  return new Response(JSON.stringify({
    status: result.flagged ? 'pending' : 'published',
    moderationStatus: result.flagged ? 'pending' : 'approved'
  }))
})
```

**Prioridad:** 🔴 Alta (seguridad)  
**Tiempo estimado:** 2-4 horas

---

### Resumen de Estado

| Componente | ¿Listo para Producción? | Prioridad |
|------------|------------------------|-----------|
| **Remote DataSource** | ✅ Sí (Supabase funciona) | ✅ Completado |
| **ID Generation** | ✅ Sí (Supabase auto-genera) | ✅ Completado |
| **Local DataSource** | ❌ No (mock en memoria) | 🟡 Media (solo si necesitas offline) |
| **Location Repository** | ⚠️ Funciona pero es mock | 🟢 Baja (JSON local es suficiente) |
| **Content Moderator** | ❌ No (hardcoded) | 🔴 Alta (seguridad) |

---

## 🎯 TAREAS PENDIENTES

### 1. SEGURIDAD (CRÍTICO - Obligatorio antes de producción)

#### 1.1 Autenticación
**Prioridad:** ALTA  
**Bloqueante:** Sí - No se puede lanzar sin auth

**Qué hacer:**
```dart
// lib/core/auth/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;
  
  AuthService(this._supabase);
  
  Future<void> signInAnonymously() async {
    await _supabase.auth.signInAnonymously();
  }
  
  String? get currentUserId => _supabase.auth.currentUser?.id;
  
  bool get isAuthenticated => _supabase.auth.currentUser != null;
}
```

**Cambios necesarios:**
1. Reemplazar `'spike-user'` por `authService.currentUserId` en:
   - `supabase_gossip_remote_data_source.dart:76` (campo `created_by`)

2. Agregar guard en `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SupabaseConfig.initialize();
  
  // Auth anónimo automático
  final auth = AuthService(Supabase.instance.client);
  if (!auth.isAuthenticated) {
    await auth.signInAnonymously();
  }
  
  configureDependencies();
  runApp(const ChismesApp());
}
```

**Tiempo estimado:** 2-3 horas

---

#### 1.2 Row Level Security (RLS) en Supabase
**Prioridad:** ALTA  
**Bloqueante:** Sí - Actualmente la tabla está SIN protección

**Estado actual:**
```sql
-- ❌ INSEGURO: Cualquiera puede leer/escribir
ALTER TABLE gossips DISABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE gossips TO anon;
```

**Qué hacer:**
```sql
-- 1. Habilitar RLS
ALTER TABLE gossips ENABLE ROW LEVEL SECURITY;

-- 2. Solo usuarios autenticados pueden crear
CREATE POLICY "Usuarios autenticados pueden crear chismes"
ON gossips FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL
  AND created_by = auth.uid()
);

-- 3. Solo pueden leer chismes publicados y aprobados
CREATE POLICY "Cualquiera puede leer chismes publicados"
ON gossips FOR SELECT
TO authenticated
USING (
  status = 'published'
  AND moderation_status = 'approved'
  AND visibility = 'public'
  AND deleted_at IS NULL
);

-- 4. Solo el creador puede ver sus propios chismes (cualquier estado)
CREATE POLICY "Usuarios pueden ver sus propios chismes"
ON gossips FOR SELECT
TO authenticated
USING (created_by = auth.uid());
```

**Tiempo estimado:** 1 hora

---

#### 1.3 Validación Backend de Campos
**Prioridad:** ALTA  
**Bloqueante:** Sí - Cliente puede ser modificado

**Problema:** Actualmente Flutter valida, pero el cliente puede saltarse esto.

**Qué hacer:** Crear función en Supabase
```sql
-- lib/supabase/functions/create_gossip.sql

CREATE OR REPLACE FUNCTION validate_gossip_input()
RETURNS TRIGGER AS $$
BEGIN
  -- Validar subject
  IF NEW.subject IS NULL OR LENGTH(TRIM(NEW.subject)) = 0 THEN
    RAISE EXCEPTION 'Subject es requerido';
  END IF;
  
  IF LENGTH(NEW.subject) > 200 THEN
    RAISE EXCEPTION 'Subject no puede exceder 200 caracteres';
  END IF;
  
  -- Validar content
  IF NEW.content IS NULL OR LENGTH(TRIM(NEW.content)) = 0 THEN
    RAISE EXCEPTION 'Content es requerido';
  END IF;
  
  IF LENGTH(NEW.content) > 1000 THEN
    RAISE EXCEPTION 'Content no puede exceder 1000 caracteres';
  END IF;
  
  -- Validar ubicación
  IF NEW.country_id IS NULL OR NEW.region_id IS NULL OR NEW.city_id IS NULL THEN
    RAISE EXCEPTION 'Ubicación completa es requerida';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gossip_validation_trigger
BEFORE INSERT ON gossips
FOR EACH ROW
EXECUTE FUNCTION validate_gossip_input();
```

**Tiempo estimado:** 2 horas

---

#### 1.4 Rate Limiting
**Prioridad:** ALTA  
**Bloqueante:** Sí - Previene spam

**Qué hacer:** Crear política de rate limit en Supabase
```sql
-- Tabla para tracking de rate limits
CREATE TABLE IF NOT EXISTS rate_limits (
  user_id UUID NOT NULL,
  action TEXT NOT NULL,
  count INT DEFAULT 0,
  window_start TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, action)
);

-- Función para verificar rate limit
CREATE OR REPLACE FUNCTION check_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  user_count INT;
  window_hours INT := 1;
  max_per_hour INT := 10;
BEGIN
  -- Contar chismes del usuario en la última hora
  SELECT COUNT(*) INTO user_count
  FROM gossips
  WHERE created_by = NEW.created_by
    AND created_at >= NOW() - INTERVAL '1 hour';
  
  IF user_count >= max_per_hour THEN
    RAISE EXCEPTION 'Rate limit excedido. Máximo % chismes por hora', max_per_hour;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rate_limit_trigger
BEFORE INSERT ON gossips
FOR EACH ROW
EXECUTE FUNCTION check_rate_limit();
```

**Límites recomendados para 4-5M usuarios:**
- **Por hora:** 10 chismes
- **Por día:** 50 chismes
- **Por minuto:** 2 chismes

**Tiempo estimado:** 2-3 horas

---

### 2. LOGGING Y MONITOREO (ALTO - Necesario para debugging)

#### 2.1 Logging de Producción
**Prioridad:** ALTA  
**Bloqueante:** No, pero muy recomendado

**Problema:** Actualmente solo usa `print()` que no persiste errores.

**Qué hacer:**
```dart
// lib/core/logging/app_logger.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppLogger {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    // Log local en desarrollo
    if (kDebugMode) {
      debugPrint('❌ Error: $error');
      if (stackTrace != null) debugPrint('Stack: $stackTrace');
      if (context != null) debugPrint('Context: $context');
    }
    
    // Log remoto en producción
    if (kReleaseMode) {
      try {
        await _supabase.from('error_logs').insert({
          'error_message': error.toString(),
          'stack_trace': stackTrace?.toString(),
          'context': context,
          'user_id': _supabase.auth.currentUser?.id,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Failed to log error: $e');
      }
    }
  }
  
  static Future<void> logInfo(String message, {Map<String, dynamic>? data}) async {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }
}
```

**Crear tabla en Supabase:**
```sql
CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  context JSONB,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Index para queries rápidas
CREATE INDEX idx_error_logs_user ON error_logs(user_id);
CREATE INDEX idx_error_logs_timestamp ON error_logs(timestamp DESC);
```

**Reemplazar en:**
- `error_handler.dart:76` - Reemplazar `debugPrint` por `AppLogger.logError`
- `supabase_gossip_remote_data_source.dart:91-93` - Reemplazar `print` por `AppLogger.logError`

**Tiempo estimado:** 2-3 horas

---

### 3. PERFORMANCE (MEDIO - Para 4-5M usuarios)

#### 3.1 Paginación en Feed
**Prioridad:** MEDIA  
**Bloqueante:** Sí cuando haya muchos chismes

**Problema:** Actualmente `getGossips()` trae todos. Con millones de chismes, esto crasheará.

**Qué hacer:**
```dart
// lib/features/gossip/domain/entities/gossip_query.dart
class GossipQuery extends Equatable {
  final String? countryId;
  final String? regionId;
  final String? cityId;
  final int limit;
  final int offset; // ← NUEVO
  final String orderBy;
  final bool descending;

  const GossipQuery({
    this.countryId,
    this.regionId,
    this.cityId,
    this.limit = 20,
    this.offset = 0, // ← NUEVO
    this.orderBy = 'created_at',
    this.descending = true,
  });
  
  @override
  List<Object?> get props => [countryId, regionId, cityId, limit, offset, orderBy, descending];
}
```

**Actualizar en:**
```dart
// supabase_gossip_remote_data_source.dart
@override
Future<List<GossipModel>> getGossips(GossipQuery query) async {
  final response = await builder
      .order(query.orderBy, ascending: !query.descending)
      .range(query.offset, query.offset + query.limit - 1); // ← Paginación
  // ...
}
```

**Tiempo estimado:** 3-4 horas (incluye UI de infinite scroll)

---

#### 3.2 Índices de Base de Datos
**Prioridad:** ALTA para performance con millones de registros  
**Bloqueante:** No inicialmente, pero crítico al escalar

**Qué hacer:**
```sql
-- Índices compuestos para queries frecuentes
CREATE INDEX idx_gossips_location 
ON gossips(country_id, region_id, city_id) 
WHERE status = 'published' AND moderation_status = 'approved' AND deleted_at IS NULL;

CREATE INDEX idx_gossips_user_status 
ON gossips(created_by, status, created_at DESC);

CREATE INDEX idx_gossips_created_at 
ON gossips(created_at DESC) 
WHERE status = 'published' AND moderation_status = 'approved';

-- Índice para rate limiting
CREATE INDEX idx_gossips_rate_limit 
ON gossips(created_by, created_at DESC);
```

**Tiempo estimado:** 30 minutos

---

### 4. CALIDAD DE CÓDIGO (BAJO - Mejoras menores)

#### 4.1 Manejo de Errores UI
**Prioridad:** BAJA  
**Estado:** Funciona bien, pero podría mejorarse

**Mejora opcional:**
```dart
// lib/core/widgets/error_banner.dart
class ErrorBanner extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  
  const ErrorBanner({
    super.key,
    required this.failure,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              ErrorMessages.getMessage(failure.code),
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
```

**Tiempo estimado:** 1 hora

---

#### 4.2 Internacionalización (i18n)
**Prioridad:** BAJA - Solo si planeas múltiples idiomas  
**Estado:** Strings en español hardcodeados

**¿Necesario?**
- ❌ NO si solo apuntas a usuarios hispanohablantes
- ✅ SÍ si planeas expandir a otros países

**Si decides hacerlo:**
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
```

**Tiempo estimado:** 1 día completo

---

### 5. PREPARACIÓN PARA PRODUCCIÓN (CHECKLIST)

#### 5.1 Configuración de Entornos
**Prioridad:** MEDIA  
**Necesario:** Para separar dev/staging/production

**Qué hacer:**
```dart
// lib/core/config/environment.dart
enum Environment { development, production }

class EnvConfig {
  static Environment get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return env == 'production' 
        ? Environment.production 
        : Environment.development;
  }
  
  static bool get isProduction => current == Environment.production;
  static bool get isDevelopment => current == Environment.development;
}
```

**Compilar para producción:**
```bash
flutter build apk --dart-define=ENV=production --release
```

**Tiempo estimado:** 1-2 horas

---

### 6. CLEANUP DE IMÁGENES HUÉRFANAS (ESTRATEGIA 3)

#### 6.1 ¿Qué son archivos huérfanos?

**Problema:**
```
Usuario sube imagen → Storage
Usuario cancela o app crashea → Gossip NO se crea
Imagen queda en Storage → HUÉRFANA (cuesta dinero)
```

**Impacto sin cleanup:**
```
10,000 imágenes huérfanas/mes × 150 KB = 1.5 GB/mes
Después de 1 año: 18 GB acumulados
Costo: $0.40/mes (basura acumulada)
```

#### 6.2 Estrategia Implementada (Prevención)

**✅ ESTRATEGIA 1: Subir DESPUÉS**

Ya implementado en `CreateGossip` use case:
1. Crear gossip SIN imagen → DB
2. Subir imagen con gossipId → Storage
3. Actualizar gossip con URL → DB

**Ventajas:**
- ✅ 0% archivos huérfanos (imagen solo se sube si gossip existe)
- ✅ Simple de implementar
- ✅ No requiere cleanup

**Ver:**
- `lib/features/gossip/domain/usecases/create_gossip.dart`
- `lib/core/media/supabase_storage_service.dart`
- `audio_imagen.md` sección "Estrategia 1"

#### 6.3 Estrategia Complementaria (Limpieza)

**⚠️ ESTRATEGIA 3: Cleanup Periódico**

Para limpiar residuos (app crasheó, bugs, etc.):

**Implementación en Supabase:**

```sql
-- Función SQL para limpiar imágenes huérfanas
CREATE OR REPLACE FUNCTION cleanup_orphaned_images()
RETURNS TABLE (deleted_count INTEGER, storage_freed_mb NUMERIC) AS $$
DECLARE
  orphan_record RECORD;
  deleted INTEGER := 0;
BEGIN
  -- Buscar imágenes en storage.objects que NO tienen referencia en gossips
  FOR orphan_record IN
    SELECT 
      o.name,
      o.created_at,
      LENGTH(o.metadata->'size')::INTEGER as size_bytes
    FROM storage.objects o
    WHERE o.bucket_id = 'images'
      AND o.name LIKE 'gossips/%'
      -- Solo mayores a 24 horas (evitar borrar en-progreso)
      AND o.created_at < NOW() - INTERVAL '24 hours'
      -- NO están referenciadas en gossips
      AND NOT EXISTS (
        SELECT 1 FROM gossips g 
        WHERE o.name LIKE '%' || SPLIT_PART(g.id, '-', 1) || '%'
          OR g.image_url LIKE '%' || o.name || '%'
          OR g.thumbnail_url LIKE '%' || o.name || '%'
      )
  LOOP
    -- Eliminar archivo huérfano
    DELETE FROM storage.objects 
    WHERE bucket_id = 'images' 
      AND name = orphan_record.name;
    
    deleted := deleted + 1;
    
    RAISE NOTICE 'Deleted: % (created: %)', 
      orphan_record.name, 
      orphan_record.created_at;
  END LOOP;
  
  -- Retornar estadísticas
  RETURN QUERY SELECT 
    deleted,
    ROUND((deleted * 150.0) / 1024, 2); -- Asumiendo 150 KB promedio
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentario
COMMENT ON FUNCTION cleanup_orphaned_images() IS
'Limpia imágenes huérfanas en Supabase Storage.
Ejecutar manualmente 1 vez/mes o configurar con pg_cron.
Solo borra imágenes > 24 horas sin referencia en gossips.';
```

**Ejecutar manualmente:**
```sql
-- Desde Supabase Dashboard > SQL Editor
SELECT * FROM cleanup_orphaned_images();

-- Output ejemplo:
-- deleted_count | storage_freed_mb
-- --------------|------------------
--     127       |      18.60
```

**Ejecutar automáticamente (si pg_cron disponible):**
```sql
-- Ejecutar primer domingo de cada mes a las 3 AM
SELECT cron.schedule(
  'cleanup-orphaned-images-monthly',
  '0 3 1 * *',  -- Minuto Hora Día Mes DiaSemana
  'SELECT cleanup_orphaned_images();'
);

-- Verificar schedule
SELECT * FROM cron.job WHERE jobname = 'cleanup-orphaned-images-monthly';

-- Desactivar si es necesario
SELECT cron.unschedule('cleanup-orphaned-images-monthly');
```

**O ejecutar desde Flutter (admin tool):**
```dart
// lib/admin/cleanup_orphaned_images.dart
class OrphanedImagesCleanup {
  final SupabaseClient _supabase;
  
  Future<CleanupResult> runCleanup() async {
    final response = await _supabase.rpc('cleanup_orphaned_images');
    
    return CleanupResult(
      deletedCount: response['deleted_count'],
      storageFreedMB: response['storage_freed_mb'],
    );
  }
}
```

#### 6.4 Frecuencia Recomendada

| Usuarios Activos | Frecuencia | Método |
|-----------------|------------|--------|
| < 10,000 | Cada 3 meses | Manual |
| 10,000 - 100,000 | Cada mes | Manual o Cron |
| > 100,000 | Cada semana | Cron automático |

#### 6.5 Monitoreo

**Ver estadísticas en Supabase Dashboard:**
```
Storage → Bucket: images → Usage
- Total size
- Object count
- Growth rate
```

**Query manual para ver posibles huérfanos:**
```sql
-- Ver imágenes sin referencia
SELECT 
  name,
  created_at,
  (metadata->>'size')::INTEGER / 1024 as size_kb
FROM storage.objects
WHERE bucket_id = 'images'
  AND name LIKE 'gossips/%'
  AND created_at < NOW() - INTERVAL '24 hours'
  AND NOT EXISTS (
    SELECT 1 FROM gossips g 
    WHERE name LIKE '%' || SPLIT_PART(g.id, '-', 1) || '%'
  )
ORDER BY created_at DESC
LIMIT 20;
```

#### 6.6 Resumen

**Estado actual:**
- ✅ **Prevención implementada** (Estrategia 1: Subir después)
- ⚠️ **Limpieza pendiente** (Estrategia 3: Cleanup periódico)

**Prioridad:** 🟢 Baja (solo implementar si hay problema)

**Cuándo implementar:**
- Si ves crecimiento de storage sin explicación
- Si costos de storage suben inesperadamente
- Después de 6 meses en producción (mantenimiento preventivo)

**Tiempo estimado:** 1-2 horas (crear función + probar)

---

## 📊 RESUMEN DE PRIORIDADES

### 🔴 CRÍTICO (Bloqueante para producción)
1. ✅ **Autenticación** - 2-3 horas
2. ✅ **Row Level Security** - 1 hora  
3. ✅ **Validación Backend** - 2 horas
4. ✅ **Rate Limiting** - 2-3 horas
5. ✅ **Índices de BD** - 30 minutos

**Total crítico: ~8-10 horas (1-2 días)**

---

### 🟡 ALTO (Muy recomendado)
1. ⚠️ **Logging de producción** - 2-3 horas
2. ⚠️ **Paginación** - 3-4 horas

**Total alto: ~5-7 horas (1 día)**

---

### 🟢 MEDIO/BAJO (Mejoras opcionales)
1. ⭕ Configuración de entornos - 1-2 horas
2. ⭕ Error banner mejorado - 1 hora
3. ⭕ i18n - 1 día (solo si necesitas múltiples idiomas)

---

## 🎯 PLAN DE ACCIÓN SUGERIDO

### Fase 1: Seguridad (2 días)
**Antes de lanzar a producción - OBLIGATORIO**
- [ ] Implementar autenticación anónima
- [ ] Configurar RLS en Supabase
- [ ] Agregar validación backend
- [ ] Implementar rate limiting
- [ ] Crear índices de BD

### Fase 2: Desarrollo de Módulos (2-3 semanas)
**Volver al mock y desarrollar:**
- [ ] Feed (pantalla principal con lista de chismes)
- [ ] Detalle de chisme (ver chisme completo)
- [ ] Búsqueda (buscar chismes por texto/ubicación)
- [ ] Perfil (ver chismes propios)

### Fase 3: Integración Final (1 semana)
**Activar Supabase y probar end-to-end:**
- [ ] Activar SupabaseGossipRemoteDataSource
- [ ] Agregar logging de producción
- [ ] Implementar paginación
- [ ] Testing completo
- [ ] Deploy a TestFlight/Play Store Beta

---

## ✅ LO QUE YA ESTÁ BIEN

**No toques estos - ya están correctamente implementados:**

✅ Clean Architecture con separación clara de capas  
✅ Dependency Injection con get_it + injectable  
✅ Manejo de estado inmutable  
✅ Manejo de errores con Result type  
✅ Validación en cliente (GossipValidator)  
✅ Tests unitarios  
✅ Desacoplamiento (no más GlobalKey)  
✅ Repository pattern con abstracción  
✅ Models con serialización robusta  
✅ Espaciado consistente con AppSpacing  
✅ Race condition handling en cascading dropdowns  
✅ Protección contra doble submit  

---

## 🚀 SIGUIENTE PASO RECOMENDADO

**Opción A: Ir directo a producción (2-3 días)**
→ Completar Fase 1 (Seguridad)  
→ Activar Supabase  
→ Lanzar MVP con solo "Agregar chisme"

**Opción B: Completar features primero (4-5 semanas) ⭐ RECOMENDADO**
→ Terminar módulos con mock (Fase 2)  
→ Luego Fase 1 + Fase 3  
→ Lanzar app completa

---

**Nota:** Para una app de 4 pantallas y 2-3 campos, NO necesitas:
- ❌ Arquitectura más compleja
- ❌ Tokens de diseño elaborados
- ❌ Navegación con rutas nombradas
- ❌ Widgets ultra-pequeños
- ❌ Responsive para tablets (a menos que sea crítico)
- ❌ Múltiples idiomas (a menos que sea necesario)

**Mantén la simplicidad. La arquitectura actual es perfecta para tu escala.**

---

**Última actualización:** 16 de octubre de 2026  
**Revisado por:** Claude Sonnet 4.5  
**Contexto:** Post-spike Supabase, mock activo para desarrollo
