abstract class FavoritesRemoteRepository {
  Future<List<String>> getFavorites(String userId);
  Future<void> addFavorite(String userId, String restaurantId);
  Future<void> removeFavorite(String userId, String restaurantId);
}
