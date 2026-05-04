import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Galería pantalla completa con pinch-zoom y swipe horizontal.
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
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageCtrl = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: total,
            backgroundDecoration:
                const BoxDecoration(color: Colors.black),
            onPageChanged: (i) => setState(() => _index = i),
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(
                color: AppColors.atlantico,
                strokeWidth: 2,
              ),
            ),
            builder: (context, i) {
              return PhotoViewGalleryPageOptions.customChild(
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.atlantico,
                      strokeWidth: 2,
                    ),
                  ),
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

          // Top bar: close + counter + restaurant name
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.of(context).padding.top + 8,
                12,
                12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  _GlassCircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.restaurantName.toUpperCase(),
                          style: AppTextStyles.displaySection(size: 12)
                              .copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_index + 1} / $total',
                          style: AppTextStyles.ui(
                            size: 10,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom thumbnail strip
          if (total > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 14,
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: total,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final active = i == _index;
                    return GestureDetector(
                      onTap: () => _pageCtrl.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? AppColors.atlantico
                                : Colors.white.withOpacity(0.15),
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: widget.urls[i],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: context.brand.elevated),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
