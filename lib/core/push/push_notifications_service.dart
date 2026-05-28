import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:guachinches/core/logging/app_logger.dart';

class PushNotificationsService {
  static final PushNotificationsService instance =
      PushNotificationsService._internal();
  PushNotificationsService._internal();

  Future<void> init() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      AppLogger.warn('push', 'requestPermission failed: $e');
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      AppLogger.info('push', 'fcm token: $token');
    } catch (e) {
      AppLogger.warn('push', 'getToken failed: $e');
    }

    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.info('push', 'onMessage: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.info('push', 'onMessageOpenedApp: ${message.messageId}');
    });
  }
}
