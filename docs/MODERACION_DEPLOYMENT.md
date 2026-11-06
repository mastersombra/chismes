# 🚀 Despliegue de Moderación Híbrida

## ✅ Lo que se implementó

- **Edge Function** con moderación híbrida (Reglas + OpenAI)
- **Flutter** modificado para llamar a la función
- **Costo:** $0 (completamente gratis)

---

## 📋 Checklist de Despliegue

### 1️⃣ Obtener OpenAI API Key (5 min)

1. Ve a https://platform.openai.com/api-keys
2. Crea cuenta (si no tienes)
3. Click en "Create new secret key"
4. **Copia la key** (empieza con `sk-proj-...`)
5. **NO requiere billing** - Moderation API es gratis

---

### 2️⃣ Instalar Supabase CLI (2 min)

```bash
# macOS
brew install supabase/tap/supabase

# Verificar
supabase --version
```

---

### 3️⃣ Login en Supabase (1 min)

```bash
supabase login
```

---

### 4️⃣ Desplegar Edge Function (2 min)

```bash
# Desde la raíz del proyecto
cd /Users/alejo/Documents/Piloto/chismes

# Desplegar
supabase functions deploy moderate-gossip

# Verificar
supabase functions list
```

**Salida esperada:**
```
┌──────────────────┬─────────┬────────────────────┐
│      Name        │ Status  │    Last Updated    │
├──────────────────┼─────────┼────────────────────┤
│ moderate-gossip  │ ACTIVE  │ 2026-10-17...      │
└──────────────────┴─────────┴────────────────────┘
```

---

### 5️⃣ Configurar OpenAI API Key (2 min)

**Opción A: Dashboard (Recomendado)**

1. Ve a https://supabase.com/dashboard
2. Selecciona tu proyecto
3. **Edge Functions** > **Secrets**
4. Click "Add Secret"
5. Name: `OPENAI_API_KEY`
6. Value: Tu key de OpenAI
7. Save

**Opción B: CLI**

```bash
supabase secrets set OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxx
```

---

### 6️⃣ Activar en Flutter (5 min)

#### A. Comentar Mock

**Archivo:** `lib/features/gossip/data/datasources/mock_gossip_data_source.dart`

```dart
// COMENTAR esta línea:
// @Singleton(as: GossipRemoteDataSource)
class MockGossipRemoteDataSource implements GossipRemoteDataSource {
```

#### B. Descomentar Supabase

**Archivo:** `lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart`

```dart
// DESCOMENTAR esta línea:
@Singleton(as: GossipRemoteDataSource)
class SupabaseGossipRemoteDataSource implements GossipRemoteDataSource {
```

#### C. Regenerar DI

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 7️⃣ Probar en Flutter (5 min)

```bash
flutter run
```

**Casos de prueba:**

| Input | Resultado Esperado |
|-------|-------------------|
| "Hola, este es un mensaje normal" | ✅ Publicado |
| "Eres un hijueputa" | ⚠️ Enviado a revisión |
| "Te voy a matar" | ❌ Rechazado (error) |

---

## 🧪 Testing Local (Opcional)

### Iniciar Supabase Local

```bash
supabase start
supabase functions serve moderate-gossip
```

### Probar con curl

```bash
# Contenido limpio
curl -X POST 'http://localhost:54321/functions/v1/moderate-gossip' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"subject":"Test","content":"Hola mundo"}'

# Respuesta esperada:
# {"verdict":"publish","reasons":[],"source":"hybrid"}
```

---

## 📊 Monitoreo

### Ver logs

```bash
# Logs en tiempo real
supabase functions logs moderate-gossip --follow

# Ver últimos 50
supabase functions logs moderate-gossip --limit 50
```

### Ver métricas en Dashboard

1. Ve a **Edge Functions** > **moderate-gossip**
2. Pestaña **Metrics**
3. Verás invocaciones, latencia, errores

---

## ⚠️ Troubleshooting

### ❌ Error: "Missing Authorization header"

**Causa:** Usuario no autenticado

**Solución:** Implementa auth real (reemplaza 'spike-user')

### ❌ Error: "Moderation service unavailable"

**Causa:** Edge Function no responde

**Solución:**
```bash
# Ver logs
supabase functions logs moderate-gossip

# Verificar que está desplegada
supabase functions list
```

### ⚠️ Warning: "OPENAI_API_KEY not configured"

**Causa:** No se configuró la key

**Efecto:** Solo usa reglas locales (sin IA)

**Solución:** Agrega la key en Dashboard > Secrets

### 🐌 Primera llamada muy lenta (>2s)

**Causa:** Cold start de Edge Function

**Solución:** Normal. Llamadas subsecuentes <300ms

---

## 💰 Costos

| Servicio | Límite Gratis | Después |
|----------|---------------|---------|
| OpenAI Moderation | Ilimitado | $0 |
| Supabase Edge Functions | 500K/mes | $2 por 1M |

**Para 4-5M usuarios con ~500K chismes/mes:**
- Moderación: $0
- Edge Functions: $0 (dentro de tier gratis)
- **TOTAL: $0** 🎉

---

## 📚 Documentación Adicional

- **Edge Function README:** `supabase/functions/moderate-gossip/README.md`
- **Código Flutter:** `lib/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart`
- **Auditoría:** `docs/audit_add_gossip_module.md` (sección 20.2, problema #1)

---

## ✅ Checklist Final

- [ ] OpenAI API Key obtenida
- [ ] Supabase CLI instalado
- [ ] Edge Function desplegada (`supabase functions list`)
- [ ] OpenAI API Key configurada en Secrets
- [ ] Mock comentado en Flutter
- [ ] Supabase descomentado en Flutter
- [ ] DI regenerado (`build_runner`)
- [ ] Probado crear chisme con palabras prohibidas
- [ ] Logs verificados (`supabase functions logs`)

---

**🎉 Una vez completado, la moderación híbrida estará activa y lista para producción.**
