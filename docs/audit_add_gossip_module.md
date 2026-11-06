# Auditoría técnica — `add_gossip` y dependencias directas

Fecha: 2026-10-20  
Estado de salida: **no apto para producción todavía**

## Alcance y método

Esta auditoría se limita al flujo de creación de un chisme y a lo que lo hace posible: formulario, controlador y estado, ubicación, creación, media, caché, Supabase, Edge Function de moderación/rate limit, migraciones, configuración, logging y pruebas directas. No se auditó la implementación de login, search ni profile.

Se revisó el código Dart y SQL/TypeScript relacionado, los permisos Android/iOS necesarios para este flujo, las dependencias pertinentes y las pruebas. Se ejecutaron:

```text
flutter analyze lib/features/gossip lib/core/media lib/core/config/supabase_config.dart \
  lib/core/error lib/core/result lib/core/logging lib/core/id lib/core/validation \
  lib/core/audit lib/core/services/location_service.dart
→ Sin diagnósticos.

flutter test test/features/gossip test/core/media
→ Falló: 51 pruebas.

flutter test test/features/gossip/presentation/controllers/add_gossip_controller_test.dart
→ 61 pruebas correctas.

flutter test test/features/gossip/domain/usecases/create_gossip_test.dart \
  test/features/gossip/data/datasources/supabase_gossip_remote_data_source_test.dart \
  test/core/media/supabase_storage_service_test.dart
→ 164 pruebas correctas.
```

No se desplegó ni se atacó un proyecto Supabase real. Por ello, los hallazgos del backend son estáticos, con evidencia directa en las migraciones y la Edge Function; deben confirmarse en un entorno de staging después de corregirlos.

## Resumen ejecutivo

La base de UI y dominio es aprovechable: hay entidades inmutables, validación local, `Result`, abstracción de repositorio, protección contra respuestas obsoletas al cambiar ubicación y una intención correcta de delegar moderación al servidor. Sin embargo, la frontera de confianza no está cerrada y el flujo de media no es compatible con las políticas actuales.

Los cuatro bloqueadores son:

| Prioridad | Hallazgo | Consecuencia |
| --- | --- | --- |
| P0 | Una `SUPABASE_SERVICE_ROLE_KEY` configurada está en `.env`, y `.env` se empaqueta como asset. | Cualquier APK/IPA distribuido puede revelar una llave que bypasa RLS. |
| P0 | La política `INSERT` de `gossips` usa `WITH CHECK (true)`. | Un cliente modificado puede crear contenido público/aprobado sin pasar por moderación ni rate limit. |
| P0 | La Function permite continuar sin usuario autenticado y usa `spike-user`. | Los borradores pueden quedar visibles/editables por cualquiera y el rate limit no opera con ese identificador no UUID. |
| P1 | La subida/finalización de media se hace desde el cliente después de crear el chisme. | Para contenido publicado la actualización choca con RLS; se informará éxito sin imagen y pueden quedar archivos huérfanos o públicos antes de moderarse. |

No conviene hacer una prueba de estrés amplia todavía. Primero deben cerrarse los P0/P1 y recuperar una suite verde. Sí conviene, desde ya, preparar datos sintéticos, métricas y casos de carga para ejecutarlos en staging una vez exista esa base segura.

## Flujo actual y límites de confianza

```text
AddGossipScreen
  → AddGossipController
  → CreateGossip
  → GossipRepository / SupabaseGossipRemoteDataSource
  → Edge Function `moderate-gossip`
  → tabla `gossips`

En paralelo para imagen (actualmente incompleto):
  CreateGossip → SupabaseStorageService → Storage desde el cliente
               → UPDATE directo a `gossips` desde el cliente
```

La primera rama tiene una buena intención: el cliente envía texto y la Function decide estado y moderación. La segunda rompe esa frontera porque el caso de uso de dominio importa `SupabaseClient` y actualiza la tabla directamente. La creación y finalización de media deben pertenecer al mismo límite confiable del servidor.

## Hallazgos prioritarios

### P0-01 — Service role empaquetado en la aplicación

