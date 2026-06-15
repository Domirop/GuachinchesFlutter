import 'package:guachinches/data/model/quiz/quiz_models.dart';

enum QuizPhase {
  idle, // antes de empezar / tras salir
  loading, // creando partida
  spinning, // ruleta girando hacia [landed]
  question, // pregunta activa, temporizador corriendo
  revealing, // mostrando acierto/fallo + explicación
  won, // ¡Pleno! (7 quesitos)
  lost, // 0 vidas
  error,
}

/// Estado inmutable de una partida del juego. El scoring vive en el servidor;
/// aquí guardamos el espejo ([session]) + el control de UI (fase, temporizador,
/// pregunta actual y resultado revelado).
class QuizGameState {
  final QuizPhase phase;
  final List<QuizCategory> categories;
  final QuizSession? session;

  /// Stats acumuladas del jugador (para el lobby/victoria). null = sin cargar.
  final QuizStats? stats;

  /// Categoría en la que cae la ruleta este turno.
  final QuizCategory? landed;

  /// Pregunta actual (sin respuesta correcta).
  final QuizQuestion? question;

  /// Índice elegido por el usuario (para el reveal). null = tiempo agotado.
  final int? selectedIndex;

  /// Resultado del servidor (única vía con `correctIndex`).
  final QuizAnswerResult? result;

  /// Segundos restantes del temporizador (para el anillo de progreso).
  final int secondsLeft;

  /// Si en esta partida acaba de subir de nivel (para celebrarlo en victoria).
  final bool leveledUp;

  final String? error;

  const QuizGameState({
    this.phase = QuizPhase.idle,
    this.categories = const [],
    this.session,
    this.stats,
    this.landed,
    this.question,
    this.selectedIndex,
    this.result,
    this.secondsLeft = 0,
    this.leveledUp = false,
    this.error,
  });

  int get lives => session?.lives ?? 3;
  int get score => session?.score ?? 0;
  int get streak => session?.streak ?? 0;
  List<String> get wedges => session?.wedges ?? const [];

  QuizGameState copyWith({
    QuizPhase? phase,
    List<QuizCategory>? categories,
    QuizSession? session,
    QuizStats? stats,
    QuizCategory? landed,
    QuizQuestion? question,
    int? selectedIndex,
    QuizAnswerResult? result,
    int? secondsLeft,
    bool? leveledUp,
    String? error,
    bool clearLanded = false,
    bool clearQuestion = false,
    bool clearSelected = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return QuizGameState(
      phase: phase ?? this.phase,
      categories: categories ?? this.categories,
      session: session ?? this.session,
      stats: stats ?? this.stats,
      landed: clearLanded ? null : (landed ?? this.landed),
      question: clearQuestion ? null : (question ?? this.question),
      selectedIndex:
          clearSelected ? null : (selectedIndex ?? this.selectedIndex),
      result: clearResult ? null : (result ?? this.result),
      secondsLeft: secondsLeft ?? this.secondsLeft,
      leveledUp: leveledUp ?? this.leveledUp,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
