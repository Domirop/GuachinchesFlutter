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
      value: mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  void toggle() => setMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  static Future<ThemeMode> hydrate() async {
    try {
      final stored = await AppStorage.instance.read(key: _storageKey);
      final mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _syncTextStyleDefaults(mode);
      return mode;
    } catch (_) {
      _syncTextStyleDefaults(ThemeMode.light);
      return ThemeMode.light;
    }
  }

  static void _syncTextStyleDefaults(ThemeMode mode) {
    AppTextStyles.defaultTextColor =
        mode == ThemeMode.light ? AppColors.ink : AppColors.crema;
  }
}
