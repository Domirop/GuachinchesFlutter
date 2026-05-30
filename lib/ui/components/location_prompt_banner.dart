import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/utils/location_prompt_action.dart';

/// Banner global que pide activar la ubicación.
///
/// Comportamiento adaptativo según el sub-tipo de `LocationDenied`:
///  - [LocationDenied] base: tap → `requestLocation()` (intenta modal nativo).
///  - [LocationPermanentlyDenied]: tap → push [LocationDeniedScreen] con
///    instrucciones para Ajustes.
///  - [LocationServiceDisabled]: tap → push [LocationDeniedScreen] con
///    instrucciones para activar Servicios de Localización.
///
/// Se oculta automáticamente en `LocationLoaded`, `LocationLoading`,
/// `LocationInitial` y `LocationUnavailable`.
class LocationPromptBanner extends StatelessWidget {
  /// Si `true` el banner usa un layout más compacto (1 línea) — pensado para
  /// el home. Si `false` (default) muestra eyebrow + título + sub-copy.
  final bool compact;

  const LocationPromptBanner({super.key, this.compact = false});

  // El comportamiento lo gestiona el helper compartido para que el banner
  // y la pantalla `CercaAhoraScreen` reaccionen igual.
  Future<void> _onTap(BuildContext context) =>
      handleLocationPromptTap(context);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (state is! LocationDenied) {
          // LocationDenied es la base de las 3 variantes → cubre todo.
          return const SizedBox.shrink();
        }

        final isPermanent = state is LocationPermanentlyDenied;
        final isServiceOff = state is LocationServiceDisabled;
        final needsSettings = isPermanent || isServiceOff;

        final eyebrow = isServiceOff
            ? 'UBICACIÓN APAGADA'
            : (isPermanent ? 'PERMISO BLOQUEADO' : 'ACTIVAR UBICACIÓN');
        final title = isServiceOff
            ? 'Activa Servicios de Localización'
            : 'Ver lo que está cerca de ti';
        final cta = needsSettings ? 'Ajustes' : 'Activar';

        return Semantics(
          identifier: 'home-location-prompt',
          button: true,
          child: GestureDetector(
            onTap: () => _onTap(context),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              decoration: BoxDecoration(
                color: context.brand.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.brand.border, width: 1),
              ),
              clipBehavior: Clip.hardEdge,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: AppColors.atlantico),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          compact ? 10 : 12,
                          12,
                          compact ? 10 : 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.atlantico.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.atlantico,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!compact)
                                    Text(
                                      eyebrow,
                                      style: AppTextStyles.eyebrow(
                                        size: 10,
                                        color: AppColors.atlantico,
                                      ),
                                    ),
                                  if (!compact) const SizedBox(height: 3),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.ui(
                                      size: compact ? 13 : 14,
                                      weight: FontWeight.w600,
                                      color: context.brand.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.atlantico,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                cta,
                                style: AppTextStyles.ui(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
