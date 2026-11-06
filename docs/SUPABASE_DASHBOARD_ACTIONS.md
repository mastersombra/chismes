# Acciones Requeridas en Supabase Dashboard

**Propósito:** Guía de acciones que **DEBEN hacerse manualmente** en Supabase Dashboard antes de producción.

**Contexto:** Algunas configuraciones críticas no pueden automatizarse con migraciones SQL y requieren acceso al Dashboard.

---

## 🔴 BLOQUEADORES (Antes de Beta)

### 1. ⚠️ Rotar API Keys

**Dashboard:** Settings → API → Project API keys

**Acciones:**
1. **Rotar `anon key`:**
   - Clic en "Generate new anon key"
   - Actualizar `.env` local con nueva key:
     ```bash
     SUPABASE_ANON_KEY=nueva_key_aqui
     ```
   - Rebuild app
   - Verificar que app funciona con nueva key
   - **Después de verificar:** Revocar key antigua

2. **Verificar que `service_role` NO está en `.env`:**
   ```bash
   grep SERVICE_ROLE .env
   # Resultado esperado: (vacío)
   ```

**Por qué es crítico:**
- Keys actuales han estado en repositorio/logs
- Rotation previene acceso no autorizado
- `service_role` nunca debe estar en cliente

**Frecuencia:** 
- ✅ Ahora (antes de beta)
- 🔄 Cada 90 días (mínimo)
- 🚨 Inmediatamente si hay sospecha de compromiso

---

### 2. 📦 Configurar Backups Automáticos

**Dashboard:** Settings → Database → Backups

**Acciones:**
1. **Habilitar backups diarios:**
   - Toggle "Enable automatic backups" → ON
   - Frequency: Daily
   - Retention: 7 days (mínimo)
   - Time: 3:00 AM (hora local del servidor)

2. **Crear primer backup manual:**
   - Clic "Create backup now"
   - Label: "Pre-beta baseline"
   - Esperar confirmación (puede tardar minutos)

3. **Probar restauración:**
   - Crear proyecto de staging
   - Restore desde backup
   - Verificar que datos son correctos

**Por qué es crítico:**
- Protección contra data loss
- Rollback si migración falla
- Recuperación de desastres

**Costo:** 
- Incluido en plan Pro ($25/mes)
- Backups adicionales: $0.125/GB/mes

---

### 3. 🕐 Habilitar Cron Jobs (pg_cron)

**Dashboard:** Database → Extensions → pg_cron

**Acciones:**
1. **Habilitar extensión pg_cron:**
   - Buscar "pg_cron" en Extensions
   - Clic "Enable"
   - Confirmar

2. **Verificar que funciona:**
   ```sql
   -- Dashboard → SQL Editor
   SELECT cron.schedule(
     'test-job',
     '* * * * *',  -- Cada minuto
     $$SELECT now()$$
   );
   
   -- Esperar 2 minutos
   SELECT * FROM cron.job_run_details
   WHERE jobname = 'test-job'
   ORDER BY start_time DESC
   LIMIT 5;
   
   -- Cleanup
   SELECT cron.unschedule('test-job');
   ```

3. **Programar cleanup jobs:**
   ```sql
   -- Cleanup de quarantine (cada hora)
   SELECT cron.schedule(
     'cleanup-image-quarantine',
     '0 * * * *',  -- Top of every hour
     $$SELECT cleanup_old_quarantine_images()$$
   );
   
   SELECT cron.schedule(
     'cleanup-audio-quarantine',
     '0 * * * *',
     $$SELECT cleanup_old_quarantine_audio()$$
   );
   
   -- Cleanup de error logs (diario a las 2 AM)
   SELECT cron.schedule(
     'cleanup-old-error-logs',
     '0 2 * * *',
     $$SELECT cleanup_old_error_logs()$$
   );
   ```

**Por qué es crítico:**
- Sin pg_cron, archivos de quarantine se acumulan forever
- Error logs llenarían la BD
- Cleanup manual no es escalable

**Verificación:**
```sql
-- Listar jobs activos
SELECT * FROM cron.job;

-- Ver últimas ejecuciones
SELECT 
  jobname,
  status,
  start_time,
  end_time,
  return_message
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 10;
```

