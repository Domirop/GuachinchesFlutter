Resolver el **grupo B (alto impacto)** de la auditoría UI/UX del home: inconsistencia de spacing (mezcla 14/16/20/24 en magic numbers), ritmo vertical irregular entre secciones, touch targets por debajo de 44pt en los CTA de cabecera, ausencia de estados de error (las secciones desaparecen en silencio), y fatiga de carruseles (4 carruseles horizontales apilados con la sección de mayor intención —"Cerca de ti"— enterrada al final). Scope: home (tab 0) — `new_home_body.dart`, `section_header.dart`, y un nuevo fichero de tokens.

CONTEXTO ACTUAL (verificado a mano):

- **No existe fichero de tokens de spacing**. `lib/config/` solo tiene `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`, `brand_colors.dart`. Los espaciados son magic numbers dispersos:
  * Gutter horizontal de los carruseles: `EdgeInsets.symmetric(horizontal: 14)` (new_home_body :307, :350, :393).
  * `SectionHeader` (`lib/ui/components/section_header.dart`): `EdgeInsets.fromLTRB(14, 20, 14, 10)`.
  * Separadores entre cards: `SizedBox(width: 12)` (listas/visitas), `SizedBox(width: 10)` (cerca de ti) — **inconsistente**.
  * Padding final del scroll: `SliverToBoxAdapter(child: SizedBox(height: 24))` (new_home_body :412).
  * Otros widgets del home usan 14/16 mezclados (`hour_aware_banner.dart`, `contextual_section_card.dart`, `search_field_dynamic.dart`, `canarian_specialties_section.dart`).

- **B3 — touch target sub-44pt**: en `lib/ui/components/section_header.dart` el CTA es un `GestureDetector` envuelto en `Semantics(identifier:'section-header-cta')` cuyo hijo es un `Text('$actionLabel ›')` de `AppTextStyles.ui(size:11)`. Altura efectiva ≈ 14-16px. Apple HIG / Material piden ≥ 44×44. Hoy es difícil de pulsar.

- **B4 — secciones desaparecen en silencio**: en `new_home_body.dart`:
  * Listas curadas (:301-326): `CuratedListsLoaded` con lista vacía → `SizedBox.shrink()`; `CuratedListsFailure` → `SizedBox.shrink()`. El usuario no sabe si falló o si no hay datos.
  * Visitas (:344-372): idéntico patrón (`VisitsLoaded` vacío → shrink, `VisitsFailure` → shrink).
  * No hay forma de reintentar tras un fallo de red (relevante con el backend inestable del :459).

- **B5 — orden de secciones / fatiga de carruseles**. Orden actual del `CustomScrollView` (new_home_body):
  1. Hero (SizedBox reservado) → 2. `SearchFieldDynamic` → 3. `LocationPromptBanner` → 4. `OpenNowCallout` → 5. `ContextualSectionCard` ("HOY EN…") → 6. `CanarianSpecialtiesSection` (carrusel) → 7. Guías (header + carrusel) → 8. Últimas Visitas (header + carrusel) → 9. **Cerca de ti** (header + carrusel, solo si `nearbyList.isNotEmpty`) → 10. padding 24.
  - "Cerca de ti" es la sección de mayor intención cuando hay ubicación, pero está la ÚLTIMA, tras 3 carruseles. Hay 4 carruseles horizontales seguidos (6→7→8→9) → fatiga.

CONTRATO FUNCIONAL:

1. **B1 — Tokens de spacing (`lib/config/app_spacing.dart` NUEVO)**:
   - Clase `AppSpacing` con `static const double` (sin instanciar). Escala base de 4: `xs=4, sm=8, md=12, lg=16, xl=20, xxl=24`. Más alias semánticos del home:
     ```dart
     static const double gutter = 14;          // padding horizontal de contenido del home
     static const double cardGap = 12;          // separación entre cards en carruseles
     static const double sectionHeaderTop = 20; // espacio sobre una cabecera de sección
     static const double sectionHeaderBottom = 10;
     static const double scrollBottom = 24;     // respiración al final del scroll
     ```
   - Reemplazar los magic numbers de spacing en `new_home_body.dart` y `section_header.dart` por estos tokens. **Unificar el separador de carruseles a `AppSpacing.cardGap` (12)** en los 3 carruseles (hoy "Cerca de ti" usa 10 → pasa a 12).
   - NO cambiar valores que alteren el diseño aprobado de los CARDS (CardHorizontal, CardVisit, etc.) ni del Hero — solo el spacing estructural del scroll del home y la cabecera.

