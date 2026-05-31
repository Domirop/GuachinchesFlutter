Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M5 (de la serie M1…M13, uno por harness)**: **dual-theme del modo coche**. Los componentes de conducción (`_DriveNearbyStrip`, `_DriveNearestCard`, `_DrivePill`) usan **neutros dark-only hardcodeados** (`GlobalMethods.bgColor`, `Colors.white12`, `Colors.white10`, `Colors.white60`, `Color(0xFF2A2D36)`, `Colors.white`) que **se rompen en tema claro** (tarjeta oscura sobre fondo claro, texto blanco ilegible). Migrar esos neutros a tokens `context.brand.*`. Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- Tokens de marca disponibles vía `context.brand.*` (de `lib/config/brand_colors.dart`, ya usados en el fichero: `brand.surface`, `brand.elevated`, `brand.base`, `brand.border`, `brand.textPrimary`, `brand.textMuted`, etc.). Los tres widgets afectados son `StatelessWidget`/`State` con `BuildContext context` en `build`, así que `context.brand` está disponible.
- `AppColors.atlantico` (azul acento) y los `status.color` (semánticos: verde/ámbar/rojo, `_kStatusUrgent`/`_kStatusWarning`) son **independientes del tema** → **NO se tocan**.
- `_EnterDrivePill` (~2238) y `_DriveExitPill` (~2289) son pills con **fondo atlántico + contenido blanco** → legibles en ambos temas → **FUERA DE ALCANCE** (no tocar).

Mapeo EXACTO a aplicar (líneas aprox.):

1. **`_DriveNearbyStripState.build`** — gradiente scrim (~1312-1313):
   - `GlobalMethods.bgColor` → `context.brand.base`
   - `GlobalMethods.bgColor.withOpacity(0.0)` → `context.brand.base.withOpacity(0.0)`

2. **`_DriveNearestCard.build`** (~1377-1391):
   - fondo `color: GlobalMethods.bgColor` → `context.brand.elevated`
   - borde `Border.all(color: Colors.white12, ...)` → `Border.all(color: context.brand.border, ...)`
   - sombra `BoxShadow(color: Colors.black.withOpacity(0.4), ...)` → suavizar a `Colors.black.withOpacity(0.18)` (la 0.4 es muy dura sobre fondo claro; negro translúcido suave funciona en ambos temas).
   - nombre `Text(restaurant.nombre, style: TextStyle(color: Colors.white, ...))` (~1415) → `color: context.brand.textPrimary`.

3. **`_DrivePill.build`** (~1481-1548):
   - fondo inactivo `: const Color(0xFF2A2D36)` (~1484) → `: context.brand.surface` (quitar `const` del `BoxDecoration`/expresión si el análisis lo exige por dejar de ser const).
   - borde inactivo `Colors.white10` (~1491) → `context.brand.border`.
   - nombre `Text(restaurant.nombre.toUpperCase(), style: TextStyle(color: Colors.white, ...))` (~1523) → `color: active ? Colors.white : context.brand.textPrimary` (en activo el fondo es atlántico → blanco; en inactivo el fondo es `brand.surface` → textPrimary).
   - trailing: en la rama inactiva-normal `Colors.white60` (~1542) → `context.brand.textMuted`. (Las ramas `active ? Colors.white` y `(closingSoon||unreachable) ? status.color` se mantienen.)

4. **Import:** tras M5 ya **no quedará ningún `GlobalMethods.*`** en el fichero (M4 quitó `blueColor`; M5 quita los `bgColor`). Por tanto **eliminar** la línea `import 'package:guachinches/globalMethods.dart';` para evitar el warning `unused_import`. (Verificar con grep que no queda ninguna referencia a `GlobalMethods.` antes de quitar el import.)

---

CONTRATO FUNCIONAL (sólo M5):
- Aplicar el mapeo de arriba: cero neutros dark-only hardcodeados en `_DriveNearbyStrip`/`_DriveNearestCard`/`_DrivePill`; todos derivan de `context.brand.*`.
- El resultado debe verse bien en **ambos temas** (claro: tarjeta clara, texto oscuro legible; oscuro: igual que hoy o equivalente).

NO MODIFICAR / NO ROMPER:
- `AppColors.atlantico`, `status.color`, `_kStatusUrgent/_kStatusWarning`, los `Colors.white` que van sobre **fondo atlántico** (activos, iconos de los Enter/Exit pills) — son legibles en ambos temas, se quedan.
- `_EnterDrivePill` / `_DriveExitPill` (fuera de alcance).
- La lógica de paginación (`PageView`, `_index`, `_go`), `_DrivingDetector`, cámara chase, `_IrButton`, `_fmtDistance`, `_fmtDriveMinutes`, `_statusFor`, `_closingTimeNow` — NO tocar lógica, sólo colores.
- El `BlocListener`/recarga de M1, chip de M2, anchors de M3, el azul unificado de M4.
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M5 **NO** toca: scrim del header (M6), logo Google (M7), empty states (M8), distance pill '--' (M9), http client (M10), filtrado cliente (M11), pausa de sensores (M12), marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Dejar `GlobalMethods.bgColor` o cualquier `Colors.white12/white10/white60` / `Color(0xFF2A2D36)` como fondo/borde/texto-neutro en los 3 componentes drive.
- Dejar el `import globalMethods.dart` si `GlobalMethods` queda sin usar (warning `unused_import`).
- Cambiar `AppColors.atlantico`, status colors, o tocar Enter/Exit pills.
- Tocar otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `grep -c "GlobalMethods" lib/ui/pages/map/map_search.dart` == 0 (incluido el import).
- En los 3 componentes drive: sin `Colors.white12`, `Colors.white10`, `Colors.white60`, `Color(0xFF2A2D36)` como neutro; fondos/bordes/textos-neutros vía `context.brand.*`.
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`); **sin `unused_import`**.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Scrim/gradient detrás del header principal (no el del drive strip): M6.

ENTREGA:
1. Diff de `map_search.dart` (neutros drive → context.brand.*, import limpio).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M5.

Diff objetivo ≤ 40 líneas.
