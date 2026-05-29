import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/short_quote.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';

class YoutubeShortSection extends StatelessWidget {
  final Restaurant restaurant;

  const YoutubeShortSection({super.key, required this.restaurant});

  static bool shouldRender(Restaurant r) =>
      r.shortVideoId != null && r.shortVideoId!.isNotEmpty;

  Future<void> _open(BuildContext context) async {
    await YoutubeEmbedSheet.show(context, videoId: restaurant.shortVideoId!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EL SHORT DE JONAY Y JOANA',
            style: AppTextStyles.displaySection(size: 11),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _open(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (restaurant.shortThumbnailUrl != null &&
                        restaurant.shortThumbnailUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: restaurant.shortThumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: context.brand.elevated),
                      )
                    else
                      Container(color: context.brand.elevated),
                    const _ShortFade(),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (restaurant.shortDuration != null)
                            _ShortDurationBadge(restaurant.shortDuration!),
                          const _ShortsBadge(),
                        ],
                      ),
                    ),
                    const Center(child: _ShortPlayButton()),
                    Positioned(
                      right: 8,
                      bottom: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (restaurant.shortLikes != null)
                            _ShortAction(
                              icon: Icons.favorite_border,
                              count: _formatCount(restaurant.shortLikes!),
                            ),
                          if (restaurant.shortLikes != null)
                            const SizedBox(height: 12),
                          if (restaurant.shortComments != null)
                            _ShortAction(
                              icon: Icons.chat_bubble_outline,
                              count: restaurant.shortComments!.toString(),
                            ),
                          if (restaurant.shortComments != null)
                            const SizedBox(height: 12),
                          const _ShortAction(
                            icon: Icons.reply,
                            count: 'Compartir',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GUACHINCHESMODERNOS',
                            style: AppTextStyles.displaySection(size: 11)
                                .copyWith(color: Colors.white),
                          ),
                          if (restaurant.shortDescription != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              restaurant.shortDescription!,
                              style: AppTextStyles.ui(
                                size: 9,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (restaurant.shortQuotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _QuotesBox(quotes: restaurant.shortQuotes),
          ],
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ShortFade extends StatelessWidget {
  const _ShortFade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Color(0x99000000),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _ShortDurationBadge extends StatelessWidget {
  final String duration;
  const _ShortDurationBadge(this.duration);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        duration,
        style: AppTextStyles.ui(
          size: 9,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ShortsBadge extends StatelessWidget {
  const _ShortsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mojo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            'Shorts',
            style: AppTextStyles.ui(
              size: 9,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortPlayButton extends StatelessWidget {
  const _ShortPlayButton();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          alignment: Alignment.center,
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _ShortAction extends StatelessWidget {
  final IconData icon;
  final String count;

  const _ShortAction({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          count,
          style: AppTextStyles.ui(
            size: 8,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _QuotesBox extends StatelessWidget {
  final List<ShortQuote> quotes;
  const _QuotesBox({required this.quotes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LO QUE DICEN',
            style: AppTextStyles.eyebrow(
              size: 8,
              color: context.brand.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          ...quotes.map((q) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: q.isWarning
                            ? AppColors.mojo
                            : AppColors.atlantico,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '"${q.text}"',
                        style: AppTextStyles.editorial(
                          size: 11,
                          color: context.brand.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
