import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_logic.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_share_card.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_story_sheet.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Detalle del canarismo (tablero «Canarismo»): hero vino a sangre con la
/// palabra y su significado sobre el mantel, bloque «Comparte el canarismo»
/// (abre la hoja «Tarjeta para historias»), «Canarismos anteriores» y pie.
///
/// [initial] es la voz que se enseña y [date] su día (hoy por defecto). Si
/// no es la de hoy, no dice «del día». [today] solo para tests.
class CanarismoDetailScreen extends StatefulWidget {
  final Canarismo initial;
  final DateTime? date;
  final DateTime? today;

  const CanarismoDetailScreen({
    super.key,
    required this.initial,
    this.date,
    this.today,
  });

  @override
  State<CanarismoDetailScreen> createState() => _CanarismoDetailScreenState();
}

class _CanarismoDetailScreenState extends State<CanarismoDetailScreen> {
  final _scroll = ScrollController();
  final _heroKey = GlobalKey();
  late final DateTime _today;
  late final DateTime _date;
  late final bool _isToday;
  bool _pastHero = false;

  @override
  void initState() {
    super.initState();
    _today = widget.today ?? DateTime.now();
    _date = widget.date ?? _today;
    _isToday = canarismoIsSameDay(_date, _today);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final heroH = _heroKey.currentContext?.size?.height ?? 352;
    final top = MediaQuery.paddingOf(context).top;
    final past = _scroll.offset > heroH - top - 52;
    if (past != _pastHero) setState(() => _pastHero = past);
  }

  void _share() => shareCanarismoAsImage(
        context,
        widget.initial,
        date: _date,
        isToday: _isToday,
      );

  void _openCard() => showCanarismoStorySheet(
        context,
        canarismo: widget.initial,
        date: _date,
        isToday: _isToday,
      );