**Evidencia.** `.env` contiene una `SUPABASE_SERVICE_ROLE_KEY` configurada. `pubspec.yaml:86-88` incluye el archivo entero como asset y `main.dart:34-38` lo carga al iniciar. Ignorarlo en Git (`.gitignore:47-50`) evita un commit accidental, pero no evita que el secreto viaje dentro del binario.

**Impacto.** La service role de Supabase es un secreto de servidor: puede bypasear RLS. Si una build que la contiene llegó a un dispositivo, hay que asumir que la llave está comprometida, aunque `SupabaseConfig` sólo lea la anon key hoy.

**Acción antes de continuar.** Rotar la service role en Supabase, revocar la anterior, eliminarla del `.env` que empaqueta Flutter y de cualquier variante móvil. Mantener sólo URL y publishable/anon key en configuración de cliente; service role exclusivamente en Secrets de Edge Functions y en un entorno de CLI/CI no distribuido. Revisar también el historial de Git y los artefactos de CI si alguno pudo contenerla.

### P0-02 — Se puede bypasear la moderación por REST directo

**Evidencia.** `supabase/migrations/001_create_gossips_table.sql:135-142` permite `INSERT` con `WITH CHECK (true)`. El trigger de `:223-263` sólo fuerza contadores a cero durante un `INSERT`; no fuerza `status`, `moderation_status`, `visibility`, `created_by` ni la ruta de moderación. El cliente conoce la URL y la anon key por diseño.

**Impacto.** Un actor no necesita usar Flutter ni invocar `moderate-gossip`: puede usar PostgREST con la anon key e insertar directamente un registro con `status='published'`, `moderation_status='approved'` y `visibility='public'`. Es una vulnerabilidad actual, no un riesgo teórico.

**Corrección.** Crear una nueva migración de endurecimiento —no modificar una migración ya aplicada— que elimine las políticas permissivas de `INSERT`/`UPDATE` para `anon` y `authenticated`. La única vía de creación debe ser la Function/RPC privilegiada. Si posteriormente hay edición de borradores, exponer una operación de servidor que autorice campos y transiciones explícitamente. Añadir una prueba de integración negativa que pruebe que el `INSERT` REST directo recibe 403.

### P0-03 — El modo `spike-user` anula autenticación, privacidad y rate limiting

**Evidencia.** La Function obtiene el usuario en `supabase/functions/moderate-gossip/index.ts:101-111`, pero no corta cuando `authError || !user`; en `:125` usa `'spike-user'`. Las políticas SQL mantienen excepciones para ese literal en `001...sql:121-127` y `:150-162`. La tabla `rate_limits.user_id` es `UUID NOT NULL` (`005_create_rate_limits_table.sql:10-14`), mientras el fallback es texto no UUID.

**Impacto.** En el spike, los borradores de `spike-user` son seleccionables y actualizables por cualquier consumidor que use la anon key; además las consultas/insert de rate limit fallan y el código opta por continuar. Los contenidos en revisión no conservan aislamiento por autor. Esto no puede pasar a producción.

**Corrección.** Exigir una sesión válida al inicio de la Function y derivar siempre `user.id`; eliminar todos los fallbacks `spike-user`, las políticas de spike y los datos de ejemplo antes del lanzamiento. Usar `created_by UUID REFERENCES auth.users(id)` en una migración de evolución cuando se active auth. Cubrir con pruebas: sin JWT → 401; JWT A no lee/edita borrador de B; JWT A sí recupera sólo su borrador.

### P0-04 — Rate limit evadible incluso con usuarios reales

**Evidencia.** `checkRateLimit` hace lecturas separadas y si cualquiera falla retorna `null` (`moderate-gossip/index.ts:290-377`); la inserción del registro ocurre después de crear el gossip y sus fallos se ignoran (`:386-409`). Dos solicitudes concurrentes pueden pasar las verificaciones antes de registrar su acción. La guía actual declara explícitamente la estrategia fail-open (`docs/rate_limiting.md:448-478`).

**Impacto.** En una funcionalidad de contenido generado por usuarios, un fallo de base de datos o ráfagas concurrentes permiten spam/costo de moderación. El índice existente ayuda a velocidad (`005...:25-32`), pero no convierte varias lecturas y una escritura en una decisión atómica.

