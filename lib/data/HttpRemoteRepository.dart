import 'dart:convert';

import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/Municipality.dart';
import 'package:guachinches/model/fotoBanner.dart';
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
    var uri = Uri.parse(endpoint + "user/" + userId);
    var response = await _client.get(uri);

    var data = json.decode(response.body)['result'];

    if(data['Usuario'] == null){
      throw Error();
    }
    UserInfo user = UserInfo.fromJson(data['Usuario']);

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
  Future<List<ModelCategory>> getAllCategories() async {
    var uri = Uri.parse(endpoint + "restaurant/category");
    var response = await _client.get(uri);
    List<dynamic> data = json.decode(response.body)['result'];
    List<ModelCategory> categories = [];

    for (var i = 0; i < data.length; i++) {
      ModelCategory category = ModelCategory.fromJson(data[i]);
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
    for (var i = 0; i < data.length; i++) {
      Municipality municipality = Municipality.fromJson(data[i]);
      municipalities.add(municipality);
    }
    return municipalities;
  }

  @override
  Future<bool> updateReview(String userId, String reviewId, String title,
      String rating, String review) async {
    var uri = Uri.parse(endpoint + "user/" + userId + "/review/" + reviewId);

    var body;
    body = jsonEncode({"title": title, "review": review, "rating": rating});
    var response = await _client.put(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    return true;
  }

  @override
  Future<bool> saveReview(String userId, Restaurant restaurant, String title,
      String review, String rating) async {
    var uri = Uri.parse(endpoint + "user/" + userId + "/review");
    var body;
    body = jsonEncode({
      "title": title,
      "review": review,
      "rating": rating,
      "ValoracionesNegocioId": restaurant.id
    });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    if (jsonDecode(response.body)["code"] == 200) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<dynamic> loginUser(String login, String password) async {
    var uri = Uri.parse(endpoint + "login");

    var body;
    body = jsonEncode({
      "email": login,
      "password": password,
    });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    var data = jsonDecode(response.body);
    return data["result"];
  }

  @override
  Future<List<FotoBanner>> getGlobalImages() async {
    var uri = Uri.parse(endpoint + "restaurant/banners");
    var response =
        await _client.get(uri, headers: {"Content-Type": "application/json"});
    List<dynamic> data = json.decode(response.body)['result'];
    List<FotoBanner> banners = [];
    for (var i = 0; i < data.length; i++) {
      FotoBanner fotoBanner = FotoBanner.fromJson(data[i]);
      banners.add(fotoBanner);
    }
    return banners;
  }

  @override
  Future<bool> registerUser(Map data) async {
    var uri = Uri.parse(endpoint + "register");
    var body;
    body = jsonEncode({
      "email": data["email"],
      "password": data["password"],
    });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    String id = json.decode(response.body)["result"];
    if (json.decode(response.body)["code"] == 200 && id != null) {
      uri = Uri.parse(endpoint + "user");
      body = jsonEncode({
        "id": id,
        "nombre": data["nombre"],
        "apellidos": data["apellidos"],
        "email": data["email"],
        "telefono": data["telefono"],
      });
      response = await _client.post(uri,
          headers: {"Content-Type": "application/json"}, body: body);
      if(json.decode(response.body)["code"] == 200 && json.decode(response.body)["result"] != null){
        return true;
      }else{
        return false;
      }
    } else {
      return false;
    }
  }
}
