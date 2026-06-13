import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';

/// Tarjeta de consentimiento RGPD para el newsletter. Se muestra **tras el
/// registro** (no antes): el opt-in es la acción afirmativa de pulsar
/// "Sí, suscribirme", desvinculada del registro y sin casilla premarcada.
///
/// `source`: origen del consentimiento ('onboarding' | 'settings'), para la
/// prueba RGPD del backend (migration 029).
Future<void> showNewsletterConsentSheet(
  BuildContext context, {
  required String userId,
  required NewsletterConsentService service,
  required String source,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (ctx) => _NewsletterConsentSheet(
      onChoice: (granted) async {
        await service.submit(
          userId: userId,
          granted: granted,
          source: source,
        );
        if (ctx.mounted) Navigator.of(ctx).pop();
      },
    ),
  );
}

class _NewsletterConsentSheet extends StatefulWidget {
  final Future<void> Function(bool granted) onChoice;
  const _NewsletterConsentSheet({required this.onChoice});

  @override
  State<_NewsletterConsentSheet> createState() =>
      _NewsletterConsentSheetState();
}

class _NewsletterConsentSheetState extends State<_NewsletterConsentSheet> {
  bool _busy = false;

  Future<void> _choose(bool granted) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onChoice(granted);
    // El sheet se cierra desde onChoice; si sigue montado, libera el estado.
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'newsletter-consent-sheet',
      child: Container(
        decoration: BoxDecoration(
          color: brand.base,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: brand.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.atlantico.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('📩', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Te mandamos las mejores aperturas y rutas?',
              style: AppTextStyles.displaySection(
                size: 20,
                color: brand.textPrimary,
              ).copyWith(height: 1.2),
            ),
            const SizedBox(height: 10),
            Text(
              'Recibe por email nuestras recomendaciones de dónde comer en '
              'Canarias. Sin spam, te das de baja cuando quieras.',
              style: AppTextStyles.ui(size: 14, color: brand.textSecondary)
                  .copyWith(height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Tratamos tus datos según nuestra Política de Privacidad.',
              style: AppTextStyles.ui(size: 12, color: brand.textMuted),
            ),
            const SizedBox(height: 24),
            // Opt-in: la acción afirmativa explícita.
            Semantics(
              identifier: 'newsletter-consent-accept',
              button: true,
              child: GestureDetector(
                onTap: () => _choose(true),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.atlantico,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Sí, suscribirme',
                          style: AppTextStyles.ui(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              identifier: 'newsletter-consent-decline',
              button: true,
              child: TextButton(
                onPressed: _busy ? null : () => _choose(false),
                child: Text(
                  'Ahora no',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: brand.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