**Corrección.** Antes de moderar, ejecutar una única operación transaccional/RPC en PostgreSQL que serialice por usuario (por ejemplo, lock por usuario) y reserve el cupo; si la moderación o inserción falla, liberar la reserva de forma segura. Para esta barrera antiabuso, preferir fail-closed o una degradación explícita de "no podemos publicar temporalmente", no permitir ilimitadamente. Medir reintentos e intentos bloqueados.

### P1-01 — Media: el diseño actual falla con RLS y no es atómico

**Evidencia.** Tras crear el gossip, `CreateGossip` sube archivos y hace `UPDATE gossips` con el cliente Flutter (`lib/features/gossip/domain/usecases/create_gossip.dart:128-173` y `:191-201`). Sin embargo, la política de update sólo permite filas que ya estén en `draft` (`001...sql:150-162`); una publicación aprobada por la Function llega como `published`. Si el upload, thumbnail o update falla, el `catch` retorna éxito sin imagen. `SupabaseStorageService` sube full y thumbnail de forma separada (`lib/core/media/supabase_storage_service.dart:88-105`), sin compensación si falla un paso.

**Impacto.** Una publicación aprobada con imagen puede quedar creada pero sin `image_url`, mientras el archivo queda almacenado. La UI confirma éxito, por lo que el usuario no puede reintentar conscientemente. La afirmación documental de "0% huérfanos" no se cumple ante caída entre upload y update. Adicionalmente, no hay una migración versionada que cree el bucket `images` ni sus políticas; su configuración no es reproducible ni auditable desde el repositorio.

**Corrección propuesta.**

1. No enviar URLs arbitrarias al endpoint ni actualizar `gossips` desde Flutter.
2. Usar un bucket privado de cuarentena con path acotado al usuario y políticas de objeto versionadas en SQL. El servidor valida tamaño, MIME real, decodificación/dimensiones y propiedad del objeto.
3. La Function finaliza una operación: valida/adjunta el objeto, modera, crea o actualiza la fila con service role y sólo publica/mueve media al aprobar. Todo fallo debe devolver un resultado recuperable y dejar una limpieza programada.
4. Conservar `storage_path` canónico, no sólo URL pública; emitir URL firmada o pública únicamente cuando el estado lo permita.

Hasta implementar eso, ocultar el selector de imagen o mostrarlo explícitamente como no disponible. Los handlers actuales sólo escriben un warning (`add_gossip_controller.dart:513-524`) aunque la UI ofrece Cámara y Galería (`image_picker_widget.dart:171-205`).

### P1-02 — La Function no valida el contrato antes de moderar ni valida ubicación

**Evidencia.** El body se convierte por aserción de tipo (`moderate-gossip/index.ts:114`) y sólo se valida por "truthiness" (`:116-122`). No hay máximo de longitud, tipo, UUID de idempotencia ni normalización antes de llamar a OpenAI (`:183-184`). La tabla `gossips` tiene límites máximos (`001...sql:36-37`), pero permite texto vacío tras `trim`; los IDs de país/región/ciudad son `TEXT` sin claves foráneas (`:30-33`).

**Impacto.** Un cliente modificado puede enviar texto enorme a moderación antes de que PostgreSQL lo rechace, aumentando latencia y costo; también puede persistir texto de sólo espacios o ubicaciones inexistentes. `published_as` sí termina protegido por un `CHECK`, pero demasiado tarde y con una respuesta de servidor genérica.

**Corrección.** En la Function, antes de rate limit costoso/moderación: exigir objeto JSON, strings no vacíos tras trim, 200/1000 caracteres, enum permitido, UUID v4 y límites de body. Validar la jerarquía de location en servidor. Para integridad duradera, agregar FKs/triggers compuestos una vez existan las tablas de location o hacer la validación en una RPC transaccional. Probar payloads inválidos y una carga de textos máximos/límites.

### P1-03 — Idempotencia no es segura bajo concurrencia

**Evidencia.** La Function busca primero la clave (`moderate-gossip/index.ts:134-152`) y después inserta (`:205-224`). Existe un índice único (`001...sql:93-96`), pero el segundo request concurrente acabará en violación única y respuesta 500 en lugar de devolver el gossip original.

