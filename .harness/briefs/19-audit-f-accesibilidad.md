Resolver el **grupo F (accesibilidad)** de la auditoría UI/UX del home (tab 0). Tres defectos: (F1) faltan anchors `Semantics(identifier:)` en bloques importantes del home, lo que obliga a tests frágiles por `find.text()`; (F2) el LIVE dot pulsante del `OpenNowCallout` no aporta descripción coherente para VoiceOver — el lector lee el dot como nodo suelto o no lo describe; (F3) el placeholder del campo de búsqueda usa `context.brand.textMuted` (30% de opacidad sobre `surface.withOpacity(0.6)`), contraste estimado ~2.8:1 que probablemente falla WCAG AA. Scope: `new_home_body.dart`, `open_now_callout.dart`, `search_field_dynamic.dart`.

CONTEXTO ACTUAL (verificado a mano):

- **Anchors `Semantics(identifier:)` existentes hoy en el home** (grep real):
  * `new_home_body.dart:166` → `home-refresh-indicator`.
  * `new_home_body.dart:285` → `home-section-nearby` (envuelve la sección "Cerca de ti").
  * `new_home_body.dart:323` → `home-section-specialties` (envuelve `CanarianSpecialtiesSection`).
  * `open_now_callout.dart:79` → `home-cerca-ahora-cta`.
  * `location_prompt_banner.dart:55` → `home-location-prompt`.
  * `skeletons.dart:121` → `home-cerca-ahora-skeleton`.
  * `section_header.dart:41` → `section-header-cta`.
  * `top_filter_bar.dart:57` → `home-zone-chip`.
  - **NO existen** `home-hero`, `home-search-field`, `home-section-today`, `home-section-curated-lists`, `home-section-visits` (grep confirma: "NONE of those anchors exist yet").

- **Estructura de `new_home_body.dart` (build → Stack)**:
  * Scroll principal = `CustomScrollView` con slivers en este orden:
    - `:177` spacer del hero (`SizedBox(height: kHeroHeight)`).
    - `:182-187` `SearchFieldDynamic(...)` ← necesita anchor `home-search-field`.
    - `:193` `LocationPromptBanner()` (ya tiene su anchor propio).
    - `:198-210` `OpenNowCalloutSlot(...)` (skeleton/oculto/callout, anchors internos ya cubiertos).
    - `:221-279` bloque contextual "HOY EN ···" con 3 ramas mutuamente excluyentes (`if bootstrapLoading` → skeleton; `else if showTodaySection`; `else if showOpeningSoonSection`), cada una un `SliverToBoxAdapter(child: ContextualSectionCard(...))` ← necesita anchor `home-section-today` que envuelva el bloque (cuando se renderice alguna rama).
    - `:282-318` sección "Cerca de ti" (`home-section-nearby`, YA existe).
    - `:321-330` "Especialidades" (`home-section-specialties`, YA existe).
    - `:333-381` "GUÍAS DE JONAY Y JOANA" (SectionHeader + `BlocBuilder<CuratedListsCubit>`) ← necesita anchor `home-section-curated-lists`.
    - `:384-434` "ÚLTIMAS VISITAS DE JONAY Y JOANA" (SectionHeader + `BlocBuilder<VisitsCubit>`) ← necesita anchor `home-section-visits`.
  * Hero = `Positioned(:446-462, child: ParallaxHero(...))` fuera del scroll, por encima en el Stack ← necesita anchor `home-hero`.

- **`OpenNowCallout` (F2)** — `lib/ui/components/open_now_callout.dart`:
  * `Semantics(identifier: 'home-cerca-ahora-cta', button: widget.onTap != null, child: GestureDetector(...))` envuelve TODO el callout (`:78-81`).
  * Dentro, cuando `hasOpen`, se pinta `_LiveDot(controller: _pulse, color: accent)` (`:120`) seguido del eyebrow ("ABIERTOS AHORA · TENERIFE"), headline ("5 sitios abiertos cerca") y support.
  * `_LiveDot` (`:198-239`) es un `AnimatedBuilder` puramente decorativo (punto pulsante). Hoy NO está excluido del árbol de semántica → VoiceOver puede pararse en él como nodo sin label útil, y la lectura del botón se fragmenta.

