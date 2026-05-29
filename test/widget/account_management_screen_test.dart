import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/account/account_state.dart';
import 'package:guachinches/ui/pages/profile/account_management_screen.dart';

// ── Fake helpers ──────────────────────────────────────────────────────────────

class _NoOpRepo extends Fake implements RemoteRepository {
  @override
  Future<DateTime> requestAccountDeletion(String userId) async =>
      DateTime(2026, 7, 1);

  @override
  Future<void> cancelAccountDeletion(String userId) async {}

  @override
  Future<Map<String, dynamic>> exportUserData(String userId) async => {};
}

/// Spy cubit: overrides action methods to count calls without hitting IO.
class _SpyAccountCubit extends AccountCubit {
  int exportCalls = 0;
  int requestDeletionCalls = 0;
  int cancelDeletionCalls = 0;

  _SpyAccountCubit(AccountState seedState)
      : super(
          repo: _NoOpRepo(),
          userId: 'test-user',
          getDir: () async => Directory.systemTemp,
        ) {
    // Seed a specific state for scenario-based tests.
    // ignore: invalid_use_of_protected_member
    emit(seedState);
  }

  @override
  Future<void> exportData() async {
    exportCalls++;
  }

  @override
  Future<void> requestDeletion() async {
    requestDeletionCalls++;
  }

  @override
  Future<void> cancelDeletion() async {
    cancelDeletionCalls++;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(_SpyAccountCubit cubit) => MaterialApp(
      home: BlocProvider<AccountCubit>.value(
        value: cubit,
        child: const AccountManagementScreen(),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AccountManagementScreen', () {
    testWidgets('(a) AccountIdle shows both buttons and no banner',
        (tester) async {
      final cubit = _SpyAccountCubit(const AccountIdle());
      await tester.pumpWidget(_wrap(cubit));

      // Export button visible
      expect(find.bySemanticsLabel('account-export-button'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'account-export-button',
        ),
        findsOneWidget,
      );

      // Delete request button visible
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'account-delete-request-button',
        ),
        findsOneWidget,
      );

      // Banner NOT visible
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'account-delete-scheduled-banner',
        ),
        findsNothing,
      );
    });

    testWidgets(
        '(b) AccountDeletionScheduled shows banner with formatted date and cancel button',
        (tester) async {
      final cubit = _SpyAccountCubit(
        AccountDeletionScheduled(DateTime(2026, 7, 1)),
      );
      await tester.pumpWidget(_wrap(cubit));

      // Banner visible
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'account-delete-scheduled-banner',
        ),
        findsOneWidget,
      );

      // Banner contains formatted date
      expect(find.textContaining('01/07/2026'), findsOneWidget);

      // Cancel button visible
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'account-delete-cancel-button',
        ),
        findsOneWidget,
      );
    });

    testWidgets('(c) tap account-export-button calls exportData()',
        (tester) async {
      final cubit = _SpyAccountCubit(const AccountIdle());
      await tester.pumpWidget(_wrap(cubit));

      final exportButton = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'account-export-button',
      );
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pump();

      expect(cubit.exportCalls, 1);
    });

    testWidgets(
        '(d) tap account-delete-request-button opens confirm modal and confirming calls requestDeletion()',
        (tester) async {
      final cubit = _SpyAccountCubit(const AccountIdle());
      await tester.pumpWidget(_wrap(cubit));

      final deleteButton = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'account-delete-request-button',
      );
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm dialog appeared
      expect(find.text('Eliminar'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(cubit.requestDeletionCalls, 1);
    });
  });
}
