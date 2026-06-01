Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M9 (de la serie M1…M13, uno por harness)**: **ocultar la distance pill cuando no hay distancia válida**. En la tarjeta flotante del carrusel (`_FloatingMapCard`), la "distance pill" muestra `_fmtDistance(distanceMeters)`, que devuelve `'--'` cuando la distancia **no es finita** (p. ej. sin permiso de ubicación / sin fix GPS). El resultado es una pill huérfana "📍 --" que no aporta nada y ensucia la tarjeta. Cuando la distancia no es finita, **no renderizar la pill** (ni su separación inferior). Cliente-puro, cambio mínimo. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- `_fmtDistance(double meters)` (~línea 2067): `if (!meters.isFinite) return '--';` → '--' es el sentinel de "sin distancia".
- En `_FloatingMapCard.build`, dentro del `Column` de info (~líneas 1846-1871):
  ```dart
  // Distance pill
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.atlantico.withOpacity(0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.place_rounded, color: AppColors.atlantico, size: 12),
        const SizedBox(width: 3),
        Text(_fmtDistance(distanceMeters), style: AppTextStyles.ui(...)),
      ],
    ),
  ),
  const SizedBox(height: 6),
  Text(r.nombre.toUpperCase(), ...),   // nombre (se mantiene SIEMPRE)
  ```
- `distanceMeters` es el campo `final double distanceMeters` de `_FloatingMapCard` (~línea 1710).
- **Sólo** esta pill muestra '--'. `_StatusLine` (otra parte de la tarjeta) NO muestra distancia (sólo estado/municipio/precio), así que no se toca. Los componentes de modo coche (`_DriveNearestCard`/`_DrivePill`) quedan fuera de M9 (en conducción la distancia siempre es finita; ese caso compuesto es follow-up si acaso).

---

CONTRATO FUNCIONAL (sólo M9):

1. En `_FloatingMapCard.build`, **condicionar** la distance pill (el `Container` de la pill **más** el `const SizedBox(height: 6)` que la separa del nombre) a `distanceMeters.isFinite`. Patrón con spread:
   ```dart
   if (distanceMeters.isFinite) ...[
     Container( ... distance pill ... ),
     const SizedBox(height: 6),
   ],
   Text(r.nombre.toUpperCase(), ...),
   ```
   - Cuando NO es finita: no se renderiza la pill ni su separación; el nombre del restaurante pasa a ser el primer elemento del Column (sin hueco muerto arriba).
   - Cuando SÍ es finita: comportamiento idéntico al actual.

---

NO MODIFICAR / NO ROMPER:
- El nombre del restaurante, `_StatusLine`, el botón IR, la imagen/badge, el layout general de la tarjeta.
- `_fmtDistance` (no cambiar su firma ni el sentinel '--'; sigue usándose en modo coche).
- Los componentes de modo coche (`_DriveNearestCard`, `_DrivePill`) — fuera de alcance.
- M1-M8 — intactos (recarga isla, chip, anchors, azul, dual-theme, scrim, padding, empty-state).
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M9 **NO** toca: http client (M10), filtrado cliente (M11), pausa sensores (M12), marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Dejar la pill "📍 --" visible cuando la distancia no es finita.
- Dejar un hueco/`SizedBox` muerto donde estaba la pill (ocultar también su separación).
- Cambiar `_fmtDistance` o tocar el modo coche / otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: la distance pill + su `SizedBox(height:6)` están envueltos en `if (distanceMeters.isFinite) ...[ ... ]`; el nombre se mantiene incondicional.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Línea compuesta de distancia en `_DriveNearestCard` (modo coche): follow-up si alguna vez muestra '--' con GPS sin fix.

ENTREGA:
1. Diff de `map_search.dart` (pill condicionada a isFinite).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M9.

Diff objetivo ≤ 12 líneas.
