Resolver el **grupo D (accesibilidad / anchors)** de la auditoría de las pantallas de detalle que se abren desde el home. Las pantallas de detalle **no exponen `Semantics(identifier:)` estables** en su contenido cargado ni en sus acciones (back, guardar, compartir, cómo-llegar, ir-al-restaurante), lo que las hace no navegables por tests de integración. `CercaAhoraScreen` ya tiene anchors completos (sprint #9) y es la **referencia**. Cambio puramente estructural (envolver en `Semantics` + añadir params opcionales de identifier a componentes compartidos): se verifica por **code-review + `flutter analyze`** (regla 5 de CLAUDE.md). **NO escribir tests de widget** en este sprint: montar RestaurantDetail/Visit/CuratedList requiere mockear repos/sqflite/http (esas pantallas crean el repo internamente en `initState`), y los anchors son envoltorios `Semantics` estáticos que se revisan leyendo el diff — mismo criterio que B y C.

Ficheros: `lib/ui/pages/restaurant_detail/widgets/floating_buttons.dart`, `lib/ui/components/bottom_cta_bar.dart`, `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`, `lib/ui/pages/visit/visit_screen.dart`, `lib/ui/pages/curated_list_detail/curated_list_detail_screen.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**Convención (CLAUDE.md regla 1):** `Semantics(identifier: '<screen>-<componente>-<rol>')`, kebab-case inglés. NUNCA `Semantics(label:)` como anchor técnico. Prefijos por pantalla: `restaurant-detail-*`, `visit-detail-*`, `curated-list-*`.

**Anchors que YA existen (no se tocan):**
- RestaurantDetail: `restaurant-detail-error`, `restaurant-detail-error-back`, `restaurant-detail-retry-button`, `restaurant-detail-skeleton`.
- Visit: `visit-detail-skeleton`.
- CuratedList: `curated-list-skeleton`.
- CercaAhora (referencia, COMPLETA): `cerca-ahora-screen-root`, `cerca-ahora-location-required`, `cerca-ahora-activate-location-button`, `cerca-ahora-empty`, `cerca-ahora-list`, `cerca-ahora-skeleton`.

**Componentes compartidos sin soporte de anchor (hay que añadirles un param opcional):**
- `FloatingCircleButton` y `DetailFloatingButtons` en `floating_buttons.dart`. Usados por RestaurantDetail (vía `DetailFloatingButtons`) y por Visit (`FloatingCircleButton` directo en `_buildFloatingButtons`).
- `BottomCtaBar` en `lib/ui/components/bottom_cta_bar.dart` (botón primario "CÓMO LLEGAR" + `_SecondaryBtn` de share). Usado por RestaurantDetail y Visit.
- `_IconChip` (privado de `curated_list_detail_screen.dart`, `:331`). Usado en `_Hero` (back + share) y en `_ErrorView` (back).

**Estructura cargada (dónde colgar el anchor de contenido):**
- RestaurantDetail: `_buildScrollContent` devuelve un `CustomScrollView` (el contenido cargado). La llamada a `DetailFloatingButtons(...)` y a `BottomCtaBar(...)` están en `build`.
- Visit: `_buildScrollContent` devuelve un `SingleChildScrollView`. Botones flotantes en `_buildFloatingButtons` (back `Icons.arrow_back_ios_new` left:12, storefront `Icons.storefront_outlined` right:12). `BottomCtaBar(onPrimary: _openMaps, onSecondary: _share)` en `_buildScaffold`. `_ErrorView` (`:539`) con `ElevatedButton('Reintentar')` (`:558-564`).
- CuratedList: `_buildLoaded` devuelve un `CustomScrollView`. `_Hero` tiene dos `_IconChip` (back `arrow_back_rounded` + share `ios_share_rounded`). `_EmptyView` (`:692`) y `_ErrorView` (`:727`, con `_IconChip` de back).

**D2 (contraste light):** ya resuelto en el sprint B (divider de RestaurantDetail → `context.brand.border`; CercaAhora 100% theme-aware). Las pantallas de tema dinámico no tienen texto hardcodeado de bajo contraste residual. CuratedList es pantalla **light por diseño** (`_LightTheme` fuerza light; `AppColors.ink/crema` son intencionales). Este sprint es **anchors-only**.

---

CONTRATO FUNCIONAL:

**1. Componentes compartidos — añadir soporte de anchor OPCIONAL (aditivo, retro-compatible):**
- `FloatingCircleButton` (`floating_buttons.dart`): añadir `final String? identifier;` (param opcional en el ctor). En `build`, si `identifier != null`, envolver el `GestureDetector` en `Semantics(identifier: identifier!, button: true, child: ...)`; si es null, dejar el árbol idéntico (cero cambio para llamadas existentes).
- `DetailFloatingButtons` (`floating_buttons.dart`): añadir `final String? backIdentifier;` y `final String? saveIdentifier;` (opcionales). Pasarlos como `identifier:` a los dos `FloatingCircleButton` (back y favorite).
- `BottomCtaBar` (`bottom_cta_bar.dart`): añadir `final String? primaryIdentifier;` y `final String? secondaryIdentifier;` (opcionales). Envolver el `ElevatedButton` primario en `Semantics(identifier: primaryIdentifier!, button: true, ...)` sólo si no es null; pasar `secondaryIdentifier` a `_SecondaryBtn` (que también gana un `String? identifier` y se auto-envuelve igual). Cero cambio si son null.
- `_IconChip` (`curated_list_detail_screen.dart`): añadir `final String? identifier;` opcional; auto-envolver el `GestureDetector` en `Semantics(identifier:, button: true)` si no es null.

**2. RestaurantDetail (`restaurant-detail-*`):**
- Envolver el `CustomScrollView` de `_buildScrollContent` en `Semantics(identifier: 'restaurant-detail-content', child: ...)`.
- En la llamada a `DetailFloatingButtons(...)`: `backIdentifier: 'restaurant-detail-back-button'`, `saveIdentifier: 'restaurant-detail-save-button'`.
- En la llamada a `BottomCtaBar(...)`: `primaryIdentifier: 'restaurant-detail-maps-button'`, `secondaryIdentifier: 'restaurant-detail-share-button'`.

**3. Visit (`visit-detail-*`):**
- Envolver el `SingleChildScrollView` de `_buildScrollContent` en `Semantics(identifier: 'visit-detail-content', child: ...)`.
- En `_buildFloatingButtons`: al `FloatingCircleButton` de back → `identifier: 'visit-detail-back-button'`; al de storefront → `identifier: 'visit-detail-restaurant-button'`.
- En `_buildScaffold`, `BottomCtaBar(...)`: `primaryIdentifier: 'visit-detail-maps-button'`, `secondaryIdentifier: 'visit-detail-share-button'`.
- `_ErrorView`: envolver su raíz en `Semantics(identifier: 'visit-detail-error', child: ...)` y el `ElevatedButton('Reintentar')` en `Semantics(identifier: 'visit-detail-retry-button', button: true, child: ...)`.

**4. CuratedList (`curated-list-*`):**
- Envolver el `CustomScrollView` de `_buildLoaded` en `Semantics(identifier: 'curated-list-content', child: ...)`.
- En `_Hero`: `_IconChip` de back → `identifier: 'curated-list-back-button'`; `_IconChip` de share → `identifier: 'curated-list-share-button'`.
- `_EmptyView`: envolver su raíz en `Semantics(identifier: 'curated-list-empty', child: ...)`.
- `_ErrorView`: envolver su raíz en `Semantics(identifier: 'curated-list-error', child: ...)` y su `_IconChip` de back → `identifier: 'curated-list-error-back'`.

---

NO MODIFICAR:
- `pubspec.yaml`, `ios/`, `android/`.
- Los anchors existentes (`cerca-ahora-*`, `restaurant-detail-error/-error-back/-retry-button/-skeleton`, `*-skeleton`).
- La lógica de datos, cubits, presenters, navegación ni el look de los componentes (los params nuevos son opcionales y NO cambian el render cuando son null).
- La firma EXISTENTE de los componentes compartidos: sólo se AÑADEN params opcionales (nullable, sin romper llamadas actuales como las de CercaAhora/otros).
- CuratedList sigue siendo light por diseño (no convertir a theme-aware).

---

PROHIBIDO (rechazo automático del Evaluator):
- Usar `Semantics(label:)` como anchor técnico (es para screen reader; mete ruido a11y). El anchor es SIEMPRE `Semantics(identifier:)`.
- Identifiers que no sigan `<screen>-<componente>-<rol>` kebab-case inglés.
- Romper llamadas existentes de los componentes compartidos (los params nuevos DEBEN ser opcionales con default null).
- Cambiar el render visual cuando el identifier es null (debe ser un no-op).
- Escribir tests de widget que monten estas pantallas (rabbit hole de mocking; este sprint es code-review).
- Tocar `pubspec.yaml`, `ios/`, `android/`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` limpio en los ficheros tocados (sólo se permiten los infos preexistentes de `withOpacity`/`Share` deprecados, y los warnings ya-existentes de `visit_screen.dart` del bloque comentado ⑥⑦ que se limpian en el sprint F: `del_video_section`, `ticket_card_widget`, `_videoQuotes`).
- Confirmar leyendo el diff que existen los anchors nuevos: `restaurant-detail-content/-back-button/-save-button/-maps-button/-share-button`; `visit-detail-content/-back-button/-restaurant-button/-maps-button/-share-button/-error/-retry-button`; `curated-list-content/-back-button/-share-button/-empty/-error/-error-back`. Todos `Semantics(identifier:)`, ninguno `label:`.
- Confirmar que los params nuevos de los componentes compartidos son opcionales (nullable) y no rompen las llamadas existentes.
- Smoke: `flutter test` de la suite existente sigue verde (no se rompió nada). NO añadir tests nuevos. (NOTA: ~30 tests de la suite YA fallan ANTES de este sprint por infra preexistente — `widget_test.dart` template, `settings/login/listas/visitas` por `WebViewPlatform.instance`/remote-config/network mocks. NO son regresiones de este sprint; el baseline es ese. No intentar arreglarlos aquí.)

OUT OF SCOPE (mencionar en informe):
- Anchors sobre cada item de lista (CuratedListItemCard / NearbyRestaurantCard): basta el anchor de la lista contenedora; los items son otro nivel.
- Tests de integración Patrol que naveguen home→detalle y toquen estos anchors: valioso, pero requiere fixtures de Restaurant/Visit e inyección de repos (las pantallas crean el repo en initState). Sprint aparte de testabilidad.
- Migrar el contenido de CuratedList a theme-aware: es light por diseño (revista).

ENTREGA:
1. Diff con los 5 ficheros.
2. `flutter analyze` limpio (salvo infos preexistentes y warnings F-diferidos de visit_screen).
3. `flutter test` (suite existente) sin NUEVOS fallos respecto al baseline preexistente (~30 fallos de infra ajenos).
4. Informe del Evaluator confirmando los anchors por code-review.

Diff objetivo ≤ 170 líneas.
