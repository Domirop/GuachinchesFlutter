import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityOnline) return const SizedBox.shrink();
        return Semantics(
          identifier: 'offline-banner',
          child: Container(
            color: AppColors.mojo,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sin conexión — mostrando datos guardados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
