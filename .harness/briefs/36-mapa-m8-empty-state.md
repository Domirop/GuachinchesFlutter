Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M8 (de la serie M1…M13, uno por harness)**: **empty-state** del mapa. Hoy, cuando la carga termina y el dataset de la isla/filtros está **vacío** (`restaurants.isEmpty`), el mapa NO da ningún feedback — el usuario ve un mapa pelado sin saber si está cargando, si no hay datos, o si sus filtros no casan. Añadir un **estado vacío** flotante (tarjeta centrada sobre el mapa, sin tapar el mapa entero) con copy claro y, si hay filtros activos, una acción "Quitar filtros". Cliente-puro (UI + l10n). Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: `lib/ui/pages/map/map_search.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, y los generados `lib/l10n/app_localizations*.dart` (vía `flutter gen-l10n`). **Nada más.**

---

CONTEXTO (verificado leyendo el código):

- `RestaurantMapState` **NO tiene** estado de Error ni de Loading; sólo `RestaurantInitial`, `RestaurantFilterMap(list)`, `RestaurantMapLoaded(resp)`, `AllRestaurantMapLoaded(resp)`. El `RestaurantMapCubit` **no captura errores** (las excepciones de red burbujean). → El **estado de error real** requeriría añadir un `Error` state + try/catch al cubit (toca `restaurant_map_cubit.dart`/`_state.dart`), lo cual está **FUERA DE ALCANCE** de M8 (cliente-puro, sólo el mapa). M8 = **sólo empty-state**. (El error-state queda como follow-up que sí tocará el cubit.)
- En el `BlocBuilder<RestaurantMapCubit, RestaurantMapState>` (~línea 746), tras computar `restaurants`, se puede saber si la **carga terminó** con: `final loaded = state is AllRestaurantMapLoaded || state is RestaurantFilterMap;`. El empty-state se muestra cuando `loaded && restaurants.isEmpty && !isDriving`.
- Filtros activos = `_quickOpen || _quickCategoryId != null || _searchText.isNotEmpty`. Helpers existentes: `_clearSearch`, `_toggleOpenFilter`, `_toggleCategory`, `_applyQuickFilters`. **No** hay un "limpiar todo" → añadir `_clearAllQuickFilters()`.
- El mapa ya usa l10n generado: `AppL10n.of(context).mapRestaurantsNearby(...)` (import `package:guachinches/l10n/app_localizations.dart`). Config en `l10n.yaml`: template `app_es.arb`, clase `AppL10n`, `nullable-getter:false`. → **Añadir copy nueva como claves l10n**, NO hardcodear strings (antipatrón CLAUDE).
- `context.read<NewHomeFiltersCubit>().state.islandLabel` da el nombre de la isla actual (para copy contextual, opcional).
- Tokens dual-theme `context.brand.*` y `AppTextStyles`/`AppColors` disponibles. Patrón de tarjeta flotante: ver el chip contador (~líneas 917-941, `brand.surface` + borde + sombra).

---

CONTRATO FUNCIONAL (sólo M8):

1. **Claves l10n nuevas** en `app_es.arb` (template) y `app_en.arb`, luego `flutter gen-l10n`:
   - `mapEmptyTitle` → ES "Sin restaurantes" · EN "No restaurants".
   - `mapEmptyWithFilters` → ES "No encontramos sitios con estos filtros. Prueba a quitarlos o cambiar de isla." · EN "No places match these filters. Try clearing them or switching island."
   - `mapEmptyNoFilters` → ES "Todavía no hay restaurantes en esta isla." · EN "There are no restaurants on this island yet."
   - `mapClearFilters` → ES "Quitar filtros" · EN "Clear filters".
   (Incluir los bloques `@clave` de descripción como hace el resto del arb.)

2. **`_clearAllQuickFilters()`** nuevo en `MapSearchState`: cancela el debounce de búsqueda, `_searchController.clear()`, `setState` → `_quickOpen=false; _quickCategoryId=null; _searchText='';`, y recarga (`presenter.getAllRestaurants(islandId)`).

3. **Widget empty-state** (private, p. ej. `_MapEmptyState`, o inline) montado en el `Stack` del builder (como un `Center`/`Positioned` por ENCIMA del mapa pero por DEBAJO del header), visible sólo cuando `loaded && restaurants.isEmpty && !isDriving`:
   - Tarjeta centrada (`brand.surface`, radio ~20, borde `brand.border`, sombra suave) con: icono (`Icons.location_off_outlined` o similar, `brand.textMuted`), título `mapEmptyTitle` (`AppTextStyles` displaySection/ui), subtítulo = `filtros activos ? mapEmptyWithFilters : mapEmptyNoFilters`.
   - Si hay filtros activos, botón "Quitar filtros" (`mapClearFilters`, relleno `AppColors.atlantico` + texto blanco) que llama `_clearAllQuickFilters()`.
   - **NO** tapar todo el mapa: es una tarjeta centrada con ancho acotado (p. ej. `maxWidth ~320`, márgenes), el mapa sigue visible alrededor.
   - Anchors (regla CLAUDE): envolver la tarjeta en `Semantics(identifier: 'mapa-empty-state', label: 'Sin restaurantes')` y el botón en `Semantics(identifier: 'mapa-clear-filters', button: true, label: 'Quitar filtros')`.

---

NO MODIFICAR / NO ROMPER:
- El `RestaurantMapCubit`/`RestaurantMapState` (NO añadir estados ni try/catch — eso es el follow-up de error). El presenter. Sus firmas.
- La lógica de markers, carrusel, drive strip, FABs, header/scrim de M6, padding de M7, recarga de isla M1, chip M2, anchors M3, azul M4, dual-theme M5.
- El `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- NO cambiar el comportamiento cuando SÍ hay resultados (el empty-state sólo aparece con lista vacía tras carga).

PROHIBIDO (rechazo automático del Evaluator):
- Hardcodear los textos del empty-state en Dart (deben venir de `AppL10n`).
- Tapar el mapa completo con un overlay opaco (debe ser una tarjeta centrada acotada).
- Mostrar el empty-state en `RestaurantInitial` (eso es arranque/carga, NO vacío) o en modo coche.
- Tocar el cubit/state/presenter, otros M's, `pubspec.yaml`/`ios/`/`android/`/`main.dart`. Tests de widget que monten `MapSearch`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`). `flutter gen-l10n` sin errores.
- Confirmar por diff: 4 claves nuevas en ambos arb + generados; `_clearAllQuickFilters()`; widget empty-state condicionado a `loaded && restaurants.isEmpty && !isDriving`; botón "Quitar filtros" sólo con filtros activos; anchors `mapa-empty-state` y `mapa-clear-filters`; copy vía `AppL10n`.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- **Estado de ERROR de red** (fetch fallido): requiere añadir un `Error` state + try/catch al `RestaurantMapCubit` → follow-up dedicado (no cliente-puro de un solo fichero).
- Loading/skeleton del mapa mientras carga (hoy `RestaurantInitial`): follow-up.

ENTREGA:
1. Diff de `map_search.dart` + arb + generados (empty-state + l10n + clear-filters).
2. `flutter analyze` + `flutter gen-l10n` sin issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M8 (y la nota de error-state como follow-up).

Diff objetivo ≤ 90 líneas (sin contar los `app_localizations*.dart` generados).
