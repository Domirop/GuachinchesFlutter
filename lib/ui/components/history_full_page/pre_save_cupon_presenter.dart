import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';

class PreSaveCuponPresenter{
  final PreSaveCuponView _view;
  final RemoteRepository repository;

  PreSaveCuponPresenter(this._view, this.repository);

  saveCupon(String cuponId, String userId) async {
    String aux = await repository.saveCupon(cuponId, userId);
    _view.saveCuponState(aux);
  }
}
abstract class PreSaveCuponView{
  saveCuponState(String isCorrect);
}
