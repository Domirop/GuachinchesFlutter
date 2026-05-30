Resolver el **grupo D (estados de carga)** de la auditoría UI/UX del home. Tres defectos alrededor del `OpenNowCallout` ("ABIERTOS CERCA AHORA"): (D1) no tiene skeleton de carga, (D2) durante `bootstrapLoading` muestra el estado vacío count=0 ("Sin abiertos cerca · Abren pronto"), afirmando prematuramente que no hay nada cuando en realidad aún está cargando, y (D3) cuando no hay permisos de ubicación el callout coexiste con el `LocationPromptBanner` justo encima, duplicando mensajería en la zona superior. Scope: home (tab 0), `new_home_body.dart`, `open_now_callout.dart`, `skeletons.dart`, y un nuevo widget "slot".

CONTEXTO ACTUAL (verificado a mano):

- **Ya existe infraestructura de shimmer** en `lib/ui/pages/new_home/widgets/skeletons.dart`: `_Shimmer` (StatefulWidget con `AnimationController` 1200ms repeat reverse, opacity 0.06→0.18 sobre `AppColors.crema`), `CardRowSkeleton` (3 cards 200×200), `RankingRowSkeleton`. Los carruseles ya usan `CardRowSkeleton` mientras cargan (new_home_body :233 bootstrap, :377 listas, :430 visitas). **El skeleton existe — D1 es extenderlo al callout, no crearlo de cero.**

- **`OpenNowCallout`** (`lib/ui/components/open_now_callout.dart`):
  * Recibe `{ required int count, required String contextLabel, VoidCallback? onTap }`.
  * `hasOpen = count > 0`. Si `count == 0` → estado vacío: eyebrow "ABRE PRONTO · {ZONA}", headline "Sin abiertos cerca", support "Abren a lo largo del día", accent `AppColors.sol`, SIN LiveDot. Anchor `home-cerca-ahora-cta`.
  * No tiene ninguna noción de "cargando" — con count=0 SIEMPRE pinta el estado vacío.

- **`new_home_body.dart`**:
  * `:193` `const SliverToBoxAdapter(child: LocationPromptBanner())` — el banner se auto-oculta salvo en estados `LocationDenied` (y sub-tipos `LocationPermanentlyDenied`, `LocationServiceDisabled`); en `LocationLoaded`/`LocationInitial`/`LocationUnavailable` no renderiza nada (ver `location_prompt_banner.dart`).
  * `:199-210` `OpenNowCallout(count: openNow.length, contextLabel: zoneLabel, onTap: → CercaAhoraScreen)`. **Se renderiza SIEMPRE**, incluso durante `widget.bootstrapLoading` (donde `openNow` está vacío → count=0 → estado vacío falso, D2) y aunque no haya permiso de ubicación (a la vez que el banner, D3).
  * `openNow` = `filterOpenNow(pool)` — filtra por estado abierto del pool de la isla/zona, NO por GPS. Es válido sin ubicación, pero "abiertos CERCA" + el banner de "Activar ubicación" juntos saturan la zona superior.

- **`LocationCubit` / `LocationState`** (`lib/data/cubit/location/`): estados `LocationInitial`, `LocationLoading`(si existe), `LocationLoaded`, `LocationDenied` (base) + sub-tipos `LocationPermanentlyDenied extends LocationDenied`, `LocationServiceDisabled extends LocationDenied`, y `LocationUnavailable`. `LocationCubit` ya está provided globalmente (lo consume `LocationPromptBanner`).

CONTRATO FUNCIONAL:

1. **D1 — Skeleton del callout** (`skeletons.dart`):
   - Crear `OpenNowCalloutSkeleton extends StatelessWidget` que reproduzca la SILUETA del `OpenNowCallout` (mismo `margin: EdgeInsets.fromLTRB(16,12,16,4)`, mismo `borderRadius:16`, banda lateral izquierda de 4px, y dentro filas shimmer: una barra fina para el eyebrow, una barra media para el headline, una barra corta para el support). Reusar `_Shimmer` (hacerlo accesible: si hoy es privado al fichero, está bien porque el skeleton vive en el MISMO `skeletons.dart`). Banda lateral en un gris neutro/`context.brand.border` (no verde ni sol — no anticipar resultado).
   - NO LiveDot, NO chevron, NO tappable (sin `GestureDetector`).
   - Anchor `Semantics(identifier: 'home-cerca-ahora-skeleton')`.

2. **D2 + D3 — "Slot" que decide skeleton / oculto / real** (NUEVO `lib/ui/pages/new_home/widgets/open_now_callout_slot.dart`):
   - `OpenNowCalloutSlot extends StatelessWidget` con `{ required bool bootstrapLoading, required int count, required String contextLabel, VoidCallback? onTap }`.
   - Lógica de `build`:
     ```
     if (bootstrapLoading) return const OpenNowCalloutSkeleton();   // D2: nunca count-copy durante carga
     final loc = context.watch<LocationCubit>().state;             // (o BlocBuilder)
     if (loc is LocationDenied) return const SizedBox.shrink();    // D3: el banner cubre la zona; no duplicar
     return OpenNowCallout(count: count, contextLabel: contextLabel, onTap: onTap);
     ```
   - `LocationDenied` cubre sus 3 sub-tipos por herencia (base, PermanentlyDenied, ServiceDisabled) → en cualquiera de ellos el banner ya está visible y el callout se oculta.
   - En `LocationLoaded` y `LocationUnavailable` (permiso concedido aunque sin fix GPS) el callout REAL se muestra: los datos son por isla/zona, no por GPS, así que siguen siendo válidos.
   - En `LocationInitial` el callout real se muestra solo si NO estamos en bootstrap (durante bootstrap ya cae en el skeleton). Si el equipo prefiere ocultar también en Initial, documentarlo; el criterio mínimo es: bootstrap→skeleton, Denied→oculto, Loaded→real.

