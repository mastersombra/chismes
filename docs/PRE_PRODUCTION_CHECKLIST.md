# Checklist Pre-Producción

**Fecha de creación:** 2026-10-22  
**Objetivo:** Verificar que el proyecto está listo para producción  
**Estado:** 📋 EN PROGRESO
**Última revisión:** 2026-11-24 (notificaciones in-app; antes: seguidores, perfil editable, políticas en la app)

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

**Hecho 2026-11-20:** reglas de moderación en tabla (`moderation_rules`, ítem 1
de la hoja de ruta). **Aplicar a `chismes-dev`:** reset con la 013 modificada
(`scripts/reset-database.sh`) + desplegar `moderate-gossip`.

También 2026-11-20: panel de moderación en la app (ítem 4). **Probar en la app**
con el usuario moderador: Perfil → Panel de moderación (requiere desplegar
`moderation-review` y el reset con la 013 modificada).

**Hecho 2026-11-21:** sanciones, apelaciones y reincidentes (ítem 7 de la hoja
de ruta). **Aplicar a `chismes-dev`:** reset con la 015
(`scripts/reset-database.sh`) + desplegar `account-status`, `moderate-gossip`,
`report-gossip` y `moderation-review`. **Probar en la app:** rechazar con
gravedad alta un chisme de una cuenta de prueba → no puede publicar → apela
desde Perfil → Estado de la cuenta → el moderador acepta en Apelaciones → puede
publicar otra vez.

También 2026-11-21: la app no mostraba los errores específicos de
`moderate-gossip` (rate limit, contenido rechazado, imagen inválida): todo salía
como error genérico porque `functions.invoke` lanza `FunctionException` en
respuestas no 2xx. Arreglado en `SupabaseGossipRemoteDataSource.edgeFunctionFailure`.

Deuda 🟢: `social` importa `Gossip`/`GossipCard` de `features/gossip` (igual que
Home y Search); lo limpio es moverlos a `core/`. `tools/audit_dependencies.sh`
no detecta imports relativos entre features.

Deuda 🟢: Perfil importa pantallas de `features/moderation` (panel y estado de
la cuenta); lo limpio es navegar por rutas registradas en `core/`.

**Hecho 2026-11-24:** políticas legales dentro de la app (es/en) con aviso en
Registro y Login, Perfil → Legal y Perfil → Ubicación; registro de aceptación
en el servidor (`016_policy_acceptances.sql`); código muerto de privacidad
eliminado. Los textos se alinearon con lo que hace la app (sanciones reales,
apelación desde la app, eliminación inmediata, rutas de menú). **Aplicar a
`chismes-dev`:** reset con la 016 (`scripts/reset-database.sh`).

**Hecho 2026-11-24 (2):** Editar perfil (foto, nombre, @usuario, bio) vía la
Edge Function `update-profile`: modera texto y foto (rechazo con aviso, IA
caída → reintentar; nunca queda en revisión), con sanción vigente no se edita
texto ni foto, @usuario una vez cada 30 días. **Vulnerabilidad corregida:** la
app escribía `profiles` directo (bio/nombre sin moderar, cualquier
`avatar_url`); ahora no tiene permiso (`017_profile_editing.sql`). Opciones del
Perfil reales: `user_settings` (notificaciones, privacidad, mostrar email y
actividad) y tema Sistema/Claro/Oscuro local. Arreglado: el Perfil no mostraba
@usuario, nombre ni bio (el usuario de la sesión no traía el perfil).
**Aplicar a `chismes-dev`:** reset con la 016 y 017 + desplegar
`update-profile`, `moderate-gossip` y `delete-account` (`reset-database.sh`
despliega todas). Pendiente 🟡: las opciones de notificaciones y privacidad se
guardan pero aún no tienen efecto (no hay notificaciones, seguidores ni
perfiles públicos); al implementarlos, leer `user_settings`.

