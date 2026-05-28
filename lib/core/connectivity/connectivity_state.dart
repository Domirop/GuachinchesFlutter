abstract class ConnectivityState {
  const ConnectivityState();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}
