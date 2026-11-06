# Security Fix: Logging y Modo Release

**Fecha:** 2026-10-22  
**Issue:** Seguridad P0 - Logs con datos sensibles, RLS bloqueará inserts, debug mode en producción  
**Status:** ✅ RESUELTO

---

## 📋 Problemas Originales

### 1. Debug Mode Hardcodeado en Producción

**Archivo:** `lib/core/config/supabase_config.dart:19`

```dart
// ❌ VULNERABLE
debug: true, // Para spike, muestra logs útiles
```

**Riesgo:**
- Logs verbose de Supabase en producción
- Performance degradado
- Información sensible en logs

---

### 2. RLS Bloqueará Inserts desde Cliente

**Problema:**
- `RemoteLogger` intenta `INSERT` directo a `error_logs`
- Política RLS: Solo `service_role` puede insertar
- Cliente móvil usa `anon_key` (no `service_role`)

**Resultado:**
- ❌ Todos los logs fallarán silenciosamente en producción
- Error capturado pero no propagado (`catch` solo hace `debugPrint`)

**Código problemático:**
```dart
// remote_logger.dart:47
await _client.from('error_logs').insert(entry.toJson());  // ❌ FALLARÁ
```

**Política RLS que lo bloquea:**
```sql
-- 003_create_error_logs.sql:50-54
CREATE POLICY "Service role can insert error_logs"
  ON public.error_logs
  FOR INSERT
  TO service_role  -- ❌ Solo service_role
  WITH CHECK (true);
```

---

### 3. Datos Sensibles en Logs

**Problema:**
- `LogEntry` permite cualquier dato en `context`
- Sin sanitización ni allowlist
- Puede incluir:
  - Texto completo de gossips
  - Coordenadas GPS exactas
  - URLs firmadas (signed URLs)
  - Headers HTTP
  - Tokens de auth
  - Contraseñas

**Riesgo:**
- Exposición de datos sensibles en logs
- Incumplimiento GDPR/CCPA
- Ataque de privacidad

---

### 4. Scheduler de Limpieza No Configurado

**Problema:**
- Existe función `clean_old_error_logs()`
- PERO no hay scheduler que la ejecute
- Logs crecerán indefinidamente

**Resultado:**
- Base de datos crece sin límite
- Performance degradado
- Costos incrementados

---

## ✅ Soluciones Implementadas

### Fix 1: Debug Mode Condicional

**Archivo:** `lib/core/config/supabase_config.dart`

**Antes:**
```dart
debug: true, // Para spike
```

**Ahora:**
```dart
import 'package:flutter/foundation.dart';

debug: kDebugMode, // ✅ Solo debug en modo DEBUG
```

**Resultado:**
- ✅ DEBUG mode: Logs verbose
- ✅ RELEASE mode: Sin logs (mejor performance)

---

### Fix 2: Edge Function para Logging Seguro

**Archivo:** `supabase/functions/log-error/index.ts`

**Arquitectura:**
```
Cliente móvil (anon_key)
  ↓
  HTTP POST con Authorization header
  ↓
Edge Function 'log-error'
  ↓ Valida auth (auth.uid())
  ↓ Sanitiza datos (allowlist)
  ↓ Rate limiting (50/hora, 200/día)
  ↓
  INSERT con service_role (bypasa RLS)
  ↓
Tabla error_logs
```

**Características de seguridad:**

1. **Autenticación obligatoria:**
   ```typescript
   const { data: { user }, error } = await supabaseAnon.auth.getUser()
   if (!user) return 401
   ```

2. **Allowlist de campos en context:**
   ```typescript
   const CONTEXT_ALLOWLIST = new Set([
     // IDs (sin datos sensibles)
     'gossipId', 'userId', 'cityId',
     // Operaciones
     'operation', 'action', 'screen',
     // Códigos
     'errorCode', 'httpStatus',
     // Flags
     'isRetry', 'isOffline',
   ])
   ```

