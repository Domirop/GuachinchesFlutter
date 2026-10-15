import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/new_home/widgets/quiz_banner.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';

QuizCategory _cat(String slug, String name, int order) => QuizCategory(
      slug: slug,
      name: name,
      island: 'Isla',
      colorHex: '#000000',
      icon: 'help',
      sortOrder: order,
    );

QuizStats _stats(
        {int played = 4,
        int won = 1,
        String rank = 'Gofio',
        QuizRankNext? next}) =>
    QuizStats(
      totalPoints: 3120,
      gamesPlayed: played,
      gamesWon: won,
      bestScore: 2480,
      bestStreak: 7,
      categoriesMastered: const [],
      rank: QuizRank(key: 'gofio', name: rank, gamesWon: won, next: next),
    );

QuizRankingEntry _entry(int pos, String name, int pts,
        {int won = 0, bool me = false}) =>
    QuizRankingEntry(
      position: pos,
      userId: 'u$pos',
      name: name,
      totalPoints: pts,
      gamesWon: won,
      tier: 1,
      tierName: 'Marea',
      isMe: me,
    );

void main() {
  group('paleta de quesitos', () {
    test('mismo orden y colores que la tarjeta del Inicio', () {
      expect(kQuizQuesitos.map((q) => q.fill).toList(), QuesitosWheel.colors);
      expect(kQuizQuesitos.map((q) => q.slug).toList(), [
        'geografia',
        'folclore',
        'historia',
        'arte_literatura',
        'ciencia_natura',
        'entretenimiento',
        'deporte',
      ]);
    });

    test('las tintas pasan AA (4,5:1) sobre tarjeta de día y de noche', () {
      double contrast(Color a, Color b) {
        final la = a.computeLuminance(), lb = b.computeLuminance();
        final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
        return (hi + 0.05) / (lo + 0.05);
      }

      for (final q in kQuizQuesitos) {
        expect(contrast(q.inkDay, const Color(0xFFFFFFFF)),
            greaterThanOrEqualTo(4.5),
            reason: '${q.slug} día');
        expect(contrast(q.inkNight, const Color(0xFF13212B)),
            greaterThanOrEqualTo(4.5),
            reason: '${q.slug} noche');
      }
    });

    test('ordena categorías del backend como la rueda; desconocidas al final',
        () {
      final cats = [
        _cat('deporte', 'Deporte', 1),
        _cat('nueva', 'Nueva', 0),
        _cat('geografia', 'Geografía', 7),
        _cat('historia', 'Historia', 3),
      ];
      expect(quizOrderCategories(cats).map((c) => c.slug).toList(),
          ['geografia', 'historia', 'deporte', 'nueva']);
    });
  });

  group('textos', () {
    test('quesitos que faltan', () {
      final cats = [
        for (final q in kQuizQuesitos) _cat(q.slug, q.name, 0),
      ];
      expect(
        quizWheelSubtitle(
            {'geografia', 'folclore', 'ciencia_natura', 'deporte'}, cats),
        'Te faltan Historia, Arte y Literatura y Entretenimiento.',
      );
      expect(
          quizWheelSubtitle(
              {for (final q in kQuizQuesitos) q.slug}..remove('historia'),
              cats),
          'Te falta Historia.');
      expect(quizWheelSubtitle({}, cats),
          'Acierta una pregunta de cada categoría.');
    });

    test('formato de números y plurales', () {
      expect(quizFormatInt(0), '0');
      expect(quizFormatInt(380), '380');
      expect(quizFormatInt(1240), '1.240');
      expect(quizFormatInt(41804), '41.804');
      expect(quizFormatInt(1234567), '1.234.567');
      expect(quizCount(1, 'pleno', 'plenos'), '1 pleno');
      expect(quizCount(3, 'pleno', 'plenos'), '3 plenos');
    });

    test('nombre de pila en tipo título', () {
      expect(quizFirstName('MARIA JOSE perez'), 'Maria');
      expect(quizFirstName('  jjose '), 'Jjose');
      expect(quizFirstName('ana-belén García'), 'Ana-Belén');
      expect(quizFirstName(''), 'Jugador');
    });

    test('rango: «Mago/a» → «Mago o Maga»', () {
      expect(quizRankName('Mago/a'), 'Mago o Maga');
      expect(quizRankName('Gofio'), 'Gofio');
      final s = _stats(
          won: 1, next: const QuizRankNext(key: 'mago', name: 'Mago/a', at: 3));
      expect(quizRankProgress(s), '2 plenos más para ser Mago o Maga');
      expect(quizRankProgress(_stats()), isNull);
    });

    test('dificultad y fecha corta', () {
      expect(quizDifficultyLabel('facil'), 'fácil');
      expect(quizDifficultyLabel('dificil'), 'difícil');
      expect(quizDifficultyLabel('media'), 'media');
      final now = DateTime(2026, 10, 14);
      expect(quizShortDate('2026-10-12T18:00:00', now: now), '12 oct');
      expect(quizShortDate('2025-09-01T18:00:00', now: now), '1 sept 2025');
      expect(quizShortDate(null, now: now), isNull);
    });

    test('vidas tras fallar', () {
      expect(quizLivesLeftText(2), 'Pierdes una vida: te quedan 2.');
      expect(quizLivesLeftText(1), 'Pierdes una vida: te queda 1.');
      expect(quizLivesLeftText(0), 'Te has quedado sin vidas.');
    });
  });

  group('arenas y conquista', () {
    test('segundos por arena: 20 · 18 · 15', () {
      expect(quizTierSeconds(1), 20);
      expect(quizTierSeconds(2), 18);
      expect(quizTierSeconds(3), 15);
      expect(quizTierMedal(1), QuizMedalKind.bronze);
      expect(quizTierMedal(2), QuizMedalKind.silver);
      expect(quizTierMedal(3), QuizMedalKind.gold);
    });

    test('pie de la tarjeta de conquista y subtítulo tras conquistar', () {
      final c = QuizConquest(
        tier: 1,
        tierName: 'Marea',
        maxTier: 3,
        conqueredIslands: const ['el_hierro'],
        islands: [
          for (final s in [
            'la_palma',
            'el_hierro',
            'la_gomera',
            'tenerife',
            'gran_canaria',
            'fuerteventura',
            'lanzarote'
          ])
            QuizIsland(slug: s, name: s),
        ],
      );
      final (a, b, d) = quizConquestFoot(c);
      expect('$a$b$d', 'Conquista 6 islas más para subir a la arena Volcán.');
      expect(b, '6 islas más');
      expect(quizConqueredSubtitle(c),
          '1 de 7 islas. Te quedan 6 para subir a la arena Volcán.');
      expect(quizLadderStatus(0, 2), 'completada');
      expect(quizLadderStatus(1, 2), 'tu arena');
      expect(quizLadderStatus(2, 2), 'siguiente');
      expect(quizLadderStatus(2, 1), 'después');
    });
  });

  group('lobby, historial y ranking', () {
    test('CTA del lobby', () {
      const active = QuizSession(
          id: 's',
          status: 'active',
          score: 0,
          lives: 3,
          streak: 0,
          bestStreak: 0,
          wedges: []);
      expect(quizLobbyCta(stats: _stats(played: 0), active: null),
          QuizLobbyCta.firstGame);
      expect(quizLobbyCta(stats: _stats(played: 0), active: active),
          QuizLobbyCta.resume);
      expect(quizLobbyCta(stats: _stats(), active: null), QuizLobbyCta.play);
    });

    test('«Tu puesto»: distancia al de arriba, o invitación a jugar', () {
      final r = [
        _entry(1, 'Maria', 41804, won: 11),
        _entry(2, 'Pedro', 37529, won: 6),
        _entry(3, 'Yo', 3120, won: 1, me: true),
      ];
      final me = quizMyPlace(r, _stats());
      expect(me.position, 3);
      expect(me.subtitle, '1 pleno · a 34.409 puntos del 2.º');
      expect(quizMyPlace(r.sublist(0, 2), _stats(played: 0)).subtitle,
          'Juega una partida y tu nombre aparecerá aquí.');
      expect(quizMyPlace(r.sublist(0, 2), _stats()).position, isNull);
    });

    test('cabecera del historial usa las stats', () {
      const h = [
        QuizSessionSummary(
            id: 'a', status: 'won', score: 2480, bestStreak: 7, wedges: []),
        QuizSessionSummary(
            id: 'b', status: 'lost', score: 380, bestStreak: 3, wedges: []),
      ];
      expect(quizHistoryHeader(h, null), '2 partidas · 1 pleno');
      expect(quizHistoryHeader(h, _stats(played: 12, won: 3)),
          '12 partidas · 3 plenos');
    });
  });
}
