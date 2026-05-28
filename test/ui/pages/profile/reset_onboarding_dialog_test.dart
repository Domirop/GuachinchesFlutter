import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_state.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _NullStorage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      null;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}

/// Hand-rolled spy cubit — counts reset() invocations without touching storage.
class _SpyCubit extends OnboardingCubit {
  int resetCount = 0;

  _SpyCubit() : super(storage: _NullStorage()) {
    emit(const OnboardingLoaded(OnboardingData(
      finished: false,
      tastes: [],
      locationAsked: false,
      surveyShown: false,
    )));
  }

  @override
  Future<void> reset() async {
    resetCount++;
  }
}

// ── Test widget ───────────────────────────────────────────────────────────────

/// Minimal widget that replicates the reset-onboarding button + dedicated
/// dialog from profile_v2.dart. Uses the exact same Semantics identifiers.
class _ResetButtonWidget extends StatelessWidget {
  const _ResetButtonWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          identifier: 'profile-reset-onboarding-button',
          child: ElevatedButton(
            onPressed: () => _onTap(context),
            child: const Text('Reiniciar onboarding'),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Semantics(
        identifier: 'reset-onboarding-confirm-dialog',
        child: AlertDialog(
          title: const Text('¿Resetear onboarding?'),
          content: const Text(
              'Se borrarán tus preferencias y volverás a la pantalla de bienvenida.'),
          actions: [
            Semantics(
              identifier: 'reset-onboarding-cancel-cta',
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancelar'),
              ),
            ),
            Semantics(
              identifier: 'reset-onboarding-confirm-cta',
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Resetear'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      context.read<OnboardingCubit>().reset();
    }
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────

Finder _byIdentifier(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Widget _wrap(_SpyCubit cubit) => BlocProvider<OnboardingCubit>.value(
      value: cubit,
      child: const MaterialApp(home: _ResetButtonWidget()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('reset-onboarding dialog', () {
    testWidgets(
        '(a) tap profile-reset-onboarding-button shows '
        'reset-onboarding-confirm-dialog', (tester) async {
      final cubit = _SpyCubit();
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(_byIdentifier('profile-reset-onboarding-button'));
      await tester.pumpAndSettle();

      expect(_byIdentifier('reset-onboarding-confirm-dialog'), findsOneWidget);
      expect(find.text('¿Resetear onboarding?'), findsOneWidget);
    });

    testWidgets(
        '(b) tap reset-onboarding-cancel-cta closes dialog without '
        'calling cubit.reset()', (tester) async {
      final cubit = _SpyCubit();
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(_byIdentifier('profile-reset-onboarding-button'));
      await tester.pumpAndSettle();

      await tester.tap(_byIdentifier('reset-onboarding-cancel-cta'));
      await tester.pumpAndSettle();

      expect(_byIdentifier('reset-onboarding-confirm-dialog'), findsNothing);
      expect(cubit.resetCount, 0);
    });

    testWidgets(
        '(c) tap reset-onboarding-confirm-cta invokes cubit.reset() '
        'exactly once', (tester) async {
      final cubit = _SpyCubit();
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(_byIdentifier('profile-reset-onboarding-button'));
      await tester.pumpAndSettle();

      await tester.tap(_byIdentifier('reset-onboarding-confirm-cta'));
      await tester.pumpAndSettle();

      expect(cubit.resetCount, 1);
    });
  });
}
