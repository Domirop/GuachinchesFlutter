import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';

@immutable
abstract class CuponesState {
  const CuponesState();
}

class CuponesInitial extends CuponesState {
  const CuponesInitial();
}

class CuponesLoaded extends CuponesState {
  final List<CuponesAgrupados> cuponesAgrupados;
  const CuponesLoaded(this.cuponesAgrupados);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CuponesLoaded && o.cuponesAgrupados == cuponesAgrupados;
  }
}
