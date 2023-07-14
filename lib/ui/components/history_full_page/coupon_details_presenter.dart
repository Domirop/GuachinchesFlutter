import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/CuponesUser.dart';

class CouponDetailsPresenter{
  final CouponDetailsView _view;
  final RemoteRepository _remoteRepository;

  CouponDetailsPresenter(this._view, this._remoteRepository);

  getCoupon(String userId,String id) async {
    CuponesUser coupon = await _remoteRepository.getOneCupon(userId, id);
    print('API COUPON ID');
    print(coupon.id);
    _view.setCouponData(coupon);
  }
}

abstract class CouponDetailsView{
  setCouponData(CuponesUser coupon);
}