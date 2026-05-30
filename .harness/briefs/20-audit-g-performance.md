Resolver el **grupo G (performance)** de la auditoría UI/UX del home (tab 0). Dos defectos: (G1) el `ParallaxHero` se reconstruye en CADA frame de scroll porque el offset de scroll vive en un `setState` del screen que reconstruye TODO `NewHomeBody` (incluido el subárbol del hero, con su foto, starfield, sol/luna y `WeatherLayer`); (G2) las secciones inferiores del `CustomScrollView` se montan como `SliverToBoxAdapter` con sus hijos construidos eager, en vez de construirse on-demand al entrar en viewport. Scope: `new_home_screen.dart`, `new_home_body.dart`, un nuevo widget `ParallaxHeroSlot`, y `home_pull_to_refresh_test.dart` (actualizar el stub de construcción de `NewHomeBody` tras el cambio de API).

CONTEXTO ACTUAL (verificado a mano):

- **G1 — el hero se reconstruye por frame de scroll**:
  * `new_home_screen.dart:70-71`: `final ScrollController _scrollCtrl = ScrollController();` + `double _scrollOffset = 0;`.
  * `:92`: `_scrollCtrl.addListener(_onScroll);`.
  * `:133`: `void _onScroll()` → `if (mounted) setState(() => _scrollOffset = _scrollCtrl.offset);` — **un `setState` por cada evento de scroll**, que reconstruye el `build` del screen y, dentro, todo `NewHomeBody`.
  * `:298-300`: `NewHomeBody(scrollCtrl: _scrollCtrl, scrollOffset: _scrollOffset, ...)`.
  * `new_home_body.dart` es `StatefulWidget` con `final double scrollOffset` (`:50`, requerido en el ctor `:79`).
  * **`scrollOffset` sólo se usa para posicionar el hero**: `:154` `overscroll = math.max(-widget.scrollOffset, 0)`, `:156` `scrollUp = math.max(widget.scrollOffset, 0)`, y `:446-462` el `Positioned(top: -scrollUp, height: kHeroHeight + overscroll, child: ParallaxHero(scrollOffset: 0, ...))`. **Ningún otro widget del body depende de `scrollOffset`** (la `TopFilterBar` `:465-476` NO lo usa; el parallax interno de la foto recibe `scrollOffset: 0` ya, `:452`). Confirmado por grep.
  * El hero (`ParallaxHero`) monta foto (`CachedNetworkImage`), `WeatherLayer` (HTTP), `StarfieldWidget` (CustomPaint animado) y `SunMoonArc`. Reconstruir ese subárbol en cada frame de scroll es caro e innecesario: sólo cambia la POSICIÓN (`top`/`height`), no el contenido.

- **G2 — secciones eager**:
  * `new_home_body.dart` `CustomScrollView.slivers` (`:175-438`) son ~8 `SliverToBoxAdapter` directos. Los `SliverToBoxAdapter` construyen su `child` durante el `build` del body aunque estén fuera de viewport (sólo el paint es lazy). Las dos secciones de cola — "GUÍAS DE JONAY Y JOANA" (`:333-381`, SectionHeader + `BlocBuilder<CuratedListsCubit>` con `ListView` horizontal de cards) y "ÚLTIMAS VISITAS" (`:384-434`, SectionHeader + `BlocBuilder<VisitsCubit>`) — son las más pesadas y están SIEMPRE al final (debajo del fold inicial). Construirlas on-demand con un delegate reduce el trabajo del primer pintado.

- **Tests que construyen `NewHomeBody`** (grep): sólo `test/ui/pages/new_home/home_pull_to_refresh_test.dart` (helper `_wrap`, pasa `scrollOffset: 0`) y el propio `new_home_screen.dart`. Cambiar la API de `NewHomeBody` impacta exactamente esos dos sitios.

CONTRATO FUNCIONAL:

