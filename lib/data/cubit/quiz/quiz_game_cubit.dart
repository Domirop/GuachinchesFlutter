import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';

/// Orquesta una partida del "Reto de los 7 Quesitos". La validación de aciertos
/// y el cálculo de puntos viven en el servidor (anti-trampa); este cubit maneja
/// el flujo: girar la ruleta → pedir pregunta → temporizador 20 s → enviar
/// respuesta → revelar → siguiente turno / victoria / derrota.
class QuizGameCubit extends Cubit<QuizGameState> {
  final QuizRepository _repo;
  QuizGameCubit(this._repo) : super(const QuizGameState());

  /// Segundos por pregunta (configurable). Aviso visual bajo [warningSeconds].
  static const int questionSeconds = 20;
  static const int warningSeconds = 5;

  Timer? _timer;
  DateTime? _pausedAt;
  final Random _rng = Random();
  final Set<String> _exhausted = {}; // categorías sin preguntas en la partida
  int _gamesWonBefore = 0;
  DateTime? _questionShownAt;

  /// Permutación de la pregunta actual: `_optionPerm[i]` = índice ORIGINAL de la
  /// opción que se muestra en la posición barajada `i`. Las opciones se barajan
  /// en el cliente (el seed las servía con la correcta siempre en A); al enviar
  /// se traduce a índice original y al revelar se mapea de vuelta a la barajada.
  List<int>? _optionPerm;

  /// Devuelve una copia de [q] con las opciones barajadas + la permutación
  /// (barajada→original).
  (QuizQuestion, List<int>) _shuffleQuestion(QuizQuestion q) {
    final perm = List<int>.generate(q.options.length, (i) => i)..shuffle(_rng);
    final shuffled = QuizQuestion(
      id: q.id,
      difficulty: q.difficulty,
      question: q.question,
      options: [for (final i in perm) q.options[i]],
      categorySlug: q.categorySlug,
      categoryName: q.categoryName,
      island: q.island,
      colorHex: q.colorHex,
      icon: q.icon,
    );
    return (shuffled, perm);
  }

  /// Traduce el `correctIndex` (orden original) del servidor a la posición
  /// barajada que ve el usuario, para que el reveal ilumine bien.
  QuizAnswerResult _mapResultToShuffled(QuizAnswerResult res, List<int>? perm) {
    if (perm == null) return res;
    final shownCorrect = perm.indexOf(res.correctIndex);
    return QuizAnswerResult(
      isCorrect: res.isCorrect,
      correctIndex: shownCorrect < 0 ? res.correctIndex : shownCorrect,
      explanation: res.explanation,
      points: res.points,
      newWedge: res.newWedge,
      session: res.session,
    );
  }

  // ── Lobby ───────────────────────────────────────────────────────────────────

  /// Carga categorías + stats para el lobby. No inicia partida (sigue en idle).
  /// Los fallos no se tragan: se registran y se marcan en el estado
  /// ([QuizGameState.lobbyFailed] / [QuizGameState.historyFailed]) para que la
  /// UI pinte error + «Reintentar» en vez de datos vacíos que mienten.
  Future<void> loadLobby() async {
    if (state.phase == QuizPhase.idle &&
        (state.categories.isEmpty || state.lobbyFailed)) {
      emit(state.copyWith(phase: QuizPhase.loading, clearError: true));
    }
    List<QuizCategory>? cats;
    QuizStats? stats;
    QuizSession? active;
    List<QuizSessionSummary>? history;
    QuizConquest? conquest;
    var lobbyFailed = false;
    var historyFailed = false;
    Future<void> guard(String what, Future<void> Function() f,
        {bool history = false}) async {
      try {
        await f();
      } catch (e, st) {
        AppLogger.error('quiz-lobby', 'load $what: $e', st);
        if (history) {
          historyFailed = true;
        } else {
          lobbyFailed = true;
        }
      }
    }

    await Future.wait([
      guard('categories', () async => cats = await _repo.getCategories()),
      guard('stats', () async => stats = await _repo.getStats()),
      guard('active', () async => active = await _repo.getActiveSession()),
      guard('history', () async => history = await _repo.getMySessions(),
          history: true),
      guard('conquest', () async => conquest = await _repo.getConquest()),
    ]);
    emit(state.copyWith(
      phase: QuizPhase.idle,
      categories: cats ?? state.categories,
      stats: stats ?? state.stats,
      conquest: conquest ?? state.conquest,
      activeSession: active,
      clearActiveSession: active == null,
      history: history ?? state.history,
      lobbyFailed: lobbyFailed,
      historyFailed: historyFailed,
    ));
  }

