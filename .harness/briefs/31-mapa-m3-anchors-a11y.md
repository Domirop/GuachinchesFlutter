Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M3 (de la serie M1…M13, uno por harness)**: **pase de accesibilidad/anchors** sobre los controles interactivos del mapa que hoy NO tienen `Semantics(identifier:)`. Hoy el único anchor del fichero es `mapa-refresh-fab` (+ `mapa-island-chip` que añadió M2). Cliente-puro, sin tocar backend ni modelo. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO escribir tests de widget** que monten `MapSearch` (rabbit hole: GoogleMap platform-view, cubits, presenter, geolocator, remote-config).

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

- Controles interactivos SIN anchor hoy:
  1. **Search field** — `TextField` dentro de `_MapHeader.build` (~líneas 2079-2101). Sin `Semantics`.
  2. **Quick pills** — widget `_QuickPill` (~línea 2317). Se usa para "ABIERTO AHORA" y para cada categoría (en `_MapHeader`, ~líneas 2155-2169). Estado activo se distingue por color **y** por `fontWeight` (w800 vs w600) — ya hay afordancia no-cromática, pero falta semántica de "seleccionado" para lectores de pantalla, y no hay identifier estable.
  3. **FAB centrar-en-usuario** — `FloatingActionButton.small(heroTag:'centerOnUser')` (~línea 826). Sin anchor.
  4. **FAB refresh** — ya envuelto en `Semantics(identifier:'mapa-refresh-fab')` (~línea 871) pero sin `button:true`/`label`.
  5. **Tarjetas del carrusel** — `_FloatingMapCard` (~línea 1588): `GestureDetector` → `RestaurantDetailScreen(id: r.id)`. Sin anchor. Tiene `restaurant.id` y nombre disponibles.
- Regla del repo (CLAUDE.md §1): anchors = `Semantics(identifier: '<screen>-<componente>-<rol>')`, **kebab-case inglés**; `label:` en **español** (para lector de pantalla); NUNCA `label:` como anchor técnico.

---

CONTRATO FUNCIONAL (sólo M3) — añadir `Semantics` a cada control:

1. **Search field:** envolver el `TextField` (o su contenedor inmediato) en `Semantics(identifier: 'mapa-search-field', textField: true, label: 'Buscar restaurantes', child: ...)`. No cambiar el `decoration`/hint visual.

2. **Quick pills:** añadir un parámetro `final String identifier;` (requerido) a `_QuickPill` y envolver su `GestureDetector` en `Semantics(identifier: identifier, button: true, selected: active, label: label, child: ...)`. En `_MapHeader`, pasar:
   - Pill "ABIERTO AHORA": `identifier: 'mapa-pill-abierto'`.
   - Pills de categoría: `identifier: 'mapa-pill-${c.id}'` (id estable de la categoría).
   - (El `_DriveExitPill`/`_EnterDrivePill` son de modo coche — quedan fuera de M3, NO añadir anchors ahí; eso va con M5.)
   - NO cambiar colores (`GlobalMethods.blueColor` → AppColors es **M4**).

3. **FAB centrar-en-usuario:** envolver en `Semantics(identifier: 'mapa-center-fab', button: true, label: 'Centrar en mi ubicación', child: FloatingActionButton.small(...))`.

4. **FAB refresh:** enriquecer el `Semantics` existente con `button: true` y `label: 'Refrescar restaurantes'` (mantener `identifier: 'mapa-refresh-fab'`).

5. **Tarjetas del carrusel:** envolver el `GestureDetector` de `_FloatingMapCard` en `Semantics(identifier: 'mapa-card-${r.id}', button: true, label: r.nombre /* o el campo de nombre que use el modelo */, child: ...)`. Verifica el nombre real del getter de nombre en `Restaurant` (`lib/data/model/restaurant.dart`) — usa el que exista (p. ej. `nombre`); si no hay nombre trivial, deja sólo `identifier` + `button: true` (NO inventar copy).

---

NO MODIFICAR / NO ROMPER:
- El `BlocListener`/recarga de M1, el chip selector de M2, la lógica de markers, carrusel (más allá de envolver en Semantics), `_refreshVisible`, detección de conducción, cámara chase, defer-mount, los `onPressed`/`onTap` existentes (sólo envolver, no cambiar callbacks).
- Colores, estilos, tamaños, layout — M3 es **sólo semántica/anchors**, cero cambios visuales.
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M3 **NO** toca: doble azul GlobalMethods/AppColors (M4), modo coche dual-theme/anchors de drive (M5), scrim (M6), empty states (M8), ni ningún otro M.

PROHIBIDO (rechazo automático del Evaluator):
- `Semantics(label: ...)` como anchor técnico (el identifier es el anchor; label es para lector de pantalla, en español).
- Identifiers no kebab-case-inglés o no estables (p. ej. derivados de texto traducible en vez del id).
- Cambiar callbacks, colores o layout. Tocar otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff que existen los anchors: `mapa-search-field`, `mapa-pill-abierto`, `mapa-pill-<categoryId>`, `mapa-center-fab`, `mapa-card-<restaurantId>`, y que `mapa-refresh-fab` ahora tiene `button:true`+`label`. Pills con `selected: active`. Cero cambios de color/layout.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones, no arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- Anchors de los controles de **modo coche** (drive pills/strip): van con M5.
- Cambio de color del estado activo (color-blind total): la afordancia no-cromática ya existe (fontWeight); el cambio a AppColors es M4.

ENTREGA:
1. Diff de `map_search.dart` (anchors + Semantics en search, pills, FABs, cards).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M3.

Diff objetivo ≤ 70 líneas.
