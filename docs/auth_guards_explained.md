# 🛡️ Sistema de Protección contra Tokens Expirados

## 📋 Resumen

El sistema implementa **3 barreras de protección** para detectar y prevenir acceso con tokens expirados o sesiones inválidas.

---

## 🔒 Las 3 Barreras de Protección

### **Barrera #1: Validación en ProfileSetupScreen**

**Archivo:** `lib/features/auth/presentation/screens/profile_setup_screen.dart`

**Puntos de Validación:**

#### 1.1 En `initState()` - Validación al Entrar
```dart
if (!_authService.isAuthenticated) {
  // Redirige a login inmediatamente
  _showError('Tu sesión ha expirado...');
  Navigator.pushNamedAndRemoveUntil('/login', ...);
}
```

**Cuándo:** Al cargar la pantalla de Profile Setup  
**Qué hace:** Verifica que haya una sesión activa  
**Si falla:** Redirige automáticamente a login

#### 1.2 En `_onSkipPressed()` - Validación antes de Skip
```dart
if (!_authService.isAuthenticated || _authService.isSessionExpired()) {
  _showError('Tu sesión ha expirado...');
  return; // NO navega
}
```

**Cuándo:** Usuario presiona botón "Después" (Skip)  
**Qué hace:** Valida sesión antes de permitir saltar  
**Si falla:** Muestra error, NO navega al home

#### 1.3 En `_navigateToHome()` - Validación antes de Navegar
```dart
// Primera validación
if (!_authService.isAuthenticated || currentUser == null) {
  _showError('Tu sesión ha expirado...');
  Navigator.pushNamedAndRemoveUntil('/login', ...);
  return;
}

// Segunda validación: Expiración manual
if (_authService.isSessionExpired()) {
  _showError('Tu sesión ha expirado...');
  Navigator.pushNamedAndRemoveUntil('/login', ...);
  return;
}

// Si todo OK, navegar al home
Navigator.pushAndRemoveUntil(...MainNavigationScreen...);
```

**Cuándo:** Antes de navegar al home (completar perfil o skip)  
**Qué hace:** 
1. Verifica `isAuthenticated` y `currentUser`
2. Verifica manualmente si el token está expirado
**Si falla:** Redirige a login, NO navega al home

**Propósito de esta Barrera:**  
Evitar que el usuario navegue al home si el token expiró mientras estaba configurando su perfil.

---

### **Barrera #2: Auth Guard en MainNavigationScreen**

**Archivo:** `lib/features/home/presentation/screens/main_navigation_screen.dart`

**Componentes:**

#### 2.1 Validación al Iniciar (`_validateSessionOnInit`)
```dart
void _validateSessionOnInit() {
  if (!_authService.isAuthenticated) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToLogin(reason: 'No authenticated session');
    });
    return;
  }

  if (_authService.isSessionExpired()) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToLogin(reason: 'Session token expired');
    });
    return;
  }
}
```

**Cuándo:** Al inicializar MainNavigationScreen (home)  
**Qué hace:**
1. Verifica `isAuthenticated`
2. Verifica manualmente si el token está expirado
**Si falla:** Redirige a login después del frame actual

#### 2.2 Listener en Tiempo Real (`_setupAuthListener`)
```dart
void _setupAuthListener() {
  _authStateSubscription = _authService.userStream.listen(
    (user) {
      if (user == null) {
        // Sesión expiró o cerró → redirigir
        _redirectToLogin(reason: 'Session expired');
      }
    },
    onError: (error) {
      _logger.e('Error in auth state listener', error: error);
    },
  );
}
```

**Cuándo:** Continuamente mientras el usuario está en el home  
**Qué hace:** Escucha el stream `authStateChanges` de Supabase  
**Si detecta `user == null`:** Sesión expiró → Redirige automáticamente a login

