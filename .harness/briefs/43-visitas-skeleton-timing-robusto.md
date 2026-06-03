Pantalla **Visitas** (`lib/ui/pages/visitas/visitas_screen.dart`). Tarea: **hacer la pantalla robusta al timing del `userId`** para que NUNCA se quede atascada en el skeleton (barras grises) en un arranque en frío (TestFlight). Cliente-puro, cambio mínimo, **un solo fichero**. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `VisitasScreen`.

Ficheros a tocar: **sólo** `lib/ui/pages/visitas/visitas_screen.dart`.

---

PROBLEMA ESTRUCTURAL (verificado leyendo el código):

- Los 5 tabs (EXPLORA·LISTAS·MAPA·VISITAS·PERFIL) viven en un `IndexedStack` en `new_home_tab_scaffold.dart` → **todos los `initState` corren en el arranque de la app**, no al tocar el tab. Visitas = índice **3**, Perfil = índice **4**.
- En `VisitasScreen._resolveUserIdAndLoad()`: lee `UserCubit.state` (si `UserLoaded` → `userId`), si no, cae a `FlutterSecureStorage().read(key: 'userId')` (Keychain). Sólo si hay `userId` llama `UserVisitsCubit.load(userId)`.
- `UserCubit` hidrata de forma **asíncrona** (`getUserInfo` con timeout 15s emite `UserLoaded`). En el instante del arranque suele estar en `UserInitial`.
- Si en ese momento el Keychain tampoco devuelve `userId` a tiempo (arranque frío en TestFlight), `load()` **no se llama nunca** → `UserVisitsCubit` queda en `UserVisitsInitial` → la pantalla pinta `_SkeletonList` (barras grises) **para siempre**. En local hay sesión caliente (Keychain ya tiene `userId` / hot-restart preserva `UserCubit`) → carga bien; por eso "en local se ve".
- **No es ATS, ni fotos, ni HTTPS** — es **timing del `userId` + falta de reintento/listener**.

ESTADO ACTUAL DEL FICHERO (ya parcialmente arreglado en commit previo `9faed9d`, dar por hecho que está así):
- Campos `bool _loadTriggered = false;` y `bool _noSession = false;`.
- `_resolveUserIdAndLoad()` ya: resuelve `userId` (UserCubit → Keychain), si hay → `_loadTriggered = true`, limpia `_noSession`, llama `load()`; si NO hay → `setState(() => _noSession = true)`.
- `build` ya envuelve el `BlocBuilder<UserVisitsCubit>` en un `BlocListener<UserCubit, UserState>` cuyo `listener` llama `_resolveUserIdAndLoad()` cuando `userState is UserLoaded && !_loadTriggered`.
- Ya existe `_NoSessionBody` (icono `lock_outline` + "Inicia sesión para ver tus visitas" + `Semantics(identifier: 'visitas-login-cta')` → `MenuCubit.updateSelectedIndex(4)`), y el `builder` muestra `_NoSessionBody` cuando `_noSession && state is UserVisitsInitial`.

---

CONTRATO FUNCIONAL (lo que FALTA — añadir, sin romper lo anterior):

**Re-resolver al hacerse visible el tab** (mismo patrón que ya usa el Mapa con `MenuCubit`), no sólo en `initState`/listener de `UserCubit`:

1. Añadir constante `static const int _kVisitasTabIndex = 3;` en el `State`.
2. Envolver el árbol existente (el `BlocListener<UserCubit>`) con un **`BlocListener<MenuCubit, MenuState>`**:
   ```dart
   BlocListener<MenuCubit, MenuState>(
     listenWhen: (prev, curr) => prev.selectedIndex != curr.selectedIndex,
     listener: (_, state) {
       if (state.selectedIndex == _kVisitasTabIndex && !_loadTriggered) {
         _resolveUserIdAndLoad();
       }
     },
     child: /* el BlocListener<UserCubit, UserState> actual */,
   )
   ```
   - Import necesario: `package:guachinches/data/cubit/menu/menu_cubit.dart` (ya importado para `MenuCubit`; `MenuState` vive en el mismo fichero).
   - `MenuState` expone `final int selectedIndex;`. `MenuCubit` arranca en `selectedIndex: 0`.
3. Resultado: si el `userId` no estaba listo en el arranque, en cuanto el usuario **toca el tab Visitas** (o el `UserCubit` emite `UserLoaded`, lo que ocurra primero) se reintenta la carga. `_loadTriggered` evita disparos duplicados.

Comportamiento esperado tras el fix:
- **Con sesión caliente**: idéntico a hoy (carga directa).
- **Arranque frío con sesión válida**: aunque el `initState` no consiga `userId`, al resolverse `UserCubit` o al entrar al tab se dispara `load()` → ya no hay skeleton perpetuo.
- **Sin sesión real**: `_NoSessionBody` ("inicia sesión para ver tus visitas") en vez de skeleton infinito.

---

NO MODIFICAR / NO ROMPER:
- La UI de `_LoadedBody`, `_EmptyBody`, `_ErrorBody`, `_SkeletonList`/`_SkeletonCard`, `_NoSessionBody` — sin cambios (salvo que el wrapper nuevo no altere su render).
- Los anchors existentes: `visitas-screen-root`, `visitas-refresh-indicator`, `visitas-list`, `visitas-card-<id>`, `visitas-empty-cta`, `visitas-retry-button`, `visitas-login-cta` — intactos.
- `_resolveUserIdAndLoad()` ya existente — reutilizarla, no duplicar la lógica de resolución de `userId`.
- `UserCubit`/`UserVisitsCubit`/`MenuCubit`, sus estados, el modelo, `pubspec.yaml`, `ios/`, `android/`, `main.dart`, `new_home_tab_scaffold.dart` — **no tocar**.

PROHIBIDO (rechazo automático del Evaluator):
- Dejar que la pantalla pueda quedarse en `_SkeletonList` indefinidamente sin sesión (debe caer a `_NoSessionBody`).
- Disparar `load()` en bucle / sin guard `_loadTriggered` (re-fetch infinito).
- Mover lógica a otros ficheros, tocar cubits/presenter/scaffold, `pubspec.yaml`/`ios/`/`android/`/`main.dart`.
- Tests de widget que monten `VisitasScreen`. `Semantics(label:)` como anchor técnico.
- Strings hardcodeadas nuevas más allá del copy ya existente del `_NoSessionBody`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/visitas/visitas_screen.dart`: sin nuevos warnings/errores (se permiten `info` preexistentes).
- Confirmar por diff: `_kVisitasTabIndex = 3`; `BlocListener<MenuCubit, MenuState>` con `listenWhen` por `selectedIndex` que reintenta `_resolveUserIdAndLoad()` cuando se entra al tab y `!_loadTriggered`; el `BlocListener<UserCubit>` y `_NoSessionBody` previos intactos; guard `_loadTriggered` respetado.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Migrar el copy del `_NoSessionBody` a l10n (hoy hay strings hardcodeadas en `_EmptyBody`/`_ErrorBody` también): follow-up.
- Rediseño visual del skeleton o de las tarjetas de visita.

ENTREGA:
1. Diff de `visitas_screen.dart` (re-resolución por visibilidad del tab vía `MenuCubit`).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando la robustez al timing del `userId`.

Diff objetivo ≤ 15 líneas.