- **`SearchFieldDynamic` (F3)** — `lib/ui/pages/new_home/widgets/search_field_dynamic.dart`:
  * `:28` fondo `context.brand.surface.withOpacity(0.6)`.
  * `:37-41` icono lupa ya en `context.brand.textSecondary` (arreglado en sprint E4).
  * `:44-50` el placeholder (`Text(placeholder, style: AppTextStyles.editorial(size: 13, color: context.brand.textMuted))`) usa `textMuted`.
  * En `brand_colors.dart`: `textMuted = crema 30%` (`0x4DF2E8D5`) / `textSecondary = crema 55%` (`0x8CF2E8D5`). `textSecondary` ≈ casi el doble de contraste → cumple mejor AA sin ser un acento.

CONTRATO FUNCIONAL:

1. **F1 — Añadir anchors `Semantics(identifier:)` faltantes** (kebab-case inglés, NUNCA `label:` como anchor técnico):
   - `home-search-field`: envolver el `SearchFieldDynamic` del `:182-187` (o añadir el `Semantics` dentro del propio widget envolviendo su raíz; preferible en `new_home_body.dart` para mantener el widget reutilizable agnóstico, decisión del Planner). El anchor debe contener el campo completo.
   - `home-hero`: envolver el `child: ParallaxHero(...)` del `Positioned` `:451` con `Semantics(identifier: 'home-hero', child: ParallaxHero(...))`. NO cambiar el `Positioned` ni el parallax.
   - `home-section-today`: envolver el bloque contextual. Como hay 3 ramas (`bootstrapLoading` / `showTodaySection` / `showOpeningSoonSection`) y a veces NINGUNA se renderiza, el anchor debe envolver **cada** `ContextualSectionCard` que se pinte (o factorizar el `Semantics` alrededor del `SliverToBoxAdapter` de cada rama). Cuando no se renderiza ninguna rama, el anchor simplemente no está presente (correcto).
   - `home-section-curated-lists`: envolver el conjunto SectionHeader + row de "GUÍAS DE JONAY Y JOANA" (`:333-381`). Puede agruparse en un `Semantics(identifier: ..., child: Column([...]))` o envolver ambos slivers; el criterio es que el anchor exista cuando la sección está montada.
   - `home-section-visits`: ídem para "ÚLTIMAS VISITAS" (`:384-434`).
   - Patrón a seguir: idéntico a `home-section-nearby` (`:284`) y `home-section-specialties` (`:322`) — `Semantics(identifier: '<id>', child: ...)`. NO usar `container: true` salvo que sea necesario para que el nodo agrupe; seguir el patrón existente.

2. **F2 — LIVE dot con semántica coherente para VoiceOver** (`open_now_callout.dart`):
   - El `_LiveDot` es decorativo y debe dejar de fragmentar la lectura del botón. Aplicar UNA de estas dos soluciones (decisión del Planner, ambas válidas):
     * (a) Envolver `_LiveDot` en `ExcludeSemantics(child: _LiveDot(...))` para que VoiceOver NO se pare en él y lea el callout como un único botón con su eyebrow+headline+support. **Recomendada por simplicidad.**
     * (b) Darle al dot `Semantics(label: 'Indicador en vivo', excludeSemantics: true, child: _LiveDot(...))` — aquí `label:` es descripción de screen-reader legítima (NO un anchor técnico), permitida por su uso a11y real.
   - En cualquier caso, el `Semantics(identifier: 'home-cerca-ahora-cta', button: ...)` exterior NO cambia: sigue siendo el anchor del botón. El objetivo es que el lector anuncie el callout como una sola acción coherente, sin un nodo "punto" suelto sin sentido.
   - NO tocar la animación del `_pulse`, su API, ni el copy.

3. **F3 — Contraste del placeholder** (`search_field_dynamic.dart:48`):
   - `color: context.brand.textMuted` → `color: context.brand.textSecondary`.
   - NO tocar el icono (ya está en `textSecondary`), ni el fondo, ni el copy del placeholder, ni el radio.

4. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/`.
   - El look/animación del hero, del callout real, ni del campo de búsqueda (sólo los cambios a11y/contraste descritos).
   - Los anchors ya existentes (`home-section-nearby`, `home-section-specialties`, etc.) ni su lógica.
   - `LocationCubit`/`LocationState`/`LocationPromptBanner`.

TESTS OBLIGATORIOS:

- **Widget** `test/ui/pages/new_home/search_field_a11y_test.dart` (F1 anchor + F3 contraste):
  * Montar `SearchFieldDynamic(onTap: () {})` bajo `MaterialApp(theme: appLightTheme, darkTheme: appDarkTheme)`.
  * (si el anchor `home-search-field` se coloca dentro del widget) verificar `find.byWidgetPredicate((w) => w is Semantics && w.properties.identifier == 'home-search-field')` → `findsOneWidget`. **Si el Planner coloca el anchor en `new_home_body.dart` en lugar del widget**, omitir este assert aquí y verificar el anchor del campo por code-review del Evaluator (documentarlo en el informe).
  * Localizar el `Text` del placeholder y verificar `text.style.color == context.brand.textSecondary` (usar un context-probe del tema claro). Como mínimo: `color != AppColorsBrand.textMuted` y `color == textSecondary`.

- **Widget** `test/ui/components/open_now_callout_a11y_test.dart` (F2):
  * Montar `OpenNowCallout(count: 5, contextLabel: 'Tenerife', onTap: () {})` bajo `MaterialApp(theme: appLightTheme)`.
  * Verificar que el callout sigue exponiendo el anchor botón `home-cerca-ahora-cta` (`findsOneWidget`).
  * Verificar que el `_LiveDot` ya NO se anuncia como nodo suelto: usar el `SemanticsTester`/`tester.getSemantics` sobre el nodo del botón y comprobar que su `label` (lectura combinada) contiene el headline "5 sitios abiertos cerca" y NO hay un nodo hijo independiente con sólo el dot. Implementación pragmática aceptada: assert de que existe `ExcludeSemantics` (solución a) en el árbol envolviendo el dot, o que el `Semantics` del dot tiene `excludeSemantics == true` (solución b). El criterio mínimo es que el test falle si se elimina el tratamiento a11y del dot.
  * No-regresión: con `count: 0` el callout no pinta `_LiveDot` (estado vacío) y el test no debe romper.

- **F1 (anchors en body)** — los anchors `home-hero`, `home-section-today`, `home-section-curated-lists`, `home-section-visits` viven en `new_home_body.dart`, que es **impracticable de montar en widget test** (monta `WeatherLayer` con HTTP vía `CachedNetworkImage` + `Positioned` que requiere `Stack` ancestro — mismo motivo documentado en `home_pull_to_refresh_test.dart`). Por tanto se verifican por **code-review del Evaluator** leyendo el diff: confirmar que cada uno envuelve la sección correcta con `Semantics(identifier:)` kebab-case. Documentar esto en el informe.

PROHIBIDO (rechazo automático del Evaluator):

- `Semantics(label: ...)` como anchor TÉCNICO (de test). En F2, `label:` sólo se admite como descripción de screen-reader del dot decorativo (uso a11y real), nunca como selector.
- Usar `find.text()` o coordenadas como sustituto de los anchors.
- Dejar el placeholder en `textMuted`.
- Dejar el `_LiveDot` sin tratamiento a11y (que VoiceOver lo lea como nodo suelto).
- Cambiar el look/animación del hero, callout o campo.
- Tocar `pubspec.yaml`, `ios/`, `android/`.

OUT OF SCOPE (mencionar en informe):

- Auditoría a11y completa de OTRAS pantallas (sólo home tab 0).
- Reemplazar los emojis del `HourAwareBanner` por SVGs (eso era C4/otro grupo, excluido).
- Tamaños de fuente dinámicos / `MediaQuery.textScaler` (no es este sprint).
- Anchors para secciones que ya los tienen (`home-section-nearby`, `home-section-specialties`).

ENTREGA:

1. Diff con:
   - `lib/ui/pages/new_home/new_home_body.dart` (anchors `home-hero`, `home-search-field` [si va aquí], `home-section-today`, `home-section-curated-lists`, `home-section-visits`).
   - `lib/ui/components/open_now_callout.dart` (tratamiento a11y del `_LiveDot`).
   - `lib/ui/pages/new_home/widgets/search_field_dynamic.dart` (placeholder `textMuted` → `textSecondary`; anchor `home-search-field` si va aquí).
   - 2 ficheros de test nuevos.
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/ui/pages/new_home/search_field_a11y_test.dart test/ui/components/open_now_callout_a11y_test.dart test/ui/components/open_now_callout_test.dart` al 100% (incluir el test existente del callout para confirmar no-regresión).
4. Informe del Evaluator confirma: anchors `home-*` añadidos (F1), `_LiveDot` con semántica coherente (F2), placeholder en `textSecondary` (F3).

Diff objetivo ≤ 300 líneas (incl. tests).
