Pulido de diseño de la pantalla **Visitas** (la tab "Visitas" del bottom-nav, que monta **`DiscoverScreen`** — NO `visitas_screen.dart`, que es otra pantalla del usuario). Cinco problemas de producto detectados en revisión de diseño, TODOS cliente-puro, sin tocar backend ni modelo de datos: (V1) **vocabulario de sentimiento incoherente** entre sheet y card; (V2) **redundancia de filtros** (doble entrada al sheet con el mismo icono + sección "Creador" duplica los chips de pantalla); (V4) **eco de la quote** (caption colapsada se repite como primer bloque del expandido); (V5) **faltan anchors a11y** estables y labels en iconos; (V6) **`_islandFilterDisabled` irreversible** (cambiar de isla global tras "Ver todas" ya no re-filtra). Cambios visuales/de lógica de filtrado sin tests de widget: se verifican por **code-review + `flutter analyze`** (regla 5/6 de CLAUDE.md) + suite existente sin nuevos fallos. **NO escribir tests de widget** que monten `DiscoverScreen` (requiere mockear `VisitsCubit`/`NewHomeFiltersCubit`/remote-config/network; rabbit hole).

Ficheros a tocar:
- `lib/ui/pages/discover/discover_screen.dart`
- `lib/ui/pages/discover/widgets/visit_list_tile.dart`
- `lib/ui/pages/discover/widgets/visit_filter_sheet.dart`
- (NUEVO permitido) `lib/ui/pages/discover/visit_sentiment.dart` — única fuente de verdad de label+color de sentimiento (sólo si se elige extraer a helper; ver V1).

---

CONTEXTO ACTUAL (verificado leyendo el código):

**V1 — vocabulario de sentimiento incoherente (label + color duplicados en dos sitios).**
- Sheet (`visit_filter_sheet.dart`): `const Map<String,String> kSentimentLabels` = `muy_positivo:'Muy positivo'`, `positivo:'Positivo'`, `neutro:'Neutro'`, `negativo:'Negativo'`; colores en el método `_sentimentColor(String)` (laurisilva/atlantico/arena/mojo). `kSentimentLabels` lo consume también `_ActiveFiltersBar` en `discover_screen.dart` (`kSentimentLabels[s] ?? s`).
- Card (`visit_list_tile.dart`, `_MetaLine._sentimentChip`): `switch (sentiment)` propio con copy DISTINTO: `muy_positivo→'Muy bueno'`, `positivo→'Bueno'`, `neutro→'Neutro'`, `negativo→'Flojo'` + colores laurisilva/atlantico/arena/mojo. El usuario filtra por "Positivo" y en la card ve "BUENO" → parece otra cosa.

**V2 — redundancia de filtros de creador / doble entrada al sheet.**
- El creador se filtra desde los chips en pantalla (`_CreatorChipsRow`, escribe `_filters.creators` vía `_toggleCreator`) Y desde la sección "Creador" del sheet (`VisitFilterSheet`, `_toggleCreator` interno, sección bajo `if (widget.creators.isNotEmpty)`).
- Al sheet se llega por DOS affordances con el MISMO icono `Icons.tune_rounded`: el `_IconBubble` del `_DiscoverHeader` (`onFilter`) y el chip "Más filtros" al final de `_CreatorChipsRow` (`onMore`). Confunde cuál es cuál.

**V4 — eco de la quote.**
- En `VisitListTile`, collapsed muestra `caption` (`_captionFor` prioriza `extraText` → `quotes.first.text` → `summary` → `highlights.first`), oculta cuando `_expanded`.
- En `_ExpandedBody`, el PRIMER bloque pintado es `_Quote(text: quote)` con `quote = v.quotes.isNotEmpty ? v.quotes.first.text : null`. Si la caption colapsada era esa misma quote (caso muy común), al expandir se repite la misma frase arriba del todo.

**V5 — faltan anchors estables y labels a11y.**
- Sólo existen 2 `Semantics(identifier:)`: `discover-active-island-label` y `discover-show-all-islands-button`. NO hay anchor por card (Listas sí tiene `listas-card-<id>`), ni en search / sort / filtro.
- Los `_IconBubble` (sort, filtro) y el chevron de expandir de la card NO tienen `Semantics(label:)` → un lector de pantalla anuncia "botón" sin nombre.

