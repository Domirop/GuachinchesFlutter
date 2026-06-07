import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';

/// Comparte un canarismo como **imagen 9:16 branded** (para Stories), igual que
/// hacen apps como Flighty. Renderiza [CanarismoShareCard] fuera de pantalla a
/// PNG y lo comparte por `share_plus`. Si la captura falla, cae a texto plano.
Future<void> shareCanarismoAsImage(
  BuildContext context,
  Canarismo c,
) async {
  final text = '"${c.palabra}" — ${c.significado}\n\nvía Dónde Comer Canarias';
  Analytics.I.logEvent(AnalyticsEvents.canarismoShared, {'palabra': c.palabra});
  try {
    final bytes = await _captureCard(
      context,
      CanarismoShareCard(canarismo: c),
      const Size(360, 640), // 9:16
      pixelRatio: 3, // → 1080×1920
    );
    if (bytes == null) {
      await SharePlus.instance.share(ShareParams(text: text));
      return;
    }
    final dir = await getTemporaryDirectory();
    final safe = _slug(c.palabra);
    final file = File('${dir.path}/canarismo_$safe.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile(file.path, mimeType: 'image/png')],
      ),
    );
  } catch (_) {
    // Fallback robusto: nunca dejar al usuario sin compartir.
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

String _slug(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.runes) {
    final c = String.fromCharCode(ch);
    if (RegExp(r'[a-z0-9]').hasMatch(c)) {
      buf.write(c);
    } else if (c == ' ') {
      buf.write('_');
    }
  }
  final out = buf.toString();
  return out.isEmpty ? 'canarismo' : out;
}

/// Renderiza [child] (de tamaño [size]) fuera de pantalla y devuelve su PNG.
Future<Uint8List?> _captureCard(
  BuildContext context,
  Widget child,
  Size size, {
  double pixelRatio = 3,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final repaintKey = GlobalKey();

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // Fuera de pantalla pero montado y pintado (RepaintBoundary crea su capa,
      // así que toImage la rasteriza aunque no esté visible).
      left: -9999,
      top: -9999,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: repaintKey,
          child: MediaQuery(
            data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Esperar a que el subárbol se asiente (layout + fuentes + pintura).
    await WidgetsBinding.instance.endOfFrame;
    var boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    var tries = 0;
    while ((boundary == null || boundary.debugNeedsPaint) && tries < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      tries++;
    }
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}

/// Tarjeta 9:16 para compartir en historias. Misma identidad que el detalle:
/// gradiente atlántico→ámbar, greca canaria, inicial de marca de agua.
class CanarismoShareCard extends StatelessWidget {
  final Canarismo canarismo;

  const CanarismoShareCard({super.key, required this.canarismo});

  @override
  Widget build(BuildContext context) {
    const cream = AppColors.crema;
    final initial = canarismoInitial(canarismo.palabra);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kCanarismoGradient),
      child: Stack(
        children: [
          // Marca de agua.
          Positioned(
            right: -30,
            bottom: 40,
            child: Text(
              initial,
              style: AppTextStyles.displayHero(
                size: 360,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marca.
                Text(
                  'DÓNDE COMER CANARIAS',
                  style: AppTextStyles.eyebrow(
                    size: 13,
                    color: cream,
                  ).copyWith(letterSpacing: 2.0),
                ),
                const SizedBox(height: 6),
                Text(
                  'EL CANARISMO DEL DÍA',
                  style: AppTextStyles.eyebrow(
                    size: 11,
                    color: cream.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                GrecaBand(color: cream.withOpacity(0.5), height: 16),
                const SizedBox(height: 22),
                Text(
                  '"${canarismo.palabra}"',
                  style: AppTextStyles.displayHero(size: 52, color: cream),
                ),
                const SizedBox(height: 18),
                Text(
                  canarismo.significado,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.editorial(
                    size: 18,
                    color: cream.withOpacity(0.92),
                  ).copyWith(height: 1.45),
                ),
                const SizedBox(height: 22),
                GrecaBand(color: cream.withOpacity(0.5), height: 16),
                const Spacer(),
                // Pie de marca.
                Row(
                  children: [
                    Icon(Icons.restaurant_rounded,
                        size: 16, color: cream.withOpacity(0.85)),
                    const SizedBox(width: 8),
                    Text(
                      'Diccionario del habla canaria',
                      style: AppTextStyles.ui(
                        size: 13,
                        color: cream.withOpacity(0.85),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
