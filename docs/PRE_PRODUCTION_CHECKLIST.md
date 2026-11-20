# Checklist Pre-Producción

**Fecha de creación:** 2026-10-22  
**Objetivo:** Verificar que el proyecto está listo para producción  
**Estado:** 📋 EN PROGRESO
**Última revisión:** 2026-11-20

---

## 🎯 Próximos pasos priorizados (2026-11-18)

Orden sugerido. El detalle de cada ítem está en su sección.

| # | Pendiente | Prioridad | Tipo | Requiere |
|---|---|---|---|---|
| 1 | ~~Limpieza de media~~ ✅ Edge Function `cleanup-media` (Storage API) + pg_cron `media-cleanup` (`011_media_cleanup_storage_api.sql`); cubre imágenes y audio. Falta setup de secrets (ver `supabase/functions/README.md`) | ✅ | Backend | Aplicar 011 + secrets + deploy |
| 2 | ~~Limpieza de idempotency keys~~ ✅ pg_cron directo (`010_idempotency_cleanup_cron.sql`); trigger y Edge Function eliminados | ✅ | Backend | Aplicar migración 010 |
| 3 | ~~Configuración por entorno~~ ✅ `--dart-define` (`AppEnvironment`, `config/<env>.json`; ver README "Entornos"). Falta crear `config/staging.json`/`prod.json` y un proyecto Supabase de staging si se quiere | ✅ | Infra | Crear los JSON |
| 4 | App ID definitivo `com.shadows.chismes` ✅ y signing release Android vía `key.properties` ✅ (`docs/ANDROID_RELEASE_SIGNING.md`). Falta: generar keystore, clients OAuth de Google con el ID nuevo (Android + iOS, `GoogleService-Info.plist` y `REVERSED_CLIENT_ID`), registrar el App ID en Apple, beta (TestFlight / internal track) | 🔴 | Deploy | Cuentas de Apple/Google |
| 5 | ~~Moderador local duplicado~~ ✅ eliminado de `lib/` (2026-11-19); la moderación vive solo en `moderate-gossip`. Ver "Hoja de ruta de moderación" | ✅ | Código | — |
| 6 | ~~Regla GetIt~~ ✅ `PATTERNS.md` ajustado al patrón real: screens/root usan `getIt` en `initState`, widgets hoja no. Deuda: `gossip_card`, `language_selector`, `settings_section` aún lo usan | ✅ | Arquitectura | — |
| 7 | ~~`debugPrint` en `lib/`~~ ✅ No se pasan a `AppLogger` los del propio logging (`RemoteLogger`, `AppLogger`, `DeviceInfoProvider`): sería un ciclo. Ahora solo imprimen en debug (antes salían en release). `ErrorHandler` ya estaba bajo `kDebugMode`. Contador de rebuilds de `AddGossipScreen` eliminado | ✅ | Código | — |
| 8 | ~~Docs con nombres viejos de migraciones~~ ✅ Tabla de equivalencias en `supabase/migrations/README.md` ("Nombres anteriores → archivo actual"). No se reescribieron los reportes históricos: un reemplazo masivo rompía su contexto (`mv`, mapeos, números de línea) | ✅ | Docs | — |
| 10 | ~~Test SQL roto~~ ✅ `001_gossip_creation_security_test.sql` reescrito con UUIDs reales; verificado que falla sin la 012 y pasa con ella | ✅ | Tests | — |
| 11 | 🔴 **Vulnerabilidad corregida (2026-11-19):** `upsert_gossip_idempotent` y otras 8 funciones SECURITY DEFINER eran ejecutables por `anon`: sin login se podía publicar un chisme aprobado a nombre de cualquier usuario. Fix: `012_revoke_client_execute_server_functions.sql`. **Aplicar en prod cuanto antes** | 🔴 | Seguridad | `supabase db push` |
| 9 | Apple Sign-In: código listo, falta config externa (ver `docs/google_sign_in_setup.md`) | 🟡 | Externo | Apple Developer (USD 99/año) |


### ⏭️ Siguiente sesión (dejado 2026-11-20)

Hecho 2026-11-19/20 (aplicado a `chismes-dev` con `scripts/reset-database.sh`):
AuthGate valida la sesión con el servidor; lectura de chismes solo vía la vista
`public_gossips`; moderación de imagen con fail-closed; reportes con umbral
configurable y cola de revisión humana (`moderation-review`). El reset borró los
usuarios: el usuario del mantenedor (Google) se re-registró y tiene
`app_metadata.role = moderator`.

