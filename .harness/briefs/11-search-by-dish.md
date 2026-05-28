Extender la búsqueda de la app para que **encuentre restaurantes por nombre de plato** cuando ese plato aparece asociado a una `Visit` (vídeo/reseña de Jonay & Joana). Hoy "Buscar restaurante…" sólo machea contra `restaurant.nombre` server-side → si el usuario escribe `carne cabra` no aparece "Casa Efigenia" aunque Jonay & Joana tengan visita con `VisitDish(name: "Carne de cabra")`.

CONTEXTO ACTUAL (verificado a mano):

- **Search UI**:
  * `lib/ui/pages/new_home/widgets/search_field_dynamic.dart` — lure en la home (sólo visual), navega a AdvancedSearch.
  * `lib/ui/pages/advance_search/advanced_search.dart:121-128` — `_runSearch()` llama `_restaurantsCubit.getFilterRestaurantsAdvance(text: _searchController.text, …)`.
  * `_onQueryChanged` (línea 131) debouncea con `_searchDebouncer` y reejecuta `_runSearch`.

- **Endpoint actual**:
  * `lib/data/HttpRemoteRepository.dart:166` → `getFilterRestaurants(...)`: `GET /restaurant/findByFilter/filter?name=<text>&…&island=<id>`. El backend matchea sólo el campo `nombre` del restaurante. **No hay endpoint server-side por plato.**

- **Modelo Visit** (ya cargado en cliente):
  * `lib/data/model/Visit.dart:60` — `Visit { id, restaurantId, dishes: List<VisitDish>, highlights: List<String>, name, summary, ... }`.
  * `VisitDish { name, description, sentiment, isTop }` (línea 3).
  * **VisitsCubit** (`lib/data/cubit/new_home/visits_cubit.dart`) cargado globalmente en `main.dart:227` vía `getAllVisits()` → endpoint `video-ingestion/restaurant-videos/published`. Cache SWR ya activa. Estado `VisitsLoaded(List<Visit> visits)`.
  * Usado ya en `discover_screen.dart:222` (BlocBuilder funciona).

- **Modelo Restaurant**:
  * Cada Visit tiene `restaurantId` pero el objeto `restaurant` puede venir o no en el payload (es opcional, ver Visit.dart:72). Cuando viene es un Restaurant completo.

- **RestaurantCubit emite `RestaurantFilterAdvanced(restaurants)`** que `advanced_search.dart` consume vía `BlocBuilder` (líneas posteriores) para pintar resultados.

OBJETIVO: Que escribir un término asociado a un plato (`carne cabra`, `papas arrugadas`, `gofio`, `cochino negro`…) en el buscador devuelva tanto los matches por nombre de restaurante (comportamiento actual) **como** los restaurantes cuyas visitas contienen ese plato. Debe ser **fast (≤ frame), sin red extra**, y **debe distinguirse visualmente** qué resultados vienen de un match por plato.

CONTRATO FUNCIONAL:

1. **Nuevo utility** `lib/utils/dish_search_index.dart`:
   - Función pura `Map<String, Set<String>> buildDishIndex(List<Visit> visits)` que devuelve un mapa `normalized-token → Set<restaurantId>`.
   - **Normalización** (helper privado `_normalize(String s) → String`): lowercase, sin acentos (`á→a`, `ñ→n`, …), trim, colapso de espacios. Documentar la regla en el doc-comment.
   - Para cada `Visit v` y cada `VisitDish d in v.dishes`: tokenizar `d.name` por espacios; cada token (longitud ≥ 3 tras normalizar) se añade al mapa apuntando a `v.restaurantId`. Ej. `"Carne de cabra"` → tokens `["carne", "cabra"]` (el `de` se ignora por longitud).
   - Función `Set<String> matchRestaurantIds(Map<String,Set<String>> index, String query)`:
     * Si `query.trim().length < 3` → devuelve `{}`.
     * Tokeniza la query igual que arriba.
     * Devuelve la **intersección** de los sets de cada token (matches que cumplen TODOS los tokens). Si la intersección queda vacía, **fallback a la unión** sólo si la query tiene ≥ 2 tokens (eso captura "carne cabra" cuando uno de los dos tokens no está indexado pero el otro sí).
   - Tests unitarios obligatorios en `test/utils/dish_search_index_test.dart` cubriendo: normalización con acentos, query corta, intersección, fallback a unión, query vacía, visita sin dishes.

