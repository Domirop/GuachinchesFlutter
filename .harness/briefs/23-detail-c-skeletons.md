Resolver el **grupo C (loading states / skeletons)** de la auditoría de las pantallas de detalle que se abren desde el home. Las cuatro pantallas muestran un **spinner centrado** (`CircularProgressIndicator` + "Cargando…") durante la carga, lo cual no comunica qué está por venir ni preserva el layout (salto brusco spinner→contenido). Sustituirlos por **skeletons** que reflejan la silueta del contenido real. Cambio puramente visual/estructural: se verifica por **code-review + `flutter analyze`** (regla 5 de CLAUDE.md). **NO escribir tests de widget** en este sprint (montar estas pantallas requiere mockear repos/sqflite/http y NO aporta señal; el cambio es de presentación y se revisa leyendo el diff — mismo criterio que el sprint B).

Ficheros: `lib/ui/components/shimmer_box.dart` (NUEVO), `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`, `lib/ui/pages/visit/visit_screen.dart`, `lib/ui/pages/curated_list_detail/curated_list_detail_screen.dart`, `lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**Ya existe infra de shimmer privada** en `lib/ui/pages/new_home/widgets/skeletons.dart:6-54`: clase `_Shimmer` (StatefulWidget con `AnimationController` 1200ms `repeat(reverse:true)`, `Tween(0.06→0.18)` sobre `AppColors.crema.withValues(alpha:)`). Es **privada** a ese fichero (home), no reutilizable. El home también define `CardRowSkeleton`/`RankingRowSkeleton`/`OpenNowCalloutSkeleton` públicos. NO se toca `skeletons.dart` en este sprint (ver OUT OF SCOPE).

**Spinners a reemplazar (uno por pantalla, más CercaAhora con tres):**

- **RestaurantDetail** — `restaurant_detail_screen.dart`:
  * Branch de carga en `build`: `:282-285` `if (_loading || r == null) const _DetailSkeleton() else _buildScrollContent()`.
  * `_DetailSkeleton` (`:524-546`) es hoy `Center(Column[ CircularProgressIndicator(AppColors.atlantico), 'Cargando…' ])`. Se reescribe su `build` (la clase y su uso se conservan).
  * Layout real a imitar: `DetailHero` (rectángulo grande full-width arriba) + navbar de secciones + cuerpo con título/subtítulo/chips/párrafos.

- **Visit** — `visit_screen.dart`:
  * Branch `:193-198` `if (_loading) Scaffold(body: const _LoadingView())`.
  * `_LoadingView` (`:470-485`) es hoy `Center(Column[ CircularProgressIndicator(AppColors.atlantico), 'Cargando visita…' ])`. Se reescribe su `build`.
  * Layout real: hero de vídeo (16:9) + título + bloques de contenido.

- **CuratedList** — `curated_list_detail_screen.dart`:
  * `_LoadingView` (`:629-667`) **ya pinta el `_Hero` real** (con los datos de `list`) dentro de un `CustomScrollView`, y debajo un `SliverFillRemaining` con `CircularProgressIndicator(color: list.accent)` (`:653-663`). El hero se CONSERVA (es contenido real, no placeholder). Sólo se sustituye el `SliverFillRemaining` del spinner por una **lista de cards skeleton**.

- **CercaAhora** — `cerca_ahora_screen.dart` (theme-aware ya tras sprint B):
  * Tres `CircularProgressIndicator` desnudos: `:156` (resolviendo ubicación: `LocationInitial`/`LocationLoading`), `:233` (`_isLoading` de restaurantes), `:239` (`_initialized` sin estado de filtro aún). Los tres se sustituyen por la **misma lista skeleton** (siluetas de `NearbyRestaurantCard`).
  * La lista real (`:335-356`) usa `ListView.separated` (padding `H16/V8`, separación 12) de `NearbyRestaurantCard` (imagen + texto).

---

CONTRATO FUNCIONAL:

**1. Componente shimmer compartido (NUEVO, canónico):**
- Crear `lib/ui/components/shimmer_box.dart` con un widget **público** `ShimmerBox`:
  * `const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8})`.
  * StatefulWidget con `SingleTickerProviderStateMixin`, `AnimationController(duration: 1200ms)..repeat(reverse: true)`, `Tween<double>(begin: 0.04, end: 0.12)`.
  * **Theme-aware** (estas pantallas son duales): el color base es `context.brand.textPrimary.withValues(alpha: _anim.value)` sobre `BoxDecoration(borderRadius: BorderRadius.circular(radius))`. (En light da gris-oscuro sobre fondo claro; en dark, gris-claro sobre fondo oscuro: visible en ambos.)
  * `width`/`height` aceptan `double.infinity` para anchos elásticos (envuelto por el padre en `Expanded`/`SizedBox` según convenga).
  * Importa `package:flutter/material.dart` y `package:guachinches/config/brand_colors.dart`.
- Este es el sitio canónico del shimmer reutilizable. (El `_Shimmer` privado de home NO se migra aquí en este sprint — ver OUT OF SCOPE.)

**2. RestaurantDetail `_DetailSkeleton` → silueta del detalle:**
- Reescribir el `build` para devolver una columna no interactiva (`IgnorePointer`) que imite el layout: `SingleChildScrollView` con
  * hero: `ShimmerBox(width: double.infinity, height: 340, radius: 0)`;
  * padding `H16 V16`: barra título `ShimmerBox(width: 220, height: 26)`, gap 10, subtítulo `ShimmerBox(width: 150, height: 14)`, gap 20, fila de 3 chips (`Row` de `ShimmerBox(width: 72, height: 28, radius: 14)` separados 8), gap 24, y 3–4 líneas de párrafo (`ShimmerBox(width: double.infinity, height: 12)` + una última `width: 200`, separadas 10).
- Envolver la raíz en `Semantics(identifier: 'restaurant-detail-skeleton', child: ...)`.
- Importar `package:guachinches/ui/components/shimmer_box.dart`. (`AppColors`/`AppTextStyles` ya no se usan en `_DetailSkeleton`; mantenerlos sólo si el resto del fichero los usa — no quitar imports que el fichero siga necesitando.)

**3. Visit `_LoadingView` → silueta de la visita:**
- Reescribir el `build`: `IgnorePointer` + `SingleChildScrollView` con
  * hero vídeo: `ShimmerBox(width: double.infinity, height: ...)` con `AspectRatio(16/9)` o altura fija ~220, radius 0;
  * padding `H16 V16`: título `ShimmerBox(width: 240, height: 24)`, gap 10, meta `ShimmerBox(width: 120, height: 12)`, gap 22, dos bloques de párrafo (3 líneas full-width + 1 corta cada uno, separación 10, con gap 18 entre bloques).
- Envolver en `Semantics(identifier: 'visit-detail-skeleton', child: ...)`.
- Importar `shimmer_box.dart`.

**4. CuratedList `_LoadingView` → hero real + lista de cards skeleton:**
- Mantener el `_Hero(detail: ...)` tal cual (`:636-652`).
- Sustituir el `SliverFillRemaining` del spinner (`:653-663`) por un `SliverPadding(padding: EdgeInsets.all(16))` con un `SliverList`/`SliverList.separated` de ~4 filas skeleton de card. Cada fila: `Row[ ShimmerBox(width: 96, height: 96, radius: 12), SizedBox(width: 12), Expanded(Column[ ShimmerBox(width: double.infinity, height: 16), gap 8, ShimmerBox(width: 140, height: 12), gap 8, ShimmerBox(width: 90, height: 12) ]) ]`, separación 14.
- Envolver el sliver de skeletons en `SliverToBoxAdapter`→ no; usar `Semantics(identifier: 'curated-list-skeleton')` rodeando la lista de filas (p.ej. un `Column` dentro de un único `SliverToBoxAdapter` con `Semantics`, o `SliverMainAxisGroup` no necesario: basta un `SliverToBoxAdapter(child: Semantics(identifier: 'curated-list-skeleton', child: Column([...filas...])))` con su padding). Elige la forma más limpia que conserve el hero como sliver hermano.
- Importar `shimmer_box.dart`. El spinner usaba `list.accent`; ya no se usa para el skeleton (el shimmer es theme-aware) — no romper otros usos de `list`.

**5. CercaAhora: tres spinners → lista skeleton compartida:**
- Crear un widget privado `_CercaListSkeleton extends StatelessWidget` (en el mismo fichero) que devuelva `Semantics(identifier: 'cerca-ahora-skeleton', child: ListView(padding: H16 V8, children: [...]))` con ~6 filas skeleton estilo `NearbyRestaurantCard`: `Padding(vertical: 6)` + `Row[ ShimmerBox(width: 88, height: 88, radius: 12), SizedBox(width: 12), Expanded(Column[ ShimmerBox(infinity, 16), gap 8, ShimmerBox(160, 12), gap 8, ShimmerBox(100, 12) ]) ]`. `ListView` con `physics: NeverScrollableScrollPhysics` (es placeholder).
- Reemplazar los tres `const Center(child: CircularProgressIndicator())` de `:156`, `:233`, `:239` por `const _CercaListSkeleton()` (o sin `const` si el ctor no puede serlo).
- Importar `shimmer_box.dart`. **NO tocar** los anchors `cerca-ahora-*` existentes, ni `AppColors.atlantico` del `RefreshIndicator`/botones, ni la tipografía `'SF Pro Display'`.

---

NO MODIFICAR:
- `pubspec.yaml`, `ios/`, `android/`. (No se añade dependencia: el shimmer es casero, sin `shimmer` package.)
- `lib/ui/pages/new_home/widgets/skeletons.dart` (el `_Shimmer` privado de home y sus skeletons públicos se quedan como están).
- La lógica de datos, cubits, geolocalización, presenters, ni los estados de error/empty (sólo se toca el branch de **loading**).
- Los anchors existentes `cerca-ahora-*`, `restaurant-detail-*`, ni el `_Hero`/`DetailHero` reales.
- `AppColors.atlantico` en botones/refresh, ni la tipografía `'SF Pro Display'`.

---

PROHIBIDO (rechazo automático del Evaluator):
- Dejar cualquier `CircularProgressIndicator` en los branches de **loading** de las 4 pantallas (el de la pantalla de error/otros estados NO se toca; sólo loading).
- Añadir el package `shimmer` (u otra dep) a `pubspec.yaml`.
- Duplicar la lógica de animación del shimmer en cada pantalla: debe vivir SÓLO en `ShimmerBox` (`lib/ui/components/shimmer_box.dart`).
- Skeleton no theme-aware (colores `Colors.white*` hardcodeados, o base que sea invisible en light). Usar `context.brand.*`.
- Escribir tests de widget que monten estas pantallas (rabbit hole de mocking; este sprint es code-review).
- Tocar `ios/`, `android/`, o `skeletons.dart` de home.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` limpio en los ficheros tocados (sólo se permiten los infos preexistentes de `withOpacity`/`Share` deprecados, y los warnings ya-existentes de `visit_screen.dart` del bloque comentado ⑥⑦ que se limpian en el sprint F: `del_video_section`, `ticket_card_widget`, `_videoQuotes`).
- Confirmar leyendo el diff: (1) `ShimmerBox` existe, es público y theme-aware; (2) las 4 pantallas usan skeletons que imitan su layout en lugar de spinner; (3) CuratedList conserva su `_Hero` real; (4) CercaAhora reemplaza sus 3 spinners por `_CercaListSkeleton`; (5) cada skeleton lleva su `Semantics(identifier: '<screen>-skeleton')`.
- Smoke: `flutter test` de la suite existente sigue verde (no se rompió nada). NO añadir tests nuevos.

OUT OF SCOPE (mencionar en informe):
- Migrar el `_Shimmer` privado de `new_home/widgets/skeletons.dart` (y sus skeletons públicos) a `ShimmerBox` compartido: deseable (DRY), pero home es la pantalla de smoke visual y su shimmer usa `AppColors.crema` calibrado para dark; migrarlo arriesga el arranque. Follow-up de polish.
- Añadir anchors de contenido (no-skeleton) a estas pantallas: es el sprint D (accesibilidad).
- Animaciones de transición skeleton→contenido (crossfade): otro sprint de polish.

ENTREGA:
1. Diff con los 5 ficheros (1 nuevo + 4 pantallas).
2. `flutter analyze` limpio (salvo infos preexistentes y warnings F-diferidos de visit_screen).
3. `flutter test` (suite existente) verde.
4. Informe del Evaluator confirmando C por code-review.

Diff objetivo ≤ 220 líneas.