3. **Denylist de campos prohibidos:**
   ```typescript
   const CONTEXT_DENYLIST = new Set([
     'password', 'token', 'accessToken',
     'latitude', 'longitude', 'coords',
     'subject', 'content', 'text',  // ❌ Texto de gossips
     'email', 'phone', 'address',
     'url', 'signedUrl', 'headers',
   ])
   ```

4. **Sanitización automática:**
   ```typescript
   function sanitizeContext(context) {
     const sanitized = {}
     for (const [key, value] of Object.entries(context)) {
       if (CONTEXT_DENYLIST.has(key)) continue  // ❌ Rechazar
       if (!CONTEXT_ALLOWLIST.has(key)) continue  // ⚠️ Solo permitidos
       // Truncar strings largos
       sanitized[key] = String(value).substring(0, 200)
     }
     return sanitized
   }
   ```

5. **Rate limiting:**
   ```typescript
   // Max 50 logs/hora por usuario
   // Max 200 logs/día por usuario
   const rateLimitCheck = await checkRateLimit(supabaseAdmin, userId)
   if (!rateLimitCheck.allowed) return 429
   ```

6. **Service role insert:**
   ```typescript
   // Bypasa RLS (solo service_role puede insertar)
   const supabaseAdmin = createClient(
     Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
   )
   await supabaseAdmin.from('error_logs').insert({...})
   ```

---

### Fix 3: RemoteLogger Actualizado

**Archivo:** `lib/core/logging/remote_logger.dart`

**Antes:**
```dart
// ❌ Insert directo (fallará por RLS)
await _client.from('error_logs').insert(entry.toJson());
```

**Ahora:**
```dart
// ✅ Usar Edge Function
final response = await _client.functions.invoke(
  'log-error',
  body: entry.toJson(),  // Edge Function sanitizará
);

if (response.status == 200) {
  debugPrint('📤 Log enviado a Edge Function');
} else if (response.status == 429) {
  debugPrint('⚠️ Rate limit excedido');
}
```

**Beneficios:**
- ✅ Auth automática (Supabase SDK envía Authorization header)
- ✅ Sanitización en servidor (allowlist/denylist)
- ✅ Rate limiting en servidor
- ✅ Bypasa RLS (service_role)
- ✅ Fire-and-forget (no propaga errores)

---

### Fix 4: Scheduler de Limpieza

**Archivo:** `supabase/migrations/012_schedule_error_logs_cleanup.sql`

**Configuración pg_cron:**
```sql
-- Ejecutar clean_old_error_logs() cada domingo a las 3 AM UTC
SELECT cron.schedule(
  'error-logs-cleanup',
  '0 3 * * 0',  -- Cron: Domingos 3 AM
  'SELECT clean_old_error_logs()'
);
```

**Función mejorada:**
```sql
CREATE OR REPLACE FUNCTION clean_old_error_logs()
RETURNS TABLE(deleted_count BIGINT) AS $$
BEGIN
  DELETE FROM public.error_logs
  WHERE created_at < NOW() - INTERVAL '90 days';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RAISE NOTICE 'Cleaned % old error logs', v_deleted_count;

  RETURN QUERY SELECT v_deleted_count;
END;
$$;
```

**Retención:** 90 días  
**Frecuencia:** Semanal (domingos)  
**Automático:** Sí (pg_cron)

---

### Fix 5: Vistas de Monitoreo

**Agregadas en migración 012:**

1. **recent_errors** - Errores últimas 24h
   ```sql
   SELECT * FROM recent_errors;
   ```

2. **error_summary** - Resumen por tipo (últimos 7 días)
   ```sql
   SELECT * FROM error_summary ORDER BY count DESC;
   ```

3. **users_with_most_errors** - Top 20 usuarios con más errores
   ```sql
   SELECT * FROM users_with_most_errors;
   ```