**Hecho 2026-11-24 (3): seguidores y bloqueos** (`018_social_follows_blocks.sql`,
feature `lib/features/social`). Seguir libre en cuentas públicas y con
solicitud en privadas (`privacy_level` ahora tiene efecto y queda
`public`/`private`); listas de seguidores/seguidos, quitar seguidor,
solicitudes, bloquear/desbloquear (ambos sentidos, oculta perfil y chismes con
perfil; los anónimos nunca). Autor visible (nombre/@usuario/foto) solo en
chismes con perfil; feed Siguiendo real (antes vacío y recibía el `user_id`
del cliente); búsqueda de usuarios; contadores reales en Perfil; límite
anti-spam de 60 follows/hora y 300/día (`moderation_settings`). Home, Search,
Gossip y Perfil abren `social` vía `core/navigation/social_navigator.dart`.
**Aplicar a `chismes-dev`:** reset con 016+017+018 (`scripts/reset-database.sh`).
Pendiente 🟢: contador de solicitudes pendientes en Perfil; botón Seguir en
listas y búsqueda. `follow_notifications` sigue sin efecto hasta implementar
notificaciones.

**Hecho 2026-11-24 (4): notificaciones dentro de la app** (`019_notifications.sql`,
feature `lib/features/notifications`). Las crean triggers del servidor (nunca
la app): nuevo seguidor, solicitud (se borra al responderla o cancelarla) y
solicitud aceptada; decisión humana de moderación (rechazo con motivo, nunca
la nota interna; aprobado tras revisión o tras ocultar por reportes) y
apelación resuelta. `notifications_enabled`/`follow_notifications` ya tienen
efecto: apagan solo las sociales (las de la cuenta llegan siempre).
Anti-spam por (destinatario, tipo, autor); bloquear borra los avisos entre
ambos; pg_cron borra las de más de 90 días. App: campana con contador en
Home (sin Realtime: se refresca al abrir, al volver a primer plano y al
cambiar de pestaña), pantalla paginada que marca leídas las que muestra.
Navegación vía `core/navigation/notifications_navigator.dart` y
`account_navigator.dart` (Estado de la cuenta, implementado en moderation).
Tests: SQL `011` (N1–N13), 92 Flutter. **Aplicar a `chismes-dev`:** reset con
la 019 (`scripts/reset-database.sh`). Pendiente 🟡: **push** (FCM/APNs,
requiere cuentas de Apple/Google; `push_notifications` sigue sin efecto),
email. Pendiente 🟢: abrir el chisme al tocar "aprobado"; `comments`/`likes`
sin efecto hasta que existan.

**Siguiente recomendado:** los pendientes 🔴 del ítem 4 (App ID / release).

1. ~~**AuthGate debe validar la sesión con el servidor**~~ ✅ (2026-11-19) `AuthRepository.validateSession()` (`GET /auth/v1/user`) en segundo plano al iniciar y al volver a primer plano (máx. cada 5 min). Cierra sesión solo si GoTrue responde `user_not_found`, `session_not_found`, `user_banned` o `bad_jwt` (o 401/403 sin código); sin red/timeout/5xx conserva la sesión. Con el access token vencido no valida: lo resuelve el refresh. Mejora posterior 🟢: cerrar sesión ante cualquier 401 de Edge Functions/PostgREST, y avisar en Login "tu sesión expiró".
2. ~~**Privacidad de la tabla `gossips`**~~ ✅ (2026-11-19, en 001/008/009) Los clientes ya no leen la tabla: leen la vista `public_gossips` (columnas explícitas, autor de anónimos oculto salvo para su autor). Feed y `search_gossips` leen la vista; `search_gossips` solo `authenticated`. `report-gossip` adaptada. Test: `supabase/tests/004_anonymous_author_privacy_test.sql`. Aplicado a `chismes-dev` (2026-11-20).
3. 🔴 **Ítem 4 (App ID):** keystore de release, cliente OAuth Android de release (SHA-1 de la llave de release + Play App Signing), registrar App ID en Apple, beta (TestFlight / internal track).
4. 🟡 **Pendientes de este checklist:** ~~tests E2E de Edge Functions~~ ✅ (2026-11-20, `./scripts/e2e.sh`: 60 casos con Supabase local + OpenAI falso, más los tests SQL; en el CI vía `.github/workflows/backend.yml`), backups/PITR. Moderación de imagen, reportes y cola: ✅ (ver "Hoja de ruta de moderación").

### 🛡️ Hoja de ruta de moderación (decidida 2026-11-19)

Principio: **toda decisión de moderación en el servidor**. La app nunca modera
(se puede saltar modificando el APK, y expondría las reglas).

