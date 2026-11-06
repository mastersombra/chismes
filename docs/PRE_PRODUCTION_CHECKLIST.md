# Checklist Pre-Producción

**Fecha de creación:** 2026-10-22  
**Objetivo:** Verificar que el proyecto está listo para producción  
**Estado:** 📋 EN PROGRESO

---

## 🔐 SEGURIDAD

### Configuración

- [x] ✅ `.env` NO contiene `SERVICE_ROLE_KEY`
- [x] ✅ `.gitignore` incluye `.env` y `.env.*`
- [ ] 🔴 Rotar `SUPABASE_ANON_KEY` antes de lanzamiento público
- [ ] 🔴 Crear usuarios de producción (no test/spike)
- [ ] 🟡 Configurar domain custom (chismes.app)
- [ ] 🟡 Habilitar 2FA en cuenta Supabase

### Edge Functions

- [x] ✅ Autenticación JWT obligatoria en `moderate-gossip`
- [x] ✅ Autenticación JWT obligatoria en `log-error`
- [x] ✅ Sanitización de datos sensibles (allowlist/denylist)
- [x] ✅ Rate limiting implementado (50/hora, 200/día)
- [ ] 🔴 Configurar OpenAI API key en Supabase Secrets (no en código)
- [ ] 🟡 Configurar timeouts de Edge Functions (10s default ok)
- [ ] 🟡 Configurar CORS apropiado

### RLS (Row Level Security)

- [x] ✅ RLS habilitado en tabla `gossips`
- [x] ✅ RLS habilitado en tabla `error_logs`
- [x] ✅ RLS en bucket `image-quarantine` (privado)
- [x] ✅ RLS en bucket `image` (público con restricciones)
- [x] ✅ RLS en bucket `audio-quarantine` (privado)
- [x] ✅ RLS en bucket `audio` (público con restricciones)
- [ ] 🔴 Verificar políticas con tests (ver TESTING_ROADMAP.md)

### Datos Sensibles

- [x] ✅ GPS usa `LocationAccuracy.low` (no high)
- [x] ✅ GPS logging solo en `kDebugMode`
- [x] ✅ Modo anónimo implementado
- [x] ✅ Usuario puede olvidar ubicación
- [x] ✅ Solo ciudad guardada (no coordenadas exactas)
- [ ] 🟡 Configurar GDPR consent para usuarios EU
- [ ] 🟡 Implementar data export (GDPR portabilidad)

---

## 💻 CÓDIGO

### Mocks y Temporales

- [x] ✅ `MockGossipRemoteDataSource` NO registrado en DI
- [x] ✅ `MockGossipLocalDataSource` NO registrado en DI
- [x] ✅ `spike-user` solo en tests (no en código producción)
- [x] ✅ Audio picker NO expuesto en UI (backend listo, UI oculta)
- [ ] 🟡 Renombrar `MvpContentModerator` a `LocalFallbackContentModerator`
- [ ] 🟡 Agregar comentarios de advertencia en mocks

### Logging y Debug

- [x] ✅ `AppLogger` configurado con niveles apropiados
- [x] ✅ Logging remoto solo `error` y `fatal`
- [x] ✅ `kDebugMode` usado para logs sensibles
- [ ] 🟡 Buscar y eliminar `debugPrint` innecesarios
- [ ] 🟡 Buscar y eliminar comentarios de "TODO: spike"
- [ ] 🟡 Revisar logs de producción (no exponer datos sensibles)

### Validación

- [x] ✅ FormValidators para UI
- [x] ✅ Domain validators para business logic
- [x] ✅ Edge Functions validan schema
- [x] ✅ Edge Functions validan ubicación (ciudad/región/país existen)
- [x] ✅ MIME type validation (magic bytes, no extensión)
- [x] ✅ Tamaño máximo de imagen (10MB)
- [x] ✅ Tamaño máximo de audio (10MB)

### Error Handling

- [x] ✅ Repository pattern con `Result<Failure, Success>`
- [x] ✅ Error handler centralizado
- [x] ✅ Failures con códigos de error
- [x] ✅ UI muestra errores user-friendly
- [ ] 🟡 Agregar Sentry/Crashlytics (monitoreo producción)

