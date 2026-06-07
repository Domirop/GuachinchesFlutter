import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  late final RemoteRepository _remoteRepository;
  late Restaurant restaurant;
  int _requestSeq = 0;

  RestaurantCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants(int number,String islandId) async {
    RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(number,islandId);

    emit(RestaurantLoaded(restaurantResponse));
  }

  static const int _pageSize = 15;
  // Concurrencia máxima de páginas en vuelo (no saturar el backend).
  static const int _pageBatch = 6;

  Future<void> getAllRestaurants(int number, String islandId) async {
    final int seq = ++_requestSeq;
    emit(RestaurantLoading());

    // 1ª página: además de sus filas nos da el `count` total → sabemos cuántas
    // páginas faltan y las pedimos en PARALELO (antes era un while en serie:
    // ~22 requests encadenados para 329 restaurantes).
    final RestaurantResponse first =
        await _remoteRepository.getAllRestaurants(0, islandId);
    if (seq != _requestSeq) return;

    final int total = first.count ?? first.restaurants.length;
    final offsets = <int>[
      for (int off = _pageSize; off < total; off += _pageSize) off,
    ];

    if (offsets.isEmpty) {
      // Sin `count` fiable y página llena → caemos al modo serie por seguridad.
      if (first.count == null &&
          first.restaurants.length >= _pageSize) {
        await _loadRemainingSerial(first, islandId, seq);
      }
      if (seq != _requestSeq) return;
      emit(AllRestaurantLoaded(first));
      return;
    }

    // Lotes de _pageBatch páginas en paralelo, lotes secuenciales.
    for (int i = 0; i < offsets.length; i += _pageBatch) {
      final batch = offsets.sublist(
          i, (i + _pageBatch).clamp(0, offsets.length));
      final pages = await Future.wait(
        batch.map((off) => _remoteRepository.getAllRestaurants(off, islandId)),
      );
      if (seq != _requestSeq) return;
      for (final p in pages) {
        first.restaurants.addAll(p.restaurants);
      }
    }

    emit(AllRestaurantLoaded(first));
  }

  /// Fallback en serie cuando el backend no devuelve `count`.
  Future<void> _loadRemainingSerial(
      RestaurantResponse acc, String islandId, int seq) async {
    int index = 1;
    while (true) {
      final page =
          await _remoteRepository.getAllRestaurants(index * _pageSize, islandId);
      if (seq != _requestSeq) return;
      if (page.restaurants.isEmpty) break;
      acc.restaurants.addAll(page.restaurants);
      index++;
    }
  }
  Future<void> getFilterRestaurants({List<String>? categories, List<String>? municipalities, List<String>? types, String? text,String? islandId,bool isOpen=false}) async {
    final int seq = ++_requestSeq;
    List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
    if (seq != _requestSeq) return;
    if (isOpen) {
      restaurants = restaurants.where((element) => element.open).toList();
    }

    emit(RestaurantFilter(restaurants));
  }
  Future<void> getFilterRestaurantsAdvance({List<String>? categories, List<String>? municipalities, List<String>? types, String? text,String? islandId,bool isOpen=false}) async {
    final int seq = ++_requestSeq;
    emit(RestaurantLoading());
    List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
    if (seq != _requestSeq) return;
    if (isOpen) {
      restaurants = restaurants.where((element) => element.open).toList();
    }

    emit(RestaurantFilterAdvanced(restaurants));
  }
}