1. ~~**Reglas en tabla**~~ ✅ (2026-11-20) `moderation_rules` en `013_moderation.sql`, leída por `moderate-gossip` en cada chisme: términos (normalizados, palabra completa), umbrales por categoría de OpenAI (`min_score` → review/reject; solo endurecen, lo `flagged` se rechaza siempre) y on/off + acción de las reglas fijas (amenaza, datos personales, spam). Las regex siguen en el código a propósito (ReDoS). **Fail-closed:** si no se pueden leer o hay una fila inválida → review (`rules_unavailable`). CHECK contra typos; clientes sin acceso. Tests: `moderation.test.ts` (32), `005_moderation_test.sql` (R1–R5), `003_api_grants_test.sql`. Pendiente 🟢: definir umbrales iniciales de IA (hoy ninguno: mismo comportamiento que antes).
2. ~~**Cola de revisión humana**~~ ✅ (2026-11-19, backend) `013_moderation.sql` + Edge Function `moderation-review` (solo `app_metadata.role = 'moderator'`): `list` con URL firmada de la media en cuarentena; `decide` aprobar (publica la media) / rechazar (oculta y conserva el texto; borra la media pública, ver nota de storage; gravedad obligatoria). El veredicto `review` de `moderate-gossip` se encola con la ruta de su media, y `cleanup-media` no la borra mientras esté pendiente. Cada decisión guarda autor, gravedad y motivo (base de sanciones). Genérica por tipo de contenido (lista para comentarios). Tests: `005_moderation_test.sql`, `moderation-review/logic.test.ts`, E2E local.
3. ~~**Reportes → cola**~~ ✅ (2026-11-19) `content_reports` (genérica, reemplaza a `gossip_reports`) + trigger: entra a la cola con ≥ `report_min_count` reportes de cuentas con ≥ `report_min_account_age_hours`; se auto-oculta si además supera `report_ratio` de las interacciones; desde `report_popular_interactions` nunca se oculta solo (prioridad alta). Todo en `moderation_settings`, editable sin desplegar. Arreglado: el umbral nunca funcionaba (`protect_critical_fields` revertía el UPDATE del trigger; `report-gossip` contaba solo los reportes propios). Además: la app mostraba error al reportar (esperaba 200; la función responde 201) y el autor podía reportar lo propio.
4. ~~**Panel de moderación**~~ ✅ (2026-11-20) En la app (`lib/features/moderation`), entrada en Perfil visible solo si `app_metadata.role = 'moderator'` (el servidor igual exige el rol: sin él, 403 → "sin permisos"). Pestañas Pendientes / Aprobados / Rechazados con scroll infinito; detalle con contenido, imagen en cuarentena (URL firmada), razones traducidas, reportes, autor real (también de anónimos); aprobar (con confirmación) o rechazar (gravedad obligatoria, motivo predefinido, nota interna). Si otro moderador ya decidió (409/404) avisa y lo saca de la lista. Backend: `list` acepta `offset`, el historial se ordena por `decided_at` desc y la vista trae `author_username`/`author_display_name`. Tests: 71 Flutter (100% en casi todo el módulo), `logic.test.ts`, `005` D3. Apelaciones: ✅ pestaña propia (ítem 7). Pendiente 🟡: reproducir el **audio** en el panel (hoy solo indica que hay audio).
5. ~~**Moderación de imagen**~~ ✅ (2026-11-19) `_shared/moderation.ts`: texto + imagen en una sola llamada a `omni-moderation-latest` (imagen como data URL, nunca una URL de cuarentena); imagen marcada → reject y se borra de cuarentena. **Fail-closed:** sin API key, error, timeout (10 s) o respuesta inválida → `review`, nunca se publica. **Audio → `review` siempre** (no se modera automáticamente; la UI sigue oculta). Tests: `moderation.test.ts` (Deno, OpenAI simulado). Pendiente 🟡: texto dentro de la imagen (OCR → mismas reglas de datos personales), detección de CSAM por hash, audio con transcripción + moderación del texto y duración máxima.
6. 🟢 **Aviso previo en la app** vía un endpoint de pre-validación del servidor (no copiando reglas).
7. ~~**Sanciones al usuario + apelaciones**~~ ✅ (2026-11-21) `015_sanctions.sql`. Falta = rechazo humano no anulado (la IA no sanciona). Puntos leve 1 · media 2 · alta 4 · crítica suspende; vencen a los 90 días; 3 pts → 24 h sin publicar ni reportar, 6 → 7 días, 10 → suspensión indefinida. Calculadas del historial (no se guardan). Bloqueo en `moderate-gossip` y `report-gossip` (403 `account_restricted`, antes del rate limit, fail-closed). Apelación: una por rechazo en 14 días; aceptada → falta anulada y texto republicado (la media no vuelve). Reincidentes: heredan faltas por la huella del email (`ACCOUNT_HASH_SECRET`). App: Perfil → **Estado de la cuenta** (estado, puntos, rechazos, apelar) y pestaña **Apelaciones** en el panel. Todo configurable en `moderation_settings`. Tests: `007` SQL, `sanctions_e2e` (4), Deno, Flutter. Pendiente 🟢: notificar al usuario (push/email) cuando lo sancionan o se decide su apelación; `appeal_different_moderator = 1` cuando haya más de un moderador; una suspensión heredada no se puede apelar (el contenido se borró con la cuenta).
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
- [x] ✅ Políticas de tablas verificadas con tests SQL (`supabase/tests/001`–`005`, en el CI). Falta storage: ver "Tests de RLS storage"

