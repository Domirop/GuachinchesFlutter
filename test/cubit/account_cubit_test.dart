import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/account/account_state.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {
  final DateTime? _scheduledAt;
  final bool _cancelFails;
  final Map<String, dynamic>? _exportData;

  _FakeRepo({
    DateTime? scheduledAt,
    bool cancelFails = false,
    Map<String, dynamic>? exportData,
  })  : _scheduledAt = scheduledAt,
        _cancelFails = cancelFails,
        _exportData = exportData;

  @override
  Future<DateTime> requestAccountDeletion(String userId) async {
    if (_scheduledAt == null) throw Exception('HTTP 500');
    return _scheduledAt!;
  }

  @override
  Future<void> cancelAccountDeletion(String userId) async {
    if (_cancelFails) throw Exception('HTTP 500');
  }

  @override
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    if (_exportData == null) throw Exception('HTTP 500');
    return _exportData!;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const kUserId = 'user-42';
  final kScheduledAt = DateTime(2026, 7, 1);
  final kTempDir = Directory.systemTemp;

  group('AccountCubit', () {
    test('requestDeletion emits AccountDeletionScheduled with the returned DateTime',
        () async {
      final cubit = AccountCubit(
        repo: _FakeRepo(scheduledAt: kScheduledAt),
        userId: kUserId,
        getDir: () async => kTempDir,
      );

      await cubit.requestDeletion();

      expect(cubit.state, isA<AccountDeletionScheduled>());
      expect((cubit.state as AccountDeletionScheduled).scheduledAt, kScheduledAt);
    });

    test('cancelDeletion emits AccountIdle', () async {
      final cubit = AccountCubit(
        repo: _FakeRepo(scheduledAt: kScheduledAt),
        userId: kUserId,
        getDir: () async => kTempDir,
      );

      // Put cubit in a scheduled state first
      await cubit.requestDeletion();
      expect(cubit.state, isA<AccountDeletionScheduled>());

      await cubit.cancelDeletion();

      expect(cubit.state, isA<AccountIdle>());
    });

    test('exportData emits AccountExporting then AccountExportReady with correct filename',
        () async {
      final cubit = AccountCubit(
        repo: _FakeRepo(exportData: {'name': 'Test User', 'email': 't@e.com'}),
        userId: kUserId,
        getDir: () async => kTempDir,
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AccountExporting>(),
          isA<AccountExportReady>().having(
            (s) => s.file.path,
            'file path contains pattern',
            contains('mis-datos-dcc-$kUserId-'),
          ),
        ]),
      );

      cubit.exportData();
      await expectation;

      expect(cubit.state, isA<AccountExportReady>());
      final file = (cubit.state as AccountExportReady).file;
      expect(file.path, contains('mis-datos-dcc-$kUserId-'));
      expect(file.path, endsWith('.json'));
    });

    test('requestDeletion emits AccountError on HTTP failure', () async {
      final cubit = AccountCubit(
        repo: _FakeRepo(),
        userId: kUserId,
        getDir: () async => kTempDir,
      );

      await cubit.requestDeletion();

      expect(cubit.state, isA<AccountError>());
    });
  });
}