1. **G1 — Aislar el hero del rebuild de scroll** (offset por `ValueListenable`, no por `setState`):
   - **`new_home_screen.dart`**:
     * Cambiar `double _scrollOffset = 0;` → `final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);`.
     * `_onScroll()`: `_scrollOffset.value = _scrollCtrl.offset;` — **sin `setState`** (el scroll ya no reconstruye el screen ni el body).
     * `dispose()`: añadir `_scrollOffset.dispose();` (junto al `_scrollCtrl.dispose()` existente).
     * En la construcción de `NewHomeBody`: pasar `scrollListenable: _scrollOffset` en lugar de `scrollOffset: _scrollOffset`.
   - **Nuevo widget `lib/ui/pages/new_home/widgets/parallax_hero_slot.dart`**:
     ```dart
     class ParallaxHeroSlot extends StatelessWidget {
       final ValueListenable<double> offset;
       final Widget child; // el ParallaxHero, construido UNA vez por el padre
       const ParallaxHeroSlot({super.key, required this.offset, required this.child});

       @override
       Widget build(BuildContext context) {
         return ValueListenableBuilder<double>(
           valueListenable: offset,
           // `child` se pasa al builder para que NO se reconstruya cuando
           // cambia el offset: sólo se recalcula el Positioned envolvente.
           child: RepaintBoundary(child: child),
           builder: (context, value, child) {
             final overscroll = math.max(-value, 0).toDouble();
             final scrollUp = math.max(value, 0).toDouble();
             return Positioned(
               top: -scrollUp,
               left: 0,
               right: 0,
               height: kHeroHeight + overscroll,
               child: child!,
             );
           },
         );
       }
     }
     ```
     * NOTA Flutter: un `Positioned` devuelto DESDE un `ValueListenableBuilder` (StatelessWidget, sin RenderObject intermedio) sigue siendo posicionado correctamente por el `Stack` ancestro — `Positioned` es un `ParentDataWidget` que atraviesa elementos sin RenderObject. Es un patrón válido; NO meter el `ValueListenableBuilder` dentro del `Positioned`.
     * El `RepaintBoundary` envuelve el hero para aislar su capa de pintado del resto del Stack.
   - **`new_home_body.dart`**:
     * Reemplazar `final double scrollOffset` por `final ValueListenable<double> scrollListenable` (ctor y campo). Importar `package:flutter/foundation.dart` si hace falta `ValueListenable`.
     * Eliminar las líneas `:154` y `:156` (cálculo top-level de `overscroll`/`scrollUp`) — ahora viven dentro de `ParallaxHeroSlot`.
     * Sustituir el bloque `Positioned(:446-462, child: ParallaxHero(...))` por:
       ```dart
       ParallaxHeroSlot(
         offset: widget.scrollListenable,
         child: Semantics(            // mantener anchor home-hero si el sprint F ya lo añadió
           identifier: 'home-hero',
           child: ParallaxHero(
             scrollOffset: 0,
             hour: widget.hour,
             assetImage: _assetForIsland(filters.islandKey),
             zona: filters.zoneLabel ?? filters.islandLabel,
             islandLabel: filters.islandLabel,
             zoneIsSet: filters.zoneLabel != null,
             openCount: openNow.length,
             onZoneChipTap: () => _showZoneSheet(context),
             onIslandChipTap: () => _showIslandSheet(context),
           ),
         ),
       ),
       ```
       (Si el sprint F NO se ha mezclado en esta rama, omitir el `Semantics(home-hero)` y dejar el `ParallaxHero` directo como `child`. El Planner debe verificar el estado del fichero en la rama actual y NO romper lo que F dejó.)
     * El `ParallaxHero` se construye en el `build` del body (depende de `hour`, `filters`, `openNow.length`): se reconstruye cuando cambian los DATOS (que es correcto), pero ya NO en cada frame de scroll, porque el scroll dejó de disparar `setState`. Al pasarse como `child:` del `ValueListenableBuilder`, los ticks del offset no lo reconstruyen.

2. **G2 — Construcción on-demand de las secciones de cola** (las más pesadas, siempre debajo del fold):
   - Convertir las DOS secciones finales — "GUÍAS DE JONAY Y JOANA" (`:333-381`) y "ÚLTIMAS VISITAS" (`:384-434`) — en builders perezosos dentro de un `SliverList` con `SliverChildBuilderDelegate`:
     ```dart
     SliverList(
       delegate: SliverChildBuilderDelegate(
         (context, index) {
           switch (index) {
             case 0: return _buildCuratedListsSection(context);   // header + BlocBuilder curated
             case 1: return _buildVisitsSection(context);         // header + BlocBuilder visits
             default: return null;
           }
         },
         childCount: 2,
       ),
     ),
     ```
     * Extraer cada sección a un método privado `_buildCuratedListsSection(BuildContext)` / `_buildVisitsSection(BuildContext)` que devuelva el `Column`/contenido (SIN el `SliverToBoxAdapter`, ya que ahora son children del delegate). Con `SliverChildBuilderDelegate`, el builder se invoca on-demand cuando la fila entra en el `cacheExtent`, no durante el `build` del body → defiere su construcción.
     * Mantener internamente los `BlocBuilder<CuratedListsCubit>` / `BlocBuilder<VisitsCubit>`, los `SectionHeader`, los `SectionErrorRetry`, los `CardRowSkeleton` y los `RepaintBoundary` de las cards EXACTAMENTE como están — sólo se mueve el envoltorio sliver.
     * Si el sprint F añadió anchors `home-section-curated-lists` / `home-section-visits`, preservarlos dentro de los métodos extraídos.
   - **NO** convertir las secciones de la mitad (contextual/nearby/specialties) ni las de cabecera (spacer/search/location/callout): quedan como `SliverToBoxAdapter`. Sólo la cola pesada pasa a delegate perezoso (cambio acotado y seguro).
   - El `SizedBox(height: AppSpacing.scrollBottom)` final (`:437`) se mantiene como `SliverToBoxAdapter` después del nuevo `SliverList`.

