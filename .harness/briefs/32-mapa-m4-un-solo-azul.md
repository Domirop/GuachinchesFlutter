Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M4 (de la serie M1…M13, uno por harness)**: **unificar el azul** — el fichero mezcla dos fuentes para el MISMO color (`GlobalMethods.blueColor` legacy y `AppColors.atlantico` de la paleta oficial). Reemplazar **todas** las apariciones de `GlobalMethods.blueColor` por `AppColors.atlantico`. Es un refactor de fuente **puro, cero cambio visual** (ambos son exactamente `#0085C4`). Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- `GlobalMethods.blueColor = Color.fromRGBO(0, 133, 196, 1)` == `#0085C4`. `AppColors.atlantico = Color(0xFF0085C4)` == `#0085C4`. **Mismo color** → el reemplazo NO cambia un solo pixel; sólo unifica la fuente a la paleta oficial (CLAUDE.md: "Mockups y código nuevo usan AppColors, no GlobalMethods").
- `AppColors` ya está importado en el fichero (`import 'package:guachinches/config/app_colors.dart';`, línea 12) y ya se usa (p. ej. `AppColors.ink`, `AppColors.atlantico` en M2). No hace falta añadir import.
- Hay **24** apariciones de `GlobalMethods.blueColor` (incluyendo formas `GlobalMethods.blueColor.withOpacity(...)`). Líneas aprox.: 534, 555, 1152, 1157, 1219, 1224, 1402, 1483, 1488, 1497, 1933, 1937, 2121, 2171, 2179, 2188, 2251, 2255, 2303, 2307, 2368, 2371, 2377. (La lista es orientativa; el objetivo es **cero** `GlobalMethods.blueColor` tras el cambio.)

---

CONTRATO FUNCIONAL (sólo M4):

1. **Reemplazar todas** las apariciones de `GlobalMethods.blueColor` por `AppColors.atlantico` en `map_search.dart`, incluidas las que llevan `.withOpacity(...)` encadenado (`GlobalMethods.blueColor.withOpacity(0.35)` → `AppColors.atlantico.withOpacity(0.35)`). Esto incluye las apariciones dentro de componentes de modo coche (`_DriveNearestCard`, `_DrivePill`, `_EnterDrivePill`, `_DriveExitPill`) — el azul-acento atlántico es independiente del tema y se queda; el rework de **fondos** dual-theme de esos componentes es **M5**, NO se toca aquí.
2. Tras el cambio, `grep "GlobalMethods.blueColor"` sobre el fichero debe devolver **0 resultados**.

---

NO MODIFICAR / NO ROMPER:
- **NO tocar `GlobalMethods.bgColor`** (3 apariciones, líneas ~1312, ~1313, ~1381, dentro de `_DriveNearbyStrip`/`_DriveNearestCard`). Es un **fondo** dark-only que pertenece a **M5** (dual-theme de modo coche). Dejarlo intacto.
- NO cambiar opacidades, tamaños, layout, ni ningún otro color (`brand.*`, `Colors.white`, `Colors.white12`, etc. se quedan igual). SÓLO `blueColor` → `atlantico`.
- El `BlocListener`/recarga de M1, el chip selector de M2, los anchors de M3, la lógica de markers, carrusel, detección de conducción, cámara chase, defer-mount, FABs.
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`. NO añadir/quitar imports salvo que `GlobalMethods` quede sin usar (ver abajo).
- **Import de GlobalMethods:** tras el cambio, `GlobalMethods` SIGUE usándose (por `bgColor`), así que **NO quitar** `import '.../globalMethods.dart';`. (Si por algún motivo quedara totalmente sin usar, entonces sí quitarlo para evitar warning `unused_import` — pero NO debería ser el caso.)

PROHIBIDO (rechazo automático del Evaluator):
- Dejar cualquier `GlobalMethods.blueColor` en el fichero.
- Tocar `GlobalMethods.bgColor` (eso es M5) o cualquier otro color/opacidad/layout.
- Cambiar el valor del color (no usar otro azul; `AppColors.atlantico` es el equivalente exacto).
- Tocar otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `grep -c "GlobalMethods.blueColor" lib/ui/pages/map/map_search.dart` == 0; `grep -c "GlobalMethods.bgColor" ...` == 3 (intacto).
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`). En particular, sin `unused_import` de globalMethods.
- Confirmar por diff que SÓLO cambian líneas `blueColor`→`atlantico` (mismo valor), sin tocar nada más.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones, no arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- `GlobalMethods.bgColor` y `Colors.white12` de los componentes de modo coche → dual-theme: M5.

ENTREGA:
1. Diff de `map_search.dart` (blueColor → atlantico, mecánico).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M4.

Diff objetivo ≤ 30 líneas.