#### 2.3 Cleanup (`dispose`)
```dart
@override
void dispose() {
  _authStateSubscription?.cancel(); // Evita memory leaks
  super.dispose();
}
```

**Cuándo:** Al destruir el widget  
**Qué hace:** Cancela la suscripción al stream

#### 2.4 Redirect Handler (`_redirectToLogin`)
```dart
void _redirectToLogin({required String reason}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Tu sesión ha expirado...')),
  );

  Navigator.pushAndRemoveUntil(...LoginScreen...);
}
```

**Qué hace:**
1. Muestra SnackBar al usuario
2. Redirige a login
3. Limpia el stack de navegación

**Propósito de esta Barrera:**  
Detectar expiración de token en tiempo real mientras el usuario usa la app y redirigir automáticamente.

---

### **Barrera #3: Validación Manual de Expiración**

**Archivo:** `lib/core/services/auth_service.dart`

**Métodos:**

#### 3.1 `debugSessionStatus()` - Información Detallada
```dart
Map<String, dynamic> debugSessionStatus() {
  final session = SupabaseConfig.client.auth.currentSession;
  
  if (session == null) {
    return {'hasSession': false, 'isAuthenticated': false};
  }

  final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
  final now = DateTime.now();
  final isExpired = expiresAt.isBefore(now);

  return {
    'hasSession': true,
    'userId': user.id,
    'expiresAt': expiresAt.toIso8601String(),
    'timeUntilExpiryMinutes': expiresAt.difference(now).inMinutes,
    'isExpired': isExpired,
  };
}
```

**Cuándo:** Cuando se necesita información detallada (debugging)  
**Qué hace:** Retorna estado completo de la sesión  
**Retorna:** Map con toda la información del token

#### 3.2 `isSessionExpired()` - Verificación Simple
```dart
bool isSessionExpired() {
  final session = SupabaseConfig.client.auth.currentSession;
  
  if (session == null) return true;

  final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
  return expiresAt.isBefore(DateTime.now());
}
```

**Cuándo:** Validaciones en ProfileSetup y MainNavigation  
**Qué hace:** Verifica manualmente si el token está expirado  
**Retorna:** `true` si expiró, `false` si está válido

**Cómo funciona:**
1. Lee directamente del `SupabaseClient`
2. Obtiene `expiresAt` del token
3. Compara con tiempo actual
4. NO depende del auto-refresh de Supabase

**Propósito de esta Barrera:**  
Proporcionar verificación independiente que no depende del auto-refresh automático de Supabase.

---

## 🎯 Flujo Completo de Protección

```
Usuario verifica OTP ✅
       │
       ▼
┌──────────────────────────────────────────┐
│ Barrera #1: ProfileSetup                 │
├──────────────────────────────────────────┤
│ 1. Valida al iniciar pantalla           │
│ 2. Valida antes de Skip                  │
│ 3. Valida antes de navegar a Home        │
└──────────────────────────────────────────┘
       │
       ▼ (Si todo OK)
┌──────────────────────────────────────────┐
│ Barrera #2: MainNavigation               │
├──────────────────────────────────────────┤
│ 1. Valida al iniciar home                │
│ 2. Listener detecta cambios en tiempo    │
│    real (token expira → redirige auto)   │
└──────────────────────────────────────────┘
       │
       ▼ (Token expira mientras usa app)
┌──────────────────────────────────────────┐
│ Barrera #2: Listener detecta cambio      │
├──────────────────────────────────────────┤
│ • user == null                           │
│ • SnackBar: "Tu sesión ha expirado"      │
│ • Redirige a login automáticamente       │
└──────────────────────────────────────────┘
```

---

## 🔍 Validación Manual (Barrera #3)

**Usada por:**
- Barrera #1 (ProfileSetup)
- Barrera #2 (MainNavigation)

**Método:** `AuthService.isSessionExpired()`

```dart
// En ProfileSetup
if (_authService.isSessionExpired()) {
  // Token expiró → Bloquear navegación
}

// En MainNavigation
if (_authService.isSessionExpired()) {
  // Token expiró → Redirigir a login
}
```

