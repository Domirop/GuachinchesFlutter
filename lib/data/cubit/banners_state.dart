import 'package:flutter/foundation.dart';
import 'package:guachinches/model/fotoBanner.dart';

@immutable
abstract class BannersState {
  const BannersState();

}

class BannersInitial extends BannersState {
  const BannersInitial();
}

class BannersLoaded extends BannersState {
  final List<FotoBanner> banners;
  const BannersLoaded(this.banners);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is BannersLoaded && o.banners == banners;
  }

  @override
  int get hashCode => banners.hashCode;
}
