import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';
import 'package:guachinches/ui/pages/quiz/quiz_game_screen.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/pages/quiz/quiz_sound.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_island_map.dart';
import 'package:http/http.dart' as http;

class _NoClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

const kIslands = [
  'la_palma',
  'el_hierro',
  'la_gomera',
  'tenerife',
  'gran_canaria',
  'fuerteventura',
  'lanzarote',
];

QuizSession quizSession({
  String id = 's1',
  String status = 'active',
  int score = 0,
  int lives = 3,
  int streak = 0,
  int bestStreak = 0,
  List<String> wedges = const [],
}) =>
    QuizSession(
      id: id,
      status: status,
      score: score,
      lives: lives,
      streak: streak,
      bestStreak: bestStreak,
      wedges: wedges,
    );

/// Repositorio en memoria del juego. Cada llamada puede fallar a demanda.
class FakeQuizRepository extends QuizRepository {
  FakeQuizRepository() : super(_NoClient());

  bool failCategories = false;
  bool failStats = false;
  bool failHistory = false;
  bool failRanking = false;
  bool failConquest = false;

  int gamesPlayed = 4;
  QuizSession? active;
  List<QuizSessionSummary> history = const [
    QuizSessionSummary(
        id: 'h1',
        status: 'won',
        score: 2480,
        bestStreak: 7,
        wedges: [],
        endedAt: '2026-10-12T18:00:00'),
  ];
  List<QuizRankingEntry> ranking = const [
    QuizRankingEntry(
        position: 1,
        userId: 'a',
        name: 'MARIA perez',
        totalPoints: 41804,
        gamesWon: 11,
        tier: 1,
        tierName: 'Marea',
        isMe: false),
  ];

  /// Resultado de responder (por defecto: acierto con quesito).
  QuizAnswerResult Function(String slug, int? selected)? onAnswer;

  final List<String> abandoned = [];
  int startCalls = 0;
  int historyCalls = 0;
  int rankingCalls = 0;
  final List<int> answerTimes = [];

  @override
  Future<String?> currentUserId() async => 'me';

  @override
  Future<List<QuizCategory>> getCategories() async {
    if (failCategories) throw QuizException('categories');
    return [
      for (var i = 0; i < kQuizQuesitos.length; i++)
        QuizCategory(
          slug: kQuizQuesitos[i].slug,
          name: kQuizQuesitos[i].name,
          island: 'Tenerife',
          colorHex: '#0085C4',
          icon: 'help',
          sortOrder: i,
        ),
    ];
  }

  @override
  Future<QuizStats> getStats() async {
    if (failStats) throw QuizException('stats');
    return QuizStats(
      totalPoints: 3120,
      gamesPlayed: gamesPlayed,
      gamesWon: 1,
      bestScore: 2480,
      bestStreak: 7,
      categoriesMastered: const [],
      rank: const QuizRank(
          key: 'gofio',
          name: 'Gofio',
          gamesWon: 1,
          next: QuizRankNext(key: 'mago', name: 'Mago/a', at: 3)),
    );
  }

  @override
  Future<QuizSession?> getActiveSession() async => active;

  @override
  Future<List<QuizSessionSummary>> getMySessions({int limit = 10}) async {
    historyCalls++;
    if (failHistory) throw QuizException('history');
    return history;
  }

  @override
  Future<List<QuizRankingEntry>> getRanking({int limit = 50}) async {
    rankingCalls++;
    if (failRanking) throw QuizException('ranking');
    return ranking;
  }

  @override
  Future<QuizConquest> getConquest() async {
    if (failConquest) throw QuizException('conquest');
    return QuizConquest(
      tier: 1,
      tierName: 'Marea',
      maxTier: 3,
      conqueredIslands: const ['el_hierro'],
      islands: [
        for (final s in kIslands) QuizIsland(slug: s, name: quizIslandName(s))
      ],
    );
  }

  @override
  Future<QuizSession> startSession() async {
    startCalls++;
    return quizSession(id: 'new$startCalls');
  }

  @override
  Future<QuizQuestion> nextQuestion(String sessionId, String slug) async =>
      QuizQuestion(
        id: 'q-$slug',
        difficulty: 'media',
        question: '¿Pregunta de $slug?',
        options: const ['Uno', 'Dos', 'Tres', 'Cuatro'],
        categorySlug: slug,
        categoryName: '',
        island: 'Tenerife',
        colorHex: '#0085C4',
        icon: 'help',
      );

  @override
  Future<QuizAnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required int? selectedIndex,
    required int timeMs,
    required int secondsLeft,
  }) async {
    answerTimes.add(timeMs);
    final slug = questionId.substring(2);
    final f = onAnswer ??
        (slug, sel) => QuizAnswerResult(
              isCorrect: sel != null,
              correctIndex: 0,
              explanation: 'Porque sí.',
              points: sel != null ? 420 : 0,
              newWedge: sel != null,
              session: quizSession(
                id: sessionId,
                score: sel != null ? 420 : 0,
                lives: sel != null ? 3 : 2,
                wedges: sel != null ? [slug] : const [],
              ),
            );
    return f(slug, selectedIndex);
  }

  @override
  Future<void> abandon(String sessionId) async => abandoned.add(sessionId);

  /// Conquista: por defecto suma la isla en Marea; [promote] sube a Volcán.
  bool promote = false;

  @override
  Future<QuizConquerResult> conquerIsland(
      String sessionId, String islandSlug) async {
    final base = await getConquest();
    final c = promote
        ? QuizConquest(
            tier: 2,
            tierName: 'Volcán',
            maxTier: 3,
            conqueredIslands: const [],
            islands: base.islands)
        : QuizConquest(
            tier: 1,
            tierName: 'Marea',
            maxTier: 3,
            conqueredIslands: [...base.conqueredIslands, islandSlug],
            islands: base.islands);
    return QuizConquerResult(
        island: islandSlug, promoted: promote, conquest: c);
  }
}

class FakeQuizAudio implements QuizAudio {
  int correctCalls = 0;
  int failCalls = 0;
  int introCalls = 0;

  @override
  Future<void> correct() async => correctCalls++;

  @override
  Future<void> fail() async => failCalls++;

  @override
  Future<void> introIfFirstTime() async => introCalls++;

  @override
  void dispose() {}
}

/// Monta el juego en un iPhone de 402 × 874.
Future<void> pumpQuiz(
  WidgetTester tester,
  FakeQuizRepository repo, {
  FakeQuizAudio? audio,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: QuizGameScreen(repository: repo, audio: audio ?? FakeQuizAudio()),
  ));
  await tester.pumpAndSettle();
}
