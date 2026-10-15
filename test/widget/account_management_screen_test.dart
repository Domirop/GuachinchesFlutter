import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/account/account_state.dart';
import 'package:guachinches/ui/pages/profile/account_deletion_store.dart';
import 'package:guachinches/ui/pages/profile/account_management_screen.dart';

// ── Fake helpers ──────────────────────────────────────────────────────────────

class _NoOpRepo extends Fake implements RemoteRepository {}

/// Spy cubit: cuenta llamadas y emite lo que diga el test.
class _SpyAccountCubit extends AccountCubit {
  int exportCalls = 0;
  int requestDeletionCalls = 0;
  int cancelDeletionCalls = 0;
  AccountState? onRequest;
  AccountState? onExport;

  _SpyAccountCubit(AccountState seedState)
      : super(
          repo: _NoOpRepo(),
          userId: 'test-user',
          getDir: () async => Directory.systemTemp,
        ) {
    emit(seedState);
  }

  @override
  Future<void> exportData() async {
    exportCalls++;
    if (onExport != null) emit(onExport!);
  }

  @override
  Future<void> requestDeletion() async {
    requestDeletionCalls++;
    if (onRequest != null) emit(onRequest!);
  }

  @override
  Future<void> cancelDeletion() async {
    cancelDeletionCalls++;
    emit(const AccountIdle());
  }
}

final _now = DateTime(2026, 10, 14, 9, 41);

Widget _wrap(_SpyAccountCubit cubit) => MaterialApp(
      theme: appLightTheme,
      home: BlocProvider<AccountCubit>.value(
        value: cubit,
        child: AccountManagementScreen(clock: () => _now),
      ),
    );

Finder _id(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 4200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('Mi cuenta', () {
    testWidgets('normal: exportar y solicitar, sin aviso', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_wrap(_SpyAccountCubit(const AccountIdle())));
      await tester.pumpAndSettle();

      expect(find.text('Mi cuenta'), findsOneWidget);
      expect(_id('account-export-button'), findsOneWidget);
      expect(_id('account-delete-request-button'), findsOneWidget);
      expect(_id('account-delete-scheduled-banner'), findsNothing);
    });

    testWidgets('programada: aviso con fecha y «Cancelar eliminación»',
        (tester) async {
      _tall(tester);
      final cubit = _SpyAccountCubit(
          AccountDeletionScheduled(DateTime(2026, 11, 13, 10)));
      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      expect(_id('account-delete-scheduled-banner'), findsOneWidget);
      expect(find.text('Tu cuenta se eliminará el 13/11/2026'), findsOneWidget);
      expect(find.textContaining('Quedan 30 días.'), findsOneWidget);
      expect(find.textContaining('Lo pediste el 14/10/2026'), findsOneWidget);
      expect(_id('account-delete-cancel-button'), findsOneWidget);

      await tester.tap(_id('account-delete-cancel-button'));
      await tester.pumpAndSettle();
      expect(cubit.cancelDeletionCalls, 1);
      expect(_id('account-delete-scheduled-banner'), findsNothing);
      expect(await const AccountDeletionStore().read('test-user'), isNull);
    });

    testWidgets('la fecha guardada en el móvil se recupera al volver',
        (tester) async {
      _tall(tester);
      FlutterSecureStorage.setMockInitialValues({
        AccountDeletionStore.keyFor('test-user'):
            DateTime.utc(2026, 11, 13, 10).toIso8601String(),
      });
      await tester.pumpWidget(_wrap(_SpyAccountCubit(const AccountIdle())));
      await tester.pumpAndSettle();
      expect(_id('account-delete-scheduled-banner'), findsOneWidget);
      expect(_id('account-delete-cancel-button'), findsOneWidget);
    });

    testWidgets('exportar llama al cubit y muestra «Preparando el archivo…»',
        (tester) async {
      _tall(tester);
      final cubit = _SpyAccountCubit(const AccountIdle())
        ..onExport = const AccountExporting();
      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.tap(_id('account-export-button'));
      await tester.pump();
      expect(cubit.exportCalls, 1);
      expect(_id('account-export-loader'), findsOneWidget);
      expect(find.text('Preparando el archivo…'), findsOneWidget);
    });

    testWidgets('error al exportar: aviso sin detalle técnico', (tester) async {
      _tall(tester);
      final cubit = _SpyAccountCubit(const AccountIdle())
        ..onExport =
            const AccountError('Exception: exportUserData failed: 500');
      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.tap(_id('account-export-button'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo exportar'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('500'), findsNothing);
      // El aviso se va solo.
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo exportar'), findsNothing);
    });

    testWidgets('solicitar abre la hoja y confirmar programa la eliminación',
        (tester) async {
      _tall(tester);
      final cubit = _SpyAccountCubit(const AccountIdle())
        ..onRequest = AccountDeletionScheduled(DateTime(2026, 11, 13, 10));
      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.tap(_id('account-delete-request-button'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      expect(find.textContaining('13 de noviembre de 2026'), findsOneWidget);

      await tester.tap(_id('account-delete-confirm-button'));
      await tester.pumpAndSettle();
      expect(cubit.requestDeletionCalls, 1);
      expect(_id('account-delete-scheduled-banner'), findsOneWidget);
      expect(await const AccountDeletionStore().read('test-user'),
          DateTime(2026, 11, 13, 10).toUtc());
    });

    testWidgets('cancelar en la hoja no solicita nada', (tester) async {
      _tall(tester);
      final cubit = _SpyAccountCubit(const AccountIdle());
      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.tap(_id('account-delete-request-button'));
      await tester.pumpAndSettle();
      await tester.tap(_id('account-delete-dismiss-button'));
      await tester.pumpAndSettle();
      expect(cubit.requestDeletionCalls, 0);
      expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
    });
  });
}
