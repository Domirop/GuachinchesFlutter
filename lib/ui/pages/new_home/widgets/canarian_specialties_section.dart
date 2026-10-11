import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// «Especialidades canarias» en la banda crema (rediseño iOS 27):
/// - Hero «Guachinches tradicionales» (Type "tradicional") con foto real de
///   un guachinche tradicional de la isla, vapor que sube dos veces, flecha
///   de cristal y tira de mantel de cuadros.
/// - Tres losetas con glifos propios (cabra, cochino negro, vieja) que se
///   mueven una vez. Mapean a categorías por nombre y se descartan las que no
///   existan en BD (las mismas condiciones de siempre).
class CanarianSpecialtiesSection extends StatelessWidget {
  final List<ModelCategory> categories;
  final List<Types> types;

  /// Pool de la isla: de aquí sale la foto del hero (si hay).
  final List<Restaurant> pool;
  final void Function({
    List<ModelCategory>? categories,
    List<Types>? types,
  }) onSearchPreSelected;

  const CanarianSpecialtiesSection({
    super.key,
    required this.categories,
    required this.types,
    required this.onSearchPreSelected,
    this.pool = const [],
  });

  Types? _findType(String contains) {
    final c = contains.toLowerCase();
    for (final t in types) {
      if (t.nombre.toLowerCase().contains(c)) return t;
    }
    return null;
  }

  ModelCategory? _findCategory(String contains) {
    final c = contains.toLowerCase();
    for (final cat in categories) {
      if (cat.nombre.toLowerCase().contains(c)) return cat;
    }
    return null;
  }

