import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:guachinches/ui/pages/surveyDetails/surveyDetails.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPool extends StatefulWidget {
  final String userId;
  final VoidCallback? onRefresh;
  final bool toSplashScreen;
  WebViewPool(this.userId,this.onRefresh,this.toSplashScreen);

  @override
  State<WebViewPool> createState() => _WebViewPoolState();
}

class _WebViewPoolState extends State<WebViewPool> {
  late final WebViewController controller;

  @override
  void initState() {

    print("userID "+widget.userId);
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(
          'https://encuesta.guachinchesmodernos.com?user_id=' + widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Encuesta',
          style: TextStyle(fontFamily: "SF Pro Display"),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if(widget.onRefresh != null) {
              widget.onRefresh!.call();
            }
            if(widget.toSplashScreen != null) {
                if(widget.toSplashScreen) {
                  GlobalMethods().pushAndReplacement(context, SplashScreen());
                return;
                }
              }
            GlobalMethods().pushAndReplacement(context, SurveyDetails(onRefresh: widget.onRefresh,));
          },
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

class MyNextPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Siguiente'),
      ),
      body: const Center(
        child: Text('Esta es la página a la que navegas al presionar atrás.'),
      ),
    );
  }
}
