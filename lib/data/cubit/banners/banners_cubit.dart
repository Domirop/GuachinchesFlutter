import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_state.dart';
import 'package:guachinches/data/model/fotoBanner.dart';

class BannersCubit extends Cubit<BannersState> {
  final RemoteRepository _remoteRepository;

  BannersCubit(this._remoteRepository) : super(BannersInitial());

  Future<void> getBanners() async {
    List<FotoBanner> banners = await _remoteRepository.getGlobalImages();
    emit(BannersLoaded(banners));
  }
}
