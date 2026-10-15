import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/account/account_state.dart';
import 'package:guachinches/ui/pages/profile/account_deletion_store.dart';
import 'package:guachinches/ui/pages/settings/perfil_logic.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Mi cuenta (tablero PerfilMiCuenta): exportar los datos y eliminar la
/// cuenta en una sola pantalla. La eliminación se confirma en una hoja y,
/// una vez programada, se ve el aviso con la fecha y «Cancelar eliminación»
/// (la fecha se guarda en el móvil: el perfil no la devuelve).
class AccountManagementScreen extends StatefulWidget {
  /// Inyectables para tests.
  final AccountDeletionStore store;
  final DateTime Function() clock;

  const AccountManagementScreen({
    super.key,
    this.store = const AccountDeletionStore(),
    this.clock = DateTime.now,
  });

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

enum _Action { export, request, cancel }

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  DateTime? _scheduledAt;
  _Action? _pending;
  PerfilToast? _toast;
  Timer? _toastTimer;
  bool _scrolled = false;

  AccountCubit get _cubit => context.read<AccountCubit>();

  @override
  void initState() {
    super.initState();
    final s = context.read<AccountCubit>().state;
    if (s is AccountDeletionScheduled) {
      _scheduledAt = s.scheduledAt;
      widget.store.save(context.read<AccountCubit>().userId, s.scheduledAt);
    } else {
      _restore();
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final at = await widget.store.read(_cubit.userId);
    if (!mounted || at == null) return;
    if (perfilDeletionActive(at, widget.clock())) {
      setState(() => _scheduledAt = at);
    } else {
      // Plazo vencido: el aviso ya no tiene sentido.
      await widget.store.clear(_cubit.userId);
    }
  }

  // ── Acciones ───────────────────────────────────────────────────────────

  void _export() {
    HapticFeedback.lightImpact();
    _hideToast();
    setState(() => _pending = _Action.export);
    _cubit.exportData();
  }

  void _request() {
    _hideToast();
    setState(() => _pending = _Action.request);
    _cubit.requestDeletion();
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    _hideToast();
    setState(() => _pending = _Action.cancel);
    _cubit.cancelDeletion();
  }

  Future<void> _confirmDeletion() async {
    HapticFeedback.mediumImpact();
    final at = widget.clock().add(kPerfilDeletionGrace);
    final ok = await showPerfilSheet<bool>(
      context,
      builder: (ctx) {
        final gm = GmColors.of(ctx);
        return PerfilConfirmSheet(
          identifier: 'account-delete-confirm-sheet',
          icon: PerfilIcons.trash,
          iconBackground: PerfilColors.closedSoft(gm),
          iconColor: gm.closedText,
          title: '¿Eliminar tu cuenta?',
          text: 'Se borrará el ${perfilDateLong(at, withYear: true)}, con tu '
              'nombre y tus reseñas. Hasta entonces puedes cancelarlo desde '
              'Mi cuenta.',
          actions: [
            PerfilDangerButton(
              label: 'Sí, eliminar mi cuenta',
              identifier: 'account-delete-confirm-button',
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            PerfilWideButton(
              label: 'Cancelar',
              secondary: true,
              identifier: 'account-delete-dismiss-button',
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) _request();
  }

  // ── Estado del cubit ───────────────────────────────────────────────────

  Future<void> _onState(BuildContext context, AccountState state) async {
    final userId = _cubit.userId;
    switch (state) {
      case AccountDeletionScheduled(:final scheduledAt):
        _pending = null;
        setState(() => _scheduledAt = scheduledAt);
        await widget.store.save(userId, scheduledAt);
      case AccountIdle():
        if (_pending == _Action.cancel) {
          _pending = null;
          setState(() => _scheduledAt = null);
          await widget.store.clear(userId);
        }
      case AccountExportReady(:final file):
        _pending = null;
        try {
          await SharePlus.instance.share(ShareParams(
            files: [XFile(file.path, mimeType: 'application/json')],
          ));
        } catch (e) {
          AppLogger.warn('mi-cuenta', 'no se pudo compartir el archivo: $e');
          _showError(_Action.export);
        }
      case AccountError(:final message):
        // El detalle técnico va al log, nunca a la pantalla.
        AppLogger.warn('mi-cuenta', 'error ($_pending): $message');
        _showError(_pending ?? _Action.export);
        if (mounted) setState(() => _pending = null);
      case AccountExporting():
        break;
    }
  }

  void _showError(_Action action) {
    if (!mounted) return;
    final (message, retry) = switch (action) {
      _Action.export => ('No se pudo exportar', _export),
      _Action.request => ('No se pudo solicitar la eliminación', _request),
      _Action.cancel => ('No se pudo cancelar la eliminación', _cancel),
    };
    _toastTimer?.cancel();
    setState(() => _toast = PerfilToast(
          identifier: 'account-error-toast',
          message: message,
          actionLabel: 'Reintentar',
          onAction: retry,
        ));
    _toastTimer = Timer(const Duration(seconds: 6), _hideToast);
  }

  void _hideToast() {
    _toastTimer?.cancel();
    if (mounted && _toast != null) setState(() => _toast = null);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    return BlocConsumer<AccountCubit, AccountState>(
      listener: _onState,
      builder: (context, state) {
        final exporting = state is AccountExporting;
        final now = widget.clock();
        final at = state is AccountDeletionScheduled
            ? state.scheduledAt
            : _scheduledAt;
        final scheduled = at != null;
        final busy = _pending == _Action.request || _pending == _Action.cancel;

        return Scaffold(
          backgroundColor: gm.canvas,
          body: Stack(
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
                      final s = n.metrics.pixels > 4;
                      if (s != _scrolled) setState(() => _scrolled = s);
                    }
                    return false;
                  },
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: media.padding.top + 58,
                      bottom: media.padding.bottom + 96,
                    ),
                    children: [
                      const GmRise(
                        trigger: GmTrigger.mount,
                        child: PerfilLargeTitle('Mi cuenta',
                            subtitle:
                                'Tus datos y la eliminación de tu cuenta.'),
                      ),
                      if (scheduled)
                        GmRise(
                          index: 1,
                          trigger: GmTrigger.mount,
                          child: _ScheduledBanner(scheduledAt: at, now: now),
                        ),
                      GmRise(
                        index: 2,
                        trigger: GmTrigger.mount,
                        child: _Section(
                          icon: PerfilIcons.doc,
                          iconBackground: gm.accentSoft,
                          iconColor: gm.accent,
                          title: 'Descargar mis datos',
                          text: 'Te preparamos un archivo con tu nombre, tu '
                              'email y tus reseñas (formato JSON) para que lo '
                              'guardes o lo envíes.',
                          action: exporting
                              ? Semantics(
                                  identifier: 'account-export-loader',
                                  liveRegion: true,
                                  child: PerfilSoftButton(
                                    label: 'Preparando el archivo…',
                                    leading: PerfilSpinner(color: gm.label2),
                                  ),
                                )
                              : PerfilSoftButton(
                                  label: 'Exportar mis datos',
                                  identifier: 'account-export-button',
                                  leading: GmIcon(PerfilIcons.share,
                                      size: 17, color: gm.accent),
                                  onTap: _export,
                                ),
                        ),
                      ),
                      GmRise(
                        index: 3,
                        trigger: GmTrigger.mount,
                        child: _Section(
                          icon: PerfilIcons.trash,
                          iconBackground: PerfilColors.closedSoft(gm),
                          iconColor: gm.closedText,
                          title: 'Eliminar mi cuenta',
                          text: scheduled
                              ? 'Lo pediste el '
                                  '${perfilDateShort(perfilDeletionRequestedAt(at))}. '
                                  'Si cambias de idea, cancélalo antes del '
                                  '${perfilDateShort(at)}.'
                              : 'Borramos tu cuenta, tu nombre y tus reseñas. '
                                  'Tienes 30 días para arrepentirte.',
                          action: scheduled
                              ? GmCapsuleButton(
                                  label: 'Cancelar eliminación',
                                  identifier: 'account-delete-cancel-button',
                                  leading: busy
                                      ? const PerfilSpinner(color: Colors.white)
                                      : null,
                                  onTap: busy ? null : _cancel,
                                )
                              : _RequestDeletionButton(
                                  busy: busy,
                                  onTap: busy ? null : _confirmDeletion,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Text(
                          'Tus guardados viven en este móvil: no forman parte '
                          'de la cuenta y no se borran con ella.',
                          style: GmText.meta(color: gm.label2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GmTopScrim(visible: _scrolled, extra: 60),
              Positioned(
                left: GmSpace.gutter,
                top: media.padding.top + 4,
                child:
                    const PerfilBackButton(identifier: 'account-back-button'),
              ),
              Positioned(
                left: GmSpace.gutter,
                right: GmSpace.gutter,
                bottom: media.padding.bottom + 16,
                child: PerfilToastSlot(toast: _toast),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduledBanner extends StatelessWidget {
  final DateTime scheduledAt;
  final DateTime now;
  const _ScheduledBanner({required this.scheduledAt, required this.now});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'account-delete-scheduled-banner',
      container: true,
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: gm.warnSoft,
          borderRadius: BorderRadius.circular(GmRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GmIcon(PerfilIcons.clock, size: 20, color: gm.warnText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu cuenta se eliminará el ${perfilDateShort(scheduledAt)}',
                    style: GmText.body17(color: gm.label, w: FontWeight.w600)
                        .copyWith(height: 22 / 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${perfilDaysLeftText(perfilDaysLeft(scheduledAt, now))} '
                    'Hasta entonces puedes cancelarlo aquí.',
                    style: GmText.body(color: gm.label),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una acción: icono + título 20/25, texto y botón.
class _Section extends StatelessWidget {
  final String icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String text;
  final Widget action;

  const _Section({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GmCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PerfilIconTile(
                    icon: icon, background: iconBackground, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: GmText.poster(color: gm.label)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(text,
                style: GmText.body(color: gm.label2).copyWith(height: 21 / 15)),
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }
}

/// «Solicitar eliminación»: cápsula roja suave (la roja llena se reserva a
/// la confirmación de la hoja).
class _RequestDeletionButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;
  const _RequestDeletionButton({required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'account-delete-request-button',
      button: true,
      enabled: onTap != null,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: PerfilColors.closedSoft(gm),
            borderRadius: BorderRadius.circular(GmRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? PerfilSpinner(color: gm.closedText)
                  : GmIcon(PerfilIcons.trash, size: 17, color: gm.closedText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Solicitar eliminación',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: gm.closedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
