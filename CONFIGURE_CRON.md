# ⏰ Configurar Cron para Edge Functions

La CLI de Supabase aún no soporta programación de cron jobs. Se debe configurar desde el Dashboard.

**Tiempo:** 2 minutos

---

## 🚀 **CONFIGURACIÓN DESDE DASHBOARD**

### **Paso 1: Ir a Functions**

**URL directa:**
```
https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/functions
```

O navegar manualmente:
1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Click en **Edge Functions** en el menú lateral

---

### **Paso 2: Seleccionar cleanup-idempotency**

En la lista de funciones, click en **cleanup-idempotency**

---

### **Paso 3: Configurar Schedule**

Busca la sección **Cron Schedule** o **Settings** → **Schedule**

**Configuración:**
```
Cron Expression: 0 3 * * *
```

**Explicación:**
- `0` = minuto 0
- `3` = hora 3 (3 AM)
- `* * *` = todos los días, meses y días de semana

**Resultado:** Ejecuta diariamente a las 3 AM UTC

---

### **Paso 4: Guardar**

Click en **Save** o **Update**

---

## 🔍 **VERIFICACIÓN**

### **Verificar que el cron está activo:**

1. En el Dashboard, ve a la función `cleanup-idempotency`
2. Busca el campo **Cron Schedule**
3. Debe mostrar: `0 3 * * *`

### **Ver logs de ejecuciones:**

En el Dashboard de la función:
- **Logs** → Filtra por fecha
- Después de las 3 AM, deberías ver ejecuciones

---

## 📊 **SINTAXIS CRON**

```
┌───────────── minuto (0-59)
│ ┌───────────── hora (0-23)
│ │ ┌───────────── día del mes (1-31)
│ │ │ ┌───────────── mes (1-12)
│ │ │ │ ┌───────────── día de la semana (0-6)
│ │ │ │ │
* * * * *
```

**Ejemplos útiles:**

| Cron | Descripción |
|------|-------------|
| `0 3 * * *` | 3 AM diario ⭐ (recomendado) |
| `0 */6 * * *` | Cada 6 horas |
| `0 2 * * 0` | 2 AM cada domingo |
| `*/30 * * * *` | Cada 30 minutos |
| `0 0 1 * *` | 1er día del mes (mensual) |

---

## 🧪 **TESTING MANUAL**

Antes de esperar a las 3 AM, puedes probar la función manualmente:

### **Desde Dashboard:**

1. Ve a la función `cleanup-idempotency`
2. Click en **Invoke** o **Test**
3. Click en **Run**

**Respuesta esperada:**
```json
{
  "cleaned": 0,
  "timestamp": "2026-10-22T...",
  "duration_ms": 123
}
```

`cleaned: 0` es normal si no hay gossips > 24h todavía.

### **Desde terminal:**

```bash
curl -X POST \
  https://njqamqcsldpmtbiqwbwo.supabase.co/functions/v1/cleanup-idempotency \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qcWFtcWNzbGRwbXRiaXF3YndvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxOTc4NjMsImV4cCI6MjEwNzc3Mzg2M30.LOgYmc6ykAHUOPImn1XqzpMJwjpTOHgO7JdCn8vrH6w"
```

---

## 📈 **MONITOREO**

### **Ver última ejecución:**

En Dashboard → Functions → cleanup-idempotency → Logs

### **Verificar efectividad (SQL):**

```sql
SELECT
  COUNT(*) FILTER (WHERE idempotency_key IS NOT NULL) AS with_key,
  COUNT(*) AS total,
  ROUND(100.0 * COUNT(*) FILTER (WHERE idempotency_key IS NOT NULL) / COUNT(*), 2) AS percentage
FROM gossips;
```

**Valores esperados:**
- `percentage`: 1-5% (solo gossips de últimas 24h)
- Si > 10% → cron no está ejecutándose

---

## ❓ **FAQ**

### **¿Por qué no se puede desde CLI?**

La CLI de Supabase aún no tiene el comando `supabase functions schedule`. Se está trabajando en ello.

**Issue tracking:** https://github.com/supabase/cli/issues/xxx (si aplica)

### **¿Se puede usar pg_cron en su lugar?**

Sí, si tienes acceso a pg_cron (extension PostgreSQL):

```sql
SELECT cron.schedule(
  'cleanup-idempotency',
  '0 3 * * *',
  $$SELECT cleanup_old_idempotency_keys();$$
);
```

Pero esto requiere permisos de superusuario que pueden no estar disponibles en Supabase.

### **¿El cron se mantiene después de redeploy?**

Sí, la configuración de cron es independiente del deploy de la función. Sobrevive a:
- ✅ Redeploys de la función
- ✅ Updates del código
- ❌ Eliminación completa de la función

---

## ✅ **CHECKLIST**

Después de configurar:

- [ ] Ir a Dashboard de Functions
- [ ] Seleccionar cleanup-idempotency
- [ ] Configurar cron: `0 3 * * *`
- [ ] Guardar configuración
- [ ] Test manual ejecutado (sin errores)
- [ ] Verificar que `cleaned` retorna número (puede ser 0)

---

## 🔗 **ENLACES ÚTILES**

- **Dashboard Functions:** https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/functions
- **Documentación Supabase Cron:** https://supabase.com/docs/guides/functions/schedule-functions
- **Cron Expression Generator:** https://crontab.guru/

---

**¡Configuración simple en 2 minutos! ⏰**