  /// Reintenta solo el historial (pestaña Historial con error).
  Future<void> loadHistory() async {
    emit(state.copyWith(historyFailed: false, phase: QuizPhase.loading));
    try {
      final h = await _repo.getMySessions();
      emit(state.copyWith(phase: QuizPhase.idle, history: h));
    } catch (e, st) {
      AppLogger.error('quiz-lobby', 'load history: $e', st);
      emit(state.copyWith(phase: QuizPhase.idle, historyFailed: true));
    }
  }

  /// Segundos por pregunta de un tier (arena): Marea 20 · Volcán 18 ·
  /// Leyenda 15. Tiers altos = menos tiempo.
  static int secondsForTier(int tier) {
    switch (tier) {
      case 3:
        return 15;
      case 2:
        return 18;
      default:
        return questionSeconds; // 20
    }
  }

  /// Segundos por pregunta según el tier (arena) actual.
  int _secondsForTier() => secondsForTier(state.conquest?.tier ?? 1);

  /// Reclama la conquista de una isla tras GANAR. Actualiza el mapa y marca si
  /// hubo ascenso de tier.
  Future<void> conquer(String islandSlug) async {
    final s = state.session;
    if (s == null || !s.isWon || state.conquering) return;
    emit(state.copyWith(
        conquering: true, clearConquerResult: true, clearError: true));
    try {
      final res = await _repo.conquerIsland(s.id, islandSlug);
      Analytics.I.logEvent('quiz_island_conquered', {
        'island': res.island,
        'promoted': res.promoted,
        'tier': res.conquest.tier,
      });
      emit(state.copyWith(
        conquering: false,
        conquest: res.conquest,
        conquerResult: res,
      ));
    } catch (e, st) {
      AppLogger.error('quiz-conquer', e, st);
      emit(state.copyWith(conquering: false, error: e.toString()));
    }
  }

  /// Carga el ranking (pestaña Ranking, on-demand).
  Future<void> loadRanking() async {
    emit(state.copyWith(rankingLoading: true, rankingFailed: false));
    try {
      final r = await _repo.getRanking();
      emit(state.copyWith(
          ranking: r, rankingLoading: false, rankingLoaded: true));
    } catch (e, st) {
      AppLogger.error('quiz-ranking', e, st);
      emit(state.copyWith(rankingLoading: false, rankingFailed: true));
    }
  }

  /// Continúa una partida activa sin terminar.
  Future<void> resumeGame(QuizSession session) async {
    emit(state.copyWith(
      phase: QuizPhase.loading,
      clearError: true,
      clearQuestion: true,
      clearResult: true,
      clearSelected: true,
      clearLanded: true,
      clearConquerResult: true,
      paused: false,
    ));
    _exhausted.clear();
    try {
      var cats = state.categories;
      if (cats.isEmpty) cats = await _repo.getCategories();
      _gamesWonBefore = state.stats?.gamesWon ?? 0;
      emit(state.copyWith(
        phase: QuizPhase.spinning,
        categories: cats,
        session: session,
        clearActiveSession: true,
        secondsLeft: questionSeconds,
      ));
    } catch (e) {
      emit(state.copyWith(phase: QuizPhase.error, error: e.toString()));
    }
  }

  // ── Ciclo de partida ───────────────────────────────────────────────────────

  Future<void> startGame() async {
    emit(state.copyWith(
      phase: QuizPhase.loading,
      clearError: true,
      clearQuestion: true,
      clearResult: true,
      clearSelected: true,
      clearLanded: true,
      clearConquerResult: true,
      leveledUp: false,
      paused: false,
    ));
    _exhausted.clear();
    try {
      var cats = state.categories;
      if (cats.isEmpty) cats = await _repo.getCategories();
      // Para detectar ascenso de rango al ganar.
      try {
        _gamesWonBefore = (await _repo.getStats()).gamesWon;
      } catch (e) {
        AppLogger.warn('quiz-start', 'stats no disponibles: $e');
        _gamesWonBefore = state.stats?.gamesWon ?? 0;
      }
      final session = await _repo.startSession();
      Analytics.I.logEvent('quiz_session_start');
      emit(state.copyWith(
        phase: QuizPhase.spinning,
        categories: cats,
        session: session,
        clearActiveSession: true,
        secondsLeft: questionSeconds,
      ));
    } catch (e) {
      emit(state.copyWith(phase: QuizPhase.error, error: e.toString()));
    }
  }

