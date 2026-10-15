import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Términos / Política de privacidad desde el onboarding: las mismas URL
/// que abre Ajustes, en una vista web con Cerrar de cristal.
class OnbLegalWebView extends StatefulWidget {
  final String url;
  final String title;

  const OnbLegalWebView({super.key, required this.url, required this.title});

  static Future<void> open(BuildContext context,
      {required String url, required String title}) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => OnbLegalWebView(url: url, title: title),
    ));
  }

  @override
  State<OnbLegalWebView> createState() => _OnbLegalWebViewState();
}

class _OnbLegalWebViewState extends State<OnbLegalWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Scaffold(
      backgroundColor: gm.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GmToolbarButton(
                    icon: GmIcons.close,
                    light: true,
                    onTap: () => Navigator.of(context).maybePop(),
                    semanticLabel: 'Cerrar',
                    identifier: 'onboarding-legal-close',
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.guideTitle(color: gm.label)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
