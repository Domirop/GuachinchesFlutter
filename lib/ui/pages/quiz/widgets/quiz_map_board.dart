import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_canarias_paths.dart';

/// Una isla del tablero (slug + nombre). Mantiene la API pública que consumen
/// result_view / lobby_view (`kQuizMapIslands.map((i) => i.slug)`).
class QuizMapIsland {
  final String slug;
  final String name;
  const QuizMapIsland(this.slug, this.name);
}

const List<QuizMapIsland> kQuizMapIslands = [
  QuizMapIsland('la_palma', 'La Palma'),
  QuizMapIsland('el_hierro', 'El Hierro'),
  QuizMapIsland('la_gomera', 'La Gomera'),
  QuizMapIsland('tenerife', 'Tenerife'),
  QuizMapIsland('gran_canaria', 'Gran Canaria'),
  QuizMapIsland('fuerteventura', 'Fuerteventura'),
  QuizMapIsland('lanzarote', 'Lanzarote'),
];

/// Modelo geométrico (paths reales + bounds de la unión), parseado UNA vez.
class _CanariasModel {
  final List<_IslandShape> shapes;
  final Rect bounds;
  const _CanariasModel(this.shapes, this.bounds);

  double get aspect => bounds.width / bounds.height;
}

class _IslandShape {
  final String slug;
  final String name;
  final Path path; // en espacio modelo
  const _IslandShape(this.slug, this.name, this.path);
}

_CanariasModel _buildModel() {
  final shapes = <_IslandShape>[];
  Rect? union;
  for (final isl in kCanariasIslands) {
    final p = parseCanariasPath(isl);
    shapes.add(_IslandShape(isl.slug, isl.name, p));
    final b = p.getBounds();
    union = union == null ? b : union.expandToInclude(b);
  }
  return _CanariasModel(shapes, union!);
}

final _CanariasModel _model = _buildModel();

/// Aspect real de la unión de siluetas (≈ ancho/alto del archipiélago).
final double kQuizMapAspect = _model.aspect;

/// Mapa de conquista: las 7 siluetas REALES de Canarias, rellenadas en
/// [tierColor] al conquistarlas. Si [onTapIsland] no es null, las islas sin
/// conquistar son tocables (modo "elige qué isla ganar") y laten.
class QuizMapBoard extends StatefulWidget {
  final Set<String> owned;
  final Color tierColor;
  final ValueChanged<String>? onTapIsland;

  /// Modo "escena": sin marco propio (fondo transparente) para flotar sobre una
  /// ilustración. Las islas usan tonos tierra + sombra para leer sobre el mar.
  final bool bare;

  const QuizMapBoard({
    super.key,
    required this.owned,
    required this.tierColor,
    this.onTapIsland,
    this.bare = false,
  });

  @override
  State<QuizMapBoard> createState() => _QuizMapBoardState();
}

