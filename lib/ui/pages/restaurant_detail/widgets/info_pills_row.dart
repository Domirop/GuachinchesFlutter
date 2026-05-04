import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/utils/horarios_utils.dart';

class InfoPillsRow extends StatelessWidget {
  final Restaurant restaurant;

  const InfoPillsRow({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final pills = <_PillData>[];

    pills.add(_PillData(
      label: 'ESTADO',
      value: restaurant.open ? 'Abierto' : 'Cerrado',
      valueColor: restaurant.open ? AppColors.laurisilva : AppColors.mojo,
    ));

    final scheduleNow = _todayScheduleText();
    if (scheduleNow != null) {
      pills.add(_PillData(label: 'HORARIO', value: scheduleNow));
    }

    if (restaurant.minPrice != null && restaurant.maxPrice != null) {
      pills.add(_PillData(
        label: 'PRECIO',
        value: '${restaurant.minPrice}–${restaurant.maxPrice}€',
      ));
    }

    if (restaurant.avgRating > 0) {
      pills.add(_PillData(
        label: 'RATING',
        value: restaurant.avgRating.toStringAsFixed(1),
        valueColor: AppColors.sol,
      ));
    }

    if (restaurant.valoraciones.isNotEmpty) {
      pills.add(_PillData(
        label: 'RESEÑAS',
        value: restaurant.valoraciones.length.toString(),
      ));
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => _Pill(data: pills[i]),
      ),
    );
  }

  String? _todayScheduleText() {
    final json = restaurant.horariosJson;
    if (json == null) return null;
    try {
      final status = getOpenStatus(json, DateTime.now());
      return status;
    } catch (_) {
      return null;
    }
  }
}

class _PillData {
  final String label;
  final String value;
  final Color? valueColor;
  _PillData({required this.label, required this.value, this.valueColor});
}

class _Pill extends StatelessWidget {
  final _PillData data;
  const _Pill({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 60),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: AppTextStyles.eyebrow(
              size: 7,
              color: context.brand.textMuted,
            ).copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            style: AppTextStyles.chipLabel(
              size: 11,
              color: data.valueColor ?? AppColors.crema,
            ),
          ),
        ],
      ),
    );
  }
}