2. **Cubit nuevo `lib/data/cubit/search/dish_search_cubit.dart`**:
   - Estados: `DishSearchIdle`, `DishSearchReady(Map<String,Set<String>>)`, `DishSearchEmpty` (sin visitas o sin platos indexables).
   - Constructor recibe `VisitsCubit visitsCubit`. **Se suscribe** vía `visitsCubit.stream.listen(...)` y al recibir `VisitsLoaded` ejecuta `buildDishIndex` en un microtask (no en un Isolate — el set de platos es pequeño; sí en `compute` si > 200 visitas, pero eso es futuro).
   - Si al construir el cubit el visitsCubit YA está en `VisitsLoaded`, computar el índice de inmediato (no esperar a un evento nuevo).
   - Registrar el cubit en `main.dart` junto al resto de providers, ANTES de los screens que lo consumen.

3. **Integrar en `advanced_search.dart`**:
   - Inyectar `DishSearchCubit` via `context.read<DishSearchCubit>()`.
   - Modificar `_runSearch()`:
     ```
     final query = _searchController.text;
     // a) llamar al backend igual que ahora (no se rompe la búsqueda existente)
     _restaurantsCubit.getFilterRestaurantsAdvance(text: query, …);
     // b) calcular IDs de match por plato (sin red)
     final dishState = context.read<DishSearchCubit>().state;
     final dishMatchIds = dishState is DishSearchReady
         ? matchRestaurantIds(dishState.index, query)
         : <String>{};
     setState(() => _dishMatchIds = dishMatchIds);
     ```
   - En el render de la lista (donde se itera `state.restaurants` del `RestaurantFilterAdvanced`):
     * **Unir** server-side results con los restaurantes del cubit principal cuyos id estén en `_dishMatchIds` y NO estén ya en server-side. Para los nuevos, usar los `Restaurant` que vengan embebidos en `Visit.restaurant` cuando exista. Si no existe (restaurant no embebido), descartar **silenciosamente** ese id (no inventar fetchs extra — se documenta como limitación conocida).
     * Ordenar: primero los server-side, después los dish-matches no overlapping (ordenados por nombre).
     * En cada card de resultado, si el id está en `_dishMatchIds`, mostrar un **chip pequeño** `🍽 «<plato matcheado>»` debajo del municipio. El plato a mostrar es el primer dish de la primera visita cuyo nombre normalizado contiene algún token de la query.
   - Anchors nuevos:
     * `advanced-search-input` en el `TextField` raíz.
     * `advanced-search-results-list` en el ListView de resultados.
     * `advanced-search-dish-chip-<restaurantId>` por card que sea dish-match (el id se incrusta para localización en tests).
     * `advanced-search-empty-dish-hint` en el empty state — un Text bajo "Sin resultados" que sugiera "Prueba: carne de cabra, papas arrugadas, gofio…" SI el query no matchea ni server-side ni por plato, Y el índice de platos está cargado y no vacío.

4. **Loading state**:
   - Si el usuario escribe ANTES de que `VisitsCubit` cargue (`VisitsLoading` o `VisitsInitial`), el dish search se comporta como hoy (sólo server-side). No bloquear la búsqueda esperando visitas.
   - Cuando `VisitsLoaded` llega y hay un query activo, **NO** re-disparar la búsqueda automáticamente (eso causaría flicker). El usuario pulsa enter o cambia el query → se aplica el índice ya completo.

5. **Telemetría** (con `firebase_analytics`, ya en deps):
   ```dart
   FirebaseAnalytics.instance.logEvent(name: 'search_dish_match', parameters: {
     'query_len': query.length,
     'server_count': serverResults.length,
     'dish_count': dishMatchIds.length,
     'dish_only_count': dishOnlyAdded.length, // los que añadimos
   });
   ```
   Sólo emitir si `query.length >= 3` para no spammear con cada keystroke.

