import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// «Detalles» (rediseño iOS 27 · tablero Ficha): lista agrupada en una
/// tarjeta con icono teñido, etiqueta secundaria y valor. El teléfono va en
/// color de texto (nada de enlaces azules) y la fila entera se pulsa; el
/// horario muestra hoy y se despliega con el chevron.
class NTKBox extends StatelessWidget {
  final Restaurant restaurant;
  final Visit? visit;
  final String? instagram;
  final String title;

  const NTKBox({
    super.key,
    required this.restaurant,
    this.visit,
    this.instagram,
    this.title = 'Detalles',
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final rows = <Widget>[];

    final schedule = _scheduleAllDays();
    if (schedule != null) {
      rows.add(_ScheduleRow(
        hours: schedule.hours,
        todayIndex: schedule.todayIndex,
      ));
    }

    final phone = _firstNonEmpty([visit?.phone, restaurant.telefono]);
    if (phone != null) {
      rows.add(_DetailRow(
        icon: GmIcons.phone,
        iconSize: 15,
        tint: gm.accentSoft,
        ink: gm.accent,
        label: 'Teléfono',
        value: phone,
        identifier: 'restaurant-detail-phone-row',
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
      ));
    }

    final address = _firstNonEmpty([visit?.address, restaurant.direccion]);
    if (address != null) {
      rows.add(_DetailRow(
        icon: GmIcons.placeFilled,
        iconSize: 15,
        tint: const Color(0x38C9A96B),
        ink: gm.bandInk,
        label: 'Dirección',
        value: address,
      ));
    }

    final igRaw = _firstNonEmpty([instagram, visit?.instagram]);
    if (igRaw != null) {
      final handle = igRaw.startsWith('@') ? igRaw : '@$igRaw';
      rows.add(_DetailRow(
        icon: GmIcons.globe,
        iconSize: 15,
        tint: const Color(0x24C13584),
        ink: const Color(0xFFB0306E),
        label: 'Instagram',
        value: handle,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.centerLeft,
            child: Text(title, style: GmText.poster(color: gm.label)),
          ),
          const SizedBox(height: 4),
          GmCard(
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Container(height: 1, color: gm.sep),
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
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

class _DetailRow extends StatelessWidget {
  final String icon;
  final double iconSize;
  final Color tint;
  final Color ink;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? identifier;

  const _DetailRow({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.label,
    required this.value,
    this.iconSize = 16,
    this.onTap,
    this.trailing,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: GmIcon(icon, size: iconSize, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        height: 17 / 13,
                        fontWeight: FontWeight.w400,
                        color: gm.label2,
                      )),
                  Text(value,
                      style: TextStyle(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: FontWeight.w400,
                        color: gm.label,
                      )),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      identifier: identifier,
      button: true,
      child: GmPressable(onTap: onTap, pressedScale: 0.985, child: row),
    );
  }
}

class _ScheduleRow extends StatefulWidget {
  final List<String> hours;
  final int todayIndex;

  const _ScheduleRow({required this.hours, required this.todayIndex});

  @override
  State<_ScheduleRow> createState() => _ScheduleRowState();
}

class _ScheduleRowState extends State<_ScheduleRow> {
  static const _dayLabels = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final today = widget.todayIndex;
    final reduced = GmMotion.reduced(context);
    return Semantics(
      identifier: 'restaurant-detail-schedule-row',
      button: true,
      expanded: _expanded,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          children: [
            _DetailRow(
              icon: GmIcons.clock,
              tint: const Color(0x242FBF5B),
              ink: gm.greenText,
              label: 'Horario',
              value: 'Hoy, ${widget.hours[today]}',
              trailing: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: Duration(milliseconds: reduced ? 0 : 260),
                curve: GmMotion.settle,
                child: GmIcon(GmIcons.chevronDown, size: 14, color: gm.label2),
              ),
            ),
            AnimatedSize(
              duration: Duration(milliseconds: reduced ? 0 : 320),
              curve: GmMotion.settle,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(58, 0, 16, 12),
                      child: Column(
                        children: [
                          for (var k = 1; k < 7; k++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      _dayLabels[(today + k) % 7],
                                      style: GmText.body(color: gm.label2),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.hours[(today + k) % 7],
                                      style: GmText.body(color: gm.label),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
