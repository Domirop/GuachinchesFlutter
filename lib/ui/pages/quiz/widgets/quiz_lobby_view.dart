import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_map_board.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Nombres de arena por tier (1..3). Índice 0 vacío.
const List<String> _kTierNames = ['', 'Marea', 'Volcán', 'Leyenda'];

/// Pestaña INICIO, estructurada en dos zonas (estilo "stage + acción"):
///   · ARRIBA = lo gráfico: el **mapa de conquista** como héroe + barra de
///     progreso de la arena (las 7 islas como nodos hacia el ascenso).
///   · ABAJO  = lo de jugar: partida en curso, botón JUGAR y tus marcas.
class QuizLobbyView extends StatelessWidget {
  final QuizGameState state;
  final VoidCallback onPlay;
  final ValueChanged<QuizSession> onResume;
  final VoidCallback onHowTo;

  const QuizLobbyView({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onResume,
    required this.onHowTo,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final conquest = state.conquest;
    final tier = conquest?.tier ?? 1;
    final tierName = conquest?.tierName ?? 'Marea';
    final owned = conquest?.conqueredIslands.toSet() ?? <String>{};
    final color = quizTierColor(tier);
    final active = state.activeSession;
    final nextTier = tier < 3 ? _kTierNames[tier + 1] : null;

    // La foto va a pantalla completa (la pinta QuizHomeView detrás). Arriba, el
    // título y las islas flotan sobre la escena; abajo, una repisa de cristal
    // esmerilado a sangre aloja la acción para que se lea sobre la foto.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera: título + (arena · islas conquistadas) alineados arriba.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CONQUISTA CANARIAS',
                  style: AppTextStyles.displayHero(
                          size: 24, color: brand.textPrimary)
                      .copyWith(shadows: const [
                    Shadow(color: Color(0x55FFFFFF), blurRadius: 8),
                  ])),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _ArenaChip(tierName: tierName, color: color)),
                  const SizedBox(width: 8),
                  _CountPill(conquered: owned.length, total: 7),
                ],
              ),
            ],
          ),
        ),
        // Hueco grande arriba → las islas caen más abajo, sobre el mar.
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // Las islas flotando donde Preguntados pone su mascota.
          child: _HeroBand(owned: owned, color: color),
        ),
        const Spacer(flex: 1),

        // ── REPISA DE CRISTAL (acción) ────────────────────────────────────
        _BottomDeck(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ArenaProgress(
                conquered: owned.length,
                total: 7,
                color: color,
                nextTier: nextTier,
              ),
              const SizedBox(height: 12),
              if (active != null) ...[
                _ActiveGameCard(
                    session: active,
                    tierColor: color,
                    onResume: () => onResume(active)),
                const SizedBox(height: 10),
              ],
              _PlayButton(
                  label: active != null ? 'NUEVA PARTIDA' : 'JUGAR',
                  onTap: onPlay),
              const SizedBox(height: 10),
              _StatsRow(stats: state.stats),
              TextButton(
                onPressed: onHowTo,
                child: Text('¿Cómo se juega?',
                    style: AppTextStyles.ui(
                        size: 13,
                        color: brand.textSecondary,
                        weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Repisa inferior de cristal esmerilado (full-bleed) ──────────────────────────

class _BottomDeck extends StatelessWidget {
  final Widget child;
  const _BottomDeck({required this.child});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: brand.surface.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: brand.border)),
          ),
          // El padding inferior incluye el home indicator: la repisa llega al
          // borde de la pantalla y no deja ver la foto por debajo.
          padding: EdgeInsets.fromLTRB(20, 14, 20, 10 + safeBottom),
          child: child,
        ),
      ),
    );
  }
}

// ── Héroe: las islas flotando sobre la escena de la cabecera ────────────────────

class _HeroBand extends StatelessWidget {
  final Set<String> owned;
  final Color color;
  const _HeroBand({required this.owned, required this.color});

