import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart';
import 'package:http/http.dart' as http;

/// Moderación de reseñas en el cliente (normas UGC de la App Store):
/// reportar (se oculta al momento, con «Deshacer») y bloquear a quien
/// escribe (se dejan de ver todas sus reseñas).
///
/// - Reportar llama a `POST report-review` con el payload de siempre
///   (`user_id`, `valoraciones_id`). El backend **no guarda motivo**: el
///   motivo se queda aquí y en el log. El envío espera [sendDelay] para que
///   «Deshacer» no llegue a mandar nada; pasado ese tiempo ya no se puede
///   retirar (no hay endpoint) y «Deshacer» solo la vuelve a mostrar aquí.
/// - Bloquear llama a `POST block` (`blockUser`). Al recargar la ficha, el
///   presentador ya filtra lo bloqueado y lo reportado por el servidor.
///
/// Una sola instancia ([instance]) para que la ficha y «Todas las reseñas»
/// vean lo mismo.
class ReviewModeration extends ChangeNotifier {
  ReviewModeration({
    RemoteRepository? repository,
    Future<String?> Function()? readUserId,
    this.sendDelay = const Duration(seconds: 5),
  })  : _repoOverride = repository,
        _readUserId = readUserId ?? _secureUserId;

  static ReviewModeration instance = ReviewModeration();

  final RemoteRepository? _repoOverride;
  late final RemoteRepository _repo =
      _repoOverride ?? HttpRemoteRepository(http.Client());
  final Future<String?> Function() _readUserId;
  final Duration sendDelay;

  static const _storage = FlutterSecureStorage();
  static Future<String?> _secureUserId() => _storage.read(key: 'userId');

  final Set<String> _hidden = {};
  final Set<String> _blocked = {};
  final Map<String, ReviewReportReason> _reasons = {};
  final Map<String, Timer> _pending = {};
  final Set<String> _sent = {};

  /// Reseñas reportadas en esta sesión (se pintan como «Reseña oculta»).
  Set<String> get hiddenReviewIds => Set.unmodifiable(_hidden);

  /// Autores bloqueados en esta sesión.
  Set<String> get blockedUserIds => Set.unmodifiable(_blocked);

  bool isHidden(String reviewId) => _hidden.contains(reviewId);
  bool isBlocked(String userId) =>
      userId.isNotEmpty && _blocked.contains(userId);
  ReviewReportReason? reasonFor(String reviewId) => _reasons[reviewId];

  String? _cachedUserId;

  /// Última sesión leída (para no ofrecer «⋯» en tu propia reseña).
  String? get cachedUserId => _cachedUserId;

  /// Id de la persona con sesión iniciada; `null` si es invitada.
  Future<String?> currentUserId() async {
    String? id;
    try {
      final raw = await _readUserId();
      id = (raw == null || raw.isEmpty) ? null : raw;
    } catch (e, st) {
      AppLogger.error('review-moderation', e, st);
    }
    if (id != _cachedUserId) {
      _cachedUserId = id;
      notifyListeners();
    }
    return id;
  }

  /// Oculta la reseña ya y programa el envío del reporte.
  void report({
    required String reviewId,
    required String reporterId,
    required ReviewReportReason reason,
  }) {
    _hidden.add(reviewId);
    _reasons[reviewId] = reason;
    AppLogger.info('review-moderation',
        'report review=$reviewId reason=${reason.code} (motivo solo en cliente)');
    _pending[reviewId]?.cancel();
    _pending[reviewId] = Timer(sendDelay, () => _send(reviewId, reporterId));
    notifyListeners();
  }

  /// «Deshacer»: si el reporte aún no salió, no se manda.
  void undo(String reviewId) {
    final t = _pending.remove(reviewId);
    t?.cancel();
    if (t == null && _sent.contains(reviewId)) {
      AppLogger.info('review-moderation',
          'undo after send review=$reviewId: el backend no permite retirarlo');
    }
    _hidden.remove(reviewId);
    _reasons.remove(reviewId);
    notifyListeners();
  }

  /// Manda ya los reportes pendientes (p. ej. al salir de la pantalla).
  Future<void> flush() async {
    final ids = _pending.keys.toList();
    final userId = await currentUserId();
    if (userId == null) return;
    for (final id in ids) {
      _pending.remove(id)?.cancel();
      await _send(id, userId);
    }
  }

  Future<void> _send(String reviewId, String reporterId) async {
    _pending.remove(reviewId);
    if (!_hidden.contains(reviewId)) return;
    try {
      await _repo.reportReview(reporterId, reviewId);
      _sent.add(reviewId);
    } catch (e, st) {
      AppLogger.error('review-moderation', e, st);
      // Se reintenta una vez más tarde; la reseña sigue oculta aquí.
      _pending[reviewId] = Timer(
          const Duration(seconds: 30), () => _retry(reviewId, reporterId));
    }
  }

  Future<void> _retry(String reviewId, String reporterId) async {
    _pending.remove(reviewId);
    if (!_hidden.contains(reviewId)) return;
    try {
      await _repo.reportReview(reporterId, reviewId);
      _sent.add(reviewId);
    } catch (e, st) {
      AppLogger.error('review-moderation', e, st);
    }
  }

  /// Bloquea a [blockedUserId]. Devuelve `false` si el servidor falla (y no
  /// se oculta nada).
  Future<bool> block({
    required String userId,
    required String blockedUserId,
  }) async {
    if (blockedUserId.isEmpty) return false;
    try {
      await _repo.blockUser(userId, blockedUserId);
    } catch (e, st) {
      AppLogger.error('review-moderation', e, st);
      return false;
    }
    _blocked.add(blockedUserId);
    notifyListeners();
    return true;
  }

  @visibleForTesting
  bool isPending(String reviewId) => _pending.containsKey(reviewId);

  @override
  void dispose() {
    for (final t in _pending.values) {
      t.cancel();
    }
    _pending.clear();
    super.dispose();
  }
}
