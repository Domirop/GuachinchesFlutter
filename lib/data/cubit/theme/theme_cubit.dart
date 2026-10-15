import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/services/app_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _storageKey = 'themeMode';

  ThemeCubit(ThemeMode initial) : super(initial) {
    _syncTextStyleDefaults(initial);
  }

  Future<void> setMode(ThemeMode mode) async {
    _syncTextStyleDefaults(mode);
    emit(mode);
    await AppStorage.instance.write(
      key: _storageKey,
      value: mode.name, // 'light' | 'dark' | 'system'
    );
  }

  void toggle() => setMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  static Future<ThemeMode> hydrate() async {
    try {
      final stored = await AppStorage.instance.read(key: _storageKey);
      final mode = switch (stored) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      _syncTextStyleDefaults(mode);
      return mode;
    } catch (_) {
      _syncTextStyleDefaults(ThemeMode.light);
      return ThemeMode.light;
    }
  }

  static void _syncTextStyleDefaults(ThemeMode mode) {
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      // «Sistema»: el brillo del sistema al aplicarlo (las pantallas nuevas
      // usan GmColors.of(context) y siguen el cambio en vivo).
      ThemeMode.system => WidgetsBinding
              .instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
    };
    AppTextStyles.defaultTextColor = dark ? AppColors.crema : AppColors.ink;
  }
}