3. **Actualizar `test/ui/pages/new_home/home_pull_to_refresh_test.dart`**:
   - El helper `_wrap` construye `NewHomeBody(..., scrollOffset: 0, ...)`. Tras el cambio de API: `scrollListenable: ValueNotifier<double>(0)` (o un `ValueNotifier` const-equivalente). Mantener el resto del stub igual. Los tests (a)/(b) ya están `skip: true`; el test "source contract" debe seguir compilando y pasando.

4. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/`.
   - El look del hero, su parallax interno, `WeatherLayer`, starfield, sol/luna (sólo se cambia QUIÉN dispara su rebuild y su posicionamiento).
   - El contenido/orden visible de las secciones (mismo orden, mismos widgets; sólo cambia el envoltorio sliver de la cola).
   - La lógica de datos (`filterOpenNow`, memoización, cubits), los `BlocBuilder`, los `SectionErrorRetry`, los skeletons.
   - Los anchors que dejó el sprint F.

TESTS OBLIGATORIOS:

- **Widget** `test/ui/pages/new_home/parallax_hero_slot_test.dart` (G1 — el núcleo del fix, testeable en aislamiento SIN `WeatherLayer`):
  * Montar `ParallaxHeroSlot` dentro de un `Stack` (en `MaterialApp/Scaffold`) con un `child` que sea un widget contador de builds (un `StatefulWidget`/`StatelessWidget` que incremente un contador en cada `build`, p.ej. vía un closure o un `ValueNotifier<int>` externo). Usar un `ValueNotifier<double> offset = ValueNotifier(0)`.
  * `await tester.pump()` → el child se construye 1 vez (contador == 1).
  * `offset.value = 120; await tester.pump();` → el `Positioned` se reubica (verificar que el `top` del `Positioned` cambió: localizar el `Positioned` y comprobar `top == -120` o leer el render box `localToGlobal`), **pero el contador de builds del child SIGUE en 1** (el subárbol del hero NO se reconstruyó). Este es el assert clave de G1.
  * Repetir con un overscroll negativo: `offset.value = -50; await tester.pump();` → `Positioned.height == kHeroHeight + 50`, contador sigue en 1.

- **No-regresión** `test/ui/pages/new_home/home_pull_to_refresh_test.dart`: tras actualizar el stub a `scrollListenable`, debe compilar y el test "source contract" pasar (los otros dos siguen `skip`).

- **G2** se verifica por **code-review del Evaluator** (regla 5/6 de CLAUDE.md: cambios de performance estructurales se revisan leyendo el diff): confirmar que las dos secciones de cola pasan por `SliverChildBuilderDelegate` (builder on-demand, `childCount: 2`), que el resto de secciones no cambió de orden ni de widget, y que `flutter analyze` queda limpio. Montar el body completo en widget test es impracticable (`WeatherLayer` HTTP + `Positioned`/`Stack`), documentado en `home_pull_to_refresh_test.dart`.

PROHIBIDO (rechazo automático del Evaluator):

- Dejar el `setState(_scrollOffset)` por frame de scroll en `new_home_screen.dart` (G1 sin resolver).
- Meter el `ValueListenableBuilder` DENTRO del `Positioned` (rompe el posicionamiento del Stack) o el hero fuera del `child:` del builder (lo seguiría reconstruyendo).
- Reconstruir el subárbol del `ParallaxHero` en cada tick de offset (el test de build-count debe quedar en 1).
- Romper el orden o el contenido visible de las secciones.
- Tocar `pubspec.yaml`, `ios/`, `android/`.
- Olvidar `_scrollOffset.dispose()` (fuga del `ValueNotifier`).
- `Semantics(label: ...)` como anchor técnico.

OUT OF SCOPE (mencionar en informe):

- Lazificar TODAS las secciones del scroll (sólo la cola pesada en este sprint; el resto puede migrar después).
- Cachear/optimizar `WeatherLayer` o la descarga de la foto del hero (otro sprint).
- Sustituir el `Stack` hero+scroll por un `SliverAppBar`/`SliverPersistentHeader` (rediseño mayor, fuera de alcance).
- Memoización de filtros (ya resuelta en sprint A5).

ENTREGA:

1. Diff con:
   - `lib/ui/pages/new_home/widgets/parallax_hero_slot.dart` (NUEVO).
   - `lib/ui/pages/new_home/new_home_screen.dart` (`ValueNotifier` offset, `_onScroll` sin setState, dispose, pasa `scrollListenable`).
   - `lib/ui/pages/new_home/new_home_body.dart` (API `scrollListenable`, usa `ParallaxHeroSlot`, cola en `SliverChildBuilderDelegate`).
   - `test/ui/pages/new_home/parallax_hero_slot_test.dart` (NUEVO).
   - `test/ui/pages/new_home/home_pull_to_refresh_test.dart` (stub `scrollListenable`).
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/ui/pages/new_home/parallax_hero_slot_test.dart test/ui/pages/new_home/home_pull_to_refresh_test.dart` al 100%.
4. Informe del Evaluator confirma: hero aislado del rebuild de scroll (G1, build-count==1 bajo cambios de offset) y secciones de cola en delegate perezoso (G2).

Diff objetivo ≤ 300 líneas (incl. tests).
