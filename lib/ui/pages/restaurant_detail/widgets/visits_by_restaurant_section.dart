import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/components/glass_sheet.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/pros_cons_section.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';

/// "VISITAS DE JONAY Y JOANA" en la ficha del negocio.
///
/// En vez de sacar al usuario a una página aparte (que duplicaría info,
/// servicios y NTK que ya están en la ficha), cada visita es un **desplegable
/// curado**: una fila CTA "¿Quieres ver la visita?" que abre/cierra inline solo
/// lo ÚNICO de la visita — vídeo + veredicto (a favor/en contra) + platos
/// probados. El resto (info del local) no se repite; para verla completa hay un
/// enlace que abre el sheet glass.
class VisitsByRestaurantSection extends StatelessWidget {
  final List<Visit> visits;

  const VisitsByRestaurantSection({super.key, required this.visits});

  static bool shouldRender(List<Visit> visits) => visits.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'VISITAS DE JONAY Y JOANA',
            style: AppTextStyles.displaySection(
              size: 11,
              color: AppColors.atlantico,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < visits.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: context.brand.border),
            ),
          _VisitExpandable(visit: visits[i]),
        ],
      ],
    );
  }
}

class _VisitExpandable extends StatefulWidget {
  final Visit visit;
  const _VisitExpandable({required this.visit});

  @override
  State<_VisitExpandable> createState() => _VisitExpandableState();
}

class _VisitExpandableState extends State<_VisitExpandable> {
  bool _open = false;

  static const _months = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  String? _dateLabel(String? raw) {
    if (raw == null) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return '${d.day} ${_months[d.month - 1]} ${d.year.toString().substring(2)}';
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final v = widget.visit;
    final date = _dateLabel(v.sortDate);
    final eyebrow = [
      if (v.creator != null && v.creator!.trim().isNotEmpty)
        v.creator!.toUpperCase()
      else
        'JONAY Y JOANA',
      if (date != null) date,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fila CTA (abre/cierra) ──────────────────────────────────────
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _Thumb(thumbnail: v.thumbnail),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: AppTextStyles.eyebrow(size: 10)
                            .copyWith(letterSpacing: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _open ? 'Ocultar visita' : '¿Quieres ver la visita?',
                        style: AppTextStyles.displaySection(
                          size: 15,
                          color: brand.textPrimary,
                        ).copyWith(letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.atlanticoClaro, size: 26),
                ),
              ],
            ),
          ),
        ),
        // ── Contenido desplegable (curado) ──────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: _ExpandedContent(visit: v),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 240),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final Visit visit;
  const _ExpandedContent({required this.visit});

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final hasVideo =
        v.youtubeVideoId != null && v.youtubeVideoId!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVideo) ...[
          _VideoTeaser(visit: v),
          const SizedBox(height: 14),
        ],
        if (v.summary != null && v.summary!.trim().isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              v.summary!,
              style: AppTextStyles.editorial(size: 13),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (ProsConsSection.shouldRender(v.highlights, v.lowlights)) ...[
          ProsConsSection(pros: v.highlights, cons: v.lowlights),
          const SizedBox(height: 14),
        ],
        if (DishesSection.shouldRender(v.dishes)) ...[
          DishesSection(dishes: v.dishes, heroPrefix: v.id),
          const SizedBox(height: 14),
        ],
        // Acceso a la visita completa (sheet glass) — opcional.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showGlassSheet(
              context,
              child: VisitDetailPage(visitId: v.id, asSheet: true),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver visita completa',
                  style: AppTextStyles.ui(
                    size: 12,
                    color: AppColors.atlanticoClaro,
                    weight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.atlanticoClaro, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoTeaser extends StatelessWidget {
  final Visit visit;
  const _VideoTeaser({required this.visit});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => YoutubeEmbedSheet.show(
          context,
          videoId: visit.youtubeVideoId!,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (visit.thumbnail != null && visit.thumbnail!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: visit.thumbnail!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: brand.surface),
                    errorWidget: (_, __, ___) =>
                        Container(color: brand.surface),
                  )
                else
                  Container(color: brand.surface),
                // Scrim + botón play.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                  ),
                ),
                Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 34),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? thumbnail;
  const _Thumb({required this.thumbnail});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnail != null && thumbnail!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumbnail!,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                placeholder: (_, __) => Container(color: brand.surface),
                errorWidget: (_, __, ___) => Container(color: brand.surface),
              )
            else
              Container(color: brand.surface),
            DecoratedBox(
              decoration:
                  BoxDecoration(color: Colors.black.withOpacity(0.22)),
            ),
            const Center(
              child: Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
