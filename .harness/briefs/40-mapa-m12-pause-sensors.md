Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M12 (de la serie M1…M13, uno por harness)**: **pausar los sensores cuando el tab Mapa no está visible**. El Mapa vive en un `IndexedStack` (5 tabs) → **permanece montado** aunque el usuario esté en otro tab, así que su `Geolocator.getPositionStream` (alta precisión, `distanceFilter: 5`) **sigue consumiendo GPS/batería** en segundo plano aunque nadie mire el mapa. M12 = **suspender el stream de posición (y, por tanto, el `_DrivingDetector` que se alimenta de él) mientras el tab Mapa no es el visible**, y **reanudarlo** al volver. Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- Visibilidad del tab = `MenuCubit.state.selectedIndex == _kMapTabIndex` (`_kMapTabIndex = 2`). Ya hay un `BlocListener<MenuCubit, MenuState>` en `build` (~líneas 672-683) que SÓLO marca `_mapMounted=true` la primera vez que el mapa se hace visible:
  ```dart
  return BlocListener<MenuCubit, MenuState>(
    listenWhen: (prev, curr) =>
        !_mapMounted && curr.selectedIndex == _kMapTabIndex,
    listener: (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mapMounted) return;
        setState(() => _mapMounted = true);
      });
    },
    child: BlocListener<NewHomeFiltersCubit, NewHomeFiltersState>(... _buildScaffold ...),
  );
  ```
- `initState` (~líneas 125-135) hace **incondicionalmente** `_startLiveLocation();` y luego, aparte, `if (menu.state.selectedIndex == _kMapTabIndex) _mapMounted = true;`. → el GPS arranca aunque el usuario abra la app en otro tab.
- `_startLiveLocation()` (~302): chequea servicio/permiso y hace `_locationSubscription = Geolocator.getPositionStream(LocationSettings(accuracy: high, distanceFilter: 5)).listen(_onPositionUpdate);`. **No** comprueba si ya hay una suscripción (riesgo de doble-suscripción si se llama dos veces).
- `_onPositionUpdate` (~326) hace `setState` (currentLocation/_hasUserLocation), `_driving.onPosition(position)` y mueve la cámara. → El `_DrivingDetector` (clase ~1133) es **puramente position-driven**: NO tiene timers propios; sólo avanza cuando llega `onPosition`. Por tanto, **cortar el stream lo congela** (no requiere pausa aparte). Tiene `_samples`/`_lastPos` (ventana móvil) y `currentSpeed`.
- `dispose()` (~211) ya hace `_locationSubscription?.cancel()`.

---

CONTRATO FUNCIONAL (sólo M12):

1. **Guard anti-doble-suscripción** en `_startLiveLocation()`: al principio (antes de los chequeos async, o justo antes de asignar `_locationSubscription`), `if (_locationSubscription != null) return;`.

2. **Arranque condicional en `initState`**: mover el `_startLiveLocation();` para que **sólo** se llame si el tab inicial es el Mapa. Es decir, sustituir el `_startLiveLocation();` suelto por arrancarlo dentro del bloque que ya detecta el tab inicial:
   ```dart
   _driving.isDriving.addListener(_onDrivingChanged);
   _driving.shouldSuggest.addListener(_onDriveSuggested);
   _buildDotIcons();

   final menu = context.read<MenuCubit>();
   if (menu.state.selectedIndex == _kMapTabIndex) {
     _mapMounted = true;
     _startLiveLocation();
   }
   ```
   (Si la app arranca en otro tab, el GPS no se enciende hasta que el usuario abra el Mapa — lo hará el listener del paso 4.)

3. **Nuevo método** `_setSensorsActive(bool active)` en `MapSearchState`:
   ```dart
   void _setSensorsActive(bool active) {
     if (active) {
       _startLiveLocation(); // guard interno evita doble-suscripción
     } else {
       _locationSubscription?.cancel();
       _locationSubscription = null;
       _driving.onPaused();
     }
   }
   ```

4. **Ampliar el `BlocListener<MenuCubit>`** de `build` para pausar/reanudar en cada cambio de tab (manteniendo el comportamiento de `_mapMounted`):
   ```dart
   return BlocListener<MenuCubit, MenuState>(
     listenWhen: (prev, curr) => prev.selectedIndex != curr.selectedIndex,
     listener: (_, state) {
       final onMap = state.selectedIndex == _kMapTabIndex;
       if (onMap) {
         if (!_mapMounted) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (!mounted || _mapMounted) return;
             setState(() => _mapMounted = true);
           });
         }
         _setSensorsActive(true);
       } else {
         _setSensorsActive(false);
       }
     },
     child: BlocListener<NewHomeFiltersCubit, NewHomeFiltersState>(...),
   );
   ```

5. **Nuevo método** `onPaused()` en `_DrivingDetector` (limpia la ventana móvil para evitar artefactos de delta al reanudar; NO toca `isDriving`/`shouldSuggest`/cooldown):
   ```dart
   void onPaused() {
     _samples.clear();
     _lastPos = null;
     currentSpeed.value = 0;
   }
   ```

---

NO MODIFICAR / NO ROMPER:
- La semántica de `_DrivingDetector` (umbrales, cooldown, `isDriving`/`shouldSuggest`, `forceExit`, `confirmDrive`, `dismissSuggestion`) — sólo se AÑADE `onPaused()`.
- `_onPositionUpdate`, `_animateToUser`, la cámara, los markers, el carrusel, los filtros cliente (M11), empty-state (M8), padding (M7), scrim (M6), etc. M1-M11 intactos.
- `dispose()` sigue cancelando la suscripción (no cambia).
- El modelo, cubits, presenter, `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M12 **NO** toca: marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Dejar el `getPositionStream` activo cuando el tab Mapa no es el visible.
- Doble-suscripción (arrancar un segundo stream sin cancelar el anterior) → fuga.
- Arrancar el GPS en `initState` aunque el tab inicial no sea el Mapa.
- Resetear/forzar salida del modo coche al pausar (sólo `onPaused()` limpia la ventana de muestras; `isDriving` se conserva).
- Tocar otros M's, cubits/presenter (firmas), `pubspec.yaml`/`ios/`/`android/`/`main.dart`. Tests de widget que monten `MapSearch`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: guard `if (_locationSubscription != null) return;` en `_startLiveLocation`; `_startLiveLocation` en `initState` sólo si el tab inicial es el Mapa; `_setSensorsActive(bool)`; `BlocListener<MenuCubit>` reacciona a cualquier cambio de `selectedIndex` y llama `_setSensorsActive(onMap)` preservando `_mapMounted`; `_DrivingDetector.onPaused()` añadido.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Pausar también en `AppLifecycleState.paused` (app en segundo plano) vía `WidgetsBindingObserver`: follow-up complementario (M12 cubre la visibilidad de tab dentro del IndexedStack, que es el agujero principal de batería con la app en primer plano).

ENTREGA:
1. Diff de `map_search.dart` (pausa/reanuda sensores por visibilidad de tab).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M12.

Diff objetivo ≤ 40 líneas.