  @override
  Widget build(BuildContext context) {
    // Banda transparente: solo el mapa. El fondo es la escena que pinta
    // QuizHomeView detrás; la arena y el contador van en la cabecera.
    return SizedBox(
      height: 150,
      child: Center(
        child: QuizMapBoard(owned: owned, tierColor: color, bare: true),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int conquered;
  final int total;
  const _CountPill({required this.conquered, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white),
      ),
      child: Text('$conquered/$total islas',
          style: AppTextStyles.displaySection(
              size: 12, color: const Color(0xFF11343F))),
    );
  }
}

// ── Chip de arena ──────────────────────────────────────────────────────────────

class _ArenaChip extends StatelessWidget {
  final String tierName;
  final Color color;
  const _ArenaChip({required this.tierName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terrain_rounded, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text('ARENA · ${tierName.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.eyebrow(size: 10, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Barra de progreso de la arena (nodos hacia el ascenso) ──────────────────────

class _ArenaProgress extends StatelessWidget {
  final int conquered;
  final int total;
  final Color color;
  final String? nextTier; // null si ya es la arena máxima

  const _ArenaProgress({
    required this.conquered,
    required this.total,
    required this.color,
    required this.nextTier,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < total; i++) ...[
              _Node(filled: i < conquered, color: color, brand: brand),
              if (i < total - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      // Conector encendido solo si el nodo siguiente ya cayó.
                      color: i < conquered - 1
                          ? color.withValues(alpha: 0.9)
                          : brand.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
            const SizedBox(width: 8),
            // Recompensa al final: ascenso al siguiente tier.
            _RewardBadge(
              color: nextTier == null
                  ? quizTierColor(3)
                  : quizTierColor(_nextTierIndex()),
              done: conquered >= total,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          nextTier == null
              ? (conquered >= total
                  ? 'Has conquistado la arena máxima 👑'
                  : 'Completa las $total islas de la arena Leyenda')
              : 'Conquista ${total - conquered} isla${total - conquered == 1 ? '' : 's'} más para ascender a $nextTier',
          textAlign: TextAlign.center,
          style: AppTextStyles.ui(size: 11.5, color: brand.textSecondary),
        ),
      ],
    );
  }

  int _nextTierIndex() {
    // nextTier es el nombre; mapear a su índice (2 o 3).
    final idx = _kTierNames.indexOf(nextTier ?? '');
    return idx < 1 ? 2 : idx;
  }
}

class _Node extends StatelessWidget {
  final bool filled;
  final Color color;
  final BrandColors brand;
  const _Node({required this.filled, required this.color, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: filled ? color : brand.glass,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? color : brand.borderStrong,
          width: 1.6,
        ),
        boxShadow: filled
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
            : null,
      ),
      child: filled
          ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
          : null,
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final Color color;
  final bool done;
  const _RewardBadge({required this.color, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: done ? 1 : 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
        boxShadow: done
            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)]
            : null,
      ),
      child: Icon(Icons.emoji_events_rounded,
          size: 16, color: done ? Colors.white : color),
    );
  }
}

// ── Partida en curso ────────────────────────────────────────────────────────────

class _ActiveGameCard extends StatelessWidget {
  final QuizSession session;
  final Color tierColor;
  final VoidCallback onResume;
  const _ActiveGameCard({
    required this.session,
    required this.tierColor,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return QuizGlassCard(
      tint: AppColors.atlantico.withValues(alpha: 0.16),
      borderColor: AppColors.atlantico.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.atlanticoClaro, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PARTIDA EN CURSO',
                    style: AppTextStyles.eyebrow(
                        size: 10, color: AppColors.atlanticoClaro)),
                const SizedBox(height: 2),
                Text(
                    '${session.wedges.length}/7 quesitos · ${session.lives} vidas · ${session.score} pts',
                    style:
                        AppTextStyles.ui(size: 12, color: brand.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onResume,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.atlantico,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text('CONTINUAR',
                  style: AppTextStyles.displaySection(
                      size: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Marcas ───────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final QuizStats? stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return QuizGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _Stat(label: 'PUNTOS', value: '${stats?.totalPoints ?? 0}'),
          _Divider(),
          _Stat(label: 'GANADAS', value: '${stats?.gamesWon ?? 0}'),
          _Divider(),
          _Stat(label: 'MEJOR RACHA', value: '${stats?.bestStreak ?? 0}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displaySection(
                  size: 16, color: brand.textPrimary)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.eyebrow(size: 9, color: brand.textMuted)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: context.brand.border);
}

// ── Botón JUGAR con borde-degradado vivo (estilo "Crear partida") ───────────────

class _PlayButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PlayButton({required this.label, required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      // RepaintBoundary: el borde-degradado late a 60fps; aislándolo en su
      // propia capa evitamos que su repintado obligue a re-difuminar el
      // BackdropFilter de la repisa cada frame (eso recalentaba el móvil).
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Container(
              height: 58,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.full),
                gradient: SweepGradient(
                  transform: GradientRotation(t * 6.2831853),
                  colors: const [
                    AppColors.atlantico,
                    AppColors.atlanticoClaro,
                    AppColors.sol,
                    AppColors.atlanticoClaro,
                    AppColors.atlantico,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.atlantico.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.atlantico, AppColors.atlanticoClaro],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(widget.label,
                    style: AppTextStyles.displaySection(
                            size: 18, color: Colors.white)
                        .copyWith(letterSpacing: 2)),
              ),
            );
          },
        ),
      ),
    );
  }
}
