# Plan de Tests → Coverage >85%

**Meta:** >85% sin `lib/l10n/` (código generado, decidido 2026-11-18). ✅ Alcanzada en la Sesión 3.
**Estado:** plan cerrado (Sesión 7). El CI falla si el coverage sin l10n baja de 88%.

## 1. Estado actual (2026-11-18, después de la Sesión 7 — plan cerrado)

| Métrica | Valor |
|---|---|
| Coverage sin l10n | **97.44%** (6,816 / 6,995) · CI falla si < 88% |
| Tests | 4,079 pasan · 0 fallan · 3 skip (tag `integration`, requieren Supabase real) |
| Sesiones hechas | 1–7 (detalle en §6 Tracking) |
| Pendientes | — |

---

## 2. Reglas (leer completas antes de empezar)

### Qué NO hacer
1. **No modificar `lib/`.** Si un test destapa un bug de producción, **detenerse y avisar al usuario** con archivo, línea y propuesta. Solo corregirlo si el usuario lo aprueba.
2. **No reescribir ni borrar archivos de test completos.** Agregar grupos o editar tests puntuales. Un archivo existente puede tener tests reales que hoy cubren líneas; si se reemplaza, el coverage baja (pasó en la Sesión 3: 83.4% → 81.9%).
3. **No borrar un test que pasa** salvo que sea falso (ver §2.3). Antes y después de borrarlo, medir el archivo: el coverage no debe bajar.
4. **No correr `build_runner` sobre todo el proyecto.** Reusar los mocks generados que ya existen (importarlos con prefijo, ej. `import '...login_screen_test.mocks.dart' as login_mocks;`) o escribir uno a mano: `class _MockX extends Mock implements X {}`.
5. **No modificar los helpers de `test/helpers/`**, solo agregar. Los usa toda la suite.
6. **No tocar `lib/l10n/` ni escribir tests para el código generado.**
7. **No crear reportes `.md` nuevos.** El único registro es la tabla §6 de este archivo.
8. **No usar tiempo real** (`Future.delayed` en el test, `sleep`). Usar `tester.pump(Duration)`.
9. **No dejar estado global sucio.** Todo `getIt.registerSingleton` en un test lleva su `addTearDown(() => getIt.unregister<T>())`.
10. **No hacer `--amend` ni push.** Un commit por archivo terminado o por sesión.

### Flujo obligatorio por archivo
1. Medir el archivo objetivo (comando §4) y anotar las líneas sin cubrir.
2. Leer esas líneas en `lib/` y los tests que ya existen para ese archivo.
3. Buscar en esos tests los patrones falsos de §2.3 y corregirlos ahí mismo.
4. Escribir tests contra las líneas sin cubrir.
5. **Volver a medir el archivo.** Si no subió, el test es falso: corregirlo antes de pasar al siguiente.
6. Correr `flutter analyze` sobre los tests tocados: 0 issues.

### Tests falsos que existen en este repo (detectarlos y corregirlos)
| Patrón | Por qué es falso | Corrección |
|---|---|---|
| `const x = 'a'; expect(x, 'a')` o copiar una función privada al test y probar la copia | No ejecuta código de `lib/` | Probar a través del método público real |
| Capturar `addListener` en **una** variable | La screen también registra el listener de `AnimatedBuilder`; se captura el equivocado | Guardar todos en una lista y llamarlos todos |
| `expect(captured, isNotNull)` como única aserción | Pasa aunque la lógica no corra | Asertar el resultado visible: snackbar, navegación, `verify(...)` |
| `find.text('...')` de un helperText o hint | Siempre está visible | Buscar el texto de error real vía `AppLocalizations` |
| `try { await x(); } catch (_) {}` + `verify(logger...)` | No prueba el resultado | `expectLater(x(), throwsA(isA<T>()))` |
| Tap sobre un widget fuera de pantalla | El tap no llega (warning "would not hit test") y el test pasa por error | `await tester.ensureVisible(finder)` antes del tap |
| `expect(true, isTrue)`, grupos "documentation" | No prueba nada | Borrar |