**Impacto.** Evita muchos duplicados, pero no el caso precisamente crítico de doble tap, timeout/retry o solicitudes simultáneas. También crea una experiencia incorrecta: el usuario puede creer que falló y reintentar.

**Corrección.** Resolver creación e idempotencia en una sola transacción/RPC: insert con conflicto controlado y lectura del registro existente, siempre acotado por `created_by` + clave. Mantener la misma clave mientras el usuario reintenta el mismo intento; el controlador actual genera una nueva en cada `submit` (`add_gossip_controller.dart:638-651`), lo que sólo protege el doble tap mientras sigue en memoria, no un retry posterior tras timeout/reinicio.

## Arquitectura, estado y mantenibilidad

La separación `presentation → domain → data` está presente para creación normal (`AddGossipController` → `CreateGossip` → `GossipRepository`). Es una decisión razonable para el tamaño actual y facilita sustituir implementations. Hay tres desvíos relevantes:

| Severidad | Principios afectados | Evidencia y efecto | Recomendación |
| --- | --- | --- | --- |
| Media | DIP, separación de responsabilidades | El caso de uso de dominio importa `SupabaseClient`/`SupabaseStorageService` (`create_gossip.dart:1-8`, `:69-80`) y ejecuta SQL (`:197-200`). El dominio queda atado a infraestructura y salta el repositorio/RLS. | Definir un puerto de media/finalización en domain y dejar la implementación Supabase en data; idealmente una sola operación de servidor. |
| Media | SRP, mantenibilidad | `AddGossipController` reúne formulario, GPS, preferencias persistentes, selección de imagen, idempotencia y sincronización de cinco notifiers en 769 líneas. Sus comentarios incluso declaran que no debería conocer GPS (`:27-44`), pero inyecta `LocationService` (`:112`). | Extraer selección de ubicación y media en collaborators/use cases. Mantener al controller como orquestador de eventos de UI. |
| Baja | Fuente única de verdad | Existe `AddGossipState`, cinco `ValueNotifier` y un `ChangeNotifier`. Cada cambio llama `notifyListeners()` (`add_gossip_controller.dart:731-755`) y la pantalla escucha el controller entero (`add_gossip_screen.dart:50-61`). | Elegir estado granular con selectores o mantener un único notifier. No duplicar estado salvo que se deje de reconstruir el árbol global. |
| Baja | Contrato de datos | `GossipModel.toJson()` usa camelCase (`gossip_model.dart:414-437`) pero el backend usa snake_case; hoy no se usa para requests remotos, sólo caché. | Separar explícitamente serialización de caché y DTO de API, o usar un mapa SQL consistente. Impedir que una futura llamada reutilice el JSON equivocado. |

La máquina de estados y el validador local son valiosos para UX, pero no son un control de seguridad: el servidor debe mantener la autoridad de estados, ubicación, contadores y ownership.

## Rendimiento y escalabilidad

### Rebuilds y UI

Es un hallazgo real, aunque no un bloqueo al volumen actual: escribir cada carácter dispara `_updateState`, que llama `notifyListeners`, y reconstruye el `Scaffold` completo por el `AnimatedBuilder` global. Los `ValueListenableBuilder` internos no evitan esa reconstrucción inicial. Al añadir previews, progreso o catálogos mayores, el coste crecerá.

Acción: separar la escucha del estado de ubicación/publicación de los campos de texto y usar `child` invariante donde aplique. Medir en profile mode con un formulario completo antes y después; no optimizar a ciegas.

### Ubicación y autocomplete

`SupabaseLocationRemoteDataSource.getCitiesByRegion()` hace `select()` de todas las columnas y todas las ciudades de la región (`lib/features/location/data/datasources/supabase_location_remote_data_source.dart:78-89`). Luego `CityAutocomplete` hace un filtro O(n) y crea una nueva lista por cada pulsación (`city_autocomplete.dart:79-90`). Existe ya una RPC indexada `search_cities`, pero el flujo `add_gossip` no la utiliza.

Para regiones pequeñas es aceptable. Para catálogos de GeoNames de gran tamaño no lo es: aumenta transferencia, memoria y jank. Cambiar a búsqueda remota con debounce de 250–350 ms, mínimo 2–3 caracteres, cancelación/ignorancia de respuestas viejas y límite de 20 resultados. Cachear países/regiones y las consultas recientes, no un país completo de ciudades.

