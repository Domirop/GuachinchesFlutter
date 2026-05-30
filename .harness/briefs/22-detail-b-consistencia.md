Resolver el **grupo B (consistencia)** de la auditoría de las pantallas de detalle que se abren desde el home. Tres defectos de coherencia entre pantallas hermanas, todos verificados a mano. Cambios puramente de consistencia/tema/DRY: se verifican por **code-review + `flutter analyze`** (regla 5 de CLAUDE.md). **NO escribir tests de widget** en este sprint (montar estas pantallas requiere mockear repos/sqflite/http y NO aporta señal aquí; el cambio es visual/estructural y se revisa leyendo el diff).

Ficheros: `lib/ui/pages/visit/visit_screen.dart`, `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`, `lib/ui/pages/restaurant_detail/widgets/floating_buttons.dart`, `lib/ui/pages/curated_list_detail/curated_list_detail_screen.dart`, `lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**B1 — `VisitDetailPage` reimplementa el botón flotante.**
- `visit_screen.dart:473-500`: clase privada `_FloatingButton` que es **idéntica** (mismo `ClipOval`+`BackdropFilter`+`Container` 36x36, `AppColors.glassDark`, borde `Colors.white.withOpacity(0.15)`, icono blanco 16px) al widget compartido `FloatingCircleButton` que ya existe en `restaurant_detail/widgets/floating_buttons.dart:6-40`. Es duplicación pura.
- `visit_screen.dart:322-340` `_buildFloatingButtons` usa `_FloatingButton` tres veces: back (left:12), share (right:12), storefront (right:56).

**B2 — acción "Compartir" duplicada (Restaurant + Visit) y muerta (CuratedList).**
- *Duplicada en Visit*: `_buildFloatingButtons` pinta un `_FloatingButton(icon: Icons.ios_share, onTap: _share)` (`:330-333`) Y ADEMÁS la `BottomCtaBar(onPrimary: _openMaps, onSecondary: _share)` (`:231-234`) ya muestra share como acción secundaria. Dos affordances de share en la misma pantalla.
- *Duplicada en Restaurant*: `DetailFloatingButtons` (en `floating_buttons.dart:42-89`) incluye un botón `Icons.ios_share` (`:78-85`, vía `onShare`) Y la `BottomCtaBar(onSecondary: _share)` (`restaurant_detail_screen.dart`, en el `bottomNavigationBar`) también muestra share. Mismo problema.
- *Muerta en CuratedList*: `curated_list_detail_screen.dart:244-247` `_IconChip(icon: Icons.ios_share_rounded, onTap: () {})` — **callback vacío, no hace nada**. Está dentro de `_Hero` (StatelessWidget con `detail` en scope, `:212-214`).
- `BottomCtaBar` (`lib/ui/components/bottom_cta_bar.dart`) tiene `secondaryIcon = Icons.ios_share` por defecto y sólo pinta el secundario si `onSecondary != null` (`:48-51`). Es el sitio canónico, siempre visible y al alcance del pulgar.

**B3 — theming no theme-aware (invisible en light).**
- *RestaurantDetail*: `restaurant_detail_screen.dart` `_SectionDivider` (cerca del final del fichero) usa `Container(height: 1, color: Colors.white.withOpacity(0.04))` — hardcodeado, invisible sobre fondos claros.
- *CercaAhora*: `cerca_ahora_screen.dart` está lleno de colores hardcodeados que NO respetan el tema dual (la pantalla se ve rota en light): Scaffold `:138` `backgroundColor: AppColors.base`; AppBar `:144` `backgroundColor: AppColors.surface`, `:145` `foregroundColor: Colors.white`; iconos `Colors.white38` (`:181`, `:279`); textos `Colors.white` (`:188`, `:259`, `:286`, `:321`) y `Colors.white54` (`:199`). NO importa `brand_colors.dart`. (Los anchors `cerca-ahora-*` ya existen del sprint #9 y NO se tocan.)

---

CONTRATO FUNCIONAL:

**1. B1 — VisitDetail usa el botón flotante compartido:**
- En `visit_screen.dart`: importar `package:guachinches/ui/pages/restaurant_detail/widgets/floating_buttons.dart`.
- En `_buildFloatingButtons`, sustituir cada `_FloatingButton(...)` por `FloatingCircleButton(...)` (misma API: `icon`, `onTap`).
- **Eliminar por completo la clase privada `_FloatingButton`** (`:473-500`). Confirmar que ningún otro sitio del fichero la use (grep).
- Cero cambio visual (los dos widgets son pixel-idénticos).

**2. B2 — Unificar share en UN solo sitio (la BottomCtaBar) y matar el share muerto:**
- *Regla canónica*: el share vive en la `BottomCtaBar` (secundario). Los botones flotantes quedan para navegación + acción propia de pantalla (back, guardar, ir-al-restaurante). Se ELIMINA el icono de share flotante en las dos pantallas que lo duplican.
- **Visit**: en `_buildFloatingButtons` quitar el `Positioned` del share (`:330-333`). Quedan dos botones: back (left:12) y storefront; **mover el storefront a `right: 12`** (era right:56) para que quede en el borde. Mantener `BottomCtaBar(onSecondary: _share)` intacta. El método `_share` se conserva (lo usa la bottom bar).
- **Restaurant** (`floating_buttons.dart` + `restaurant_detail_screen.dart`):
  * En `DetailFloatingButtons`: eliminar el tercer `Positioned`/`FloatingCircleButton` de `Icons.ios_share` (`:78-85`) y el campo+param `onShare` (`:46`, `:52`, `:53`). Recolocar el botón de guardar (`favorite`) de `right: 56` a `right: 12`. Resultado: back (left:12) + guardar (right:12).
  * En `restaurant_detail_screen.dart`, en la llamada a `DetailFloatingButtons(...)`, quitar el argumento `onShare: _share`. Mantener la `BottomCtaBar(onSecondary: _share)` del `bottomNavigationBar`. El método `_share` del screen se conserva (lo usa la bottom bar).
  * **Verificar con grep que `DetailFloatingButtons` sólo se usa en `restaurant_detail_screen.dart`** antes de cambiar su firma. Si se usa en otro sitio, actualizar también esa llamada.
- **CuratedList** (`curated_list_detail_screen.dart`): wirear el `_IconChip` de share muerto (`:244-247`) a un share de texto real (deeplinks están desactivados en el proyecto, así que share de texto es el mínimo honesto):
  * Importar `package:share_plus/share_plus.dart' show SharePlus, ShareParams;`.
  * `onTap: () => SharePlus.instance.share(ShareParams(text: '${detail.title} en ¿Dónde Comer Canarias?'))`.
  * (`detail` está en scope dentro de `_Hero.build`.)

