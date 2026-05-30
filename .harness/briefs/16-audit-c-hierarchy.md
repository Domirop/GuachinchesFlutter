Resolver el **grupo C (jerarquía visual y consistencia de copy)** de la auditoría UI/UX del home, EXCLUYENDO C4 (emojis del banner — fuera de scope, NO tocar). Tres defectos: (C1) varios elementos compiten por atención con tratamientos de "display" cerca del top, (C2) los eyebrows mezclan separadores/espaciado inconsistentes (`  ·  ` doble espacio vs ` · ` simple), y (C3) el CTA de "ver todo" aparece en tres variantes distintas ("VER TODO" / "VER TODAS" / "VER TODOS"). Scope: home (tab 0).

CONTEXTO ACTUAL (verificado a mano):

- **Type scale** (`lib/config/app_text_styles.dart`): familias display (Oswald), editorial (Merriweather italic), ui (Inter). Helpers: `displayHero(size:32 default)`, `displaySection(size:13 default, letterSpacing 1.4)`, `eyebrow(size:11 default, letterSpacing 1.6)`, `chipLabel`, `editorial`, `ui`, `muted`. Suelo `minSize = 11`.

- **C1 — displays compitiendo cerca del top del home**:
  * Hero (`parallax_hero.dart:193-209`): `displayHero(size:32)` — correcto, es EL display de la pantalla.
  * `hour_aware_banner.dart:195`: título de la sección "HOY EN…" usa `displaySection(size:18)` — un tamaño ad-hoc; en el resto del repo `displaySection` se llama con size 13/15/18/20 sin criterio (island_picker :77 size18, canarian_specialties :183, card_visit :111, etc.).
  * `OpenNowCallout` (`lib/ui/components/open_now_callout.dart`): tiene su propio titular grande ("23 sitios abiertos cerca"). Hay que verificar que NO use `displayHero` (sólo el Hero debe ser tier-hero).
  * Resultado: tras el Hero, el usuario encuentra OpenNowCallout + título del banner como dos titulares fuertes seguidos, sin un step-down claro de jerarquía.

- **C2 — formato de eyebrow inconsistente**:
  * `hour_aware_banner.dart:147-148`: `'${s.label}  ·  HOY EN ${zoneLabel.toUpperCase()}'` → separador con **doble espacio** (`  ·  `).
  * `OpenNowCallout`: eyebrow "ABIERTOS AHORA · TENERIFE" → separador con **espacio simple** (` · `).
  * `SectionHeader` usa `eyebrow(size:10)`; el banner usa `eyebrow(size:10)` ✓ mismo tamaño, pero los strings de eyebrow que concatenan segmentos lo hacen con separadores distintos.

- **C3 — copy "ver todo" en 3 variantes**:
  * `new_home_body.dart:230, :247`: `actionLabel: 'VER TODO'` (banner contextual).
  * `new_home_body.dart:336, :387`: `actionLabel: 'VER TODAS'` (Guías, Últimas Visitas).
  * `new_home_body.dart:291-292`: `AppL10n.of(context).homeSeeAll.toUpperCase()` (Cerca de ti). Hoy `homeSeeAll = 'Ver todos'` (`lib/l10n/app_es.arb:19` + `lib/l10n/app_localizations_es.dart:27`) → renderiza "VER TODOS".
  * Tres variantes visibles en la misma pantalla. Inconsistente.

CONTRATO FUNCIONAL:

