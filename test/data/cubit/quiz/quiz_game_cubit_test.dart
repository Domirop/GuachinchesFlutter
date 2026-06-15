import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';

/// Repo falso: sin red. `submitAnswer` se programa con [nextResult].
class _FakeQuizRepository extends QuizRepository {
  _FakeQuizRepository() : super(_DummyClient());

  QuizAnswerResult Function(int? selected)? nextResult;
  int answerCalls = 0;

  static final _cats = List.generate(
    7,
    (i) => QuizCategory(
      slug: 'cat$i',
      name: 'Cat $i',
      island: 'Isla $i',
      colorHex: '#0085C4',
      icon: 'help',
      sortOrder: i,
    ),
  );

  @override
  Future<List<QuizCategory>> getCategories() async => _cats;

  @override
  Future<QuizStats> getStats() async => const QuizStats(
        totalPoints: 0,
        gamesPlayed: 0,
        gamesWon: 0,
        bestScore: 0,
        bestStreak: 0,
        categoriesMastered: [],
        rank: QuizRank(key: 'gofio', name: 'Gofio', gamesWon: 0),
      );

  @override
  Future<QuizSession> startSession() async => const QuizSession(
        id: 's1',
        status: 'active',
        score: 0,
        lives: 3,
        streak: 0,
        bestStreak: 0,
        wedges: [],
      );

  @override
  Future<QuizQuestion> nextQuestion(String sessionId, String slug) async =>
      QuizQuestion(
        id: 'q-$slug',
        difficulty: 'facil',
        question: '¿Pregunta de $slug?',
        options: const ['A', 'B', 'C', 'D'],
        categorySlug: slug,
        categoryName: 'Cat',
        island: 'Isla',
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
    answerCalls++;
    return nextResult!(selectedIndex);
  }

  @override
  Future<void> abandon(String sessionId) async {}
}

class _DummyClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

QuizSession _session({
  String status = 'active',
  int score = 0,
  int lives = 3,
  int streak = 0,
  int bestStreak = 0,
  List<String> wedges = const [],
}) =>
    QuizSession(
      id: 's1',
      status: status,
      score: score,
      lives: lives,
      streak: streak,
      bestStreak: bestStreak,
      wedges: wedges,
    );

void main() {
  late _FakeQuizRepository repo;
  late QuizGameCubit cubit;

  setUp(() {
    repo = _FakeQuizRepository();
    cubit = QuizGameCubit(repo);
  });

  tearDown(() => cubit.close());

  test('startGame → spinning con sesión y 7 categorías', () async {
    await cubit.startGame();
    expect(cubit.state.phase, QuizPhase.spinning);
    expect(cubit.state.categories.length, 7);
    expect(cubit.state.session?.lives, 3);
  });

  test('spin precarga categoría + pregunta; onSpinSettled abre la pregunta',
      () async {
    await cubit.startGame();
    await cubit.spin();
    expect(cubit.state.landed, isNotNull);
    expect(cubit.state.question, isNotNull);
    expect(cubit.state.phase, QuizPhase.spinning); // aún girando

    cubit.onSpinSettled();
    expect(cubit.state.phase, QuizPhase.question);
    expect(cubit.state.secondsLeft, QuizGameCubit.questionSeconds);
  });

  test('acierto: revealing con puntos y quesito; continuar vuelve a girar',
      () async {
    await cubit.startGame();
    await cubit.spin();
    cubit.onSpinSettled();
    final slug = cubit.state.landed!.slug;

    repo.nextResult = (sel) => QuizAnswerResult(
          isCorrect: true,
          correctIndex: sel ?? 0,
          points: 150,
          newWedge: true,
          session: _session(score: 400, streak: 1, wedges: [slug]),
        );
    await cubit.answer(0);
    expect(cubit.state.phase, QuizPhase.revealing);
    expect(cubit.state.result?.isCorrect, true);
    expect(cubit.state.score, 400);
    expect(cubit.state.wedges, [slug]);

    cubit.continueAfterReveal();
    expect(cubit.state.phase, QuizPhase.spinning);
    expect(cubit.state.question, isNull); // limpiada para el siguiente turno
  });

  test('fallo con última vida → lost', () async {
    await cubit.startGame();
    await cubit.spin();
    cubit.onSpinSettled();

    repo.nextResult = (sel) => QuizAnswerResult(
          isCorrect: false,
          correctIndex: 2,
          points: 0,
          newWedge: false,
          session: _session(status: 'lost', lives: 0, streak: 0),
        );
    await cubit.answer(0);
    cubit.continueAfterReveal();
    expect(cubit.state.phase, QuizPhase.lost);
  });

  test('séptimo quesito → won', () async {
    await cubit.startGame();
    await cubit.spin();
    cubit.onSpinSettled();

    repo.nextResult = (sel) => QuizAnswerResult(
          isCorrect: true,
          correctIndex: sel ?? 0,
          points: 350,
          newWedge: true,
          session: _session(
            status: 'won',
            score: 2500,
            wedges: ['cat0', 'cat1', 'cat2', 'cat3', 'cat4', 'cat5', 'cat6'],
          ),
        );
    await cubit.answer(0);
    cubit.continueAfterReveal();
    expect(cubit.state.phase, QuizPhase.won);
  });
}
