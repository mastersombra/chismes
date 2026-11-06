# Flujo de Autenticación Reactivo - Chismes App

**Fecha:** 2026-11-03  
**Versión:** 1.0  
**Patrón:** Reactivo Puro (Enfoque 1)

---

## 🎯 Arquitectura

**AuthGate es la ÚNICA fuente de verdad para autenticación.**

```
main.dart
  └─ MaterialApp
      └─ home: AuthGate() ← Punto de entrada único
          │
          ├─ StreamBuilder<User?>
          │   └─ authRepository.authStateChanges
          │       │
          │       ├─ User existe → MainNavigationScreen
          │       │   └─ BottomNavigationBar
          │       │       ├─ HomeScreen
          │       │       ├─ SearchScreen
          │       │       ├─ AddGossipScreen
          │       │       └─ ProfileScreen
          │       │
          │       └─ User null → LoginScreen
          │           └─ SignupScreen
          │               └─ OtpVerificationScreen
          │                   └─ ProfileSetupScreen (opcional)
```

---

## 🔄 Flujos Automáticos

### 1. Apertura de App

```
Usuario abre app
  ↓
main() → inicializa Supabase
  ↓
AuthGate escucha authStateChanges
  ↓
Supabase restaura sesión desde storage local (~50-100ms)
  ↓
¿Hay sesión válida?
  ├─ SÍ → AuthGate muestra MainNavigationScreen (DIRECTO)
  └─ NO → AuthGate muestra LoginScreen (DIRECTO)
```

**Sin splash screen artificial, sin delays innecesarios.**

---

### 2. Login Exitoso

```
Usuario hace login en LoginScreen
  ↓
LoginController.signInWithEmail()
  ↓
AuthRepository.signInWithEmail()
  ↓
Supabase Auth guarda sesión en storage local
  ↓
authStateChanges emite User ← AUTOMÁTICO
  ↓
AuthGate detecta cambio ← StreamBuilder escuchando
  ↓
AuthGate muestra MainNavigationScreen ← AUTOMÁTICO
```

**LoginScreen NO navega manualmente. AuthGate lo hace automáticamente.**

---

### 3. Logout

```
Usuario presiona "Cerrar sesión" en ProfileScreen
  ↓
ProfileController.signOut()
  ↓
AuthRepository.signOut()
  ↓
Supabase Auth elimina sesión
  ↓
authStateChanges emite null ← AUTOMÁTICO
  ↓
AuthGate detecta cambio ← StreamBuilder escuchando
  ↓
AuthGate muestra LoginScreen ← AUTOMÁTICO
```

**ProfileScreen NO navega manualmente. AuthGate lo hace automáticamente.**

---

### 4. Cierre y Reapertura de App

```
Usuario cierra app (kill app o reinicia celular)
  ↓
[Sesión persiste en storage local]
  ↓
Usuario abre app nuevamente
  ↓
main() → inicializa Supabase
  ↓
Supabase restaura sesión automáticamente
  ↓
authStateChanges emite User (sesión restaurada)
  ↓
AuthGate muestra MainNavigationScreen ← SIN PEDIR LOGIN
```

**Usuario NO necesita volver a hacer login. Sesión persiste.**

---

### 5. Token Expirado

```
Token expira (default: 1 hora)
  ↓
Supabase intenta renovar token automáticamente
  ↓
¿Refresh token válido?
  ├─ SÍ → Token renovado, usuario sigue autenticado (invisible para usuario)
  └─ NO → authStateChanges emite null
           ↓
           AuthGate detecta cambio
           ↓
           AuthGate muestra LoginScreen
```

**Supabase maneja renovación automática de tokens.**

---

## 📝 Cambios Realizados

### Archivos Creados

1. **`lib/features/auth/presentation/widgets/auth_gate.dart`**
   - StreamBuilder que escucha `authStateChanges`
   - Decide entre `MainNavigationScreen` y `LoginScreen`
   - Única fuente de verdad para navegación de auth

### Archivos Modificados