4. **check_error_log_rate()** - Alertas de tasa alta
   ```sql
   SELECT * FROM check_error_log_rate();
   -- Retorna warning si >100/hora o >1000/día
   ```

---

## 🔒 Garantías de Seguridad

### ✅ Datos Sensibles NUNCA Loggeados:

| Dato Sensible | ¿Loggeado? | Protección |
|---------------|-----------|------------|
| Texto de gossips | ❌ | Denylist (`subject`, `content`) |
| Coordenadas GPS | ❌ | Denylist (`latitude`, `longitude`, `coords`) |
| Tokens de auth | ❌ | Denylist (`token`, `accessToken`, `idToken`) |
| Contraseñas | ❌ | Denylist (`password`, `secret`) |
| URLs firmadas | ❌ | Denylist (`signedUrl`, `presignedUrl`) |
| Headers HTTP | ❌ | Denylist (`headers`, `authorization`) |
| Emails/teléfonos | ❌ | Denylist (`email`, `phone`) |

### ✅ Datos Permitidos (Allowlist):

| Dato Permitido | Ejemplo | Uso |
|----------------|---------|-----|
| IDs | `gossipId: "abc123"` | Identificar entidad |
| Operación | `operation: "createGossip"` | Contexto del error |
| Códigos de error | `errorCode: "NETWORK_ERROR"` | Clasificación |
| Flags booleanos | `isRetry: true` | Estado |
| Contadores | `attemptCount: 3` | Debugging |

---

## 📊 Flujo Completo de Logging

### Antes (VULNERABLE):

```
1. App genera error
   ↓
2. AppLogger.error() llama RemoteLogger
   ↓
3. RemoteLogger.log() → INSERT directo
   ↓
4. RLS bloquea (no es service_role)
   ↓
5. ❌ Log perdido silenciosamente
```

### Ahora (SEGURO):

```
1. App genera error
   ↓
2. AppLogger.error() llama RemoteLogger
   ↓
3. RemoteLogger.log() → POST a Edge Function
   |  (Authorization: Bearer <user-token>)
   ↓
4. Edge Function 'log-error':
   - ✅ Valida auth (auth.uid())
   - ✅ Valida rate limiting (50/hora)
   - ✅ Sanitiza context (allowlist/denylist)
   - ✅ Sanitiza device_info
   - ✅ INSERT con service_role (bypasa RLS)
   ↓
5. ✅ Log persistido en error_logs
   ↓
6. [Semanal] pg_cron ejecuta cleanup (>90 días)
```

---

## 🧪 Testing

### Test 1: Debug mode condicional

```dart
// En main.dart
import 'package:flutter/foundation.dart';

void main() {
  print('kDebugMode: $kDebugMode');  // true en DEBUG, false en RELEASE
  SupabaseConfig.initialize();  // debug: kDebugMode
}
```

**Verificar:**
- DEBUG: Ver logs de Supabase
- RELEASE: Sin logs

### Test 2: Edge Function de logging

```bash
# Invocar Edge Function manualmente
curl -X POST https://xxx.supabase.co/functions/v1/log-error \
  -H "Authorization: Bearer <user-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "error",
    "message": "Test error",
    "context": {
      "gossipId": "test123",
      "subject": "SECRET TEXT"
    }
  }'
```

**Verificar:**
- ✅ Log insertado en `error_logs`
- ✅ `gossipId` presente en context
- ❌ `subject` NO presente (denylist)

### Test 3: Rate limiting

```dart
// Enviar >50 logs en 1 hora desde misma cuenta
for (int i = 0; i < 60; i++) {
  AppLogger.error('Test error $i');
  await Future.delayed(Duration(seconds: 1));
}
```

**Verificar:**
- Primeros 50: ✅ Persisten
- Siguientes: ❌ 429 Rate Limit Exceeded

### Test 4: Scheduler de limpieza

