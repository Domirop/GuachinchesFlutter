import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/logging/app_logger.dart';

/// Fecha de eliminación programada, guardada en el móvil.
///
/// El perfil (`GET /user/:id`) no dice si la cuenta está pendiente de
/// eliminación; solo `POST …/request-deletion` devuelve la fecha. La
/// guardamos por usuario para que, al volver a abrir Mi cuenta, siga el
/// aviso y el botón «Cancelar eliminación».
class AccountDeletionStore {
  final FlutterSecureStorage _storage;

  const AccountDeletionStore(
      {FlutterSecureStorage storage = const FlutterSecureStorage()})
      : _storage = storage;

  static String keyFor(String userId) => 'account_deletion_at_$userId';

  Future<DateTime?> read(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final raw = await _storage.read(key: keyFor(userId));
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (e) {
      AppLogger.warn('account-deletion', 'no se pudo leer la fecha: $e');
      return null;
    }
  }

  Future<void> save(String userId, DateTime at) async {
    if (userId.isEmpty) return;
    try {
      await _storage.write(
          key: keyFor(userId), value: at.toUtc().toIso8601String());
    } catch (e) {
      AppLogger.warn('account-deletion', 'no se pudo guardar la fecha: $e');
    }
  }

  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _storage.delete(key: keyFor(userId));
    } catch (e) {
      AppLogger.warn('account-deletion', 'no se pudo borrar la fecha: $e');
    }
  }
}