### Datos Sensibles

- [x] ✅ GPS usa `LocationAccuracy.low` (no high)
- [x] ✅ GPS logging solo en `kDebugMode`
- [x] ✅ Modo anónimo implementado
- [x] ✅ Usuario puede olvidar ubicación
- [x] ✅ Solo ciudad guardada (no coordenadas exactas)
- [x] ✅ Prueba de aceptación de las políticas (2026-11-24, `016_policy_acceptances.sql`): el servidor registra versión y fecha al crear la cuenta
- [ ] 🟡 Pedir re-aceptación cuando cambie una política (comparar `policy_acceptances` con `legal_documents`; pantalla "La política cambió")
- [ ] 🟡 Implementar data export (GDPR portabilidad): la Política 5.1/5.4 hoy lo ofrece por email
- [x] ✅ Rectificación desde la app (2026-11-24): Perfil → Editar perfil (Política 5.2)
- [x] ✅ **Eliminación de cuenta desde la app** (2026-11-20; App Store 5.1.1(v) y Google Play): Perfil → Eliminar cuenta, doble confirmación (explicación + escribir ELIMINAR). Inmediata: borra cuenta, perfil, todos los chismes y su media (pública y cuarentena); guarda solo un registro anónimo de faltas si las hubo (`014_account_deletion.sql`, huella HMAC con `ACCOUNT_HASH_SECRET`). Política de privacidad actualizada (v1.1, revisar con abogado). Tests: Flutter, `006`, E2E
- [x] ✅ 014 aplicada + `ACCOUNT_HASH_SECRET` configurado en `chismes-dev` (2026-11-21). Confirmar que `delete-account` está desplegada
- [ ] 🔴 **Página web para pedir la eliminación sin la app** (Google Play la exige en Play Console → Data safety): depende de hospedar las políticas (chismes.app)
- [ ] 🟡 Revocar el token de Apple al eliminar la cuenta (obligatorio solo si se activa Sign in with Apple)
- [x] ✅ Código muerto eliminado (2026-11-24): `PrivacySettingsScreen` y `PrivacyConsentScreen` (y 96 textos sin uso). "Olvidar ubicación" y "No guardar ubicación" pasaron a Perfil → Ubicación (lo promete la Política 5.7)

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
- [x] ✅ `debugPrint` solo dentro del logging y `ErrorHandler`, bajo `kDebugMode` (ver ítem 7 de próximos pasos)
- [x] ✅ Sin comentarios "TODO: spike" en `lib/` (verificado 2026-11-20)
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
- [x] ✅ Tests de controller (suite completa en verde)
- [x] ✅ Cobertura: 97.58% sin `lib/l10n` (objetivo >85%; el CI falla <88%)

### Integración