**V6 — `_islandFilterDisabled` irreversible.**
- Estado `bool _islandFilterDisabled = false`. El CTA "Ver todas las visitas" (`_IslandEmptyState.onShowAll`) hace `setState(() => _islandFilterDisabled = true)` y queda `true` toda la sesión. Si el usuario cambia de isla en el filtro global (`NewHomeFiltersCubit`), el filtro por isla ya NO vuelve a aplicarse aunque la nueva isla sí tenga visitas. `islandKey` es un `String` ('TF','GC',…) disponible en el `build` vía `filtersState.islandKey`.

---

CONTRATO FUNCIONAL:

**V1 — una sola fuente de verdad para sentimiento (label + color):**
- Crear UNA definición canónica de label+color por clave de sentimiento (`muy_positivo|positivo|neutro|negativo`). Recomendado: nuevo fichero `lib/ui/pages/discover/visit_sentiment.dart` exportando p.ej. `kSentimentLabels` (Map<String,String>) y `sentimentColor(String) → Color?` (o un `Map<String,Color>`); o, si se prefiere no crear fichero, centralizar en `visit_filter_sheet.dart` y que la card lo importe. Lo que NO vale: dejar dos copys distintos.
- **Copy canónico** (editorial, gana el de la card): `muy_positivo:'Muy bueno'`, `positivo:'Bueno'`, `neutro:'Neutro'`, `negativo:'Flojo'`. Colores: `muy_positivo→AppColors.laurisilva`, `positivo→AppColors.atlantico`, `neutro→AppColors.arena`, `negativo→AppColors.mojo`.
- El sheet (`_PickerChip` de Sentimiento), el `_ActiveFiltersBar` y la card (`_sentimentChip`) deben TODOS leer de esa fuente única. Resultado: filtrar "Bueno" y ver "BUENO" en la card. La card sigue pintando el label en mayúsculas (`.toUpperCase()`) como hoy; eso es presentación, no copy distinto.

**V2 — colapsar redundancia de filtros (los chips de pantalla mandan para creador):**
- Dejar el `_IconBubble` `tune` del `_DiscoverHeader` como ÚNICA entrada al sheet. **Eliminar el chip "Más filtros"** del final de `_CreatorChipsRow` (y su callback `onMore` / el parámetro asociado si queda sin uso).
- **Eliminar la sección "Creador" del sheet** (`visit_filter_sheet.dart`): el `_SectionTitle('Creador')`, su `Wrap` de `_PickerChip`, el `_toggleCreator` interno del sheet, y el parámetro `creators` del constructor y de `VisitFilterSheet.show(...)`. La fila de chips de creador en pantalla queda como ÚNICA fuente de filtrado por creador. El sheet conserva **Sentimiento**, **Zona** y **Otros (solo con vídeo)**.
- En `discover_screen.dart` `_openFilters(...)`, dejar de pasar `creators:` al sheet. Mantener `_uniqueCreators` (lo usa la fila de chips). El campo `VisitFilterValues.creators` se CONSERVA intacto (lo escriben los chips de pantalla, lo lee `_applyFilters`, lo muestra `_ActiveFiltersBar`).

**V4 — quitar el eco de la quote:**
- Pasar a `_ExpandedBody` la caption colapsada (la que devuelve `_captionFor(v)`), p.ej. nuevo parámetro `collapsedCaption`.
- En `_ExpandedBody`, pintar el bloque `_Quote` SÓLO si `quote != null && quote.isNotEmpty && quote != collapsedCaption`. Así, cuando la caption ya era la quote, no se repite. El resto del expandido (resumen, platos, lo mejor/peor, servicios, CTA) intacto.

**V5 — anchors estables + labels a11y:**
- Anchor por card: envolver cada `VisitListTile` (en el `itemBuilder` de `discover_screen.dart`, igual que Listas con `listas-card-<id>`) en `Semantics(identifier: 'discover-visit-card-${filtered[i].id}', button: true, child: ...)`. NO romper el `onTap` de navegación.
- `Semantics(identifier: 'discover-search-field')` sobre el `_SearchRow` (o su `TextField`).
- Sort e filtro: añadir a cada `_IconBubble` (sort y filtro del header) un `Semantics(identifier:, label:, button: true)`: sort → `identifier:'discover-sort-button'`, `label:'Ordenar visitas'`; filtro → `identifier:'discover-filter-button'`, `label:'Filtrar visitas'`. Puede hacerse envolviendo en el call-site o añadiendo params opcionales a `_IconBubble`.
- Chevron de expandir de la card: `Semantics(button: true, label: _expanded ? 'Plegar' : 'Desplegar', child: ...)`.
- Kebab-case inglés en los `identifier`. Los `label` (de lectura) en español. Nunca usar `label:` como anchor técnico — el anchor es siempre `identifier:`.