1. **C3 — Unificar el CTA a UNA sola copy vía i18n** (la pieza más clara):
   - Copy canónica: **"Ver todo"** (neutro; en mayúsculas "VER TODO").
   - Cambiar el valor de `homeSeeAll` en español: `lib/l10n/app_es.arb:19` `"Ver todos"` → `"Ver todo"`, y reflejarlo en el generado `lib/l10n/app_localizations_es.dart:27` (`=> 'Ver todo';`). Inglés (`app_en.arb` / `app_localizations_en.dart`) se queda en `"See all"`.
   - Reemplazar TODOS los `actionLabel:` hardcodeados de las cabeceras de sección del home por `AppL10n.of(context).homeSeeAll.toUpperCase()`:
     * `new_home_body.dart:230` y `:247` (banner contextual, hoy 'VER TODO').
     * `new_home_body.dart:336` (Guías, hoy 'VER TODAS').
     * `new_home_body.dart:387` (Últimas Visitas, hoy 'VER TODAS').
     * `:291-292` (Cerca de ti) ya usa `homeSeeAll` → queda correcto automáticamente.
   - Tras el sprint, `grep -rn "VER TODAS\|VER TODOS\|'VER TODO'" lib/ui/pages/new_home/` no debe devolver ningún `actionLabel` hardcodeado; todo pasa por `homeSeeAll`.
   - OJO: el `HourAwareBanner` recibe `actionLabel` como parámetro; pásale el valor de `homeSeeAll.toUpperCase()` desde `new_home_body.dart` (NO hardcodear dentro del banner).

2. **C2 — Unificar el formato de eyebrow con un helper único**:
   - Crear `lib/utils/eyebrow_format.dart` con:
     ```dart
     /// Une segmentos de un eyebrow con el separador canónico ' · '
     /// (punto medio U+00B7, espacio simple a cada lado). Ignora vacíos.
     String eyebrowJoin(List<String> parts) =>
         parts.where((p) => p.trim().isNotEmpty).map((p) => p.trim()).join(' · ');
     ```
   - Usarlo donde se concatenan segmentos de eyebrow:
     * `hour_aware_banner.dart:147-149`: sustituir el `'${s.label}  ·  HOY EN ...'` (doble espacio) por `eyebrowJoin([s.label, if (mode==openNow && zoneLabel!=null) 'HOY EN ${zoneLabel!.toUpperCase()}'])`.
     * `OpenNowCallout`: si construye su eyebrow concatenando "ABIERTOS AHORA" + contextLabel, pasarlo por `eyebrowJoin([...])` para garantizar el mismo separador. (Verificar el código real del callout antes de tocar; si ya usa ' · ' simple, dejar el string pero idealmente migrar al helper por consistencia.)
   - El separador canónico es ` · ` (espacio simple). Nada de `  ·  ` (doble), ni `-`, ni `|`.

3. **C1 — Jerarquía: un solo tier "display", step-down consistente para titulares de sección**:
   - Documentar la escala en un comentario de cabecera en `app_text_styles.dart`: **Hero (displayHero ~32) › Section headline (displaySection ~18) › Eyebrow (eyebrow ~10)**. Es documentación, no cambia los helpers.
   - Introducir una constante semántica para el tamaño de titular de sección del home y usarla en el banner: en `app_text_styles.dart` añadir `static const double sectionHeadlineSize = 18;` (o el valor actual del banner) y en `hour_aware_banner.dart:195` usar `displaySection(size: AppTextStyles.sectionHeadlineSize, ...)` en lugar del literal `18`.
   - **Garantizar que sólo el Hero usa tier-hero en el primer viewport**: verificar `OpenNowCallout` y `HourAwareBanner` — si alguno usa `displayHero`, bajarlo a `displaySection(size: AppTextStyles.sectionHeadlineSize)`. El titular del callout puede ser fuerte pero NO tier-hero (32+). El Hero (`parallax_hero.dart`) es el único `displayHero` de la zona superior.
   - NO tocar los `displayHero(size:56/64)` que viven DENTRO de cards (card_horizontal, card_editor_pick): son números/nombres grandes en su propio contexto cerrado, no compiten con el Hero de pantalla.
   - Cambios mínimos y de bajo riesgo: el objetivo es que no haya DOS titulares tier-hero en la zona superior, no rediseñar tipografía.

4. **NO MODIFICAR / EXCLUSIONES**:
   - **C4 está FUERA de scope**: NO tocar los emojis del `hour_aware_banner.dart` (☀️🌙🌇⏱🍽). Se quedan.
   - `pubspec.yaml`, `ios/`, `android/`.
   - El Hero / parallax (es la referencia tier-hero correcta).
   - El diseño de los cards (los `displayHero` internos de card_horizontal/card_editor_pick).
   - La lógica de horas/copys del banner (`_stateForHour`, subtítulos) salvo el formato del eyebrow (C2) y el size token del título (C1).
   - Los sheets (island/zone/municipality picker) — fuera del home scroll; no es scope.

