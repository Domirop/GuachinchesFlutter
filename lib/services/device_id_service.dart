import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();
  static const _kDeviceId = 'survey_device_id';

  /// Estrategia:
  /// 1. Leer UUID guardado en storage (persiste entre sesiones, se borra al desinstalar en Android).
  /// 2. Si no hay UUID (primera vez o reinstalación en Android), usar el hardware fingerprint
  ///    como base → derivar un UUID determinista con SHA-256.
  ///    El fingerprint sobrevive reinstalaciones en Android.
  /// 3. Guardar el UUID resultante para futuras sesiones.
  static Future<String> getDeviceId() async {
    final storage = AppStorage.instance;

    // 1. Intentar leer UUID guardado
    try {
      final stored = await storage.read(key: _kDeviceId);
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {}

    // 2. Generar UUID a partir del hardware (persistente entre reinstalaciones)
    final hardwareId = await _getHardwareId();
    final deviceId = _deterministicUuid(hardwareId);

    // 3. Guardar para próximas sesiones
    try {
      await storage.write(key: _kDeviceId, value: deviceId);
    } catch (_) {}

    return deviceId;
  }

  /// Obtiene un identificador hardware del dispositivo.
  /// Android: fingerprint del build (persiste entre reinstalaciones, cambia con actualizaciones de SO).
  /// iOS: identifierForVendor (persiste en Keychain incluso entre reinstalaciones).
  static Future<String> _getHardwareId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        // fingerprint incluye brand/device/version/build — estable entre reinstalaciones
        if (info.fingerprint.isNotEmpty) return info.fingerprint;
        if (info.id.isNotEmpty) return info.id;
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        final idfv = info.identifierForVendor;
        if (idfv != null && idfv.isNotEmpty) return idfv;
      }
    } catch (_) {}
    return 'unknown-${const Uuid().v4()}';
  }

  /// Convierte un string hardware en un UUID v4 determinista usando SHA-256.
  /// El mismo input siempre produce el mismo UUID.
  static String _deterministicUuid(String input) {
    final hash = sha256.convert(utf8.encode(input)).bytes;
    // Formatear los primeros 16 bytes como UUID v4
    final b = hash.sublist(0, 16);
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant
    final hex = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
