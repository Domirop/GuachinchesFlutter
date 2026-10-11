import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/pros_cons_section.dart';

/// Aggregates highlights/lowlights across all visits and presents them
/// with a "Generado por IA" badge.
class AiInsightsSection extends StatelessWidget {
  final List<Visit> visits;

  const AiInsightsSection({super.key, required this.visits});

  static bool shouldRender(List<Visit> visits) {
    if (visits.isEmpty) return false;
    return visits.any((v) => v.highlights.isNotEmpty || v.lowlights.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final pros = _dedupe(visits.expand((v) => v.highlights));
    final cons = _dedupe(visits.expand((v) => v.lowlights));
    if (pros.isEmpty && cons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _AiBadge(),
        ),
        const SizedBox(height: 10),
        ProsConsSection(pros: pros, cons: cons),
      ],
    );
  }

  List<String> _dedupe(Iterable<String> items) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in items) {
      final clean = raw.trim();
      if (clean.isEmpty) continue;
      final key = clean.toLowerCase();
      if (seen.add(key)) result.add(clean);
    }
    return result;
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: gm.accentSoft,
        borderRadius: BorderRadius.circular(GmRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: gm.accent),
          const SizedBox(width: 6),
          Text('Resumen con IA',
              style: GmText.chip(color: gm.accent, w: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('a partir de las visitas',
              style: GmText.chip(color: gm.label2, w: FontWeight.w400)),
        ],
      ),
    );
  }
}