  /// Gira la ruleta: elige categoría (con preguntas disponibles) y precarga su
  /// pregunta. La UI anima la rueda hacia [state.landed] y al terminar llama
  /// [onSpinSettled].
  Future<void> spin() async {
    final session = state.session;
    if (session == null || state.phase != QuizPhase.spinning) return;
    try {
      QuizCategory? landed;
      QuizQuestion? question;
      final tried = <String>{};
      while (question == null) {
        final candidate = _pickCategory(exclude: tried);
        if (candidate == null) break; // todas agotadas (improbable: 26/cat)
        try {
          question = await _repo.nextQuestion(session.id, candidate.slug);
          landed = candidate;
        } on QuizNoQuestionsLeft {
          _exhausted.add(candidate.slug);
          tried.add(candidate.slug);
        }
      }
      if (landed == null || question == null) {
        emit(state.copyWith(
            phase: QuizPhase.error, error: 'Sin preguntas disponibles'));
        return;
      }
      Analytics.I.logEvent('quiz_spin', {'category': landed.slug});
      final (shuffledQ, perm) = _shuffleQuestion(question);
      _optionPerm = perm;
      emit(state.copyWith(
        landed: landed,
        question: shuffledQ,
        clearResult: true,
        clearSelected: true,
      ));
    } catch (e) {
      emit(state.copyWith(phase: QuizPhase.error, error: e.toString()));
    }
  }

  /// La animación de la ruleta terminó: muestra la pregunta y arranca el reloj.
  void onSpinSettled() {
    if (state.phase != QuizPhase.spinning || state.question == null) return;
    final q = state.question!;
    Analytics.I.logEvent('quiz_question_view', {
      'category': q.categorySlug,
      'difficulty': q.difficulty,
    });
    _questionShownAt = DateTime.now();
    final secs = _secondsForTier();
    emit(state.copyWith(
      phase: QuizPhase.question,
      secondsLeft: secs,
      secondsTotal: secs,
      clearSelected: true,
      clearResult: true,
    ));
    _startTimer();
  }

  /// Responde (o `null` si se agotó el tiempo). El servidor puntúa.
  Future<void> answer(int? index) async {
    final session = state.session;
    final q = state.question;
    if (session == null ||
        q == null ||
        state.phase != QuizPhase.question ||
        state.paused) {
      return;
    }
    _cancelTimer();
    final secondsLeft = state.secondsLeft.clamp(0, questionSeconds);
    final timeMs = _questionShownAt != null
        ? DateTime.now().difference(_questionShownAt!).inMilliseconds
        : (questionSeconds - secondsLeft) * 1000;

    // `index` es la posición BARAJADA que tocó el usuario; el servidor valida
    // contra el orden original, así que traducimos.
    final perm = _optionPerm;
    final originalIndex = (index != null && perm != null) ? perm[index] : index;

    // Muestra de inmediato la opción elegida (en su posición barajada).
    emit(state.copyWith(selectedIndex: index));

    try {
      final res = await _repo.submitAnswer(
        sessionId: session.id,
        questionId: q.id,
        selectedIndex: originalIndex,
        timeMs: timeMs,
        secondsLeft: secondsLeft,
      );
      _emitAnalyticsForAnswer(res, q);
      // El servidor devuelve correctIndex en orden ORIGINAL; lo mapeamos a la
      // posición barajada para que el reveal ilumine la opción correcta.
      final shown = _mapResultToShuffled(res, perm);
      final won = res.session.isWon;
      final leveled =
          won && _rankIndex(_gamesWonBefore) != _rankIndex(_gamesWonBefore + 1);
      emit(state.copyWith(
        phase: QuizPhase.revealing,
        result: shown,
        session: res.session,
        leveledUp: leveled,
      ));
    } catch (e) {
      emit(state.copyWith(phase: QuizPhase.error, error: e.toString()));
    }
  }

  /// Tras el reveal (la UI espera ~2 s): siguiente turno, victoria o derrota.
  void continueAfterReveal() {
    if (state.phase != QuizPhase.revealing) return;
    final session = state.session;
    if (session == null) return;
    if (session.isWon) {
      emit(state.copyWith(phase: QuizPhase.won));
    } else if (session.isLost) {
      emit(state.copyWith(phase: QuizPhase.lost));
    } else {
      emit(state.copyWith(
        phase: QuizPhase.spinning,
        clearQuestion: true,
        clearResult: true,
        clearSelected: true,
        clearLanded: true,
        secondsLeft: questionSeconds,
      ));
    }
  }

  Future<void> restart() => startGame();

  /// «Nueva» con una partida en curso (ya confirmado por el usuario):
  /// abandona la activa en el servidor y empieza otra.
  Future<void> startNewGame() async {
    final active = state.activeSession;
    if (active != null && active.isActive) {
      try {
        await _repo.abandon(active.id);
      } catch (e, st) {
        AppLogger.error('quiz-new', 'abandon: $e', st);
      }
    }
    await startGame();
  }

