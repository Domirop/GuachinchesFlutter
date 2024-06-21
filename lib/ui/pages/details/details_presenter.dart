import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/block_user.dart';
import 'package:guachinches/data/model/report_review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;

class DetailPresenter {
  RemoteRepository _remoteRepository;
  DetailView _view;
  final storage = new FlutterSecureStorage();
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();

  DetailPresenter(this._remoteRepository, this._view);

  isUserLogged() async {
    String? userId = await storage.read(key: "userId");
    print('test'+ userId.toString());
    if (userId != null) {
      _view.setUserId(userId);
    }
    return userId;
  }

  deleteVideo(String id) async {
    await _remoteRepository.deleteVideo(id);
  }

  getRestaurantVideos(String id) async {
    List<Video> videos = await _remoteRepository.getVideosRestaurant(id);
    print('videos: ' + videos.length.toString());

    _view.setRestaurantVideos(videos);
  }
  getRestaurantById(String id) async {
    Restaurant restaurant = await _remoteRepository.getRestaurantById(id);
    FirebaseAnalytics.instance.logEvent(
        name: 'detalles_restaurantes',
        parameters: <String, dynamic>{
          'id': '${restaurant.id}',
          'name': '${restaurant.nombre}'
        });
    // await getIsFav(id);
    try {
      String userId = await isUserLogged();

      List<BlockUser> userBlocked =
      await _remoteRepository.getBlockUser(userId);
      List<ReportReview> reportReview =
      await _remoteRepository.getReviewReported(userId);
      List<Review> valoracionesNotBlocked = [];
      print('val: ' + restaurant.valoraciones.length.toString());

      for (var i = 0; i < restaurant.valoraciones.length; i++) {
        var condition = false;
        for (var y = 0; y < userBlocked.length; y++) {
          print('userBlocked ' + restaurant.valoraciones[i].usuario.toString());
          if (userBlocked[y].userBlockedId ==
              restaurant.valoraciones[i].usuario!.id) {
            condition = true;
          }
        }
        for (var y = 0; y < reportReview.length; y++) {
          if (reportReview[y].valoracionesId ==
              restaurant.valoraciones[i].id) {
            condition = true;
          }
        }
        if (!condition) {
          valoracionesNotBlocked.add(restaurant.valoraciones[i]);
        }
      }
      restaurant.valoraciones = valoracionesNotBlocked;
    } catch (e) {
      print('error: ' + e.toString());
    }
    _view.setRestaurant(restaurant);
  }

  blockUser(String userId, String userIdToBlock) async {
    await _remoteRepository.blockUser(userId, userIdToBlock);
    _view.refreshScreen();
  }
  reportReview(String userId, String reviewId) async{
    await _remoteRepository.reportReview(userId, reviewId);
    _view.refreshScreen();

  }

  Future<void> uploadVideo(MediaInfo video, String title, String restaurantId) async {
    final file = File(video.path!);

    var request = http.MultipartRequest('POST', Uri.parse('https://api.guachinchesmodernos.com:459/videos'));
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['title'] = title;
    request.fields['restaurant_id'] = restaurantId;

    var response = await request.send();

    if (response.statusCode == 201) {
      print('Video uploaded successfully!');
    } else {
      print('Video upload failed with status: ${response.statusCode}');
    }
  }

  getIsFav(String restaurantId) async {
    RestaurantSQLLite restaurantSQLLite =
        await sqlLiteLocalRepository.getRestaurant(restaurantId);
    bool correct = false;
    if (restaurantSQLLite != null) {
      correct = true;
    } else {
      correct = false;
    }
    _view.setFav(correct);
  }

  saveFavRestaurant(String restaurantId) async {
    bool correct = false;
    RestaurantSQLLite restaurantSQLLite =
        await sqlLiteLocalRepository.getRestaurant(restaurantId);
    if (restaurantSQLLite != null) {
      correct = await sqlLiteLocalRepository.removeRestaurant(restaurantId);
    } else {
      correct = await sqlLiteLocalRepository.insertRestaurant(restaurantId);
    }
    sqlLiteLocalRepository.getRestaurants();
    _view.setFav(correct);
  }
}

abstract class DetailView {
  goToLogin();

  setFav(bool correct);

  refreshScreen();

  setUserId(String id);

  setRestaurant(Restaurant restaurant);

  setRestaurantVideos(List<Video> videos);

  updateVideos();
}
