import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

// TODO(backend): Sustituir por las URLs reales cuando el backend las exponga.
const kPerfilTermsUrl = 'https://dondecomercanarias.com/terminos';
const kPerfilPrivacyUrl = 'https://dondecomercanarias.com/privacidad';

/// Términos y privacidad dentro de la app (WebView) con la barra del
/// rediseño: botón «Cerrar» de cristal y título centrado sobre el lienzo.
class LegalWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const LegalWebViewScreen({super.key, required this.url, required this.title});

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (e) {
          // Solo cuenta el documento principal (no imágenes ni scripts).
          if (e.isForMainFrame == false) return;
          if (mounted) {
            setState(() {
              _loading = false;
              _failed = true;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: gm.canvas,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 4, 16, 8),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  GmToolbarButton(
                    icon: GmIcons.close,
                    iconSize: 16,
                    light: true,
                    semanticLabel: 'Cerrar',
                    identifier: 'legal-close-button',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GmText.body17(color: gm.label, w: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(GmRadius.card)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      identifier: 'legal-webview',
                      child: WebViewWidget(controller: _controller),
                    ),
                  ),
                  if (_loading)
                    Positioned.fill(
                      child: ColoredBox(
                        color: gm.canvas,
                        child: Center(child: PerfilSpinner(color: gm.label2)),
                      ),
                    ),
                  if (_failed)
                    Positioned.fill(
                      child: ColoredBox(
                        color: gm.canvas,
                        child: Center(
                          child: PerfilStateCard(
                            identifier: 'legal-error',
                            art: const GmSadVolcano(width: 96),
                            title: 'No pudimos abrir la página',
                            text: 'Revisa tu conexión e inténtalo de nuevo.',
                            action: GmCapsuleButton(
                              label: 'Reintentar',
                              identifier: 'legal-retry-button',
                              onTap: _retry,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
