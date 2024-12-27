import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/CuponesUser.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/block_user.dart';
import 'package:guachinches/data/model/blog_post.dart';
import 'package:guachinches/data/model/fotoBanner.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/data/model/report_review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/data/model/version.dart';
import 'package:http/http.dart';
import 'package:video_compress/src/media/media_info.dart';
import 'package:http/http.dart' as http;
import 'RemoteRepository.dart';

class HttpRemoteRepository implements RemoteRepository {
  final Client _client;

  HttpRemoteRepository(this._client);

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    var uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "user/" + userId);
    var response = await _client.get(uri);

    var data = json.decode(response.body)['result'];

    if (data['Usuario'] == null) {
      throw Error();
    }
    UserInfo user = UserInfo.fromJson(data['Usuario']);

    return user;
  }

  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
      [String islandId = "76ac0bec-4bc1-41a5-bc60-e528e0c12f4d"]) async {
    try {
      String islandQuery = islandId == null ? '' : '&island=' + islandId;
      String url = dotenv.env['ENDPOINT_V2']! +
          "restaurant/pagination?from=" +
          number.toString() +
          islandQuery;
      print('url: ' + url);
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      RestaurantResponse restaurantResponse =
          RestaurantResponse.fromJson(json.decode(response.body));
      return restaurantResponse;
    } on Exception catch (e) {
      throw e;
    }
  }

  Future<List<Restaurant>> getFilterRestaurants(
      String categorias,
      String municipalities,
      String types,
      String nombre,
      String islandId) async {
    try {
      print("esta es 1");
      List<Restaurant> restaurants = [];
      String url =
          dotenv.env['ENDPOINT_V2']! + "restaurant/findByFilter/filter?name=";
      if (nombre != null || nombre.isNotEmpty) url += nombre;
      url += "&businessType=";
      if (types != null && types.isNotEmpty) url += types;
      if (categorias != null && categorias.isNotEmpty)
        url += "&categories=" + categorias;
      if (municipalities != null && municipalities.isNotEmpty)
        url += "&municipalities=" + municipalities;
      if (islandId != null) url += "&island=" + islandId;
      print('url ' + url);

      var uri = Uri.parse(url);
      var response = await _client.get(uri);

      List<dynamic> data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        Restaurant restaurant = Restaurant.fromJson(data[i]);
        restaurants.add(restaurant);
      }
      return restaurants;
    } on Exception catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<Restaurant> getRestaurantById(String id) async {
    try {
      String url = dotenv.env['ENDPOINT_V2']! + "restaurant/" + id;
      print("url " + url.toString());
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      print('restaurant response' + response.body);
      Restaurant restaurant = Restaurant.fromJson(json.decode(response.body));
      return restaurant;
    } on Exception catch (e) {
      throw e;
    }
  }

  @override
  Future<List<ModelCategory>> getAllCategories() async {
    var uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "restaurant/category");
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
    var uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "municipality");
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
  Future<List<Municipality>> getAllMunicipalitiesFiltered(
      String islandId) async {
    var uri =
        Uri.parse(dotenv.env['ENDPOINT_V2']! + "areas/islands/" + islandId);
    var response = await _client.get(uri);
    List<dynamic> data = json.decode(response.body);
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
    var uri = Uri.parse(
        dotenv.env['ENDPOINT_V1']! + "user/" + userId + "/review/" + reviewId);

    var body;
    body = jsonEncode({"title": title, "review": review, "rating": rating});
    var response = await _client.put(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    return true;
  }

  @override
  Future<bool> saveReview(String userId, Restaurant restaurant, String title,
      String review, String rating) async {
    var uri =
        Uri.parse(dotenv.env['ENDPOINT_V1']! + "user/" + userId + "/review");
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
    var uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "login");

    var body;
    body = jsonEncode({
      "email": login,
      "password": password,
    });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    var data = jsonDecode(response.body);
    if (data["code"] == 400) {
      throw Error();
    }
    return data["result"];
  }

  @override
  Future<List<FotoBanner>> getGlobalImages() async {
    String url = dotenv.env['ENDPOINT_V2']! + "banner";
    var uri = Uri.parse(url);
    var response =
        await _client.get(uri, headers: {"Content-Type": "application/json"});
    List<dynamic> data = json.decode(response.body);
    List<FotoBanner> banners = [];
    for (var i = 0; i < data.length; i++) {
      FotoBanner fotoBanner = FotoBanner.fromJson(data[i]);
      banners.add(fotoBanner);
    }
    return banners;
  }

  @override
  Future<String> registerUser(Map data) async {
    var uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "register");
    var body;
    body = jsonEncode({
      "email": data["email"],
      "password": data["password"],
    });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    String id = json.decode(response.body)["result"];
    if (json.decode(response.body)["code"] == 200 && id != null) {
      uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "user");
      body = jsonEncode({
        "id": id,
        "nombre": data["nombre"],
        "apellidos": data["apellidos"],
        "email": data["email"],
        "telefono": data["telefono"],
      });
      response = await _client.post(uri,
          headers: {"Content-Type": "application/json"}, body: body);
      if (json.decode(response.body)["code"] == 200 &&
          json.decode(response.body)["result"] != null) {
        return "true";
      } else {
        return "Ha ocurrido un error al crear el usuario";
      }
    } else {
      return "El email ya pertenece a un usuario existente.";
    }
  }

  @override
  Future<List<TopRestaurants>> getTopRestaurants() async {
    try {
      String url = dotenv.env['ENDPOINT_V2']! + "restaurant/top/all";
      var uri = Uri.parse(url);
      print('top: ' + url);
      var response = await _client.get(uri);
      List<dynamic> data = json.decode(response.body);
      List<TopRestaurants> restaurants = [];
      for (var i = 0; i < data.length; i++) {
        TopRestaurants restaurant = TopRestaurants.fromJson(data[i]);
        restaurants.add(restaurant);
      }
      print('test02');
      return restaurants;
    } on Exception catch (e) {
      return [];
    }
  }

  @override
  Future<Version> getVersion() async {
    String url = dotenv.env['ENDPOINT_V2']! + "version";
    try {
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      Version data = Version.fromJson(json.decode(response.body));
      return data;
    } on Exception catch (e) {
      throw e;
    }
  }

  @override
  Future<List<CuponesAgrupados>> getCuponesHistorias() async {
    try {
      String url = dotenv.env['ENDPOINT_V2']! + "restaurant/cupones";
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      List<dynamic> data = json.decode(response.body);
      List<CuponesAgrupados> cupones = [];
      for (var i = 0; i < data.length; i++) {
        CuponesAgrupados cuponesAgrupados = CuponesAgrupados.fromJson(data[i]);
        cupones.add(cuponesAgrupados);
      }
      return cupones;
    } on Exception catch (e) {
      return [];
    }
  }

  @override
  Future<String> saveCupon(String cuponId, String userId) async {
    String url = dotenv.env['ENDPOINT_V2']! + "cupones/book";
    var uri = Uri.parse(url);
    String couponId = '';
    var body;
    body = jsonEncode({
      "cuponesId": cuponId,
      "userId": userId,
    });
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    print('response');
    print(response);
    var x = json.decode(response.body);
    print('cuponId');
    print(x['id']);
    couponId = x['id'];

    if (x["statusCode"] != null && x["statusCode"] == 500)
      return '';
    else
      return couponId;
  }

  Future<List<Cupones>> getCuponesUsuario(String id) async {
    try {
      List<Cupones> cupones = [];
      String url = dotenv.env['ENDPOINT_V2']! + "users/" + id + "/cupones";
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      var data = json.decode(response.body);
      for (var i = 0; i < data["cuponesUsuario"].length; i++) {
        Cupones cupon = Cupones.fromJson(data["cuponesUsuario"][i]);
        cupones.add(cupon);
      }
      return cupones;
    } on Exception catch (e) {
      return [];
    }
  }

  Future<CuponesUser> getOneCupon(String userId, String id) async {
    try {
      CuponesUser cupon;
      String url =
          dotenv.env['ENDPOINT_V2']! + "users/" + userId + "/cupones/" + id;
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      var data = json.decode(response.body);
      print('data');
      print(data);
      cupon = CuponesUser.fromJson(data);
      return cupon;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<List<Types>> getAllTypes() async {
    try {
      List<Types> typesList = [];
      String url = dotenv.env['ENDPOINT_V2']! + "types";
      var uri = Uri.parse(url);
      var response = await _client.get(uri);
      var data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        Types types = Types.fromJson(data[i]);
        typesList.add(types);
      }
      return typesList;
    } on Exception catch (e) {
      return [];
    }
  }

  @override
  Future<void> removeCupon(String id) async {
    try {
      List<Types> typesList = [];
      String url = dotenv.env['ENDPOINT_V2']! + "cupones/" + id;
      var uri = Uri.parse(url);
      var response = await _client.delete(uri);
      var data = json.decode(response.body);
    } on Exception catch (e) {}
  }

  @override
  Future<void> deleteUser(String id) async {
    var uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + "user/" + id);
    var response = await _client.delete(uri);

    var data = json.decode(response.body)['result'];

    if (data['id'] == null) {
      throw Error();
    }
  }

  @override
  Future<bool> blockUser(String userId, String userIdToBlock) async {
    String url = dotenv.env['ENDPOINT_V2']! + "block";
    var uri = Uri.parse(url);
    var body;
    body = jsonEncode({"user_id": userId, "user_blocked_id": userIdToBlock});
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);

    return true;
  }

  @override
  Future<List<BlockUser>> getBlockUser(String userId) async {
    String url = dotenv.env['ENDPOINT_V2']! + "block/" + userId;
    var uri = Uri.parse(url);
    List<BlockUser> userBlock = [];
    var response = await _client.get(uri);
    var data = json.decode(response.body);
    for (var i = 0; i < data.length; i++) {
      BlockUser blockUser = BlockUser.fromJson(data[i]);
      userBlock.add(blockUser);
    }
    return userBlock;
  }

  @override
  Future<bool> reportReview(String userId, String reviewId) async {
    String url = dotenv.env['ENDPOINT_V2']! + "report-review";
    var uri = Uri.parse(url);
    var body;
    body = jsonEncode({"user_id": userId, "valoraciones_id": reviewId});
    var response = await _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);
    return true;
  }

  @override
  Future<List<ReportReview>> getReviewReported(String userId) async {
    String url = dotenv.env['ENDPOINT_V2']! + "report-review/user/" + userId;
    var uri = Uri.parse(url);
    List<ReportReview> userBlock = [];
    var response = await _client.get(uri);
    var data = json.decode(response.body);
    for (var i = 0; i < data.length; i++) {
      ReportReview reportReview = ReportReview.fromJson(data[i]);
      userBlock.add(reportReview);
    }
    return userBlock;
  }

  @override
  Future<List<Video>> getAllVideos() {
    String url = dotenv.env['ENDPOINT_V2']! + "videos";
    var uri = Uri.parse(url);
    List<Video> videos = [];
    return _client.get(uri).then((response) {
      print('response: ' + response.body);

      var data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        Video video = Video.fromJson(data[i]);
        videos.add(video);
      }
      return videos;
    });
  }



  @override
  Future<bool> insertPhotoRestaurant(String restaurantId, String base64Image) {
    String url = dotenv.env['ENDPOINT_V2']! + "restaurant/" + restaurantId + "/addPhoto";
    var uri = Uri.parse(url);
    var body;
    body = jsonEncode({"photo": base64Image, "id": restaurantId});

    return _client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body).then((response) {
          print(response.body);
      return true;
    });
  }

  @override
  Future<List<Fotos>> getPhotosRestaurant(String restaurantId) {
    //get photos
    String url = dotenv.env['ENDPOINT_V2']! + "restaurant/" + restaurantId + "/photos";
    var uri = Uri.parse(url);
    List<Fotos> fotos = [];
    return _client.get(uri).then((response) {
      print('response: ' + response.body);

      var data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        Fotos foto = Fotos.fromJson(data[i]);
        fotos.add(foto);
      }
      return fotos;
    });

  }

  @override
  Future<List<Video>> getVideosRestaurant(String restaurantId) {
    String url = dotenv.env['ENDPOINT_V2']! + "videos/" + restaurantId;
    var uri = Uri.parse(url);
    List<Video> videos = [];
    return _client.get(uri).then((response) {
      var data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        Video video = Video.fromJson(data[i]);
        videos.add(video);
      }
      return videos;
    });
  }

  @override
  Future<bool> uploadVideo(MediaInfo video, String title, String restaurantId,String thumbnail) async {
    final file = File(video.path!);
    var request = http.MultipartRequest('POST', Uri.parse('https://api.guachinchesmodernos.com:459/videos'));
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['title'] = title;
    request.fields['restaurant_id'] = restaurantId;

    var response = await request.send();


    if (response.statusCode == 201) {
      var responseBody = await response.stream.bytesToString();
      var data = jsonDecode(responseBody);

      // Crear la URL para la solicitud PUT del thumbnail
      final putUrl = Uri.parse('https://api.guachinchesmodernos.com:459/videos/${data['id']}/thumbnail');

      // Realizar la solicitud PUT para subir el thumbnail
      final putResponse = await http.put(
        putUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'thumbnail': thumbnail}),
      );
      if (putResponse.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteVideo(String videoId) {
    String url =  "https://api.guachinchesmodernos.com:459/videos/" + videoId;
    var uri = Uri.parse(url);
    return _client.delete(uri).then((response) {
      return true;
    });
  }

  @override
  Future<List<BlogPost>> getAllBlogPosts() {
    String url = dotenv.env['ENDPOINT_V2']! + "blogPost";
    var uri = Uri.parse(url);
    List<BlogPost> blogPosts = [];
    return _client.get(uri).then((response) {
      var data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        BlogPost blogPost = BlogPost.fromJson(data[i]);
        blogPosts.add(blogPost);
      }
      print('blogPosts: $blogPosts');
      return blogPosts;
    });
  }
}
