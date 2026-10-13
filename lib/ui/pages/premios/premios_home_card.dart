import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// ¿Se enseña la campaña en el Inicio? Remote Config `show_premios`
/// (apagado por defecto); en debug se fuerza con `ENABLE_PREMIOS=true` en
/// `env_files/debug.env`. Las pantallas de la encuesta no dependen de esto:
/// solo la tarjeta y la hoja del Inicio.
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

enum PremiosCardVariant { notVoted, voted, closed }

/// Ganador de una categoría para la tarjeta cerrada («empate a 4 votos»).
@immutable
class PremiosWinner {
  final PremiosCategory category;
  final List<String> names;
  final int votes;
  const PremiosWinner(this.category, this.names, this.votes);

  static PremiosWinner? of(PremiosCategory c, List<PremiosRankEntry> list) {
    final top = list.where((e) => e.rank == 1).toList();
    if (top.isEmpty) return null;
    return PremiosWinner(c, [for (final e in top) e.name], top.first.votes);
  }

  String get meta {
    final cat =
        category == PremiosCategory.tradicional ? 'Tradicional' : 'Moderno';
    return names.length > 1
        ? '$cat · empate a ${premiosVotes(votes)}'
        : '$cat · ${premiosVotes(votes)}';
  }

  String get label => names.length <= 1
      ? names.join()
      : '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}

// ── Tarjeta del Inicio ─────────────────────────────────────────────────────

/// Tarjeta vino + oro de la encuesta (entre «Hoy» y el quiz): barrica
/// pequeña, «Tradicional · Moderno» como texto, «Votar ahora» + «Ahora no»
/// y el pie «Ver el ranking · Quedan 12 días». Tres estados.
class PremiosHomeCard extends StatelessWidget {
  final PremiosCardVariant variant;
  final String remaining;

  /// «hasta el 20 de marzo».
  final String untilShort;
  final List<PremiosWinner> winners;
  final VoidCallback onVote;
  final VoidCallback onNotNow;
  final VoidCallback onRanking;

