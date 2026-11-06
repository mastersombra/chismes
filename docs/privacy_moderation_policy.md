# Política de Privacidad - Moderación de Contenido

**Fecha:** 2026-10-22  
**Status:** ⚠️ PENDIENTE REVISIÓN  
**Versión:** 0.1 (Draft)

---

## 🔒 Resumen Ejecutivo

**Chismes** usa moderación híbrida (reglas locales + OpenAI Moderation API) para detectar contenido problemático:

- ✅ Moderación automática antes de publicar
- ⚠️ Texto se envía a OpenAI Moderation API
- ⚠️ Usuario debe consentir antes de usar la app
- ⚠️ Requiere actualizar política de privacidad

---

## 📋 Flujo de Moderación Actual

### 1. Usuario crea gossip

```
Usuario escribe:
- Título (subject)
- Contenido (content)
- Opcionalmente: imagen, audio
```

### 2. Validación local

```
Edge Function valida:
- Longitud de texto
- Formato válido
- Rate limiting
```

### 3. Moderación de texto

**Fase 1: Reglas locales (10ms)**
- Amenazas creíbles
- Datos personales (email, teléfono)
- Spam (URLs, repeticiones)
- Términos de revisión (profanidad)

**Fase 2: OpenAI Moderation API (200ms)** ⚠️
```typescript
// ⚠️ ENVÍA TEXTO A OPENAI
const openaiResponse = await fetch('https://api.openai.com/v1/moderations', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${openaiKey}`
  },
  body: JSON.stringify({ input: rawText })  // subject + content
})
```

**Categorías detectadas por OpenAI:**
- `hate`
- `hate/threatening`
- `harassment`
- `harassment/threatening`
- `self-harm`
- `sexual`
- `sexual/minors`
- `violence`
- `violence/graphic`

### 4. Decisión

- **Rechazado:** No se publica, usuario recibe feedback
- **Revisión:** Se publica en estado "pending" (requiere revisión manual)
- **Aprobado:** Se publica inmediatamente

---

## ⚠️ Privacidad y Moderación

### Datos enviados a OpenAI

**Lo que SÍ se envía:**
- Título del gossip (subject)
- Contenido del gossip (content)

**Lo que NO se envía:**
- Imagen (solo texto)
- Audio (solo texto)
- Ubicación
- ID de usuario
- Metadata

### Política de OpenAI

**Retención de datos (OpenAI):**
- OpenAI retiene datos por **30 días** para monitoreo de abuso
- Después de 30 días, se eliminan
- NO se usan para entrenar modelos (desde marzo 2023)

**Fuente:** https://openai.com/policies/api-data-usage-policies

### Cumplimiento Legal

**GDPR - Transferencia internacional:**
- OpenAI (USA) no está en UE
- Requiere **cláusulas contractuales estándar** (SCC)
- Requiere **consentimiento explícito** del usuario

**CCPA - Divulgación a terceros:**
- Requiere divulgación en política de privacidad
- Usuario debe poder opt-out (difícil en MVP)

---

## ✅ Acciones Requeridas ANTES de Lanzamiento

### 1. Actualizar Política de Privacidad

Agregar sección:

```markdown
## Moderación de Contenido

Para mantener Chismes seguro, moderamos todo el contenido antes de publicarlo.

### ¿Qué datos compartimos?
- El texto de tu chisme (título y contenido) se envía a OpenAI Moderation API
- NO compartimos tu nombre, ubicación ni otros datos personales
- NO compartimos imágenes ni audios

### ¿Por qué?
- Para detectar contenido inapropiado automáticamente
- Para cumplir con nuestras normas de comunidad

### ¿Cuánto tiempo se retiene?
- OpenAI retiene el texto por 30 días (monitoreo de abuso)
- Después se elimina automáticamente
- NO se usa para entrenar modelos de IA

### Alternativas
- Si no estás de acuerdo, no uses la app
- (Futuro) Ofreceremos moderación solo local (más lenta, menos precisa)
```

### 2. Agregar Consentimiento en Onboarding

**Pantalla de bienvenida:**
```
Bienvenido a Chismes

Para mantener la comunidad segura, moderamos todo el contenido 
con la ayuda de OpenAI Moderation API.

El texto de tus chismes (no imágenes ni ubicación) se analiza 
para detectar contenido inapropiado.

Los datos se retienen por 30 días y luego se eliminan.

[Ver Política de Privacidad]

[ ] Acepto la Política de Privacidad y Términos de Uso

[Continuar]
```

### 3. Link a Términos y Políticas

**Agregar en:**
- Pantalla de registro
- Settings → Acerca de
- Footer de la app

### 4. Documentar en README

Agregar a README.md:

```markdown
## Privacidad

