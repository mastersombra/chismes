# Re-registro: Prevención de Registro Malicioso

**Fecha:** 2026-10-30  
**Feature:** Permitir re-registro cuando el email no está verificado  
**Estado:** ✅ Implementado

---

## 📝 **Problema**

### **Escenario de Ataque:**

1. 🦹 **Usuario Malicioso** registra `victima@gmail.com` (email de otra persona)
2. ❌ **No verifica** el código OTP
3. 😔 **Víctima Real** intenta registrarse con su propio email
4. ⚠️ **Problema:** "Email ya registrado" → Víctima bloqueada

---

## ✅ **Solución Implementada**

### **Flujo Automático:**

```
Usuario intenta registrarse con email existente
  ↓
¿Email verificado?
  ├─ NO  → Reenviar OTP automáticamente → Pantalla de verificación
  └─ SÍ  → Mostrar error: "Email ya registrado y verificado. Inicia sesión."
```

### **Ventajas:**

1. ✅ **Usuario legítimo siempre gana** - Quien tiene acceso al email puede verificar
2. ✅ **Automático** - No requiere acción manual del usuario
3. ✅ **Seguro** - Solo quien tiene acceso al email puede completar el registro
4. ✅ **UX transparente** - Usuario no nota el problema, simplemente recibe el código

---

## 🔧 **Implementación Técnica**

### **Archivos Modificados:**

1. `lib/features/auth/presentation/controllers/signup_controller.dart`
   - Agregado `_handleEmailAlreadyInUse()` 
   - Detecta `ErrorCode.emailAlreadyInUse`
   - Intenta reenviar OTP automáticamente

2. `lib/features/auth/presentation/state/auth_state.dart`
   - Agregado `AuthError.custom()` constructor
   - Permite mensajes personalizados de error

### **Lógica:**

```dart
// En SignupController
if (failure.code == ErrorCode.emailAlreadyInUse) {
  // Intentar reenviar OTP
  final resendResult = await _authRepository.resendOTP(email: email);
  
  if (resendResult.isSuccess) {
    // Email NO verificado → permitir re-registro
    _setState(AuthOtpSent(email));
  } else {
    // Email YA verificado → mostrar error
    _setState(AuthError.custom(
      'Este email ya está registrado y verificado. Inicia sesión en su lugar.',
    ));
  }
}
```

---

## 🧪 **Casos de Prueba**

### **Caso 1: Email no verificado (Re-registro Exitoso)**

**Setup:**
```sql
-- Usuario existe pero email_confirmed_at = null
SELECT email, email_confirmed_at FROM auth.users 
WHERE email = 'test@example.com';
-- Result: test@example.com | null
```

**Flujo:**
1. Usuario intenta registrarse con `test@example.com`
2. Sistema detecta que email ya existe
3. Sistema intenta reenviar OTP → ✅ Éxito
4. Usuario recibe nuevo código
5. Usuario verifica código → Toma control de la cuenta

**Resultado Esperado:** ✅ Usuario completa registro exitosamente

---

### **Caso 2: Email ya verificado (Error)**

**Setup:**
```sql
-- Usuario existe Y email_confirmed_at tiene valor
SELECT email, email_confirmed_at FROM auth.users 
WHERE email = 'verified@example.com';
-- Result: verified@example.com | 2026-10-30 15:30:00+00
```

**Flujo:**
1. Usuario intenta registrarse con `verified@example.com`
2. Sistema detecta que email ya existe
3. Sistema intenta reenviar OTP → ❌ Falla (ya verificado)
4. Sistema muestra mensaje de error

**Resultado Esperado:** ❌ "Este email ya está registrado y verificado. Inicia sesión en su lugar."

---

### **Caso 3: Email nuevo (Flujo Normal)**

**Flujo:**
1. Usuario se registra con email nuevo
2. Sistema envía código OTP
3. Usuario verifica código
4. Registro completado

**Resultado Esperado:** ✅ Flujo normal sin cambios

---

## 🔄 **Flujo Completo (Diagrama)**

