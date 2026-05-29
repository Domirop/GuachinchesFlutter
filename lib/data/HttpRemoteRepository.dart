import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpCachePolicy.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_presenter.dart'
    show AlreadyVotedThisBusinessException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/weather_zone_bundle.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
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
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:http/http.dart';
import 'package:video_compress/src/media/media_info.dart';
import 'package:http/http.dart' as http;
import 'RemoteRepository.dart';
import 'model/Visit.dart';
import 'model/user_visit.dart';

class HttpRemoteRepository implements RemoteRepository {
  final Client _client;
  final HttpCacheStore _cache;
  final bool _backgroundEnabled;

  HttpRemoteRepository(
    this._client, {
    HttpCacheStore? cache,
    bool backgroundEnabled = true,
  })  : _cache = cache ?? HttpCacheStore.instance,
        _backgroundEnabled = backgroundEnabled;

  Future<T> _withSwr<T>(
    String key, {
    required Duration ttl,
    required Future<String> Function() fetchBody,
    required T Function(String body) parse,
  }) async {
    final cached = await _cache.read(key, maxAge: ttl);
    if (cached != null) {
      if (_backgroundEnabled) {
        unawaited(Future.delayed(Duration.zero, () async {
          try {
            if (await _isOffline()) return;
            final fresh = await fetchBody();
            await _cache.write(key, fresh);
          } catch (_) {}
        }));
      }
      return parse(cached);
    }

    if (await _isOffline()) {
      final stale = await _cache.readStale(key);
      if (stale != null) return parse(stale);
      throw Exception('offline:no-cache:$key');
    }

    try {
      final body = await fetchBody();
      try {
        await _cache.write(key, body);
      } catch (_) {}
      return parse(body);
    } on Exception {
      final stale = await _cache.readStale(key);
      if (stale != null) return parse(stale);
      rethrow;
    }
  }

  static Future<bool> _isOffline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result == ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> invalidateCache(String prefix) => _cache.invalidate(prefix);

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    final uri = Uri.parse(dotenv.env['ENDPOINT_V2']! + 'user/' + userId);
    AppLogger.info('http-repo', '[getUserInfo] GET $uri');
    final response = await _client.get(uri);
    AppLogger.info('http-repo', '[getUserInfo] status=${response.statusCode} bodyLen=${response.body.length}');
    if (response.statusCode == 404) {
      throw Exception('User not found');
    }
    if (response.statusCode != 200) {
      AppLogger.warn('http-repo', '[getUserInfo] FAILED body=${response.body}');
      throw Exception('getUserInfo failed: ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('getUserInfo: unexpected body shape');
    }
    return UserInfo.fromJson(decoded);
  }
  @override
  Future<List<SurveyResult>> getSurveyResults(int surveyId, String surveyName,List<Restaurant> allRestaurants) async {
    try {
      final String encodedName = Uri.encodeComponent(surveyName);
      final String url = dotenv.env['ENDPOINT_V2']! +
          "surveys/results/$surveyId/$encodedName";

      final uri = Uri.parse(url);
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((e) => SurveyResult.fromJsonWithRestaurants(e,allRestaurants)).toList();
      } else {
        throw Exception('Error al obtener resultados de la encuesta: ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw e;
    }
  }


  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
      [String islandId = "76ac0bec-4bc1-41a5-bc60-e528e0c12f4d"]) {
    final key = 'restaurants:all:$islandId:from$number';
    return _withSwr<RestaurantResponse>(
      key,
      ttl: HttpCachePolicy.listTtl,
      fetchBody: () async {
        final islandQuery = islandId == null ? '' : '&island=$islandId';
        final url = dotenv.env['ENDPOINT_V2']! +
            'restaurant/pagination?from=$number$islandQuery';
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        return response.body;
      },
      parse: (body) => RestaurantResponse.fromJson(json.decode(body)),
    );
  }

  Future<List<Restaurant>> getFilterRestaurants(
      String categorias,
      String municipalities,
      String types,
      String nombre,
      String islandId) async {
    try {

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

      var uri = Uri.parse(url);
      var response = await _client.get(uri);

      List<dynamic> data = json.decode(response.body);
      for (var i = 0; i < data.length; i++) {
        Restaurant restaurant = Restaurant.fromJson(data[i]);
        restaurants.add(restaurant);
      }
      return restaurants;
    } on Exception catch (e) {

      return [];
    }
  }

  @override
  Future<Restaurant> getRestaurantById(String id) {
    final key = 'restaurant:detail:$id';
    return _withSwr<Restaurant>(
      key,
      ttl: HttpCachePolicy.detailTtl,
      fetchBody: () async {
        final url = dotenv.env['ENDPOINT_V2']! + 'restaurant/$id';
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        return response.body;
      },
      parse: (body) => Restaurant.fromJson(json.decode(body)),
    );
  }

