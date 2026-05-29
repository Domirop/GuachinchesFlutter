import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/account/account_state.dart';
import 'package:path_provider/path_provider.dart';

class AccountCubit extends Cubit<AccountState> {
  final RemoteRepository _repo;
  final String userId;
  final Future<Directory> Function() _getDir;

  AccountCubit({
    required RemoteRepository repo,
    required this.userId,
    Future<Directory> Function()? getDir,
  })  : _repo = repo,
        _getDir = getDir ?? getTemporaryDirectory,
        super(const AccountIdle());

  Future<void> requestDeletion() async {
    try {
      final scheduledAt = await _repo.requestAccountDeletion(userId);
      emit(AccountDeletionScheduled(scheduledAt));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> cancelDeletion() async {
    try {
      await _repo.cancelAccountDeletion(userId);
      emit(const AccountIdle());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> exportData() async {
    emit(const AccountExporting());
    try {
      final data = await _repo.exportUserData(userId);
      final dir = await _getDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/mis-datos-dcc-$userId-$timestamp.json');
      await file.writeAsString(jsonEncode(data));
      emit(AccountExportReady(file));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
}
