import 'package:guachinches/data/model/restaurant.dart';

class SurveyResult {
  final String restaurantId;
  final int votes;
  final Restaurant? restaurant; // Aquí guardamos el objeto resuelto
  bool isVotedByUser = false;

  SurveyResult({
    required this.restaurantId,
    required this.votes,
    required this.restaurant,
  });

  // Constructor personalizado desde JSON + lista de restaurantes
  factory SurveyResult.fromJsonWithRestaurants(
      Map<String, dynamic> json,
      List<Restaurant> restaurants,
      ) {
    final String id = json['option'] as String;
    final int voteCount = int.parse(json['votes'].toString());

    final Restaurant? matchedRestaurant = restaurants.firstWhere(
          (r) => r.id == id
    );

    return SurveyResult(
      restaurantId: id,
      votes: voteCount,
      restaurant: matchedRestaurant,
    );
  }

  // Método para marcar los restaurantes votados por el usuario
  void markVotedRestaurants() {
    isVotedByUser = true;
  }
}
