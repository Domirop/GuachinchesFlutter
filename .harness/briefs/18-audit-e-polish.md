Resolver el **grupo E (polish visual)** de la auditoría UI/UX del home: (E1) las bandas laterales de acento usan anchos distintos (4px en el callout vs 3px en la card contextual), (E2) los border-radius son magic numbers ad-hoc (32/22/16/12), (E3) las sombras se definen inline sin tokens, y (E4) el icono de la lupa usa un azul saturado (`AppColors.atlanticoClaro`) que destaca más que el propio placeholder. Scope: home (tab 0) — `search_field_dynamic.dart`, `open_now_callout.dart`, `contextual_section_card.dart`, y un nuevo fichero de tokens de forma.

CONTEXTO ACTUAL (verificado a mano):

- **Existe `AppSpacing`** (`lib/config/app_spacing.dart`, creado en el sprint B) con tokens de espaciado. **NO existe** ningún token para radios ni sombras — son magic numbers:
  * `search_field_dynamic.dart:33`: `BorderRadius.circular(32)` (pill de búsqueda).
  * `open_now_callout.dart:85`: `BorderRadius.circular(16)` (contenedor); `:107-110` band corners 16; `:171` chevron `BorderRadius.circular(12)`.
  * `contextual_section_card.dart:40`: `BorderRadius.circular(22)` (contenedor).

- **E1 — bandas laterales inconsistentes**:
  * `open_now_callout.dart:103-112`: `Container(width: 4, ...)` banda en `accent` (laurisilva/sol), con esquinas redondeadas top/bottom-left de 16.
  * `contextual_section_card.dart:59`: `Container(width: 3, color: accent)` banda en `tierra` (o `sol`), sin radio.
  * Anchos distintos (4 vs 3) → el patrón "banda lateral de acento" no se lee como un sistema.

- **E3 — sombras inline ad-hoc**:
  * `open_now_callout.dart:90-94`: `BoxShadow(color: accent.withOpacity(0.08), blurRadius: 18, offset: Offset(0,6))`.
  * `contextual_section_card.dart:45-49`: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 22, offset: Offset(0,6))`.
  * Dos recetas distintas, ningún token compartido.

- **E4 — color del icono lupa**:
  * `search_field_dynamic.dart:37-41`: `Icon(Icons.search_rounded, color: AppColors.atlanticoClaro, size: 18)`. El placeholder de al lado usa `context.brand.textMuted` (`:48`). El icono azul saturado pesa más que el texto que acompaña, rompiendo la jerarquía "campo en reposo". Debe ser un gris de marca (secundario), no un acento.

CONTRATO FUNCIONAL:

1. **E2 + E3 — Tokens de forma (`lib/config/app_shapes.dart` NUEVO)**:
   - `class AppRadius` con `static const double`:
     ```dart
     class AppRadius {
       AppRadius._();
       static const double sm = 12;    // chips, chevrons, badges
       static const double md = 16;    // callout, cards medianas
       static const double lg = 22;    // contenedores de sección (card contextual)
       static const double pill = 32;  // campo de búsqueda / pills
     }
     ```
   - `class AppShadows` con métodos que devuelven `List<BoxShadow>` (las sombras dependen de color/contexto, por eso son métodos, no consts):
     ```dart
     class AppShadows {
       AppShadows._();
       /// Sombra suave neutra para contenedores "asentados" (card contextual).
       static List<BoxShadow> soft() => [
         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 22, offset: const Offset(0, 6)),
       ];
       /// Sombra teñida por un acento, sutil (callout accionable).
       static List<BoxShadow> accent(Color color) => [
         BoxShadow(color: color.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 6)),
       ];
     }
     ```
   - Reemplazar los magic numbers de radio/sombra de los 3 widgets del home por estos tokens:
     * `search_field_dynamic.dart`: `circular(32)` → `circular(AppRadius.pill)`.
     * `open_now_callout.dart`: contenedor `circular(16)` → `AppRadius.md`; esquinas de la banda 16 → `AppRadius.md`; chevron `circular(12)` → `AppRadius.sm`; `boxShadow` inline → `AppShadows.accent(accent)`.
     * `contextual_section_card.dart`: `circular(22)` → `AppRadius.lg`; `boxShadow` inline → `AppShadows.soft()`.
   - NO cambiar valores numéricos efectivos (sólo sustituir el literal por el token equivalente) salvo lo que pida E1.

2. **E1 — Unificar la banda lateral de acento**:
   - Añadir a `AppSpacing` (o a `AppShapes`, decisión del Planner) un token `static const double accentBand = 4;`.
   - Aplicar `width: AppSpacing.accentBand` (4px) a AMBAS bandas: la del `open_now_callout.dart:104` (ya es 4 → pasa a token) y la del `contextual_section_card.dart:59` (hoy 3 → sube a 4 para igualar el patrón).
   - Mantener los colores semánticos (laurisilva/sol en el callout; tierra/sol en la card) — la unificación es de ANCHO/sistema, no de color. Verificar que el accent de la card contextual (`tierra` sobre `cremaSoft`) mantiene contraste legible; si el Planner lo juzga demasiado sutil, puede oscurecer ligeramente a un tono de marca más contrastado, pero NO es obligatorio cambiar el color.

3. **E4 — Icono lupa con color de marca, no acento**:
   - `search_field_dynamic.dart:39`: `color: AppColors.atlanticoClaro` → `color: context.brand.textSecondary` (gris de marca, theme-aware, coherente con el campo en reposo). NO usar `atlanticoClaro` ni ningún acento saturado.

4. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/`.
   - Los valores numéricos de radio/sombra (sólo tokenizar) salvo el ancho de banda (E1: 3→4 en la card) y el color del icono (E4).
   - El diseño de los cards internos (card_horizontal, card_visit, etc.) ni sus radios propios — sólo los 3 widgets del scope.
   - La animación LiveDot del callout, su API, su copy.
   - `AppColors`, `brand_colors`, `AppTextStyles`, `AppSpacing` existentes (sólo AÑADIR `accentBand` si va ahí).

