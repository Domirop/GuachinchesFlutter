import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Compara versiones `mayor.menor.parche` numéricamente (`4.10.0` > `4.9.3`).
/// Ignora el sufijo de compilación (`+94`) y lo que no sea número. Negativo si
/// [a] < [b], 0 si son iguales, positivo si [a] > [b].
int compareAppVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .trim()
      .split('.')
      .map((p) => int.tryParse(RegExp(r'^\d+').stringMatch(p) ?? '') ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

/// Versión de la app según `env_files/*.env` (`GET_IOS_VERSION` /
/// `GET_ANDROID_VERSION`), la misma que usa la pantalla de arranque.
String? currentAppVersion() {
  if (!dotenv.isInitialized) return null;
  final v = dotenv.env[Platform.isIOS ? 'GET_IOS_VERSION' : 'GET_ANDROID_VERSION'];
  return v == null || v.trim().isEmpty ? null : v.trim();
}
