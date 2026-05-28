import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[i][$tag] $message');
    } else {
      FirebaseCrashlytics.instance.log('[i][$tag] $message');
    }
  }

  static void warn(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[!][$tag] $message');
    } else {
      FirebaseCrashlytics.instance.log('[!][$tag] $message');
    }
  }

  static void error(String tag, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[x][$tag] $error${stack != null ? '\n$stack' : ''}');
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    }
  }
}