2. **`lib/main.dart`**
   - Cambiado `home: LoginScreen()` por `home: AuthGate()`
   - Elimina navegación manual, AuthGate decide

3. **`lib/features/auth/presentation/screens/login_screen.dart`**
   - ✅ Eliminado `_navigateToHome()`
   - ✅ Eliminado import de `MainNavigationScreen`
   - ✅ `_onStateChanged()` ya NO navega manualmente
   - ✅ AuthGate detecta login automáticamente

4. **`lib/features/home/presentation/screens/main_navigation_screen.dart`**
   - ✅ Eliminado `_validateSessionOnInit()`
   - ✅ Eliminado `_setupAuthListener()`
   - ✅ Eliminado `_redirectToLogin()`
   - ✅ Eliminado `_authStateSubscription`
   - ✅ Eliminado dependencias de `AuthService` y `AppLogger`
   - ✅ Eliminado imports de `dart:async`, `AuthService`, `LoginScreen`
   - ✅ AuthGate ya maneja validación de sesión

5. **`lib/features/profile/presentation/screens/profile_screen.dart`**
   - ✅ Actualizado comentario: AuthGate maneja logout automáticamente
   - ✅ Ya no navega manualmente a LoginScreen

6. **`lib/features/auth/presentation/screens/profile_setup_screen.dart`**
   - ✅ Eliminado `_navigateToHome()`
   - ✅ Eliminado `_prefillData()` que usaba AuthService
   - ✅ Eliminado validación de sesión en `initState()`
   - ✅ Eliminado dependencia de `AuthService`
   - ✅ Eliminado imports de `AuthService` y `MainNavigationScreen`
   - ✅ `_onStateChanged()` y `_onSkipPressed()` ahora solo hacen `pop()`
   - ✅ AuthGate ya muestra MainNavigationScreen (usuario autenticado)

7. **`lib/features/auth/presentation/screens/privacy_consent_screen.dart`**
   - ✅ Cambiado `pushReplacementNamed('/home')` por `pop()`
   - ✅ AuthGate ya muestra MainNavigationScreen

### Archivos Eliminados

8. **`lib/features/auth/presentation/screens/splash_screen.dart`**
   - ❌ Eliminado completamente (delay artificial innecesario)
   - ✅ AuthGate muestra logo brevemente durante loading (~50-100ms)

---

## ✅ Verificaciones

### 1. Login Funciona
- [x] Usuario ingresa email y password
- [x] LoginController llama a AuthRepository
- [x] AuthGate detecta cambio automáticamente
- [x] Navega a MainNavigationScreen sin navegación manual

### 2. Logout Funciona
- [x] Usuario presiona "Cerrar sesión"
- [x] ProfileController llama a AuthRepository.signOut()
- [x] AuthGate detecta cambio automáticamente
- [x] Navega a LoginScreen sin navegación manual

### 3. Persistencia de Sesión Funciona
- [x] Usuario hace login
- [x] Supabase guarda sesión en storage local
- [x] Usuario cierra app
- [x] Usuario abre app nuevamente
- [x] AuthGate restaura sesión automáticamente
- [x] Usuario entra DIRECTO a MainNavigationScreen

### 4. No Acceso a Pantallas Privadas
- [x] Si usuario NO está autenticado, AuthGate muestra LoginScreen
- [x] MainNavigationScreen solo es accesible si AuthGate detecta User
- [x] No se puede "bypassear" navegando manualmente

### 5. No Parpadeos ni Navegaciones Duplicadas
- [x] AuthGate es StreamBuilder (reactivo puro)
- [x] No hay múltiples guards compitiendo
- [x] No hay navegaciones manuales que conflictúen
- [x] Una sola fuente de verdad

---

## 🚫 Anti-Patterns Eliminados

### ❌ ANTES (Navegación Manual)

```dart
// LoginScreen
void _onStateChanged() {
  if (state is AuthSuccess) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainNavigationScreen()),
    );
  }
}
```

### ✅ AHORA (Reactivo)

```dart
// LoginScreen
void _onStateChanged() {
  if (state is AuthSuccess) {
    // ✅ AuthGate detecta el cambio automáticamente
    // No navegamos manualmente
  }
}
```

