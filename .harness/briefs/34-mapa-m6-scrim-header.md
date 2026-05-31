Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M6 (de la serie M1…M13, uno por harness)**: **scrim/gradient detrás del header**. Hoy el header (`_MapHeader`: barra de búsqueda + fila de quick-pills) flota directamente sobre el `GoogleMap`. La barra y las pills tienen fondo opaco propio, pero **los huecos** (zona de status bar por encima de la barra, espacios entre pills, bordes) dejan que **los markers y labels del mapa se cuelen** detrás del header, restando legibilidad y separación visual. Añadir un **gradiente sutil** (color de fondo de la app arriba → transparente abajo) **detrás del header** para crear contraste y separar el header del mapa. Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- `_MapHeader.build` (~línea 2046) empieza así:
  ```dart
  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          ...
  ```
  El header se monta en `Positioned(top:0, left:0, right:0, child: _MapHeader(...))` (~línea 801) sobre el `Positioned.fill(GoogleMap(...))`.
- `brand.base` es el color de fondo de la app (token dual-theme, ya disponible vía `context.brand`).
- Patrón de scrim ya usado en el fichero: `_DriveNearbyStripState` pinta un `LinearGradient` `[brand.base, brand.base.withOpacity(0.0)]` (M5). Reusar el mismo lenguaje.

---

CONTRATO FUNCIONAL (sólo M6):

1. **Envolver el contenido del header en un `Container` con gradiente** que vaya de un fondo semi-opaco arriba a transparente abajo, **por encima del `SafeArea`** para que cubra también la zona de status bar:
   ```dart
   return Container(
     decoration: BoxDecoration(
       gradient: LinearGradient(
         begin: Alignment.topCenter,
         end: Alignment.bottomCenter,
         colors: [
           brand.base.withOpacity(0.92),
           brand.base.withOpacity(0.0),
         ],
       ),
     ),
     child: SafeArea(
       bottom: false,
       child: Padding(
         padding: const EdgeInsets.fromLTRB(12, 8, 12, 16), // bottom 0 → 16: deja que el gradiente se difumine por debajo de las pills
         child: Column( ... ),  // contenido actual sin cambios
       ),
     ),
   );
   ```
   - El gradiente auto-dimensiona a la altura intrínseca del header (barra+pills), así que **funciona también en modo coche** (menos contenido = scrim más corto) sin cálculos de altura.
   - Subir el `bottom` del `Padding` de `0` a `16` para dar margen de difuminado por debajo de la última fila de pills (ajuste fino aceptable; no toca el resto del padding).

2. **No tapar taps del mapa:** el gradiente NO debe interceptar gestos en su zona transparente inferior. Como el `Container` envuelve sólo el header (cuya altura es la del contenido) y el header ya estaba en un `Positioned(top:0)` que NO es `fill`, el área del gradiente coincide con el header — no se extiende sobre el resto del mapa. Verificar que NO se añade `Positioned.fill` ni se agranda el área tappable. (Si el Evaluator detecta riesgo de bloqueo de taps, envolver el `Container` en `IgnorePointer`-NO — porque el header SÍ necesita recibir taps en search/pills; basta con que el `Container` ciña el contenido.)

---

NO MODIFICAR / NO ROMPER:
- El contenido del header (search bar, `_QuickPill`s, chip de isla, sus anchors de M3, el selector de M2) — sólo se **envuelve**, no se reordena ni re-estiliza.
- El `Positioned(top:0,...)` que monta `_MapHeader`, el `GoogleMap`, los FABs, el drive strip, el carrusel.
- M1 (recarga isla), M2 (chip), M3 (anchors), M4 (azul), M5 (dual-theme) — intactos.
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M6 **NO** toca: logo Google (M7), empty states (M8), distance pill '--' (M9), http client (M10), filtrado cliente (M11), pausa sensores (M12), marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Un scrim opaco que tape el mapa entero o que bloquee los taps sobre los markers (usar gradiente que termina en `withOpacity(0.0)` y ceñido al header, NO `Positioned.fill`).
- Hardcodear un color de scrim (usar `brand.base.withOpacity(...)`, dual-theme).
- Reordenar/re-estilizar el contenido del header. Tocar otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: hay un `Container(decoration: BoxDecoration(gradient: LinearGradient([brand.base.withOpacity(0.92), brand.base.withOpacity(0.0)])))` envolviendo el `SafeArea` del header; el contenido (Column) no cambió; no se añadió `Positioned.fill`.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Ajuste del padding del logo de Google del mapa / compliance: M7.

ENTREGA:
1. Diff de `map_search.dart` (scrim gradient detrás del header).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M6.

Diff objetivo ≤ 25 líneas.
