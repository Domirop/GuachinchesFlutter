import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_cards.dart'
    show ListOpenStatus;
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/widgets/map_place_parts.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Hoja flotante del sitio elegido (tablero TabMapa · «sitio elegido»):
/// foto, antetítulo con tipo y municipio, nombre, estado, valoración y
/// distancia; cuatro acciones (Cómo llegar, Llamar, Guardar, Ver ficha) y
/// «N de M en esta zona · por cercanía» con anterior/siguiente.
///
/// Se cierra con la X o arrastrando hacia abajo; deslizar a los lados pasa
/// de sitio.
class MapPeekSheet extends StatelessWidget {
  final MapSite site;
  final String positionLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final VoidCallback onDirections;

  /// `null` si el sitio no tiene teléfono (el botón sale deshabilitado).
  final VoidCallback? onCall;

  /// Guardados (por defecto los del dispositivo; inyectable en tests).
  final GmFavorites? favorites;

  const MapPeekSheet({
    super.key,
    required this.site,
    required this.positionLabel,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
    required this.onOpenDetail,
    required this.onDirections,
    this.onCall,
    this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = site.restaurant;
    final name = gmDisplayName(r.nombre);
    final rating = mapRating(site, long: true);
    final km = site.meters == null ? null : mapKm(site.meters!);

    return Semantics(
      identifier: 'mapa-peek-sheet',
      container: true,
      label: name,
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 250) onClose();
        },
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) onNext();
          if (v > 250) onPrev();
        },
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Container(
            decoration: BoxDecoration(
              color: gm.canvas,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: gm.sep, spreadRadius: 0.5),
                const BoxShadow(
                  color: Color(0x59000000),
                  offset: Offset(0, 18),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: gm.sep,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      identifier: 'mapa-peek-open',
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onOpenDetail,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MapSitePhoto(site, size: 84, radius: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MapSiteEyebrow(site),
                                    const SizedBox(height: 1),
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GmText.title2(color: gm.label),
                                    ),
                                    const SizedBox(height: 1),
                                    ListOpenStatus(site.open, fontSize: 15),
                                    if (rating != null || km != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Row(
                                          children: [
                                            if (rating != null) rating,
                                            if (km != null)
                                              Text(
                                                rating != null ? ' · $km' : km,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    height: 18 / 13,
                                                    color: gm.label2),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            identifier: 'mapa-peek-directions',
                            icon: GmIcons.car,
                            label: 'Cómo llegar',
                            primary: true,
                            onTap: onDirections,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            identifier: 'mapa-peek-call',
                            icon: GmIcons.phone,
                            label: 'Llamar',
                            onTap: onCall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _SaveTile(
                                site: site,
                                favorites: favorites ?? GmFavorites.instance)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            identifier: 'mapa-peek-detail',
                            icon: GmIcons.menu,
                            label: 'Ver ficha',
                            onTap: onOpenDetail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _RoundButton(
                          identifier: 'mapa-peek-prev',
                          icon: GmIcons.chevronLeft,
                          label: 'Sitio anterior',
                          onTap: onPrev,
                        ),
                        Expanded(
                          child: Text(
                            positionLabel,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.eyebrow(color: gm.label2),
                          ),
                        ),
                        _RoundButton(
                          identifier: 'mapa-peek-next',
                          icon: GmIcons.chevronRight,
                          label: 'Sitio siguiente',
                          onTap: onNext,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: -6,
                  top: -10,
                  child: _RoundButton(
                    identifier: 'mapa-peek-close',
                    icon: GmIcons.close,
                    label: 'Cerrar',
                    iconSize: 13,
                    onTap: onClose,
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

/// Botón redondo de 36 en `fill` (44 de toque).
class _RoundButton extends StatelessWidget {
  final String identifier;
  final String icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  const _RoundButton({
    required this.identifier,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: gm.fill, shape: BoxShape.circle),
              child:
                  Center(child: GmIcon(icon, size: iconSize, color: gm.label)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loseta de acción (60 de alto, r20): primaria en `accentFill`.
class _ActionTile extends StatelessWidget {
  final String identifier;
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool toggled;

  const _ActionTile({
    required this.identifier,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.toggled = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final enabled = onTap != null;
    final fg = primary ? Colors.white : (enabled ? gm.accent : gm.label2);
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      toggled: identifier == 'mapa-peek-save' ? toggled : null,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            color: primary ? null : gm.card,
            gradient: primary ? GmColors.accentFill : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: Color(0x99005A8C),
                      offset: Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: -8,
                    ),
                  ]
                : gm.shadow1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GmIcon(icon, size: 22, color: fg),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    height: 16 / 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Guardar» / «Guardado» (cableado a [GmFavorites]).
class _SaveTile extends StatelessWidget {
  final MapSite site;
  final GmFavorites favorites;
  const _SaveTile({required this.site, required this.favorites});

  @override
  Widget build(BuildContext context) {
    favorites.ensureLoaded();
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favorites,
      builder: (_, ids, __) {
        final saved = ids.contains(site.id);
        return _ActionTile(
          identifier: 'mapa-peek-save',
          icon: saved ? GmIcons.bookmarkFilled : GmIcons.bookmark,
          label: saved ? 'Guardado' : 'Guardar',
          toggled: saved,
          onTap: () {
            HapticFeedback.lightImpact();
            favorites.toggle(site.id);
          },
        );
      },
    );
  }
}
