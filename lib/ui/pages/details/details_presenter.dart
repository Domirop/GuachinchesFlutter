import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/Visit.dart';
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
    AppLogger.info('details-presenter', 'userId: $userId');
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
    AppLogger.info('details-presenter', 'videos: ${videos.length}');

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
    try {
      String userId = await isUserLogged();

      List<BlockUser> userBlocked =
      await _remoteRepository.getBlockUser(userId);
      List<ReportReview> reportReview =
      await _remoteRepository.getReviewReported(userId);
      List<Review> valoracionesNotBlocked = [];
      AppLogger.info('details-presenter', 'val: ${restaurant.valoraciones.length}');

      for (var i = 0; i < restaurant.valoraciones.length; i++) {
        var condition = false;
        for (var y = 0; y < userBlocked.length; y++) {
          AppLogger.info('details-presenter', 'userBlocked ${restaurant.valoraciones[i].usuario}');
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
    } catch (e, st) {
      AppLogger.error('details-presenter', e, st);
    }
    _view.setRestaurant(restaurant);

    // Fetch visit data for editorial sections (non-blocking)
    try {
      final visits = await _remoteRepository.getVisitsByRestaurant(restaurant.id);
      _view.setVisit(visits.isNotEmpty ? visits.first : null);
    } catch (e, st) {
      AppLogger.error('details-presenter', e, st);
      _view.setVisit(null);
    }
  }

  blockUser(String userId, String userIdToBlock) async {
    await _remoteRepository.blockUser(userId, userIdToBlock);
    _view.refreshScreen();
  }

  reportReview(String userId, String reviewId) async {
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
      AppLogger.info('details-presenter', 'Video uploaded successfully!');
    } else {
      AppLogger.warn('details-presenter', 'Video upload failed with status: ${response.statusCode}');
    }
  }

  getIsFav(String restaurantId) async {
    final isFav = await sqlLiteLocalRepository.isFavorite(restaurantId);
    _view.setFav(isFav);
  }

  saveFavRestaurant(String restaurantId) async {
    final wasFav = await sqlLiteLocalRepository.isFavorite(restaurantId);
    if (wasFav) {
      final ok = await sqlLiteLocalRepository.removeRestaurant(restaurantId);
      _view.setFav(ok ? false : true);
    } else {
      final ok = await sqlLiteLocalRepository.insertRestaurant(restaurantId);
      _view.setFav(ok ? true : false);
    }
  }
}

abstract class DetailView {
  goToLogin();

  setFav(bool correct);

  refreshScreen();

  setUserId(String id);

  setRestaurant(Restaurant restaurant);

  setRestaurantVideos(List<Video> videos);

  setVisit(Visit? visit);

  updateVideos();
}
