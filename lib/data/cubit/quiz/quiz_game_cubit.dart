import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
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
  final Random _rng = Random();
  final Set<String> _exhausted = {}; // categorías sin preguntas en la partida
  int _gamesWonBefore = 0;
  DateTime? _questionShownAt;

  // ── Lobby ───────────────────────────────────────────────────────────────────

  /// Carga categorías + stats para el lobby. No inicia partida (sigue en idle).
  /// Resiliente: si una llamada falla (p.ej. backend aún sin desplegar), deja
  /// lo que se pudo cargar y no rompe la pantalla.
  Future<void> loadLobby() async {
    if (state.phase == QuizPhase.idle && state.categories.isEmpty) {
      emit(state.copyWith(phase: QuizPhase.loading, clearError: true));
    }
    List<QuizCategory>? cats;
    QuizStats? stats;
    QuizSession? active;
    List<QuizSessionSummary>? history;
    await Future.wait([
      () async {
        try {
          cats = await _repo.getCategories();
        } catch (_) {}
      }(),
      () async {
        try {
          stats = await _repo.getStats();
        } catch (_) {}
      }(),
      () async {
        try {
          active = await _repo.getActiveSession();
        } catch (_) {}
      }(),
      () async {
        try {
          history = await _repo.getMySessions();
        } catch (_) {}
      }(),
    ]);
    emit(state.copyWith(
      phase: QuizPhase.idle,
      categories: cats ?? state.categories,
      stats: stats ?? state.stats,
      activeSession: active,
      clearActiveSession: active == null,
      history: history ?? state.history,
    ));
  }

  /// Carga el ranking (pestaña Ranking, on-demand).
  Future<void> loadRanking() async {
    emit(state.copyWith(rankingLoading: true));
    try {
      final r = await _repo.getRanking();
      emit(state.copyWith(ranking: r, rankingLoading: false));
    } catch (_) {
      emit(state.copyWith(rankingLoading: false));
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
      leveledUp: false,
    ));
    _exhausted.clear();
    try {
      var cats = state.categories;
      if (cats.isEmpty) cats = await _repo.getCategories();
      // Para detectar ascenso de rango al ganar.
      try {
        _gamesWonBefore = (await _repo.getStats()).gamesWon;
      } catch (_) {
        _gamesWonBefore = 0;
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
      emit(state.copyWith(
        landed: landed,
        question: question,
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
    emit(state.copyWith(
      phase: QuizPhase.question,
      secondsLeft: questionSeconds,
      clearSelected: true,
      clearResult: true,
    ));
    _startTimer();
  }

  /// Responde (o `null` si se agotó el tiempo). El servidor puntúa.
  Future<void> answer(int? index) async {
    final session = state.session;
    final q = state.question;
    if (session == null || q == null || state.phase != QuizPhase.question) {
      return;
    }
    _cancelTimer();
    final secondsLeft = state.secondsLeft.clamp(0, questionSeconds);
    final timeMs = _questionShownAt != null
        ? DateTime.now().difference(_questionShownAt!).inMilliseconds
        : (questionSeconds - secondsLeft) * 1000;

    // Muestra de inmediato la opción elegida; el reveal llega con el servidor.
    emit(state.copyWith(selectedIndex: index));

    try {
      final res = await _repo.submitAnswer(
        sessionId: session.id,
        questionId: q.id,
        selectedIndex: index,
        timeMs: timeMs,
        secondsLeft: secondsLeft,
      );
      _emitAnalyticsForAnswer(res, q);
      final won = res.session.isWon;
      final leveled = won &&
          _rankIndex(_gamesWonBefore) != _rankIndex(_gamesWonBefore + 1);
      emit(state.copyWith(
        phase: QuizPhase.revealing,
        result: res,
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

  /// Sale del juego: abandona la partida activa (fire-and-forget).
  void quit() {
    _cancelTimer();
    final s = state.session;
    if (s != null && s.isActive) {
      _repo.abandon(s.id).catchError((_) {});
    }
    emit(const QuizGameState());
  }

  /// Vuelve al lobby DEJANDO la partida activa (se podrá continuar luego).
  /// No abandona la sesión; sigue 'active' en el backend.
  void leaveToLobby() {
    _cancelTimer();
    emit(state.copyWith(
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
    final s = state.session;
    if (s != null && s.isActive) {
      try {
        await _repo.abandon(s.id);
      } catch (_) {}
    }
    emit(state.copyWith(
      clearQuestion: true,
      clearResult: true,
      clearSelected: true,
      clearLanded: true,
    ));
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

  int _rankIndex(int gamesWon) =>
      gamesWon >= 12 ? 2 : (gamesWon >= 3 ? 1 : 0);

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