**Ventaja:**  
No depende del auto-refresh de Supabase. Verifica directamente si `expiresAt < now`.

---

## 📊 Resumen de Barreras

| Barrera | Ubicación | Cuándo Actúa | Método de Detección |
|---------|-----------|--------------|---------------------|
| **#1 ProfileSetup** | `profile_setup_screen.dart` | 3 puntos: init, skip, navigate | `isAuthenticated` + `isSessionExpired()` |
| **#2 Auth Guard** | `main_navigation_screen.dart` | Init + Tiempo real | `isAuthenticated` + Listener + `isSessionExpired()` |
| **#3 Validación Manual** | `auth_service.dart` | Llamado explícitamente | Lee `expiresAt` del token |

---

## ✅ Comportamiento Esperado

### Escenario 1: Token expira en ProfileSetup
```
Usuario en ProfileSetup
Token expira
Usuario presiona "Skip"
  → Barrera #1.2: Detecta expiración
  → Muestra: "Tu sesión ha expirado"
  → NO navega al home
```

### Escenario 2: Token expira en Home
```
Usuario navegando en Home
Token expira
  → Barrera #2.2: Listener detecta user == null
  → Muestra SnackBar: "Tu sesión ha expirado"
  → Redirige automáticamente a login
```

### Escenario 3: Usuario intenta navegar con token expirado
```
Usuario completa perfil
Token expiró mientras llenaba form
Usuario presiona "Guardar"
  → Barrera #1.3: Detecta expiración
  → Muestra: "Tu sesión ha expirado"
  → Redirige a login (NO navega a home)
```

---

## 🧪 Cómo Testear

### Test 1: Barrera #1 en ProfileSetup
```dart
// 1. Verificar OTP
// 2. En ProfileSetup, ejecutar en DevTools:
await SupabaseConfig.client.auth.signOut();

// 3. Intentar "Skip" o completar perfil
// RESULTADO ESPERADO: Error "Tu sesión ha expirado" + NO navega
```

### Test 2: Barrera #2 en MainNavigation
```dart
// 1. Llegar al Home
// 2. En DevTools:
await SupabaseConfig.client.auth.signOut();

// RESULTADO ESPERADO: SnackBar + Redirige a login automáticamente
```

### Test 3: Barrera #3 - Validación Manual
```dart
// 1. Verificar OTP
// 2. En Supabase Dashboard, cambiar JWT Expiry a 120 (2 minutos)
// 3. Esperar 2-3 minutos
// 4. Intentar navegar

// RESULTADO ESPERADO: isSessionExpired() == true → Bloquea navegación
```

---

## 🎯 Ventajas del Sistema

1. **Triple Protección:** 3 capas independientes
2. **Detección Proactiva:** Listener en tiempo real detecta expiración automáticamente
3. **Validación Manual:** No depende del auto-refresh de Supabase
4. **UX Claro:** Mensajes claros al usuario sobre qué pasó
5. **Sin Memory Leaks:** Cleanup apropiado de subscriptions

---

## 📝 Notas Importantes

1. **Auto-Refresh de Supabase:**
   - Supabase renueva automáticamente los tokens a los ~55 minutos
   - Por eso es difícil ver tokens "realmente expirados" en testing normal
   - Para testear, usar `signOut()` manual o reducir JWT Expiry en Supabase

2. **Validación Manual (Barrera #3):**
   - Es independiente del auto-refresh
   - Lee directamente `expiresAt` del token
   - Compara con tiempo actual manualmente

3. **Listener (Barrera #2):**
   - Detecta cambios en `authStateChanges`
   - Se dispara cuando `user == null`
   - Funciona incluso si el auto-refresh falla

---

**Creado:** 2026-10-31  
**Última actualización:** 2026-10-31  
**Versión:** 1.0