  Future<List<String>> getVotedRestaurantsByUser(String surveySchemaId, String userId) async {
    try {
      String baseUrl = dotenv.env['ENDPOINT_V2']!;
      String url = dotenv.env['ENDPOINT_V2']! + "surveys/results/$surveySchemaId/$userId/voted-restaurants";


      var uri = Uri.parse(url);
      var response = await _client.get(uri);


      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map<String>((item) => item.toString()).toList();
      } else {
        throw Exception('Error al obtener los restaurantes votados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la petición: $e');
    }
  }

  @override
  Future<List<ModelCategory>> getAllCategories() {
    return _withSwr<List<ModelCategory>>(
      'categories',
      ttl: HttpCachePolicy.referenceTtl,
      fetchBody: () async {
        final response = await _client
            .get(Uri.parse(dotenv.env['ENDPOINT_V2']! + 'categorias'))
            .timeout(const Duration(seconds: 15));
        return response.body;
      },
      parse: (body) {
        final data = json.decode(body) as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(ModelCategory.fromJson)
            .toList();
      },
    );
  }

  @override
  Future<List<Municipality>> getAllMunicipalities() {
    return _withSwr<List<Municipality>>(
      'municipalities',
      ttl: HttpCachePolicy.referenceTtl,
      fetchBody: () async {
        final response = await _client
            .get(Uri.parse(dotenv.env['ENDPOINT_V1']! + 'municipality'))
            .timeout(const Duration(seconds: 15));
        return response.body;
      },
      parse: (body) {
        final data = json.decode(body)['result'] as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(Municipality.fromJson)
            .toList();
      },
    );
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
      var response = await _client.get(uri);
      List<dynamic> data = json.decode(response.body);
      List<TopRestaurants> restaurants = [];
      for (var i = 0; i < data.length; i++) {
        try {
          TopRestaurants restaurant = TopRestaurants.fromJson(data[i]);
          restaurants.add(restaurant);
        } catch (e, stackTrace) {
          AppLogger.error('http-repo', e, stackTrace);
        }

      }
      return restaurants;
    } on Exception catch (e) {
      AppLogger.error('http-repo', e);
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
    AppLogger.info('http-repo', 'activateCoupon response: $response');
    var x = json.decode(response.body);
    AppLogger.info('http-repo', 'coupon id: ${x['id']}');
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
      cupon = CuponesUser.fromJson(data);
      return cupon;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<List<Types>> getAllTypes() {
    return _withSwr<List<Types>>(
      'types',
      ttl: HttpCachePolicy.referenceTtl,
      fetchBody: () async {
        final response = await _client
            .get(Uri.parse(dotenv.env['ENDPOINT_V2']! + 'types'))
            .timeout(const Duration(seconds: 15));
        return response.body;
      },
      parse: (body) {
        final data = json.decode(body) as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(Types.fromJson)
            .toList();
      },
    );
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
          AppLogger.info('http-repo', 'insertPhoto response: ${response.body}');
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
      return blogPosts;
    });
  }

  @override
  Future<List<SurveyInAppChoice>> getSurveyInAppChoices(String categoryName, String userId) async {
    try {
      final String url = dotenv.env['ENDPOINT_V2']! +
          'category-restaurants/surveyjs/1/$categoryName/by-user?user_id=$userId';
      final uri = Uri.parse(url);
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => SurveyInAppChoice.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener opciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al obtener opciones de encuesta: $e');
    }
  }

  @override
  Future<Map<String, List<String>>> getVotedByDevice(int surveySchemaId, String deviceToken) async {
    try {
      final encodedToken = Uri.encodeComponent(deviceToken);
      final url = dotenv.env['ENDPOINT_V2']! +
          'surveys/results/$surveySchemaId/by-device?device_token=$encodedToken';
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final voted = data['voted'] as Map<String, dynamic>? ?? {};
        return voted.map((key, value) =>
            MapEntry(key, (value as List).map((e) => e.toString()).toList()));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<bool> submitSurveyInAppVotes(String userId, Map<String, String> votes, String signature, int duration, String deviceToken) async {
    try {
      final String url = dotenv.env['ENDPOINT_V2']! + 'surveys/results/v2';
      final uri = Uri.parse(url);
      final body = jsonEncode({
        'survey_schema_id': 1,
        'content': votes,
        'user_id': userId,
        'token': signature,
        'duration': duration,
        'source': 'mobile',
        'device_token': deviceToken,
      });
      final response = await _client.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
      AppLogger.info('http-repo', 'HTTP POST $url → ${response.statusCode} | ${response.body}');
      if (response.statusCode == 409) {
        throw AlreadyVotedThisBusinessException();
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } on AlreadyVotedThisBusinessException {
      rethrow;
    } catch (e) {
      throw Exception('Error al enviar votos: $e');
    }
  }

  @override
  Future<bool> checkUserSurveyStatus(String userId) {

    String url = dotenv.env['ENDPOINT_V2']! + "surveys/results/1/" + userId+ "/completed";
    AppLogger.info('http-repo', '[checkUserSurveyStatus] GET $url');
    var uri = Uri.parse(url);
    return _client.get(uri).then((response) {
      var data = json.decode(response.body);
      return data["completed"];
    });
  }


  @override
  Future<List<Restaurant>> getAllSurveyRestaurants(String surveyId) async {
    try {
      String url = dotenv.env['ENDPOINT_V2']! + "category-restaurants/1/"+surveyId;
      var uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Restaurant> restaurants = [];

        for (var item in data) {
          if (item["restaurant"] != null) {
            restaurants.add(Restaurant.fromJson(item["restaurant"]));
          }
        }

        return restaurants;
      } else {
        throw Exception("Error al cargar los restaurantes: ${response.statusCode}");
      }
    } catch (e, st) {
      AppLogger.error('http-repo', e, st);
      throw Exception("Fallo al obtener restaurantes de encuesta");
    }
  }
  // Crear una visita
  Future<Visit> createVisit({
    required String restaurantId,
    String? videoUrl,
    String? creator,
    String? extraText,
  }) async {
    final url = '${dotenv.env['ENDPOINT_V2']!}visits';
    final uri = Uri.parse(url);

    final body = jsonEncode({
      'restaurantId': restaurantId,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (creator != null) 'creator': creator,
      if (extraText != null) 'extraText': extraText,
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      return Visit.fromJson(data);
    } else {
      throw Exception('Error al crear visita: ${response.statusCode} ${response.body}');
    }
  }

// Obtener todas las visitas (vídeos publicados)
  Future<List<Visit>> getAllVisits() async {
    final url =
        '${dotenv.env['ENDPOINT_V2']!}video-ingestion/restaurant-videos/published';
    final uri = Uri.parse(url);

    AppLogger.info('get-all-visits', 'GET $url');
    final response = await _client.get(uri);
    AppLogger.info(
      'get-all-visits',
      'status=${response.statusCode} body_len=${response.body.length}',
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data =
          decoded is List ? decoded : (decoded['data'] as List? ?? const []);
      AppLogger.info('get-all-visits', 'parsed array length=${data.length}');
      final visits = <Visit>[];
      var parseErrors = 0;
      for (final e in data) {
        try {
          visits.add(Visit.fromJson(e));
        } catch (err, st) {
          // Si una visita concreta tiene un shape raro y peta su parser,
          // no debe tumbar TODA la pantalla. Antes el `.map(...).toList()`
          // propagaba la excepción y `loadVisits` quemaba con VisitsFailure
          // → "No hemos podido cargar las visitas" pero por una sola fila
          // mala. Ahora la saltamos y seguimos con el resto.
          parseErrors++;
          AppLogger.error('get-all-visits-parser', err, st);
        }
      }
      AppLogger.info(
        'get-all-visits',
        'visits_built=${visits.length} parse_errors=$parseErrors',
      );
      return visits;
    } else {
      throw Exception('Error al obtener visitas: ${response.statusCode}');
    }
  }

// Obtener una visita por ID
  Future<Visit> getVisitById(String id) async {
    final url =
        '${dotenv.env['ENDPOINT_V2']!}video-ingestion/restaurant-videos/$id';
    final uri = Uri.parse(url);

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Visit.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Visita no encontrada');
    } else {
      throw Exception('Error al obtener visita: ${response.statusCode}');
    }
  }

// Obtener visitas por restaurante
  Future<List<Visit>> getVisitsByRestaurant(String restaurantId) async {
    final url = '${dotenv.env['ENDPOINT_V2']!}restaurants/$restaurantId/visits';
    final uri = Uri.parse(url);

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Visit.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener visitas del restaurante: ${response.statusCode}');
    }
  }

// Actualizar una visita
  Future<Visit> updateVisit(
      String id, {
        String? videoUrl,
        String? creator,
        String? extraText,
        String? restaurantId, // opcional por si permites mover la visita a otro restaurant
      }) async {
    final url = '${dotenv.env['ENDPOINT_V2']!}visits/$id';
    final uri = Uri.parse(url);

    final payload = <String, dynamic>{};
    if (videoUrl != null) payload['videoUrl'] = videoUrl;
    if (creator != null) payload['creator'] = creator;
    if (extraText != null) payload['extraText'] = extraText;
    if (restaurantId != null) payload['restaurantId'] = restaurantId;

    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Visit.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Visita no encontrada');
    } else {
      throw Exception('Error al actualizar visita: ${response.statusCode} ${response.body}');
    }
  }

