abstract class FavoritesState {
  const FavoritesState();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<String> restaurantIds;
  final bool fromCache;

  const FavoritesLoaded(this.restaurantIds, {this.fromCache = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoritesLoaded &&
        other.fromCache == fromCache &&
        _listEqual(other.restaurantIds, restaurantIds);
  }

  @override
  int get hashCode => Object.hash(fromCache, Object.hashAll(restaurantIds));

  static bool _listEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoritesError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