TESTS OBLIGATORIOS:

- **Unit** `test/utils/eyebrow_format_test.dart` (C2):
  * `eyebrowJoin(['12:00 · MEDIODÍA', 'HOY EN TENERIFE']) == '12:00 · MEDIODÍA · HOY EN TENERIFE'`.
  * `eyebrowJoin(['ABIERTOS AHORA', 'TENERIFE']) == 'ABIERTOS AHORA · TENERIFE'`.
  * Ignora vacíos: `eyebrowJoin(['A', '', '  ', 'B']) == 'A · B'`.
  * Trim: `eyebrowJoin(['  A ', 'B ']) == 'A · B'`.
  * Nunca produce doble espacio alrededor del `·`.

- **Widget** `test/ui/pages/new_home/see_all_copy_unified_test.dart` (C3):
  * Montar `HourAwareBanner(hour: 13, zoneLabel:'Tenerife', actionLabel: 'VER TODO', onAction: () {})` y verificar que el CTA muestra "VER TODO ›" (o el texto exacto con el chevron que use el widget).
  * Montar `SectionHeader(title:'GUÍAS', actionLabel:'VER TODO', onAction: () {})` y verificar "VER TODO ›".
  * Verificar que `AppL10nEs().homeSeeAll == 'Ver todo'` (o instanciar el localizations es) → confirma el cambio de valor canónico.
  * Negativo: ninguno de los anteriores muestra "VER TODAS" ni "VER TODOS".

- **C1** se verifica por **code-review del Evaluator**: existe `AppTextStyles.sectionHeadlineSize`, el banner lo usa, y ni `OpenNowCallout` ni `HourAwareBanner` usan `displayHero` (sólo el Hero).

PROHIBIDO (rechazo automático del Evaluator):

- Dejar cualquier `actionLabel:` hardcodeado ("VER TODO"/"VER TODAS"/"VER TODOS") en las cabeceras de sección del home — todo vía `homeSeeAll`.
- Mantener separadores de eyebrow con doble espacio (`  ·  `) o caracteres distintos de ` · `.
- Tocar los emojis del banner (eso es C4, excluido).
- Usar `displayHero` en `OpenNowCallout` o `HourAwareBanner`.
- Modificar `pubspec.yaml`, `ios/`, `android/`, o el Hero.
- `Semantics(label: ...)` como anchor técnico.

OUT OF SCOPE (mencionar en informe):

- C4 (emojis del banner) — excluido por petición del usuario.
- Migrar los sheets / otras pantallas a la escala documentada.
- Rediseñar la tipografía de los cards.
- Cambiar `displaySection` default global (sólo añadir la constante semántica y usarla en el banner).

ENTREGA:

1. Diff con:
   - `lib/l10n/app_es.arb` + `lib/l10n/app_localizations_es.dart` (homeSeeAll → "Ver todo").
   - `lib/utils/eyebrow_format.dart` (NUEVO).
   - `lib/config/app_text_styles.dart` (comentario de escala + `sectionHeadlineSize`).
   - `lib/ui/pages/new_home/widgets/hour_aware_banner.dart` (eyebrowJoin + size token).
   - `lib/ui/components/open_now_callout.dart` (eyebrowJoin si concatena + verificar no-hero).
   - `lib/ui/pages/new_home/new_home_body.dart` (actionLabel → homeSeeAll en :230/:247/:336/:387).
   - 2 ficheros de test nuevos.
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/utils/eyebrow_format_test.dart test/ui/pages/new_home/see_all_copy_unified_test.dart` al 100%.
4. Informe del Evaluator confirma: copy unificada "VER TODO" (C3), eyebrows con separador canónico ` · ` (C2), un solo tier-hero + token de section headline (C1), emojis intactos (C4 no tocado).

Diff objetivo ≤ 350 líneas (incl. tests).
