import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:url_launcher/url_launcher.dart';

class NTKBox extends StatelessWidget {
  final Restaurant restaurant;
  final String? instagram;

  const NTKBox({super.key, required this.restaurant, this.instagram});

  @override
  Widget build(BuildContext context) {
    final rows = <_NTKRowData>[];

    rows.add(_NTKRowData(
      key: 'Estado',
      value: restaurant.open ? 'Abierto ahora' : 'Cerrado',
      color: restaurant.open ? AppColors.laurisilva : AppColors.mojo,
    ));

    if (restaurant.googleHorarios.isNotEmpty &&
        restaurant.googleHorarios.toLowerCase() != 'sin horario') {
      rows.add(_NTKRowData(key: 'Horario', value: _todayLine()));
    }

    if (restaurant.minPrice != null && restaurant.maxPrice != null) {
      rows.add(_NTKRowData(
        key: 'Precio medio',
        value: '${restaurant.minPrice}–${restaurant.maxPrice}€',
      ));
    }

    if (restaurant.reservationInfo != null &&
        restaurant.reservationInfo!.isNotEmpty) {
      rows.add(_NTKRowData(
        key: 'Reservas',
        value: restaurant.reservationInfo!,
      ));
    }

    if (restaurant.season != null && restaurant.season!.isNotEmpty) {
      rows.add(_NTKRowData(
        key: 'Temporada',
        value: restaurant.season!,
        color: AppColors.mojo,
      ));
    }

    if (restaurant.telefono.isNotEmpty) {
      rows.add(_NTKRowData(
        key: 'Teléfono',
        value: restaurant.telefono,
        color: AppColors.atlanticoClaro,
        onTap: () async {
          final uri = Uri.parse('tel:${restaurant.telefono}');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ));
    }

    if (restaurant.parking != null && restaurant.parking!.isNotEmpty) {
      rows.add(_NTKRowData(key: 'Parking', value: restaurant.parking!));
    }

    if (instagram != null && instagram!.isNotEmpty) {
      final handle = instagram!.startsWith('@') ? instagram! : '@$instagram';
      rows.add(_NTKRowData(
        key: 'Instagram',
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 12, color: context.brand.textMuted),
                const SizedBox(width: 6),
                Text(
                  'LO QUE NECESITAS SABER',
                  style: AppTextStyles.eyebrow(
                    size: 8,
                    color: context.brand.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return _NTKRow(data: e.value, isLast: isLast);
          }),
        ],
      ),
    );
  }

  String _todayLine() {
    final json = restaurant.horariosJson;
    if (json != null) {
      try {
        final weekday = json['weekday_text'];
        if (weekday is List) {
          // Google: 0=Sun..6=Sat. Dart: 1=Mon..7=Sun.
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
    return restaurant.googleHorarios.split('\n').first;
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
                bottom:
                    BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: data.onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.key,
              style: AppTextStyles.ui(
                size: 10,
                color: context.brand.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                data.value,
                textAlign: TextAlign.right,
                style: AppTextStyles.chipLabel(
                  size: 10,
                  color: data.color ?? AppColors.crema,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
