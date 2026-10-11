import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Galería a pantalla completa (tablero FichaGaleria): fondo negro, foto
/// entera (contain) con pinch-zoom y swipe, cristal Cerrar · «3 / 14» ·
/// Compartir, pie «Nombre · foto 3 de 14» y tira de miniaturas con anillo.
class RestaurantPhotosGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String restaurantName;

  const RestaurantPhotosGallery({
    super.key,
    required this.urls,
    required this.restaurantName,
    this.initialIndex = 0,
  });

  @override
  State<RestaurantPhotosGallery> createState() =>
      _RestaurantPhotosGalleryState();
}

class _RestaurantPhotosGalleryState extends State<RestaurantPhotosGallery> {
  late final PageController _pageCtrl;
  final _thumbs = ScrollController();
  late int _index;

  static const double _thumb = 56;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageCtrl = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerThumb());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _thumbs.dispose();
    super.dispose();
  }

  void _centerThumb() {
    if (!_thumbs.hasClients) return;
    final w = MediaQuery.sizeOf(context).width;
    final target = (16 + _index * (_thumb + 6) + _thumb / 2 - w / 2)
        .clamp(0.0, _thumbs.position.maxScrollExtent);
    _thumbs.animateTo(target,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  void _share() {
    SharePlus.instance.share(ShareParams(
        text:
            '${gmDisplayName(widget.restaurantName)} en ¿Dónde Comer Canarias?\n${widget.urls[_index]}'));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;
    final pad = MediaQuery.paddingOf(context);
    final name = gmDisplayName(widget.restaurantName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageCtrl,
              itemCount: total,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              onPageChanged: (i) {
                setState(() => _index = i);
                _centerThumb();
              },
              loadingBuilder: (_, __) => const SizedBox.shrink(),
              builder: (context, i) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white24, size: 48),
                    ),
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.urls[i]),
                );
              },
            ),
            // Cerrar · contador · compartir.
            Positioned(
              left: 16,
              right: 16,
              top: pad.top + 2,
              child: Row(
                children: [
                  GmToolbarButton(
                    icon: GmIcons.close,
                    iconSize: 16,
                    semanticLabel: 'Cerrar la galería',
                    identifier: 'gallery-close-button',
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x2EFFFFFF),
                          borderRadius: BorderRadius.circular(GmRadius.pill),
                          border: Border.all(
                              color: const Color(0x40FFFFFF), width: 0.5),
                        ),
                        child: Text(
                          '${_index + 1} / $total',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  GmToolbarButton(
                    icon: GmIcons.share,
                    semanticLabel: 'Compartir la foto',
                    identifier: 'gallery-share-button',
                    onTap: _share,
                  ),
                ],
              ),
            ),
            // Pie: nombre + posición y tira de miniaturas.
            Positioned(
              left: 0,
              right: 0,
              bottom: pad.bottom + 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.body17(
                          color: Colors.white, w: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Foto ${_index + 1} de $total',
                      style: GmText.eyebrow(
                          color: const Color(0x99FFFFFF), w: FontWeight.w400),
                    ),
                  ),
                  if (total > 1) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      height: _thumb + 6,
                      child: ListView.separated(
                        controller: _thumbs,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: total,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final on = i == _index;
                          return GestureDetector(
                            onTap: () => _pageCtrl.animateToPage(i,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOut),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: on ? _thumb + 6 : _thumb,
                              height: on ? _thumb + 6 : _thumb,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: on
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Opacity(
                                  opacity: on ? 1 : 0.6,
                                  child: CachedNetworkImage(
                                    imageUrl: widget.urls[i],
                                    fit: BoxFit.cover,
                                    memCacheWidth: 180,
                                    placeholder: (_, __) => const ColoredBox(
                                        color: Color(0xFF1C1C1C)),
                                    errorWidget: (_, __, ___) =>
                                        const ColoredBox(
                                            color: Color(0xFF1C1C1C)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
