Resolver los **5 bloqueantes (grupo A)** de la auditoría UI/UX del home. Son defectos de corrección (no estética): un componente `SectionHeader` duplicado con dos APIs distintas, un tap muerto, color hardcodeado que rompe el light theme, y dos problemas de rendimiento (rebuilds de carruseles + filtros recalculados en cada build). Scope acotado al home (tab 0) y a los dos consumidores legacy del header.

CONTEXTO ACTUAL (verificado a mano):

- **Dos widgets llamados `SectionHeader` coexisten con APIs y diseños distintos** — esto es el núcleo de A1:
  * **Legacy** `lib/ui/components/section_header.dart`: API `onTap` (VoidCallback?) + `actionLabel` (default `'Ver todos →'`). Estilo: título `fontSize 18 / bold / color Colors.white` (HARDCODED → A3), CTA `GlobalMethods.blueColor`. Padding `fromLTRB(16, 20, 16, 10)`. Consumidores:
    - `lib/ui/components/nearby_section.dart:48` → `SectionHeader(title: '📍 Cerca de ti')`
    - `lib/ui/pages/home/home.dart` (home LEGACY, no es el home vivo) líneas 491, 502, 542, 596.
  * **Nuevo/canónico** `lib/ui/pages/new_home/widgets/section_header.dart`: API `onAction` (VoidCallback?) + `actionLabel` (String? nullable, sin default). Estilo theme-aware: título `AppTextStyles.eyebrow(size:10, color: context.brand.textSecondary)`, CTA `'$actionLabel ›'` con `AppTextStyles.ui(size:11, color: AppColors.atlanticoClaro, w600)`. Padding `fromLTRB(14, 20, 14, 10)`. Consumidores: `lib/ui/pages/new_home/new_home_body.dart` líneas 271, 312, 356.

- **A2 — tap muerto**: `lib/ui/pages/new_home/new_home_body.dart:359`, sección "CERCA DE TI", el header tiene `onAction: () {}` (no hace nada). Las otras dos cabeceras del mismo fichero (GUÍAS :274, ÚLTIMAS VISITAS :315) sí navegan (a `ListasScreen` y `DiscoverScreen`). La sección "Cerca de ti" muestra `CardNearbyMinimap` (mini-mapa de restaurantes cercanos). El destino natural de "VER TODOS" es el **tab Mapa** (índice 2) o `MapSearch`.

- **A4 — rebuilds de carruseles**: en `new_home_body.dart` los dos `BlocBuilder` horizontales:
  * `:282-307` `BlocBuilder<CuratedListsCubit, CuratedListsState>` (listas curadas, altura 320).
  * `:323-349` `BlocBuilder<VisitsCubit, VisitsState>` (visitas, altura 300).
  Sus `ListView.separated` horizontales no envuelven los items en `RepaintBoundary`, así que al hacer scroll vertical del CustomScrollView se repintan enteros. El `BlocBuilder` ya filtra por su propio cubit (no rebuild cruzado), pero falta `RepaintBoundary` por item.

- **A5 — filtros recalculados cada build**: `new_home_body.dart:113-116`:
  ```dart
  final openNow = widget.presenter.filterOpenNow(widget.pool);
  final contextual = widget.presenter.filterContextual(widget.pool, widget.hour);
  ```
  Se ejecutan en CADA `build()` de `_NewHomeBodyState`. `widget.pool` (List<Restaurant>) y `widget.hour` (int) solo cambian cuando cambia el dataset o la hora. Hoy se recalcula en cada rebuild (scroll, setState de otros, theme rebuild...). Debe memoizarse por identidad de `(pool, hour)`.

CONTRATO FUNCIONAL:

