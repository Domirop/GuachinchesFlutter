Resolver el **grupo A (blockers)** de la auditoría de las pantallas de detalle que se abren desde el home. Dos defectos independientes, ambos confirmados a mano:

- **A1 — `RestaurantDetailScreen` se queda en spinner infinito si falla la carga**. Es la pantalla más visitada y la ÚNICA de las 4 de detalle sin estado de error.
- **A2 — `CuratedListDetailScreen` muta un static global (`AppTextStyles.defaultTextColor`) durante `build`**, sin restaurarlo → la fuga contamina el color de texto por defecto del resto de la app (dark mode) tras visitar una lista.

Scope de ficheros: `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`, `lib/ui/pages/curated_list_detail/curated_list_detail_screen.dart`, y un nuevo test de widget para A1.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**A1 — spinner infinito:**
- `restaurant_detail_screen.dart:38-39`: el State `implements DetailView`. Campos `:44-49`: `Restaurant? _restaurant`, `bool _loading = true`, etc.
- `:61-70` `initState`: crea `_repo = HttpRemoteRepository(http.Client())` (`:63`), `_presenter = DetailPresenter(_repo, this)` (`:64`), y dispara `_presenter.getRestaurantById(widget.id)` (`:65`, **sin await, sin try/catch**), más `getIsFav`, `_loadVisits`, `_loadListAppearances`.
- `details_presenter.dart:44-45`: `getRestaurantById` hace `Restaurant restaurant = await _remoteRepository.getRestaurantById(id);` **en la primera línea, FUERA de cualquier try/catch**. Si ese await lanza (red caída, 500, timeout), la excepción se propaga como error async no capturado y `_view.setRestaurant(...)` (`:85`) NUNCA se llama.
- `restaurant_detail_screen.dart:170-177` `setRestaurant` es lo único que pone `_loading = false`. Si nunca se llama → `_loading` queda `true` por siempre.
- `:226-252` `build`: `if (_loading || r == null) const _DetailSkeleton() else _buildScrollContent()`. `_DetailSkeleton` (`:375-397`) es sólo un `CircularProgressIndicator` + "Cargando…". **No hay rama de error ni reintento** → spinner eterno.
- Las otras 3 pantallas de detalle SÍ tienen estado de error con reintento (referencia de estilo: `curated_list_detail_screen.dart:684-753` `_ErrorView` con `_IconChip` back + icono `cloud_off` + botón "Reintentar").

**A2 — mutación de static global en build:**
- `curated_list_detail_screen.dart:33-58`: `_LightTheme` es `StatelessWidget`. En su `build`, dentro de un `Builder` (`:50-54`), ejecuta **`AppTextStyles.defaultTextColor = AppColors.ink;`** (`:52`) como efecto secundario en cada construcción.
- `app_text_styles.dart:33`: `static Color defaultTextColor = AppColors.crema;` es un **global mutable**. Los helpers `displayHero/displaySection/chipLabel/ui` (`:69,78,96,121`) lo usan como fallback `color ?? defaultTextColor`, y los getters `_eyebrowColor/_editorialColor/_mutedColor` (`:37-50`) ramifican según si `defaultTextColor == AppColors.crema` (dark) o no (light).
- El comentario `:30-32` dice que **sólo el ThemeCubit** debe tocar `defaultTextColor`, y sólo en cambio de modo. Como `_LightTheme` lo pone a `ink` y nadie lo restaura al salir, tras visitar una lista curada en dark mode todo el texto sin color explícito de la app queda `ink` (oscuro) sobre fondos oscuros → casi invisible, hasta el siguiente toggle de tema. **Fuga global confirmada.**
- `_LightTheme` YA aporta correctamente `BrandColors.light` vía `Theme(extensions: [...])` (`:41-43`); eso está bien y se mantiene. El problema es EXCLUSIVAMENTE la mutación no-restaurada del global.

---

CONTRATO FUNCIONAL:

**1. A1 — Estado de error con reintento en `RestaurantDetailScreen`:**

- **Inyectabilidad para test** (mínima y aditiva): añadir un parámetro opcional al constructor del widget:
  ```dart
  final String id;
  final RemoteRepository? repository; // null en prod → usa HttpRemoteRepository real
  const RestaurantDetailScreen({super.key, required this.id, this.repository});
  ```
  En `initState`: `_repo = widget.repository ?? HttpRemoteRepository(http.Client());`. Importar `package:guachinches/data/RemoteRepository.dart`. NO cambiar ninguna llamada existente al constructor (el param es opcional).

- **Nuevo estado** `bool _error = false;` junto a `_loading`.