---

## 3. Recetas que funcionan

**Supabase (tablas y RPC):** `test/helpers/fake_supabase_http.dart`, un `SupabaseClient` real sobre `http.Client` falso.
```dart
final fake = FakeSupabaseHttp();
final ds = MiDataSource(fake.client, MockAppLogger());
fake.respondJson([...]);           // éxito
fake.respondError(400);            // PostgrestException (usar 4xx en GET: 503/520 se reintentan)
fake.respondRaw('null');           // RPC que retorna null
expect(fake.lastRequest.url.queryParameters['order'], 'name.asc.nullslast');
expect(fake.lastBody, {...});      // params de RPC
```
Notas: `.order(col)` es DESC por defecto y siempre agrega `.nullslast`. Edge Functions (`functions.invoke`) se mockean con `MockFunctionsClient` (ver `supabase_gossip_remote_data_source_test.dart`).

**Textos:** nunca hardcodear strings en español. `AppLocalizations.of(tester.element(find.byType(MiScreen)))!.clave`.

**Pop/navegación:** para probar `Navigator.pop`/`canPop`, montar la screen encima de una ruta base (botón "HOST" que hace `push`). Para `pushNamed('/x')`, armar un `MaterialApp` con `routes: {'/x': ...}` y los mismos delegates que `testableWidget`.

**Screens que navegan a otras:** registrar en GetIt los controllers de la pantalla destino (mocks existentes con prefijo) + `addTearDown`.

**Links en `TextSpan` (`TapGestureRecognizer`):** recorrer los `RichText`, encontrar el span por texto y llamar a `recognizer.onTap!()`.

**Timers en la screen** (debounce, `Future.delayed`): `tester.pump(Duration(...))` exacto; `pumpAndSettle` no avanza timers pendientes.

---

## 4. Comandos

```bash
# Total (sin l10n)
flutter test --coverage > /tmp/cov.txt 2>&1; tail -c 200 /tmp/cov.txt
awk '/^SF:/{skip=($0 ~ /lib\/l10n\//)} /^LF:/&&!skip{lf+=substr($0,4)} /^LH:/&&!skip{lh+=substr($0,4)} END{printf "Coverage sin l10n: %.2f%% (%d/%d)\n", lh*100/lf, lh, lf}' coverage/lcov.info

# Un archivo: correr su test con --coverage y listar líneas sin cubrir
flutter test test/ruta/mi_test.dart --coverage
awk -v f="mi_archivo.dart" '$0 ~ "^SF:.*/"f"$"{p=1;next} p&&/^DA:/{split(substr($0,4),a,","); if(a[2]==0) printf "%s ", a[1]} p&&/^(LF|LH):/{printf "%s ", $0} p&&/end_of_record/{print ""; p=0}' coverage/lcov.info
```
`lcov --remove` falla con lcov 2.6 en esta máquina; por eso se filtra con awk. La salida de `flutter test` es enorme: siempre redirigirla a un archivo o usar `tail`/`grep`.

---

## 5. Sesiones pendientes

### Sesión 5 — UI de gossip/search/profile · ~+200 líneas → ~93%
| Sin cubrir | Cov | Archivo |
|---:|---:|---|
| 74 | 68% | `features/search/presentation/screens/search_screen.dart` |
| 47 | 62% | `features/gossip/presentation/widgets/location_change_dialog.dart` |
| 41 | 51% | `features/gossip/presentation/widgets/gossip_card.dart` |
| 30 | 67% | `features/profile/presentation/screens/profile_screen.dart` |
| 29 | 81% | `features/gossip/presentation/screens/add_gossip_screen.dart` |
| 18 | 55% | `features/gossip/presentation/widgets/media_attachment_section.dart` |

No tocar `test/.../add_gossip_screen_test.dart.disabled` (tests viejos desactivados; decisión aparte).

