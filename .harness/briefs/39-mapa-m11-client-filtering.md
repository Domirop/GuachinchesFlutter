Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M11 (de la serie M1…M13, uno por harness)**: **filtrado en cliente de los quick-filters**. Hoy cada toggle de chip (abierto / categoría) y **cada pulsación** de búsqueda (con debounce de 350ms) dispara una llamada de red `getFilterMapRestaurants` → backend `restaurant/findByFilter`. Como el mapa ya carga el **dataset completo de la isla** en memoria (`getAllRestaurants` → `AllRestaurantMapLoaded`), esos filtros se pueden aplicar **en cliente** sobre la lista cargada, sin round-trip por interacción. Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- El mapa carga TODA la isla: `initState` → `presenter.getAllRestaurants(islandId)`; el `RestaurantMapCubit.getAllRestaurants` pagina (15 en 15) hasta vaciar y emite `AllRestaurantMapLoaded(respuesta_completa)`.
- En el `BlocBuilder` (~líneas 748-757) se deriva `restaurants` del estado:
  ```dart
  List<Restaurant> restaurants = _allRestaurants;
  if (state is AllRestaurantMapLoaded) {
    restaurants = state.restaurantResponse.restaurants;
  } else if (state is RestaurantFilterMap) {
    restaurants = state.filtersRestaurants;
  }
  ```
  Después: `_allRestaurants = restaurants; _rebuildMarkers(restaurants);` y `_refreshVisible()` (que recalcula el carrusel intersectando `_allRestaurants` con el viewport). Es decir, **`_allRestaurants` ES el conjunto mostrado** (markers + carrusel derivan de él).
- Quick-filters actuales (todos llaman a red vía `_applyQuickFilters` → `restaurantsCubit.getFilterMapRestaurants(...)`):
  - `_toggleOpenFilter()` (~988): `setState(_quickOpen=!_quickOpen); _applyQuickFilters();`
  - `_toggleCategory(id)` (~993): `setState(_quickCategoryId = toggled); _applyQuickFilters();`
  - `_onSearchChanged(value)` (~998): debounce 350ms → `setState(_searchText=value); _applyQuickFilters();`
  - `_clearSearch()` (~1006): cancel debounce, clear controller, `setState(_searchText=''); _applyQuickFilters();`
  - `_clearAllQuickFilters()` (~1013): cancel debounce, clear controller, `setState` reset 3 flags, `presenter.getAllRestaurants(islandId)`.
  - `_onIslandChanged(newIslandId)` (~692): setState isla, `getAllMunicipalities`, y `if (filtros activos) _applyQuickFilters(); else getAllRestaurants(newIslandId);`.
- **El payload de `getAllRestaurants` SÍ hidrata `categoriaRestaurantes`**: el mismo endpoint/deserializer (`Restaurant.fromJson`, clave JSON `categoriasRestaurantes`) lo usa `new_home_presenter` (`getAllRestaurants(0, islandId)` + `filterTerraza`/`filterMercados` que hacen `r.categoriaRestaurantes.any(...)`) en producción. → Filtrar por categoría en cliente es seguro.
- Modelo `Restaurant`: `bool open`, `String nombre`, `List<CategoryRestaurant> categoriaRestaurantes` con `CategoryRestaurant.categoriaId` (== id de `ModelCategory`). El chip de categoría usa `c.id` de `ModelCategory` como `_quickCategoryId` → casa con `categoriaId`.
- Empty-state (M8) ya está condicionado a `(state is AllRestaurantMapLoaded || state is RestaurantFilterMap) && restaurants.isEmpty && !isDriving`. Como `restaurants` pasará a ser la lista **ya filtrada en cliente**, el empty-state aparecerá correctamente cuando un filtro deje 0 resultados (estado `AllRestaurantMapLoaded`), y "Quitar filtros" → `_clearAllQuickFilters` restaura la lista completa.

---

CONTRATO FUNCIONAL (sólo M11):

1. **Nuevo helper privado** `_applyClientFilters(List<Restaurant> source)` en `MapSearchState`:
   ```dart
   List<Restaurant> _applyClientFilters(List<Restaurant> source) {
     final q = _searchText.trim().toLowerCase();
     if (!_quickOpen && _quickCategoryId == null && q.isEmpty) return source;
     return source.where((r) {
       if (_quickOpen && !r.open) return false;
       if (_quickCategoryId != null &&
           !r.categoriaRestaurantes
               .any((c) => c.categoriaId == _quickCategoryId)) {
         return false;
       }
       if (q.isNotEmpty && !r.nombre.toLowerCase().contains(q)) return false;
       return true;
     }).toList(growable: false);
   }
   ```

