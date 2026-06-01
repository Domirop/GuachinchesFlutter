Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M13 (último de la serie M1…M13, uno por harness)**: **marker sin "n/d"**. El marker custom del mapa (pill estilo TheFork, `_buildBubbleMarker`) pinta `r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : 'n/d'`. Para restaurantes **sin valoración** se dibuja un "n/d" textual dentro del pin, que es ruido (la tarjeta flotante ya resuelve esto bien: `if (r.avgRating > 0)` muestra el badge de estrella, si no, nada). M13 = cuando **no hay rating**, renderizar el marker **sólo con el punto de estado** (abierto/cerrado), **sin texto "n/d"** ni el ancho reservado para él (pill compacto dot-only). Cliente-puro, cambio mínimo. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- `_buildBubbleMarker(Restaurant r, {bool selected})` (~línea 495) construye el bitmap del marker con: fondo redondeado (pill) + sombra + borde + **punto de estado** (verde abierto / rojo cerrado) + **texto de rating** + cola (triángulo).
- El texto de rating (~510): `final ratingText = r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : 'n/d';`. Se mide con un `TextPainter` (~513-526).
- El ancho del pill (~528): `final double w = pad + dotSize + dotGap + ratingPainter.width + pad;`.
- El punto de estado se pinta SIEMPRE (~590-598) en `Offset(originX + pad + dotSize/2, originY + h/2)`.
- El texto de rating se pinta (~600-607): `ratingPainter.paint(canvas, Offset(originX + pad + dotSize + dotGap, originY + (h - ratingPainter.height)/2));`.
- La cola se centra en `tailCenterX = originX + w/2` (~610) → al recalcular `w` para el caso dot-only, la cola y el centrado siguen correctos automáticamente.
- La tarjeta flotante (`_FloatingMapCard`, ~1823) YA hace `if (r.avgRating > 0) ...badge estrella...` (no muestra "n/d"). M13 alinea el MARKER con ese criterio.

---

CONTRATO FUNCIONAL (sólo M13):

1. Calcular un flag `hasRating` y vaciar el texto cuando no hay rating:
   ```dart
   final bool hasRating = r.avgRating > 0;
   final ratingText = hasRating ? r.avgRating.toStringAsFixed(1) : '';
   ```
   (Se mantiene el `TextPainter` con `ratingText` —vacío cuando no hay rating, `layout()` da width 0—, así no hay que volverlo nullable.)

2. **Ancho condicional** del pill: dot-only cuando no hay rating (sin `dotGap` ni ancho de texto):
   ```dart
   final double w = hasRating
       ? pad + dotSize + dotGap + ratingPainter.width + pad
       : pad + dotSize + pad;
   ```

3. **No pintar** el texto cuando no hay rating: envolver el `ratingPainter.paint(...)` en `if (hasRating) { ... }`.

   - Resultado sin rating: pill compacto con sólo el punto de estado centrado, sin "n/d". El resto del marker (sombra, borde, halo de selección, cola, colores selected/atlántico) **idéntico**.
   - Con rating: comportamiento **idéntico** al actual.

---

NO MODIFICAR / NO ROMPER:
- El punto de estado (abierto/cerrado) — sigue pintándose SIEMPRE (también en el caso dot-only).
- La sombra, borde, halo de selección, cola, escala/tamaños `selected`, colores (`AppColors.atlantico` / `0xFF1B1D22`), el anchor del marker — sin cambios.
- `_fmtDistance`/distance pill (M9), filtros cliente (M11), pausa sensores (M12), empty-state (M8), etc. M1-M12 intactos.
- El `_FloatingMapCard` y su badge de estrella (~1823) — NO tocar (ya está bien).
- El modelo, cubits, presenter, `pubspec.yaml`, `ios/`, `android/`, `main.dart`.

PROHIBIDO (rechazo automático del Evaluator):
- Dejar "n/d" textual en el marker cuando `avgRating <= 0`.
- Dejar un hueco/ancho muerto donde iría el texto (el pill debe encoger a dot-only).
- Ocultar el punto de estado o el marker completo (el restaurante sin rating debe seguir teniendo pin tappable).
- Tocar la tarjeta flotante u otros M's, cubits/presenter, `pubspec.yaml`/`ios/`/`android/`/`main.dart`. Tests de widget que monten `MapSearch`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: `hasRating`; `ratingText` vacío sin rating; `w` condicional (dot-only sin rating); `ratingPainter.paint` envuelto en `if (hasRating)`; el punto de estado se sigue pintando siempre.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Rediseño del marker (icono de estrella en vez de punto, etc.): fuera de M13 (sólo se elimina el "n/d").

ENTREGA:
1. Diff de `map_search.dart` (marker dot-only sin "n/d").
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M13 (y cierre de la serie M1-M13).

Diff objetivo ≤ 12 líneas.
