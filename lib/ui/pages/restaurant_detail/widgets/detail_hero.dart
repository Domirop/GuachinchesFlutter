import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_photos_gallery.dart';

class DetailHero extends StatefulWidget {
  final Restaurant restaurant;

  const DetailHero({super.key, required this.restaurant});

  @override
  State<DetailHero> createState() => _DetailHeroState();
}

class _DetailHeroState extends State<DetailHero> {
  static const double _height = 320;
  static const Duration _autoplayInterval = Duration(seconds: 7);
  static const Duration _autoplayTransition = Duration(milliseconds: 1200);

  late final PageController _pageCtrl;
  Timer? _autoplayTimer;
  int _index = 0;

  List<String> get _photoUrls {
    final urls = widget.restaurant.fotos
        .map((f) => f.photoUrl ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty && widget.restaurant.mainFoto.isNotEmpty) {
      return [widget.restaurant.mainFoto];
    }
    return urls;
  }

  bool get _hasShort =>
      widget.restaurant.shortVideoId != null &&
      widget.restaurant.shortVideoId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    if (_photoUrls.length > 1) _startAutoplay();
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(_autoplayInterval, (_) {
      if (!mounted || _photoUrls.isEmpty) return;
      final next = (_index + 1) % _photoUrls.length;
      _pageCtrl.animateToPage(
        next,
        duration: _autoplayTransition,
        curve: Curves.easeInOut,
      );
    });
  }

  void _openGallery({int? at}) {
    if (_photoUrls.isEmpty) return;
    _autoplayTimer?.cancel();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantPhotosGallery(
          urls: _photoUrls,
          initialIndex: at ?? _index,
          restaurantName: widget.restaurant.nombre,
        ),
      ),
    ).then((_) {
      if (mounted && _photoUrls.length > 1) _startAutoplay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final urls = _photoUrls;
    final hasMultiple = urls.length > 1;

    return SizedBox(
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urls.isEmpty)
            _placeholder()
          else
            GestureDetector(
              onTap: () => _openGallery(),
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: urls[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(),
                  errorWidget: (_, __, ___) => _placeholder(),
                ),
              ),
            ),

          // Fade inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xBF0A0F14),
                      context.brand.base,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          if (_hasShort)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 14,
              child: const _YoutubeBadge(),
            ),
          if (_hasShort)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 14,
              child: const _JJAvatars(),
            ),

          // Nombre y badges
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _eyebrowText(),
                    style: AppTextStyles.eyebrow(
                      size: 8,
                      color: context.brand.textSecondary,
                    ).copyWith(letterSpacing: 1.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.restaurant.nombre.toUpperCase(),
                    style: AppTextStyles.displayHero(
                      size: 26,
                      color: context.brand.textPrimary,
                    ).copyWith(
                      letterSpacing: -0.3,
                      shadows: const [
                        Shadow(blurRadius: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: _badges(),
                        ),
                      ),
                      if (hasMultiple) ...[
                        const SizedBox(width: 8),
                        _PhotoCounterBadge(
                          current: _index + 1,
                          total: urls.length,
                          onTap: () => _openGallery(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _eyebrowText() {
    final r = widget.restaurant;
    final parts = <String>[];
    if (r.type.isNotEmpty && r.type != 'vacio') parts.add(r.type.toUpperCase());
    if (r.season != null && r.season!.isNotEmpty) parts.add('TEMPORADA');
    if (r.rankNumber != null) parts.add('Nº ${r.rankNumber}');
    return parts.join(' · ');
  }

  List<Widget> _badges() {
    final r = widget.restaurant;
    final badges = <Widget>[
      _HeroBadge(
        text: r.open ? '● Abierto' : '● Cerrado',
        variant: r.open ? _BadgeVariant.open : _BadgeVariant.closed,
      ),
    ];
    if (r.avgRating > 0) {
      badges.add(_HeroBadge(
        text: '★ ${r.avgRating.toStringAsFixed(1)}',
        variant: _BadgeVariant.rating,
      ));
    }
    if (r.municipio.isNotEmpty) {
      badges.add(_HeroBadge(text: '📍 ${r.municipio}'));
    }
    if (r.minPrice != null && r.maxPrice != null) {
      badges.add(_HeroBadge(text: '${r.minPrice}–${r.maxPrice}€'));
    }
    return badges;
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D1500),
              Color(0xFF7A3010),
              Color(0xFFC8856A),
            ],
          ),
        ),
      );
}

class _PhotoCounterBadge extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onTap;

  const _PhotoCounterBadge({
    required this.current,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Ver fotos · $current/$total',
                  style: AppTextStyles.ui(
                    size: 10,
                    weight: FontWeight.w600,
                    color: Colors.white,
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

enum _BadgeVariant { neutral, open, closed, rating }

class _HeroBadge extends StatelessWidget {
  final String text;
  final _BadgeVariant variant;

  const _HeroBadge({required this.text, this.variant = _BadgeVariant.neutral});

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white.withOpacity(0.10);
    Color textColor = AppColors.crema;
    switch (variant) {
      case _BadgeVariant.open:
        borderColor = AppColors.laurisilva.withOpacity(0.35);
        textColor = AppColors.laurisilva;
        break;
      case _BadgeVariant.closed:
        borderColor = AppColors.mojo.withOpacity(0.35);
        textColor = AppColors.mojo;
        break;
      case _BadgeVariant.rating:
        borderColor = AppColors.sol.withOpacity(0.30);
        textColor = AppColors.sol;
        break;
      case _BadgeVariant.neutral:
        break;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.glassDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            text,
            style: AppTextStyles.ui(
              size: 9,
              weight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _YoutubeBadge extends StatelessWidget {
  const _YoutubeBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 9),
          decoration: BoxDecoration(
            color: AppColors.glassDark,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.mojo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'YouTube Shorts · Jonay y Joana',
                style: AppTextStyles.ui(
                  size: 9,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JJAvatars extends StatelessWidget {
  const _JJAvatars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 24,
      child: Stack(
        children: [
          Positioned(left: 0, child: _circle(context, 'J', AppColors.profundo)),
          Positioned(left: 18, child: _circle(context, 'J', AppColors.atlantico)),
        ],
      ),
    );
  }

  Widget _circle(BuildContext context, String letter, Color bg) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: context.brand.base, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: AppTextStyles.displaySection(size: 9)
              .copyWith(color: Colors.white),
        ),
      );
}