**3. B3 — Theming theme-aware:**
- **RestaurantDetail `_SectionDivider`**: `Colors.white.withOpacity(0.04)` → `context.brand.border`. (El widget ya recibe `BuildContext` en `build`; `brand_colors.dart` ya está importado en ese fichero.)
- **CercaAhora**: importar `package:guachinches/config/brand_colors.dart` y reemplazar TODOS los colores hardcodeados por tokens de tema (mantener `AppColors.atlantico` en los botones de acción y `'SF Pro Display'` en los `TextStyle` — sólo cambian los COLORES, no la tipografía):
  * `:138` Scaffold `AppColors.base` → `context.brand.base`.
  * `:144` AppBar `AppColors.surface` → `context.brand.surface`.
  * `:145` AppBar `foregroundColor: Colors.white` → `context.brand.textPrimary`.
  * `:181` Icon `Colors.white38` → `context.brand.textMuted`.
  * `:188` Text `Colors.white` → `context.brand.textPrimary`.
  * `:199` Text `Colors.white54` → `context.brand.textSecondary`.
  * `:259` Text `Colors.white` → `context.brand.textPrimary`.
  * `:279` Icon `Colors.white38` → `context.brand.textMuted`.
  * `:286` Text `Colors.white` → `context.brand.textPrimary`.
  * `:321` Text `Colors.white` → `context.brand.textPrimary`.
  * Donde el `TextStyle` sea `const` y deje de poder serlo al usar `context.brand`, quitar el `const`. Los textos que estaban en widgets `const` (p.ej. `:184-193`, `:195-202`, `:255-263`) deben dejar de ser `const` para poder leer el color del tema (ajustar el árbol mínimamente).

---

NO MODIFICAR:
- `pubspec.yaml`, `ios/`, `android/`. (`share_plus` YA es dependencia del proyecto — sólo se añade un import.)
- La lógica de datos, cubits, geolocalización, los anchors `cerca-ahora-*` ni `restaurant-detail-*`.
- El look del `FloatingCircleButton` / `DetailFloatingButtons` más allá de quitar el share y recolocar.
- El `BottomCtaBar` (su `_share` y su secundario se mantienen; es el sitio canónico de share).
- La tipografía `'SF Pro Display'` de CercaAhora (otro sprint podría migrar a AppTextStyles; aquí sólo color).

---

PROHIBIDO (rechazo automático del Evaluator):
- Dejar dos affordances de share en Restaurant o en Visit (B2 sin resolver).
- Dejar el `_IconChip` de CuratedList con `onTap: () {}` (botón muerto).
- Dejar `_FloatingButton` duplicado en visit_screen.dart (B1 sin resolver).
- Dejar cualquier `Colors.white*` o `AppColors.base/surface` hardcodeado en CercaAhora o el divider blanco en RestaurantDetail (B3 sin resolver).
- Escribir tests de widget que monten estas pantallas (rabbit hole de mocking; este sprint es code-review).
- Tocar `pubspec.yaml`, `ios/`, `android/`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` limpio en los 5 ficheros tocados (sólo se permiten los infos preexistentes de `withOpacity`/`Share` deprecados).
- Confirmar leyendo el diff: (B1) visit usa `FloatingCircleButton` y `_FloatingButton` borrado; (B2) un único share por pantalla en la bottom bar, share de CuratedList funcional; (B3) CercaAhora y `_SectionDivider` 100% theme-aware (`context.brand.*`), sin `Colors.white*` ni `AppColors.base/surface` residuales.
- Smoke: `flutter test` de la suite existente sigue verde (no se rompió nada). NO añadir tests nuevos.

OUT OF SCOPE (mencionar en informe):
- Migrar los `TextStyle` inline de CercaAhora a `AppTextStyles` (otro sprint de polish).
- Unificar el `_IconChip` (chip) de CuratedList con el `FloatingCircleButton` (círculo): son tratamientos visuales distintos a propósito (pantalla revista en light); no se fuerza aquí.
- Modernizar `Share.share` → `SharePlus` en RestaurantDetail (grupo F, deprecación).
- AppBar de CercaAhora vs floating de las detalle: CercaAhora es pantalla-lista, su AppBar es adecuado; no se unifica con el patrón floating.

ENTREGA:
1. Diff con los 5 ficheros.
2. `flutter analyze` limpio (salvo infos preexistentes).
3. `flutter test` (suite existente) verde.
4. Informe del Evaluator confirmando B1/B2/B3 por code-review.

Diff objetivo ≤ 180 líneas.
