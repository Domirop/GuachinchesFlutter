import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/login/login_sheet.dart';
import 'package:guachinches/ui/pages/restaurant_detail/review_moderation.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Flujo «⋯» de una reseña (tablero ResenasTodas): hoja de acciones
/// «Reportar reseña» / «Bloquear a <Nombre>», hoja de motivos, alerta de
/// bloqueo, alerta de invitado («Entra para reportar») y aviso final.
Future<void> openReviewActions(
  BuildContext context, {
  required Review review,
  required String restaurantName,
  ReviewModeration? moderation,
}) async {
  final mod = moderation ?? ReviewModeration.instance;
  HapticFeedback.selectionClick();
  final name = reviewAuthorName(review);
  final userId = await mod.currentUserId();
  if (!context.mounted) return;
  if (userId == null) {
    await _showGuestAlert(context,
        review: review, restaurantName: restaurantName);
    return;
  }
  final action = await _showActionSheet(context, name);
  if (!context.mounted || action == null) return;
  switch (action) {
    case _ReviewAction.report:
      final reason = await showModalBottomSheet<ReviewReportReason>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x52000000),
        builder: (_) => ReviewReportSheet(authorName: name),
      );
      if (reason == null || !context.mounted) return;
      mod.report(reviewId: review.id, reporterId: userId, reason: reason);
      showGmToast(context, 'Gracias. Ya no la verás.');
    case _ReviewAction.block:
      final ok = await _showBlockAlert(context, name);
      if (ok != true || !context.mounted) return;
      final done = await mod.block(
          userId: userId, blockedUserId: reviewAuthorId(review));
      if (!context.mounted) return;
      showGmToast(
        context,
        done
            ? 'Has bloqueado a $name.'
            : 'No pudimos bloquear a $name. Inténtalo de nuevo.',
        ok: done,
      );
  }
}

enum _ReviewAction { report, block }

// ── Hoja de acciones (estilo iOS) ──────────────────────────────────────────

Future<_ReviewAction?> _showActionSheet(BuildContext context, String name) {
  return showModalBottomSheet<_ReviewAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x52000000),
    elevation: 0,
    builder: (ctx) {
      final gm = GmColors.of(ctx);
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      Widget button(String label, String icon, Color color,
          {required VoidCallback onTap,
          FontWeight w = FontWeight.w400,
          String? identifier}) {
        return Semantics(
          identifier: identifier,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon.isNotEmpty) ...[
                    GmIcon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            height: 22 / 18,
                            fontWeight: w,
                            color: color)),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      Widget group(List<Widget> children) => GmGlass(
            borderRadius: BorderRadius.circular(26),
            tint: gm.isDark ? gm.card.withValues(alpha: 0.92) : gm.glass,
            edge: gm.glassEdge,
            blur: 30,
            shadow: const [
              BoxShadow(
                  color: Color(0x73000000),
                  offset: Offset(0, 20),
                  blurRadius: 50,
                  spreadRadius: -14),
            ],
            child: Material(
              type: MaterialType.transparency,
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          );

      return Semantics(
        identifier: 'restaurant-reviews-actions-sheet',
        container: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              group([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    children: [
                      Text('Reseña de $name',
                          textAlign: TextAlign.center,
                          style: GmText.eyebrow(color: gm.label)),
                      Text(
                          'Si incumple las normas, la revisamos y la retiramos.',
                          textAlign: TextAlign.center,
                          style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                Container(height: 1, color: gm.sep),
                button('Reportar reseña', _kFlagIcon, gm.accent,
                    identifier: 'restaurant-reviews-action-report',
                    onTap: () => Navigator.pop(ctx, _ReviewAction.report)),
                Container(height: 1, color: gm.sep),
                button('Bloquear a $name', _kBlockIcon, gm.closedText,
                    identifier: 'restaurant-reviews-action-block',
                    onTap: () => Navigator.pop(ctx, _ReviewAction.block)),
              ]),
              const SizedBox(height: 8),
              group([
                button('Cancelar', '', gm.accent,
                    w: FontWeight.w600,
                    identifier: 'restaurant-reviews-action-cancel',
                    onTap: () => Navigator.pop(ctx)),
              ]),
            ],
          ),
        ),
      );
    },
  );
}

final _kFlagIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
    'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" '
    'stroke-linejoin="round"><path d="M5 21V4"/><path d="M5 4h11l-2 4 2 4H5"/></svg>';
final _kBlockIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
    'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round">'
    '<circle cx="12" cy="12" r="8.5"/><path d="M6 6l12 12"/></svg>';

/// Bandera de «Reseña oculta».
String get reviewFlagIcon => _kFlagIcon;

// ── Hoja «Reportar reseña» ─────────────────────────────────────────────────