class _QuizMapBoardState extends State<QuizMapBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool get _hasSelectable =>
      widget.onTapIsland != null &&
      _model.shapes.any((s) => !widget.owned.contains(s.slug));

  @override
  void initState() {
    super.initState();
    if (_hasSelectable) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(QuizMapBoard old) {
    super.didUpdateWidget(old);
    if (_hasSelectable && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_hasSelectable && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Transform modelo→canvas (BoxFit.contain con [inset] de margen).
  Matrix4 _fitTransform(Size size, double inset) {
    final b = _model.bounds;
    final w = size.width - inset * 2;
    final h = size.height - inset * 2;
    // BoxFit.contain: el menor de los dos factores cabe el archipiélago entero.
    final scale = (w / b.width) < (h / b.height) ? w / b.width : h / b.height;
    final drawnW = b.width * scale;
    final drawnH = b.height * scale;
    final dx = inset + (w - drawnW) / 2 - b.left * scale;
    final dy = inset + (h - drawnH) / 2 - b.top * scale;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _handleTap(Offset local, Size size) {
    final onTap = widget.onTapIsland;
    if (onTap == null) return;
    final m = _fitTransform(size, 10);
    for (final s in _model.shapes) {
      if (widget.owned.contains(s.slug)) continue;
      final fitted = s.path.transform(m.storage);
      if (fitted.contains(local)) {
        onTap(s.slug);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final scene = widget.bare;
    // Sobre la escena: tierra cálida con borde oscuro, lee sobre cielo/mar.
    final landFill = scene
        ? const Color(0xFFE4D3A6)
        : Color.alphaBlend(
            brand.textPrimary.withValues(alpha: 0.13), brand.surface);
    final landStroke = scene
        ? const Color(0xCC24351E)
        : brand.textPrimary.withValues(alpha: 0.32);

    final content = LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final m = _fitTransform(size, scene ? 4 : 10);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d.localPosition, size),
          // RepaintBoundary: el "latido" de las islas (pulse) repinta a 60fps
          // en la pantalla de conquista; lo aislamos para no repintar la escena
          // ni la repisa de cristal de alrededor.
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        isComplex: true,
                        painter: _CanariasPainter(
                          owned: widget.owned,
                          tierColor: widget.tierColor,
                          selectable: widget.onTapIsland != null,
                          landFill: landFill,
                          landStroke: landStroke,
                          scene: scene,
                          pulse: _pulse.value,
                          transform: m,
                        ),
                      ),
                    ),
                    for (final s in _model.shapes)
                      _label(context, s, m, brand, scene),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (scene) {
      return AspectRatio(aspectRatio: kQuizMapAspect, child: content);
    }
    return AspectRatio(
      aspectRatio: kQuizMapAspect,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                  AppColors.atlantico.withValues(alpha: 0.16), brand.surface),
              brand.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: brand.border),
        ),
        child: content,
      ),
    );
  }

  Widget _label(BuildContext context, _IslandShape s, Matrix4 m,
      BrandColors brand, bool scene) {
    final b = s.path.getBounds();
    final center = MatrixUtils.transformPoint(m, b.center);
    final conquered = widget.owned.contains(s.slug);
    final selectable = widget.onTapIsland != null && !conquered;
    final color = scene
        ? const Color(0xFF11343F)
        : ((conquered || selectable) ? brand.textPrimary : brand.textMuted);
    return Positioned(
      left: center.dx - 50,
      top: center.dy + 5,
      width: 100,
      child: IgnorePointer(
        child: Text(
          s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.ui(
            size: 9.5,
            weight: FontWeight.w800,
            color: color,
          ).copyWith(
            shadows: scene
                ? const [
                    Shadow(
                        color: Color(0xCCFFFFFF),
                        blurRadius: 3,
                        offset: Offset(0, 0.5)),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _CanariasPainter extends CustomPainter {
  final Set<String> owned;
  final Color tierColor;
  final bool selectable;
  final Color landFill;
  final Color landStroke;
  final bool scene;
  final double pulse;
  final Matrix4 transform;

  _CanariasPainter({
    required this.owned,
    required this.tierColor,
    required this.selectable,
    required this.landFill,
    required this.landStroke,
    required this.scene,
    required this.pulse,
    required this.transform,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = transform.storage;
    for (final s in _model.shapes) {
      final path = s.path.transform(t);
      final conquered = owned.contains(s.slug);
      final isSelectable = selectable && !conquered;

      // Sobre la escena: sombra suave bajo cada isla (flota sobre el mar).
      if (scene) {
        canvas.drawPath(
          path.shift(const Offset(0, 2)),
          Paint()
            ..color = const Color(0x55000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Halo para islas conquistadas y seleccionables (late).
      if (conquered || isSelectable) {
        final glowA = conquered ? 0.45 : 0.25 + pulse * 0.45;
        canvas.drawPath(
          path,
          Paint()
            ..color = tierColor.withValues(alpha: glowA)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.outer, conquered ? 7 : 5 + pulse * 6),
        );
      }

      // Relleno.
      final Color fill;
      if (conquered) {
        fill = tierColor;
      } else if (isSelectable) {
        fill = Color.alphaBlend(
            tierColor.withValues(alpha: 0.16 + pulse * 0.12), landFill);
      } else {
        fill = landFill;
      }
      canvas.drawPath(path, Paint()..color = fill);

      // Contorno.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = conquered ? 1.6 : 1.1
          ..strokeJoin = StrokeJoin.round
          ..color = conquered
              ? Colors.white.withValues(alpha: 0.7)
              : (isSelectable
                  ? tierColor.withValues(alpha: 0.55 + pulse * 0.3)
                  : landStroke),
      );

      // Bandera de conquista (icono ✓ vía path simple) — usamos un punto
      // brillante en el centroide para no depender de fuentes de iconos.
      if (conquered) {
        final ctr =
            MatrixUtils.transformPoint(transform, s.path.getBounds().center);
        canvas.drawCircle(
            ctr, 3.2, Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(_CanariasPainter old) =>
      old.pulse != pulse ||
      old.owned != owned ||
      old.tierColor != tierColor ||
      old.selectable != selectable ||
      old.landFill != landFill ||
      old.scene != scene ||
      old.transform != transform;
}
