import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_my_votes_page.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:http/http.dart' show Client;

/// ¿Se enseña la campaña en el Inicio? Remote Config `show_premios`
/// (apagado por defecto); en debug se fuerza con `ENABLE_PREMIOS=true` en
/// `env_files/debug.env`. Las pantallas de la encuesta no dependen de esto:
/// solo el módulo y la hoja del Inicio y las entradas del Inicio viejo.
bool premiosHomeEnabled() {
  if (dotenv.isInitialized &&
      (dotenv.env['ENABLE_PREMIOS'] ?? '').toLowerCase() == 'true') {
    return true;
  }
  try {
    return DccRemoteConfig.instance.showPremios;
  } catch (e) {
    // Sin Firebase (tests): campaña apagada.
    AppLogger.warn('premios', 'remote config no disponible: $e');
    return false;
  }
}

class _CategoriesMeta extends StatelessWidget {
  const _CategoriesMeta();

  @override
  Widget build(BuildContext context) {
    final st = GmText.eyebrow(color: PremiosColors.cream82);
    return Row(
      children: [
        const PremiosCopa(size: 14, ink: PremiosColors.creamInk),
        const SizedBox(width: 6),
        Text('Tradicional', style: st),
        const SizedBox(width: 8),
        Text('·', style: st.copyWith(color: PremiosColors.creamDim)),
        const SizedBox(width: 8),
        const PremiosMantel(size: 12),
        const SizedBox(width: 6),
        Text('Moderno', style: st),
      ],
    );
  }
}

// ── Hoja al abrir la app ───────────────────────────────────────────────────

/// Hoja «¿Cuál es tu guachinche favorito?». Devuelve `true` si se pulsa
/// «Votar ahora».
Future<bool?> showPremiosSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: PremiosColors.sheetBarrier,
      builder: (_) => const PremiosSheet(),
    );