---

## 🧪 TESTS

### Unitarios

- [x] ✅ Tests de domain (validators, use cases)
- [x] ✅ Tests de data (repositories, models)
- [x] ✅ Tests de widgets (115 tests)
- [x] 🟡 Tests de controller (13/61 pasando, 48 rotos)
- [x] ✅ Cobertura actual: 78.9% (objetivo: >80%)

### Integración (Ver TESTING_ROADMAP.md)

- [ ] 🔴 Tests de autenticación Edge Functions (5 casos)
- [ ] 🔴 Tests de validación Edge Functions (8 casos)
- [ ] 🔴 Tests de RLS gossips (8 casos)
- [ ] 🔴 Tests de RLS storage (6 casos)
- [ ] 🔴 Tests de media validation (7 casos)

### E2E (Ver TESTING_ROADMAP.md)

- [ ] 🔴 Crear gossip sin media (golden path)
- [ ] 🔴 Crear gossip con imagen (golden path)
- [ ] 🔴 Idempotencia (retry con misma key)
- [ ] 🟡 GPS denegado → selección manual
- [ ] 🟡 Pérdida de red durante submit

**Estimación para completar P0:** 10-12 días (ver TESTING_ROADMAP.md)

---

## ⚙️ CONFIGURACIÓN SUPABASE

### Database

- [x] ✅ Migraciones aplicadas (001-012)
- [x] ✅ Seeds aplicados (países, regiones, ciudades)
- [x] ✅ pg_cron configurado (error logs cleanup)
- [ ] 🔴 Backups automáticos habilitados
- [ ] 🔴 Point-in-time recovery configurado
- [ ] 🟡 Índices verificados (performance)

### Storage

- [x] ✅ Buckets creados (image, image-quarantine, audio, audio-quarantine)
- [x] ✅ Límites de tamaño configurados (10MB)
- [x] ✅ MIME types permitidos configurados
- [ ] 🟡 CDN configurado (mejor performance)
- [ ] 🟡 Compresión automática habilitada

### Auth

- [ ] 🔴 Configurar email templates (welcome, reset password)
- [ ] 🔴 Configurar email provider (SendGrid, AWS SES)
- [ ] 🟡 Configurar OAuth providers (Google, Apple) si necesario
- [ ] 🟡 Rate limiting de login (anti-bruteforce)

### Edge Functions

- [x] ✅ `moderate-gossip` deployed
- [x] ✅ `log-error` deployed
- [ ] 🔴 Variables de entorno configuradas en Supabase Dashboard
  - [ ] `OPENAI_API_KEY`
  - [ ] `MODERATION_THRESHOLD` (si aplica)
- [ ] 🟡 Logs de Edge Functions monitoreados
- [ ] 🟡 Alertas configuradas (errores >X por hora)

---

## 📱 APLICACIÓN MÓVIL

### Performance

- [ ] 🟡 Tiempo de carga inicial <500ms
- [ ] 🟡 Submit con imagen <3s
- [ ] 🟡 Scroll del feed 60fps
- [ ] 🟡 Memory leaks verificados (ninguno)
- [ ] 🟡 Batería: GPS no drena en background

### UX/UI

- [x] ✅ AppSpacing usado (no números mágicos)
- [x] ✅ AppRadius usado (no hardcoded)
- [x] ✅ Sin overflow en 320px (dispositivos pequeños)
- [x] ✅ Texto largo con ellipsis
- [ ] 🟡 Dark mode funcional
- [ ] 🟡 Accesibilidad: escalado de fuente (2.0x)
- [ ] 🟡 Accesibilidad: lector de pantalla
- [ ] 🟡 Modo landscape (si aplica)

### Permisos

- [x] ✅ GPS: "When In Use" (no Always)
- [x] ✅ GPS: `COARSE_LOCATION` (no FINE)
- [x] ✅ Cámara: solo cuando usuario usa picker
- [x] ✅ Galería: solo cuando usuario usa picker
- [ ] 🟡 Verificar texto de permisos (claro y transparente)