### Feed, paginación y media producida por este flujo

1. `GossipQuery` usa por defecto `orderBy: 'createdAt'` (`gossip_query.dart:44-47`), pero la columna PostgreSQL es `created_at` (`001...sql:64`). El datasource pasa el valor sin traducir (`supabase_gossip_remote_data_source.dart:59-62`). En Supabase real esto puede producir un error de columna y caer a caché vacía.
2. El cursor existe en `GossipQuery` pero el datasource lo ignora. El feed no tiene paginación keyset real; con inserciones concurrentes habrá duplicados o saltos al implementarla después.
3. El repositorio, al caer al cache, devuelve todo el cache sin aplicar el `GossipQuery` (`gossip_repository_impl.dart:37-45`). Aunque `GetGossips` vuelve a filtrar estados públicos, no conserva filtros de ciudad/región/país.
4. Se almacena `thumbnail_url` (`001...sql:42`) pero no existe en `Gossip`/`GossipModel`; `GossipCard` usa `imageUrl` completo (`gossip_card.dart:83-98`). Se paga la generación de thumbnail sin aprovecharla y se consumirá más red de la necesaria.
5. El trigger de limpieza de idempotency hace, con 10% de los inserts, un `UPDATE` global de filas antiguas (`001...sql:269-310`). A escala crea escrituras, WAL y contención dentro del camino de publicación. Mover esa limpieza a una tarea programada e indexar la condición de selección si se conserva el TTL.

Para el feed público, evaluar en staging los planes de consulta y crear índices parciales que coincidan con cada acceso real, por ejemplo ciudad + `(created_at DESC, id DESC)` condicionado a contenido publicado, aprobado, público y no eliminado. No crear todos los índices por anticipación: respaldarlos con `EXPLAIN (ANALYZE, BUFFERS)` y carga representativa.

## Seguridad, privacidad y observabilidad adicionales

### Media y contenido externo

La Function acepta `audio_url` e `image_url` recibidos del cliente (`moderate-gossip/index.ts:213-215`). Un cliente no confiable puede apuntarlos a hosts externos. Cuando se rendericen, esos hosts pueden rastrear IP/dispositivo de quien ve el gossip. Aceptar sólo referencias/paths emitidos por tu propio flujo de storage, nunca URLs arbitrarias.

Como se trata de una app de contenido sobre personas, una foto o audio pendiente no debe ser público antes de moderación. La política de Storage debe ser privada por defecto; publicar/firmar sólo después de la decisión autorizada. Agregar reporte, apelación, bloqueo, retención/borrado de contenido y revisión humana antes del lanzamiento público.

### GPS y minimización

El flujo requiere sólo ciudad, pero solicita precisión alta (`location_service.dart:71-76`), declara permiso "Always" en iOS (`ios/Runner/Info.plist:43-47`) y registra coordenadas exactas en logs de info (`location_service.dart:78-81`, `:107-110`).

Usar permiso sólo "When In Use", precisión suficiente para escoger ciudad y nunca registrar latitud/longitud en release. Mantener la ciudad como preferencia es menos sensible que conservar coordenadas, pero documentar claramente propósito, consentimiento y opción "olvidar ubicación". Revisar política de privacidad y el envío de texto a un proveedor de moderación antes de recoger usuarios reales.

### Logging y modo release

`SupabaseConfig.initialize` mantiene `debug: true` (`supabase_config.dart:15-20`). Debe depender de `kDebugMode`/flavor. Además `SupabaseRemoteLogger` intenta insertar directamente con el cliente móvil (`remote_logger.dart:46-54`), pero `error_logs` permite insert sólo a `service_role` (`004_create_error_logs.sql:43-54`). En producción los errores se perderán silenciosamente, pues se capturan y sólo se imprimen.

Enviar logs saneados mediante una Function autenticada o un proveedor de observabilidad con token de ingesta de alcance mínimo; aplicar allowlist de `context`, no incluir texto del gossip, URLs firmadas, headers, tokens ni coordenadas. Definir retención, acceso administrativo y alertas. La limpieza de logs está definida pero no hay evidencia de scheduler que la ejecute.

