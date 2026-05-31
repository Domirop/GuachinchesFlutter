Resolver el **grupo F (dead code / observabilidad)** de la auditoría de las pantallas de detalle. Dos limpiezas in-scope, puramente cliente, sin tocar backend: (F1) **eliminar código muerto** en `visit_screen.dart` (bloques comentados ⑥⑦, imports huérfanos y el método `_videoQuotes` no referenciado) — esto borra las **3 únicas warnings de `flutter analyze`** que quedaron diferidas desde los sprints C/D/E; y (F2) **dar observabilidad a los `catch` silenciosos** de `restaurant_detail_screen.dart` (4 sitios) vía `AppLogger`, **conservando** el fallback de datos-opcionales (control de flujo idéntico). Cambios sin efecto visual ni de comportamiento observable: se verifican por **code-review + `flutter analyze`** + suite existente verde (regla 5 de CLAUDE.md). **NO escribir tests de widget** que monten estas pantallas (mocking de repos/sqflite/http; rabbit hole).

Ficheros: `lib/ui/pages/visit/visit_screen.dart`, `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**F1 — código muerto en `visit_screen.dart` (genera las 3 warnings vivas de analyze).**
- `flutter analyze` reporta HOY exactamente estas 3 warnings sobre este fichero (las únicas pendientes de los sprints de detalle):
  - `:14` `import '.../widgets/del_video_section.dart'` → **unused_import**.
  - `:20` `import '.../widgets/ticket_card_widget.dart'` → **unused_import**.
  - `:353` `_videoQuotes` → **unused_element** (método declarado pero no referenciado).
- `DelVideoSection` y `TicketCardWidget` sólo aparecen en **bloques comentados**:
  - ⑥ (`:291-295`): `// ⑥ Ticket "42€ PARA DOS" — ocultado…` con `// TicketCardWidget.shouldRender(v)…`.
  - ⑦ (`:297-304`): `// ⑦ DEL VIDEO — ocultado temporalmente…` con `// DelVideoSection( quotes: _videoQuotes(v), …`.
- `_videoQuotes` (`:353-361`) es el **único consumidor** de `ShortQuote`; su único call-site estaba en el bloque ⑦ ya comentado. Al borrarlo, el import `:11` `import '.../data/model/short_quote.dart'` queda huérfano (analyze aún no lo marca porque `_videoQuotes` lo usa; tras borrar el método, marcarlo a mano para no dejar un import muerto nuevo).
- El resto de imports de widgets (`dishes_section`, `ntk_box`, `pros_cons_section`, `restaurant_info_card`, `services_chips_section`, `visit_header_section`, `visit_pills_row`) **SÍ se usan** — NO tocarlos.

**F2 — `catch (_)` silenciosos en `restaurant_detail_screen.dart` (4 sitios).**
- `:125` per-list dentro de `_loadListAppearances` (el `.map` sobre cada lista): `} catch (_) { return null; }` — traga errores de `getCuratedListById(l.id)`.
- `:134` outer de `_loadListAppearances`: `} catch (_) { // silent — listas opcionales }`.
- `:147` de `_loadVisits`: `} catch (_) { // silent — visits are optional }`.
- `:157` per-visit dentro de `_enrichVisits`: `} catch (_) { return v; }` — traga errores de `getVisitById(v.id)`.
- `AppLogger` (`lib/core/logging/app_logger.dart`) **ya está importado** (`:6`) y usado en `_loadRestaurant`/`_loadIsFav` (`:88`, `:96`) con `AppLogger.error('restaurant-detail', e, st)`. API: `info(tag, msg)`, `warn(tag, msg)`, `error(tag, error, [stack])`.
- Estos catches son **fallbacks legítimos de datos opcionales** (listas/visitas no deben tumbar la pantalla). El problema es la **opacidad**: hoy no dejan rastro. Hay que **loguear** (nivel `warn`, no `error` — no es un crash) **manteniendo el mismo control de flujo** (mismo `return null` / `return v` / mismo fallback).

---

CONTRATO FUNCIONAL:

**1. F1 — borrar código muerto en `visit_screen.dart`:**
- Eliminar el import `:14` `del_video_section.dart`.
- Eliminar el import `:20` `ticket_card_widget.dart`.
- Eliminar el import `:11` `short_quote.dart` (queda huérfano tras borrar `_videoQuotes`).
- Eliminar el bloque comentado ⑥ completo (`:291-295`, las 4 líneas `// ⑥ Ticket … // ];`).
- Eliminar el bloque comentado ⑦ completo (`:297-304`, las líneas `// ⑦ DEL VIDEO … // ];`).
- Eliminar el método `_videoQuotes` completo (`:353-361`).
- **Resultado esperado:** las 3 warnings de analyze sobre `visit_screen.dart` (`:14`, `:20`, `:353`) desaparecen y NO aparece ninguna nueva (el import `short_quote` se va con el método).
- **NO** tocar ningún otro import, ni la lógica de render (`④ Descripción`, `⑤ SERVICIOS`, `⑧ LO QUE PEDIMOS`, `⑨ A FAVOR/EN CONTRA`, `⑩ LO QUE NECESITAS SABER`), ni `_description`, ni `_buildFloatingButtons`, ni los anchors `visit-detail-*` (sprint D), ni el theming `context.brand.*` (sprint B), ni el skeleton (sprint C), ni el `sharedHttpClient` (sprint E).

