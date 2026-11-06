# Configurar SendGrid SMTP para Supabase OTP

**Ventajas sobre Gmail:**
- ✅ 100 emails/día gratis (vs 500 de Gmail, pero más profesional)
- ✅ Mejor deliverability (menos spam)
- ✅ No requiere 2FA ni App Passwords
- ✅ Profesional (emails desde `noreply@tudominio.com`)
- ✅ Dashboard con analytics de emails

**Desventajas:**
- ⏱️ Toma ~10 minutos (vs 5 de Gmail)
- 📧 Requiere verificación de email/dominio

---

## 📝 Paso 1: Crear Cuenta en SendGrid

1. Ve a [SendGrid](https://sendgrid.com/)
2. Click en **"Start for Free"** o **"Sign Up"**
3. Completa el registro:
   - Email: `tu-email@gmail.com` (tu email personal)
   - Password: (tu contraseña segura)
   - Click **"Create Account"**

4. **Verifica tu email**:
   - Revisa tu inbox
   - Click en el enlace de verificación

5. **Completa el cuestionario** (onboarding):
   - What do you do? → **Developer**
   - What are you building? → **Mobile App**
   - How many emails per month? → **Less than 40k**
   - What is your goal? → **Transactional emails**

6. **Salta el tutorial** (opcional)

---

## 🔑 Paso 2: Verificar Sender Identity (Single Sender)

SendGrid requiere verificar **quién** envía los emails. Para testing, usa "Single Sender":

1. En el dashboard de SendGrid, ve a:
   - **Settings** → **Sender Authentication**
   - O directo: [Sender Authentication](https://app.sendgrid.com/settings/sender_auth)

2. Scroll down hasta **"Single Sender Verification"**
3. Click en **"Get Started"** o **"Create New Sender"**

4. Completa el formulario:
   ```
   From Name: Chismes
   From Email Address: tu-email@gmail.com
   Reply To: tu-email@gmail.com
   Company Address: (tu dirección o cualquiera)
   City: (tu ciudad)
   State: (tu estado/provincia)
   Zip Code: (tu código postal)
   Country: Colombia (o tu país)
   Nickname: Chismes Development
   ```

5. Click **"Create"**

6. **Verifica el email**:
   - SendGrid enviará un email a `tu-email@gmail.com`
   - Abre el email
   - Click en **"Verify Single Sender"**
   - Deberías ver "Sender verified successfully" ✅

---

## 🔐 Paso 3: Generar API Key

1. En SendGrid dashboard, ve a:
   - **Settings** → **API Keys**
   - O directo: [API Keys](https://app.sendgrid.com/settings/api_keys)

2. Click en **"Create API Key"**

3. Configuración:
   ```
   API Key Name: Supabase Chismes
   API Key Permissions: Restricted Access
   ```

4. En **"Restricted Access"**, expande **"Mail Send"**:
   - ✅ **Mail Send** → **Full Access**
   - Todo lo demás en "No Access"

5. Click **"Create & View"**

6. **Copia la API Key** que aparece:
   ```
   SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   - ⚠️ **IMPORTANTE**: Se muestra solo UNA VEZ
   - ⚠️ Guárdala en un lugar seguro (ej: Notes, password manager)
   - ⚠️ Después de cerrar NO podrás verla de nuevo

7. Click **"Done"**

---

## ⚙️ Paso 4: Configurar SMTP en Supabase

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto "Chismes"
3. **Authentication** → **Email Templates**
4. Click en **"Set up SMTP"**
5. Ingresa la configuración de SendGrid:

```
Host: smtp.sendgrid.net
Port: 587
Username: apikey
Password: SG.xxxxx... (tu API Key completa de SendGrid)
Sender email: tu-email@gmail.com (el que verificaste en SendGrid)
Sender name: Chismes
```

⚠️ **IMPORTANTE**:
- El **Username** es literalmente la palabra `apikey` (no tu email)
- El **Password** es tu API Key completa (empieza con `SG.`)
- El **Sender email** debe ser el mismo que verificaste en SendGrid

6. Click **"Save"**

7. Supabase enviará un email de prueba
   - Si llega → ✅ Configuración exitosa
   - Si no llega → Revisa los pasos anteriores

---

## 📝 Paso 5: Editar Template "Confirm sign up"

Ahora que tienes SMTP custom, edita el template:

1. En **Email Templates** → **Confirm sign up** →
2. Click en **"Source"** (arriba del body)
3. **Reemplaza todo** con:

```html
<h2>Bienvenido a Chismes</h2>
<p>Para confirmar tu cuenta, ingresa este código en la app:</p>

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

4. **Opcional**: Cambia el Subject:
   ```
   Tu código de verificación - Chismes
   ```

5. Click **"Save"**

---

## ✅ Paso 6: Probar

1. En tu app Flutter, crea un usuario **nuevo**
2. Deberías recibir email con código de 6 dígitos
3. Ingresa el código en la app
4. Debería verificar ✅

---

## 🚨 Problemas Comunes

### "Authentication failed" al guardar SMTP

**Causa**: API Key incorrecta o username incorrecto

**Solución**:
1. Verifica que Username sea `apikey` (literal)
2. Verifica que Password sea tu API Key completa (con `SG.`)
3. No agregues espacios al copiar/pegar
4. Genera una nueva API Key si es necesario

### "Sender address is not verified"

**Causa**: El Sender email no fue verificado en SendGrid

**Solución**:
1. Ve a SendGrid → Settings → Sender Authentication
2. Verifica que tu email tenga ✅ "Verified"
3. Si no, reenvía el email de verificación
4. Usa exactamente el mismo email en Supabase SMTP

### El email no llega

**Causa 1**: Email en spam

**Solución**:
- Revisa carpeta de spam
- Marca como "Not spam"

**Causa 2**: Sender no verificado

**Solución**:
- Verifica que tu Single Sender esté verificado ✅

**Causa 3**: API Key sin permisos

**Solución**:
- Genera nueva API Key con "Mail Send - Full Access"

---

## 📊 Límites de SendGrid (Free Plan)

| Aspecto | Límite |
|---------|--------|
| Emails por día | 100 |
| Emails por mes | ~3,000 |
| Destinatarios por email | 1 |
| Tamaño máximo | 30 MB |
| API Key expiration | Never (si no la revocas) |

**Para más volumen**: Planes pagos desde $19.95/mes (40k emails)

---

## 🚀 Bonus: Verificar Dominio Propio (Producción)

Cuando tengas un dominio (ej: `chismes.app`), verifica el dominio completo:

1. **Compra dominio** en Namecheap, GoDaddy, Cloudflare, etc.

2. En SendGrid:
   - Settings → Sender Authentication
   - **Authenticate Your Domain**
   - Sigue el wizard

3. **Agrega DNS records** en tu proveedor de dominio:
   - SPF record
   - DKIM records (2-3 CNAME)
   - DMARC record (opcional)

4. **Espera propagación** (~24-48 horas)

5. **Actualiza Supabase SMTP**:
   ```
   Sender email: noreply@chismes.app
   ```

**Ventajas de dominio verificado:**
- ✅ Mejor deliverability
- ✅ Menos spam
- ✅ Emails más profesionales
- ✅ Branding consistente

---

## 🔒 Seguridad

### ✅ Buenas Prácticas

1. **NO** compartas tu API Key
2. **NO** commites la API Key al repo Git
3. **Rota** la API Key cada 3-6 meses
4. **Usa** API Keys con permisos mínimos (solo Mail Send)
5. **Monitorea** activity en SendGrid dashboard

### Revocar API Key

Si comprometes tu API Key:

1. Ve a SendGrid → Settings → API Keys
2. Click en los 3 puntos (...) al lado de la key
3. Click **"Delete"**
4. Genera una nueva
5. Actualiza en Supabase

### Variables de Entorno

Para producción, **NO** pongas la API Key directo en código:

```bash
# .env (NO commitear)
SENDGRID_API_KEY=SG.xxxxx...
```

Pero en Supabase dashboard, sí la pegas directamente (está seguro).

---

## 📈 Monitoreo

Dashboard de SendGrid muestra:
- Emails enviados
- Emails entregados
- Bounces (rebotes)
- Spam reports
- Opens (si habilitas tracking)
- Clicks (si habilitas tracking)

Para ver stats:
1. SendGrid → **Activity** → **Stats**
2. Filtra por fecha

---

## 💰 Costos (Futuro)

| Plan | Emails/mes | Precio |
|------|------------|--------|
| **Free** | 100/día (~3k/mes) | $0 |
| **Essentials** | 40k | $19.95/mes |
| **Essentials** | 100k | $34.95/mes |
| **Pro** | 1.5M | $89.95/mes |

**Para Chismes MVP**: Free plan es suficiente
**Para 1k usuarios activos**: Free plan OK
**Para 10k usuarios**: Considera Essentials

---

## 🆚 Comparación: SendGrid vs Gmail

| Aspecto | SendGrid | Gmail |
|---------|----------|-------|
| Setup | 10 min | 5 min |
| Límite diario | 100 | 500 |
| Profesional | ✅ | ❌ |
| Analytics | ✅ | ❌ |
| Deliverability | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Costo | Gratis | Gratis |
| Escalable | ✅ | ❌ |
| Dominio propio | ✅ | ❌ |

**Recomendación**: SendGrid para producción, Gmail para testing rápido

---

## 📚 Referencias

- [SendGrid Docs](https://docs.sendgrid.com/)
- [SMTP Integration](https://docs.sendgrid.com/for-developers/sending-email/integrating-with-the-smtp-api)
- [Sender Authentication](https://docs.sendgrid.com/ui/account-and-settings/how-to-set-up-domain-authentication)

---

**Última actualización**: 2026-10-30
