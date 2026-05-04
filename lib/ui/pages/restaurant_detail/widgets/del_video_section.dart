import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/short_quote.dart';
import 'package:url_launcher/url_launcher.dart';

class DelVideoSection extends StatelessWidget {
  final List<ShortQuote> quotes;
  final String? videoId;

  const DelVideoSection({
    super.key,
    required this.quotes,
    this.videoId,
  });

  static bool shouldRender(List<ShortQuote> quotes) => quotes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEL VIDEO',
            style: AppTextStyles.displaySection(
              size: 11,
              color: AppColors.atlantico,
            ),
          ),
          const SizedBox(height: 12),
          ...quotes.map((q) => _QuoteCard(quote: q, videoId: videoId)),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final ShortQuote quote;
  final String? videoId;

  const _QuoteCard({required this.quote, this.videoId});

  Future<void> _openAtTimestamp() async {
    if (videoId == null) return;
    final seconds = _parseTimestampToSeconds(quote.timestamp);
    final url = seconds != null
        ? Uri.parse('https://youtube.com/shorts/$videoId?t=$seconds')
        : Uri.parse('https://youtube.com/shorts/$videoId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  int? _parseTimestampToSeconds(String? ts) {
    if (ts == null) return null;
    final parts = ts.split(':');
    try {
      if (parts.length == 2) return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (parts.length == 3) {
        return int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            int.parse(parts[2]);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: const BorderSide(color: AppColors.atlantico, width: 3),
          top: BorderSide(color: context.brand.border),
          right: BorderSide(color: context.brand.border),
          bottom: BorderSide(color: context.brand.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${quote.text}"',
            style: AppTextStyles.editorial(
              size: 13,
              color: context.brand.textSecondary,
            ),
          ),
          if (quote.timestamp != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _openAtTimestamp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.atlantico,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      quote.timestamp!,
                      style: AppTextStyles.ui(
                        size: 10,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