**2. F2 — observabilidad de los catch silenciosos en `restaurant_detail_screen.dart`:**
- `:125` (per-list): mantener `return null;` y añadir antes un `AppLogger.warn('restaurant-detail', 'curated list ${l.id} appearance check failed: $e');` capturando la excepción con `} catch (e) {`.
- `:134` (outer `_loadListAppearances`): mantener el comportamiento silencioso de UI (sin re-throw) y sustituir el comentario por `AppLogger.warn('restaurant-detail', 'list appearances unavailable: $e');` con `} catch (e) {`.
- `:147` (`_loadVisits`): igual, `} catch (e) { AppLogger.warn('restaurant-detail', 'visits unavailable: $e'); }`.
- `:157` (per-visit `_enrichVisits`): mantener `return v;` (fallback al básico) y añadir antes `AppLogger.warn('restaurant-detail', 'visit ${v.id} enrich failed: $e');` con `} catch (e) {`.
- **Conservar EXACTAMENTE** el control de flujo: `_loadListAppearances` sigue sin tumbar la pantalla, `_enrichVisits` sigue devolviendo el básico, `_loadVisits` sigue tragando su error a nivel UI. Sólo se añade el log.
- Usar `warn` (no `error`): son datos opcionales, no fallos fatales. NO añadir stack trace (warn no lo toma); el mensaje incluye `$e`.

---

NO MODIFICAR:
- `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- Los widgets `DelVideoSection`/`TicketCardWidget`/`ShortQuote` en sí (sólo se quitan sus imports/usos muertos de `visit_screen.dart`; los ficheros de esos widgets quedan intactos por si otra pantalla los usa).
- Los anchors `visit-detail-*` / `restaurant-detail-*` (sprint D), el theming (sprint B), los skeletons (sprint C), el `sharedHttpClient` (sprint E), el caching de distancia (sprint E).
- La semántica de `_loadListAppearances`/`_loadVisits`/`_enrichVisits` (el N+1 es estructural/backend, sprint E lo documentó OUT OF SCOPE): NO refactorizar, sólo añadir logging.
- Los `AppLogger.error('restaurant-detail', e, st)` existentes en `_loadRestaurant`/`_loadIsFav`.

---

PROHIBIDO (rechazo automático del Evaluator):
- Dejar `} catch (_)` silencioso en cualquiera de los 4 sitios de `restaurant_detail_screen.dart` (F2 sin resolver).
- Cambiar el control de flujo de los catch (re-throw, mostrar error de UI, romper el fallback `return null`/`return v`): rompería la tolerancia a datos opcionales.
- Borrar imports que SÍ se usan en `visit_screen.dart`, o borrar lógica de render / `_description` / anchors / theming.
- Dejar viva alguna de las 3 warnings de `visit_screen.dart` o introducir una nueva (p.ej. dejar el import `short_quote` huérfano tras borrar `_videoQuotes`).
- Escribir tests de widget que monten estas pantallas; tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.
- Eliminar/“limpiar” warnings preexistentes de OTROS ficheros fuera de scope (`video/`, `videoInput/`, `PoolWebView.dart`, etc.): NO se tocan en este sprint.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze`: las 3 warnings de `visit_screen.dart` (`:14` unused_import, `:20` unused_import, `:353` unused_element) **YA NO aparecen** y no se introduce ninguna nueva. (Siguen permitidos los infos preexistentes de `withOpacity` deprecado en `visit_screen.dart:442/444` y demás ruido de ficheros fuera de scope: `video/`, `videoInput/`, `verifiedVisit/`, `PoolWebView`, tests.)
- Confirmar leyendo el diff: (F1) borrados los 3 imports muertos + bloques ⑥⑦ + método `_videoQuotes`; ningún import vivo eliminado. (F2) los 4 catch de `restaurant_detail` ahora capturan `e` y loguean con `AppLogger.warn('restaurant-detail', …)` **conservando** `return null`/`return v`/silencio-de-UI.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: ~30 tests YA fallan ANTES de este sprint por infra preexistente (`widget_test.dart` template, `settings/login/listas/visitas` por `WebViewPlatform.instance`/remote-config/network mocks). NO son regresiones; no intentar arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- Warnings de `flutter analyze` en ficheros NO-detalle (`video/video.dart`, `videoInput/`, `PoolWebView.dart`, `verifiedVisitsScreen.dart`, ruido en `test/`): limpieza transversal de otro sprint.
- El N+1 de `_loadListAppearances` (estructural/backend, documentado en sprint E): aquí sólo se le añade observabilidad, no se refactoriza.
- Migrar los `AppLogger.warn` a un nivel/estructura distinta o añadir telemetría a Crashlytics para los warns: follow-up.

ENTREGA:
1. Diff con los 2 ficheros (visit_screen: −3 imports, −2 bloques comentados, −1 método; restaurant_detail: 4 catch con logging).
2. `flutter analyze` con las 3 warnings de detalle eliminadas y sin nuevas (resto de ruido preexistente intacto).
3. `flutter test` (suite existente) sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando F1 (dead code fuera) y F2 (catches observables, fallback conservado) por code-review.

Diff objetivo ≤ 40 líneas.
