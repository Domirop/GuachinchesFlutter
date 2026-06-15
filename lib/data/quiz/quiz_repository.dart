import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:http/http.dart' as http;

/// Acceso REST al juego "¿Cuánto sabes de Canarias?" (backend NestJS `/quiz/*`).
/// Auth por header `x-user-id` (uuid de `usuarios`), como el resto del backend.
/// El scoring y la validación van en servidor; aquí solo orquestamos llamadas.
class QuizRepository {
  final http.Client _client;
  QuizRepository([http.Client? client]) : _client = client ?? sharedHttpClient;

  String get _base => dotenv.env['ENDPOINT_V2']!;

  Future<String?> currentUserId() =>
      AppStorage.instance.read(key: 'userId');

  Future<Map<String, String>> _authHeaders() async {
    final uid = await currentUserId();
    return {
      'Content-Type': 'application/json',
      if (uid != null) 'x-user-id': uid,
    };
  }

  Map<String, dynamic> _decodeMap(http.Response r, String op) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw QuizException('$op falló (${r.statusCode})');
    }
    final d = jsonDecode(r.body);
    if (d is! Map<String, dynamic>) {
      throw QuizException('$op: respuesta inesperada');
    }
    return d;
  }

  /// Catálogo público de las 7 categorías.
  Future<List<QuizCategory>> getCategories() async {
    final r = await _client.get(Uri.parse('${_base}quiz/categories'));
    if (r.statusCode != 200) {
      throw QuizException('getCategories falló (${r.statusCode})');
    }
    final list = jsonDecode(r.body) as List;
    final cats = list
        .map((e) => QuizCategory.fromJson((e as Map).cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return cats;
  }

  /// Stats + rango del jugador autenticado.
  Future<QuizStats> getStats() async {
    final r = await _client.get(Uri.parse('${_base}quiz/me/stats'),
        headers: await _authHeaders());
    return QuizStats.fromJson(_decodeMap(r, 'getStats'));
  }

  /// Partida activa del usuario (para continuar), o null.
  Future<QuizSession?> getActiveSession() async {
    final r = await _client.get(Uri.parse('${_base}quiz/me/active'),
        headers: await _authHeaders());
    if (r.statusCode != 200 || r.body.isEmpty || r.body == 'null') return null;
    final d = jsonDecode(r.body);
    if (d is! Map<String, dynamic>) return null;
    return QuizSession.fromJson(d);
  }

  /// Historial de partidas terminadas.
  Future<List<QuizSessionSummary>> getMySessions({int limit = 10}) async {
    final r = await _client.get(
        Uri.parse('${_base}quiz/me/sessions?limit=$limit'),
        headers: await _authHeaders());
    if (r.statusCode != 200) {
      throw QuizException('getMySessions falló (${r.statusCode})');
    }
    final list = jsonDecode(r.body) as List;
    return list
        .map((e) =>
            QuizSessionSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Ranking por puntos totales (top N + tu posición).
  Future<List<QuizRankingEntry>> getRanking({int limit = 50}) async {
    final r = await _client.get(
        Uri.parse('${_base}quiz/ranking?limit=$limit'),
        headers: await _authHeaders());
    if (r.statusCode != 200) {
      throw QuizException('getRanking falló (${r.statusCode})');
    }
    final list = jsonDecode(r.body) as List;
    return list
        .map((e) =>
            QuizRankingEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Inicia una partida nueva.
  Future<QuizSession> startSession() async {
    final r = await _client.post(Uri.parse('${_base}quiz/sessions'),
        headers: await _authHeaders());
    return QuizSession.fromJson(_decodeMap(r, 'startSession'));
  }

  /// Siguiente pregunta de una categoría (no repetida, sin respuesta).
  Future<QuizQuestion> nextQuestion(
      String sessionId, String categorySlug) async {
    final uri = Uri.parse(
        '${_base}quiz/sessions/$sessionId/next-question?category=$categorySlug');
    final r = await _client.get(uri, headers: await _authHeaders());
    if (r.statusCode == 404) {
      throw QuizNoQuestionsLeft(categorySlug);
    }
    return QuizQuestion.fromJson(_decodeMap(r, 'nextQuestion'));
  }

  /// Envía la respuesta; el servidor valida y puntúa.
  Future<QuizAnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required int? selectedIndex,
    required int timeMs,
    required int secondsLeft,
  }) async {
    final r = await _client.post(
      Uri.parse('${_base}quiz/sessions/$sessionId/answer'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'timeMs': timeMs,
        'secondsLeft': secondsLeft,
      }),
    );
    return QuizAnswerResult.fromJson(_decodeMap(r, 'submitAnswer'));
  }

  /// Abandona la partida activa (al salir del juego sin terminar).
  Future<void> abandon(String sessionId) async {
    await _client.post(
      Uri.parse('${_base}quiz/sessions/$sessionId/abandon'),
      headers: await _authHeaders(),
    );
  }
}

class QuizException implements Exception {
  final String message;
  QuizException(this.message);
  @override
  String toString() => 'QuizException: $message';
}

/// La categoría se quedó sin preguntas no contestadas en esta partida.
class QuizNoQuestionsLeft extends QuizException {
  final String categorySlug;
  QuizNoQuestionsLeft(this.categorySlug)
      : super('Sin preguntas en $categorySlug');
}
