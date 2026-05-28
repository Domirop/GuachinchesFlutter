import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/model/Island.dart';

/// Bottom sheet para cambiar de isla. Mismo lenguaje visual que ZonePickerSheet.
///
/// Las islas se cargan del backend vía [IslandsCubit] (provisto a nivel app en
/// `main.dart`). Si la cubit está en `IslandsLoaded`, se pintan todas las islas
/// del archipiélago — no solo las hardcoded en `AllIsland`.
class IslandPickerSheet extends StatelessWidget {
  final String selectedIslandId;
  final ValueChanged<Island> onSelect;

  const IslandPickerSheet({
    super.key,
    required this.selectedIslandId,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required String selectedIslandId,
    required ValueChanged<Island> onSelect,
  }) {
    // Captura la cubit del contexto del caller — el `showModalBottomSheet`
    // monta el builder en un Navigator distinto donde el provider no es
    // visible. Lo reinyectamos por encima del sheet.
    final cubit = context.read<IslandsCubit>();
    // Si nunca se cargó (estado inicial), dispara la carga ahora.
    if (cubit.state is IslandsInitial) {
      cubit.load();
    }
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.brand.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: IslandPickerSheet(
          selectedIslandId: selectedIslandId,
          onSelect: onSelect,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.brand.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CAMBIA DE ISLA',
              style: AppTextStyles.displaySection(size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige dónde quieres comer hoy',
              style: AppTextStyles.muted(size: 12),
            ),
            const SizedBox(height: 16),
            // Lista de islas dinámica desde el backend (vía IslandsCubit).
            // Con scroll por si la altura del sheet no cubre las 7 islas.
            Flexible(
              child: BlocBuilder<IslandsCubit, IslandsState>(
                builder: (context, state) {
                  if (state is IslandsLoaded && state.islands.isNotEmpty) {
                    final list = [...state.islands]
                      ..sort((a, b) => a.position.compareTo(b.position));
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: list.map((island) {
                          final active = island.id == selectedIslandId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _IslandListCard(
                              island: island,
                              active: active,
                              onTap: () {
                                Navigator.pop(context);
                                if (!active) onSelect(island);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                  if (state is IslandsFailure) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No pudimos cargar las islas. Vuelve a intentarlo en un momento.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted(size: 13),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandListCard extends StatelessWidget {
  final Island island;
  final bool active;
  final VoidCallback onTap;

  const _IslandListCard({
    required this.island,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.atlantico.withOpacity(0.12)
                : context.brand.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? AppColors.atlantico.withOpacity(0.55)
                  : context.brand.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IslandThumb(island: island),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            island.name.toUpperCase(),
                            style: AppTextStyles.displaySection(size: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.atlantico,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _descriptionFor(island.name),
                      style: AppTextStyles.muted(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: context.brand.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Descripción editorial por isla. Buscamos por nombre normalizado para
  /// no depender del UUID y poder cubrir las 7 islas devueltas por el backend.
  static String _descriptionFor(String name) {
    final n = name.toLowerCase().trim();
    switch (n) {
      case 'tenerife':
        return 'Guachinches, mar y Teide';
      case 'gran canaria':
        return 'Capital, dunas y kilómetros de costa';
      case 'lanzarote':
        return 'Volcanes, vinos y arquitectura blanca';
      case 'fuerteventura':
        return 'Playas largas y queso majorero';
      case 'la palma':
        return 'La Isla Bonita y cocina de mercado';
      case 'la gomera':
        return 'Bosques de laurisilva y almogrote';
      case 'el hierro':
        return 'Quesos ahumados y vinos del Atlántico';
      default:
        return '';
    }
  }
}

class _IslandThumb extends StatelessWidget {
  final Island island;
  const _IslandThumb({required this.island});

  /// Emoji por isla — consistente con onboarding. Funciona aunque el backend
  /// no devuelva `logoUrl` y sin gastar red en el sheet.
  static const _emoji = {
    'tenerife': '🏔',
    'gran canaria': '🌅',
    'lanzarote': '🌋',
    'fuerteventura': '🏝',
    'la palma': '🌿',
    'la gomera': '🌲',
    'el hierro': '🌊',
  };

  @override
  Widget build(BuildContext context) {
    final key = island.name.toLowerCase().trim();
    final glyph = _emoji[key] ?? '🏝';
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.atlanticoClaro, AppColors.atlantico],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(glyph, style: const TextStyle(fontSize: 28)),
    );
  }
}