```
┌─────────────────────────────────────────────────┐
│ Usuario intenta Sign Up con email X             │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │ Email existe? │
         └───┬───────┬───┘
             │       │
         NO  │       │ SÍ
             │       │
             ▼       ▼
      ┌──────────┐ ┌─────────────────┐
      │ Enviar   │ │ Reenviar OTP    │
      │ OTP      │ │ (automático)    │
      └────┬─────┘ └────┬────────────┘
           │            │
           │            ▼
           │     ┌──────────────┐
           │     │ ¿Funcionó?   │
           │     └──┬───────┬───┘
           │        │       │
           │    SÍ  │       │ NO
           │        │       │
           ▼        ▼       ▼
      ┌─────────────────┐ ┌──────────────────┐
      │ Pantalla OTP    │ │ Error: Email ya  │
      │                 │ │ verificado       │
      └────────┬────────┘ └──────────────────┘
               │
               ▼
      ┌─────────────────┐
      │ Verificar Código│
      └────────┬────────┘
               │
               ▼
      ┌─────────────────┐
      │ Registro OK ✅  │
      └─────────────────┘
```

---

## 📊 **Mensajes de Usuario**

| Situación | Mensaje |
|-----------|---------|
| Email nuevo | "Te enviamos un código a tu email" |
| Email no verificado (re-registro) | "Te enviamos un código a tu email" (sin cambios) |
| Email ya verificado | "Este email ya está registrado y verificado. Inicia sesión en su lugar." |

**Nota:** El usuario con email no verificado **no nota ninguna diferencia** - simplemente recibe el código y continúa.

---

## 🛡️ **Seguridad**

### **¿Por qué es seguro?**

1. **Control del Email:** Solo quien tiene acceso al email puede verificar el código
2. **OTP Expirable:** Los códigos expiran en 10 minutos
3. **Rate Limiting:** Supabase limita reenvíos (1 por minuto)
4. **Sin Info Leak:** No revelamos si un email está registrado o no hasta después del intento de reenvío

### **¿Qué previene?**

- ✅ Registro malicioso de emails ajenos
- ✅ Bloqueo de cuentas legítimas
- ✅ Spam de registros

### **¿Qué NO previene?**

- ❌ Alguien con acceso al email (ese es el dueño legítimo)
- ❌ Rate limiting bypass (manejado por Supabase)

---

## 🔄 **Combinación con Cleanup Automático**

Esta feature se complementa con cleanup automático de usuarios no verificados:

```sql
-- Ejecutar diariamente a las 3 AM
DELETE FROM auth.users
WHERE email_confirmed_at IS NULL
  AND created_at < NOW() - INTERVAL '24 hours';
```

**Resultado:** 
- Re-registro funciona en las primeras 24 horas
- Después de 24h, el usuario no verificado se elimina automáticamente
- Usuario legítimo puede registrarse limpiamente

Ver: `docs/CLEANUP_UNVERIFIED_USERS.md` (pendiente)

---

## 🚀 **Próximas Mejoras**

### **Opción 1: Mostrar mensaje diferente**

En lugar de ocultarlo, informar explícitamente:

```
"Este email ya fue registrado pero no verificado. 
Te reenviamos el código de verificación."
```

**Pros:** Más transparente  
**Contras:** Leak de información (revela si email está en BD)

### **Opción 2: Limitar reintentos**

Agregar contador de reintentos de re-registro:

```dart
if (retryCount > 3) {
  return Error('Demasiados intentos. Espera 1 hora.');
}
```

**Pros:** Previene spam  
**Contras:** Más complejidad

---

## 📚 **Referencias**

- **Implementación Similar:** WhatsApp, Telegram (permiten re-registro)
- **Patrón de Seguridad:** Email Verification Flow
- **Estándar:** OAuth 2.0 Email Verification

---

## ✅ **Checklist de Implementación**

- [x] Detectar error `emailAlreadyInUse`
- [x] Intentar reenviar OTP automáticamente
- [x] Navegar a OTP screen si email no verificado
- [x] Mostrar error apropiado si email ya verificado
- [x] Agregar constructor `AuthError.custom()`
- [x] Tests de flujo completo
- [ ] Agregar cleanup automático (24 horas)
- [ ] Documentar en user-facing docs

---

**Última actualización:** 2026-10-30  
**Mantenedor:** Alejo