/// Motivos del reporte en lista agrupada con radio; «Enviar reporte» se
/// activa al elegir uno. Devuelve el motivo.
class ReviewReportSheet extends StatefulWidget {
  final String authorName;
  const ReviewReportSheet({super.key, required this.authorName});

  @override
  State<ReviewReportSheet> createState() => _ReviewReportSheetState();
}

class _ReviewReportSheetState extends State<ReviewReportSheet> {
  ReviewReportReason? _reason;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final name = widget.authorName;
    return Semantics(
      identifier: 'restaurant-reviews-report-sheet',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 30,
                offset: Offset(0, -10)),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, 8, 0, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                      color: gm.sep,
                      borderRadius: BorderRadius.circular(GmRadius.pill)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GmToolbarButton(
                      icon: GmIcons.close,
                      iconSize: 15,
                      light: true,
                      semanticLabel: 'Cerrar',
                      identifier: 'restaurant-reviews-report-close',
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text('Reportar reseña',
                            textAlign: TextAlign.center,
                            style: GmText.guideTitle(color: gm.label)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 2, 34, 16),
                child: Text('¿Qué le pasa a esta reseña de $name?',
                    textAlign: TextAlign.center,
                    style: GmText.body(color: gm.label2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GmCard(
                  child: Column(
                    children: [
                      for (final r in ReviewReportReason.values) ...[
                        if (r != ReviewReportReason.values.first)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Container(height: 1, color: gm.sep),
                          ),
                        _ReasonRow(
                          reason: r,
                          selected: _reason == r,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _reason = r);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
                child: Text(
                  '$name no sabrá que la has reportado. La ocultamos para ti '
                  'ahora y la revisamos en menos de 24 horas.',
                  style: GmText.meta(color: gm.label2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _reason == null
                    ? const GmSoftCapsuleButton(
                        label: 'Enviar reporte',
                        height: 54,
                        fontSize: 17,
                        identifier: 'restaurant-reviews-report-send',
                      )
                    : GmCapsuleButton(
                        label: 'Enviar reporte',
                        height: 54,
                        fontSize: 17,
                        identifier: 'restaurant-reviews-report-send',
                        onTap: () => Navigator.pop(context, _reason),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final ReviewReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonRow(
      {required this.reason, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-reviews-report-reason-${reason.code}',
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: reason.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(reason.label,
                    style: GmText.body17(color: gm.label, w: FontWeight.w500)
                        .copyWith(letterSpacing: -0.3)),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? GmColors.accentFill : null,
                  border:
                      selected ? null : Border.all(color: gm.sep, width: 1.5),
                ),
                alignment: Alignment.center,
                child: selected
                    ? GmIcon(GmIcons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alertas de cristal ─────────────────────────────────────────────────────

Future<T?> _showGlassAlert<T>(
  BuildContext context, {
  required String identifier,
  required String title,
  required List<Widget> body,
  required List<Widget> Function(BuildContext ctx) actions,
  bool column = false,
}) {
  final reduced = GmMotion.reduced(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: const Color(0x52000000),
    transitionDuration: Duration(milliseconds: reduced ? 0 : 220),
    transitionBuilder: (_, anim, __, child) {
      final t = GmMotion.settle.transform(anim.value);
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(scale: 1.08 - 0.08 * t, child: child),
      );
    },
    pageBuilder: (ctx, _, __) {
      final gm = GmColors.of(ctx);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Semantics(
              identifier: identifier,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: GmGlass(
                borderRadius: BorderRadius.circular(30),
                tint: gm.isDark ? gm.card.withValues(alpha: 0.94) : gm.glass,
                edge: gm.glassEdge,
                blur: 30,
                shadow: const [
                  BoxShadow(
                      color: Color(0x80000000),
                      offset: Offset(0, 30),
                      blurRadius: 70,
                      spreadRadius: -10),
                ],
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title,
                            textAlign: TextAlign.center,
                            style: GmText.body17(
                                    color: gm.label, w: FontWeight.w700)
                                .copyWith(height: 22 / 17)),
                        const SizedBox(height: 6),
                        ...body,
                        const SizedBox(height: 14),
                        if (column)
                          ...actions(ctx)
                        else
                          Row(
                            children: [
                              for (final (i, a) in actions(ctx).indexed) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(child: a),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Botón de alerta (48, cápsula).
class _AlertButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Gradient? gradient;
  final VoidCallback onTap;
  final String identifier;
  final double height;

  const _AlertButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.identifier,
    this.gradient,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: identifier,
        button: true,
        label: label,
        excludeSemantics: true,
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.96,
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: gradient == null ? background : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(GmRadius.pill),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foreground)),
          ),
        ),
      );
}

Future<bool?> _showBlockAlert(BuildContext context, String name) {
  final gm = GmColors.of(context);
  return _showGlassAlert<bool>(
    context,
    identifier: 'restaurant-reviews-block-alert',
    title: reviewBlockTitle(name),
    body: [
      Text(
          'Dejarás de ver sus reseñas y fotos en toda la app. No recibe '
          'ningún aviso.',
          textAlign: TextAlign.center,
          style: GmText.sub(color: gm.label)),
    ],
    actions: (ctx) => [
      _AlertButton(
        label: 'Cancelar',
        identifier: 'restaurant-reviews-block-cancel',
        background: GmColors.of(ctx).fill,
        foreground: GmColors.of(ctx).label,
        onTap: () => Navigator.pop(ctx, false),
      ),
      _AlertButton(
        label: 'Bloquear',
        identifier: 'restaurant-reviews-block-confirm',
        // badgeRed (#D6362A) con blanco: 4,7:1 en día y en noche.
        background: GmColors.badgeRed,
        foreground: Colors.white,
        onTap: () => Navigator.pop(ctx, true),
      ),
    ],
  );
}

Future<void> _showGuestAlert(
  BuildContext context, {
  required Review review,
  required String restaurantName,
}) async {
  final gm = GmColors.of(context);
  final choice = await _showGlassAlert<String>(
    context,
    identifier: 'restaurant-reviews-guest-alert',
    title: 'Entra para reportar',
    column: true,
    body: [
      Text(
          'Pedimos cuenta para evitar reportes falsos. Si es urgente, '
          'escríbenos y lo miramos igual.',
          textAlign: TextAlign.center,
          style: GmText.sub(color: gm.label)),
    ],
    actions: (ctx) {
      final g = GmColors.of(ctx);
      return [
        _AlertButton(
          label: 'Iniciar sesión',
          identifier: 'restaurant-reviews-guest-login',
          background: GmColors.atlantico,
          gradient: GmColors.accentFill,
          foreground: Colors.white,
          onTap: () => Navigator.pop(ctx, 'login'),
        ),
        const SizedBox(height: 8),
        _AlertButton(
          label: 'Escribir a soporte',
          identifier: 'restaurant-reviews-guest-support',
          background: g.fill,
          foreground: g.label,
          onTap: () => Navigator.pop(ctx, 'support'),
        ),
        const SizedBox(height: 4),
        _AlertButton(
          label: 'Ahora no',
          identifier: 'restaurant-reviews-guest-dismiss',
          background: Colors.transparent,
          foreground: g.label2,
          height: 44,
          onTap: () => Navigator.pop(ctx),
        ),
      ];
    },
  );
  if (!context.mounted) return;
  if (choice == 'login') {
    await showLoginSheet(context, reason: LoginReason.report);
  } else if (choice == 'support') {
    final uri = reviewSupportMailUri(
      restaurantName: restaurantName,
      authorName: reviewAuthorName(review),
      reviewId: review.id,
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        showGmToast(context, 'Escríbenos a $kReviewSupportEmail', ok: false);
      }
    } catch (e, st) {
      AppLogger.error('review-moderation', e, st);
      if (context.mounted) {
        showGmToast(context, 'Escríbenos a $kReviewSupportEmail', ok: false);
      }
    }
  }
}

// ── Aviso (toast) de cristal ───────────────────────────────────────────────

OverlayEntry? _toastEntry;
Timer? _toastTimer;

/// Aviso de cristal abajo («Gracias. Ya no la verás.»), 3 s. Candidato a
/// promover a `lib/ui/theme/`.
void showGmToast(BuildContext context, String text, {bool ok = true}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastTimer?.cancel();
  _toastEntry?.remove();
  final entry = OverlayEntry(
    builder: (ctx) {
      final gm = GmColors.of(ctx);
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Positioned(
        left: 16,
        right: 16,
        bottom: bottom + 16,
        child: IgnorePointer(
          child: Semantics(
            identifier: 'gm-toast',
            liveRegion: true,
            container: true,
            child: GmRise(
              trigger: GmTrigger.mount,
              child: GmGlass(
                borderRadius: BorderRadius.circular(GmRadius.pill),
                tint: gm.isDark ? gm.card.withValues(alpha: 0.94) : gm.glass,
                edge: gm.glassEdge,
                blur: 30,
                shadow: gm.shadow2,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GmIcon(ok ? GmIcons.check : GmIcons.warn,
                          size: 18, color: ok ? gm.greenText : gm.warnText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(text,
                            style: GmText.body(
                                color: gm.label, w: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  _toastEntry = entry;
  overlay.insert(entry);
  _toastTimer = Timer(const Duration(seconds: 3), () {
    if (_toastEntry == entry) {
      entry.remove();
      _toastEntry = null;
    }
  });
}