3. **Cablear el slot en `new_home_body.dart`**:
   - Reemplazar el bloque `:199-210` (el `OpenNowCallout` directo) por:
     ```dart
     SliverToBoxAdapter(
       child: OpenNowCalloutSlot(
         bootstrapLoading: widget.bootstrapLoading,
         count: openNow.length,
         contextLabel: zoneLabel,
         onTap: () => Navigator.push(context,
           MaterialPageRoute(builder: (_) => const CercaAhoraScreen())),
       ),
     ),
     ```
   - No cambiar el `LocationPromptBanner` de `:193` ni su lógica.

4. **NO MODIFICAR**:
   - `pubspec.yaml`, `ios/`, `android/` — NO añadir el paquete `shimmer`; reusar el `_Shimmer` propio que ya existe.
   - El diseño visual del `OpenNowCallout` real (count/eyebrow/LiveDot/headline) — sólo se le añade el SLOT por delante; el callout en sí no cambia su API ni su look.
   - `LocationCubit`/`LocationState` ni `LocationPromptBanner`.
   - El resto de skeletons (`CardRowSkeleton`, `RankingRowSkeleton`) y su uso en los carruseles — ya funcionan.

TESTS OBLIGATORIOS:

- **Widget** `test/ui/components/open_now_callout_skeleton_test.dart` (D1):
  * Montar `OpenNowCalloutSkeleton` bajo `MaterialApp(theme: appLightTheme, darkTheme: appDarkTheme)`.
  * Verifica anchor `home-cerca-ahora-skeleton` presente.
  * NO renderiza copy de estado: `find.text('Sin abiertos cerca')` → `findsNothing`; `find.textContaining('abiertos')` → `findsNothing`.
  * No es accionable: no hay `Icons.arrow_forward_rounded`.

- **Widget** `test/ui/pages/new_home/open_now_callout_slot_test.dart` (D2 + D3):
  * Usar un fake `LocationCubit` con estado fijo (patrón del `location_prompt_banner_test.dart`: `_FakeLocationCubit extends Cubit<LocationState> implements LocationCubit`). Envolver en `BlocProvider<LocationCubit>.value`.
  * (a) `bootstrapLoading: true` (cualquier estado de ubicación) → muestra `home-cerca-ahora-skeleton`, NO `home-cerca-ahora-cta`. **(D2)**
  * (b) `bootstrapLoading: false`, estado `LocationDenied()` → `home-cerca-ahora-cta` `findsNothing` y `home-cerca-ahora-skeleton` `findsNothing` (slot vacío). **(D3)**
  * (c) `bootstrapLoading: false`, estado `LocationPermanentlyDenied()` → también oculto (cubre sub-tipo). **(D3)**
  * (d) `bootstrapLoading: false`, estado `LocationLoaded(latitude:28, longitude:-16)`, `count: 5` → `home-cerca-ahora-cta` visible y muestra "5 sitios abiertos cerca".
  * (e) `bootstrapLoading: false`, estado `LocationUnavailable()`, `count: 3` → callout real visible (permiso concedido sin GPS, datos por isla válidos).

PROHIBIDO (rechazo automático del Evaluator):

- Añadir el paquete `shimmer` u otra dependencia a `pubspec.yaml` — reusar `_Shimmer` existente.
- Que el callout muestre count-copy (count=0 "Sin abiertos cerca" o cifras) durante `bootstrapLoading`.
- Que el callout y el `LocationPromptBanner` se rendericen simultáneamente en estados `LocationDenied` (cualquiera de los 3 sub-tipos).
- Cambiar la API o el look del `OpenNowCallout` real.
- Tocar `LocationCubit`/`LocationState`/`LocationPromptBanner`.
- `Semantics(label: ...)` como anchor técnico — siempre `identifier:` kebab-case inglés.

OUT OF SCOPE (mencionar en informe):

- Skeletons para el Hero o la barra de búsqueda (no es scope; el Hero ya tiene su placeholder).
- Migrar a un paquete de shimmer externo.
- Cambiar el comportamiento de `LocationPromptBanner` (es de un sprint anterior y está cubierto por sus tests).
- Estados de error de red del callout (no aplica: el callout no hace fetch propio, deriva de `pool`).

ENTREGA:

1. Diff con:
   - `lib/ui/pages/new_home/widgets/skeletons.dart` (+ `OpenNowCalloutSkeleton`).
   - `lib/ui/pages/new_home/widgets/open_now_callout_slot.dart` (NUEVO).
   - `lib/ui/pages/new_home/new_home_body.dart` (cablea el slot en :199-210; añadir import del slot; quitar el import directo de `OpenNowCallout` si ya no se usa aquí).
   - 2 ficheros de test nuevos.
2. `flutter analyze` limpio en ficheros nuevos/modificados.
3. `flutter test test/ui/components/open_now_callout_skeleton_test.dart test/ui/pages/new_home/open_now_callout_slot_test.dart test/ui/components/open_now_callout_test.dart` al 100% (incluir el test existente del callout para confirmar que no se rompió).
4. Informe del Evaluator confirma: skeleton del callout durante bootstrap (D1), nunca count-copy en carga (D2), callout oculto cuando el banner de permisos está visible (D3).

Diff objetivo ≤ 350 líneas (incl. tests).