class PremiosSheet extends StatelessWidget {
  const PremiosSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final panel = Container(
      height: 150,
      decoration: BoxDecoration(
        color: PremiosColors.band(gm),
        borderRadius: BorderRadius.circular(26),
        border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SheetTablePainter(
                  band: PremiosColors.band(gm),
                  veil: gm.isDark ? 0.5 : 0,
                ),
              ),
            ),
            const Positioned(
              left: 18,
              top: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiosEyebrow(color: PremiosColors.goldText),
                  SizedBox(height: 8),
                  _CategoriesMeta(),
                ],
              ),
            ),
            const Positioned(
                right: 26,
                top: 0,
                child: PremiosMiniBarrel(width: 84, trigger: GmTrigger.mount)),
          ],
        ),
      ),
    );
    return Semantics(
      identifier: 'home-premios-sheet',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
                color: PremiosColors.sheetShadow,
                offset: Offset(0, -10),
                blurRadius: 30)
          ],
        ),
        // Como el tablero: 40 hasta el borde (por encima del indicador).
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, math.max(40, MediaQuery.paddingOf(context).bottom + 6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: PremiosColors.sepStrong(gm),
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            panel,
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Cuál es tu guachinche favorito?',
                      style: GmText.largeTitle(color: gm.label).copyWith(
                          fontSize: 28, height: 34 / 28, letterSpacing: -0.6)),
                  const SizedBox(height: 6),
                  Text('Vota y decide quiénes merecen los premios de este año.',
                      style: GmText.body17(color: gm.label2)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GmCapsuleButton(
              label: 'Votar ahora',
              identifier: 'home-premios-sheet-vote',
              height: 52,
              fontSize: 17,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            Center(
              child: Semantics(
                identifier: 'home-premios-sheet-not-now',
                button: true,
                child: GmPressable(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: Text('Ahora no',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: gm.accent)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTablePainter extends CustomPainter {
  final Color band;
  final double veil;
  const _SheetTablePainter({required this.band, required this.veil});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 370, 1);
    final cloth = Path()
      ..moveTo(40, 104)
      ..quadraticBezierTo(185, 100, 330, 104)
      ..lineTo(380, 150)
      ..lineTo(-10, 150)
      ..close();
    GmGinghamPainter.paintCells(canvas, const Rect.fromLTRB(-10, 100, 380, 150),
        cell: 7, stripe: kPremiosClothRed, clip: cloth);
    canvas.drawRect(
      const Rect.fromLTWH(0, 100, 370, 22),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [band, band.withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(0, 100, 370, 22)),
    );
    if (veil > 0) {
      canvas.drawRect(const Rect.fromLTWH(0, 100, 370, 50),
          Paint()..color = band.withValues(alpha: veil));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheetTablePainter old) =>
      old.band != band || old.veil != veil;
}

// ── Card de Premios en vino y oro ──────────────────────────────────────────

enum PremiosCardVariant { notVoted, voted, closed }

/// La card de Premios del Inicio (tablero EncuestaInicioCard), encima de
/// «Hoy»: vino con resplandor oro y filo de oro de 2 px con brillo que lo
/// recorre una vez; antetítulo, título, barrica, segmentado y el podio del
/// Ranking; «Tu voto»; CTA a todo el ancho (brillo sincronizado con el filo y
/// tres respiraciones) y pie con línea de oro. Sin «Ahora no». Con el
/// ranking oculto, el podio en silueta y «El ranking se desvela al cierre».
class PremiosWineCard extends StatefulWidget {
  final PremiosCardVariant variant;
  final PremiosRankingState ranking;
  final int totalVotes;
  final String remaining;
  final VoidCallback onVote;
  final VoidCallback onRanking;
  final VoidCallback onMyVotes;
  final VoidCallback onHowTo;

  const PremiosWineCard({
    super.key,
    required this.variant,
    required this.ranking,
    required this.totalVotes,
    required this.remaining,
    required this.onVote,
    required this.onRanking,
    required this.onMyVotes,
    required this.onHowTo,
  });

  @override
  State<PremiosWineCard> createState() => _PremiosWineCardState();
}

class _PremiosWineCardState extends State<PremiosWineCard> {
  PremiosCategory _tab = PremiosCategory.tradicional;

  /// El brillo del filo y el del CTA, a la vez.
  static const _sheenDelay = Duration(milliseconds: 1200);

  @override
  Widget build(BuildContext context) {
    final r = widget.ranking;
    final v = widget.variant;
    final closed = v == PremiosCardVariant.closed;
    final hidden = r.load == PremiosLoad.ready && r.hidden;
    // 404, red…: estado discreto (anuncio y CTA, sin podio ni fallo).
    final failed = r.load == PremiosLoad.error;
    final list = r.of(_tab);
    final mine = v == PremiosCardVariant.notVoted || hidden || failed
        ? null
        : list.where((e) => e.mine).firstOrNull;

    final (eyebrow, title, body) = switch (v) {
      PremiosCardVariant.closed => (
          'Premios 2026 · ganadores',
          'Ya tenemos ganadores',
          'Gracias a todos los que votaron. Enhorabuena a los ganadores.'
        ),
      PremiosCardVariant.voted => (
          'Premios 2026 · ya votaste',
          '¡Gracias por votar!',
          hidden || failed
              ? 'Tu voto ya está en la barrica.'
              : 'Tu voto ya está en la barrica. Así va la votación:'
        ),
      PremiosCardVariant.notVoted => (
          'Premios Donde Comer Canarias 2026',
          '¿Cuál es tu guachinche favorito?',
          hidden || failed
              ? 'Vota y decide quiénes merecen los premios de este año.'
              : 'Así va la votación ahora mismo. Vota y decide quién se lo '
                  'lleva.'
        ),
    };
    final (String ctaLabel, Widget ctaIcon, VoidCallback ctaTap) = closed
        ? (
            'Ver el ranking completo',
            const PremiosPodiumIcon(size: 20, color: Colors.white),
            widget.onRanking
          )
        : (
            v == PremiosCardVariant.voted
                ? 'Votar a otros sitios'
                : 'Votar ahora',
            const PremiosBallotIcon(),
            widget.onVote
          );
    final (String footLabel, String footMeta, VoidCallback footTap) = closed
        ? (
            'Mis votos',
            widget.totalVotes > 0 ? premiosVotes(widget.totalVotes) : '',
            widget.onMyVotes
          )
        : (hidden || failed)
            ? ('Cómo se vota', widget.remaining, widget.onHowTo)
            : ('Ver el ranking', widget.remaining, widget.onRanking);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 132),
                    child: _Header(eyebrow: eyebrow, title: title, body: body),
                  ),
                  if (hidden || failed) const _CategoriesMeta(),
                  if (hidden) ...[
                    const SizedBox(height: 12),
                    const PremiosSilhouettePodium(
                        label: 'El ranking se desvela al cierre'),
                  ] else if (!failed) ...[
                    const SizedBox(height: 4),
                    PremiosSegmented(
                      value: _tab,
                      onWine: true,
                      identifierPrefix: 'home-premios-tab',
                      onChanged: (c) => setState(() => _tab = c),
                    ),
                    const SizedBox(height: 12),
                    if (r.load == PremiosLoad.ready && list.isNotEmpty)
                      PodioPremios(
                        key: ValueKey(_tab),
                        category: _tab,
                        entries: list.take(3).toList(),
                        onWine: true,
                      )
                    else if (r.load == PremiosLoad.ready)
                      SizedBox(
                        height: 64,
                        child: Center(
                          child: Text('Aún no hay votos. ¡Estrena el podio!',
                              style: GmText.meta(color: PremiosColors.cream72)),
                        ),
                      )
                    else
                      const PremiosSilhouettePodium(),
                    if (mine != null) _MineRow(entry: mine, closed: closed),
                  ],
                  const SizedBox(height: 18),
                  PremiosCardCta(
                    label: ctaLabel,
                    icon: ctaIcon,
                    onTap: ctaTap,
                    sheenDelay: _sheenDelay,
                  ),
                ],
              ),
              const Positioned(
                right: -4,
                top: -12,
                child: PremiosMiniBarrel(width: 76),
              ),
            ],
          ),
        ),
        const _GoldRule(),
        _Foot(label: footLabel, meta: footMeta, onTap: footTap),
      ],
    );

    return Semantics(
      identifier: 'home-premios-card',
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GmRadius.guide),
          boxShadow: const [
            BoxShadow(
                color: PremiosColors.wineShadow,
                offset: Offset(0, 14),
                blurRadius: 34,
                spreadRadius: -14),
            BoxShadow(
                color: Color(0x5978541E),
                offset: Offset(0, 2),
                blurRadius: 6,
                spreadRadius: -2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GmRadius.guide),
          child: GmOnce(
            duration: const Duration(milliseconds: 1100),
            delay: _sheenDelay,
            trigger: GmTrigger.visible,
            child: Stack(
              children: [
                const Positioned.fill(child: _WineGlow()),
                content,
              ],
            ),
            builder: (_, t, child) => CustomPaint(
              foregroundPainter: PremiosGoldRimPainter(sheen: t),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String eyebrow, title, body;
  const _Header(
      {required this.eyebrow, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GmGlyph(GmGlyphKind.medalla, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (r) => const LinearGradient(colors: [
                    Color(0xFFF3DFA8),
                    Color(0xFFD6B675),
                    PremiosColors.goldText,
                  ], stops: [
                    0,
                    0.55,
                    1
                  ]).createShader(r),
                  child: Text(eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.eyebrow(
                          color: Colors.white, w: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 84),
            child: Semantics(
              header: true,
              child: Text(title, style: GmText.title2(color: GmColors.creamHi)),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 84),
            child: Text(body, style: GmText.body(color: PremiosColors.cream82)),
          ),
        ],
      );
}

/// Fondo vino con resplandor oro arriba a la derecha y vino abajo.
class _WineGlow extends StatelessWidget {
  const _WineGlow();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(color: GmColors.wine),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.2,
                  colors: [Color(0x3DC9A96B), Color(0x00C9A96B)],
                  stops: [0, 0.55],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 0.8,
                  colors: [PremiosColors.wineGlow, Color(0x00781E2D)],
                  stops: [0, 0.7],
                ),
              ),
            ),
          ],
        ),
      );
}

