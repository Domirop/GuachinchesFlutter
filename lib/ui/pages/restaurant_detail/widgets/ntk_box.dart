import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:url_launcher/url_launcher.dart';

class NTKBox extends StatelessWidget {
  final Restaurant restaurant;
  final Visit? visit;
  final String? instagram;

  const NTKBox({
    super.key,
    required this.restaurant,
    this.visit,
    this.instagram,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_NTKRowData>[];

    final address = _firstNonEmpty([visit?.address, restaurant.direccion]);
    if (address != null) {
      rows.add(_NTKRowData(key: 'DIRECCIÓN', value: address));
    }

    final schedule = _scheduleLine();
    if (schedule != null) {
      rows.add(_NTKRowData(key: 'HORARIO', value: schedule));
    }

    final phone = _firstNonEmpty([visit?.phone, restaurant.telefono]);
    if (phone != null) {
      rows.add(_NTKRowData(
        key: 'TELÉFONO',
        value: phone,
        color: AppColors.atlanticoClaro,
        onTap: () async {
          final uri = Uri.parse('tel:$phone');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ));
    }

    final igRaw = _firstNonEmpty([instagram, visit?.instagram]);
    if (igRaw != null) {
      final handle = igRaw.startsWith('@') ? igRaw : '@$igRaw';
      rows.add(_NTKRowData(
        key: 'INSTAGRAM',
        value: handle,
        color: AppColors.atlanticoClaro,
        onTap: () async {
          final url = Uri.parse(
              'https://instagram.com/${handle.replaceFirst('@', '')}');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LO QUE NECESITAS SABER',
            style: AppTextStyles.eyebrow(
              size: 11,
              color: AppColors.atlantico,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return _NTKRow(data: e.value, isLast: isLast);
          }),
        ],
      ),
    );
  }

  String? _firstNonEmpty(List<String?> xs) {
    for (final x in xs) {
      if (x != null && x.isNotEmpty) return x;
    }
    return null;
  }

  String? _scheduleLine() {
    if (visit?.openingHours?.isNotEmpty == true) return visit!.openingHours;

    final json = restaurant.horariosJson;
    if (json != null) {
      try {
        final weekday = json['weekday_text'];
        if (weekday is List) {
          final idx = (DateTime.now().weekday + 6) % 7;
          if (idx < weekday.length) {
            final line = weekday[idx].toString();
            final colon = line.indexOf(':');
            if (colon != -1 && colon + 1 < line.length) {
              return line.substring(colon + 1).trim();
            }
            return line;
          }
        }
      } catch (_) {}
    }

    if (restaurant.googleHorarios.isNotEmpty &&
        restaurant.googleHorarios.toLowerCase() != 'sin horario') {
      return restaurant.googleHorarios.split('\n').first;
    }
    return null;
  }
}

class _NTKRowData {
  final String key;
  final String value;
  final Color? color;
  final VoidCallback? onTap;
  _NTKRowData({
    required this.key,
    required this.value,
    this.color,
    this.onTap,
  });
}

class _NTKRow extends StatelessWidget {
  final _NTKRowData data;
  final bool isLast;

  const _NTKRow({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: data.onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                data.key,
                style: AppTextStyles.eyebrow(
                  size: 9,
                  color: context.brand.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.value,
                style: AppTextStyles.ui(
                  size: 11,
                  color: data.color ?? context.brand.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
