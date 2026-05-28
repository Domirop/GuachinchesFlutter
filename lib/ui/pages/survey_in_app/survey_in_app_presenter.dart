import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/services/device_id_service.dart';
import 'package:uuid/uuid.dart';

const String _kSurveyUserId = 'surveyUserId';
const int _kMinDurationSeconds = 3;

class SurveyInAppPresenter {
  final RemoteRepository _repository;
  final SurveyInAppView _view;
  final _storage = AppStorage.instance;

  late String _userId;
  String _deviceId = 'unknown-device';
  String _deviceToken = '';
  DateTime? _surveyStartTime;

  SurveyInAppPresenter(this._repository, this._view);

  Future<void> initialize() async {
    try {
      _userId = await _getOrCreateUserId();
      _deviceId = await DeviceIdService.getDeviceId();
      _deviceToken = '$_deviceId:${_computeHmac(dotenv.env['DEVICE_HMAC_SECRET']!, _deviceId)}';
      AppLogger.info('survey-in-app-presenter', '── SURVEY INIT ── USER_ID=$_userId DEVICE_ID=$_deviceId DEVICE_TOKEN=$_deviceToken');
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
    } catch (e, st) {
      AppLogger.error('survey-in-app-presenter', e, st);
      return const Uuid().v4();
    }
  }

  Future<void> _loadChoices() async {
    _view.setLoading(true);
    try {
      // Cargar en paralelo: opciones disponibles + ya votados por este dispositivo
      final results = await Future.wait([
        _repository.getSurveyInAppChoices('Mejor-Guachinche-Tradicional', _userId),
        _repository.getSurveyInAppChoices('Mejor-Guachinche-Moderno', _userId),
        _repository.getVotedByDevice(1, _deviceToken),
      ]);

      var tradicionales = results[0] as List<SurveyInAppChoice>;
      var modernos = results[1] as List<SurveyInAppChoice>;
      final voted = results[2] as Map<String, List<String>>;

      // Excluir los que este dispositivo ya votó
      final votedTrad = voted['Mejor-Guachinche-Tradicional'] ?? [];
      final votedMod = voted['Mejor-Guachinche-Moderno'] ?? [];

      tradicionales = tradicionales
          .where((c) => !votedTrad.contains(c.value))
          .toList();
      modernos = modernos
          .where((c) => !votedMod.contains(c.value))
          .toList();

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
    if (_surveyStartTime != null) {
      final elapsed = DateTime.now().difference(_surveyStartTime!).inSeconds;
      if (elapsed < _kMinDurationSeconds) {
        _view.showError('Por favor, tómate tu tiempo para votar.');
        return;
      }
    }

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

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dataToSign = '$_userId:${votes.toString()}:$timestamp';
    final signature = _computeHmac(_userId, dataToSign);

    final duration = _surveyStartTime != null
        ? DateTime.now().difference(_surveyStartTime!).inSeconds
        : 0;

    AppLogger.info('survey-in-app-presenter', '── SUBMIT VOTES ── votes=$votes device_token=$_deviceToken');
    _view.setSubmitting(true);
    try {
      final success = await _repository.submitSurveyInAppVotes(
          _userId, votes, signature, duration, _deviceToken);

      if (success) {
        AppLogger.info('survey-in-app-presenter', 'SUBMIT: OK');
        _view.onSubmitSuccess();
      } else {
        AppLogger.warn('survey-in-app-presenter', 'SUBMIT: FAILED (non-200/201)');
        _view.showError('No se pudo enviar tu voto. Inténtalo de nuevo.');
      }
    } on AlreadyVotedThisBusinessException {
      AppLogger.warn('survey-in-app-presenter', 'SUBMIT: 409 already_voted_this_business');
      _view.showError('Ya has votado a este negocio anteriormente.');
    } catch (e, st) {
      AppLogger.error('survey-in-app-presenter', e, st);
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

class AlreadyVotedThisBusinessException implements Exception {}

abstract class SurveyInAppView {
  void setLoading(bool loading);
  void setSubmitting(bool submitting);
  void setChoices({
    required List<SurveyInAppChoice> tradicionales,
    required List<SurveyInAppChoice> modernos,
  });
  void showError(String message);
  void onSubmitSuccess();
}