## UX, accesibilidad y preparación de media

La pantalla usa controles, labels y objetivos táctiles con buen punto de partida. Hay dos problemas visibles:

1. La UI promete adjuntar foto, pero `image_picker` ni siquiera está declarado en `pubspec.yaml`; los callbacks no seleccionan archivo. No debe llegar a usuarios como una opción funcional.
2. Una prueba reprodujo un `RenderFlex overflow` en `CompactLocationSelector` con texto largo/carga. La fila interna contiene spinner + texto y un botón "Cambiar" de ancho mínimo (`compact_location_selector.dart:53-125`); la prueba `compact_location_selector_test.dart` falla precisamente en ese caso. Usar `Flexible` para el texto de carga, un `Wrap`/layout vertical para anchos estrechos o un botón sólo icono en breakpoint pequeño.

También hay tokens visuales sin centralizar en `LocationChangeDialog` (`BorderRadius.circular(16/12)`, tamaños de texto), menores pero inconsistentes con `AppRadius` y el tema.

## Pruebas: qué cubren y qué falta

La lógica local tiene cobertura útil: el controller (61 pruebas), use case, datasource mock y validadores prueban validación, carrera país/región/ciudad, doble submit en memoria y mapeo de resultados. Eso no valida los controles de servidor.

La prueba activa de la pantalla está rota: los 48 casos de `test/features/gossip/presentation/screens/add_gossip_screen_test.dart` fallan porque el mock sólo prepara `state`, listeners y ubicación (`:22-28`), pero la pantalla ahora exige `failureNotifier`, `imageNotifier`, `isUploadingImageNotifier` e `isSubmittingNotifier` (`add_gossip_screen.dart:80-166`). Es una desincronización de test al introducir notifiers, no evidencia por sí sola de que la pantalla falle en dispositivo; aun así deja sin garantía el flujo principal.

Antes de producción, añadir estas pruebas automatizadas:

| Capa | Casos mínimos |
| --- | --- |
| Edge Function / integración | JWT ausente/expirado; INSERT/UPDATE REST directos prohibidos; schema inválido; ubicación inválida; moderación provider caído; timeout; 429; payload máximo. |
| Base de datos | RLS con usuarios A/B; transición de estados; contador inmutable; idempotencia simultánea; reserva/rollback de rate limit; migración limpia desde cero. |
| Media | MIME real incorrecto, pixel bomb/tamaño, objeto de otro usuario, fallo entre full/thumb/finalización, limpieza idempotente, contenido pendiente no legible. |
| Flutter widget | Actualizar los stubs de notifiers; validación visible, error/retry, sin overflow 320 px + texto grande + escalado de fuente, cámara/galería disponible o oculta. |
| E2E | Crear sin media, pendiente/aprobado/rechazado, reintento conservando misma idempotency key, GPS denegado, pérdida de red y retorno desde background. |

Los tests unitarios de Storage no sustituyen una prueba real del bucket/RLS/Function. Tampoco se encontró un directorio `integration_test/` para este flujo.

## Mocks, temporalidad y configuración a retirar

| Elemento | Uso actual | Acción |
| --- | --- | --- |
| `MockGossipRemoteDataSource` | No está registrado para producción; conserva datos en memoria para tests/desarrollo. | Mantener sólo para tests. No usarlo como referencia de seguridad ni idempotencia real. |
| `MockGossipLocalDataSource` | En memoria, sólo tests. | Mantener para tests. |
| `MvpContentModerator` | Regla local; la implementación activa de producción usa la Edge Function. | Mantener como test/fallback explícito, sin confundirla con moderación de servidor. |
| `spike-user`, políticas permissivas y seed sample | Activos en Function/migración, no sólo documentación. | Eliminar con migración y exigir auth antes de beta externa. |
| Selector imagen/audio | Imagen se muestra pero no selecciona; audio ni se presenta en la pantalla actual. | Ocultar hasta tener el flujo seguro y completo o implementar como P1. |
| `.env` móvil con service role | Activo y empaquetado. | Rotar/remover inmediatamente; separar configuración móvil de secretos backend. |

No recomiendo añadir dependencias nuevas salvo `image_picker` cuando se decida entregar media. Antes de eso, ocultar los controles evita una dependencia y una promesa de UX incumplida.

