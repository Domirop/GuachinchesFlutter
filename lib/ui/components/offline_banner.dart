import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Aviso de «sin conexión»: cápsula de cristal que flota bajo la barra de
/// estado, sin empujar el contenido ni tapar la hora. La pantalla sigue
/// enseñando lo que ya había cargado.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const text = 'Sin conexión · Ves lo último que cargaste';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityOnline) return const SizedBox.shrink();
        final gm = GmColors.of(context);
        return Semantics(
          identifier: 'offline-banner',
          liveRegion: true,
          child: Center(
            child: GmGlass(
              borderRadius: BorderRadius.circular(GmRadius.pill),
              tint: gm.glass,
              edge: gm.glassEdge,
              shadow: gm.shadow2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: gm.warnText, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 2,
                        style: GmText.sub(color: gm.label, w: FontWeight.w600),
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
