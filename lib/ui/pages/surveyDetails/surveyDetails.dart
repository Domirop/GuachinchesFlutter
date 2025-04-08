import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/surveyDetails/surveyDetailsPresenter.dart';
import 'package:http/http.dart';
import '../web_encuesta/PoolWebView.dart';

class SurveyDetails extends StatefulWidget {
  final VoidCallback? onRefresh;

  SurveyDetails({Key? key, this.onRefresh}) : super(key: key);

  @override
  _SurveyDetailsState createState() => _SurveyDetailsState();
}

class _SurveyDetailsState extends State<SurveyDetails> implements SurveyDetailsView {
  Color bgColor = const Color.fromRGBO(25, 27, 32, 1);
  late RemoteRepository remoteRepository;
  late SurveyDetailsPresenter _presenter;
  String userId = "";

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    _presenter = SurveyDetailsPresenter(remoteRepository, this);
    _presenter.getUserSurveyId();
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'Hacer la encuesta';
    VoidCallback? onPressed = () {
      GlobalMethods().pushAndReplacement(
        context,
        WebViewPool(userId, widget.onRefresh,false),
      );
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color.fromRGBO(25, 27, 32, 1)],
                      stops: [0.5, 1.0],
                    ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                  },
                  blendMode: BlendMode.darken,
                  child: Image.asset(
                    'assets/images/images-beach.png',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.black.withOpacity(0.5),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Premios donde Comer Canarias 2025",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: Color.fromRGBO(208, 221, 255, 1), thickness: 0.4),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presentamos los premios Donde Comer Canarias 2025. Puedes votar ya en las siguientes categorías:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      fontFamily: "SF Pro Display",
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    'Mejor Guachinche Tradicional',
                    'Mejor Guachinche Moderno',
                  ].map((category) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '• $category',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontFamily: "SF Pro Display",
                      ),
                    ),
                  )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: onPressed == null
                    ? Colors.grey
                    : const Color.fromRGBO(0, 255, 102, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "SF Pro Display",
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  setUserSurveyId(String surveyUserId) {
    setState(() {
      userId = surveyUserId;
    });
  }
}