## ¿Pruebas de estrés ahora?

**Aún no una prueba de estrés amplia.** Correrla ahora mediría una arquitectura que permite bypases, no un límite de capacidad confiable; además la moderación externa puede producir costos, rate limits ajenos y datos en logs. Primero cerrar P0/P1, usar staging aislado y recuperar CI verde.

Después, ejecutar en staging con usuarios sintéticos autenticados, contenido no sensible y claves distintas a producción:

1. **Smoke de seguridad y contrato:** 20 solicitudes concurrentes con la misma idempotency key deben devolver el mismo `id`; el POST directo a tabla debe ser 403; el límite por usuario no debe superarse bajo concurrencia.
2. **Carga escalonada de texto:** warm-up, luego 1, 5 y 10 creaciones/segundo durante 10–15 minutos, ajustando el objetivo a la proyección de usuarios. Medir p50/p95/p99 de Function, porcentaje de 5xx/429, cold starts, errores del proveedor de moderación, conexiones y uso de DB.
3. **Media por separado:** mezcla realista de 0/1 imagen por publicación, redes lentas y cancelaciones. Medir tasa de huérfanos, tamaño final, egress y reintentos. No probar archivos reales de usuarios.
4. **Soak corto:** 1–2 horas a carga sostenida para observar `rate_limits`, logs, limpieza y crecimiento de Storage. Verificar `EXPLAIN ANALYZE` de feed, rate limit y cleanup.
5. **Prueba de degradación:** timeout de OpenAI, Storage inaccesible, Postgres lento y pérdida de red de cliente. La salida debe ser un error seguro y recuperable, nunca publicación sin moderación ni bucle de retry.

Definir antes los SLO de producto; como punto inicial, publicar texto debería tener una tasa de éxito funcional alta y p95 medido por separado para "validación local", "moderación" y "persistencia". No usar una cifra única que esconda lentitud del proveedor externo.

## Checklist de salida a producción

### Bloqueadores

- [ ] Rotar service role y retirar todos los secretos del asset móvil.
- [ ] Nueva migración que elimine el modo spike y bloquee CRUD directo de `gossips`/Storage.
- [ ] Autenticación obligatoria en la Function y ownership basado sólo en `auth.uid()`.
- [ ] Rate limit/idempotencia atómicos y pruebas concurrentes.
- [ ] Validación de schema, longitudes, IDs y ubicación antes de moderar.
- [ ] Flujo de media privado, autorizado por servidor, con compensación/cleanup y políticas de bucket versionadas.
- [ ] Reparar los 48 widget tests de `AddGossipScreen` y dejar CI verde.

### Antes de beta pública

- [ ] Traducir `createdAt` a `created_at`, implementar paginación keyset y tests de contrato Supabase.
- [ ] Cambiar ciudades a autocomplete remoto con debounce y límites.
- [ ] Resolver overflow en ancho pequeño, font scale alto y estado de GPS/carga.
- [ ] Desactivar `debug` en release y hacer operativo el logging remoto saneado.
- [ ] Eliminar precisión GPS/logs innecesarios y solicitar sólo permiso "When In Use".
- [ ] Política de privacidad, reglas de moderación, canal de reportes/apelación y proceso de borrado/retención.
- [ ] Staging reproducible: migraciones desde cero, secretos separados, backups, rollback probado y dashboards/alertas.

## Orden recomendado de ejecución

1. Contener el secreto: rotación y separación de configuración.
2. Aplicar migración de cierre RLS + exigir auth; verificar con pruebas negativas.
3. Rehacer la operación de crear/moderar/idempotencia/rate limit como límite atómico de servidor.
4. Decidir si media entra en la primera beta. Si sí, completar el flujo privado de servidor; si no, ocultarla.
5. Corregir contratos de feed/cache, tests de pantalla y responsive.
6. Desplegar staging, ejecutar pruebas de integración y sólo entonces las cargas escalonadas.

Con esos pasos, la arquitectura actual puede evolucionar sin rehacer la UI: el controller seguirá invocando un caso de uso de creación, pero el servidor se convertirá en la fuente de verdad para identidad, estados, moderación, media y límites.
