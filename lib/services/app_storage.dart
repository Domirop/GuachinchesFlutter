import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage compartido con opciones consistentes en todas las plataformas.
/// En Android usa encryptedSharedPreferences (más fiable que el Keystore por defecto).
class AppStorage {
  static final FlutterSecureStorage instance = Platform.isAndroid
      ? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true))
      : const FlutterSecureStorage();
}
