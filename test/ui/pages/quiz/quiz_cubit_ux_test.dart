import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

import 'quiz_fakes.dart';

/// Arreglos de UX que tocan el cubit (añadidos, sin cambiar su flujo).
void main() {
  group('carga del lobby: los fallos no se tragan', () {
    test('historial que falla → historyFailed (no lista vacía muda)', () async {
      final repo = FakeQuizRepository()..failHistory = true;
      final c = QuizGameCubit(repo);
      await c.loadLobby();
      expect(c.state.historyFailed, isTrue);
      expect(c.state.lobbyFailed, isFalse);

      repo.failHistory = false;
      await c.loadHistory();
      expect(c.state.historyFailed, isFalse);
      expect(c.state.history, isNotEmpty);
      await c.close();
    });

    test('categorías, stats o conquista que fallan → lobbyFailed', () async {
      for (final setup in <void Function(FakeQuizRepository)>[
        (r) => r.failCategories = true,
        (r) => r.failStats = true,
        (r) => r.failConquest = true,
      ]) {
        final repo = FakeQuizRepository();
        setup(repo);
        final c = QuizGameCubit(repo);
        await c.loadLobby();
        expect(c.state.lobbyFailed, isTrue);
        expect(c.state.phase, QuizPhase.idle);
        await c.close();
      }
    });

    test('ranking: rankingFailed y rankingLoaded', () async {
      final repo = FakeQuizRepository()..failRanking = true;
      final c = QuizGameCubit(repo);
      await c.loadRanking();
      expect(c.state.rankingFailed, isTrue);
      expect(c.state.rankingLoaded, isFalse);
      repo.failRanking = false;
      await c.loadRanking();
      expect(c.state.rankingFailed, isFalse);
      expect(c.state.rankingLoaded, isTrue);
      await c.close();
    });
  });

  group('partida', () {
    testWidgets('pauseTimer congela el reloj y bloquea responder',
        (tester) async {
      final repo = FakeQuizRepository();
      final c = QuizGameCubit(repo);
      await c.startGame();
      await c.spin();
      c.onSpinSettled();
      await tester.pump(const Duration(seconds: 3));
      expect(c.state.secondsLeft, 17);

      c.pauseTimer();
      expect(c.state.paused, isTrue);
      await tester.pump(const Duration(seconds: 10));
      expect(c.state.secondsLeft, 17);
      await c.answer(0);
      expect(c.state.phase, QuizPhase.question); // no responde en pausa

      c.resumeTimer();
      expect(c.state.paused, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(c.state.secondsLeft, 15);

      await c.answer(1);
      expect(repo.answerTimes, hasLength(1));
      await c.close();
      await tester.pumpWidget(const SizedBox());
    });

    test('startNewGame abandona la activa y empieza otra', () async {
      final repo = FakeQuizRepository()..active = quizSession(id: 'old');
      final c = QuizGameCubit(repo);
      await c.loadLobby();
      await c.startNewGame();
      expect(repo.abandoned, ['old']);
      expect(c.state.phase, QuizPhase.spinning);
      expect(c.state.session?.id, 'new1');
      await c.close();
    });

    test('una partida nueva no arrastra la conquista anterior', () async {
      final repo = FakeQuizRepository()
        ..onAnswer = (slug, sel) => QuizAnswerResult(
              isCorrect: true,
              correctIndex: sel ?? 0,
              points: 100,
              newWedge: true,
              session: quizSession(status: 'won', wedges: [slug]),
            );
      final c = QuizGameCubit(repo);
      await c.loadLobby();
      await c.startGame();
      await c.spin();
      c.onSpinSettled();
      await c.answer(0);
      c.continueAfterReveal();
      expect(c.state.phase, QuizPhase.won);
      // Simula una conquista ya resuelta.
      c.emit(c.state.copyWith(
          conquerResult: QuizConquerResult(
              island: 'tenerife',
              promoted: false,
              conquest: c.state.conquest!)));
      await c.restart();
      expect(c.state.conquerResult, isNull);
      await c.close();
    });
  });
}