- [x] ✅ Tests de autenticación Edge Functions (`scripts/e2e.sh`, 6 casos, 2026-11-20)
- [x] ✅ Tests de validación Edge Functions (E2E: 8 casos, incluye rate limit e idempotencia)
- [x] ✅ Tests de RLS gossips (SQL `001`, `003`, `004`: escritura, grants, privacidad del autor)
- [x] ✅ Tests de RLS storage con acceso directo de clientes (2026-11-20, `supabase/tests/e2e/storage_rls_e2e.test.ts`, 26 casos: anon y usuario × 4 buckets × escribir/mover/copiar/borrar/listar/leer/firmar + administrar buckets). Arreglado: los buckets públicos (`images`, `audio`) se podían **listar** sin sesión (política SELECT innecesaria en `006`; las URLs públicas no la necesitan). Arreglado: al rechazar un chisme ya publicado, su foto/audio seguía accesible por URL pública para siempre; ahora `apply_moderation_decision` la desvincula y `moderation-review` la borra (texto conservado para apelación)
- [x] ✅ Tests de media validation (E2E: magic bytes, tamaño, imagen marcada, cuarentena → público)

### E2E

- [x] ✅ Crear gossip sin media (golden path) — E2E backend (falta E2E desde la app)
- [x] ✅ Crear gossip con imagen (golden path) — E2E backend
- [x] ✅ Idempotencia (retry con misma key) — E2E backend
- [ ] 🟡 GPS denegado → selección manual
- [ ] 🟡 Pérdida de red durante submit

**Estimación para completar P0:** 10-12 días (ver `test/integration/README.md`)

---

## ⚙️ CONFIGURACIÓN SUPABASE

### Database

- [x] ✅ Migraciones aplicadas en `chismes-dev` (001-014)
- [ ] 🔴 Aplicar 015 (sanciones) en `chismes-dev` + desplegar `account-status`, `moderate-gossip`, `report-gossip`, `moderation-review`
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
  - [x] ~~`MODERATION_THRESHOLD`~~ no aplica: los umbrales viven en la tabla `moderation_rules`
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
- [x] ✅ Políticas dentro de la app (2026-11-24): `assets/legal/` en español e inglés, renderer propio (`SimpleMarkdown`), aviso con links en Registro y Login (Google/Apple también crean cuentas) y Perfil → Legal. Al hospedarlas, la app puede seguir mostrando la copia local
- [ ] 🟡 Revisión legal de políticas (abogado), incluida la traducción al inglés. Falta definir ley aplicable y tribunales en los Términos (`[PAÍS/ESTADO A DEFINIR]`)
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

- [x] ✅ GitHub Actions configurado (`flutter.yml`, `backend.yml`)
- [x] ✅ Tests automáticos en PR (Flutter + coverage ≥88%; backend: Deno, tests SQL y E2E cuando cambia `supabase/**`)
- [x] ✅ Build automático de APK en push/PR a main (artefacto, sin firma de release)
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

1. **Tests de seguridad**
   - ~~RLS tests de tablas~~ ✅ · ~~Edge Functions tests~~ ✅ (en el CI)
   - ~~RLS de storage con acceso directo de clientes~~ ✅
   - E2E golden paths desde la app (el backend ya está cubierto)

2. **Configuración Supabase** (2 días)
   - ~~OpenAI API key en Secrets~~ ✅
   - Email provider
   - Backups automáticos
   - Point-in-time recovery

3. **Build y signing** (1 día)
   - iOS signing (registrar `com.shadows.chismes`)
   - Android: generar keystore (`key.properties` ya preparado)
   - ~~Versión 1.0.0~~ ✅

4. **Legal** (1 día)
   - Hospedar políticas en web
   - Links en app
   - ~~Eliminación de cuenta desde la app~~ ✅ · falta la página web para pedirla (Google Play)

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
   - Notificaciones (in-app ✅ 2026-11-24; falta push)

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
- 🔴 Tests E2E de golden paths (backend ✅; falta desde la app)
- ~~🔴 Eliminación de cuenta desde la app~~ ✅ (falta aplicar 014 + secret en el remoto)
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

# Backend: tests SQL + E2E de Edge Functions (Docker + Supabase CLI)
./scripts/e2e.sh
# Esperado: ✅ E2E OK

# Verificar coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
# Esperado: >88% sin lib/l10n (umbral del CI)

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
