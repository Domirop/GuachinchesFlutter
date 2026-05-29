Propagar la **isla seleccionada en el home hero** (NewHomeFiltersCubit) a las pantallas **Listas** y **Visitas/Discover**, y restringir los **municipios** de cualquier filtro a la isla activa. Hoy el filtro por isla solo aplica al home (tab 0). En tab 1 (Listas) hay un filtro local roto. En tab 3 (Visitas/Discover) no hay filtro de isla.

CONTEXTO ACTUAL (verificado a mano):

- **Single source of truth para isla seleccionada**: `NewHomeFiltersCubit` en `lib/data/cubit/new_home/new_home_filters_cubit.dart`. Estado `NewHomeFiltersState` (`lib/data/cubit/new_home/new_home_filters_state.dart`) contiene `islandId`, `islandKey` (TF/GC/LZ/FV/LP/GO/EH), `islandLabel`. Default = Tenerife `76ac0bec-4bc1-41a5-bc60-e528e0c12f4d`. Mutación vía `selectIsland({id, key, label})`. Ya provided globalmente en `main.dart` → MultiBlocProvider.

- **Lista canónica de islas con id real** disponible en `IslandsCubit` (state `IslandsState` con `islands: List<Island>`). Cada `Island` tiene `id`, `nombre` y opcional `key`. Cuando `key` viene null del backend, hay helper `_islandKeyFromName(name)` en `lib/ui/pages/new_home/new_home_screen.dart:133-149` (TF/GC/LZ/FV/LP/GO/EH). **Reusar ese mapeo — no duplicarlo: extraerlo a `lib/utils/island_key_utils.dart` y reemplazar el inline.**

- **Listas screen** (`lib/ui/pages/listas/listas_screen.dart`):
  * Línea 39: lee `NewHomeFiltersCubit.state.islandId` SOLO en `initState`. No reacciona a cambios posteriores → si el usuario cambia isla en home y luego va a Listas, el filtro queda obsoleto.
  * Líneas 370-378 `_kIslands`: lista hardcoded `[TF, GC, LZ, FV, LP, LG, EH]` donde solo TF tiene id. El resto tiene `id: null` → chips no clicables (línea 399: `onTap: opt.id == null ? null : ...`). **Esto está roto: el usuario ve 7 chips pero solo TF responde.**
  * `_islandIdFilter` es estado local; cuando cambia, llama `setState`. No emite al cubit global.
  * Modelo `CuratedList` ya tiene `String? islandId` (línea 15 de `lib/data/model/curated_list.dart`). Filtrado actual (línea 69-71): `r.where((l) => l.islandId == null || l.islandId == _islandIdFilter)` — listas sin isla aparecen siempre (intencional, son globales).

- **Discover/Visits screen** (`lib/ui/pages/discover/discover_screen.dart`):
  * Usa `VisitsCubit.loadVisits()` (todas las visitas, sin filtro de isla).
  * `Visit.restaurant` (nested) tiene `String? island` con el **nombre** de la isla (NO un id). Restaurant model line 46: `String? island;` y line 237: `island = json["island"]?.toString();`.
  * Filter sheet (`visit_filter_sheet.dart`): soporta `creators`, `sentiments`, `zones`, `onlyWithVideo`. **NO** tiene filtro de isla.
  * Tampoco hay ningún chip de isla visible en la pantalla.

- **Advanced search** (`lib/ui/pages/advance_search/advanced_search.dart`):
  * Recibe `islandId` como param ✓.
  * Recibe `municipalities: List<Municipality>` ya pre-filtrados por el caller.
  * Caller desde `new_home_screen.dart` (línea 391-409): pasa `_municipalitiesOld` cargado vía `repo.getAllMunicipalitiesFiltered(islandId)` en `_loadOldMunicipalities` (línea 122). Se invoca en bootstrap (línea 87) **y** cada vez que cambia la isla en el chip row (línea 371). Esto YA funciona correctamente.
  * Caller desde `lib/ui/pages/home/home.dart` (legacy, líneas 124/318/506/529): verificar que también pasa municipios filtrados. Si no, ajustar para que use el repo filtrado por islandId.

- **Listas filter sheet** (`lib/ui/pages/listas/widgets/listas_filter_sheet.dart`): contiene `islandIds: Set<String>` como filtro multi-select. Hoy ofrece las 7 islas hardcodeadas. **Debe restringirse a la isla activa** (solo mostrar/preseleccionar la actual, o esconder esa sección del sheet — decisión del Planner).

CONTRATO FUNCIONAL:

1. **`lib/utils/island_key_utils.dart` (NUEVO)**:
   - Mover el helper `islandKeyFromName(String name)` desde `new_home_screen.dart`.
   - Añadir `islandNameFromKey(String key)` (inversa, devuelve "Tenerife", "Gran Canaria", etc.) — la usaremos para filtrar Visits por nombre.
   - Lista canónica de las 7 islas como `const kCanonicalIslandKeys = ['TF','GC','LZ','FV','LP','GO','EH']`.
   - Reemplazar el inline de `new_home_screen.dart:133-149` por import de este util.

