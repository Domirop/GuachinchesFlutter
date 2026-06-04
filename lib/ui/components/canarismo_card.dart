import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_detail_screen.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';

/// "Canarismo del día" — banner editorial en el feed del home.
/// Gradiente atlántico→ámbar, inicial gigante como marca de agua, palabra
/// protagonista + preview del significado, atajo de compartir y pie
/// "DESCÚBRELO Y COMPÁRTELO". Al tocar navega a [CanarismoDetailScreen].
class CanarismoCard extends StatelessWidget {
  const CanarismoCard({super.key});

  void _share(Canarismo c) {
    SharePlus.instance.share(
      ShareParams(
        text:
            '"${c.palabra}" — ${c.significado}\n\nvía Dónde Comer Canarias',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = canarismoOfDay();
    const cream = AppColors.crema;

    return Semantics(
      identifier: 'home-canarismo',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          gradient: kCanarismoGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          identifier: 'home-canarismo-toggle',
          button: true,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CanarismoDetailScreen(initial: c),
              ),
            ),
            child: Stack(
              children: [
                // Marca de agua: inicial gigante.
                Positioned(
                  right: -8,
                  top: -22,
                  child: IgnorePointer(
                    child: Text(
                      canarismoInitial(c.palabra),
                      style: AppTextStyles.displayHero(
                        size: 150,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'EL CANARISMO DEL DÍA',
                                  style: AppTextStyles.eyebrow(
                                    size: 11,
                                    color: cream.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.palabra.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.displayHero(
                                    size: 34,
                                    color: cream,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.significado,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.ui(
                                    size: 14,
                                    color: cream.withOpacity(0.88),
                                  ).copyWith(height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Atajo de compartir.
                          Semantics(
                            identifier: 'home-canarismo-share',
                            button: true,
                            child: GestureDetector(
                              onTap: () => _share(c),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.12),
                                      border: Border.all(
                                        color: cream.withOpacity(0.45),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.ios_share,
                                      size: 20,
                                      color: cream,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'COMPARTIR',
                                    style: AppTextStyles.eyebrow(
                                      size: 11,
                                      color: cream.withOpacity(0.7),
                                    ).copyWith(letterSpacing: 0.8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: cream.withOpacity(0.18),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'DESCÚBRELO Y COMPÁRTELO',
                            style: AppTextStyles.eyebrow(
                              size: 11,
                              color: AppColors.arena,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: cream.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
