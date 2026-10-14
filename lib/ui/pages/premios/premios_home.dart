import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
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

// ── Módulo «Premios 2026 en directo» ───────────────────────────────────────

enum PremiosLiveVariant { notVoted, voted, closed }

/// El módulo del Inicio (tablero EncuestaInicioTarjeta), encima de «Hoy»:
/// antetítulo «● En directo · Premios 2026 · N votos», «Así va la votación ›»,
/// barrica pequeña asomando, segmentado y podio compacto en vino, «Tu voto»
/// y el pie con la cuenta atrás y «Votar». Cerrada: «Ganadores 2026».
class PremiosLiveSection extends StatefulWidget {
  final PremiosLiveVariant variant;
  final PremiosRankingState ranking;
  final int totalVotes;
  final String remaining;
  final VoidCallback onVote;
  final VoidCallback onRanking;

  const PremiosLiveSection({
    super.key,
    required this.variant,
    required this.ranking,
    required this.totalVotes,
    required this.remaining,
    required this.onVote,
    required this.onRanking,
  });

  @override
  State<PremiosLiveSection> createState() => _PremiosLiveSectionState();
}

class _PremiosLiveSectionState extends State<PremiosLiveSection> {
  PremiosCategory _tab = PremiosCategory.tradicional;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final closed = widget.variant == PremiosLiveVariant.closed;
    final list = widget.ranking.of(_tab);
    final mine = widget.variant == PremiosLiveVariant.notVoted
        ? null
        : list.where((e) => e.mine).firstOrNull;
    final eyebrow = closed
        ? const PremiosEyebrow()
        : GmEyebrow(
            spans: [
              TextSpan(
                  text: 'En directo', style: TextStyle(color: gm.greenText)),
              TextSpan(
                  text: widget.totalVotes > 0
                      ? ' · Premios 2026 · ${premiosVotes(widget.totalVotes)}'
                      : ' · Premios 2026'),
            ],
            leading: const GmLiveDot(),
          );
    return Semantics(
      identifier: 'home-premios-live',
      container: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 96),
                child: GmSectionHeader(
                  eyebrow: eyebrow,
                  title: closed ? 'Ganadores 2026' : 'Así va la votación',
                  onTap: widget.onRanking,
                  identifier: 'home-premios-title',
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
                child: GmCard(
                  radius: GmRadius.guide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: PremiosSegmented(
                            value: _tab,
                            flat: true,
                            identifierPrefix: 'home-premios-tab',
                            onChanged: (c) => setState(() => _tab = c),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: switch (widget.ranking.load) {
                            PremiosLoad.ready when list.isNotEmpty =>
                              PodioPremios(
                                key: ValueKey(_tab),
                                category: _tab,
                                entries: list.take(3).toList(),
                                compact: true,
                              ),
                            PremiosLoad.ready => SizedBox(
                                height: 72,
                                child: Center(
                                  child: Text(
                                      'Aún no hay votos. ¡Estrena el podio!',
                                      style: GmText.meta(color: gm.label2)),
                                ),
                              ),
                            _ => const _PodiumSkeleton(),
                          },
                        ),
                        if (mine != null) _MineRow(entry: mine, closed: closed),
                        const SizedBox(height: 14),
                        Container(height: 1, color: gm.sep),
                        closed
                            ? _ClosedFoot(onTap: widget.onRanking)
                            : _OpenFoot(
                                voted:
                                    widget.variant == PremiosLiveVariant.voted,
                                remaining: widget.remaining,
                                onVote: widget.onVote,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            right: 24,
            top: -18,
            child: PremiosMiniBarrel(width: 58),
          ),
        ],
      ),
    );
  }
}

class _PodiumSkeleton extends StatelessWidget {
  const _PodiumSkeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget col(double h) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: gm.fill, shape: BoxShape.circle),
              ),
              const SizedBox(height: 7),
              Container(
                height: h,
                decoration: BoxDecoration(
                  color: gm.fill,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12), bottom: Radius.circular(5)),
                ),
              ),
            ],
          ),
        );
    return SizedBox(
      height: 168,
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                col(40),
                const SizedBox(width: 8),
                col(54),
                const SizedBox(width: 8),
                col(30)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Tu voto · Guachinche Casa Pepe · Va 4.º con 5 votos».
class _MineRow extends StatelessWidget {
  final PremiosRankEntry entry;
  final bool closed;
  const _MineRow({required this.entry, required this.closed});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final pos = '${closed ? 'Quedó' : 'Va'} ${entry.rank}.º con '
        '${premiosVotes(entry.votes)}';
    return Semantics(
      identifier: 'home-premios-mine',
      label: 'Tu voto: ${entry.name}. $pos',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: gm.fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gm.okSoft,
                borderRadius: BorderRadius.circular(GmRadius.pill),
              ),
              child: Text('Tu voto',
                  style: GmText.chip(color: gm.greenText, w: FontWeight.w700)
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
                      style: GmText.sub(color: gm.label, w: FontWeight.w600)
                          .copyWith(height: 18 / 14)),
                  Text(pos,
                      style: GmText.chip(color: gm.label2, w: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenFoot extends StatelessWidget {
  final bool voted;
  final String remaining;
  final VoidCallback onVote;
  const _OpenFoot(
      {required this.voted, required this.remaining, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    voted
                        ? 'Ya has votado'
                        : '¿Cuál es tu guachinche favorito?',
                    style: GmText.body(color: gm.label, w: FontWeight.w600)
                        .copyWith(letterSpacing: -0.2)),
                if (remaining.isNotEmpty)
                  Text(remaining, style: GmText.meta(color: gm.label2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          voted
              ? GmSoftCapsuleButton(
                  label: 'Votar a otros sitios',
                  identifier: 'home-premios-vote-again',
                  fontSize: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: onVote,
                )
              : GmCapsuleButton(
                  label: 'Votar',
                  identifier: 'home-premios-vote',
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  onTap: onVote,
                ),
        ],
      ),
    );
  }
}

class _ClosedFoot extends StatelessWidget {
  final VoidCallback onTap;
  const _ClosedFoot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'home-premios-ranking',
      button: true,
      label: 'Ver el ranking completo',
      onTap: onTap,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              PremiosPodiumIcon(size: 17, color: gm.label2),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ver el ranking completo',
                    style: GmText.body(color: gm.label, w: FontWeight.w600)),
              ),
              GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
            ],
          ),
        ),
      ),
    );
  }
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
        ? PremiosLiveVariant.closed
        : (PremiosVotedStore.instance.hasVoted
            ? PremiosLiveVariant.voted
            : PremiosLiveVariant.notVoted);
    final r = _ranking;
    final total = r is PremiosResultsController ? r.totalVotes : 0;
    return Padding(
      padding: const EdgeInsets.only(top: GmSpace.section),
      child: GmRise(
        key: ValueKey(_rise),
        index: 1,
        trigger: GmTrigger.mount,
        child: PremiosLiveSection(
          variant: variant,
          ranking: r?.state ?? const PremiosRankingState(),
          totalVotes: total,
          remaining: phase.counting ? edition.remainingLabel(now) : '',
          onVote: variant == PremiosLiveVariant.voted ? _voteAgain : _openEntry,
          onRanking: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PremiosRankingPage(controller: _ranking),
          )),
        ),
      ),
    );
  }
}
