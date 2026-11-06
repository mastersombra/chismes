# Configurar Gmail SMTP para Supabase OTP

**Objetivo**: Configurar Gmail como servidor SMTP en Supabase para poder enviar códigos OTP de 6 dígitos.

---

## 📧 Paso 1: Generar App Password en Gmail

### Pre-requisito: Habilitar 2FA

1. Ve a [Google Account](https://myaccount.google.com/)
2. Click en **"Security"** (Seguridad)
3. Busca **"2-Step Verification"** (Verificación en 2 pasos)
4. Si NO está habilitado:
   - Click en "2-Step Verification"
   - Sigue los pasos para habilitar (usa tu teléfono)
   - **Importante**: Necesitas 2FA para generar App Passwords

### Generar App Password

1. Ve a [Google Account](https://myaccount.google.com/)
2. **Security** → Scroll down
3. Busca **"App passwords"** (Contraseñas de aplicaciones)
   - Si no lo ves, asegúrate de tener 2FA habilitado
4. Click en **"App passwords"**
5. Selecciona:
   - **App**: Mail
   - **Device**: Other (custom name)
   - Escribe: "Supabase Chismes"
6. Click **"Generate"**
7. **Copia el password de 16 caracteres** (formato: `xxxx xxxx xxxx xxxx`)
   - ⚠️ Guárdalo en un lugar seguro
   - ⚠️ Solo se muestra una vez

---

## ⚙️ Paso 2: Configurar SMTP en Supabase

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto "Chismes"
3. **Authentication** → **Email Templates**
4. Click en **"Set up SMTP"**
5. Ingresa la configuración:

```
Host: smtp.gmail.com
Port: 587
Username: tu-email@gmail.com  (tu email completo de Gmail)
Password: xxxx xxxx xxxx xxxx  (App Password de 16 caracteres)
Sender email: tu-email@gmail.com
Sender name: Chismes
```

6. Click **"Save"**
7. Supabase enviará un email de prueba
8. Verifica tu inbox de Gmail
9. Si llega el email de prueba → ✅ Configuración exitosa

---

## 📝 Paso 3: Editar Template "Confirm sign up"

Ahora que tienes SMTP custom, puedes editar templates:

1. En **Email Templates**
2. Click en **"Confirm sign up"** →
3. Click en **"Source"** (arriba del body)
4. **Reemplaza TODO el contenido** con:

```html
<h2>Bienvenido a Chismes</h2>
<p>Gracias por registrarte. Para confirmar tu cuenta, ingresa este código en la app:</p>

<div style="text-align: center; margin: 30px 0;">
  <h1 style="font-size: 48px; font-weight: bold; letter-spacing: 8px; padding: 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 12px; display: inline-block;">
    {{ .Token }}
  </h1>
</div>

<p style="color: #666; font-size: 14px;">Este código es válido por <strong>60 minutos</strong>.</p>
<p style="color: #999; font-size: 12px;">Si no solicitaste este registro, ignora este correo.</p>

<hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">

<p style="color: #999; font-size: 12px;">
  Saludos,<br>
  El equipo de Chismes
</p>
```

5. **Opcional**: Edita el Subject (asunto):
   ```
   Antes: "Confirm your email address"
   Después: "Tu código de verificación - Chismes"
   ```

6. Click **"Save"**

---

## ✅ Paso 4: Probar

1. En tu app Flutter, crea un usuario **nuevo** con un email diferente
2. Deberías recibir un email en tu Gmail con:
   - ✅ Un código de 6 dígitos (ej: `123456`)
   - ✅ Diseño bonito con gradiente morado
   - ❌ NO un enlace de confirmación

3. Ingresa el código en la app
4. Debería verificar correctamente

---

## 🚨 Problemas Comunes

### "Invalid credentials" al guardar SMTP

**Causa**: App Password incorrecto o 2FA no habilitado

**Solución**:
1. Verifica que 2FA esté habilitado en Google
2. Genera un nuevo App Password
3. Copia y pega sin espacios
4. Usa tu email completo como username

### El email no llega

**Causa 1**: Gmail bloqueó el email por sospechoso

**Solución**:
1. Revisa la carpeta de Spam
2. Revisa Gmail → Settings → Filters
3. Verifica que no haya filtros bloqueando

**Causa 2**: Límite de Gmail alcanzado (500/día)

**Solución**:
- Espera 24 horas
- O migra a SendGrid

### "SMTP test failed"

**Causa**: Configuración incorrecta

**Solución**:
1. Verifica que el Port sea `587` (no 465 ni 25)
2. Verifica que Host sea `smtp.gmail.com` (no gmail.com)
3. Verifica que Username sea tu email completo
4. Verifica que Password sea el App Password (no tu contraseña normal)

---

## 📊 Límites de Gmail

| Aspecto | Límite |
|---------|--------|
| Emails por día | 500 |
| Emails por hora | ~100 |
| Destinatarios por email | 1 |
| Tamaño máximo | 25 MB |

**Para producción**: Considera migrar a SendGrid (100/día gratis) o AWS SES ($0.10/1000 emails)

---

## 🔒 Seguridad

### ✅ Buenas Prácticas

1. **NO** compartas tu App Password
2. **NO** commites el App Password al repo
3. **Usa** diferentes App Passwords para diferentes servicios
4. **Revoca** App Passwords que no uses
5. **Monitorea** actividad sospechosa en Google Account

### Revocar App Password

Si comprometes tu App Password:

1. Ve a [Google Account](https://myaccount.google.com/)
2. **Security** → **App passwords**
3. Click en el App Password de "Supabase Chismes"
4. Click **"Revoke"**
5. Genera uno nuevo y actualiza en Supabase

---

## 🚀 Siguiente Paso: Migrar a Producción

Cuando estés listo para producción:

1. **Compra un dominio** (ej: `chismes.app`)
2. **Configura SendGrid** con tu dominio
3. **Verifica el dominio** en SendGrid (SPF, DKIM)
4. **Actualiza SMTP** en Supabase con SendGrid
5. **Actualiza emails** de `tu-email@gmail.com` a `noreply@chismes.app`

Ver: `SENDGRID_SETUP.md` (próximamente)

---

**Última actualización**: 2026-10-30
