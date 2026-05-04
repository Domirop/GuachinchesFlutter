import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

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
          Text(
            'SERVICIOS',
            style: AppTextStyles.displaySection(
              size: 11,
              color: AppColors.atlantico,
            ),
          ),
          const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.brand.elevated,
        border: Border.all(color: context.brand.borderStrong),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.chipLabel(
          size: 10,
          color: context.brand.textPrimary,
        ),
      ),
    );
  }
}
