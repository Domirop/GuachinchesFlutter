import 'dart:convert';

import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:http/http.dart';

import 'RemoteRepository.dart';

class HttpRemoteRepository implements RemoteRepository {
  final Client _client;
  final String endpoint = "http://163.172.183.16:32683/";

  HttpRemoteRepository(this._client);

  @override
  Future<List<Restaurant>> getAllRestaurants() async {
    var uri = Uri.parse(endpoint + "restaurant");
    var response = await _client.get(uri);
    List<dynamic> data = json.decode(response.body)['result'];

    List<Restaurant> restaurants = [];
    for (var i = 0; i < data.length; i++) {
      Restaurant restaurant = Restaurant.fromJson(data[i]);
      restaurants.add(restaurant);
    }
    return restaurants;

  }

  @override
  Future<List<Category>> getAllCategories() async {
    var uri = Uri.parse(endpoint + "restaurant/category");
    var response = await _client.get(uri);
    List<dynamic> data = json.decode(response.body)['result'];
    List<Category> categories = [];

    for (var i = 0; i < data.length; i++) {
      Category category = Category.fromJson(data[i]);
      categories.add(category);
    }
    return categories;
  }


}
