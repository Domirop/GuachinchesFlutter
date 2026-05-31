Pulido de diseño de la pantalla **Listas** (`lib/ui/pages/listas/listas_screen.dart` + su sheet de filtros). Tres problemas de producto detectados en revisión de diseño, todos cliente-puro, sin tocar backend ni modelo de datos: (P2) **numeral grande ambiguo** (parece ranking, es recuento de sitios), (P3) **filtro de autor duplicado** (chips de la pantalla + sección AUTOR del sheet hacen lo mismo y pueden contradecirse), (P4) **controles muertos** (icono de vista que no hace nada + filtro "Guardadas" permanentemente vacío). Cambios visuales/de lógica de filtrado sin tests de widget: se verifican por **code-review + `flutter analyze`** (regla 5/6 de CLAUDE.md) + suite existente sin nuevos fallos. **NO escribir tests de widget** que monten `ListasScreen` (requiere mockear `CuratedListsCubit`/`IslandsCubit`/`NewHomeFiltersCubit`/remote-config; rabbit hole).

CONTEXTO: La pantalla ya se unificó en un commit previo — TODAS las listas se renderizan con `_FeaturedListCard` (card grande full-width de 220px) apiladas en un `SliverList`; ya NO existe `_GridListCard`. La badge "DESTACADA" sólo aparece en la primera card (`showFeaturedBadge: i == 0`). Cada card ya tiene anchor `listas-card-<id>`. Este sprint NO toca esa unificación; sólo pule lo de abajo.

