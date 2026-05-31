Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M2 (de la serie M1…M13, uno por harness)**: convertir el **chip de isla del header** (hoy una afordancia MUERTA — está estilado como botón con borde azul y texto en negrita pero NO tiene `onTap`) en un **selector real** que abre el `IslandPickerSheet` ya existente para cambiar de isla desde el propio mapa. Cliente-puro, sin tocar backend ni modelo. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO escribir tests de widget** que monten `MapSearch` (rabbit hole: GoogleMap platform-view, cubits, presenter, geolocator, remote-config).

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

- M1 (ya commiteado) hizo que el mapa lea la isla del `NewHomeFiltersCubit` y dejó un `BlocListener<NewHomeFiltersCubit,NewHomeFiltersState>` (en `_buildScaffold` → método `_onIslandChanged`) que **recarga el mapa cuando `islandId` cambia**. Por tanto, M2 NO necesita cablear recarga: basta con disparar `selectIsland(...)` en el cubit y el mapa reacciona solo.
- El chip vive en `_MapHeader.build` (~líneas 2118-2137): un `Container` con `border` azul (`GlobalMethods.blueColor`) y `Text(municipalityLabel)`. **No está envuelto en ningún gesture** → tap muerto. `municipalityLabel` ya llega como `filtersState.islandLabel.toUpperCase()` (M1).
- Existe un bottom-sheet reusable: `IslandPickerSheet.show({required BuildContext context, required String selectedIslandId, required ValueChanged<Island> onSelect})` en `lib/ui/pages/new_home/sheets/island_picker_sheet.dart`. Carga las islas vía `IslandsCubit` (provisto a nivel app en `main.dart`, disponible en el contexto de `MapSearch`).
- Patrón canónico de `onSelect` (copiado de `new_home_screen.dart` ~líneas 331-342):
  ```dart
  onSelect: (island) {
    final key = (island.key != null && island.key!.isNotEmpty)
        ? island.key!
        : islandKeyFromName(island.name);
    context.read<NewHomeFiltersCubit>().selectIsland(
          id: island.id,
          key: key,
          label: island.name,
        );
  }
  ```
  `islandKeyFromName` vive en `lib/.../island_key_utils.dart` (mismo helper que usa el home). `Island` model: `lib/data/model/Island.dart`.
- `NewHomeFiltersCubit.selectIsland(...)` emite nuevo `islandId` → el `BlocListener` de M1 recarga el mapa (restaurantes + municipios + re-aplica quick-filters). Cero trabajo extra de recarga en M2.

---

CONTRATO FUNCIONAL (sólo M2):

1. **Chip tappable:** envolver el `Container` del chip de isla en un gesture (`InkWell`/`GestureDetector`) cuyo `onTap` abra `IslandPickerSheet.show(...)` con:
   - `selectedIslandId: context.read<NewHomeFiltersCubit>().state.islandId`,
   - `onSelect:` el patrón canónico de arriba (deriva `key`, llama `selectIsland`).
   - El `BuildContext` pasado a `show(...)` debe ser uno que vea `IslandsCubit` + `NewHomeFiltersCubit` (el de `MapSearchState` sirve; ambos providers están por encima del tab scaffold).
   - Patrón recomendado: añadir `final VoidCallback onIslandTap;` a `_MapHeader` y, en `_buildScaffold` de `MapSearchState`, pasar `onIslandTap: () => _showIslandSheet(context)`, con un método privado nuevo `_showIslandSheet(BuildContext context)` en el State que invoque `IslandPickerSheet.show(...)`. Así el sheet se monta con el contexto correcto (providers visibles) y reusa toda la lógica existente.

2. **Afordancia visual de "desplegable":** añadir un caret (`Icon(Icons.expand_more, size: 16, color: GlobalMethods.blueColor)`) dentro del chip, a la derecha del label, para que se lea como selector y no como etiqueta estática. Mantener el estilo azul actual del chip (el unificar el azul GlobalMethods→AppColors es **M4**, NO lo toques aquí).

3. **Anchor del nuevo control interactivo:** como el chip pasa a ser interactivo, envolverlo en `Semantics(identifier: 'mapa-island-chip', button: true, label: 'Cambiar de isla', child: ...)` (kebab-case inglés para el identifier; label en español para el lector de pantalla). Éste es el ÚNICO anchor que añade M2 (el resto de anchors del header — search field, quick pills — son **M3**).

---

NO MODIFICAR / NO ROMPER:
- El `BlocListener`/`_onIslandChanged` de M1, la carga inicial, ni la fuente de la isla (sigue siendo el cubit).
- La lógica de markers, carrusel, `_refreshVisible`, detección de conducción, cámara chase, defer-mount del GoogleMap, FABs, quick-pills (`_QuickPill`), search bar.
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- NO reescribir `IslandPickerSheet` (reusarlo tal cual).
- M2 **NO** toca: el doble azul GlobalMethods/AppColors (M4), el resto de anchors/a11y (M3), modo coche dual-theme (M5), scrim (M6), ni ningún otro M.

PROHIBIDO (rechazo automático del Evaluator):
- Dejar el chip de isla sin `onTap` (M2 sin resolver).
- Duplicar un picker de isla nuevo en vez de reusar `IslandPickerSheet`.
- Cablear una recarga del mapa manual en `onSelect` (ya lo hace el listener de M1 — sería doble fetch).
- Cambiar `GlobalMethods.blueColor` por `AppColors` aquí (eso es M4).
- Tocar otros M's en este diff. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: el chip tiene gesture→`IslandPickerSheet.show`; `onSelect` llama `selectIsland` con `id/key/label`; hay caret `expand_more`; el chip está envuelto en `Semantics(identifier:'mapa-island-chip', button:true, label:'Cambiar de isla')`; no hay recarga manual añadida en `onSelect`.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente (remote-config/WebViewPlatform/network mocks); NO son regresiones, no arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- Reencuadre de cámara a la nueva isla con coordenadas dedicadas: follow-up (no inventar coords por isla).
- Resto de anchors/a11y del header: M3.

ENTREGA:
1. Diff de `map_search.dart` (chip tappable → `IslandPickerSheet`, caret, anchor).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M2.

Diff objetivo ≤ 60 líneas.