1. **A1 + A3 — Consolidar en UN solo `SectionHeader` canónico, theme-aware**:
   - El canónico vive en `lib/ui/components/section_header.dart` (carpeta correcta para widgets compartidos). Reescribir su contenido con el diseño del nuevo (AppColors + eyebrow + `context.brand`), API: `{ required String title, String? actionLabel, VoidCallback? onAction }`. Sin `Colors.white` ni `GlobalMethods` (elimina A3). El CTA solo se renderiza si `actionLabel != null && onAction != null`.
   - **Borrar** `lib/ui/pages/new_home/widgets/section_header.dart`.
   - Actualizar el import en `new_home_body.dart` a `package:guachinches/ui/components/section_header.dart` (sus 3 usos ya usan la API `onAction`/`actionLabel`, no requieren cambios de call-site).
   - **Migrar consumidores legacy** de la API vieja (`onTap`) a la nueva (`onAction`):
     * `nearby_section.dart:48` → `SectionHeader(title: 'Cerca de ti')` (quitar emoji 📍; el eyebrow va en mayúsculas por estilo).
     * `home.dart` líneas 491/502/542/596: cambiar `onTap:` → `onAction:` y quitar emojis de los títulos. Si alguno usaba `actionLabel` custom, preservarlo.
   - Si `home.dart` o `nearby_section.dart` resultan ser pantallas muertas (no montadas: el home vivo es `new_home_screen.dart` tab 0), igualmente deben COMPILAR tras la migración. Mencionar en informe si están deprecadas.
   - Añadir anchor `Semantics(identifier: 'section-header-cta')` envolviendo el `GestureDetector` del CTA cuando existe (para poder testear el tap).

2. **A2 — Wire del tap "CERCA DE TI · VER TODOS"**:
   - En `new_home_body.dart:356-360`, reemplazar `onAction: () {}` por una acción real. `NewHomeBody` debe recibir un nuevo callback opcional `final VoidCallback? onShowAllNearby;` y usarlo: `onAction: widget.onShowAllNearby`.
   - El caller `new_home_screen.dart` cablea `onShowAllNearby` para **cambiar al tab Mapa** (índice 2). Investigar cómo `new_home_tab_scaffold.dart` expone el cambio de tab (IndexedStack); si hay un callback/controller de tabs, usarlo. Si no existe un mecanismo de cambio de tab accesible desde aquí, fallback: `Navigator.push` a `MapSearch` vía `MaterialPageRoute` (con los providers globales ya disponibles en `main.dart`).
   - Si `onShowAllNearby == null`, el CTA NO debe renderizarse (por la regla `actionLabel != null && onAction != null` — pasar `actionLabel: null` en ese caso) para que no quede un tap muerto nunca.

3. **A4 — RepaintBoundary en carruseles**:
   - En los `itemBuilder` de los dos `ListView.separated` (`:286-301` listas curadas, `:327-344` visitas), envolver cada item en `RepaintBoundary(child: ...)`.
   - Aplicar lo mismo al carrusel "CERCA DE TI" (`:365-...`, items `CardNearbyMinimap`) por consistencia.

4. **A5 — Memoizar filtros derivados**:
   - Cachear `openNow` y `contextual` por identidad de `(widget.pool, widget.hour)`. Mantener en `_NewHomeBodyState` campos privados `_memoKey` (un record o par `(identityHashCode(pool), hour)` o `(pool, hour)` por `==`/identical) + `_openNowCache` + `_contextualCache`. En `build()`, recalcular solo si la clave cambió; si no, reusar caché.
   - No cambiar la firma pública de `filterOpenNow`/`filterContextual` en el presenter; solo evitar llamarlos en cada build.
   - `contextualCount`, `todayPool`, `showTodaySection` (`:116-118`) se derivan de `contextual` — siguen igual, solo que ahora desde la caché.

5. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/`.
   - El presenter `NewHomePresenter` (lógica de filtros) — solo dejar de invocarlo redundantemente.
   - El diseño visual del nuevo header (eyebrow 10pt) — es el canónico.
   - `CardHorizontal`, `CardCuratedList`, `CardVisit`, `CardNearbyMinimap` (los cards están aprobados).
   - El resto de secciones del home (Hero, Search, Banner ubicación, OpenNowCallout, ContextualSectionCard, Especialidades).

TESTS OBLIGATORIOS:

- **Widget** `test/ui/components/section_header_test.dart` (canónico consolidado):
  * (a) Renderiza `title`.
  * (b) Con `actionLabel:'VER TODAS'` + `onAction` → renderiza el CTA y el anchor `section-header-cta`; tap invoca `onAction` (contador).
  * (c) Sin `onAction` (null) → NO renderiza CTA ni el anchor `section-header-cta`.
  * (d) Sin `actionLabel` (null) pero con `onAction` → NO renderiza CTA.
  * (e) **A3 anti-regresión light theme**: montar bajo `MaterialApp(theme: appLightTheme)` y verificar que el color resuelto del título NO es `Colors.white` (leer el `Text` widget y comprobar `style.color != const Color(0xFFFFFFFF)`; debe venir de `context.brand.textSecondary`). Montar también bajo `appDarkTheme` y verificar que renderiza (no crash).

- **Widget** `test/ui/pages/new_home/nearby_see_all_test.dart` (A2):
  * Montar `NewHomeBody` (o un harness mínimo que monte solo la sección "Cerca de ti") con `nearbyList` no vacío y un `onShowAllNearby` espía.
  * Verificar que existe el anchor `section-header-cta` en la cabecera "CERCA DE TI" y que al tap invoca `onShowAllNearby` (contador == 1).
  * Caso `onShowAllNearby == null` → el CTA de esa cabecera NO se renderiza.
  * Si montar `NewHomeBody` completo es inviable por dependencias, extraer la fila "Cerca de ti" a un sub-widget testeable o testear vía el `SectionHeader` con los params que usa esa sección. Documentar la decisión en el informe.

- **A4/A5** se verifican por **code-review del Evaluator** (no test de rendimiento flaky): confirmar presencia de `RepaintBoundary` en los 3 carruseles y de la caché memoizada de `(pool, hour)` que evita recalcular filtros en cada build.

PROHIBIDO (rechazo automático del Evaluator):

- Dejar dos clases `SectionHeader` en el repo tras el sprint (debe quedar UNA, en `lib/ui/components/`).
- Cualquier `Colors.white` / `GlobalMethods.blueColor` hardcodeado en el header canónico.
- Dejar cualquier `onAction: () {}` (tap muerto) en `new_home_body.dart`.
- Recalcular `filterOpenNow`/`filterContextual` en cada `build()`.
- `Semantics(label: ...)` como anchor técnico — siempre `Semantics(identifier: ...)` kebab-case inglés.
- Tocar `pubspec.yaml`, `ios/`, `android/`.
- Romper la compilación de `home.dart` legacy o `nearby_section.dart` (migrarlos, no abandonarlos a medias).

OUT OF SCOPE (mencionar en informe):

- Refactor visual de `home.dart` legacy más allá de migrar el header (es pantalla muerta probable).
- Tokenizar spacing/sombras (eso es Sprint E).
- Reordenar secciones / ritmo vertical (Sprint B).
- Cambiar copy de los CTA (Sprint C).

ENTREGA:

1. Diff con:
   - `lib/ui/components/section_header.dart` reescrito (canónico theme-aware + anchor CTA).
   - `lib/ui/pages/new_home/widgets/section_header.dart` BORRADO.
   - `new_home_body.dart`: import actualizado, `onShowAllNearby` cableado (A2), `RepaintBoundary` en 3 carruseles (A4), memoización de filtros (A5).
   - `new_home_screen.dart`: pasa `onShowAllNearby` (cambio a tab Mapa o push a MapSearch).
   - `nearby_section.dart` + `home.dart`: migrados a la API `onAction`.
   - 2 ficheros de test nuevos.
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/ui/components/section_header_test.dart test/ui/pages/new_home/nearby_see_all_test.dart` al 100%.
4. Informe del Evaluator confirma: un solo `SectionHeader`, light theme no rompe (A3), no quedan taps muertos (A2), `RepaintBoundary` presente (A4), filtros memoizados (A5).

Diff objetivo ≤ 400 líneas (incl. tests). Si crece, priorizar A1+A2+A3 (corrección) sobre A4+A5 (perf) y dejar A4/A5 para iteración siguiente (mencionar en informe).