TESTS OBLIGATORIOS:

- **Unit** `test/config/app_shapes_test.dart` (E2/E3):
  * `AppRadius.sm == 12`, `AppRadius.md == 16`, `AppRadius.lg == 22`, `AppRadius.pill == 32`.
  * `AppShadows.soft()` devuelve lista no vacía con `blurRadius == 22` y `offset == Offset(0,6)`.
  * `AppShadows.accent(AppColors.laurisilva)` devuelve lista no vacía con `blurRadius == 18`; el color de la sombra deriva del acento pasado (no negro).

- **Widget** `test/ui/pages/new_home/search_field_icon_test.dart` (E4):
  * Montar `SearchFieldDynamic(onTap: () {})` bajo `MaterialApp(theme: appLightTheme, darkTheme: appDarkTheme)`.
  * Localizar el `Icon(Icons.search_rounded)` y verificar `icon.color != AppColors.atlanticoClaro`.
  * (Si es viable obtener el brand desde un context probe) verificar que el color coincide con `context.brand.textSecondary`; si no, basta con el assert negativo anterior + que NO sea ningún `AppColors` de acento (atlantico/laurisilva/sol/mojo).

- **Widget** `test/ui/pages/new_home/accent_band_test.dart` (E1):
  * Montar `ContextualSectionCard(child: SizedBox())` y localizar la banda lateral (`find.byWidgetPredicate` por un `Container` con `constraints.maxWidth == 4` / `width == AppSpacing.accentBand`); assert que existe con ancho 4.
  * Montar `OpenNowCallout(count: 3, contextLabel: 'Tenerife', onTap: () {})` y localizar su banda lateral; assert ancho 4.
  * Confirma que ambas bandas comparten el mismo ancho (sistema unificado).

- **E2/E3** además se verifican por **code-review del Evaluator**: los 3 widgets usan `AppRadius.*` / `AppShadows.*` en lugar de literales.

PROHIBIDO (rechazo automático del Evaluator):

- Dejar magic numbers de radio (32/22/16/12) o sombras inline en los 3 widgets del scope cuando ya existe el token equivalente.
- Mantener anchos de banda distintos (3 vs 4) entre callout y card contextual.
- Usar `AppColors.atlanticoClaro` (ni otro acento) en el icono de la lupa.
- Cambiar el look de los cards internos o de otras pantallas.
- Tocar `pubspec.yaml`, `ios/`, `android/`.
- `Semantics(label: ...)` como anchor técnico.

OUT OF SCOPE (mencionar en informe):

- Migrar TODO el repo a `AppRadius`/`AppShadows` (sólo los 3 widgets del home en este sprint; el resto puede adoptarlo después).
- Rediseñar la paleta o los acentos semánticos.
- Tokenizar radios de los cards internos (card_horizontal, etc.).

ENTREGA:

1. Diff con:
   - `lib/config/app_shapes.dart` (NUEVO: `AppRadius` + `AppShadows`).
   - `lib/config/app_spacing.dart` (+ `accentBand = 4`, si va aquí).
   - `lib/ui/pages/new_home/widgets/search_field_dynamic.dart` (radio pill token + icono `textSecondary`).
   - `lib/ui/components/open_now_callout.dart` (radios + sombra + banda 4 vía tokens).
   - `lib/ui/pages/new_home/widgets/contextual_section_card.dart` (radio lg + sombra soft + banda 3→4).
   - 3 ficheros de test nuevos.
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/config/app_shapes_test.dart test/ui/pages/new_home/search_field_icon_test.dart test/ui/pages/new_home/accent_band_test.dart test/ui/components/open_now_callout_test.dart` al 100% (incluir el test del callout existente para confirmar no-regresión).
4. Informe del Evaluator confirma: tokens de radio/sombra aplicados (E2/E3), bandas a 4px (E1), icono lupa en gris de marca (E4).

Diff objetivo ≤ 350 líneas (incl. tests).
