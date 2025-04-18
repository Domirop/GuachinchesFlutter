import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/blog_post.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/profile/profile_v2.dart';
import 'package:guachinches/ui/pages/search_page/search_page.dart';
import '../../../data/model/Category.dart';
import '../video/video.dart';
import 'home.dart';

class HomePresenter{
  final HomeView _view;
  TopRestaurantCubit _topRestaurantCubit;
  CuponesCubit _cuponesCubit;
  UserCubit _userCubit;
  final RemoteRepository repository;
  BannersCubit _bannersCubit;
  RestaurantCubit _restaurantCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._topRestaurantCubit, this._bannersCubit, this._cuponesCubit, this._userCubit, this.repository,this._restaurantCubit);

  getTopRestaurants() async {
    List<TopRestaurants> topRestaurants = await repository.getTopRestaurants();
    print(topRestaurants.length);
    _view.setTopRestaurants(topRestaurants);
  }
  getSurveyRestaurants() async {
    List<Restaurant> restaurantsGuachinchesModernos =
    await repository.getAllSurveyRestaurants("Mejor-Guachinche-Moderno");

    List<Restaurant> restaurantsGuachinchesTradicionales =
    await repository.getAllSurveyRestaurants("Mejor-Guachinche-Tradicional");

    List<Restaurant> allSurveyRestaurants = restaurantsGuachinchesModernos + restaurantsGuachinchesTradicionales;

    _view.setSurveyRestaurants(allSurveyRestaurants);
  }

  getIsland() async {
    String islandId = await storage.read(key: 'islandId') ?? '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
    _view.setIsland(islandId);
  }
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
    print("Survey "+ guachinchesModernos.toString());

    _view.setSurveyResults(guachinchesModernos, guachinchesTradicionales);
  }
  Future<List<String>> getRestaurantsVotedByUser() async {
    String? surveyUserId = await storage.read(key: "surveyUserId");

    List<String> restaurantsVoted = await repository.getVotedRestaurantsByUser("1", surveyUserId!);
    return restaurantsVoted;
  }

  getAllRestaurants(String islandId) async {

    await _restaurantCubit.getAllRestaurants(0,islandId);
  }
  getAllBlogPosts() async {
    List<BlogPost> blogPosts = await  repository.getAllBlogPosts();
    _view.setBlogPosts(blogPosts);
  }
  getRestaurantsFilterByCategory(String categoryId, String islandId) async {
    List<Restaurant> filteredRestaurants1 = await repository.getFilterRestaurants(categoryId, '', '', '', islandId);
    List<Restaurant> filteredRestaurants2 = await repository.getFilterRestaurants('de73bfc5-641f-4796-960b-ae75583b8d24', '', '', '', islandId);
    _view.setRestaurantsFiltered(filteredRestaurants1,filteredRestaurants2);
  }

  getAllVideos() async {
    List<Video> videos = await repository.getAllVideos();
    _view.setAllVideos(videos);
  }
  getAllCategories() async {
    List<ModelCategory> categories = await repository.getAllCategories();
    _view.setCategories(categories);
  }

  getAllTypes() async {
    List<Types> types = await repository.getAllTypes();
    print('types '+types.length.toString());
    _view.setTypes(types);
  }
  getAllMunicipalities(String islandId) async {
    List<Municipality> municipalities = await repository.getAllMunicipalitiesFiltered(islandId);
    _view.setMunicipalities(municipalities);
  }
  getScreens() async {
    final storage = new FlutterSecureStorage();
    List<Widget> screens = [
      Home(),
      MapSearch(),
      VideoScreen(index: 0),
      Login("Para ver tu perfíl debes iniciar sesión.")
    ];
    try {
      String? userId = await storage
          .read(key: "userId");

      if (userId != null) {
        if (_userCubit.state is UserInitial) {
          var response = await _userCubit.getUserInfo(userId);
          if (response == true) {
            screens = [Home(), SearchPage(userId: userId), VideoScreen(index: 0), Profilev2()];
          } else {
            await storage.delete(key: "userId");
          }
        }else if(_userCubit.state is UserLoaded){
          screens = [Home(), SearchPage(userId: userId), VideoScreen(index:0),  Profilev2()];
        }
      } else {
        screens = [
          Home(),
          MapSearch(),
          Login("Para ver tus valoraciones debes iniciar sesión."),
          Login("Para ver tu perfíl debes iniciar sesión.")
        ];
      }
    } catch (e) {
    }
    _view.setScreens(screens);
  }

  getCupones() async {
    List<CuponesAgrupados> cupones= await repository.getCuponesHistorias();
    _view.setCupones(cupones);
  }

  getUserInfo() async {
    String? userId = await storage.read(key: "userId");
    if (userId != null){
      _view.setUserId(userId!);

    }
  }

  getAllBanner() async {
    await _bannersCubit.getBanners();
  }

  changeScreen(widget){
    _view.changeScreen(widget);
  }
}
abstract class HomeView{
  setTopRestaurants(List<TopRestaurants> restaurants);
  changeCharginInitial();
  setUserId(String id);
  setRestaurantsFiltered(List<Restaurant> restaurantsFiltered1,List<Restaurant> restaurantsFiltered2);
  setScreens(List<Widget> screens);
  changeScreen(widget);
  setAllVideos(List<Video> videos);
  setCategories(List<ModelCategory> categories);
  setTypes(List<Types> types);
  setMunicipalities(List<Municipality> municipalities);
  setCupones(List<CuponesAgrupados>cuponesAgrupadosParam);
  setBlogPosts(List<BlogPost> blogPosts) {}
  setIsland(String islandId) {}
  setSurveyResults(List<SurveyResult> guachinchesModernos,List<SurveyResult> guachinchesTradicionales);
  setSurveyRestaurants(List<Restaurant> restaurants);
}
