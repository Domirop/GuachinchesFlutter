Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M1 (de una serie M1…M13, uno por harness)**: hacer que el mapa **respete la isla global** del `NewHomeFiltersCubit` en vez de estar hardcodeado a Tenerife. Cliente-puro, sin tocar backend ni modelo. Verificación por **code-review + `flutter analyze`** (regla 5/6 de CLAUDE.md) + suite existente sin nuevos fallos. **NO escribir tests de widget** que monten `MapSearch` (requiere mockear GoogleMap platform-view, `RestaurantMapCubit`, presenter, geolocator, remote-config; rabbit hole).

Fichero a tocar: `lib/ui/pages/map/map_search.dart` (sólo este).

---

CONTEXTO ACTUAL (verificado leyendo el código):

- El mapa NO importa ni escucha `NewHomeFiltersCubit`. Listas (`listas_screen.dart`) y Visitas (`discover_screen.dart`) SÍ filtran por la isla global vía `BlocBuilder<NewHomeFiltersCubit, NewHomeFiltersState>`.
- En `map_search.dart` la isla está **hardcodeada**:
  - Estado `String _municipalityLabel = 'TENERIFE';` (línea ~73) — se muestra en el chip azul del header (`_MapHeader`, param `municipalityLabel`).
  - El island id UUID `'76ac0bec-4bc1-41a5-bc60-e528e0c12f4d'` aparece como **literal repetido**: en `initState` → `presenter.getAllMunicipalities('76ac0bec-…')` (~línea 117) y en `_applyQuickFilters` como fallback `islandId.isEmpty ? '76ac0bec-…' : islandId` (~líneas 924-926).
  - `String islandId = '';` se rellena vía `setIsland(String)` (callback `MapSearchView`), que a su vez llama `presenter.getAllRestaurants(islandId)` (~líneas 971-975). `presenter.getIsland()` se invoca en `initState` y termina llamando `setIsland(...)` con la isla por defecto.
- `NewHomeFiltersState` (`lib/data/cubit/new_home/new_home_filters_state.dart`) YA expone los tres campos: `islandId` (UUID), `islandKey` ('TF'…), `islandLabel` ('Tenerife'…). Su `initial` es Tenerife (`76ac0bec-…`). El `NewHomeFiltersCubit` está provisto por encima del tab scaffold (lo consume Discover en el tab hermano), así que `context.read/watch<NewHomeFiltersCubit>()` está disponible dentro de `MapSearch`.
- Filtros/red: `_applyQuickFilters()` (~línea 917) llama `restaurantsCubit.getFilterMapRestaurants(... islandId: ...)`. La carga inicial sin filtros llega por `setIsland` → `presenter.getAllRestaurants(islandId)`.

---

CONTRATO FUNCIONAL (sólo M1):

1. **El mapa lee la isla del `NewHomeFiltersCubit`** (fuente única de verdad):
   - El chip del header debe mostrar `filtersState.islandLabel.toUpperCase()` (no la constante `'TENERIFE'`). Elimina el hardcode `_municipalityLabel = 'TENERIFE'` (o pásalo a derivarse del estado).
   - Todas las llamadas que hoy usan el literal `'76ac0bec-…'` o `islandId` interno deben usar `filtersState.islandId` (el UUID de la isla activa). Elimina las apariciones del literal UUID del fichero (queda como única fuente el estado del cubit).

2. **Reaccionar al cambio de isla:** cuando `islandId` del `NewHomeFiltersCubit` cambie (el usuario cambió de isla en otro tab), el mapa debe **recargar los restaurantes** de la nueva isla y re-aplicar los quick-filters activos (`_quickOpen`, `_quickCategoryId`, `_searchText`) sobre la nueva isla. Patrón recomendado: envolver el árbol del mapa (o usar un `BlocListener<NewHomeFiltersCubit,…>` junto al `BlocListener<MenuCubit,…>` ya existente en `build`) que, ante un cambio de `islandId`, dispare la recarga (`presenter.getAllRestaurants(nuevoIslandId)` o `_applyQuickFilters()` con la nueva isla, lo que corresponda según si hay filtros activos).
   - Tras cambiar de isla, **reencuadrar la cámara** a la nueva isla es deseable pero NO obligatorio en M1; si es trivial (centrar en el primer restaurante o dejar que el flujo de ubicación lo maneje) hazlo, si no, queda fuera de alcance (no inventar coordenadas por isla hardcodeadas).

3. **Sin doble carga / sin parpadeos:** evita disparar dos cargas simultáneas en el arranque (la de `presenter.getIsland()`/`setIsland` y la del nuevo listener). Lo más limpio: **sembrar** `islandId` interno desde `filtersState.islandId` en el primer build/initState y dejar el listener sólo para CAMBIOS posteriores. Si `getIsland()` ya no aporta (porque la isla viene del cubit), puedes dejar de llamarlo, PERO sólo si `getAllMunicipalities`/otros consumidores siguen recibiendo un islandId válido (usa `filtersState.islandId`).

---

NO MODIFICAR / NO ROMPER:
- La lógica de markers (`_rebuildMarkers`, `_buildBubbleMarker`, caché de bitmaps, dot icons), el carrusel `_FloatingCardCarousel`, `_refreshVisible`, la detección de conducción (`_DrivingDetector`, modo coche) ni la cámara chase.
- El defer-mount del GoogleMap (`_mapMounted` + `BlocListener<MenuCubit>`), el FAB de centrar, el FAB refresh (`mapa-refresh-fab`), el `_EnterDrivePill`.
- El modelo, el backend, `RestaurantMapCubit`, el presenter (`MapSearchPresenter`) — NO cambiar sus firmas; sólo llamarlos con el islandId correcto. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- Este sprint M1 **NO** toca: el chip muerto sin onTap (eso es M2), los anchors/a11y (M3), el doble azul GlobalMethods/AppColors (M4), ni ningún otro M. SÓLO la fuente de la isla.

PROHIBIDO (rechazo automático del Evaluator):
- Dejar el literal `'76ac0bec-4bc1-41a5-bc60-e528e0c12f4d'` o la constante `'TENERIFE'` hardcodeados en `map_search.dart`.
- Que cambiar de isla en otro tab NO recargue el mapa (M1 sin resolver).
- Romper la carga inicial de restaurantes o provocar doble fetch/parpadeo en el arranque.
- Tocar otros problemas (M2…M13) en este diff. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` sobre `lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: el chip usa `islandLabel` del cubit; el UUID literal y `'TENERIFE'` desaparecen; existe un mecanismo (listener/builder) que recarga al cambiar `islandId`; sin doble carga en initState.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente (remote-config/WebViewPlatform/network mocks); NO son regresiones, no arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- Chip de isla como **selector** tappable (abrir picker de isla desde el mapa): es M2 / follow-up.
- Reencuadre de cámara por isla con coordenadas dedicadas: follow-up.

ENTREGA:
1. Diff de `map_search.dart` (isla desde `NewHomeFiltersCubit`, recarga al cambiar, sin literales).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M1.

Diff objetivo ≤ 80 líneas.