### Sesión 6 — Auth datasource + core services · ✅ hecha (+268 líneas)
1. **`features/auth/data/datasources/supabase_auth_datasource_impl.dart` (146, 27%)**: la Sesión 2 lo marcó intesteable, pero con `fake_supabase_http.dart` sí se pueden probar `getCurrentUser`, `updateProfile`, `isUsernameAvailable`, `checkEmailExistsAndConfirmed` y probablemente los flujos de email/OTP/reset. **Primero verificar** con un test mínimo que `client.auth.signInWithPassword` pase por el `http.Client` falso; si no pasa, cubrir solo lo que va por `from()`/`rpc()`. **No intentar** Google/Apple OAuth (dependen de plugins nativos): anotarlos como intesteables.
2. `core/services/location_service.dart` (34), `core/services/auth_service.dart` (21), `core/media/supabase_storage_service.dart` (19), `core/media/image_compressor.dart` (12).
3. `core/logging/device_info_provider.dart` (38): mockear el method channel `dev.fluttercommunity.plus/device_info` con `TestDefaultBinaryMessengerBinding`.
4. `core/services/deep_link_service.dart` (64): `AppLinks()` se instancia inline; cubrir solo el parsing/manejo de URIs. Si exige refactor, anotarlo y seguir.

### Sesión 7 — Cierre · ✅ hecha
- [x] Umbral en CI: fallar si coverage sin l10n < 88% (mantiene margen sobre la meta de 85%). Mostrar el cambio de CI al usuario antes de commitear.
- [x] Actualizar métricas en `CLAUDE.md` (sigue diciendo 78.9% / 1,897 tests).
- [x] Mover docs viejos de testing (`docs/TEST_*.md` salvo este, `docs/sesion_7_*`, `docs/test_sessions/`) a `docs/archive/testing/`.
- [x] Preguntar al usuario sobre los 3 tests `skip` de `settings_section_test.dart` (líneas 306, 404, 428: "widget not accessible") y el código de producción sin uso (`media_reference.dart`, `shared/data/gossip_mock_data.dart`, `core/auth/mock_auth_repository.dart`, `core/theme/theme_extensions.dart`).

---

## 6. Tracking