---

### 4. 🔐 Verificar RLS Policies en Storage

**Dashboard:** Storage → Policies

**Acciones para cada bucket:**

#### `image-quarantine` (privado)
- ✅ Users can upload: `bucket_id = 'image-quarantine' AND (storage.foldername(name))[1] = auth.uid()::text`
- ✅ Service role can read all: `(SELECT auth.role() = 'service_role')`
- ❌ NO debe tener: Public read

#### `image` (público para leer, privado para escribir)
- ✅ Public can read: `bucket_id = 'image'`
- ✅ Service role can write: `(SELECT auth.role() = 'service_role')`
- ❌ NO debe tener: User can upload

#### `audio-quarantine` (privado)
- ✅ Users can upload: `bucket_id = 'audio-quarantine' AND (storage.foldername(name))[1] = auth.uid()::text`
- ✅ Service role can read all: `(SELECT auth.role() = 'service_role')`
- ❌ NO debe tener: Public read

#### `audio` (público para leer, privado para escribir)
- ✅ Public can read: `bucket_id = 'audio'`
- ✅ Service role can write: `(SELECT auth.role() = 'service_role')`
- ❌ NO debe tener: User can upload

**Verificación:**
- Intentar subir a `image` con anon key → **403**
- Intentar leer de `image-quarantine` con anon key de otro usuario → **403**
- Leer de `image` público → **200**

---

### 5. 🚨 Configurar Alertas de Billing

**Dashboard:** Organization Settings → Billing → Usage Alerts

**Acciones:**
1. **Alert de Database Size:**
   - Threshold: 1 GB (Plan Free tiene 500 MB)
   - Email: tu-email@ejemplo.com
   - Acción: Revisar cleanup jobs

2. **Alert de Bandwidth:**
   - Threshold: 80% del límite (4 GB para Free, 50 GB para Pro)
   - Email: tu-email@ejemplo.com
   - Acción: Optimizar queries, revisar cache

3. **Alert de Egress (Storage):**
   - Threshold: 80% del límite (2 GB para Free, 200 GB para Pro)
   - Email: tu-email@ejemplo.com
   - Acción: Implementar CDN si es necesario

**Por qué es crítico:**
- Prevenir sorpresas en facturación
- Detectar abuso temprano
- Plan ahead para upgrade

---

## 🟡 ANTES DE BETA PÚBLICA

### 6. 📊 Configurar Monitoring Dashboard

**Dashboard:** No existe nativo → Usar herramienta externa

**Opciones:**

#### Opción A: Supabase Dashboard (básico)
- Dashboard → Project → Reports
- Métricas incluidas: API requests, DB size, bandwidth
- **Pros:** Gratis, incluido
- **Cons:** Muy básico, sin alertas customizadas

#### Opción B: Grafana + Prometheus (recomendado)
1. **Setup Prometheus exporter:**
   - Instalar `postgres_exporter` en servidor
   - Configurar conexión a Supabase DB
   - Exportar métricas custom

2. **Setup Grafana:**
   - Cloud gratis: https://grafana.com/
   - Importar dashboard: PostgreSQL Database
   - Agregar panels custom para:
     - Rate limit violations (SELECT COUNT(*) FROM rate_limits WHERE ...)
     - Error logs por severity
     - Gossips created per hour
     - Media upload failures

3. **Configurar alertas:**
   - Error rate > 10/min → Slack/Email
   - DB connections > 80% → Email
   - Storage quarantine > 1000 files → Slack

**Tiempo estimado:** 4-6 horas (primera vez)

---

### 7. 🔔 Configurar Incident Management

**Herramientas recomendadas:**

#### Para equipo pequeño (1-3 personas):
- **Slack + Webhooks** (gratis)
  - Canal #alerts
  - Integraciones: Supabase, Grafana
  - Runbooks en Google Docs

#### Para equipo mediano (4-10 personas):
- **PagerDuty** (desde $19/usuario/mes)
  - Escalation policies
  - On-call rotation
  - Integraciones con todo