2. **B2 — Ritmo vertical consistente**:
   - Garantizar el mismo gap vertical entre bloques de sección. Como cada `SectionHeader` ya aporta `sectionHeaderTop`/`sectionHeaderBottom`, el ritmo se logra usando esos tokens de forma homogénea (B1 lo cubre). Para secciones SIN header (OpenNowCallout, ContextualSectionCard, Especialidades) asegurar un gap vertical equivalente entre ellas vía un `SizedBox(height: AppSpacing.xl)` o el padding propio del widget — sin solapamientos ni dobles márgenes. Verificación por code-review.

3. **B3 — Touch targets ≥ 44pt en el CTA de `SectionHeader`**:
   - En `lib/ui/components/section_header.dart`, el `GestureDetector` del CTA debe tener un área de toque mínima de 44×44 sin agrandar visualmente el texto. Usar `ConstrainedBox(constraints: BoxConstraints(minHeight: 44, minWidth: 44))` + `Padding` simétrico + `behavior: HitTestBehavior.opaque` en el GestureDetector, manteniendo el `Text` con su tamaño actual (11pt) centrado.
   - El anchor `section-header-cta` debe seguir envolviendo la zona pulsable (ahora de 44pt).

4. **B4 — Estados de error con reintento (no desaparición silenciosa)**:
   - Para `CuratedListsFailure` (new_home_body :324) y `VisitsFailure` (:370), reemplazar `SizedBox.shrink()` por un widget compacto inline (altura ≈ la del carrusel o menor) que muestre copy breve "No pudimos cargar esta sección" + un botón "Reintentar". Crear un widget reutilizable `lib/ui/pages/new_home/widgets/section_error_retry.dart` con `{ required String message, required VoidCallback onRetry }` y anchors:
     * Botón reintentar de listas: `home-curated-retry`.
     * Botón reintentar de visitas: `home-visits-retry`.
   - `onRetry` debe re-disparar la carga del cubit correspondiente (p.ej. `context.read<CuratedListsCubit>().load()` / el método de carga existente — verificar su nombre real en el cubit). No inventar métodos: usar el que ya exista para la carga inicial.
   - El caso `Loaded` con lista **vacía** SE MANTIENE oculto (`SizedBox.shrink()`) — es UX intencional no llenar el home de secciones vacías. Solo los `*Failure` ganan el retry.

5. **B5 — Reordenar para reducir fatiga y subir intención**:
   - Mover el bloque **"Cerca de ti"** (header + carrusel, el `if (widget.nearbyList.isNotEmpty)`) para que aparezca **inmediatamente después** del `ContextualSectionCard` ("HOY EN…") y **antes** de `CanarianSpecialtiesSection`. Nuevo orden:
     1. Hero → 2. Search → 3. LocationPromptBanner → 4. OpenNowCallout → 5. ContextualSectionCard → **6. Cerca de ti** → 7. Especialidades → 8. Guías → 9. Últimas Visitas → 10. padding.
   - Esto rompe la racha de 4 carruseles seguidos y front-loadea la sección geolocalizada cuando hay ubicación.
   - Añadir anchors `Semantics(identifier:)` a los contenedores de sección para poder testear el orden: `home-section-nearby` (envuelve header+carrusel de Cerca de ti) y `home-section-specialties` (envuelve Especialidades). Usar `identifier`, nunca `label`.

6. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/`.
   - Diseño de los cards aprobados (CardHorizontal, CardVisit, CardCuratedList, CardNearbyMinimap, OpenNowCallout, ContextualSectionCard) — solo su POSICIÓN/spacing externo.
   - La lógica de qué secciones se muestran (los guards `showTodaySection`, `nearbyList.isNotEmpty`, etc.).
   - El Hero ni el parallax.
   - Los cubits (solo invocar su método de carga existente en el retry).

TESTS OBLIGATORIOS:

- **Widget** `test/ui/components/section_header_touch_target_test.dart` (B3):
  * Montar `SectionHeader(title:'X', actionLabel:'VER', onAction: () {})`.
  * `tester.getSize(find.byWidgetPredicate(...identifier=='section-header-cta'))` → `height >= 44.0` y `width >= 44.0`.
  * Tap sobre el anchor sigue invocando `onAction` (no romper B/A).

- **Widget** `test/ui/pages/new_home/section_error_retry_test.dart` (B4):
  * Montar `SectionErrorRetry(message:'...', onRetry: spy)`.
  * Verifica que renderiza el mensaje y un botón con anchor parametrizable; tap → `onRetry` invocado (contador==1).
  * (Opcional, si viable) montar la sección de listas con un `CuratedListsCubit` en estado `Failure` y verificar anchor `home-curated-retry` presente; tap re-dispara la carga.

- **Widget** `test/ui/pages/new_home/section_order_test.dart` (B5):
  * Montar `NewHomeBody` (o harness mínimo) con `nearbyList` no vacío.
  * Localizar anchors `home-section-nearby` y `home-section-specialties`.
  * Assert `tester.getTopLeft(nearby).dy < tester.getTopLeft(specialties).dy` (Cerca de ti va por encima de Especialidades).
  * Si montar `NewHomeBody` completo es inviable, documentar y testear el orden con un harness que monte solo esos dos sub-bloques en el orden nuevo.

- **B1/B2** se verifican por **code-review del Evaluator**: existe `AppSpacing`, los magic numbers de spacing del home se sustituyen por tokens, separador de carruseles unificado a 12.

PROHIBIDO (rechazo automático del Evaluator):

- Dejar magic numbers de spacing duplicados en `new_home_body.dart`/`section_header.dart` cuando ya existe el token equivalente en `AppSpacing`.
- Mostrar secciones VACÍAS (Loaded con 0 items) — solo los Failure ganan UI; los vacíos siguen ocultos.
- Inventar métodos de cubit en el retry — usar el método de carga real existente.
- Romper el diseño de los cards o del Hero.
- `Semantics(label: ...)` como anchor técnico — siempre `identifier:` kebab-case inglés.
- Tocar `pubspec.yaml`, `ios/`, `android/`.

OUT OF SCOPE (mencionar en informe):

- Tokenizar radios/sombras (Sprint E).
- Cambiar jerarquía tipográfica de los displays (Sprint C).
- Skeleton shimmer (Sprint D).
- Migrar OTRAS pantallas (mapa, listas, perfil) a `AppSpacing` — solo el home en este sprint; el resto puede adoptarlo después.

ENTREGA:

1. Diff con:
   - `lib/config/app_spacing.dart` (NUEVO).
   - `lib/ui/components/section_header.dart` (tokens + touch target 44pt).
   - `lib/ui/pages/new_home/widgets/section_error_retry.dart` (NUEVO).
   - `lib/ui/pages/new_home/new_home_body.dart` (tokens, separadores unificados, error+retry en Failure, reorden Cerca de ti, anchors de sección).
   - 3 ficheros de test nuevos.
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/ui/components/section_header_touch_target_test.dart test/ui/pages/new_home/section_error_retry_test.dart test/ui/pages/new_home/section_order_test.dart` al 100%.
4. Informe del Evaluator confirma: tokens aplicados (B1), ritmo vertical homogéneo (B2), CTA ≥44pt (B3), Failure con retry funcional (B4), "Cerca de ti" por encima de Especialidades (B5).

Diff objetivo ≤ 450 líneas (incl. tests). Si crece, priorizar B3+B4+B5 (impacto de uso) y dejar la tokenización exhaustiva B1/B2 para iteración siguiente (mencionar en informe).