**Probar en la app (no verificado aún en el remoto):** publicar con imagen
(confirma que `OPENAI_API_KEY` funciona: si todo queda en revisión, la key
falla), reportar un chisme ajeno (debe mostrar éxito), y listar la cola con
`moderation-review`.

**Siguiente recomendado:** C (reglas de moderación en tabla), panel de
moderación (ítem 4 de la hoja de ruta) o sanciones (ítem 7).

1. ~~**AuthGate debe validar la sesión con el servidor**~~ ✅ (2026-11-19) `AuthRepository.validateSession()` (`GET /auth/v1/user`) en segundo plano al iniciar y al volver a primer plano (máx. cada 5 min). Cierra sesión solo si GoTrue responde `user_not_found`, `session_not_found`, `user_banned` o `bad_jwt` (o 401/403 sin código); sin red/timeout/5xx conserva la sesión. Con el access token vencido no valida: lo resuelve el refresh. Mejora posterior 🟢: cerrar sesión ante cualquier 401 de Edge Functions/PostgREST, y avisar en Login "tu sesión expiró".
2. ~~**Privacidad de la tabla `gossips`**~~ ✅ (2026-11-19, en 001/008/009) Los clientes ya no leen la tabla: leen la vista `public_gossips` (columnas explícitas, autor de anónimos oculto salvo para su autor). Feed y `search_gossips` leen la vista; `search_gossips` solo `authenticated`. `report-gossip` adaptada. Test: `supabase/tests/004_anonymous_author_privacy_test.sql`. Aplicado a `chismes-dev` (2026-11-20).
3. 🔴 **Ítem 4 (App ID):** keystore de release, cliente OAuth Android de release (SHA-1 de la llave de release + Play App Signing), registrar App ID en Apple, beta (TestFlight / internal track).
4. 🟡 **Pendientes de este checklist:** tests E2E de Edge Functions (automatizar el E2E local que se hizo a mano), backups/PITR. Moderación de imagen, reportes y cola: ✅ (ver "Hoja de ruta de moderación").

### 🛡️ Hoja de ruta de moderación (decidida 2026-11-19)

Principio: **toda decisión de moderación en el servidor**. La app nunca modera
(se puede saltar modificando el APK, y expondría las reglas).

1. 🔴 **Reglas en tabla** (`moderation_rules`: términos, patrones, umbrales) leídas por `moderate-gossip`, editables sin deploy ni release de app.
2. ~~**Cola de revisión humana**~~ ✅ (2026-11-19, backend) `013_moderation.sql` + Edge Function `moderation-review` (solo `app_metadata.role = 'moderator'`): `list` con URL firmada de la media en cuarentena; `decide` aprobar (publica la media) / rechazar (oculta, no borra; gravedad obligatoria). El veredicto `review` de `moderate-gossip` se encola con la ruta de su media, y `cleanup-media` no la borra mientras esté pendiente. Cada decisión guarda autor, gravedad y motivo (base de sanciones). Genérica por tipo de contenido (lista para comentarios). Tests: `005_moderation_test.sql`, `moderation-review/logic.test.ts`, E2E local.
3. ~~**Reportes → cola**~~ ✅ (2026-11-19) `content_reports` (genérica, reemplaza a `gossip_reports`) + trigger: entra a la cola con ≥ `report_min_count` reportes de cuentas con ≥ `report_min_account_age_hours`; se auto-oculta si además supera `report_ratio` de las interacciones; desde `report_popular_interactions` nunca se oculta solo (prioridad alta). Todo en `moderation_settings`, editable sin desplegar. Arreglado: el umbral nunca funcionaba (`protect_critical_fields` revertía el UPDATE del trigger; `report-gossip` contaba solo los reportes propios). Además: la app mostraba error al reportar (esperaba 200; la función responde 201) y el autor podía reportar lo propio.
4. 🟡 **Panel de moderación** (UI sobre `moderation-review`: aprobar/rechazar, historial, apelaciones).
5. ~~**Moderación de imagen**~~ ✅ (2026-11-19) `moderate-gossip/moderation.ts`: texto + imagen en una sola llamada a `omni-moderation-latest` (imagen como data URL, nunca una URL de cuarentena); imagen marcada → reject y se borra de cuarentena. **Fail-closed:** sin API key, error, timeout (10 s) o respuesta inválida → `review`, nunca se publica. **Audio → `review` siempre** (no se modera automáticamente; la UI sigue oculta). Tests: `moderation.test.ts` (Deno, OpenAI simulado). Pendiente 🟡: texto dentro de la imagen (OCR → mismas reglas de datos personales), detección de CSAM por hash, audio con transcripción + moderación del texto y duración máxima.
6. 🟢 **Aviso previo en la app** vía un endpoint de pre-validación del servidor (no copiando reglas).
7. 🟡 **Sanciones al usuario** (faltas/strikes por gravedad → advertencia → restricción temporal para publicar/comentar → suspensión; lo crítico suspende directo; apelación). Los datos ya se guardan: `moderation_queue.content_author_id`, `decision_severity`, `decision_reason`. Falta: tabla de sanciones, reglas de duración, bloqueo en el servidor (`moderate-gossip`) y aviso en la app.
8. 🟢 **Comentarios:** al implementarlos, reutilizar reportes y cola agregando `comment_id` (ver cabecera de `013_moderation.sql`) y moderarlos con la misma lógica (`moderation.ts`) antes de publicar.

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
- [x] ✅ OpenAI API key en Supabase Secrets (`OPENAI_API_KEY`, desde 2026-10-17)
- [ ] 🟡 Configurar timeouts de Edge Functions (10s default ok)
- [ ] 🟡 Configurar CORS apropiado

