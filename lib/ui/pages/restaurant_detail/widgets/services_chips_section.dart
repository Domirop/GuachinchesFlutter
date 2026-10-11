import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

class ServicesChipsSection extends StatelessWidget {
  final List<String> services;

  const ServicesChipsSection({super.key, required this.services});

  static bool shouldRender(List<String> services) => services.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GmDetailTitle('Servicios'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((s) => _ServiceChip(label: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: gm.card,
        borderRadius: BorderRadius.circular(GmRadius.pill),
        boxShadow: gm.shadow1,
      ),
      child: Text(
        _humanize(label),
        style: TextStyle(
          fontSize: 14,
          height: 32 / 14,
          fontWeight: FontWeight.w500,
          color: gm.label,
        ),
      ),
    );
  }

  /// «MENU_DEGUSTACION» → «Menu degustacion»; «acceso_pmr» → «Acceso PMR».
  static String _humanize(String raw) {
    final words = raw.replaceAll('_', ' ').trim().split(RegExp(r'\s+'));
    final out = <String>[];
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) continue;
      final lower = w.toLowerCase();
      if (w.length <= 3 && w == w.toUpperCase() && i > 0) {
        out.add(w); // siglas (PMR, WC)
      } else if (lower == 'pmr' || lower == 'wc') {
        out.add(lower.toUpperCase());
      } else {
        out.add(i == 0 ? lower[0].toUpperCase() + lower.substring(1) : lower);
      }
    }
    return out.join(' ');
  }
}
