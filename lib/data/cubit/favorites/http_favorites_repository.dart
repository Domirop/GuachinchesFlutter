import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:guachinches/data/cubit/favorites/favorites_remote_repository.dart';

class HttpFavoritesRepository implements FavoritesRemoteRepository {
  final http.Client _client;

  HttpFavoritesRepository(this._client);

  @override
  Future<List<String>> getFavorites(String userId) async {
    final uri = Uri.parse('${dotenv.env['ENDPOINT_V2']!}user/$userId/favorites');
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('getFavorites failed: ${response.statusCode}');
    }
    final data = json.decode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => e['restaurantId'] as String)
        .toList();
  }

  @override
  Future<void> addFavorite(String userId, String restaurantId) async {
    final uri =
        Uri.parse('${dotenv.env['ENDPOINT_V2']!}user/$userId/favorites/$restaurantId');
    final response = await _client.post(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('addFavorite failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> removeFavorite(String userId, String restaurantId) async {
    final uri =
        Uri.parse('${dotenv.env['ENDPOINT_V2']!}user/$userId/favorites/$restaurantId');
    final response = await _client.delete(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('removeFavorite failed: ${response.statusCode}');
    }
  }
}