| Sesión | Fecha | Coverage (sin l10n) | Tests (pass/fail/skip) | Notas / intesteables |
|---|---|---|---|---|
| Base | 2026-11-18 | 81.53% | 3,965 / 10 / 10 | — |
| 1 | 2026-11-18 | 80.27% | 3,835 / 0 / 13 | Arreglados 7 fallos de media_attachment_section. 3 tests de settings_section en skip. Borrados gossip_module_test y supabase_config_test, 62 `expect(true, isTrue)` y los grupos "documentation". |
| 2 | 2026-11-18 | 82.14% | ~3,938 / 0 / 13 | Auth repository +15 tests. Auth datasource quedó sin cubrir (ver Sesión 6: ahora es testeable con fake HTTP). |
| 3 | 2026-11-18 | **85.84%** ✅ | 4,115 / 0 / 16 | Datasources remotos con `fake_supabase_http.dart`: home 62/62, location 47/47, gossip 141/141, profile 28/32 (4 = `catch` inalcanzables). 🐛 Bug corregido (aprobado por el usuario): `.order('name')` en location ordenaba DESC → `ascending: true`. ⚠️ Un intento previo reemplazó estos tests por tautologías y bajó a 81.88%; revertido. |
| 4 | 2026-11-18 | **90.25%** ✅ | 4,172 / 0 / 6 | 7 screens de Auth al 100% (privacy_settings 256/257). Resueltos 7 skips. Corregidos tests falsos (listener mal capturado, `!= null` como única aserción, helperText). |
| 5 | 2026-11-18 | **93.68%** ✅ | 4,240 / 0 / 6 | Los 6 archivos al 100%: search_screen 238/238, add_gossip_screen 157/157, location_change_dialog 127/127, profile_screen 92/92, gossip_card 85/85, media_attachment_section 40/40. Corregidos tests falsos: 17 de callbacks de ubicación en add_gossip_screen (llamaban al mock directo, sin aserciones, texto inexistente tras un `if`, o sembraban `AddGossipState` cuando el diálogo lee `LocationManager.state`), 1 en location_change_dialog (solo asertaba que no se llamara nada), `Future.delayed` en search_screen → `Completer`. Nuevo helper `test/helpers/fake_network_image.dart` (`Image.network` carga un PNG real). 🐛 Bug corregido (aprobado por el usuario): search_screen se desbordaba con el historial + teclado. Ahora el historial reemplaza al contenido en el `Expanded` (scrollable, `TextFieldTapRegion`), se cierra al perder el foco (`onTapOutside`), la X sin foco vuelve a recientes y los estados vacíos son scrollables. Tests de regresión a 375×667 con teclado de 300px. 🐛 Bug corregido (aprobado): `GossipCard` desbordaba ~46px en la grilla de search a 375 de ancho; con alto fijo la imagen usa `Expanded` y el subject 1 línea, en listas (Home) sigue cuadrada. |
| 6 | 2026-11-18 | **97.42%** ✅ | 4,100 / 0 / 6 | `fake_supabase_http` sí sirve para GoTrue (password, verify, logout): auth datasource 153/200, location_service 71/74, auth_service 39/39, supabase_storage_service 27/27, image_compressor 18/18, device_info_provider 24/48, deep_link_service 74/74. **Intesteables:** Google/Apple OAuth y `_createProfile`/`_ensureProfileExists` (solo se llega por OAuth) = 47 líneas; 3 `catch` de SharedPreferences en location_service; ramas Android/iOS/Linux/Windows de device_info_provider (dependen de `dart:io Platform`; la de macOS solo corre en macOS y CI es Ubuntu). Borrados tests falsos (tautologías que no llamaban a `lib/`; coverage medido antes y después sin cambios): casi todo image_compressor_test, los grupos de lógica de supabase_storage_service_test, los de `Uri.parse` en deep_link_service_test, 2 sin aserciones en device_info y tests vacíos de "singleton en DI". Corregidos 4 `try/catch(_)` + `verify` en el auth datasource. Nuevo helper `test/helpers/fake_image_compress.dart`. 🐛 Bug corregido (aprobado): `ImageCompressor` lanzaba RangeError con archivos sin extensión y cortaba la ruta en un punto de la carpeta. 🐛 Bug corregido (aprobado): `DeepLinkService` leía el tipo de `pathSegments` en vez del host, así que ningún link `chismes://gossip/{id}` compartido se manejaba. |
| 7 | 2026-11-18 | **97.44%** ✅ | 4,079 / 0 / 3 | CI: paso `Enforce coverage threshold` (awk, sin l10n, mínimo 88%) y la suite corre una sola vez (`flutter test --coverage`); verificado local: pasa con 97.42%, falla con mínimo 99%. `CLAUDE.md` actualizado. 14 docs viejos movidos con `git mv` a `docs/archive/testing/` (`SESSION_PROMPTS.md`, `SESSION_STATE.md` y `COVERAGE_ANALYSIS_SUMMARY.md` aún los enlazan con la ruta vieja). Los 3 skips de settings_section eran tests falsos, no un bug: un tap fuera de pantalla y 2 textos hardcodeados inexistentes; corregidos con `AppLocalizations`. Borrado código sin uso (aprobado): `media_reference.dart`, `gossip_mock_data.dart`, `core/auth/mock_auth_repository.dart`, `theme_extensions.dart` y sus tests. Los 3 skips restantes son del tag `integration` (por diseño). `flutter analyze` salía con exit 1 por 7 issues previos en tests, así que el CI se cortaba en "Analyze code". Corregidos (`fake_async` pasa a dev_dependency directa, se borraron helpers y variables sin uso, se renombró `_createContext`): analyze 0 issues, y analyze, tests y umbral salen con 0 localmente. |
