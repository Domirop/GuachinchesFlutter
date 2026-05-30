import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/components/open_now_callout.dart';
import 'package:guachinches/ui/pages/new_home/widgets/skeletons.dart';

/// Decide qué renderizar en el slot del callout "Abiertos cerca ahora":
///
/// 1. [bootstrapLoading] true → [OpenNowCalloutSkeleton] (datos aún no llegan).
/// 2. [LocationDenied] (cubre subclases) → [SizedBox.shrink()] — el banner
///    de permisos ya ocupa la zona superior; no duplicar mensajería.
/// 3. Cualquier otro estado → [OpenNowCallout] real con [count] y [contextLabel].
class OpenNowCalloutSlot extends StatelessWidget {
  final bool bootstrapLoading;
  final int count;
  final String contextLabel;
  final VoidCallback? onTap;

  const OpenNowCalloutSlot({
    Key? key,
    required this.bootstrapLoading,
    required this.count,
    required this.contextLabel,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bootstrapLoading) return const OpenNowCalloutSkeleton();
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (state is LocationDenied) return const SizedBox.shrink();
        return OpenNowCallout(
          count: count,
          contextLabel: contextLabel,
          onTap: onTap,
        );
      },
    );
  }
}
