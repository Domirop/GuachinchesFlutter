import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/components/pinned_top_bar.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_share_card.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';

const _weekdays = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _longDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} de ${_months[d.month - 1]}';

String _relativeDate(DateTime d, DateTime now) {
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(now.year, now.month, now.day);
  final days = b.difference(a).inDays;
  if (days <= 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  return 'Hace $days días';
}

/// Pantalla de detalle del Canarismo del día: hero editorial con gradiente +
/// greca canaria, significado, atajo de compartir y lista de canarismos
/// anteriores (explorable). Recibe la voz inicial y su fecha (hoy por defecto).
class CanarismoDetailScreen extends StatefulWidget {
  final Canarismo initial;
  final DateTime? date;

  const CanarismoDetailScreen({super.key, required this.initial, this.date});

  @override
  State<CanarismoDetailScreen> createState() => _CanarismoDetailScreenState();
}

class _CanarismoDetailScreenState extends State<CanarismoDetailScreen> {
  late final Canarismo _current;
  late final DateTime _date;
  late final DateTime _now;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _now = DateTime.now();
    _date = widget.date ?? _now;
  }

  void _share() {
    shareCanarismoAsImage(context, _current);
  }

  void _openHistory(Canarismo c, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CanarismoDetailScreen(initial: c, date: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    // Canarismos anteriores: SOLO los que ya han aparecido (días previos a la
    // fecha mostrada, sin bajar nunca del día de lanzamiento). Máximo 5.
    final priorDays = canarismoDayIndex(_date).clamp(0, 5);
    final history = List.generate(priorDays, (i) {
      final d = _date.subtract(Duration(days: i + 1));
      return (date: d, c: canarismoOfDay(d));
    });

    return Semantics(
      identifier: 'canarismo-detail-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        body: Stack(children: [
          ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(
              word: _current.palabra,
              dateLabel: _longDate(_date),
            ),
            // Significado.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUÉ SIGNIFICA',
                    style: AppTextStyles.eyebrow(
                      size: 12,
                      color: AppColors.arena,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _current.significado,
                    style: AppTextStyles.editorial(
                      size: 19,
                      color: brand.textPrimary,
                    ).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  // Compartir (primario).
                  Semantics(
                    identifier: 'canarismo-detail-share',
                    button: true,
                    child: GestureDetector(
                      onTap: _share,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.atlantico,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x330085C4),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.ios_share,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'COMPARTE EL CANARISMO',
                              style: AppTextStyles.eyebrow(
                                size: 13,
                                color: Colors.white,
                              ).copyWith(letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Genera una tarjeta para tus historias y enséñale a quien '
                      'quieras una palabra nuestra.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.muted(size: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Canarismos anteriores — solo si ya ha salido alguno.
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: GrecaBand(),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'CANARISMOS ANTERIORES',
                  style:
                      AppTextStyles.eyebrow(size: 12, color: AppColors.arena),
                ),
              ),
              const SizedBox(height: 6),
              ...history.map(
                (e) => _HistoryTile(
                  canarismo: e.c,
                  relative: _relativeDate(e.date, _now),
                  onTap: () => _openHistory(e.c, e.date),
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
          ),
          // Barra superior anclada: back + compartir fijos al hacer scroll.
          PinnedTopBar(
            onBack: () => Navigator.maybePop(context),
            backIdentifier: 'canarismo-detail-back',
            actions: [
              PinnedCircleButton(
                icon: Icons.ios_share,
                identifier: 'canarismo-detail-share',
                onTap: _share,
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String word;
  final String dateLabel;

  const _Hero({
    required this.word,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    const cream = AppColors.crema;

    return Container(
      decoration: const BoxDecoration(
        gradient: kCanarismoGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Marca de agua: inicial gigante.
          Positioned(
            right: -12,
            bottom: 4,
            child: IgnorePointer(
              child: Text(
                canarismoInitial(word),
                style: AppTextStyles.displayHero(
                  size: 240,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hueco reservado para la barra superior anclada (back + share),
              // que ahora vive fuera del scroll a nivel de Scaffold.
              SafeArea(
                bottom: false,
                child: const SizedBox(height: 46),
              ),
              const SizedBox(height: 56),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EL CANARISMO DEL DÍA',
                      style: AppTextStyles.eyebrow(
                        size: 12,
                        color: cream.withOpacity(0.78),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: AppTextStyles.ui(
                        size: 14,
                        color: cream.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      identifier: 'canarismo-detail-word',
                      child: Text(
                        word.toUpperCase(),
                        style: AppTextStyles.displayHero(
                          size: 56,
                          color: cream,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GrecaBand(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Canarismo canarismo;
  final String relative;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.canarismo,
    required this.relative,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final grad = canarismoAvatarGradient(canarismo.palabra);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar con inicial.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: grad,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                canarismoInitial(canarismo.palabra),
                style: AppTextStyles.displayHero(
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          canarismo.palabra.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displaySection(
                            size: 15,
                            color: brand.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relative,
                        style: AppTextStyles.muted(size: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canarismo.significado,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(
                      size: 13,
                      color: brand.textSecondary,
                    ).copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: brand.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
