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
    final rowBuilders = <Widget Function(bool isLast)>[];

    final address = _firstNonEmpty([visit?.address, restaurant.direccion]);
    if (address != null) {
      rowBuilders.add((isLast) => _NTKRow(
            data: _NTKRowData(key: 'DIRECCIÓN', value: address),
            isLast: isLast,
          ));
    }

    final schedule = _scheduleAllDays();
    if (schedule != null) {
      rowBuilders.add((isLast) => _ScheduleRow(
            hours: schedule.hours,
            todayIndex: schedule.todayIndex,
            isLast: isLast,
          ));
    }

    final phone = _firstNonEmpty([visit?.phone, restaurant.telefono]);
    if (phone != null) {
      rowBuilders.add((isLast) => _NTKRow(
            data: _NTKRowData(
              key: 'TELÉFONO',
              value: phone,
              color: AppColors.atlanticoClaro,
              onTap: () async {
                // Sanea el número (quita espacios/guiones/paréntesis; deja
                // dígitos y un posible '+'). Lanzamos directo SIN canLaunchUrl:
                // en iOS `canLaunchUrl('tel:')` devuelve false salvo que el
                // esquema esté en LSApplicationQueriesSchemes → el tap moría.
                final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
                final uri = Uri(scheme: 'tel', path: sanitized);
                try {
                  await launchUrl(uri);
                } catch (_) {
                  // Sin dialer disponible (p.ej. simulador): no-op.
                }
              },
            ),
            isLast: isLast,
          ));
    }

    final igRaw = _firstNonEmpty([instagram, visit?.instagram]);
    if (igRaw != null) {
      final handle = igRaw.startsWith('@') ? igRaw : '@$igRaw';
      rowBuilders.add((isLast) => _NTKRow(
            data: _NTKRowData(
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
            ),
            isLast: isLast,
          ));
    }

    if (rowBuilders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: context.brand.border),
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
            ).copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rowBuilders.length; i++)
            rowBuilders[i](i == rowBuilders.length - 1),
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

  _ScheduleData? _scheduleAllDays() {
    final todayIndex = (DateTime.now().weekday + 6) % 7;

    final json = restaurant.horariosJson;
    if (json != null) {
      try {
        final weekday = json['weekday_text'];
        if (weekday is List && weekday.length >= 7) {
          final hours = <String>[];
          for (int i = 0; i < 7; i++) {
            hours.add(_stripDayPrefix(weekday[i].toString()));
          }
          return _ScheduleData(hours: hours, todayIndex: todayIndex);
        }
      } catch (_) {}
    }

    final raw = restaurant.googleHorarios;
    if (raw.isNotEmpty && raw.toLowerCase() != 'sin horario') {
      final lines = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.length >= 7) {
        final hours = lines
            .take(7)
            .map(_stripDayPrefix)
            .toList(growable: false);
        return _ScheduleData(hours: hours, todayIndex: todayIndex);
      }
    }

    return null;
  }

  String _stripDayPrefix(String line) {
    final colon = line.indexOf(':');
    if (colon != -1 && colon + 1 < line.length) {
      return line.substring(colon + 1).trim();
    }
    return line;
  }
}

class _ScheduleData {
  final List<String> hours;
  final int todayIndex;
  _ScheduleData({required this.hours, required this.todayIndex});
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
                bottom: BorderSide(color: context.brand.border),
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
              width: 88,
              child: Text(
                data.key,
                style: AppTextStyles.eyebrow(
                  size: 11,
                  color: context.brand.textMuted,
                ).copyWith(letterSpacing: 1.0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.value,
                style: AppTextStyles.ui(
                  size: 13,
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

class _ScheduleRow extends StatefulWidget {
  final List<String> hours;
  final int todayIndex;
  final bool isLast;

  const _ScheduleRow({
    required this.hours,
    required this.todayIndex,
    required this.isLast,
  });

  @override
  State<_ScheduleRow> createState() => _ScheduleRowState();
}

class _ScheduleRowState extends State<_ScheduleRow> {
  static const _dayLabels = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final today = widget.todayIndex;
    final tomorrow = (today + 1) % 7;
    final visibleIndices = _expanded
        ? List<int>.generate(7, (i) => (today + i) % 7)
        : <int>[today, tomorrow];

    return Container(
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : Border(
                bottom: BorderSide(color: context.brand.border),
              ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              'HORARIO',
              style: AppTextStyles.eyebrow(
                size: 11,
                color: context.brand.textMuted,
              ).copyWith(letterSpacing: 1.0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < visibleIndices.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i == visibleIndices.length - 1 ? 0 : 4),
                    child: _dayLine(context, visibleIndices[i], today),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Ver menos' : 'Ver más',
                        style: AppTextStyles.ui(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.atlanticoClaro,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.atlanticoClaro,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayLine(BuildContext context, int dayIndex, int todayIndex) {
    final isToday = dayIndex == todayIndex;
    final dayColor =
        isToday ? AppColors.atlanticoClaro : context.brand.textMuted;
    final hoursColor =
        isToday ? AppColors.atlanticoClaro : context.brand.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            _dayLabels[dayIndex],
            style: AppTextStyles.eyebrow(size: 11, color: dayColor)
                .copyWith(letterSpacing: 1.0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.hours[dayIndex],
            style: AppTextStyles.ui(
              size: 13,
              color: hoursColor,
              weight: isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
