import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';

void main() {
  group('AppRadius', () {
    test('sm == 12', () => expect(AppRadius.sm, 12.0));
    test('md == 16', () => expect(AppRadius.md, 16.0));
    test('lg == 22', () => expect(AppRadius.lg, 22.0));
    test('pill == 32', () => expect(AppRadius.pill, 32.0));
  });

  group('AppShadows.soft', () {
    test('returns non-empty list', () {
      expect(AppShadows.soft(), isNotEmpty);
    });

    test('blurRadius == 22', () {
      expect(AppShadows.soft().first.blurRadius, 22.0);
    });

    test('offset == Offset(0, 6)', () {
      expect(AppShadows.soft().first.offset, const Offset(0, 6));
    });
  });

  group('AppShadows.accent', () {
    test('returns non-empty list', () {
      expect(AppShadows.accent(AppColors.laurisilva), isNotEmpty);
    });

    test('blurRadius == 18', () {
      expect(AppShadows.accent(AppColors.laurisilva).first.blurRadius, 18.0);
    });

    test('offset == Offset(0, 6)', () {
      expect(AppShadows.accent(AppColors.laurisilva).first.offset,
          const Offset(0, 6));
    });

    test('color is derived from laurisilva (not black)', () {
      final shadow = AppShadows.accent(AppColors.laurisilva).first;
      expect(shadow.color, AppColors.laurisilva.withOpacity(0.08));
      expect(shadow.color, isNot(equals(Colors.black.withOpacity(0.08))));
    });
  });
}
