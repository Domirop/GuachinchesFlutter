import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/canarismos.dart';

class CanarismoDetailScreen extends StatefulWidget {
  final Canarismo initial;

  const CanarismoDetailScreen({super.key, required this.initial});

  @override
  State<CanarismoDetailScreen> createState() => _CanarismoDetailScreenState();
}

class _CanarismoDetailScreenState extends State<CanarismoDetailScreen> {
  late Canarismo _current;
  int _shuffleSeed = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _shuffleSeed = DateTime.now().microsecondsSinceEpoch;
  }

  void _shuffle() {
    setState(() {
      _shuffleSeed += 997;
      _current = canarismoRandom(_shuffleSeed, actual: _current);
    });
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: '"${_current.palabra}" — ${_current.significado}\n\nvía Dónde Comer Canarias',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final initial =
        _current.palabra.isNotEmpty ? _current.palabra[0].toUpperCase() : '';

    return Semantics(
      identifier: 'canarismo-detail-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Semantics(
                  identifier: 'canarismo-detail-back',
                  button: true,
                  child: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: brand.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              // Bloque central (eyebrow + palabra con inicial de marca de agua
              // + significado) CENTRADO verticalmente, para que la pantalla no
              // se sienta vacía con un hueco en medio.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CANARISMO DEL DÍA',
                        style: AppTextStyles.eyebrow(
                          size: 11,
                          color: AppColors.atlantico,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Palabra protagonista con la inicial gigante detrás.
                      Semantics(
                        identifier: 'canarismo-detail-word',
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -44,
                              left: -10,
                              child: IgnorePointer(
                                child: Text(
                                  initial,
                                  style: AppTextStyles.displayHero(
                                    size: 200,
                                    color: AppColors.atlantico
                                        .withValues(alpha: 0.10),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '"${_current.palabra}"',
                              style: AppTextStyles.displayHero(
                                size: 44,
                                color: brand.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _current.significado,
                        style: AppTextStyles.editorial(
                          size: 17,
                          color: brand.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions + footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Share (primary pill)
                    Semantics(
                      identifier: 'canarismo-detail-share',
                      button: true,
                      child: GestureDetector(
                        onTap: _share,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.atlantico,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.ios_share,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Compartir',
                                style: AppTextStyles.ui(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Shuffle (secondary pill)
                    Semantics(
                      identifier: 'canarismo-detail-shuffle',
                      button: true,
                      child: GestureDetector(
                        onTap: _shuffle,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: brand.borderStrong),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shuffle_rounded,
                                size: 18,
                                color: brand.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Otra palabra',
                                style: AppTextStyles.ui(
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: brand.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Footer
                    Center(
                      child: Text(
                        'Diccionario del habla canaria · Dónde Comer Canarias',
                        style: AppTextStyles.muted(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
