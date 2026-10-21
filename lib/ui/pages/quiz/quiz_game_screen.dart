import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';
import 'package:guachinches/ui/pages/quiz/quiz_sound.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glyphs.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_lobby_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_play_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_result_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_sheets.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_ui.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Juego «¿Cuánto sabes de Canarias?» / «Conquista Canarias» a pantalla
/// completa (rediseño iOS 27, tableros `QuizInicio`, `QuizPartida`,
/// `QuizResultado`, `QuizHojas`). Aloja el [QuizGameCubit] y conmuta la vista
/// según la fase. Sin intro forzada: el lobby pinta su esqueleto mientras
/// carga y el pito herreño suena solo la primera vez.
class QuizGameScreen extends StatelessWidget {
  /// Inyectables para tests.
  final QuizRepository? repository;
  final QuizAudio? audio;

  const QuizGameScreen({super.key, this.repository, this.audio});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizGameCubit(repository ?? QuizRepository())..loadLobby(),
      child: _QuizGameScaffold(audio: audio),
    );
  }
}

class _QuizGameScaffold extends StatefulWidget {
  final QuizAudio? audio;
  const _QuizGameScaffold({this.audio});

  @override
  State<_QuizGameScaffold> createState() => _QuizGameScaffoldState();
}

class _QuizGameScaffoldState extends State<_QuizGameScaffold> {
  late final QuizAudio _audio = widget.audio ?? QuizSound();

  /// Hoja abierta (salir / nueva): la ruleta no abre la pregunta hasta que se
  /// cierre, para que el reloj no corra a escondidas.
  bool _sheetOpen = false;
  bool _pendingSettle = false;

  @override
  void initState() {
    super.initState();
    _audio.introIfFirstTime();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  bool _inGame(QuizPhase p) =>
      p == QuizPhase.spinning ||
      p == QuizPhase.question ||
      p == QuizPhase.revealing;

  void _onPhase(BuildContext context, QuizGameState state) {
    if (state.phase == QuizPhase.revealing) {
      (state.result?.isCorrect ?? false) ? _audio.correct() : _audio.fail();
    }
  }

  void _onSettled(QuizGameCubit cubit) {
    if (_sheetOpen) {
      _pendingSettle = true;
      return;
    }
    cubit.onSpinSettled();
  }

  Future<void> _confirmExit(BuildContext context) async {
    if (_sheetOpen) return;
    final cubit = context.read<QuizGameCubit>();
    final st = cubit.state;
    final timing = st.phase == QuizPhase.question && st.selectedIndex == null;
    if (timing) cubit.pauseTimer();
    _sheetOpen = true;
    final choice = await showQuizExitSheet(
      context,
      session: st.session,
      clockPaused: timing,
    );
    _sheetOpen = false;
    if (!mounted) return;
    switch (choice) {
      case QuizExitChoice.leave:
        _pendingSettle = false;
        cubit.leaveToLobby();
      case QuizExitChoice.abandon:
        _pendingSettle = false;
        Analytics.I.logEvent('quiz_abandon');
        cubit.abandonAndLeave();
      case QuizExitChoice.keepPlaying:
      case null:
        cubit.resumeTimer();
        if (_pendingSettle) {
          _pendingSettle = false;
          cubit.onSpinSettled();
        }
    }
  }

  Future<void> _onNew(BuildContext context) async {
    final cubit = context.read<QuizGameCubit>();
    final active = cubit.state.activeSession;
    if (active == null || !active.isActive) {
      cubit.startGame();
      return;
    }
    _sheetOpen = true;
    final choice = await showQuizNewGameSheet(context, active);
    _sheetOpen = false;
    if (!mounted) return;
    switch (choice) {
      case QuizNewGameChoice.startNew:
        cubit.startNewGame();
      case QuizNewGameChoice.resume:
        cubit.resumeGame(active);
      case null:
        break;
    }
  }

  void _share(String text) {
    Analytics.I.logEvent('quiz_share');
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    return BlocConsumer<QuizGameCubit, QuizGameState>(
      listenWhen: (p, c) => p.phase != c.phase,
      listener: _onPhase,
      builder: (context, state) {
        final cubit = context.read<QuizGameCubit>();
        final inGame = _inGame(state.phase);
        final Widget body;
        final String key;
        switch (state.phase) {
          case QuizPhase.idle:
          case QuizPhase.loading:
            key = 'lobby';
            body = QuizLobbyView(
              state: state,
              onClose: () => Navigator.of(context).maybePop(),
              onHelp: () => showQuizRulesSheet(context),
              onPlay: cubit.startGame,
              onNew: () => _onNew(context),
              onResume: cubit.resumeGame,
              onRetryLobby: cubit.loadLobby,
              onRetryHistory: cubit.loadHistory,
              onLoadRanking: cubit.loadRanking,
            );
          case QuizPhase.error:
            key = 'error';
            body = _ErrorView(
              onRetry: cubit.backToLobby,
              onClose: () => Navigator.of(context).maybePop(),
            );
          case QuizPhase.spinning:
            key = 'wheel-${state.wedges.length}-${state.lives}-${state.score}';
            body = QuizWheelView(
              state: state,
              onPrefetch: cubit.spin,
              onSettled: () => _onSettled(cubit),
              onExit: () => _confirmExit(context),
            );
          case QuizPhase.question:
          case QuizPhase.revealing:
            if (state.question == null) {
              key = 'empty';
              body = const SizedBox.shrink();
            } else {
              key = 'q-${state.question!.id}';
              body = QuizQuestionView(
                state: state,
                onAnswer: cubit.answer,
                onNext: cubit.continueAfterReveal,
                onExit: () => _confirmExit(context),
              );
            }
          case QuizPhase.won:
          case QuizPhase.lost:
            key = 'result-${state.phase.name}';
            body = QuizResultView(
              state: state,
              onConquer: cubit.conquer,
              onHome: cubit.backToLobby,
              onPlayAgain: cubit.restart,
              onShare: _share,
            );
        }
        return PopScope(
          canPop: !inGame,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && inGame) _confirmExit(context);
          },
          child: Scaffold(
            backgroundColor: gm.canvas,
            body: AnimatedSwitcher(
              duration: Duration(milliseconds: reduced ? 0 : 260),
              switchInCurve: GmMotion.settle,
              switchOutCurve: GmMotion.ease,
              child: KeyedSubtree(key: ValueKey(key), child: body),
            ),
          ),
        );
      },
    );
  }
}

/// Error de partida (crear, pedir pregunta o responder). Sin texto técnico.
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;
  const _ErrorView({required this.onRetry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 16),
      child: Column(
        children: [
          QuizTopBar(
            left: GmToolbarButton(
              icon: GmIcons.close,
              light: true,
              semanticLabel: 'Cerrar el juego',
              identifier: 'quiz-error-close-button',
              onTap: onClose,
            ),
          ),
          const Spacer(),
          QuizStateCard(
            identifier: 'quiz-game-error',
            title: 'No pudimos seguir con la partida',
            text: 'Revisa tu conexión e inténtalo de nuevo.',
            mood: QuizVolcanoMood.sad,
            action: 'Reintentar',
            actionIdentifier: 'quiz-game-retry-button',
            onAction: onRetry,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