### Build

- [ ] 🔴 Configurar signing (iOS)
- [ ] 🔴 Configurar signing (Android)
- [ ] 🔴 Versión bump a 1.0.0
- [ ] 🔴 Build número inicial
- [ ] 🟡 ProGuard/R8 configurado (Android)
- [ ] 🟡 Obfuscación habilitada

---

## 📄 DOCUMENTACIÓN

### Interna

- [x] ✅ `CLAUDE.md` actualizado
- [x] ✅ `.claude/ARCHITECTURE.md` completo
- [x] ✅ `.claude/PATTERNS.md` completo
- [x] ✅ `.claude/TESTING.md` completo
- [x] ✅ `docs/TESTING_ROADMAP.md` creado
- [x] ✅ `docs/cleanup_mocks_and_temporal_config.md` creado
- [ ] 🟡 Changelog inicial (CHANGELOG.md)
- [ ] 🟡 Contributing guide (CONTRIBUTING.md)

### Legal

- [x] ✅ `PRIVACY_POLICY.md` creado
- [x] ✅ `TERMS_OF_SERVICE.md` creado
- [ ] 🔴 Hospedar políticas en web (chismes.app/privacy)
- [ ] 🔴 Agregar links a políticas en app
- [ ] 🟡 Revisión legal de políticas (abogado)
- [ ] 🟡 GDPR compliance verificado (EU users)
- [ ] 🟡 CCPA compliance verificado (CA users)
- [ ] 🟡 LGPD compliance verificado (BR users)

### Usuarios

- [ ] 🟡 FAQ creado
- [ ] 🟡 Guía de uso básica
- [ ] 🟡 Community guidelines publicadas
- [ ] 🟡 Contacto de soporte configurado

---

## 🚀 DEPLOYMENT

### Beta Privada

- [ ] 🔴 TestFlight configurado (iOS)
- [ ] 🔴 Internal testing track configurado (Android)
- [ ] 🔴 Lista de beta testers definida
- [ ] 🟡 Formulario de feedback configurado
- [ ] 🟡 Analytics configurados (Firebase, Mixpanel)

### Beta Pública

- [ ] 🔴 App Store listing (iOS)
- [ ] 🔴 Play Store listing (Android)
- [ ] 🔴 Screenshots preparados
- [ ] 🔴 Descripción de app escrita
- [ ] 🟡 Video preview (opcional)
- [ ] 🟡 Sitio web landing page

### Producción

- [ ] 🔴 Monitoreo configurado (Sentry, Datadog)
- [ ] 🔴 Alertas configuradas (errores, downtime)
- [ ] 🔴 Runbook de incidentes creado
- [ ] 🔴 Plan de rollback definido
- [ ] 🟡 Status page configurado
- [ ] 🟡 Rate limits de producción ajustados

---

## 📊 MÉTRICAS Y MONITOREO

### Métricas de Negocio

- [ ] 🟡 Dashboard de métricas (usuarios, gossips, moderación)
- [ ] 🟡 Alertas de anomalías (spike de errores)
- [ ] 🟡 Reportes semanales automáticos

### Métricas Técnicas

- [ ] 🟡 Response time p50/p95/p99
- [ ] 🟡 Error rate (<1%)
- [ ] 🟡 Availability (>99%)
- [ ] 🟡 Database size growth
- [ ] 🟡 Storage usage (images/audio)

### Costos

- [ ] 🟡 Supabase: proyección de costos con 1K/10K/100K usuarios
- [ ] 🟡 OpenAI: proyección de costos moderación
- [ ] 🟡 Storage: proyección de costos media
- [ ] 🟡 Alertas de budget (evitar sorpresas)

---

## 🔄 PROCESOS

### CI/CD

- [ ] 🟡 GitHub Actions configurado
- [ ] 🟡 Tests automáticos en PR
- [ ] 🟡 Build automático en merge a main
- [ ] 🟡 Deploy automático a staging

### Mantenimiento

- [ ] 🟡 Proceso de updates de dependencias
- [ ] 🟡 Proceso de rotación de secrets
- [ ] 🟡 Proceso de backup/restore
- [ ] 🟡 Proceso de escalamiento (si spike de usuarios)

