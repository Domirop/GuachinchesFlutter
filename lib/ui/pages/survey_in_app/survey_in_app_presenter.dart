import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/secrets.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/services/device_id_service.dart';
import 'package:uuid/uuid.dart';

const String _kVotedTradicional = 'survey_inapp_voted_tradicional';
const String _kVotedModerno = 'survey_inapp_voted_moderno';
const String _kSurveyUserId = 'surveyUserId';
const int _kMinDurationSeconds = 3;

class SurveyInAppPresenter {
  final RemoteRepository _repository;
  final SurveyInAppView _view;
  final _storage = const FlutterSecureStorage();

  late String _userId;
  String _deviceId = 'unknown-device';
  DateTime? _surveyStartTime;

  SurveyInAppPresenter(this._repository, this._view);

  Future<void> initialize() async {
    try {
      _userId = await _getOrCreateUserId();
      _deviceId = await DeviceIdService.getDeviceId();
      _surveyStartTime = DateTime.now();
      await _loadChoices();
    } catch (e) {
      _view.setLoading(false);
      _view.showError('Error al inicializar la encuesta: $e');
    }
  }

  Future<String> _getOrCreateUserId() async {
    try {
      String? stored = await _storage.read(key: _kSurveyUserId);
      if (stored != null && stored.isNotEmpty) return stored;
      final newId = const Uuid().v4();
      await _storage.write(key: _kSurveyUserId, value: newId);
      return newId;
    } catch (e) {
      // Fallback to in-memory UUID if secure storage fails
      return const Uuid().v4();
    }
  }

  Future<void> _loadPreviousVotes() async {
    try {
      final votedTradicional = await _storage.read(key: _kVotedTradicional);
      final votedModerno = await _storage.read(key: _kVotedModerno);
      _view.setPreviousVotes(
        tradicional: votedTradicional,
        moderno: votedModerno,
      );
    } catch (e) {
      // If reading previous votes fails, continue without them
      _view.setPreviousVotes(tradicional: null, moderno: null);
    }
  }

  Future<void> _loadChoices() async {
    _view.setLoading(true);
    try {
      final tradicionales = await _repository.getSurveyInAppChoices(
          'Mejor-Guachinche-Tradicional', _userId);
      final modernos = await _repository.getSurveyInAppChoices(
          'Mejor-Guachinche-Moderno', _userId);

      // Shuffle for random order (same as SurveyJS choicesOrder: "random")
      tradicionales.shuffle();
      modernos.shuffle();

      _view.setChoices(tradicionales: tradicionales, modernos: modernos);
    } catch (e) {
      _view.showError('No se pudieron cargar las opciones. Comprueba tu conexión.');
    } finally {
      _view.setLoading(false);
    }
  }

  Future<void> submitVotes({
    required String? tradicionalValue,
    required String? modernoValue,
  }) async {
    // Security: time check
    if (_surveyStartTime != null) {
      final elapsed = DateTime.now().difference(_surveyStartTime!).inSeconds;
      if (elapsed < _kMinDurationSeconds) {
        _view.showError('Por favor, tómate tu tiempo para votar.');
        return;
      }
    }

    // Require at least one vote
    if (tradicionalValue == null && modernoValue == null) {
      _view.showError('Debes seleccionar al menos una opción.');
      return;
    }

    final votes = <String, String>{};
    if (tradicionalValue != null) {
      votes['Mejor-Guachinche-Tradicional'] = tradicionalValue;
    }
    if (modernoValue != null) {
      votes['Mejor-Guachinche-Moderno'] = modernoValue;
    }

    // Security: HMAC-SHA256 signature (token existente, sin cambios)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dataToSign = '$_userId:${votes.toString()}:$timestamp';
    final signature = _computeHmac(_userId, dataToSign);

    // Security: device_token con formato "{device_id}:{hmac_hex}".
    // El HMAC se calcula sobre el deviceId usando DEVICE_HMAC_SECRET.
    final hmacHex = _computeHmac(kDeviceHmacSecret, _deviceId);
    final deviceToken = '$_deviceId:$hmacHex';

    final duration = _surveyStartTime != null
        ? DateTime.now().difference(_surveyStartTime!).inSeconds
        : 0;

    _view.setSubmitting(true);
    try {
      final success = await _repository.submitSurveyInAppVotes(
          _userId, votes, signature, duration, deviceToken);

      if (success) {
        _view.onSubmitSuccess();
      } else {
        _view.showError('No se pudo enviar tu voto. Inténtalo de nuevo.');
      }
    } catch (e) {
      _view.showError('Error al enviar: $e');
    } finally {
      _view.setSubmitting(false);
    }
  }

  String _computeHmac(String key, String data) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }
}

abstract class SurveyInAppView {
  void setLoading(bool loading);
  void setSubmitting(bool submitting);
  void setChoices({
    required List<SurveyInAppChoice> tradicionales,
    required List<SurveyInAppChoice> modernos,
  });
  void setPreviousVotes({String? tradicional, String? moderno});
  void showError(String message);
  void onSubmitSuccess();
}
