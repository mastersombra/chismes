# Configuración de OTP (Códigos de 6 dígitos) en Supabase

**Problema**: Por defecto, Supabase envía "magic links" (enlaces de confirmación) en lugar de códigos OTP de 6 dígitos.

**Solución**: Configurar Supabase para enviar códigos OTP en los emails de verificación.

---

## 🔧 Pasos para Configurar OTP

### Opción 1: Configurar Email Provider (Recomendado)

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a **Authentication** → **Providers**
3. Click en **Email**
4. Asegúrate que esté habilitado:
   - ✅ **Enable Email provider**
   - ✅ **Confirm email** (debe estar habilitado)
   - ✅ **Secure email change enabled**

### Opción 2: Configurar Email Templates

1. Ve a **Authentication** → **Email Templates**
2. Selecciona **Confirm signup**
3. **Reemplaza el contenido** con este template:

```html
<h2>Confirma tu correo electrónico</h2>
<p>Hola,</p>
<p>Gracias por registrarte en Chismes. Para confirmar tu correo electrónico, ingresa el siguiente código en la app:</p>
<h1 style="font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background: #f3f4f6; border-radius: 8px;">{{ .Token }}</h1>
<p>Este código es válido por <strong>60 minutos</strong>.</p>
<p>Si no solicitaste este código, ignora este correo.</p>
<p>Saludos,<br>El equipo de Chismes</p>
```

**Importante**: Usa `{{ .Token }}` (código) en lugar de `{{ .ConfirmationURL }}` (enlace)

### Opción 3: Configurar vía SQL (Avanzado)

Si quieres forzar OTP vía configuración de base de datos:

```sql
-- Verificar configuración actual
SELECT * FROM auth.config;

-- Configurar OTP
UPDATE auth.config 
SET 
  mailer_autoconfirm = false,
  email_confirm_signin = true;
```

---

## 🧪 Verificar Configuración

### 1. Probar Sign Up

```dart
await supabase.auth.signUp(
  email: 'test@example.com',
  password: 'password123',
);
```

### 2. Verificar Email

Deberías recibir un email con:
- ✅ Un código de 6 dígitos (ej: `123456`)
- ❌ NO un enlace de confirmación

### 3. Verificar OTP

```dart
await supabase.auth.verifyOTP(
  email: 'test@example.com',
  token: '123456',
  type: OtpType.signup,
);
```

---

## 📱 Flujo Completo en la App

```dart
// 1. Sign up
await authDataSource.signUpWithEmailOTP(
  email: email,
  password: password,
);

// 2. Usuario recibe email con código de 6 dígitos

// 3. Verificar código
final user = await authDataSource.verifyOTP(
  email: email,
  token: code, // Código de 6 dígitos
);
```

---

## 🚨 Problemas Comunes

### El email sigue enviando enlace en lugar de código

**Causa**: El template de email no fue actualizado correctamente.

**Solución**:
1. Ve a **Email Templates** → **Confirm signup**
2. Verifica que use `{{ .Token }}`
3. Click en **Save**
4. Prueba con un email nuevo (no reutilices emails anteriores)

### Error "Token has expired"

**Causa**: El código OTP expira en 60 minutos por defecto.

**Solución**:
- Solicita un nuevo código con `resendOTP()`
- O configura un tiempo de expiración mayor en Supabase (no recomendado por seguridad)

### Rate Limiting (429)

**Causa**: Supabase limita el número de emails que puedes enviar en un período de tiempo.

**Límites**:
- **Signup**: 1 email cada 60 segundos por email
- **Resend**: 1 email cada 60 segundos por email

**Solución**:
- Implementar cooldown en la UI (ya implementado en `OtpVerificationController`)
- Esperar 60 segundos entre reenvíos

---

## 🔒 Seguridad

### OTP vs Magic Links

| Aspecto | OTP (6 dígitos) | Magic Link |
|---------|-----------------|------------|
| Seguridad | ⭐⭐⭐ Medio | ⭐⭐⭐⭐ Alto |
| UX | ⭐⭐⭐⭐ Muy bueno | ⭐⭐⭐ Bueno |
| Tiempo de expiración | 60 min | 24 horas |
| Uso | Móvil (in-app) | Web (redirección) |

**Nota**: OTP es ideal para apps móviles porque el usuario no tiene que salir de la app para verificar el código.

### Mejores Prácticas

1. ✅ Limitar intentos de verificación (máximo 3-5 intentos)
2. ✅ Implementar cooldown entre reenvíos (60 segundos)
3. ✅ Expirar códigos después de 60 minutos
4. ✅ Usar HTTPS para todas las comunicaciones
5. ✅ No loggear códigos OTP en producción

---

## 📚 Referencias

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Email OTP](https://supabase.com/docs/guides/auth/phone-login)
- [Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates)

---

**Última actualización**: 2026-10-30