---

## 🎯 PRIORIZACIÓN

### 🔴 CRÍTICO (Bloquea Producción)

**Estimación total:** 10-14 días

1. **Tests de seguridad** (10 días)
   - RLS tests
   - Edge Functions tests
   - E2E golden paths
   - Ver: `docs/TESTING_ROADMAP.md`

2. **Configuración Supabase** (2 días)
   - OpenAI API key en Secrets
   - Email provider
   - Backups automáticos
   - Point-in-time recovery

3. **Build y signing** (1 día)
   - iOS signing
   - Android signing
   - Versión 1.0.0

4. **Legal** (1 día)
   - Hospedar políticas en web
   - Links en app

---

### 🟡 IMPORTANTE (Post-Lanzamiento)

**Estimación total:** 5-7 días

1. **Mejoras de código** (2 días)
   - Arreglar controller tests
   - Eliminar debugPrint
   - Renombrar MvpContentModerator

2. **Performance** (2 días)
   - Benchmarks
   - Memory leaks
   - Optimizaciones

3. **Accesibilidad** (2 días)
   - Dark mode
   - Escalado de fuente
   - Lector de pantalla

4. **Monitoreo** (1 día)
   - Sentry/Crashlytics
   - Alertas
   - Dashboard

---

### 🟢 MEJORAS (Largo Plazo)

1. **Features adicionales**
   - Audio (backend listo, falta UI)
   - Comentarios
   - Reacciones
   - Notificaciones

2. **Optimizaciones**
   - CDN para media
   - Compresión automática
   - Índices DB adicionales

3. **Documentación**
   - API docs
   - Architecture diagrams
   - Deployment guide

---

## 📝 NOTAS

### Para Beta Privada (TestFlight/Internal Testing)

**Mínimo requerido:**
- ✅ Seguridad básica (RLS, auth)
- ✅ No crashes críticos
- 🔴 Tests E2E de golden paths
- 🟡 Monitoreo básico

**Puede esperar:**
- 🟢 Performance optimizado
- 🟢 Accesibilidad completa
- 🟢 Tests exhaustivos

---

### Para Beta Pública

**Mínimo requerido:**
- 🔴 TODO lo de Beta Privada
- 🔴 Tests de seguridad completos
- 🔴 Políticas legales hosteadas
- 🔴 Monitoreo robusto
- 🟡 Performance aceptable

---

### Para Producción v1.0

**Mínimo requerido:**
- 🔴 TODO lo de Beta Pública
- 🔴 Performance optimizado
- 🔴 Alertas configuradas
- 🔴 Runbook de incidentes
- 🟡 Accesibilidad básica

---

## 🔍 COMANDOS DE VERIFICACIÓN

```bash
# Verificar .env limpio
grep -i "service_role" .env
# Esperado: Solo comentarios

# Verificar mocks desactivados
grep -r "@Singleton" lib/features/gossip/data/datasources/mock_gossip_data_source.dart
# Esperado: Línea comentada

# Verificar coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
# Esperado: >78%

# Verificar análisis
flutter analyze
# Esperado: No issues found

# Verificar migraciones
supabase db diff --linked
# Esperado: No hay cambios pendientes

# Ejecutar tests de seguridad
flutter test test/security/
# Esperado: Todos pasan (cuando estén implementados)
```

---

## ✅ SIGN-OFF

### Para aprobar lanzamiento, verificar:

- [ ] Todos los items 🔴 CRÍTICO completados
- [ ] Tests E2E de golden paths pasando
- [ ] No security warnings
- [ ] Políticas legales hosteadas
- [ ] Backups configurados
- [ ] Monitoreo activo
- [ ] Plan de rollback definido

**Aprobado por:**
- [ ] Tech Lead: _______________
- [ ] Product: _______________
- [ ] QA: _______________

**Fecha de aprobación:** _______________

---

**FIN DEL CHECKLIST**

**Última actualización:** 2026-10-22  
**Próxima revisión:** Antes de cada fase de lanzamiento  
**Mantenedor:** Alejo