  const PremiosHomeCard({
    super.key,
    required this.variant,
    required this.remaining,
    required this.untilShort,
    this.winners = const [],
    required this.onVote,
    required this.onNotNow,
    required this.onRanking,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final (eyebrow, title, body) = switch (variant) {
      PremiosCardVariant.notVoted => (
          'Premios Donde Comer Canarias 2026',
          '¿Cuál es tu guachinche favorito?',
          'Vota y decide quiénes merecen los premios de este año.'
        ),
      PremiosCardVariant.voted => (
          'Premios 2026 · ya votaste',
          '¡Gracias por votar!',
          'Tu voto ya está en la barrica. Puedes votar a otros guachinches'
              '${untilShort.isEmpty ? '' : ' $untilShort'}.'
        ),
      PremiosCardVariant.closed => (
          'Premios 2026 · ganadores',
          'Ya tenemos ganadores',
          'Gracias a todos los que votaron. Estos son los favoritos de este año.'
        ),
    };
    final closed = variant == PremiosCardVariant.closed;
    return Semantics(
      identifier: 'home-premios-card',
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: GmColors.wine,
          borderRadius: BorderRadius.circular(GmRadius.guide),
          border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
          boxShadow: const [
            BoxShadow(
                color: PremiosColors.wineShadow,
                offset: Offset(0, 14),
                blurRadius: 34,
                spreadRadius: -14),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GmRadius.guide),
          child: Stack(
            children: [
              const Positioned.fill(child: _CardGlow()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 18, 16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          right: -6,
                          top: -10,
                          child: PremiosMiniBarrel(width: 86),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PremiosEyebrow(
                                text: eyebrow, color: PremiosColors.goldText),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(right: 84),
                              child: Text(title,
                                  style:
                                      GmText.title2(color: GmColors.creamHi)),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(right: 84),
                              child: Text(body,
                                  style: GmText.body(
                                      color: PremiosColors.cream82)),
                            ),
                            if (variant == PremiosCardVariant.notVoted) ...[
                              const SizedBox(height: 10),
                              const _CategoriesMeta(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  GmCapsuleButton(
                                    label: 'Votar ahora',
                                    identifier: 'home-premios-vote',
                                    onTap: onVote,
                                  ),
                                  const SizedBox(width: 4),
                                  _WineTextButton(
                                    label: 'Ahora no',
                                    identifier: 'home-premios-not-now',
                                    onTap: onNotNow,
                                  ),
                                ],
                              ),
                            ],
                            if (variant == PremiosCardVariant.voted) ...[
                              const SizedBox(height: 16),
                              _WineSoftButton(
                                label: 'Votar a otros sitios',
                                identifier: 'home-premios-vote-again',
                                onTap: onVote,
                              ),
                            ],
                            if (closed && winners.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              for (final w in winners) _WinnerRow(w),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    identifier: 'home-premios-ranking',
                    button: true,
                    child: GmPressable(
                      onTap: onRanking,
                      pressedScale: 0.98,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 50),
                        padding: const EdgeInsets.fromLTRB(22, 0, 20, 0),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: PremiosColors.creamLine)),
                        ),
                        child: Row(
                          children: [
                            const PremiosPodiumIcon(
                                size: 17, color: PremiosColors.goldText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                closed
                                    ? 'Ver el ranking completo'
                                    : 'Ver el ranking',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.body(
                                    color: GmColors.creamHi,
                                    w: FontWeight.w600),
                              ),
                            ),
                            if (!closed)
                              Text(remaining,
                                  style: GmText.eyebrow(
                                      color: PremiosColors.cream2)),
                            const SizedBox(width: 6),
                            GmIcon(GmIcons.chevronRight,
                                size: 14, color: GmColors.gold),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGlow extends StatelessWidget {
  const _CardGlow();

  @override
  Widget build(BuildContext context) => const Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.3,
                colors: [PremiosColors.goldGlow, Color(0x00C9A96B)],
                stops: [0, 0.55],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 0.9,
                colors: [PremiosColors.wineGlow, Color(0x00781E2D)],
                stops: [0, 0.7],
              ),
            ),
          ),
        ],
      );
}

/// «Tradicional · Moderno» como texto meta (no son botones).
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

class _WinnerRow extends StatelessWidget {
  final PremiosWinner w;
  const _WinnerRow(this.w);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: PremiosColors.creamLine))),
        child: Row(
          children: [
            w.category == PremiosCategory.tradicional
                ? const PremiosCopa(size: 18, ink: PremiosColors.creamInk)
                : const PremiosMantel(size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.meta,
                      style: GmText.chip(color: PremiosColors.goldText)),
                  Text(w.label,
                      style: GmText.body(
                          color: GmColors.creamHi, w: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _WineTextButton extends StatelessWidget {
  final String label;
  final String identifier;
  final VoidCallback onTap;
  const _WineTextButton(
      {required this.label, required this.identifier, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: identifier,
        button: true,
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.95,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GmColors.creamHi)),
          ),
        ),
      );
}

class _WineSoftButton extends StatelessWidget {
  final String label;
  final String identifier;
  final VoidCallback onTap;
  const _WineSoftButton(
      {required this.label, required this.identifier, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: identifier,
        button: true,
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.95,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: PremiosColors.creamFill,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              border: Border.all(color: PremiosColors.creamEdge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: GmColors.creamHi)),
              ],
            ),
          ),
        ),
      );
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

// ── Hueco en el Inicio ─────────────────────────────────────────────────────

/// El hueco de la campaña en el Inicio: decide hoja o tarjeta y su estado.
/// Mientras la hoja está abierta no pinta la tarjeta; al cerrarla entra con
/// GmRise. Incluye su propio margen superior (40) cuando se ve.
class PremiosHomeSlot extends StatefulWidget {
  /// Inyectables para tests.
  final bool? enabled;
  final DateTime Function()? clock;

  const PremiosHomeSlot({super.key, this.enabled, this.clock});