- **Extraer la carga del restaurante** a un método con try/catch:
  ```dart
  Future<void> _loadRestaurant() async {
    try {
      await _presenter.getRestaurantById(widget.id);
    } catch (e, st) {
      AppLogger.error('restaurant-detail', e, st);
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }
  ```
  En `initState` reemplazar la llamada suelta `_presenter.getRestaurantById(widget.id);` (`:65`) por `_loadRestaurant();`. Mantener `getIsFav`, `_loadVisits`, `_loadListAppearances` igual. Importar `package:guachinches/core/logging/app_logger.dart`.

- **Reintento**:
  ```dart
  void _retryLoad() {
    setState(() { _error = false; _loading = true; });
    _loadRestaurant();
  }
  ```

- **Rama de error en `build`**: ANTES del `Scaffold` normal, si `_error` es true, devolver un Scaffold de error dedicado (sin los `DetailFloatingButtons`/`BottomCtaBar`, porque no hay restaurante):
  ```dart
  if (_error) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: _DetailError(
        onBack: () => Navigator.pop(context),
        onRetry: _retryLoad,
      ),
    );
  }
  ```

- **Nuevo widget privado `_DetailError`** (theme-aware con `context.brand.*`, NADA hardcodeado; mismo lenguaje visual que el `_ErrorView` de curated pero usando tokens de tema, no `AppColors.ink`):
  * `SafeArea` + columna centrada: chip de back arriba-izquierda, icono `Icons.cloud_off_rounded` (color `context.brand.textMuted`), título "No pudimos cargar el restaurante" (`AppTextStyles.displaySection`/`displayHero` con `color: context.brand.textPrimary`), subtítulo corto "Revisa tu conexión e inténtalo de nuevo." (`context.brand.textSecondary`), y botón "Reintentar" (relleno `AppColors.atlantico`, texto blanco) que llama `onRetry`.
  * **Anchors obligatorios** (`Semantics(identifier:)`, kebab-case inglés):
    - raíz de la vista de error: `restaurant-detail-error`
    - botón reintentar: `restaurant-detail-retry-button`
    - chip back: `restaurant-detail-error-back`

**2. A2 — Eliminar la mutación global no-restaurada en `_LightTheme`:**

- Convertir `_LightTheme` de `StatelessWidget` a `StatefulWidget`. En el State:
  * `initState`: guardar el valor previo y setear ink UNA sola vez (antes del primer build, así los `AppTextStyles` lo leen):
    ```dart
    Color? _previousDefault;
    @override
    void initState() {
      super.initState();
      _previousDefault = AppTextStyles.defaultTextColor;
      AppTextStyles.defaultTextColor = AppColors.ink;
    }
    ```
  * `dispose`: restaurar:
    ```dart
    @override
    void dispose() {
      if (_previousDefault != null) {
        AppTextStyles.defaultTextColor = _previousDefault!;
      }
      super.dispose();
    }
    ```
  * `build`: idéntico al actual PERO **sin** la línea `AppTextStyles.defaultTextColor = AppColors.ink;` y **sin** el `Builder` que sólo existía para alojar esa mutación. Devolver directamente:
    ```dart
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(extensions: <ThemeExtension<dynamic>>[BrandColors.light]),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.crema,
        ),
        child: widget.child,
      ),
    );
    ```
  * Resultado: ya NO se muta el global en cada rebuild (sólo una vez en initState) y se restaura al hacer pop → la fuga a dark mode desaparece.

---

NO MODIFICAR:
- `pubspec.yaml`, `ios/`, `android/`.
- `app_text_styles.dart` (el global se mantiene; sólo cambia QUIÉN lo restaura). NO refactorizar `AppTextStyles` para que lea de context — eso es un sprint mayor aparte (mencionar en OUT OF SCOPE).
- `details_presenter.dart` (el fix de A1 vive en el screen, no en el presenter; no tocar el contrato de `DetailView`).
- El look/orden visible de ambas pantallas en su estado normal (cargado). Sólo se añade la rama de error (A1) y se cambia el ciclo de vida del theme (A2).
- Las otras secciones, cubits, `_ToolBar`, `_Hero`, etc. de curated.

---

TESTS OBLIGATORIOS:

- **Widget (A1)** `test/ui/pages/restaurant_detail/restaurant_detail_error_test.dart`:
  * Crear un fake `RemoteRepository` que `implements RemoteRepository` y use `noSuchMethod` para stubear todo lo no usado devolviendo `Future.value()`/valores benignos, salvo `getRestaurantById` que **lanza** (`throw Exception('boom')`). Las llamadas secundarias (`getVisitsByRestaurant`, `getCuratedLists`, etc.) van envueltas en try/catch silenciosos en el screen, así que un stub que devuelva futuros benignos o lance no debe romper el test (se tragan).
  * Si `getIsFav` (vía `sqlLiteLocalRepository` real) provoca errores async por falta de plugin sqflite en el test, el Planner debe resolverlo de forma acotada (p.ej. usar `tester.runAsync` con cuidado, o envolver el bombeo de modo que el error async no capturado no falle el test — documentarlo). El objetivo del test es la rama de error de la CARGA del restaurante, no los favoritos.
  * Test 1: inyectar el repo que lanza → `pumpWidget(MaterialApp(home: RestaurantDetailScreen(id: 'x', repository: throwingRepo)))` → `pumpAndSettle` → `expect(find.bySemanticsLabel(...))` NO; usar el anchor: localizar por `find.byWidgetPredicate` que el `Semantics` con `identifier == 'restaurant-detail-error'` está presente, y que existe el botón `restaurant-detail-retry-button`. El spinner (`_DetailSkeleton`) NO debe estar.
  * Test 2 (reintento): mantener un fake con un flag que la primera vez lanza y la segunda devuelve un `Restaurant` mínimo válido. Tras pintar el error, tocar `restaurant-detail-retry-button`, `pumpAndSettle`, y verificar que el error desaparece (el anchor `restaurant-detail-error` ya no está). Si construir un `Restaurant` válido completo es inviable por dependencias, este test 2 puede quedar `skip: true` con comentario explicando por qué, y dejar el test 1 (error mostrado) como el assert duro.
  * Prohibido `sleep(...)`; usar `pump`/`pumpAndSettle`.

- **A2 se verifica por code-review del Evaluator** (`_LightTheme` es privado; no es importable en aislamiento). El Evaluator confirma leyendo el diff:
  * `_LightTheme` es ahora `StatefulWidget`.
  * NO existe ninguna asignación a `AppTextStyles.defaultTextColor` dentro de `build`.
  * `initState` guarda el valor previo y setea `ink`; `dispose` restaura el valor previo.
  * El `Theme(extensions: [BrandColors.light])` y el `AnnotatedRegion` se conservan.

---

PROHIBIDO (rechazo automático del Evaluator):
- Dejar `RestaurantDetailScreen` sin rama de error (A1 sin resolver) o con el catch del fallo de carga silenciado sin mostrar UI.
- Capturar el error pero seguir mostrando el spinner (debe verse `_DetailError` con reintento).
- Mantener la mutación `AppTextStyles.defaultTextColor = ...` dentro de `build` de `_LightTheme` (A2 sin resolver) o no restaurar el valor en `dispose`.
- Colores hardcodeados (`Colors.white`, `AppColors.ink`...) en `_DetailError` — debe ser theme-aware (`context.brand.*`).
- `Semantics(label:)` como anchor técnico (usar `identifier:`).
- Tocar `pubspec.yaml`, `ios/`, `android/`, `app_text_styles.dart`, `details_presenter.dart`.
- Cambiar el constructor de `RestaurantDetailScreen` de forma no aditiva (el nuevo param debe ser opcional y no romper las llamadas existentes).

OUT OF SCOPE (mencionar en informe, no implementar):
- Refactor de `AppTextStyles` para resolver el color desde `BuildContext`/`Theme` en vez de un global mutable (eliminaría la necesidad del save/restore; sprint mayor aparte).
- Mover el N+1 de `_loadListAppearances`/`_enrichVisits` (es el grupo E performance).
- Inyectar el repo por DI en TODAS las pantallas (E3, otro sprint).
- Skeleton/shimmer en lugar de spinner (grupo C).
- Anchors generales de la pantalla más allá de los del estado de error (grupo D).

ENTREGA:
1. Diff con:
   - `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart` (param repo opcional, `_loadRestaurant` con try/catch, `_error`, `_retryLoad`, rama de error en build, widget `_DetailError` con anchors).
   - `lib/ui/pages/curated_list_detail/curated_list_detail_screen.dart` (`_LightTheme` → Stateful con save/restore, sin mutación en build).
   - `test/ui/pages/restaurant_detail/restaurant_detail_error_test.dart` (NUEVO).
2. `flutter analyze` limpio en los ficheros tocados (los `withOpacity` deprecados preexistentes no cuentan).
3. `flutter test test/ui/pages/restaurant_detail/restaurant_detail_error_test.dart` al 100% (test 2 puede ir `skip`).
4. Informe del Evaluator confirma A1 (error+reintento visibles bajo fallo de carga) y A2 (sin mutación global en build, restaurado en dispose).

Diff objetivo ≤ 280 líneas (incl. test).
