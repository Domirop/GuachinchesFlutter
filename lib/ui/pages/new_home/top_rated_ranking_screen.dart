import 'package:flutter/material.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_ranking_numeric.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

/// Ranking completo "MEJOR VALORADOS · {ISLA}" — destino del CTA "Ver ranking"
/// de la sección del home. Lista todos los top de la isla con la misma card
/// numerada, sin cortar a 3.
class TopRatedRankingScreen extends StatelessWidget {
  final List<TopRestaurants> restaurants;
  final String islandLabel;

  const TopRatedRankingScreen({
    super.key,
    required this.restaurants,
    required this.islandLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Scaffold(
      backgroundColor: brand.base,
      appBar: AppBar(
        backgroundColor: brand.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Semantics(
          identifier: 'top-rated-back-button',
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: brand.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Mejor valorados',
          style: AppTextStyles.displaySection(size: 16, color: brand.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          itemCount: restaurants.length,
          separatorBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: brand.border),
          ),
          itemBuilder: (_, i) => CardRankingNumeric(
            restaurant: restaurants[i],
            rank: i + 1,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(id: restaurants[i].id),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
