import 'dart:convert';

import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/Municipality.dart';
import 'package:guachinches/model/Review.dart';
import 'package:guachinches/model/User.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/model/user_info.dart';
import 'package:http/http.dart';

import 'RemoteRepository.dart';

class HttpRemoteRepository implements RemoteRepository {
  final Client _client;
  final String endpoint = "http://163.172.183.16:32683/";

  HttpRemoteRepository(this._client);


  @override
  Future<UserInfo> getUserInfo(String userId) async {
    var uri = Uri.parse(endpoint + "user/"+userId);
    var response = await _client.get(uri);

    var data = json.decode(response.body)['result'];
    UserInfo user= UserInfo.fromJson(data['Usuario']);
    return user;
  }

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

  @override
  Future<List<Municipality>> getAllMunicipalities() async {
    var uri = Uri.parse(endpoint + "municipality");
    var response = await _client.get(uri);
    List<dynamic> data = json.decode(response.body)['result'];
    List<Municipality> municipalities = [];
    for(var i = 0; i<data.length;i++){
      Municipality municipality = Municipality.fromJson(data[i]);
      municipalities.add(municipality);
    }
    return municipalities;
  }

  @override
  Future<bool> updateReview(String userId, String reviewId, String title,String rating, String review) async {
    var uri = Uri.parse(endpoint + "user/" + userId + "/review/" + reviewId);

    var body;
    body = jsonEncode(
        {
          "title": title,
          "review": review,
          "rating": rating
        });
    var response = await _client.put(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    print(jsonDecode(response.body));
    return true;
  }

  @override
  Future<bool> saveReview(String userId, Restaurant restaurant ,String title, String review, String rating) async {
    var uri = Uri.parse(endpoint + "user/" + userId + "/review");

    var body;
    body = jsonEncode(
        {
          "title": title,
          "review": review,
          "rating": rating,
          "ValoracionesNegocioId":restaurant.id
        });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    print(jsonDecode(response.body));
    return true;
  }

  @override
  Future<String> loginUser(String login, String password) async {
    var uri = Uri.parse(endpoint + "login");

    var body;
    body = jsonEncode(
        {
          "email": login,
          "password": password,
          });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    var data = jsonDecode(response.body);
    print(data);
    return data["result"]["id"];
  }
}