// Eliminar una visita
  Future<bool> deleteVisit(String id) async {
    final url = '${dotenv.env['ENDPOINT_V2']!}visits/$id';
    final uri = Uri.parse(url);

    final response = await _client.delete(uri);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 404) {
      throw Exception('Visita no encontrada');
    } else {
      throw Exception('Error al eliminar visita: ${response.statusCode}');
    }
  }

  // ────────────────────────────────────────────────
  // Curated lists, zones, weather (migration-mobile/001)
  // ────────────────────────────────────────────────

  @override
  Future<List<CuratedList>> getCuratedLists({String? islandId}) async {
    final base = dotenv.env['ENDPOINT_V2']! + 'curated-lists';
    final url = islandId != null && islandId.isNotEmpty
        ? '$base?islandId=$islandId'
        : base;
    AppLogger.info('http-repo', '[getCuratedLists] GET $url');
    final response = await _client.get(Uri.parse(url));
    AppLogger.info('http-repo', '[getCuratedLists] status=${response.statusCode} body=${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
    if (response.statusCode != 200) {
      throw Exception('Error getCuratedLists: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(response.body);
    AppLogger.info('http-repo', '[getCuratedLists] count=${data.length}');
    return data
        .whereType<Map<String, dynamic>>()
        .map(CuratedList.fromJson)
        .toList();
  }

  @override
  Future<CuratedListDetail> getCuratedListById(String id) async {
    final url = dotenv.env['ENDPOINT_V2']! + 'curated-lists/' + id;
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error getCuratedListById: ${response.statusCode}');
    }
    return CuratedListDetail.fromJson(json.decode(response.body));
  }

  @override
  Future<List<Zone>> getZonesByIsland(String islandId) async {
    final url = dotenv.env['ENDPOINT_V2']! + 'zones/island/' + islandId;
    AppLogger.info('http-repo', '[getZonesByIsland] GET $url');
    final response = await _client.get(Uri.parse(url));
    AppLogger.info('http-repo', '[getZonesByIsland] status=${response.statusCode}');
    if (response.statusCode != 200) {
      AppLogger.warn('http-repo', '[getZonesByIsland] body=${response.body}');
      throw Exception('Error getZonesByIsland: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(response.body);
    AppLogger.info('http-repo', '[getZonesByIsland] count=${data.length}');
    return data
        .whereType<Map<String, dynamic>>()
        .map(Zone.fromJson)
        .toList();
  }

  @override
  Future<WeatherData> getWeatherForIsland(String islandId) =>
      _fetchWeather('weather/island/' + islandId);

  @override
  Future<WeatherData> getWeatherForMunicipality(String municipalityId) =>
      _fetchWeather('weather/municipality/' + municipalityId);

  @override
  Future<WeatherData> getWeatherForZone(String zoneId) =>
      _fetchWeather('weather/zone/' + zoneId);

  @override
  Future<WeatherZoneBundle> getWeatherBundleForIsland(String islandId) async {
    final url = dotenv.env['ENDPOINT_V2']! + 'weather/island/' + islandId + '/zones';
    AppLogger.info('http-repo', '[getWeatherBundleForIsland] GET $url');
    final response = await _client.get(Uri.parse(url));
    AppLogger.info('http-repo', '[getWeatherBundleForIsland] status=${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Error getWeatherBundleForIsland: ${response.statusCode}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return WeatherZoneBundle.fromJson(data);
  }

  @override
  Future<List<Island>> getIslands() {
    return _withSwr<List<Island>>(
      'islands',
      ttl: HttpCachePolicy.referenceTtl,
      fetchBody: () async {
        final url = dotenv.env['ENDPOINT_V2']! + 'islands';
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw Exception('Error getIslands: ${response.statusCode}');
        }
        return response.body;
      },
      parse: (body) => (json.decode(body) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Island.fromJson)
          .toList(),
    );
  }

  @override
  Future<List<SimpleMunicipality>> getOfficialMunicipalitiesByIsland(
    String islandId,
  ) async {
    final url = dotenv.env['ENDPOINT_V2']! +
        'municipios/islands/' +
        islandId +
        '?onlyOfficial=true';
    AppLogger.info('http-repo', '[getOfficialMunicipalities] GET $url');
    final response = await _client.get(Uri.parse(url));
    AppLogger.info('http-repo', '[getOfficialMunicipalities] status=${response.statusCode}');
    if (response.statusCode != 200) {
      AppLogger.warn('http-repo', '[getOfficialMunicipalities] body=${response.body}');
      throw Exception(
          'Error getOfficialMunicipalitiesByIsland: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(response.body);
    AppLogger.info('http-repo', '[getOfficialMunicipalities] count=${data.length}');
    return data
        .whereType<Map<String, dynamic>>()
        .map(SimpleMunicipality.fromJson)
        .toList();
  }

  @override
  Future<List<SimpleMunicipality>> getMunicipalitiesByZone(
    String zoneId,
  ) async {
    final url = dotenv.env['ENDPOINT_V2']! + 'municipios/zone/' + zoneId;
    AppLogger.info('http-repo', '[getMunicipalitiesByZone] GET $url');
    final response = await _client.get(Uri.parse(url));
    AppLogger.info('http-repo', '[getMunicipalitiesByZone] status=${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
          'Error getMunicipalitiesByZone: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(response.body);
    AppLogger.info('http-repo', '[getMunicipalitiesByZone] count=${data.length}');
    return data
        .whereType<Map<String, dynamic>>()
        .map(SimpleMunicipality.fromJson)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final uri = Uri.parse(dotenv.env['ENDPOINT_V2']! + 'auth/google');
    AppLogger.info('http-repo', '[loginWithGoogle] POST $uri idTokenLen=${idToken.length}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    AppLogger.info('http-repo', '[loginWithGoogle] status=${response.statusCode} body=${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('loginWithGoogle failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> loginWithApple(String idToken, {String? givenName, String? familyName}) async {
    final uri = Uri.parse(dotenv.env['ENDPOINT_V2']! + 'auth/apple');
    final Map<String, dynamic> bodyMap = {'idToken': idToken};
    if (givenName != null || familyName != null) {
      final Map<String, dynamic> fullName = {};
      if (givenName != null) fullName['givenName'] = givenName;
      if (familyName != null) fullName['familyName'] = familyName;
      bodyMap['fullName'] = fullName;
    }
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyMap),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('loginWithApple failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<List<UserVisit>> getUserVisits(String userId) async {
    final uri = Uri.parse('${dotenv.env['ENDPOINT_V2']!}visits/user/$userId');
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = json.decode(response.body);
      final List<dynamic> data =
          decoded is List ? decoded : (decoded['data'] as List? ?? const []);
      return data
          .whereType<Map<String, dynamic>>()
          .map(UserVisit.fromJson)
          .toList();
    } else {
      throw Exception('getUserVisits failed: ${response.statusCode}');
    }
  }

  Future<WeatherData> _fetchWeather(String path) async {
    final url = dotenv.env['ENDPOINT_V2']! + path;
    AppLogger.info('http-repo', '[weather] GET $url');
    final response = await _client.get(Uri.parse(url));
    AppLogger.info('http-repo', '[weather] status=${response.statusCode} body=${response.body}');
    if (response.statusCode != 200) {
      return const WeatherData.unknown();
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final tempRaw = data['tempC'];
    final condition = (data['condition'] ?? 'unknown') as String;
    final rawEmoji = data['emoji'] as String?;
    final emoji = (rawEmoji == null || rawEmoji.isEmpty || rawEmoji == '—')
        ? _emojiForCondition(condition)
        : rawEmoji;
    return WeatherData(
      tempC: tempRaw == null ? null : (tempRaw as num).toDouble(),
      condition: condition,
      emoji: emoji,
    );
  }

  static String _emojiForCondition(String condition) => switch (condition) {
        'sunny' => '☀️',
        'cloudy' => '⛅',
        'rain' => '🌧️',
        'fog' => '🌫️',
        'storm' => '⛈️',
        _ => '—',
      };

  @override
  Future<DateTime> requestAccountDeletion(String userId) async {
    final uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + 'user/$userId/request-deletion');
    final response = await _client.post(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 400) {
      throw Exception('requestAccountDeletion failed: ${response.statusCode}');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    return DateTime.parse(body['deletionScheduledAt'] as String);
  }

  @override
  Future<void> cancelAccountDeletion(String userId) async {
    final uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + 'user/$userId/cancel-deletion');
    final response = await _client.post(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 400) {
      throw Exception('cancelAccountDeletion failed: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final uri = Uri.parse(dotenv.env['ENDPOINT_V1']! + 'user/$userId/export');
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 400) {
      throw Exception('exportUserData failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
