import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:guachinches/services/survey_integrity/survey_integrity.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// *Certificate pinning* del cliente HTTP de la encuesta v3 (`editions/current`,
/// `my-votes`, `votes`).
///
/// Solo se confía en las raíces de [roots] (`SecurityContext(withTrustedRoots:
/// false)`): una CA instalada por el usuario o un proxy no pueden leer ni
/// reescribir estas peticiones (ENCUESTA-SEGURIDAD.md §10.2 #11).
///
/// `api.guachinchesmodernos.com:459` usa Let's Encrypt (cadena del 14/10/2026:
/// hoja ← YR2 ← Root YR, con firma cruzada de ISRG Root X1). Se fijan:
/// - ISRG Root X1 (RSA, caduca el 4/6/2035): ancla de la cadena actual.
/// - ISRG Root X2 (ECDSA, caduca el 17/9/2040): respaldo si el balanceador pasa
///   a un certificado ECDSA de Let's Encrypt.
/// Cómo rotarlas: `docs/encuesta-antivoto.md`.
class SurveyPinning {
  SurveyPinning._();

  static const roots = [
    'assets/certs/isrg_root_x1.pem',
    'assets/certs/isrg_root_x2.pem',
  ];

  /// Solo en debug y solo contra un backend local o en modo `fake`; en release
  /// la constante `kDebugMode` es `false` y el pinning siempre está activo.
  static bool disabledFor(Uri endpoint) =>
      kDebugMode && (FakeAppCheckTokenSource.enabled || isLocalHost(endpoint.host));

  @visibleForTesting
  static bool isLocalHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.localhost') || h.endsWith('.local')) {
      return true;
    }
    if (h == '::1' || h == '[::1]' || h == '10.0.2.2') return true;
    final ip = InternetAddress.tryParse(h);
    if (ip == null || ip.type != InternetAddressType.IPv4) return false;
    final b = ip.rawAddress;
    return b[0] == 127 ||
        b[0] == 10 ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31);
  }

  /// Contexto TLS solo con las raíces fijadas.
  static Future<SecurityContext> context({AssetBundle? bundle}) async {
    final ctx = SecurityContext(withTrustedRoots: false);
    for (final path in roots) {
      final data = await (bundle ?? rootBundle).load(path);
      ctx.setTrustedCertificatesBytes(data.buffer.asUint8List());
    }
    return ctx;
  }

  /// Cliente para la encuesta v3: con pinning, salvo [disabledFor].
  static Future<http.Client> client(Uri endpoint, {AssetBundle? bundle}) async {
    if (disabledFor(endpoint)) return http.Client();
    final io = HttpClient(context: await context(bundle: bundle))
      ..connectionTimeout = const Duration(seconds: 15);
    // Sin badCertificateCallback: cualquier cadena que no acabe en las raíces
    // fijadas falla con HandshakeException.
    return IOClient(io);
  }
}