**V6 — reaplicar el filtro de isla al cambiar de isla:**
- Sustituir `bool _islandFilterDisabled` por un estado que recuerde PARA QUÉ isla se desactivó: p.ej. `String? _islandFilterDisabledForKey` (null = activo). El filtro por isla se considera desactivado SÓLO si `_islandFilterDisabledForKey == islandKey` (la isla actual del `build`).
- En `onShowAll` del `_IslandEmptyState`, guardar la isla actual: `setState(() => _islandFilterDisabledForKey = islandKey)` (pasar `islandKey` al callback / closure; está disponible en el `build`).
- Donde hoy se lee `_islandFilterDisabled` (cálculo de `islandFilteredVisits` y de `isIslandEmpty`), usar `final islandDisabled = _islandFilterDisabledForKey == islandKey;`. Así, al cambiar de isla, el disable deja de aplicar y se re-filtra automáticamente.

---

NO MODIFICAR:
- La lógica de `_applyFilters`/`_applySort`/`_uniqueCreators`/`_uniqueZones`, el debounce de búsqueda, el `RefreshIndicator`/pull-to-refresh, los estados `_EmptyState`/`_ErrorState`/`_IslandEmptyState` (salvo el cambio puntual de `onShowAll` en V6).
- El modelo `Visit`, `VisitsCubit`, `NewHomeFiltersCubit`, el backend. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- El campo `VisitFilterValues.creators` (se conserva; sólo se quita la SECCIÓN del sheet).
- Las secciones **Sentimiento**, **Zona** y **Otros** del sheet, el badge contador del icono de filtros, el `_DiscoverHeader` título/subtítulo, el `VisitSortSheet`.
- El anchor `discover-active-island-label` y `discover-show-all-islands-button`.

PROHIBIDO (rechazo automático del Evaluator):
- Dejar dos copys/colores de sentimiento distintos (V1 sin resolver) o que el `_ActiveFiltersBar` muestre un label diferente al de la card.
- Dejar el chip "Más filtros" o la sección "Creador" en el sheet (V2 sin resolver).
- Dejar la quote repetida en collapsed+expandido cuando coinciden (V4 sin resolver).
- No añadir `discover-visit-card-<id>` o dejar sort/filtro sin `Semantics`/label (V5 sin resolver). Usar `Semantics(label:)` como anchor técnico en vez de `identifier:`.
- Dejar `_islandFilterDisabled` como bool irreversible (V6 sin resolver).
- Romper la navegación al detalle (`VisitDetailPage(visitId: ...)`) o el toggle expandir/colapsar de la card.
- Tests de widget que monten `DiscoverScreen`; tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` sobre los ficheros tocados: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`). Si se elimina el parámetro `creators` del sheet, confirmar que no queda referencia muerta (`onMore`, imports).
- Confirmar por diff: (V1) una sola definición de label+color leída por sheet+activeBar+card, copy canónico "Muy bueno/Bueno/Neutro/Flojo"; (V2) sin chip "Más filtros", sin sección "Creador" ni param `creators` en el sheet, chips de pantalla intactos; (V4) `_Quote` condicionado a `quote != collapsedCaption`; (V5) `discover-visit-card-<id>` + `discover-search-field` + `discover-sort-button`/`discover-filter-button` + labels en chevron; (V6) `_islandFilterDisabledForKey` por isla.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: los tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente (remote-config/WebViewPlatform/network mocks); NO son regresiones, no arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- **V3** (card con doble acción: tap navega vs chevron expande) — cambio de interacción más opinado, decisión de producto aparte.
- **V7** ("Solo con vídeo" posible no-op si todas las visitas traen vídeo) — depende de datos reales; revisar antes de tocar.
- Reducir la densidad de cromo de la cabecera (6 bandas antes de la primera visita) — follow-up de layout.

ENTREGA:
1. Diff de los ficheros (sentimiento unificado; sheet sin Creador/"Más filtros"; quote sin eco; anchors+labels; filtro isla por-isla).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando V1/V2/V4/V5/V6 por code-review y reconociendo V3/V7 como follow-up.

Diff objetivo ≤ 150 líneas.
