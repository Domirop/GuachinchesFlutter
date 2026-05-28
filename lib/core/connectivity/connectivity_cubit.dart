import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _sub;

  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityOnline());

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _emitFromResult(result);
    _sub = _connectivity.onConnectivityChanged.listen(_emitFromResult);
  }

  void _emitFromResult(ConnectivityResult result) {
    emit(result == ConnectivityResult.none
        ? const ConnectivityOffline()
        : const ConnectivityOnline());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