/// Filo de oro de 2 px con el metal a 135°, luz interior arriba y la banda
/// de luz que lo cruza una vez ([sheen] 0 → 1; fuera de (0, 1) no se pinta).
class PremiosGoldRimPainter extends CustomPainter {
  final double sheen;
  const PremiosGoldRimPainter({required this.sheen});

  static const _radius = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rim = RRect.fromRectAndRadius(
        rect.deflate(1), const Radius.circular(_radius - 1));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
        rim,
        stroke
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: PremiosColors.metal,
            stops: [0, 0.48, 1],
          ).createShader(rect));
    // inset 0 1px 0 rgba(255,236,190,.35): luz de 1 px bajo el filo, arriba.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, _radius));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.deflate(2.5), const Radius.circular(_radius - 2.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x59FFECBE));
    canvas.restore();
    if (sheen > 0 && sheen < 1) {
      final e = GmMotion.ease.transform(sheen);
      final cx = -1.1 * size.width + 3.2 * size.width * e;
      final half = 0.36 * size.width;
      canvas.drawRRect(
          rim,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..shader = LinearGradient(
              colors: const [
                Color(0x00FFFFFF),
                Colors.white,
                Color(0x00FFFFFF),
              ],
            ).createShader(
                Rect.fromLTRB(cx - half, 0, cx + half, size.height)));
    }
  }

  @override
  bool shouldRepaint(covariant PremiosGoldRimPainter old) => old.sheen != sheen;
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: PremiosColors.metal, stops: [0, 0.48, 1]),
        ),
      );
}