  /// Foto del hero: el tradicional mejor valorado del pool que tenga foto.
  String? _heroPhoto(Types t) {
    Restaurant? best;
    for (final r in pool) {
      if (r.type != t.id) continue;
      if (r.mainFoto.isEmpty) continue;
      if (best == null || r.avgRating > best.avgRating) best = r;
    }
    return best?.mainFoto;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final tradicional = _findType('tradicional');
    final tiles = <_TileDef>[
      _TileDef(GmGlyphKind.cabra, 'Carne de cabra', const Color(0xFFF6DCD8),
          _Idle.goat, _findCategory('cabra')),
      _TileDef(GmGlyphKind.cochino, 'Cochino negro', const Color(0xFFE9DCC2),
          _Idle.pig, _findCategory('cochino')),
      _TileDef(GmGlyphKind.vieja, 'Pescado fresco', const Color(0xFFE1E8D2),
          _Idle.fish, _findCategory('pescado')),
    ].where((c) => c.category != null).toList();

    if (tradicional == null && tiles.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: gm.band,
        border: Border(
          top: BorderSide(color: gm.sep),
          bottom: BorderSide(color: gm.sep),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmSectionHeader(
            eyebrow: GmEyebrow(
              leading: GmIcon(GmIcons.wineGlass, size: 14, color: gm.bandInk),
              text: 'Sabores de aquí',
              color: gm.bandInk,
            ),
            title: 'Especialidades canarias',
            identifier: 'home-specialties-title',
            onTap: () => onSearchPreSelected(),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tradicional != null)
                  GmRise(
                    index: 1,
                    child: _TraditionalHero(
                      photoUrl: _heroPhoto(tradicional),
                      onTap: () => onSearchPreSelected(types: [tradicional]),
                    ),
                  ),
                if (tradicional != null && tiles.isNotEmpty)
                  const SizedBox(height: 12),
                if (tiles.isNotEmpty)
                  // Losetas del mismo alto (el de la más alta si el texto
                  // del sistema crece).
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: i < tiles.length
                                ? GmRise(
                                    index: 2 + i,
                                    child: _SpecialtyTile(
                                      def: tiles[i],
                                      onTap: () => onSearchPreSelected(
                                          categories: [tiles[i].category!]),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Idle { goat, pig, fish }

class _TileDef {
  final GmGlyphKind glyph;
  final String label;
  final Color bg;
  final _Idle idle;
  final ModelCategory? category;
  _TileDef(this.glyph, this.label, this.bg, this.idle, this.category);
}

class _TraditionalHero extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;
  const _TraditionalHero({required this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticsIdentifier: 'home-specialties-traditional',
      semanticsLabel: 'Guachinches tradicionales',
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GmRadius.hero),
          boxShadow: gm.shadow2,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GmRadius.hero),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoUrl != null)
                GmPhoto(photoUrl,
                    decodeWidth: 900, alignment: const Alignment(0, 0.16))
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B2A1A), Color(0xFF2A0E14)],
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x0D1C0E06),
                      Color(0x401C0E06),
                      Color(0xDB1C0E06),
                    ],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),
              const Positioned(right: 64, top: 10, child: _Steam()),
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Auténtico',
                        style: GmText.eyebrow(color: const Color(0xFFF2D9A6))),
                    const SizedBox(height: 2),
                    Text('Guachinches tradicionales',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.title2(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      'Vino de la casa y mantel de cuadros',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.body(
                          color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: GmIcon(GmIcons.arrowRight,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 14,
                child: CustomPaint(painter: GmGinghamPainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vapor: dos volutas difuminadas que suben, dos veces (3,6 s, desfase 1,1 s).
class _Steam extends StatelessWidget {
  const _Steam();

  @override
  Widget build(BuildContext context) {
    // 0,4 s + 1,1 s de desfase + 2 × 3,6 s.
    const totalMs = 400 + 1100 + 7200;
    return IgnorePointer(
      child: RepaintBoundary(
        child: GmOnce(
          duration: const Duration(milliseconds: totalMs),
          builder: (_, t, __) => CustomPaint(
            size: const Size(120, 76),
            painter: _SteamPainter(ms: t * totalMs, done: t >= 1),
          ),
        ),
      ),
    );
  }
}

class _SteamPainter extends CustomPainter {
  final double ms;
  final bool done;
  _SteamPainter({required this.ms, required this.done});

  @override
  void paint(Canvas canvas, Size size) {
    if (done) return;
    for (var i = 0; i < 2; i++) {
      final local = ms - (400 + i * 1100);
      if (local <= 0 || local >= 7200) continue;
      final t = (local % 3600) / 3600;
      final op = gmKeyframes(t, const [(0, 0), (0.4, 1), (1, 0)]);
      final dy = gmKeyframes(t, const [(0, 8), (1, -22)]);
      final sx = gmKeyframes(t, const [(0, 0.85), (1, 1.25)]);
      if (op <= 0) continue;
      final x = i == 0 ? 30.0 : 74.0;
      final path = Path()
        ..moveTo(x, 72)
        ..cubicTo(x - 10, 62, x + 10, 55, x, 44)
        ..cubicTo(x - 8, 33, x + 8, 27, x, 16);
      canvas.save();
      canvas.translate(x, 72 + dy);
      canvas.scale(sx, 1);
      canvas.translate(-x, -72);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3 * op)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter old) => old.ms != ms;
}

class _SpecialtyTile extends StatelessWidget {
  final _TileDef def;
  final VoidCallback onTap;
  const _SpecialtyTile({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmPressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticsLabel: def.label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gm.bandCard,
          borderRadius: BorderRadius.circular(GmRadius.tile),
          boxShadow: gm.shadow1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: def.bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: _IdleGlyph(def: def),
            ),
            Text(
              def.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
                color: gm.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gesto único de cada glifo: la cabra embiste ±12°, el cochino brinca
/// −8 px, la vieja colea ±12°. Desfase 0,5 s entre ellos.
class _IdleGlyph extends StatelessWidget {
  final _TileDef def;
  const _IdleGlyph({required this.def});

  @override
  Widget build(BuildContext context) {
    final size = def.idle == _Idle.goat ? 24.0 : 26.0;
    final glyph = GmGlyph(def.glyph, size: size);
    switch (def.idle) {
      case _Idle.goat:
        return GmOnce(
          duration: const Duration(milliseconds: 1300),
          delay: const Duration(milliseconds: 600),
          child: glyph,
          builder: (_, t, c) {
            final rot = gmKeyframes(
                t, const [(0, 0), (0.25, -12), (0.5, 12), (0.75, -3), (1, 0)]);
            final dx = gmKeyframes(
                t, const [(0, 0), (0.25, -3), (0.5, 4), (0.75, 0), (1, 0)]);
            final s = gmKeyframes(
                t, const [(0, 1), (0.25, 1), (0.5, 1.06), (0.75, 1), (1, 1)]);
            final sy = gmKeyframes(
                t, const [(0, 1), (0.25, 1), (0.5, 0.95), (0.75, 1), (1, 1)]);
            return Transform(
              alignment: const Alignment(0, 0.8),
              transform: Matrix4.translationValues(dx, 0, 0)
                ..multiply(Matrix4.rotationZ(rot * math.pi / 180))
                ..multiply(Matrix4.diagonal3Values(s, sy, 1)),
              child: c,
            );
          },
        );
      case _Idle.pig:
        return GmOnce(
          duration: const Duration(milliseconds: 1200),
          delay: const Duration(milliseconds: 1100),
          child: glyph,
          builder: (_, t, c) {
            final dy = gmKeyframes(
                t, const [(0, 0), (0.2, 1), (0.5, -8), (0.75, 0), (1, 0)]);
            final sx = gmKeyframes(t,
                const [(0, 1), (0.2, 1.14), (0.5, 0.93), (0.75, 1.06), (1, 1)]);
            final sy = gmKeyframes(t,
                const [(0, 1), (0.2, 0.86), (0.5, 1.08), (0.75, 0.95), (1, 1)]);
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(0, dy, 0)
                ..multiply(Matrix4.diagonal3Values(sx, sy, 1)),
              child: c,
            );
          },
        );
      case _Idle.fish:
        return GmOnce(
          duration: const Duration(milliseconds: 1200),
          delay: const Duration(milliseconds: 1600),
          child: glyph,
          builder: (_, t, c) {
            final rot = gmKeyframes(t, const [
              (0, 0),
              (0.15, 12),
              (0.35, -12),
              (0.55, 8),
              (0.75, -4),
              (1, 0)
            ]);
            final dx = gmKeyframes(t, const [
              (0, 0),
              (0.15, 2),
              (0.35, 3),
              (0.55, 2),
              (0.75, 0),
              (1, 0)
            ]);
            return Transform(
              alignment: const Alignment(0.2, 0),
              transform: Matrix4.translationValues(dx, 0, 0)
                ..multiply(Matrix4.rotationZ(rot * math.pi / 180)),
              child: c,
            );
          },
        );
    }
  }
}