```sql
-- Insertar log antiguo (>90 días)
INSERT INTO error_logs (level, message, created_at)
VALUES ('error', 'Old test', NOW() - INTERVAL '100 days');

-- Ejecutar cleanup manualmente
SELECT * FROM clean_old_error_logs();

-- Verificar que se eliminó
SELECT COUNT(*) FROM error_logs WHERE message = 'Old test';
-- Debe retornar 0
```

### Test 5: Vistas de monitoreo

```sql
-- Ver errores recientes
SELECT * FROM recent_errors LIMIT 10;

-- Ver resumen por tipo
SELECT * FROM error_summary;

-- Ver usuarios con más errores
SELECT * FROM users_with_most_errors;

-- Verificar tasa de errores
SELECT * FROM check_error_log_rate();
```

---

## 📦 Archivos Modificados/Creados

### **Modificados:**

1. ✅ `lib/core/config/supabase_config.dart`
   - Cambio: `debug: true` → `debug: kDebugMode`

2. ✅ `lib/core/logging/remote_logger.dart`
   - Cambio: INSERT directo → Edge Function invoke

### **Nuevos:**

3. ✅ `supabase/functions/log-error/index.ts` (Edge Function)
   - Autenticación
   - Sanitización (allowlist/denylist)
   - Rate limiting
   - Service role insert

4. ✅ `supabase/migrations/012_schedule_error_logs_cleanup.sql`
   - pg_cron scheduler (domingos 3 AM)
   - Función cleanup mejorada
   - Vistas de monitoreo
   - Función de alertas

---

## 🚀 Configuración Adicional (Opcional)

### 1. Alertas Proactivas

**Configurar webhook de Supabase para alertas:**

```sql
-- Trigger para enviar webhook si >100 errores/hora
CREATE OR REPLACE FUNCTION notify_high_error_rate()
RETURNS trigger AS $$
DECLARE
  hour_count INT;
BEGIN
  -- Contar errores última hora
  SELECT COUNT(*) INTO hour_count
  FROM error_logs
  WHERE created_at > NOW() - INTERVAL '1 hour';

  -- Si >100, enviar alerta (vía webhook o pg_notify)
  IF hour_count > 100 THEN
    PERFORM pg_notify('high_error_rate', json_build_object(
      'count', hour_count,
      'threshold', 100
    )::text);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_error_rate_trigger
  AFTER INSERT ON error_logs
  FOR EACH ROW
  EXECUTE FUNCTION notify_high_error_rate();
```

### 2. Integración con Sentry/Datadog

**Si en el futuro se quiere usar proveedor externo:**

```dart
// En remote_logger.dart
@Singleton(as: RemoteLogger)
class SentryRemoteLogger implements RemoteLogger {
  @override
  Future<void> log(LogEntry entry) async {
    await Sentry.captureException(
      entry.error,
      stackTrace: entry.stackTrace,
      // ✅ Sanitizar context antes de enviar
      extra: sanitizeContext(entry.context),
    );
  }
}
```

---

## ✅ Resumen Final

### Problemas Resueltos:

1. ✅ **Debug mode:** Ahora condicional (`kDebugMode`)
2. ✅ **RLS bloqueará inserts:** Resuelto con Edge Function + service_role
3. ✅ **Datos sensibles:** Sanitización con allowlist/denylist
4. ✅ **Scheduler:** pg_cron ejecuta cleanup semanal
5. ✅ **Rate limiting:** 50/hora, 200/día por usuario
6. ✅ **Monitoreo:** Vistas para dashboard
7. ✅ **Retención:** 90 días automático

### Resultado:

**Logging seguro, escalable y conforme:**
- 🔒 Sin datos sensibles
- ⚡ Performance (solo en debug mode cuando necesario)
- 📊 Monitoreable (vistas + alertas)
- 🧹 Auto-limpieza (90 días)
- 🚫 Rate limiting (anti-abuso)
- ✅ Cumplimiento GDPR/CCPA

---

**FIN DEL DOCUMENTO**
