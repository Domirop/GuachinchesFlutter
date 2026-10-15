import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_cards.dart'
    show ListOpenStatus;
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/widgets/map_chrome.dart';
import 'package:guachinches/ui/pages/map/widgets/map_place_parts.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Estado de los datos de «Cerca de ti».
enum NearbyPhase { loading, ready, noLocation, error }

/// Barra de «Cerca de ti» (tablero MapaEmpujado): Volver, cápsula de título
/// y el segmentado Lista/Mapa.
class MapNearbyToolbar extends StatelessWidget {
  final bool listSelected;
  final ValueChanged<bool> onMode;
  final VoidCallback onBack;
  const MapNearbyToolbar({
    super.key,
    required this.listSelected,
    required this.onMode,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Row(
      children: [
        GmToolbarButton(
          identifier: 'mapa-nearby-back',
          icon: GmIcons.chevronLeft,
          semanticLabel: 'Volver',
          light: true,
          onTap: onBack,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: MapGlassCapsule(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  GmIcon(GmIcons.pin, size: 17, color: gm.accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Cerca de ti',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: gm.glassInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MapSegmented(listSelected: listSelected, onChanged: onMode),
      ],
    );
  }
}

/// Hoja inferior del modo Mapa: «N abiertos ahora · Abiertos y cerca» con
/// carrusel de filas, o los estados (cargando, sin ubicación, error, nada
/// a menos de 3 km).
class MapNearbySheet extends StatelessWidget {
  final NearbyPhase phase;
  final List<MapSite> near;
  final String? highlightedId;
  final ScrollController carousel;
  final ValueChanged<MapSite> onOpen;
  final VoidCallback onActivateLocation;
  final VoidCallback onShowIsland;
  final VoidCallback onRetry;

  const MapNearbySheet({
    super.key,
    required this.phase,
    required this.near,
    required this.carousel,
    required this.onOpen,
    required this.onActivateLocation,
    required this.onShowIsland,
    required this.onRetry,
    this.highlightedId,
  });

  /// Ancho de cada fila del carrusel (330 en el tablero).
  static double cardWidth(BuildContext context) =>
      math.min(330, MediaQuery.sizeOf(context).width - 56);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final Widget body;
    if (phase == NearbyPhase.loading) {
      body = _loading(context);
    } else if (phase == NearbyPhase.ready && near.isNotEmpty) {
      body = _ready(context);
    } else {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
        child: MapNearbyMessage(
          phase: phase,
          onActivateLocation: onActivateLocation,
          onShowIsland: onShowIsland,
          onRetry: onRetry,
        ),
      );
    }
    return Semantics(
      identifier: 'mapa-nearby-sheet',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2E000000),
                offset: Offset(0, -10),
                blurRadius: 30),
          ],
        ),
        padding: EdgeInsets.only(bottom: math.max(bottom, 16) + 8),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: gm.sep,
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                  ),
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Widget _ready(BuildContext context) {
    final gm = GmColors.of(context);
    final open = near.where((s) => s.isOpen).length;
    final w = cardWidth(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GmEyebrow(
                leading: open > 0 ? const GmLiveDot(live: true) : null,
                text: nearbyOpenEyebrow(open),
                color: open > 0 ? gm.greenText : gm.label2,
              ),
              Text(open > 0 ? 'Abiertos y cerca' : 'Lo más cerca',
                  style: GmText.title2(color: gm.label)),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            controller: carousel,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            itemCount: near.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(
              width: w,
              child: MapRowCard(
                site: near[i],
                highlighted: near[i].id == highlightedId,
                onTap: () => onOpen(near[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loading(BuildContext context) {
    final w = cardWidth(context);
    Widget row() => Container(
          width: w,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GmColors.of(context).card,
            borderRadius: BorderRadius.circular(GmRadius.card),
            boxShadow: GmColors.of(context).shadow1,
          ),
          child: Row(
            children: [
              const MapSkeleton(width: 88, height: 88, radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                        widthFactor: 0.8, child: const MapSkeleton(height: 18)),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                        widthFactor: 0.6, child: const MapSkeleton(height: 14)),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                        widthFactor: 0.5, child: const MapSkeleton(height: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Semantics(
      identifier: 'mapa-nearby-loading',
      label: 'Cargando sitios cercanos',
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MapSkeleton(width: 150, height: 14),
                SizedBox(height: 10),
                MapSkeleton(width: 180, height: 24, radius: 8),
              ],
            ),
          ),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
              children: [row(), const SizedBox(width: 10), row()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista Lista de «Cerca de ti»: título grande y lista agrupada (abiertos
/// primero, luego por distancia).
class MapNearbyList extends StatelessWidget {
  final NearbyPhase phase;
  final List<MapSite> near;
  final double topInset;
  final ValueChanged<MapSite> onOpen;
  final VoidCallback onActivateLocation;
  final VoidCallback onShowIsland;
  final VoidCallback onRetry;

  const MapNearbyList({
    super.key,
    required this.phase,
    required this.near,
    required this.topInset,
    required this.onOpen,
    required this.onActivateLocation,
    required this.onShowIsland,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom + 32;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GmEyebrow(
            leading: GmIcon(GmIcons.pin, size: 14, color: gm.accent),
            text: 'Desde tu ubicación',
            color: gm.label2,
          ),
          Semantics(
            header: true,
            child:
                Text('Cerca de ti', style: GmText.largeTitle(color: gm.label)),
          ),
          if (phase == NearbyPhase.ready)
            Text(nearbyListSubtitle(near.length),
                style: GmText.body(color: gm.label2)),
        ],
      ),
    );

    Widget content;
    if (phase == NearbyPhase.ready && near.isNotEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        child: GmRise(
          index: 2,
          child: GmCard(
            child: Column(
              children: [
                for (var i = 0; i < near.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 92),
                      child: Container(height: 0.5, color: gm.sep),
                    ),
                  _NearbyRow(site: near[i], onTap: () => onOpen(near[i])),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        child: GmCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: phase == NearbyPhase.loading
              ? const Column(
                  children: [
                    MapSkeleton(height: 64, radius: 14),
                    SizedBox(height: 12),
                    MapSkeleton(height: 64, radius: 14),
                    SizedBox(height: 12),
                    MapSkeleton(height: 64, radius: 14),
                  ],
                )
              : MapNearbyMessage(
                  phase: phase,
                  onActivateLocation: onActivateLocation,
                  onShowIsland: onShowIsland,
                  onRetry: onRetry,
                ),
        ),
      );
    }

    return Semantics(
      identifier: 'mapa-nearby-list-view',
      container: true,
      child: ListView(
        padding: EdgeInsets.only(top: topInset, bottom: bottom),
        children: [header, content],
      ),
    );
  }
}

/// Mensaje de estado de «Cerca de ti» (sin ubicación, error o nada a
/// menos de 3 km), en la hoja y en la lista.
class MapNearbyMessage extends StatelessWidget {
  final NearbyPhase phase;
  final VoidCallback onActivateLocation;
  final VoidCallback onShowIsland;
  final VoidCallback onRetry;
  const MapNearbyMessage({
    super.key,
    required this.phase,
    required this.onActivateLocation,
    required this.onShowIsland,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final String identifier;
    final Widget art;
    final String title;
    final String text;
    final List<Widget> actions;
    switch (phase) {
      case NearbyPhase.noLocation:
        identifier = 'mapa-nearby-noloc';
        art = Container(
          width: 48,
          height: 48,
          decoration:
              BoxDecoration(color: gm.accentSoft, shape: BoxShape.circle),
          child: Center(
            child: GmIcon(kMapLocateIcon, size: 22, color: gm.accent),
          ),
        );
        title = 'Activa la ubicación';
        text = '«Cerca de ti» ordena los sitios por distancia, y sin tu '
            'ubicación no sabemos dónde estás.';
        actions = [
          GmCapsuleButton(
            identifier: 'mapa-nearby-activate',
            label: 'Activar ubicación',
            onTap: onActivateLocation,
          ),
          GmSoftCapsuleButton(
            identifier: 'mapa-nearby-island',
            label: 'Ver toda la isla',
            onTap: onShowIsland,
          ),
        ];
      case NearbyPhase.error:
        identifier = 'mapa-nearby-error';
        art = const GmSadVolcano(width: 84);
        title = 'No pudimos cargar lo que tienes cerca';
        text = 'Revisa tu conexión e inténtalo de nuevo.';
        actions = [
          GmCapsuleButton(
            identifier: 'mapa-error-retry',
            label: 'Reintentar',
            onTap: onRetry,
          ),
        ];
      case NearbyPhase.loading:
      case NearbyPhase.ready:
        identifier = 'mapa-nearby-empty';
        art = const MapTypeTile(null, size: 48, glyph: 28, radius: 24);
        title = 'Nada a menos de ${kNearbyRadiusKm.round()} km';
        text = 'Por aquí no tenemos sitios todavía. En el resto de la isla '
            'hay de sobra.';
        actions = [
          GmCapsuleButton(
            identifier: 'mapa-nearby-island',
            label: 'Ver toda la isla',
            onTap: onShowIsland,
          ),
        ];
    }
    return Semantics(
      identifier: identifier,
      container: true,
      liveRegion: phase == NearbyPhase.error,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art,
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: GmText.poster(color: gm.label)),
            const SizedBox(height: 6),
            Text(text,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 15, height: 21 / 15, color: gm.label2)),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyRow extends StatelessWidget {
  final MapSite site;
  final VoidCallback onTap;
  const _NearbyRow({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = site.restaurant;
    return Semantics(
      identifier: 'mapa-nearby-row-${r.id}',
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              children: [
                MapSitePhoto(site, size: 64, radius: 14, glyph: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gmDisplayName(r.nombre),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.guideTitle(color: gm.label),
                      ),
                      MapSiteMeta(site, showRating: true),
                      ListOpenStatus(site.open),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
