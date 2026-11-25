# Edge Function: Moderación Híbrida + Creación de Gossip

## 🎯 Objetivo

**Función TODO-EN-UNO** para máxima seguridad:
1. **Moderar contenido** (reglas de la tabla `moderation_rules` + OpenAI `omni-moderation-latest`: texto **e imagen** en una llamada; audio → revisión). Lógica en `moderation.ts`, tests en `moderation.test.ts`
2. **Decidir estados** internamente (cliente NO participa)
3. **Crear gossip** en DB con service_role
4. **Retornar gossip** ya creado

## 📏 Reglas editables (`moderation_rules`)

Se editan en el dashboard (Table Editor → `moderation_rules`) y aplican **al
siguiente chisme**, sin desplegar. Cada fila: "si `target` coincide → `action`
(`review` o `reject`)"; si coinciden varias, gana `reject`.

| `kind` | `target` | Ejemplo |
|---|---|---|
| `term` | Palabra o frase. Se compara normalizada (minúsculas, sin tildes, leet `p3rr4` → `perra`) y como palabra completa (`puta` no coincide con `computadora`) | `('term', 'lavado de dólares', 'review')` |
| `ai_category` | Categoría de OpenAI (`harassment`, `hate`, `sexual`, `violence`…) con `min_score` (0–1) | `('ai_category', 'harassment', 'review', 0.3)` |
| `builtin` | Regla fija del código: `credible_threat`, `personal_data`, `spam`. Se cambia su acción o se apaga (`enabled = false`) | `('builtin', 'spam', 'reject')` |

- Los umbrales de IA **solo endurecen**: lo que OpenAI marca (`flagged`) se rechaza siempre.
- Las regex (email, celular, links, amenazas) siguen en el código a propósito: una regex editable mal escrita puede colgar la función o dejar de moderar.
- Los CHECK de la tabla rechazan typos (categoría inexistente, `min_score` fuera de rango, duplicados).
- Razones que quedan en la cola: `term:<término>`, `ai_score:<categoría>`, `potential_personal_data`, `potential_spam`, `credible_threat`.
- Los clientes no pueden leer la tabla (conocer la lista ayuda a esquivarla).

`OPENAI_MODERATION_URL` (opcional) apunta la moderación a otro servidor: **solo
para el E2E local** (`scripts/e2e.sh`). No configurarlo en el remoto; si está,
la función lo avisa en los logs.

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

**En imágenes** OpenAI solo evalúa `sexual`, `violence`, `violence/graphic` y `self-harm*`. El resultado indica qué entrada marcó cada categoría (`category_applied_input_types`: `text` / `image`), y se loguea.

## 🧪 Tests

```bash
deno test supabase/functions/_shared/moderation.test.ts
# Sin Deno instalado:
docker run --rm -v "$PWD/supabase/functions:/fn" -w /fn denoland/deno:2.1.4 \
  deno test _shared/moderation.test.ts
```

## 🔧 Troubleshooting

### Error: "Missing Authorization header"

**Causa:** No se envió el token de autenticación

**Solución:** Asegúrate de que Flutter envíe el header `Authorization` con el token del usuario

### Error: "Moderation service unavailable"

**Causa:** La Edge Function retornó status != 200

**Solución:**
1. Verifica logs: `supabase functions logs moderate-gossip`
2. Verifica que la función esté desplegada: `supabase functions list`

### Warning: "AI moderation unavailable (...) → review"

**Causa:** sin `OPENAI_API_KEY`, error HTTP de OpenAI, timeout (10 s) o respuesta inválida (la causa va entre paréntesis)

**Efecto (fail-closed):** el chisme **no se publica**: queda en `draft` + `pending` (revisión). Solo las amenazas explícitas se siguen rechazando con reglas locales. Si todos los chismes nuevos quedan en revisión, revisar la key

**Solución:** Configura `OPENAI_API_KEY` en secrets (ver arriba)

### Error: "Could not load moderation_rules" / "Moderation rules unavailable → review"

**Causa:** falló la consulta a `moderation_rules` o una fila no es válida (se loguea cuál).

**Efecto (fail-closed):** el chisme queda en revisión con la razón `rules_unavailable`; lo que OpenAI marca se sigue rechazando.

**Solución:** revisar el log, corregir o borrar la fila inválida. Verificar el `GRANT` a `service_role` (`013_moderation.sql`).

### La función es muy lenta (>1s)

**Causa:** Primera invocación (cold start)

**Solución:** Normal en Edge Functions. Invocaciones subsecuentes son <300ms

## 📚 Referencias

- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [OpenAI Moderation API](https://platform.openai.com/docs/guides/moderation)
- [Deno Deploy](https://deno.com/deploy)