Ficheros: `lib/ui/pages/listas/listas_screen.dart`, `lib/ui/pages/listas/widgets/listas_filter_sheet.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**P2 — numeral grande lee como ranking, es `count` (nº de sitios).**
- En `_FeaturedListCard`, la `Row` de badges (arriba) pinta a la derecha un `Text('${list.count}', style: AppTextStyles.displayHero(size: 64, ...))`. Sin etiqueta, un "2" gigante se lee como puesto #2 (ranking), no como "2 sitios".
- El pie editorial repite el dato: `Text('Nº ${list.position} · ${list.count} sitios', ...)`. O sea hay DOBLE aparición del count (gigante sin etiqueta + en el pie) y además se mezcla con `position` ("Nº X"), confundiendo recuento con orden editorial.

**P3 — filtro de autor duplicado y potencialmente contradictorio.**
- Pantalla: `_AuthorFilterRow` con chips `Todas / Guardadas / Jonay / Joana` (enum `_AuthorFilter`, estado `_author`). En `_applyFilters`, los casos `jonay`/`joana` filtran por `l.eyebrow.toUpperCase().contains('JONAY'|'JOANA')`.
- Sheet (`listas_filter_sheet.dart`): sección "AUTOR" con multiselección `Jonay/Joana` (`ListasFilterValues.authors`, constante `_kAuthors`, `_toggleAuthor`). En `_applyFilters` se aplica además el bloque `if (_sheetFilters.authors.isNotEmpty) { r = r.where(... up.contains(a)) }`.
- Ambos filtran el MISMO campo (`eyebrow`) y se combinan con AND: seleccionar chip "Jonay" + sheet "Joana" → AND → lista vacía. Redundante y contradictorio.

**P4 — controles muertos.**
- `_Header` pinta `_RoundIconButton(icon: Icons.view_agenda_outlined, onTap: () {})` — `onTap` vacío, no hace nada. Además, tras unificar las cards a un único formato, un toggle de vista (grid/lista) ya no tiene sentido. La clase `_RoundIconButton` sólo se usa aquí.
- El chip "Guardadas" (`_AuthorFilter.guardadas`) siempre devuelve `const []` en `_applyFilters` (caso `guardadas: r = const []`). No hay persistencia de guardadas ni acción de guardar (el bookmark decorativo se eliminó al quitar `_GridListCard`). Es un filtro que NUNCA puede tener contenido.

---

CONTRATO FUNCIONAL:

**1. P2 — desambiguar el numeral (count ≠ ranking):**
- Mantener el numeral grande como gancho visual PERO etiquetarlo inequívocamente como recuento: debajo (o pegado) del `Text('${list.count}', displayHero 64)` añadir un micro-label `'SITIOS'` (o `'sitios'`) con `AppTextStyles.eyebrow(size: 9/10, color: Colors.white.withOpacity(0.8))`, alineado a la derecha, de modo que se lea "N · SITIOS". Envolver numeral + label en una `Column(crossAxisAlignment: end, mainAxisSize: min)` dentro de la `Row` de badges (en lugar del `Text` suelto).
- Quitar la redundancia del pie: cambiar `'Nº ${list.position} · ${list.count} sitios'` por sólo `'Nº ${list.position}'` (el count ya queda claro en el numeral etiquetado). Mantener el resto del pie (título 24px, subtítulo) igual.
- Si `list.count == 0`, no pintar el numeral ni el label (igual que hoy: el numeral está bajo `if (list.count > 0)`).

**2. P3 — un único filtro de autor (la fila de chips manda):**
- Eliminar la sección "AUTOR" del sheet `listas_filter_sheet.dart`: el `_SheetSectionLabel('AUTOR')`, el `Wrap` de autores y el `SizedBox` siguiente; la constante `_kAuthors`; el método `_toggleAuthor`.
- Eliminar el campo `authors` de `ListasFilterValues` (y de su `count` getter y de `copyWith`). El sheet queda con `featuredOnly` + `minCount`.
- En `listas_screen.dart` `_applyFilters`, eliminar el bloque `if (_sheetFilters.authors.isNotEmpty) { ... }`.
- Mantener intactas las secciones "DESTACADAS" (`featuredOnly`) y "TAMAÑO" (`minCount`) del sheet, y el badge contador del icono de filtros (su `count` ahora cuenta sólo featuredOnly + minCount).
- La fila de chips de autor de la pantalla (`_AuthorFilterRow`) queda como ÚNICA fuente de filtrado por autor.

**3. P4 — quitar controles muertos:**
- Eliminar de `_Header` el `_RoundIconButton(icon: Icons.view_agenda_outlined, onTap: () {})` y el `SizedBox(width: 8)` adyacente. Eliminar la clase `_RoundIconButton` entera (queda sin usar). Conservar el `_FilterIconButton` (sí funciona).
- Eliminar el chip "Guardadas" de `_AuthorFilterRow._items` (la tupla `(_AuthorFilter.guardadas, 'Guardadas')`), porque sin persistencia nunca tiene contenido. **Conservar** el valor `_AuthorFilter.guardadas` del enum y su rama en `_applyFilters` y en `_EmptyState` (no romper el switch); sólo se quita de la fila visible. (Re-introducir "Guardadas" cuando exista persistencia de guardadas — follow-up, ver OUT OF SCOPE.)

---

NO MODIFICAR:
- La unificación de cards (todas con `_FeaturedListCard` grande), el `SliverList`, los anchors `listas-card-<id>`, ni la badge `DESTACADA` en la primera.
- El modelo `CuratedList` ni el backend. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- Los anchors de islas `listas-island-chip-*`, el pull-to-refresh, los empty states, el theming `context.brand.*`.
- Las secciones "DESTACADAS"/"TAMAÑO" del sheet ni el badge contador del icono de filtros.

PROHIBIDO (rechazo automático del Evaluator):
- Tocar la unificación de tarjetas o reintroducir el grid de 2 columnas / `_GridListCard`.
- Dejar el numeral grande sin etiqueta de "sitios" (P2 sin resolver) o dejar el doble conteo en el pie.
- Dejar la sección AUTOR en el sheet o el bloque `_sheetFilters.authors` en `_applyFilters` (P3 sin resolver).
- Dejar el icono de vista muerto (`onTap: () {}`) o el chip "Guardadas" en la fila (P4 sin resolver).
- Romper el switch de `_AuthorFilter` (el enum y sus ramas en `_applyFilters`/`_EmptyState` se conservan).
- Tests de widget que monten `ListasScreen`; tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` sobre los 2 ficheros: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: (P2) numeral con label "sitios" + pie sin el `· count sitios`; (P3) sheet sin AUTOR, `ListasFilterValues` sin `authors`, `_applyFilters` sin el bloque authors; (P4) sin `_RoundIconButton`/icono de vista y sin chip "Guardadas" en `_items`.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: los tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente (remote-config/WebViewPlatform/network mocks); NO son regresiones, no arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- **Persistencia de "Guardadas"**: requiere almacenamiento local de listas guardadas (patrón sqlite como favoritos) + acción de guardar (bookmark funcional en la card). Tarea aparte; al implementarla se re-añade el chip "Guardadas" a `_items`.
- Repensar `position` vs `count` a nivel de modelo/copy editorial: follow-up de contenido.

ENTREGA:
1. Diff de los 2 ficheros (numeral etiquetado + pie; sheet sin AUTOR; header sin icono de vista; fila sin "Guardadas").
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando P2/P3/P4 por code-review y reconociendo "Guardadas" persistencia como follow-up.

Diff objetivo ≤ 120 líneas.
