# Edge Function: Moderación Híbrida + Creación de Gossip

## 🎯 Objetivo

**Función TODO-EN-UNO** para máxima seguridad:
1. **Moderar contenido** (reglas + OpenAI)
2. **Decidir estados** internamente (cliente NO participa)
3. **Crear gossip** en DB con service_role
4. **Retornar gossip** ya creado

## 🔒 Seguridad

Esta implementación previene **bypass de moderación**:
- ✅ Cliente NO decide estados (publish/draft/pending/approved)
- ✅ Service role bypasa RLS (INSERT controlado por servidor)
- ✅ Imposible hackear desde APK modificado
- ✅ Veredicto de moderación NO se expone al cliente

## 💰 Costo

- **$0 hasta 500K gossips/mes** - Dentro del límite gratis
- **$2 por millón** después de 500K/mes
- OpenAI Moderation API: Gratis sin límite

## 🚀 Despliegue

### 1. Instalar Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Verificar instalación
supabase --version
```

### 2. Login en Supabase

```bash
supabase login
```

### 3. Desplegar la función

```bash
# Desde la raíz del proyecto
supabase functions deploy moderate-gossip

# Verificar que se desplegó
supabase functions list
```

## 🔑 Configuración de OpenAI API Key

### Opción 1: Supabase Dashboard (Recomendado)

1. Ve a tu proyecto en https://supabase.com/dashboard
2. Ve a **Edge Functions** > **Secrets**
3. Agrega un nuevo secret:
   - **Name:** `OPENAI_API_KEY`
   - **Value:** Tu API key de OpenAI (empieza con `sk-proj-...`)
4. Guarda

### Opción 2: CLI

```bash
supabase secrets set OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxx
```

### Obtener OpenAI API Key (Gratis)

1. Ve a https://platform.openai.com/api-keys
2. Crea una cuenta (si no tienes)
3. Crea un nuevo API key
4. **NO requiere billing configurado** - Moderation API es gratis

## 📋 Flujo de Moderación

| Veredicto Interno | Estado en DB | Acción |
|-------------------|--------------|--------|
| `publish` | `published` + `approved` | Gossip público inmediatamente |
| `review` | `draft` + `pending` | Gossip en revisión manual |
| `reject` | No se crea | Error 400 retornado a Flutter |

## 🧪 Testing Local

### 1. Ejecutar función localmente

```bash
# Iniciar Supabase local
supabase start

# Servir la función
supabase functions serve moderate-gossip --env-file supabase/functions/.env
```

### 2. Probar con curl

```bash
# Contenido limpio (debería crear gossip con status=published)
curl -i --location --request POST 'http://localhost:54321/functions/v1/moderate-gossip' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "subject": "Hola",
    "content": "Este es un mensaje normal",
    "country_id": "1",
    "region_id": "1",
    "city_id": "1",
    "published_as": "anonymous"
  }'

# Respuesta esperada:
# {"gossip": {"id": "...", "status": "published", "moderation_status": "approved", ...}}

# Contenido con profanidad (debería crear gossip con status=draft)
curl -i --location --request POST 'http://localhost:54321/functions/v1/moderate-gossip' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "subject": "Test",
    "content": "eres un hijueputa",
    "country_id": "1",
    "region_id": "1",
    "city_id": "1",
    "published_as": "anonymous"
  }'

# Respuesta esperada:
# {"gossip": {"id": "...", "status": "draft", "moderation_status": "pending", ...}}

# Amenaza directa (NO debería crear gossip, error 400)
curl -i --location --request POST 'http://localhost:54321/functions/v1/moderate-gossip' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "subject": "Test",
    "content": "te voy a matar",
    "country_id": "1",
    "region_id": "1",
    "city_id": "1",
    "published_as": "anonymous"
  }'

# Respuesta esperada:
# HTTP 400
# {"error": "Content rejected by moderation", "reasons": ["credible_threat"], ...}
```

## 🔍 Monitoreo

### Ver logs en producción

```bash
# Logs en tiempo real
supabase functions logs moderate-gossip --follow

# Logs filtrados por error
supabase functions logs moderate-gossip --filter error
```

### Ver invocaciones en Dashboard

1. Ve a **Edge Functions** > **moderate-gossip**
2. Pestaña **Metrics**
3. Verás:
   - Invocaciones por minuto
   - Latencia promedio
   - Tasa de error

## 🛡️ Seguridad

### ✅ Implementado

- Solo usuarios autenticados pueden llamar la función
- Claves de IA protegidas en backend (no expuestas en cliente)
- No hay bypass posible desde Flutter
- Validación de request body

### ⚠️ Pendiente

- Rate limiting por usuario (evitar spam)
- Logging de decisiones de moderación
- Dashboard de revisión manual

## 📊 Categorías Detectadas por OpenAI

| Categoría | Descripción |
|-----------|-------------|
| `sexual` | Contenido sexual |
| `hate` | Discurso de odio |
| `harassment` | Acoso |
| `self-harm` | Autolesión |
| `sexual/minors` | Contenido sexual con menores |
| `hate/threatening` | Amenazas de odio |
| `violence/graphic` | Violencia gráfica |
| `self-harm/intent` | Intención de autolesión |
| `self-harm/instructions` | Instrucciones de autolesión |
| `harassment/threatening` | Acoso con amenazas |
| `violence` | Violencia |

## 🔧 Troubleshooting

### Error: "Missing Authorization header"

**Causa:** No se envió el token de autenticación

**Solución:** Asegúrate de que Flutter envíe el header `Authorization` con el token del usuario

### Error: "Moderation service unavailable"

**Causa:** La Edge Function retornó status != 200

**Solución:**
1. Verifica logs: `supabase functions logs moderate-gossip`
2. Verifica que la función esté desplegada: `supabase functions list`

### Warning: "OPENAI_API_KEY not configured"

**Causa:** No se configuró la API key de OpenAI

**Efecto:** La función solo usará reglas locales (sin análisis de IA)

**Solución:** Configura `OPENAI_API_KEY` en secrets (ver arriba)

### La función es muy lenta (>1s)

**Causa:** Primera invocación (cold start)

**Solución:** Normal en Edge Functions. Invocaciones subsecuentes son <300ms

## 📚 Referencias

- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [OpenAI Moderation API](https://platform.openai.com/docs/guides/moderation)
- [Deno Deploy](https://deno.com/deploy)