  void _openHistory(CanarismoHistoryEntry e) {
    Analytics.I.logEvent(AnalyticsEvents.canarismoOpened, {
      'palabra': e.canarismo.palabra,
      'source': 'detail_history',
    });
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CanarismoDetailScreen(
          initial: e.canarismo,
          date: e.date,
          today: widget.today,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final mq = MediaQuery.of(context);
    final history = canarismoHistory(_date, _today);
    final darkBar = _pastHero && !gm.isDark;

    return Semantics(
      identifier: 'canarismo-detail-screen',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            (darkBar ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
                .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: gm.canvas,
          body: Stack(
            children: [
              ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  _Hero(
                    key: _heroKey,
                    canarismo: widget.initial,
                    eyebrow: canarismoDetailEyebrow(_date, isToday: _isToday),
                  ),
                  // Se monta 22 sobre el mantel del hero.
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: GmRise(
                      index: 1,
                      child: _ShareBlock(
                        canarismo: widget.initial,
                        date: _date,
                        isToday: _isToday,
                        onCreate: _openCard,
                      ),
                    ),
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 36 - 22),
                    GmRise(
                      index: 2,
                      child: GmSectionHeader(
                        eyebrow: GmEyebrow(
                          text: canarismoHistoryEyebrow(history.length,
                              isToday: _isToday),
                        ),
                        title: 'Canarismos anteriores',
                      ),
                    ),
                    const SizedBox(height: 10),
                    GmRise(
                      index: 3,
                      child: _HistoryGroup(
                        entries: history,
                        onTap: _openHistory,
                      ),
                    ),
                  ],
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, history.isEmpty ? 0 : 18, 20, 0),
                    child: Text(
                      'Una palabra nueva cada día, igual para todo el mundo. '
                      'El habla cambia entre islas y comarcas: si en tu '
                      'pueblo se dice distinto, cuéntanoslo.',
                      style: GmText.meta(color: gm.label2),
                    ),
                  ),
                  SizedBox(height: mq.padding.bottom + 40),
                ],
              ),
              GmTopScrim(visible: _pastHero, extra: 60),
              // Botones fijos: cristal oscuro sobre el hero, claro sobre el
              // lienzo al pasar el hero.
              Positioned(
                left: 16,
                right: 16,
                top: mq.padding.top + 2,
                child: Row(
                  children: [
                    GmToolbarButton(
                      icon: GmIcons.chevronLeft,
                      iconSize: 20,
                      light: _pastHero,
                      semanticLabel: 'Volver',
                      identifier: 'canarismo-detail-back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    GmToolbarButton(
                      icon: GmIcons.share,
                      iconSize: 19,
                      light: _pastHero,
                      semanticLabel: 'Compartir',
                      identifier: 'canarismo-detail-share',
                      onTap: _share,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero vino a sangre (con la barra de estado): antetítulo oro, palabra en
/// Display, filete oro, «Qué significa» y significado; mantel abajo.
class _Hero extends StatelessWidget {
  final Canarismo canarismo;
  final String eyebrow;

  const _Hero({super.key, required this.canarismo, required this.eyebrow});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final mq = MediaQuery.of(context);
    final top = mq.padding.top;
    final gold = GmText.eyebrow(color: GmColors.gold);
    final wordStyle = DefaultTextStyle.of(context)
        .style
        .merge(GmText.display(color: GmColors.creamHi));
    final fit = fitCanarismoWord(
      canarismo.palabra,
      wordStyle,
      mq.size.width - 40,
      maxSize: 46,
      minSize: 30,
      textScaler: mq.textScaler,
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: kCanarismoHeroGradient),
      position: DecorationPosition.background,
      child: DecoratedBox(
        // Noche: filo oro bajo el hero (wineEdge; transparente de día).
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: gm.wineEdge)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 26,
              top: top + 62,
              child: const ExcludeSemantics(child: CanarismoSparkle(size: 44)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 64, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 44),
                        child: Text(eyebrow, style: gold),
                      ),
                      const SizedBox(height: 6),
                      Semantics(
                        identifier: 'canarismo-detail-word',
                        header: true,
                        child: Text(
                          canarismo.palabra,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: fit.style,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: GmColors.gold,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Qué significa', style: gold),
                      const SizedBox(height: 6),
                      Text(
                        canarismo.significado,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 27 / 20,
                          color: kCanarismoMeaning,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                    ],
                  ),
                ),
                const CanarismoGinghamStrip(
                  height: 30,
                  base: kCanarismoHeroGinghamBase,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta «Comparte el canarismo»: miniatura girada −4°, título, texto y
/// cápsula «Crear tarjeta».
class _ShareBlock extends StatelessWidget {
  final Canarismo canarismo;
  final DateTime date;
  final bool isToday;
  final VoidCallback onCreate;

  const _ShareBlock({
    required this.canarismo,
    required this.date,
    required this.isToday,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: GmCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Transform.rotate(
              angle: -4 * math.pi / 180,
              child: ExcludeSemantics(
                child: CanarismoStoryPreview(
                  width: 84,
                  canarismo: canarismo,
                  date: date,
                  isToday: isToday,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    canarismoShareTitle(isToday: isToday),
                    style: GmText.guideTitle(color: gm.label).copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Genera una tarjeta para tus historias y enséñale a '
                    'quien quieras una palabra nuestra.',
                    style: GmText.sub(color: gm.label2),
                  ),
                  const SizedBox(height: 12),
                  GmCapsuleButton(
                    label: 'Crear tarjeta',
                    icon: GmIcons.share,
                    iconSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    identifier: 'canarismo-detail-create-card',
                    onTap: onCreate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista agrupada de canarismos anteriores (etiqueta relativa, palabra,
/// significado en una línea y chevron).
class _HistoryGroup extends StatelessWidget {
  final List<CanarismoHistoryEntry> entries;
  final ValueChanged<CanarismoHistoryEntry> onTap;

  const _HistoryGroup({required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        children.add(Container(
          height: 1,
          margin: const EdgeInsets.only(left: 16),
          color: gm.sep,
        ));
      }
      final e = entries[i];
      children.add(Semantics(
        identifier: 'canarismo-detail-history-row-$i',
        button: true,
        child: GmPressable(
          onTap: () => onTap(e),
          pressedScale: 0.98,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.label, style: GmText.chip(color: gm.label2)),
                        Text(
                          e.canarismo.palabra,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.guideTitle(color: gm.label),
                        ),
                        Text(
                          e.canarismo.significado,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.meta(color: gm.label2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: GmCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}