Chismes respeta tu privacidad:

- **Ubicación:** Solo guardamos tu ciudad (no coordenadas exactas)
- **Moderación:** El texto se envía a OpenAI por 30 días
- **Media:** Imágenes y audio NO se moderan (solo texto)
- **Datos:** No vendemos ni compartimos tus datos

Ver: [docs/privacy_policy.md](docs/privacy_policy.md)
```

---

## 🚀 Mejoras Futuras (Opcional)

### Opción 1: Moderación solo local (sin OpenAI)

**Pros:**
- Sin envío de datos a terceros
- Más privado

**Contras:**
- Menos precisa
- Más falsos positivos/negativos

**Implementación:**
```typescript
// Flag en config
const USE_OPENAI_MODERATION = Deno.env.get('USE_OPENAI_MODERATION') === 'true'

if (USE_OPENAI_MODERATION) {
  // Fase 2: OpenAI
} else {
  // Solo reglas locales
}
```

### Opción 2: Moderación de imagen/audio

**Problema actual:**
- Solo se modera texto
- Imagen/audio pueden contener contenido problemático

**Solución:**
- OpenAI Vision API para imagen
- Whisper API → Transcripción → Moderation API para audio

**Costo:**
- Vision: $0.01 - $0.02 por imagen
- Whisper: $0.006 por minuto de audio

### Opción 3: Opt-out de moderación automática

**Para usuarios confiables:**
- Después de X gossips aprobados
- Opción de "publicar sin moderación previa"
- Moderación post-publicación (reporte de usuarios)

---

## 📊 Comparación con Apps Similares

| App | Moderación | Proveedor 3ro | Transparencia |
|-----|-----------|---------------|---------------|
| **Chismes** | Híbrida (local + OpenAI) | OpenAI | ⚠️ Pendiente |
| Twitter | ML propio | - | Baja |
| Facebook | ML propio + humana | - | Media |
| Reddit | Humana + Automod | - | Alta |

---

## 🧪 Testing

### Verificar que moderación funciona:

**Test 1: Amenaza creíble (debe rechazar)**
```
Subject: "Amenaza"
Content: "Te voy a matar"
Resultado esperado: ❌ Rechazado (local rules)
```

**Test 2: Contenido sexual (debe rechazar/revisar)**
```
Subject: "Contenido adulto"
Content: "Contenido explícitamente sexual..."
Resultado esperado: ❌ Rechazado por OpenAI
```

**Test 3: Contenido normal (debe aprobar)**
```
Subject: "Chisme del barrio"
Content: "Ayer vi a mi vecino paseando su perro"
Resultado esperado: ✅ Aprobado
```

### Verificar logs de OpenAI:

```bash
# En logs de Edge Function buscar:
"FLAGGED BY OPENAI: [categorías]"
```

---

## ✅ Checklist Pre-Lanzamiento

**Privacidad y Legal:**
- [ ] Escribir política de privacidad completa
- [ ] Agregar sección de moderación con OpenAI
- [ ] Escribir términos de uso
- [ ] Agregar pantalla de consentimiento en onboarding
- [ ] Link a políticas en settings
- [ ] Documentar en README

**Técnico:**
- [x] Moderación implementada
- [x] Reglas locales + OpenAI
- [ ] Logging de decisiones de moderación
- [ ] Dashboard de moderación (admin)
- [ ] Sistema de apelación (futuro)

**Testing:**
- [ ] Test de contenido problemático (rechazar)
- [ ] Test de contenido normal (aprobar)
- [ ] Verificar que solo texto se envía a OpenAI
- [ ] Verificar que imagen/audio NO se envían

---

## 📞 FAQ

**P: ¿Por qué usan moderación automática?**
R: Para detectar contenido problemático rápidamente y mantener la comunidad segura.

**P: ¿Qué datos envían a OpenAI?**
R: Solo el texto del chisme (título + contenido). NO envían imagen, audio ni datos personales.

**P: ¿Cuánto tiempo guarda OpenAI mis datos?**
R: 30 días, luego se eliminan automáticamente. NO se usan para entrenar modelos.

**P: ¿Puedo optar por no usar OpenAI?**
R: En el MVP, no. En el futuro consideraremos opción de moderación solo local.

**P: ¿Qué pasa si mi chisme es rechazado?**
R: Recibes feedback sobre por qué fue rechazado. Puedes editar y reenviar.

**P: ¿Hay revisión humana?**
R: En el MVP, solo en casos flagged como "revisión". En producción habrá equipo de moderadores.

---

**FIN DEL DOCUMENTO**

**⚠️ IMPORTANTE:** Este documento es un DRAFT. Requiere revisión legal antes de lanzamiento público.
