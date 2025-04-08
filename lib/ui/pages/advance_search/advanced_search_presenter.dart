import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';

class AdvancedSearchPresenter{
  RemoteRepository remoteRepository;


  AdvancedSearchPresenter(this.remoteRepository);
}
abstract class AdvancedSearchView{
  setRestaurants(List<Restaurant> restaurants);
}