2. **`Listas screen` (`lib/ui/pages/listas/listas_screen.dart`) — sincronizar con NewHomeFiltersCubit**:
   - Envolver el body en `BlocListener<NewHomeFiltersCubit, NewHomeFiltersState>` que reaccione a cambios de `islandId`:
     ```dart
     listener: (ctx, state) {
       if (state.islandId != _islandIdFilter) {
         setState(() => _islandIdFilter = state.islandId);
       }
     }
     ```
   - **Eliminar la lista hardcoded `_kIslands`** y reemplazar `_IslandFilterRow` por una versión que lea `IslandsCubit` (vía BlocBuilder) y use ids reales. Cuando el usuario tap un chip → `context.read<NewHomeFiltersCubit>().selectIsland(id: ..., key: ..., label: ...)`. Esto propaga el cambio al home (consistencia bidireccional).
   - El chip activo se calcula desde `NewHomeFiltersCubit.state.islandId`, no desde `_islandIdFilter` local.
   - `_islandIdFilter` puede mantenerse como caché local para el filtro de la lista de `CuratedList`, pero debe quedar always-synced con el cubit.

3. **Listas filter sheet** (`listas_filter_sheet.dart`):
   - El campo `islandIds: Set<String>` ya no aplica en su forma actual (multi-select de las 7 islas).
   - Opción A (recomendada): **eliminar esa sección del sheet** — la isla se elige desde el chip row, no desde el sheet.
   - Opción B: mantener el sheet pero con un solo chip preseleccionado (read-only) que indica "Filtrando por: {islandLabel}". Tap → cierra sheet y permite cambiar arriba.
   - Decidir Planner. Si va Opción A, ajustar `ListasFilterValues` para quitar `islandIds` y todos sus usos.

4. **Discover/Visits screen** (`lib/ui/pages/discover/discover_screen.dart`) — añadir filtro por isla**:
   - Suscribir vía `BlocBuilder<NewHomeFiltersCubit, NewHomeFiltersState>` para obtener `islandLabel` y `islandKey` actuales.
   - En el pipeline de filtrado (`_applyFilters` / equivalente), añadir:
     ```dart
     final activeIslandName = islandNameFromKey(state.islandKey); // p.ej. "La Gomera"
     filtered = filtered.where((v) {
       final ri = v.restaurant?.island?.trim();
       if (ri == null || ri.isEmpty) return false; // visitas sin isla → fuera
       // Comparación tolerante: case-insensitive y permitir "Gomera" ≈ "La Gomera"
       return _matchesIslandName(ri, activeIslandName);
     }).toList();
     ```
   - Helper `_matchesIslandName(String visitIsland, String activeName)`: lowercase, trim, también acepta el match si visitIsland contiene activeName (sin el artículo "La/El"). Esto cubre payloads inconsistentes del backend.
   - Mostrar en el header (eyebrow) "{islandLabel.toUpperCase()}" para que el usuario sepa por qué se filtra.
   - Anchor `discover-active-island-label` en el chip/eyebrow.

5. **Discover empty state**:
   - Si tras filtrar por isla quedan 0 visitas, mostrar empty state: "Aún no hay visitas en {islandLabel}" + CTA "Ver todas las visitas" que abre el sheet y desactiva temporalmente el filtro de isla (modo "ver fuera de tu isla"). Anchor del CTA: `discover-show-all-islands-button`.

6. **`new_home_screen.dart`** — refactor mínimo:
   - Reemplazar el inline `_islandKeyFromName` por el import del nuevo util.
   - No cambiar nada más visual aquí.

7. **`home.dart` legacy** (`lib/ui/pages/home/home.dart`):
   - Comprobar que los 4 `AdvancedSearch(...)` (líneas 124, 318, 506, 529) reciben municipios YA filtrados por isla.
   - Si no, hacer cambio mínimo para usar `repo.getAllMunicipalitiesFiltered(islandId)` (el mismo método que ya usa `new_home_screen`).
   - **Si esa pantalla está deprecada y no se monta**, dejar TODO y mencionar en informe.

8. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/`.
   - Backend ni endpoints (filtrado client-side basta para Visits/Lists).
   - Tab Mapa (no es scope: mapa ya filtra geográficamente).
   - `IslandsCubit`, `IslandsState`, ni el modelo `Island`.
   - El picker de islas del hero (`island_picker_sheet.dart`) — ya emite a NewHomeFiltersCubit, que es la fuente de verdad.

TESTS OBLIGATORIOS:

- **Unit** `test/utils/island_key_utils_test.dart`:
  * `islandKeyFromName('Tenerife') == 'TF'`, todos los 7 casos.
  * `islandKeyFromName('TENERIFE  ') == 'TF'` (tolerante a case + trim).
  * `islandKeyFromName('Mordor') == ''` (o el default que use el código actual).
  * `islandNameFromKey('GO') == 'La Gomera'`, ida-vuelta para los 7.

- **Widget** `test/ui/pages/listas/listas_screen_island_sync_test.dart`:
  * Montar `ListasScreen` con `NewHomeFiltersCubit` y `CuratedListsCubit` provided (mocks).
  * Cargar 3 listas (1 sin islandId, 1 con islandId=TF, 1 con islandId=GC).
  * Estado inicial cubit = TF → ver solo "sin isla" + "TF" (la GC oculta).
  * Llamar `cubit.selectIsland(id: 'gc-id', key: 'GC', label: 'Gran Canaria')`.
  * Re-pump → ver solo "sin isla" + "GC" (la TF oculta).
  * Confirma que el filtro local del screen se re-sincroniza tras un cambio de isla externa.

- **Widget** `test/ui/pages/discover/discover_island_filter_test.dart`:
  * Montar `DiscoverScreen` con `NewHomeFiltersCubit`, `VisitsCubit` provided con 3 Visits (restaurantes en Tenerife, Gran Canaria, La Gomera).
  * Estado inicial = TF → ver 1 visita.
  * Cambiar a GC → ver 1 visita.
  * Cambiar a La Gomera → ver 1 visita.
  * Verificar anchor `discover-active-island-label` muestra el `islandLabel`.

- **Widget** `test/ui/pages/discover/discover_empty_state_test.dart`:
  * Visits con todas en Tenerife, cubit en La Gomera → renderiza empty state + anchor `discover-show-all-islands-button`.

PROHIBIDO (rechazo automático del Evaluator):

- Crear un nuevo cubit para selección de isla — usar `NewHomeFiltersCubit`.
- Duplicar el helper `islandKeyFromName` en más de un sitio (extraer a util).
- Hardcoded list de islas con `id: null` en cualquier UI (debe venir de `IslandsCubit`).
- Llamadas extra al backend desde Listas o Discover (filtrado client-side).
- Cambiar el comportamiento del home (tab 0) — solo lectura del cubit, sin tocar su funcionamiento actual.
- Romper `AdvancedSearch` (ya funciona; solo verificar y ajustar `home.dart` si hace falta).
- Tocar `pubspec.yaml`, `ios/`, `android/`.
- `Semantics(label: ...)` como anchor técnico — siempre `Semantics(identifier: ...)` en kebab-case inglés.

OUT OF SCOPE (mencionar en informe del Evaluator):

- Filtro de isla en el mapa (ya tiene su propio sistema geográfico).
- Persistir la isla seleccionada en disco (lo hace ya el bootstrap del cubit si aplica — fuera de scope).
- Migración de `home.dart` legacy a `new_home_screen.dart` (fuera de scope; solo ajuste defensivo si hace falta para no romper la pantalla).
- Reactivar `app_links` para deeplinks con isla preseleccionada.
- I18n del label "Filtrando por: {island}" — copy en castellano OK por ahora.

ENTREGA:

1. Diff con:
   - 1 util nuevo (`lib/utils/island_key_utils.dart`).
   - Refactor de `listas_screen.dart` (sync con cubit, eliminar `_kIslands` hardcoded).
   - Refactor de `discover_screen.dart` (añadir filtro de isla + empty state).
   - Ajuste mínimo en `listas_filter_sheet.dart` (Opción A: eliminar islandIds; Opción B: read-only).
   - Refactor mínimo en `new_home_screen.dart` (import del util).
   - Ajuste defensivo en `home.dart` legacy si los 4 `AdvancedSearch(...)` no pasan municipios filtrados.
   - 4 ficheros de test (unit util + 3 widget).
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/utils/island_key_utils_test.dart test/ui/pages/listas/ test/ui/pages/discover/` debe pasar al 100%.
4. Informe del Evaluator debe confirmar:
   - Cambiar isla en home se refleja en Listas y Visitas inmediatamente.
   - Cambiar isla en Listas se refleja en home (consistencia bidireccional).
   - Municipios en filtros de búsqueda son siempre los de la isla activa.
   - No queda ninguna lista hardcoded de 7 islas con `id: null` en la UI.
   - Las visitas se filtran por `Restaurant.island` (nombre) con match tolerante.
   - El empty state de Discover guía al usuario cuando no hay visitas en su isla.

Este sprint debe leerse en review en ≤ 20 min. Si el diff crece > 700 líneas (incl. tests), el Generator debe priorizar Listas + Discover y dejar el refactor de `home.dart` legacy + el `listas_filter_sheet.dart` Opción A para un segundo PR (mencionar en informe).
