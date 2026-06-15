import 'package:flutter/material.dart';

/// Modelos del juego "¿Cuánto sabes de Canarias?" (contrato REST del backend
/// NestJS `/quiz/*`). El cliente NUNCA recibe `correctIndex` en la pregunta;
/// solo llega en [QuizAnswerResult] tras contestar.

Color _hex(String? s) {
  if (s == null || s.isEmpty) return const Color(0xFF0085C4);
  var h = s.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF0085C4);
}

/// Una de las 7 categorías = quesito = isla.
class QuizCategory {
  final String slug;
  final String name;
  final String island;
  final String colorHex;
  final String icon;
  final int sortOrder;

  const QuizCategory({
    required this.slug,
    required this.name,
    required this.island,
    required this.colorHex,
    required this.icon,
    required this.sortOrder,
  });

  Color get color => _hex(colorHex);

  factory QuizCategory.fromJson(Map<String, dynamic> j) => QuizCategory(
        slug: j['slug']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        island: j['island']?.toString() ?? '',
        colorHex: j['color']?.toString() ?? '#0085C4',
        icon: j['icon']?.toString() ?? 'help',
        sortOrder: (j['sortOrder'] is num)
            ? (j['sortOrder'] as num).toInt()
            : int.tryParse('${j['sortOrder']}') ?? 0,
      );
}

/// Pregunta servida SIN la respuesta correcta.
class QuizQuestion {
  final String id;
  final String difficulty; // facil | media | dificil
  final String question;
  final List<String> options; // siempre 4
  final String categorySlug;
  final String categoryName;
  final String island;
  final String colorHex;
  final String icon;

  const QuizQuestion({
    required this.id,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.categorySlug,
    required this.categoryName,
    required this.island,
    required this.colorHex,
    required this.icon,
  });

  Color get color => _hex(colorHex);

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id']?.toString() ?? '',
        difficulty: j['difficulty']?.toString() ?? 'media',
        question: j['question']?.toString() ?? '',
        options: (j['options'] is List)
            ? (j['options'] as List).map((e) => e.toString()).toList()
            : const [],
        categorySlug: j['categorySlug']?.toString() ?? '',
        categoryName: j['categoryName']?.toString() ?? '',
        island: j['island']?.toString() ?? '',
        colorHex: j['color']?.toString() ?? '#0085C4',
        icon: j['icon']?.toString() ?? 'help',
      );
}

/// Estado de la partida (lo que devuelve el servidor).
class QuizSession {
  final String id;
  final String status; // active | won | lost | abandoned
  final int score;
  final int lives;
  final int streak;
  final int bestStreak;
  final List<String> wedges; // slugs de quesitos conseguidos

  const QuizSession({
    required this.id,
    required this.status,
    required this.score,
    required this.lives,
    required this.streak,
    required this.bestStreak,
    required this.wedges,
  });

  bool get isActive => status == 'active';
  bool get isWon => status == 'won';
  bool get isLost => status == 'lost';

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;

  factory QuizSession.fromJson(Map<String, dynamic> j) => QuizSession(
        id: j['id']?.toString() ?? '',
        status: j['status']?.toString() ?? 'active',
        score: _int(j['score']),
        lives: _int(j['lives']),
        streak: _int(j['streak']),
        bestStreak: _int(j['bestStreak']),
        wedges: (j['wedges'] is List)
            ? (j['wedges'] as List).map((e) => e.toString()).toList()
            : const [],
      );
}

/// Respuesta del servidor tras contestar (única vía por la que llega
/// `correctIndex`).
class QuizAnswerResult {
  final bool isCorrect;
  final int correctIndex;
  final String? explanation;
  final int points;
  final bool newWedge;
  final QuizSession session;

  const QuizAnswerResult({
    required this.isCorrect,
    required this.correctIndex,
    this.explanation,
    required this.points,
    required this.newWedge,
    required this.session,
  });

  factory QuizAnswerResult.fromJson(Map<String, dynamic> j) => QuizAnswerResult(
        isCorrect: j['isCorrect'] == true,
        correctIndex: QuizSession._int(j['correctIndex']),
        explanation: j['explanation']?.toString(),
        points: QuizSession._int(j['points']),
        newWedge: j['newWedge'] == true,
        session: QuizSession.fromJson(
            (j['session'] as Map).cast<String, dynamic>()),
      );
}

/// Siguiente grado al que se asciende (null si ya es el máximo).
class QuizRankNext {
  final String key;
  final String name;
  final int at; // partidas ganadas necesarias
  const QuizRankNext({required this.key, required this.name, required this.at});

  factory QuizRankNext.fromJson(Map<String, dynamic> j) => QuizRankNext(
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        at: QuizSession._int(j['at']),
      );
}

/// Rango permanente del jugador (Gofio → Mago/a → Guanche).
class QuizRank {
  final String key;
  final String name;
  final int gamesWon;
  final QuizRankNext? next;
  const QuizRank({
    required this.key,
    required this.name,
    required this.gamesWon,
    this.next,
  });

  factory QuizRank.fromJson(Map<String, dynamic> j) => QuizRank(
        key: j['key']?.toString() ?? 'gofio',
        name: j['name']?.toString() ?? 'Gofio',
        gamesWon: QuizSession._int(j['gamesWon']),
        next: j['next'] is Map
            ? QuizRankNext.fromJson((j['next'] as Map).cast<String, dynamic>())
            : null,
      );
}

/// Stats acumuladas del jugador + su rango.
class QuizStats {
  final int totalPoints;
  final int gamesPlayed;
  final int gamesWon;
  final int bestScore;
  final int bestStreak;
  final List<String> categoriesMastered;
  final QuizRank rank;

  const QuizStats({
    required this.totalPoints,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.bestScore,
    required this.bestStreak,
    required this.categoriesMastered,
    required this.rank,
  });

  factory QuizStats.fromJson(Map<String, dynamic> j) => QuizStats(
        totalPoints: QuizSession._int(j['totalPoints']),
        gamesPlayed: QuizSession._int(j['gamesPlayed']),
        gamesWon: QuizSession._int(j['gamesWon']),
        bestScore: QuizSession._int(j['bestScore']),
        bestStreak: QuizSession._int(j['bestStreak']),
        categoriesMastered: (j['categoriesMastered'] is List)
            ? (j['categoriesMastered'] as List)
                .map((e) => e.toString())
                .toList()
            : const [],
        rank: QuizRank.fromJson(
            (j['rank'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}
