# 🔐 Token Auto-Refresh en Supabase - Explicación

## 🎯 El Problema

Cuando creas un usuario con OTP y verificas el código, Supabase crea una **sesión** con dos tokens:

1. **Access Token**: Token de corta duración (~1 hora) que se usa para autenticar requests
2. **Refresh Token**: Token de larga duración (~30-60 días) que se usa para renovar el access token

## 🔄 Auto-Refresh Automático

**Por defecto**, Supabase Flutter SDK tiene habilitado el **auto-refresh automático** de tokens. Esto significa que:

1. Cuando el `access token` está próximo a expirar (5 minutos antes)
2. Supabase automáticamente usa el `refresh token` para obtener un nuevo `access token`
3. Este proceso es **totalmente transparente** para la aplicación

```
Access Token expira en 1 hora
      │
      ├─ 55 minutos después ─→ Supabase detecta que faltan 5 minutos
      │
      ├─ Auto-refresh ─→ Nuevo Access Token (1 hora más)
      │
      └─ Usuario sigue autenticado sin interrupciones ✅
```

## 📊 Logs que Verás

Con los nuevos logs implementados, verás:

### Al Verificar OTP:
```
🔐 Session created after OTP verification
📅 Session expires at: 2026-10-31T02:23:09.000Z
🕐 Current time: 2026-10-31T01:23:09.000Z
⏱️ Time until expiry: 60 minutes (3600 seconds)
❓ Is expired: false
🔑 Access token preview: eyJhbGciOiJIUzI1NiIsInR5cCI...
🔄 Refresh token present: YES (length: 43)
```

### Cuando Supabase Hace Auto-Refresh:
```
🔔 Auth event received: TOKEN_REFRESHED
🔄 TOKEN AUTO-REFRESHED by Supabase!
📅 New token expires at: 2026-10-31T03:23:09.000Z
⏱️ New time until expiry: 60 minutes
```

## ❓ Por Qué Dejó Entrar con Token "Expirado"

**El token NO estaba realmente expirado.** Lo que pasó fue:

1. Creaste el usuario → Access token válido por 1 hora
2. Esperaste que "expirara" → Pero Supabase lo renovó automáticamente a los 55 minutos
3. Intentaste entrar → Tenías un **nuevo access token válido**
4. La validación pasó correctamente ✅

## 🧪 Cómo Testear Tokens Realmente Expirados

Si quieres testear el comportamiento con tokens expirados **sin auto-refresh**, tienes 3 opciones:

### Opción 1: Deshabilitar Auto-Refresh Globalmente (No Recomendado)

```dart
// lib/core/config/supabase_config.dart
static Future<void> initialize() async {
  await Supabase.initialize(
    url: url,
    publishableKey: anonKey,
    debug: kDebugMode,
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false, // ⬅️ Deshabilitar auto-refresh
    ),
  );
}
```

**⚠️ Problema**: Esto afecta toda la app. Usuarios reales perderían la sesión después de 1 hora.

### Opción 2: Esperar Más de 1 Hora (Recomendado para Testing Manual)

1. Crea el usuario
2. **Espera más de 1 hora** (el refresh token también tiene límite)
3. Intenta navegar
4. Deberías ver: `🚨 Session is EXPIRED!`

### Opción 3: Invalidar Manualmente el Token (Mejor para Testing)

```dart
// En ProfileSetupScreen, antes de navegar:
final supabase = SupabaseConfig.client;
await supabase.auth.signOut(); // Invalida la sesión
// Luego intenta navegar → debería detectar sesión expirada
```

## 🔍 Cómo Verificar que las Validaciones Funcionan

### Test 1: Token Expirado en ProfileSetup

```dart
// 1. Verifica OTP normalmente
// 2. En ProfileSetup, antes de presionar "Skip", ejecuta:
await SupabaseConfig.client.auth.signOut();

// 3. Presiona "Skip"
// 4. Deberías ver:
🔍 _onSkipPressed: Checking session before skip
🚨 Session is EXPIRED!
🚫 Cannot skip: Session expired or invalid
📱 Muestra error: "Tu sesión ha expirado..."
```

### Test 2: Token Expirado en MainNavigation

```dart
// 1. Llega al home
// 2. En segundo plano, ejecuta:
await SupabaseConfig.client.auth.signOut();

// 3. El listener debería disparar:
🔔 Auth event received: SIGNED_OUT
🔴 Auth state changed: User signed out or session expired
🔄 Redirecting to login (reason: Session expired)
📱 SnackBar: "Tu sesión ha expirado..."
```

## 🎯 Configuración Actual

La app **TIENE** las validaciones implementadas, pero Supabase está haciendo auto-refresh automático. Esto es:

✅ **CORRECTO para producción** - Los usuarios no pierden su sesión cada hora
✅ **Las validaciones funcionan** - Solo que el token se renueva antes de expirar
✅ **El auth guard funciona** - Detecta sesiones realmente expiradas

## 📝 Resumen

| Escenario | Resultado | Por Qué |
|-----------|-----------|---------|
| Esperar 10 min y navegar | ✅ Pasa | Token aún válido |
| Esperar 55 min y navegar | ✅ Pasa | Auto-refresh renovó el token |
| Esperar 1h 10min y navegar | ✅ Pasa (probablemente) | Auto-refresh sigue activo |
| Esperar varios días | ❌ Falla | Refresh token también expira |
| Hacer signOut() y navegar | ❌ Falla | Sesión invalidada manualmente |

## 🚀 Recomendación Final

**Para producción:** Dejar auto-refresh **habilitado** (configuración actual)

**Para testear validaciones:** Usar `signOut()` manualmente o esperar que expire el refresh token

**Para ver los logs:** Ejecutar la app y observar:
- `🔐 Session created` → Cuándo expira inicialmente
- `🔄 TOKEN AUTO-REFRESHED` → Cuándo Supabase renueva el token
- `🚨 Session is EXPIRED` → Solo cuando realmente expira (sin refresh)

---

**Creado:** 2026-10-31  
**Última actualización:** 2026-10-31  
**Versión:** 1.0
