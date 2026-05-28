import 'dart:io';

sealed class AccountState {
  const AccountState();
}

final class AccountIdle extends AccountState {
  const AccountIdle();
}

final class AccountDeletionScheduled extends AccountState {
  final DateTime scheduledAt;
  const AccountDeletionScheduled(this.scheduledAt);
}

final class AccountExporting extends AccountState {
  const AccountExporting();
}

final class AccountExportReady extends AccountState {
  final File file;
  const AccountExportReady(this.file);
}

final class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);
}