### RLS (Row Level Security)

- [x] ✅ RLS habilitado en tabla `gossips`
- [x] ✅ RLS habilitado en tabla `error_logs`
- [x] ✅ RLS en bucket `image-quarantine` (privado)
- [x] ✅ RLS en bucket `image` (público con restricciones)
- [x] ✅ RLS en bucket `audio-quarantine` (privado)
- [x] ✅ RLS en bucket `audio` (público con restricciones)
- [ ] 🔴 Verificar políticas con tests (ver `test/integration/README.md`)

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
- [x] ✅ `MvpContentModerator` / `ContentModerator` eliminados (2026-11-19): reglas solo en el servidor
- [ ] 🟡 Agregar comentarios de advertencia en mocks
- [x] ✅ `MockLocationRepository` eliminado de DI (2026-11-18)

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

### Integración

- [ ] 🔴 Tests de autenticación Edge Functions (5 casos)
- [ ] 🔴 Tests de validación Edge Functions (8 casos)
- [ ] 🔴 Tests de RLS gossips (8 casos)
- [ ] 🔴 Tests de RLS storage (6 casos)
- [ ] 🔴 Tests de media validation (7 casos)

### E2E

- [ ] 🔴 Crear gossip sin media (golden path)
- [ ] 🔴 Crear gossip con imagen (golden path)
- [ ] 🔴 Idempotencia (retry con misma key)
- [ ] 🟡 GPS denegado → selección manual
- [ ] 🟡 Pérdida de red durante submit

**Estimación para completar P0:** 10-12 días (ver `test/integration/README.md`)

---

## ⚙️ CONFIGURACIÓN SUPABASE

### Database

- [x] ✅ Migraciones aplicadas (001-009, consolidadas)
- [x] ✅ Seeds aplicados (países, regiones, ciudades)
- [x] ✅ pg_cron configurado (error logs cleanup)
- [x] ✅ Limpieza de media programada: job `media-cleanup` → Edge Function `cleanup-media` (migración 011)
- [ ] 🔴 Aplicar 011 en prod + secrets `MEDIA_CLEANUP_SECRET` y Vault (`project_url`, `anon_key`, `media_cleanup_secret`)
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
  - [x] `OPENAI_API_KEY`
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

- [x] ✅ Configuración por entorno con `--dart-define` (`lib/core/config/app_environment.dart`)
- [ ] 🔴 Configurar signing (iOS): firma automática con el team ya configurado; falta registrar `com.shadows.chismes` en Apple Developer
- [x] ✅ Signing (Android) preparado: `key.properties` → ver `docs/ANDROID_RELEASE_SIGNING.md` (falta generar el keystore)
- [x] ✅ Versión 1.0.0+1 (`pubspec.yaml`)
- [x] ✅ App ID definitivo `com.shadows.chismes` (Android, iOS, macOS, Linux)
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
- [x] ✅ `docs/TEST_PLAN_85.md` (plan de coverage, cerrado)
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
   - Ver: `test/integration/README.md`

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
   - ~~Arreglar controller tests~~ ✅ (suite 100% verde, coverage 97%)
   - ~~Eliminar debugPrint~~ ✅ solo debug, dentro del logging
   - ~~Decidir `MvpContentModerator`~~ ✅ eliminado

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