/// CTA de la card: cápsula Atlántico de 56 a todo el ancho, 18 en negrita,
/// icono y chevron; brillo que cruza una vez y tres «respiraciones» desde
/// 2,4 s (escala 1 → 1,03 con halo azul) y luego quieta. Con movimiento
/// reducido, ni brillo ni pulso.
class PremiosCardCta extends StatefulWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Duration sheenDelay;

  static const pulseStart = Duration(milliseconds: 2400);
  static const pulse = Duration(milliseconds: 3600);
  static const pulses = 3;

  const PremiosCardCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.sheenDelay,
  });

  @override
  State<PremiosCardCta> createState() => PremiosCardCtaState();
}

@visibleForTesting
class PremiosCardCtaState extends State<PremiosCardCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: PremiosCardCta.pulse);
  Timer? _start;
  int _done = 0;
  bool _armed = false;

  /// Respiraciones terminadas (nunca más de [PremiosCardCta.pulses]).
  @visibleForTesting
  int get pulsesDone => _done;

  @visibleForTesting
  bool get isPulsing => _c.isAnimating;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _done++;
      if (_done < PremiosCardCta.pulses) _c.forward(from: 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed || GmMotion.reduced(context)) return;
    _armed = true;
    _start = Timer(PremiosCardCta.pulseStart, () {
      if (mounted) _c.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _c.dispose();
    super.dispose();
  }

  static const _shadow = [
    BoxShadow(
        color: Color(0xBF0085C4),
        offset: Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -8),
    BoxShadow(color: Color(0x40002846), spreadRadius: 1),
  ];

  @override
  Widget build(BuildContext context) {
    final button = GmCapsuleButton(
      label: widget.label,
      identifier: 'home-premios-cta',
      height: 56,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      leading: widget.icon,
      trailing: const Opacity(
        opacity: 0.85,
        child: Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
      ),
      shadow: _shadow,
      onTap: widget.onTap,
    );
    final cta = PremiosSheen(
      delay: widget.sheenDelay,
      borderRadius: BorderRadius.circular(GmRadius.pill),
      peak: 0.45,
      child: SizedBox(width: double.infinity, child: button),
    );
    return AnimatedBuilder(
      animation: _c,
      child: cta,
      builder: (_, child) {
        final t = _c.value;
        if (!_c.isAnimating || t == 0) return child!;
        final s = gmKeyframes(t, const [
          (0, 1),
          (0.62, 1),
          (0.76, 1.03),
          (0.88, 0.995),
          (1, 1),
        ]);
        final halo = gmKeyframes(t, const [
          (0, 0),
          (0.62, 0),
          (0.76, 1),
          (0.88, 0.3),
          (1, 0),
        ]).clamp(0.0, 1.0);
        return Transform.scale(
          scale: s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GmRadius.pill),
              boxShadow: [
                BoxShadow(
                    color: Color.fromRGBO(77, 174, 219, 0.18 * halo),
                    spreadRadius: 6),
                BoxShadow(
                    color: Color.fromRGBO(0, 133, 196, 0.95 * halo),
                    offset: const Offset(0, 14),
                    blurRadius: 34,
                    spreadRadius: -8),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// «Tu voto · Guachinche Casa Pepe · Va 4.º con 5 votos» sobre vino.
class _MineRow extends StatelessWidget {
  final PremiosRankEntry entry;
  final bool closed;
  const _MineRow({required this.entry, required this.closed});

  @override
  Widget build(BuildContext context) {
    final pos = '${closed ? 'Quedó' : 'Va'} ${entry.rank}.º con '
        '${premiosVotes(entry.votes)}';
    return Semantics(
      identifier: 'home-premios-mine',
      label: 'Tu voto: ${entry.name}. $pos',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: PremiosColors.wineRowFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PremiosColors.wineRowEdge),
        ),
        child: Row(
          children: [
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GmColors.gold,
                borderRadius: BorderRadius.circular(GmRadius.pill),
              ),
              child: Text('Tu voto',
                  style: GmText.chip(color: GmColors.wine, w: FontWeight.w800)
                      .copyWith(height: 1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.sub(
                              color: GmColors.creamHi, w: FontWeight.w600)
                          .copyWith(height: 18 / 14)),
                  Text(pos,
                      style: GmText.chip(
                          color: PremiosColors.cream72, w: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  final String label;
  final String meta;
  final VoidCallback onTap;
  const _Foot({required this.label, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: 'home-premios-foot',
        button: true,
        label: meta.isEmpty ? label : '$label. $meta',
        onTap: onTap,
        excludeSemantics: true,
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.98,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.fromLTRB(22, 0, 20, 0),
            child: Row(
              children: [
                const PremiosPodiumIcon(
                    size: 17, color: PremiosColors.goldText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.body(
                          color: GmColors.creamHi, w: FontWeight.w600)),
                ),
                if (meta.isNotEmpty)
                  Text(meta,
                      style: GmText.eyebrow(color: PremiosColors.cream2)),
                const SizedBox(width: 6),
                GmIcon(GmIcons.chevronRight, size: 14, color: GmColors.gold),
              ],
            ),
          ),
        ),
      );
}

// ── Hueco en el Inicio ─────────────────────────────────────────────────────

/// El hueco de la campaña en el Inicio, encima de «Hoy»: decide la hoja y
/// el módulo. Mientras la hoja está abierta no pinta el módulo; al cerrarla
/// entra con GmRise. Incluye su propio margen superior (40) cuando se ve.
/// La hoja solo sale sin votar; «ya votó» sale de la caché de `my-votes`
/// ([PremiosVotedStore]) para no activar App Check al arrancar.
class PremiosHomeSlot extends StatefulWidget {
  /// Inyectables para tests.
  final bool? enabled;
  final DateTime Function()? clock;
  final PremiosRankingController? ranking;

  const PremiosHomeSlot({super.key, this.enabled, this.clock, this.ranking});

  static final _refreshTick = ValueNotifier<int>(0);

  /// Pull-to-refresh del Inicio: vuelve a pedir la edición y los resultados.
  static void refresh() => _refreshTick.value++;

  @override
  State<PremiosHomeSlot> createState() => _PremiosHomeSlotState();
}

class _PremiosHomeSlotState extends State<PremiosHomeSlot> {
  bool _enabled = false;
  bool _ready = false;
  bool _sheetOpen = false;
  int _rise = 0;
  PremiosRankingController? _ranking;
  bool _ownsRanking = false;

  DateTime get _now => (widget.clock ?? DateTime.now)();
  PremiosEdition get _edition => PremiosEditionStore.instance.current;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled ?? premiosHomeEnabled();
    if (!_enabled) return;
    PremiosEditionStore.instance.ensureLoaded();
    PremiosEditionStore.instance.addListener(_onChange);
    PremiosVotedStore.instance.addListener(_onChange);
    PremiosHomeSlot._refreshTick.addListener(_onPull);
    _init();
  }

  void _onPull() {
    PremiosEditionStore.instance.refresh(HttpRemoteRepository(Client()));
    _ranking?.refresh();
  }

  @override
  void dispose() {
    PremiosEditionStore.instance.removeListener(_onChange);
    PremiosVotedStore.instance.removeListener(_onChange);
    PremiosHomeSlot._refreshTick.removeListener(_onPull);
    _ranking?.removeListener(_onChange);
    if (_ownsRanking) _ranking?.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    _ensureRanking();
    _maybeSheet();
  }

  Future<void> _init() async {
    await PremiosVotedStore.instance.ensureLoaded();
    await PremiosEditionStore.instance.loading;
    if (!mounted) return;
    setState(() => _ready = true);
    _ensureRanking();
    _maybeSheet();
  }

  /// Los resultados solo se piden si la campaña se enseña.
  void _ensureRanking() {
    if (_ranking != null || !_edition.showOnHome(_now)) return;
    _ranking = widget.ranking ?? PremiosResultsController();
    _ownsRanking = widget.ranking == null;
    _ranking!.addListener(_onChange);
    if (_ranking!.state.load != PremiosLoad.ready) _ranking!.refresh();
  }

  Future<void> _maybeSheet() async {
    if (!_ready || PremiosHomeStore.sheetShownThisSession) return;
    final phase = _edition.phase(_now);
    if (!phase.counting) return;
    PremiosHomeStore.sheetShownThisSession = true;
    final dismissed = await PremiosHomeStore.dismissedAt();
    if (!mounted) return;
    final show = premiosShouldShowSheet(
        phase: phase,
        voted: PremiosVotedStore.instance.hasVoted,
        dismissedAt: dismissed,
        now: _now);
    if (!show) return;
    setState(() => _sheetOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSheet());
  }

  Future<void> _showSheet() async {
    if (!mounted) return;
    final vote = await showPremiosSheet(context);
    if (!mounted) return;
    setState(() {
      _sheetOpen = false;
      _rise++;
    });
    if (vote == true) {
      _openEntry();
    } else {
      PremiosHomeStore.dismiss(_now);
    }
  }

  Future<void> _openEntry() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PremiosEntryPage(),
    ));
    _ranking?.refresh();
  }

  Future<void> _voteAgain() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PremiosVotePage(),
    ));
    _ranking?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || !_ready || _sheetOpen) return const SizedBox.shrink();
    final edition = _edition;
    final now = _now;
    // Sin fecha, antes de abrir o pasados 15 días del cierre: nada.
    if (!edition.showOnHome(now)) return const SizedBox.shrink();
    final phase = edition.phase(now);
    final variant = phase == PremiosPhase.closed
        ? PremiosCardVariant.closed
        : (PremiosVotedStore.instance.hasVoted
            ? PremiosCardVariant.voted
            : PremiosCardVariant.notVoted);
    final r = _ranking;
    final total = r?.state.totalVotes ?? 0;
    void push(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    return Padding(
      padding: const EdgeInsets.only(top: GmSpace.section),
      child: GmRise(
        key: ValueKey(_rise),
        index: 1,
        trigger: GmTrigger.mount,
        child: PremiosWineCard(
          variant: variant,
          ranking: r?.state ?? const PremiosRankingState(),
          totalVotes: total,
          remaining: phase.counting ? edition.remainingLabel(now) : '',
          onVote: variant == PremiosCardVariant.voted ? _voteAgain : _openEntry,
          onRanking: () => push(PremiosRankingPage(controller: _ranking)),
          onMyVotes: () => push(PremiosMyVotesPage(
              controller: _ranking ?? PremiosResultsController())),
          onHowTo: _openEntry,
        ),
      ),
    );
  }
}