  @override
  State<PremiosHomeSlot> createState() => _PremiosHomeSlotState();
}

class _PremiosHomeSlotState extends State<PremiosHomeSlot> {
  bool _enabled = false;
  bool _ready = false;
  bool _voted = false;
  bool _sheetOpen = false;
  bool _hidden = false;
  int _rise = 0;
  LegacyPremiosRankingController? _ranking;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled ?? premiosHomeEnabled();
    if (_enabled) {
      PremiosEditionStore.instance.ensureLoaded();
      PremiosEditionStore.instance.addListener(_onEdition);
      _init();
    }
  }

  @override
  void dispose() {
    PremiosEditionStore.instance.removeListener(_onEdition);
    _ranking?.dispose();
    super.dispose();
  }

  void _onEdition() {
    if (!mounted) return;
    setState(() {});
    _ensureRanking();
  }

  Future<void> _init() async {
    final voted = await PremiosHomeStore.hasVoted();
    final dismissed = await PremiosHomeStore.dismissedAt();
    final cardDismissed = await PremiosHomeStore.cardDismissedAt();
    if (!mounted) return;
    final now = _now;
    final phase = PremiosEditionStore.instance.current.phase(now);
    final sheet = !PremiosHomeStore.sheetShownThisSession &&
        premiosShouldShowSheet(
            phase: phase, voted: voted, dismissedAt: dismissed, now: now);
    setState(() {
      _voted = voted;
      _ready = true;
      _sheetOpen = sheet;
      _hidden = premiosRecentlyDismissed(cardDismissed, now);
    });
    _ensureRanking();
    if (sheet) {
      PremiosHomeStore.sheetShownThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSheet());
    }
  }

  /// Con la votación cerrada la tarjeta enseña a los ganadores.
  void _ensureRanking() {
    if (_ranking != null) return;
    if (PremiosEditionStore.instance.current.phase(_now) !=
        PremiosPhase.closed) {
      return;
    }
    _ranking = LegacyPremiosRankingController()..addListener(_onRanking);
    _ranking!.refresh();
  }

  void _onRanking() {
    if (mounted) setState(() {});
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
    _refreshVoted();
  }

  Future<void> _voteAgain() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PremiosVotePage(),
    ));
    _refreshVoted();
  }

  Future<void> _refreshVoted() async {
    final v = await PremiosHomeStore.hasVoted();
    if (mounted && v != _voted) setState(() => _voted = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || !_ready || _sheetOpen || _hidden) {
      return const SizedBox.shrink();
    }
    final edition = PremiosEditionStore.instance.current;
    final now = _now;
    final phase = edition.phase(now);
    // Sin fecha de cierre (o antes de abrir) la campaña no se anuncia.
    if (phase == PremiosPhase.unknown || phase == PremiosPhase.upcoming) {
      return const SizedBox.shrink();
    }
    final variant = phase == PremiosPhase.closed
        ? PremiosCardVariant.closed
        : (_voted ? PremiosCardVariant.voted : PremiosCardVariant.notVoted);
    final r = _ranking?.state;
    final winners = r == null || r.load != PremiosLoad.ready
        ? const <PremiosWinner>[]
        : [
            for (final c in PremiosCategory.values)
              if (PremiosWinner.of(c, r.of(c)) case final w?) w,
          ];
    return Padding(
      padding: const EdgeInsets.only(top: GmSpace.section),
      child: GmRise(
        key: ValueKey(_rise),
        index: 1,
        trigger: GmTrigger.mount,
        child: PremiosHomeCard(
          variant: variant,
          remaining: edition.remainingLabel(now),
          untilShort: edition.untilShort,
          winners: winners,
          onVote: variant == PremiosCardVariant.voted ? _voteAgain : _openEntry,
          onNotNow: () {
            setState(() => _hidden = true);
            PremiosHomeStore.dismissCard(now);
          },
          onRanking: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PremiosRankingPage(controller: _ranking),
          )),
        ),
      ),
    );
  }
}