2. **Aplicarlo en el builder**, justo después de derivar `restaurants` del estado y **antes** de `_allRestaurants = restaurants;`:
   ```dart
   } else if (state is RestaurantFilterMap) {
     restaurants = state.filtersRestaurants;
   }
   restaurants = _applyClientFilters(restaurants);   // ← NUEVA línea
   final dataChanged = ...
   ```
   (Así markers + carrusel + empty-state derivan de la lista ya filtrada en cliente.)

3. **Quitar la red de los toggles** (ya no llaman a `_applyQuickFilters`; sólo `setState` → rebuild → `_applyClientFilters` recomputa):
   - `_toggleOpenFilter()` → sólo `setState(() => _quickOpen = !_quickOpen);`
   - `_toggleCategory(id)` → sólo `setState(() => _quickCategoryId = _quickCategoryId == id ? null : id);`
   - `_onSearchChanged(value)` → mantener el debounce de 350ms pero el callback sólo hace `setState(() => _searchText = value);` (sin llamada de red). (El debounce evita rebuilds por cada tecla.)
   - `_clearSearch()` → cancel debounce, `_searchController.clear()`, `setState(() => _searchText = '');` (sin red).
   - `_clearAllQuickFilters()` → cancel debounce, `_searchController.clear()`, `setState` reset `_quickOpen=false; _quickCategoryId=null; _searchText='';`. **Quitar** la llamada `presenter.getAllRestaurants(islandId)` (la lista completa ya está en el cubit; resetear flags basta y el builder re-muestra todo).

4. **`_onIslandChanged(newIslandId)`** → simplificar a recargar SIEMPRE la isla completa (los filtros activos se re-aplican solos en el builder):
   ```dart
   void _onIslandChanged(String newIslandId) {
     if (!mounted) return;
     setState(() => islandId = newIslandId);
     presenter.getAllMunicipalities(newIslandId);
     presenter.getAllRestaurants(newIslandId);
   }
   ```

5. **Eliminar el método `_applyQuickFilters()`** (queda sin usar tras lo anterior → provocaría `unused_element`).

---

NOTA DE COMPORTAMIENTO (intencional, mencionar en informe):
- La **búsqueda** pasa de query difusa del backend a coincidencia **instantánea por nombre** en cliente (`nombre.contains`, case-insensitive). Para un buscador de mapa es UX mejor (instantáneo) y suficiente. El método del cubit `getFilterMapRestaurants` y el estado `RestaurantFilterMap` **se conservan** (no se borran; siguen siendo API pública del cubit) — simplemente el mapa ya no los invoca.

NO MODIFICAR / NO ROMPER:
- El `RestaurantMapCubit`/`RestaurantMapState`/presenter — NO cambiar firmas (sólo dejar de llamar a `getFilterMapRestaurants` desde el mapa).
- `_refreshVisible`, `_sortedByDistance`, `_rebuildMarkers`, la lógica de carrusel/markers/selección — NO tocar (siguen consumiendo `_allRestaurants`, que ahora ya viene filtrado).
- El empty-state (M8) y su botón "Quitar filtros" (sigue llamando a `_clearAllQuickFilters`). Anchors M3, header/scrim M6, padding M7, distance pill M9, sharedHttpClient M10. M1-M10 intactos.
- El modelo, backend, `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M11 **NO** toca: pausa sensores (M12), marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Seguir llamando a `getFilterMapRestaurants`/red en `_toggleOpenFilter`, `_toggleCategory`, `_onSearchChanged`, `_clearSearch`.
- Romper el filtrado por categoría (debe casar `categoriaRestaurantes.categoriaId == _quickCategoryId`).
- Dejar `_applyQuickFilters` sin usar (warning `unused_element`).
- Tocar el cubit/state/presenter (firmas), otros M's, `pubspec.yaml`/`ios/`/`android/`/`main.dart`. Tests de widget que monten `MapSearch`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`); en particular NINGÚN `unused_element`/`unused_method`.
- Confirmar por diff: `_applyClientFilters` añadido y aplicado en el builder antes de `_allRestaurants`; los 4 handlers de filtro/búsqueda sólo hacen `setState` (sin red); `_clearAllQuickFilters` sin `getAllRestaurants`; `_onIslandChanged` recarga siempre la isla; `_applyQuickFilters` eliminado.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Filtros avanzados (municipios/tipos) que el mapa no expone como quick-chips: siguen siendo del backend si alguna vez se cablean.
- Búsqueda difusa por descripción/platos en el mapa: si se quisiera, sería follow-up (hoy el quick-search del mapa es por nombre).

ENTREGA:
1. Diff de `map_search.dart` (filtrado en cliente).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M11.

Diff objetivo ≤ 55 líneas.
