import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

import 'quiz_fakes.dart';

QuizGameCubit _cubit(WidgetTester tester) =>
    BlocProvider.of<QuizGameCubit>(tester.element(find.byType(Scaffold).first));

Future<void> _tapId(WidgetTester tester, String id) async {
  final f = find.bySemanticsIdentifier(id);
  expect(f, findsOneWidget, reason: id);
  await tester.ensureVisible(f);
  await tester.tap(f);
}

/// Del lobby a la pregunta: «Jugar» → «Girar» → la ruleta para.
Future<void> _toQuestion(WidgetTester tester) async {
  await _tapId(tester, 'quiz-lobby-play-button');
  await tester.pumpAndSettle();
  expect(find.text('Gira la ruleta'), findsOneWidget);
  await _tapId(tester, 'quiz-wheel-spin-button');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3100));
  await tester.pump(const Duration(milliseconds: 400));
  expect(_cubit(tester).state.phase, QuizPhase.question);
}

void main() {
  group('lobby', () {
    testWidgets('listo con partida en curso: Nueva + Continuar partida',
        (tester) async {
      final repo = FakeQuizRepository()
        ..active = quizSession(score: 1240, lives: 2, wedges: [
          'geografia',
          'ciencia_natura',
          'deporte',
        ]);
      final audio = FakeQuizAudio();
      await pumpQuiz(tester, repo, audio: audio);

      expect(find.text('¿Cuánto sabes de Canarias?'), findsOneWidget);
      expect(find.text('Conquista Canarias'), findsOneWidget);
      expect(find.text('Arena Marea'), findsOneWidget);
      expect(find.text('1 de 7 islas'), findsOneWidget);
      expect(find.text('Continuar partida'), findsOneWidget);
      expect(find.text('Nueva'), findsOneWidget);
      expect(find.text('3 de 7 quesitos'), findsOneWidget);
      expect(find.text('2 plenos más para ser Mago o Maga'), findsOneWidget);
      // Sin intro forzada; el pito se pide (la bandera decide si suena).
      expect(audio.introCalls, 1);
    });

    testWidgets('primera vez: «Jugar mi primera partida» y bienvenida',
        (tester) async {
      final repo = FakeQuizRepository()..gamesPlayed = 0;
      await pumpQuiz(tester, repo);
      expect(find.text('Jugar mi primera partida'), findsOneWidget);
      expect(find.text('¡Bienvenido al reto!'), findsOneWidget);
      expect(find.text('Nueva'), findsNothing);
    });

    testWidgets('fallo del lobby → error + Reintentar (sin barra Jugar)',
        (tester) async {
      final repo = FakeQuizRepository()..failConquest = true;
      await pumpQuiz(tester, repo);
      expect(find.text('No pudimos cargar el juego'), findsOneWidget);
      expect(
          find.bySemanticsIdentifier('quiz-lobby-play-button'), findsNothing);
      repo.failConquest = false;
      await _tapId(tester, 'quiz-lobby-retry-button');
      await tester.pumpAndSettle();
      expect(find.text('No pudimos cargar el juego'), findsNothing);
      expect(find.text('Jugar'), findsOneWidget);
    });

    testWidgets(
        'historial que falla muestra error + Reintentar, no «Aún no has jugado»',
        (tester) async {
      final repo = FakeQuizRepository()..failHistory = true;
      await pumpQuiz(tester, repo);
      await _tapId(tester, 'quiz-lobby-tab-historial');
      await tester.pumpAndSettle();
      expect(find.text('No pudimos cargar tus partidas'), findsOneWidget);
      expect(find.text('Aún no has jugado'), findsNothing);

      repo.failHistory = false;
      await _tapId(tester, 'quiz-history-retry-button');
      await tester.pumpAndSettle();
      expect(find.text('Pleno'), findsOneWidget);
      expect(find.text('12 oct · mejor racha 7'), findsOneWidget);
    });

    testWidgets('historial vacío de verdad → «Aún no has jugado»',
        (tester) async {
      final repo = FakeQuizRepository()..history = const [];
      await pumpQuiz(tester, repo);
      await _tapId(tester, 'quiz-lobby-tab-historial');
      await tester.pumpAndSettle();
      expect(find.text('Aún no has jugado'), findsOneWidget);
    });

    testWidgets(
        'ranking: error + Reintentar; luego nombre de pila y «Tu puesto»',
        (tester) async {
      final repo = FakeQuizRepository()..failRanking = true;
      await pumpQuiz(tester, repo);
      await _tapId(tester, 'quiz-lobby-tab-ranking');
      await tester.pumpAndSettle();
      expect(find.text('No pudimos cargar el ranking'), findsOneWidget);

      repo.failRanking = false;
      await _tapId(tester, 'quiz-ranking-retry-button');
      await tester.pumpAndSettle();
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('MARIA perez'), findsNothing);
      expect(find.text('Tu puesto'), findsOneWidget);
      expect(find.text('Sigue sumando puntos y tu nombre aparecerá aquí.'),
          findsOneWidget);
    });

    testWidgets('«Nueva» con partida en curso pide confirmación',
        (tester) async {
      final repo = FakeQuizRepository()
        ..active = quizSession(id: 'old', wedges: ['geografia']);
      await pumpQuiz(tester, repo);
      await _tapId(tester, 'quiz-lobby-new-button');
      await tester.pumpAndSettle();
      expect(find.text('¿Empezar una partida nueva?'), findsOneWidget);
      expect(repo.startCalls, 0);

      await _tapId(tester, 'quiz-new-confirm-button');
      await tester.pumpAndSettle();
      expect(repo.abandoned, ['old']);
      expect(repo.startCalls, 1);
      expect(find.text('Gira la ruleta'), findsOneWidget);
    });
  });

  group('partida', () {
    testWidgets('la ruleta no gira sola: espera a «Girar»', (tester) async {
      final repo = FakeQuizRepository();
      await pumpQuiz(tester, repo);
      await _tapId(tester, 'quiz-lobby-play-button');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(_cubit(tester).state.phase, QuizPhase.spinning);
      expect(find.text('Gira la ruleta'), findsOneWidget);
    });

    testWidgets('acierto: «¡Correcto!» y no avanza solo; «Siguiente» sí',
        (tester) async {
      final repo = FakeQuizRepository();
      final audio = FakeQuizAudio();
      await pumpQuiz(tester, repo, audio: audio);
      await _toQuestion(tester);

      await _tapId(tester, 'quiz-question-option-1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('¡Correcto!'), findsOneWidget);
      expect(find.text('+420 puntos'), findsOneWidget);
      expect(audio.correctCalls, 1);

      await tester.pump(const Duration(seconds: 6));
      expect(_cubit(tester).state.phase, QuizPhase.revealing);

      await _tapId(tester, 'quiz-reveal-next-button');
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.phase, QuizPhase.spinning);
    });

    testWidgets('sin tiempo: «Se acabó el tiempo»', (tester) async {
      final repo = FakeQuizRepository();
      await pumpQuiz(tester, repo);
      await _toQuestion(tester);
      expect(_cubit(tester).state.secondsTotal, 20);

      for (var i = 0; i < 21; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Se acabó el tiempo'), findsOneWidget);
      expect(find.text('La correcta era Uno.'), findsOneWidget);
      expect(find.text('Pierdes una vida: te quedan 2.'), findsOneWidget);
    });

    testWidgets('fallo: «Casi, pero no»', (tester) async {
      final repo = FakeQuizRepository()
        ..onAnswer = (slug, sel) => QuizAnswerResult(
              isCorrect: false,
              correctIndex: 0,
              points: 0,
              newWedge: false,
              session: quizSession(lives: 1),
            );
      await pumpQuiz(tester, repo);
      await _toQuestion(tester);
      await _tapId(tester, 'quiz-question-option-2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Casi, pero no'), findsOneWidget);
      expect(find.text('Pierdes una vida: te queda 1.'), findsOneWidget);
    });

    testWidgets('«¿Salir de la partida?» para el reloj mientras está abierta',
        (tester) async {
      final repo = FakeQuizRepository();
      await pumpQuiz(tester, repo);
      await _toQuestion(tester);
      await tester.pump(const Duration(seconds: 2));
      final before = _cubit(tester).state.secondsLeft;

      await _tapId(tester, 'quiz-hud-exit-button');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      expect(find.text('El reloj se para mientras decides'), findsOneWidget);
      expect(_cubit(tester).state.paused, isTrue);

      await tester.pump(const Duration(seconds: 6));
      expect(_cubit(tester).state.secondsLeft, before);

      await _tapId(tester, 'quiz-exit-continue-button');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_cubit(tester).state.paused, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(_cubit(tester).state.secondsLeft, lessThan(before));
    });

    testWidgets('«Salir y continuar luego» vuelve al lobby sin abandonar',
        (tester) async {
      final repo = FakeQuizRepository();
      await pumpQuiz(tester, repo);
      await _toQuestion(tester);
      await _tapId(tester, 'quiz-hud-exit-button');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _tapId(tester, 'quiz-exit-leave-button');
      await tester.pumpAndSettle();
      expect(repo.abandoned, isEmpty);
      expect(find.text('Conquista Canarias'), findsOneWidget);
    });
  });

  group('resultado', () {
    testWidgets('derrota con los quesitos que faltan', (tester) async {
      final repo = FakeQuizRepository()
        ..onAnswer = (slug, sel) => QuizAnswerResult(
              isCorrect: false,
              correctIndex: 0,
              points: 0,
              newWedge: false,
              session: quizSession(
                  status: 'lost',
                  lives: 0,
                  score: 1660,
                  bestStreak: 5,
                  wedges: const [
                    'geografia',
                    'folclore',
                    'ciencia_natura',
                    'deporte'
                  ]),
            );
      await pumpQuiz(tester, repo);
      await _toQuestion(tester);
      await _tapId(tester, 'quiz-question-option-3');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await _tapId(tester, 'quiz-reveal-next-button');
      await tester.pumpAndSettle();
      expect(find.text('Fin de la partida'), findsOneWidget);
      expect(find.text('Te quedaste sin vidas. A la próxima, la isla es tuya.'),
          findsOneWidget);
      expect(
          find.text(
              'Te faltaron Historia, Arte y Literatura y Entretenimiento.'),
          findsOneWidget);
      expect(find.text('1.660'), findsOneWidget);
    });

    testWidgets('pleno: elegir isla con chips de 44 y conquistar',
        (tester) async {
      final repo = FakeQuizRepository()
        ..onAnswer = (slug, sel) => QuizAnswerResult(
              isCorrect: true,
              correctIndex: sel ?? 0,
              points: 350,
              newWedge: true,
              session: quizSession(
                  status: 'won',
                  score: 2480,
                  bestStreak: 7,
                  wedges: const [
                    'geografia',
                    'folclore',
                    'historia',
                    'arte_literatura',
                    'ciencia_natura',
                    'entretenimiento',
                    'deporte'
                  ]),
            );
      await pumpQuiz(tester, repo);
      await _toQuestion(tester);
      await _tapId(tester, 'quiz-question-option-0');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await _tapId(tester, 'quiz-reveal-next-button');
      await tester.pumpAndSettle();

      expect(find.text('¡Pleno!'), findsOneWidget);
      expect(find.text('Elige la isla que quieres conquistar'), findsOneWidget);
      expect(find.text('Elige una isla'), findsOneWidget);
      // El Hierro ya está conquistada: no sale como chip.
      expect(find.bySemanticsIdentifier('quiz-result-island-el_hierro'),
          findsNothing);
      final chip = find.bySemanticsIdentifier('quiz-result-island-tenerife');
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
      await _tapId(tester, 'quiz-result-island-tenerife');
      await tester.pumpAndSettle();
      expect(find.text('Conquistar Tenerife'), findsOneWidget);
    });
  });
}