6. **NO modificar**:
   - El endpoint `findByFilter` (server-side stays).
   - El `RestaurantCubit` interno (sólo se consume).
   - El comportamiento de "búsquedas recientes" (`_addRecent`).
   - Ningún sprint anterior (offline, i18n, settings, etc.).

TESTS OBLIGATORIOS:

- **Unit** (`test/utils/dish_search_index_test.dart`):
  * Normalización: `"Carne de Cabra á"` → tokens `["carne", "cabra"]`.
  * Visita sin dishes → no aporta al índice.
  * Query corta (`"ca"`) → `matchRestaurantIds` devuelve set vacío.
  * Intersección: visita A con `["carne","cabra"]`, visita B con `["carne","cerdo"]`. Query `"carne cabra"` → sólo A.
  * Fallback unión cuando intersección vacía: visita A con `["carne"]`, visita B con `["cabra"]`. Query `"carne cabra"` → ambas.
  * Query con acentos: `"papás"` matchea visita con dish `"Papas arrugadas"`.

- **Widget** (`test/ui/pages/advance_search/dish_search_integration_test.dart`):
  * Stub `VisitsCubit` con un `Visit` que tenga `VisitDish(name: "Carne de cabra")` y restaurant embebido.
  * Stub `RestaurantCubit` con `RestaurantFilterAdvanced([])` (server-side devuelve vacío).
  * Escribir `"carne cabra"` en `advanced-search-input`. Esperar debounce.
  * Verificar que aparece la card con el id del restaurante de la visita y que existe el anchor `advanced-search-dish-chip-<id>`.
  * Verificar el chip `🍽 «Carne de cabra»` visible.

- **Patrol integration** (`integration_test/search_by_dish_patrol_test.dart`) — sólo si Patrol ya está añadido por otro sprint; si no, OMITIR e indicar en el informe del Evaluator:
  * Arrancar app → tap en `tab-explora` → tap en search lure → escribir `"carne cabra"` → verificar al menos un resultado con anchor `advanced-search-dish-chip-`.

PROHIBIDO:

- Pegar al backend para descubrir platos. La fuente única es la visita cargada en cliente vía `VisitsCubit`.
- Añadir caché propia para dishes — `VisitsCubit` ya usa SWR.
- Cargar `Restaurant` extra por red para los dish-matches que no traen `restaurant` embebido (se descartan en silencio; no es regresión porque el comportamiento previo era "nada"). Generator debe documentar esto en el commit.
- Modificar `pubspec.yaml`, `ios/`, `android/` — no hace falta dep nueva.
- Strings hardcoded en presentación de plato — el formato `🍽 «<plato>»` puede ir hardcoded UNA vez con un TODO de i18n al final del fichero (i18n base ya existe del sprint #7).
- `Semantics(label:)` como anchor — sólo `Semantics(identifier:)`.

OUT OF SCOPE (no lo hagas en este sprint, pero menciona en el informe del Evaluator):

- Search server-side por dish: requiere coordination doc para backend (`migration-backend/027-restaurant-search-by-dish.md`). El Evaluator debe **mencionar** que esto es la siguiente milestone para no tener limitación cuando se carguen platos sin visita embebida.
- Búsqueda por menus (`Restaurant.menus[].plato` ya existe en el modelo) — overlaps pero está fuera; se ataca cuando exista endpoint server-side.
- Autocomplete dropdown de platos populares — futuro.

ENTREGA:

1. Diff con: nuevo utility + tests, nuevo cubit, integración en advanced_search, anchors, registro en main.dart, eventos analytics.
2. `flutter analyze` debe quedar limpio sobre los ficheros nuevos/tocados (warnings preexistentes ajenos OK).
3. `flutter test test/utils/dish_search_index_test.dart` y el widget test deben pasar al 100%.
4. En el informe del Evaluator: confirmar que (a) la búsqueda existente sigue funcionando (probar query `"bodegon"` sin tocar índice de dishes), (b) no hay flicker al cargar VisitsCubit con query activo, (c) limitación documentada de los restaurants sin `restaurant` embebido en la visita.

Este es un cambio que un senior debe poder reviewar en 10 minutos. Si el diff crece más de ~400 líneas nuevas + tests, simplifica.