---

### ❌ ANTES (Guards Duplicados)

```dart
// MainNavigationScreen
@override
void initState() {
  super.initState();
  _validateSessionOnInit();      // ❌ Guard duplicado
  _setupAuthListener();          // ❌ Guard duplicado
}
```

### ✅ AHORA (Sin Guards Duplicados)

```dart
// MainNavigationScreen
@override
void initState() {
  super.initState();
  _addGossipController = getIt<AddGossipController>();
  
  // ✅ AuthGate ya validó que usuario está autenticado
  // No necesitamos guards duplicados
}
```

---

## 📊 Comparación

| Aspecto | ANTES (Manual) | AHORA (Reactivo) |
|---------|----------------|------------------|
| **Navegación Login** | Manual (`pushReplacement`) | Automática (AuthGate) |
| **Navegación Logout** | Manual (`pushAndRemoveUntil`) | Automática (AuthGate) |
| **Guards** | 3 lugares (AuthGate, MainNav, Login) | 1 lugar (AuthGate) |
| **Persistencia** | Funciona pero navegación manual | Funciona + navegación automática |
| **Parpadeos** | Posibles (múltiples guards) | Ninguno (un solo guard) |
| **Mantenibilidad** | ⭐⭐ (lógica duplicada) | ⭐⭐⭐ (una sola fuente) |
| **Escalabilidad** | ⭐⭐ (bugs potenciales) | ⭐⭐⭐ (limpio) |
| **Código duplicado** | ⚠️ Sí | ✅ No |

---

## 🎓 Cómo Funciona Supabase Auth

### Persistencia Automática

```
Supabase Flutter usa `flutter_secure_storage` (iOS/Android):

iOS:     Keychain
Android: EncryptedSharedPreferences
Web:     localStorage

Cuando usuario hace login:
1. Supabase guarda access_token y refresh_token
2. Al reabrir app, Supabase.initialize() restaura sesión
3. authStateChanges emite User (restaurado)
4. AuthGate muestra MainNavigationScreen
```

### Renovación Automática de Tokens

```
Access Token: Expira en 1 hora (configurable)
Refresh Token: Expira en 30 días (configurable)

Cada request a Supabase:
1. Supabase verifica si access_token expiró
2. Si expiró, usa refresh_token para renovar
3. Guarda nuevo access_token automáticamente
4. Request continúa normalmente

Usuario NO necesita hacer login nuevamente.
```

### Cuándo Pedir Login Nuevamente

Solo en estos casos:
- Usuario hizo logout manualmente
- Refresh token expiró (30 días sin usar app)
- Usuario desinstaló y reinstalÓ app
- Usuario limpió datos de app manualmente

---

## 🔐 Seguridad

### RLS (Row Level Security)

```sql
-- Supabase verifica automáticamente user_id de cada request
-- usando el JWT token persistido

-- Ejemplo: Solo puedo leer mis propios chismes
CREATE POLICY "Users can read own gossips"
  ON gossips FOR SELECT
  USING (auth.uid() = user_id);
```

**Token persiste localmente, pero RLS valida en servidor.**

---

## 📚 Referencias

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)

---

## 🚀 Próximos Pasos (Opcional)

1. **Agregar biometría (Face ID, Touch ID)**
   ```dart
   final canAuthenticate = await LocalAuthentication().canCheckBiometrics;
   if (canAuthenticate) {
     await LocalAuthentication().authenticate();
   }
   ```

2. **Agregar timeout de inactividad**
   ```dart
   // Si usuario no usa app por 30 días, forzar re-login
   final lastActive = await prefs.getInt('last_active');
   if (DateTime.now().difference(lastActive).inDays > 30) {
     await authRepository.signOut();
   }
   ```

3. **Agregar logout en múltiples dispositivos**
   ```dart
   // Backend invalida refresh tokens de todos los dispositivos
   await authRepository.signOutAllDevices();
   ```

---

**FIN DEL DOCUMENTO**
