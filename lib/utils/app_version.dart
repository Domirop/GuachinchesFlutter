import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

String? _installed;

/// Lee la versión instalada (`CFBundleShortVersionString` en iOS,
/// `versionName` en Android) una vez al arrancar, antes de `runApp`.
Future<void> loadInstalledAppVersion() async {
  try {
    final v = (await PackageInfo.fromPlatform()).version.trim();
    _installed = v.isEmpty ? null : v;
  } catch (_) {
    _installed = null; // sin versión: el servidor manda (`upgrade_required`)
  }
}

/// Versión instalada de la app para `minAppVersion` de la encuesta. `null`
/// si no se ha podido leer. (No sale de `env_files/*.env`: allí
/// `GET_IOS_VERSION` es el número que la pantalla de arranque compara con
/// la base de datos, no la versión de la app.)
String? currentAppVersion() => _installed;

@visibleForTesting
set installedAppVersionForTest(String? v) => _installed = v;