  /// Desde el resultado (o un error) vuelve al lobby con datos frescos.
  Future<void> backToLobby() async {
    _cancelTimer();
    emit(state.copyWith(
      phase: QuizPhase.loading,
      clearQuestion: true,
      clearResult: true,
      clearSelected: true,
      clearLanded: true,
      clearConquerResult: true,
      clearError: true,
      paused: false,
    ));
    await loadLobby();
  }

  /// Pausa el reloj de la pregunta (hoja «¿Salir de la partida?» abierta).
  void pauseTimer() {
    if (state.phase != QuizPhase.question || state.paused) return;
    _cancelTimer();
    _pausedAt = DateTime.now();
    emit(state.copyWith(paused: true));
  }

  /// Reanuda el reloj; el tiempo en pausa no cuenta para `timeMs`.
  void resumeTimer() {
    if (!state.paused) return;
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null && _questionShownAt != null) {
      _questionShownAt =
          _questionShownAt!.add(DateTime.now().difference(pausedAt));
    }
    emit(state.copyWith(paused: false));
    if (state.phase == QuizPhase.question && state.selectedIndex == null) {
      _startTimer();
    }
  }

  /// Sale del juego: abandona la partida activa (fire-and-forget).
  void quit() {
    _cancelTimer();
    final s = state.session;
    if (s != null && s.isActive) {
      _repo
          .abandon(s.id)
          .catchError((Object e) => AppLogger.warn('quiz-quit', 'abandon: $e'));
    }
    emit(const QuizGameState());
  }

  /// Vuelve al lobby DEJANDO la partida activa (se podrá continuar luego).
  /// No abandona la sesión; sigue 'active' en el backend.
  void leaveToLobby() {
    _cancelTimer();
    _pausedAt = null;
    emit(state.copyWith(
      phase: QuizPhase.loading,
      paused: false,
      clearQuestion: true,
      clearResult: true,
      clearSelected: true,
      clearLanded: true,
    ));
    loadLobby();
  }

  /// Abandona la partida (no se podrá continuar) y vuelve al lobby.
  Future<void> abandonAndLeave() async {
    _cancelTimer();
    _pausedAt = null;
    final s = state.session;
    emit(state.copyWith(
      phase: QuizPhase.loading,
      paused: false,
      clearQuestion: true,
      clearResult: true,
      clearSelected: true,
      clearLanded: true,
    ));
    if (s != null && s.isActive) {
      try {
        await _repo.abandon(s.id);
      } catch (e, st) {
        AppLogger.error('quiz-abandon', e, st);
      }
    }
    await loadLobby();
  }

  // ── Internos ────────────────────────────────────────────────────────────────

  void _emitAnalyticsForAnswer(QuizAnswerResult res, QuizQuestion q) {
    Analytics.I.logEvent('quiz_answer', {
      'category': q.categorySlug,
      'is_correct': res.isCorrect,
      'points': res.points,
      'streak': res.session.streak,
    });
    if (res.newWedge) {
      Analytics.I.logEvent('quiz_wedge_won', {'category': q.categorySlug});
    }
    if (res.session.isWon) {
      Analytics.I.logEvent('quiz_game_won', {
        'score': res.session.score,
        'best_streak': res.session.bestStreak,
      });
    } else if (res.session.isLost) {
      Analytics.I.logEvent('quiz_game_lost', {
        'score': res.session.score,
        'wedges': res.session.wedges.length,
      });
    }
  }

  /// Elige una categoría aleatoria con preguntas disponibles (no agotada ni en
  /// [exclude]). Prioriza ligeramente las que faltan por conseguir.
  QuizCategory? _pickCategory({Set<String> exclude = const {}}) {
    final wedges = state.wedges.toSet();
    final available = state.categories
        .where((c) => !_exhausted.contains(c.slug) && !exclude.contains(c.slug))
        .toList();
    if (available.isEmpty) return null;
    final missing = available.where((c) => !wedges.contains(c.slug)).toList();
    // 70% de las veces, si quedan quesitos por conseguir, cae en uno de esos.
    final from =
        (missing.isNotEmpty && _rng.nextDouble() < 0.7) ? missing : available;
    return from[_rng.nextInt(from.length)];
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.secondsLeft - 1;
      if (left <= 0) {
        _cancelTimer();
        emit(state.copyWith(secondsLeft: 0));
        answer(null); // tiempo agotado = fallo
      } else {
        emit(state.copyWith(secondsLeft: left));
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int _rankIndex(int gamesWon) => gamesWon >= 12 ? 2 : (gamesWon >= 3 ? 1 : 0);

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
