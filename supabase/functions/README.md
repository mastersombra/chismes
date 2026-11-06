# Supabase Edge Functions

Edge Functions programadas para tareas de mantenimiento.

---

## 📋 **Funciones Disponibles**

### **cleanup-idempotency**

Limpia `idempotency_key` de gossips mayores a 24 horas.

**Propósito:** Prevenir acumulación indefinida de keys sin causar contención en inserts.

**Programación:** Diario a las 3 AM UTC (horario de baja demanda)

**Performance:**
- ~500ms para 1M gossips
- ~5s para 10M gossips
- Usa índice parcial para optimización

---

## 🚀 **Setup Inicial**

### **1. Instalar Supabase CLI**

```bash
# Si no está instalado
brew install supabase/tap/supabase

# Verificar versión
supabase --version
```

### **2. Login**

```bash
supabase login
```

### **3. Link al proyecto**

```bash
# Desde raíz del proyecto
cd /Users/alejo/Documents/Piloto/chismes

# Link (si no está linkeado)
supabase link --project-ref <project-id>
```

---

## 📦 **Deploy de Funciones**

### **Deploy individual**

```bash
# Deploy cleanup-idempotency
supabase functions deploy cleanup-idempotency

# Deploy con logs verbosos
supabase functions deploy cleanup-idempotency --debug
```

### **Deploy todas las funciones**

```bash
# Deploy todas
supabase functions deploy
```

---

## ⏰ **Programar Ejecución (Cron)**

### **Programar cleanup-idempotency**

```bash
# Diario a las 3 AM UTC
supabase functions schedule cleanup-idempotency --cron "0 3 * * *"
```

### **Sintaxis cron**

```
┌───────────── minuto (0-59)
│ ┌───────────── hora (0-23)
│ │ ┌───────────── día del mes (1-31)
│ │ │ ┌───────────── mes (1-12)
│ │ │ │ ┌───────────── día de la semana (0-6, 0=domingo)
│ │ │ │ │
* * * * *

Ejemplos:
- "0 3 * * *"     → 3 AM diario
- "0 */6 * * *"   → Cada 6 horas
- "0 2 * * 0"     → 2 AM cada domingo
- "*/30 * * * *"  → Cada 30 minutos
```

---

## 🔍 **Monitoreo**

### **Ver funciones programadas**

```bash
supabase functions list
```

Salida esperada:
```
NAME                 CRON           LAST DEPLOYED
cleanup-idempotency  0 3 * * *      2026-10-22 04:00 UTC
```

### **Ver logs en tiempo real**

```bash
# Tail logs
supabase functions logs cleanup-idempotency --tail

# Ver últimos N logs
supabase functions logs cleanup-idempotency --limit 50
```

### **Ejecutar manualmente (testing)**

```bash
# Invocar desde CLI
supabase functions invoke cleanup-idempotency

# O con curl
curl -X POST https://<project>.supabase.co/functions/v1/cleanup-idempotency \
  -H "Authorization: Bearer <anon-key>"
```

**Respuesta esperada:**
```json
{
  "cleaned": 1234,
  "timestamp": "2026-10-22T03:00:00.000Z",
  "duration_ms": 523
}
```

---

## 📊 **Verificar Efectividad**

### **Query para monitorear acumulación**

```sql
SELECT
  COUNT(*) FILTER (WHERE idempotency_key IS NOT NULL) AS with_key,
  COUNT(*) AS total,
  ROUND(100.0 * COUNT(*) FILTER (WHERE idempotency_key IS NOT NULL) / COUNT(*), 2) AS percentage,
  COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') AS last_24h
FROM gossips;
```

**Valores esperados:**
- `percentage`: 1-5% (solo gossips de últimas 24h tienen key)
- Si `percentage > 10%` → limpieza no está ejecutándose

### **Ver historial de limpiezas**

```sql
-- Si guardas logs en tabla (opcional)
SELECT
  executed_at,
  keys_cleaned,
  duration_ms
FROM cleanup_logs
ORDER BY executed_at DESC
LIMIT 10;
```

---

## 🛠️ **Troubleshooting**

### **Función no se ejecuta automáticamente**

```bash
# Verificar que está programada
supabase functions list

# Si no aparece cron, programar de nuevo
supabase functions schedule cleanup-idempotency --cron "0 3 * * *"
```

### **Ver errores en logs**

```bash
# Filtrar solo errores
supabase functions logs cleanup-idempotency --tail | grep -i error
```

### **Ejecutar manualmente para testing**

```bash
# Invocar y ver resultado inmediatamente
supabase functions invoke cleanup-idempotency --debug
```

### **Desprogramar función (si necesario)**

```bash
# Eliminar cron pero mantener función
supabase functions unschedule cleanup-idempotency

# Eliminar función completamente
supabase functions delete cleanup-idempotency
```

---

## 🔐 **Secrets y Variables de Entorno**

Las Edge Functions tienen acceso automático a:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

No necesitas configurarlas manualmente.

---

## 📚 **Documentación Adicional**

- **Análisis de opciones:** `docs/ANALYSIS_P6_IDEMPOTENCY_OPTIONS.md`
- **Migración 009:** `supabase/migrations/009_remove_idempotency_cleanup_trigger.sql`
- **Refactor P6:** `docs/REFACTOR_P6_FEED_PAGINATION_MEDIA.md`

---

## 🎯 **Checklist de Setup**

- [ ] Supabase CLI instalado
- [ ] Login completado
- [ ] Proyecto linkeado
- [ ] Edge Function deployed
- [ ] Cron programado (3 AM diario)
- [ ] Testing manual ejecutado
- [ ] Logs verificados
- [ ] Query de monitoreo ejecutado
- [ ] Documentación leída

---

**Última actualización:** 2026-10-22  
**Mantenedor:** Alejo