#### Configuración mínima (Slack):
```javascript
// Edge Function: notify-on-error
// Llamar cuando error rate > threshold
const slackWebhook = Deno.env.get('SLACK_WEBHOOK_URL');
await fetch(slackWebhook, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: '🚨 High error rate detected',
    blocks: [{
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Errors:* ${errorCount}\n*Time:* ${timestamp}\n*Top error:* ${topError}`
      }
    }]
  })
});
```

---

### 8. 🔄 Crear Runbooks

**Ubicación:** `docs/runbooks/`

**Runbooks mínimos:**

#### `incident_high_error_rate.md`
```markdown
# Runbook: High Error Rate

**Trigger:** > 50 errors/min durante 5 minutos

**Acciones:**
1. Check Supabase status: https://status.supabase.com/
2. Check error_logs table:
   SELECT error_code, COUNT(*) FROM error_logs
   WHERE created_at > NOW() - INTERVAL '10 minutes'
   GROUP BY error_code
   ORDER BY COUNT(*) DESC;
3. Si es network error → Problema de ISP/Supabase
4. Si es validation error → Posible ataque/bot
5. Si es auth error → Verificar keys no rotadas accidentalmente
```

#### `incident_database_full.md`
```markdown
# Runbook: Database Full

**Trigger:** Database size > 90% del límite

**Acciones:**
1. Verificar cleanup jobs running:
   SELECT * FROM cron.job_run_details
   ORDER BY start_time DESC LIMIT 10;
2. Cleanup manual si necesario:
   SELECT cleanup_old_error_logs();
   SELECT cleanup_old_quarantine_images();
3. Analyze tamaño por tabla:
   SELECT 
     schemaname,
     tablename,
     pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
   FROM pg_tables
   WHERE schemaname = 'public'
   ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
4. Considerar retention policy más agresiva
```

---

## 📝 CHECKLIST DE PRODUCCIÓN

Usar antes de lanzar beta pública:

### Database
- [ ] ✅ Backups automáticos habilitados
- [ ] ✅ Backup manual creado y probado
- [ ] ✅ pg_cron habilitado
- [ ] ✅ Cleanup jobs programados
- [ ] ✅ Conexion pooling configurado (default está bien)

### Security
- [ ] ✅ API keys rotadas
- [ ] ✅ .env verificado (NO service_role)
- [ ] ✅ RLS policies verificadas en Storage
- [ ] ✅ RLS policies verificadas en Tables (via migrations)

### Monitoring
- [ ] ✅ Billing alerts configuradas
- [ ] 🟡 Monitoring dashboard (Grafana o equivalente)
- [ ] 🟡 Incident management (Slack mínimo)

### Documentation
- [ ] ✅ Runbooks creados
- [ ] ✅ Playbooks de deployment
- [ ] 🟡 Architecture decision records actualizados

---

## 📚 RECURSOS

### Supabase Dashboard URLs
- **Dashboard:** https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo
- **Database:** https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/database/tables
- **Storage:** https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/storage/buckets
- **SQL Editor:** https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/sql
- **Settings:** https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/settings/api

### Documentación Supabase
- RLS Policies: https://supabase.com/docs/guides/auth/row-level-security
- pg_cron: https://supabase.com/docs/guides/database/extensions/pgcron
- Storage Policies: https://supabase.com/docs/guides/storage/security/access-control
- Backups: https://supabase.com/docs/guides/platform/backups

### Tools
- Grafana Cloud: https://grafana.com/
- PagerDuty: https://www.pagerduty.com/
- Slack Webhooks: https://api.slack.com/messaging/webhooks

---

## 🎯 PRIORIDADES

### 🔴 HACER AHORA (antes de beta):
1. Rotar API keys
2. Habilitar backups
3. Habilitar pg_cron + programar cleanup jobs
4. Verificar RLS Storage policies
5. Configurar billing alerts

### 🟡 HACER ANTES DE BETA PÚBLICA:
1. Setup Grafana/monitoring
2. Configurar alertas de incident
3. Crear runbooks mínimos
4. Probar rollback desde backup

### 🟢 NICE TO HAVE:
1. PagerDuty (si el equipo crece)
2. Custom dashboards avanzados
3. Automated testing de RLS policies

---

**Última actualización:** 2026-10-22  
**Mantenedor:** Alejo  
**Revisar:** Cada deploy mayor
