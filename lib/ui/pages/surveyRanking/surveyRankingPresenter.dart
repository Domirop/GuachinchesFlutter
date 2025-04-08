import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';

class SurveyRankingPresenter {
  final SurveyRankingView _view;
  final RemoteRepository repository;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  SurveyRankingPresenter(this._view, this.repository);

  Future<void> getSurveyResults(List<Restaurant> allRestaurants) async {
    // 1. Obtener los resultados
    List<SurveyResult> guachinchesModernos =
    await repository.getSurveyResults(1, "Mejor-Guachinche-Moderno", allRestaurants);

    List<SurveyResult> guachinchesTradicionales =
    await repository.getSurveyResults(1, "Mejor-Guachinche-Tradicional", allRestaurants);

    // 2. Obtener la lista de restaurantes votados por el usuario
    List<String> usersRestaurantsVoted = await getRestaurantsVotedByUser();

    // 3. Marcar los votados en ambas listas
    for (final result in guachinchesModernos) {
      if (usersRestaurantsVoted.contains(result.restaurantId)) {
        result.markVotedRestaurants();
      }
    }

    for (final result in guachinchesTradicionales) {
      if (usersRestaurantsVoted.contains(result.restaurantId)) {
        result.markVotedRestaurants();
      }
    }

    // 4. Enviar los resultados a la vista
    _view.setSurveyResults(guachinchesModernos, guachinchesTradicionales);
  }


  Future<List<String>> getRestaurantsVotedByUser() async {
    String? surveyUserId = await storage.read(key: "surveyUserId");

    List<String> restaurantsVoted = await repository.getVotedRestaurantsByUser("1", surveyUserId!);
    return restaurantsVoted;
  }

}
abstract class SurveyRankingView {
  void setSurveyResults(List<SurveyResult> guachinchesModernos, List<SurveyResult> guachinchesTradicionales);
}
