import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/register/register.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({Key key}) : super(key: key);

  @override
  _OnBoardingState createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  @override
  void initState() {
    final storage = new FlutterSecureStorage();
    storage.write(key: 'onBoardingFinished',value: 'true');
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover, // Ajusta la imagen para que cubra todo el Container
                      image: AssetImage("assets/images/onBoardingBg.png"))),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 172.0),
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                    image: AssetImage('assets/images/logoGrande.png'),
                                ),
                              borderRadius: BorderRadius.circular(20),

                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: SizedBox(
                            width: 250.0,
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                  fontSize: 30.0,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold
                              ),
                              child: AnimatedTextKit(
                                repeatForever: false,
                                animatedTexts: [
                                  TyperAnimatedText('Bienvenido,',textAlign: TextAlign.center,speed: Duration(milliseconds: 100)),
                                  TyperAnimatedText('tu viaje',textAlign: TextAlign.center,speed: Duration(milliseconds: 100)),
                                  TyperAnimatedText(
                                      'gastronómico',textAlign: TextAlign.center,speed: Duration(milliseconds: 100)),
                                  TyperAnimatedText(
                                      'comienza aquí',textAlign: TextAlign.center,speed: Duration(milliseconds: 140)),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 62.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width *0.72,
                    child: Column(
                      children: [
                        ElevatedButton(
                            onPressed: ()=>GlobalMethods().pushAndReplacement(context, Login('Introduce tus datos de inicio de sesión')),child: Text('Iniciar sesión',style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),),style: ButtonStyle(
                          shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // <-- Radius
                          ),),
                            minimumSize: MaterialStateProperty.all(Size.fromHeight(46)),
                            backgroundColor: MaterialStateProperty.all(Color.fromRGBO(0, 189, 195, 1)))),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton(
                              onPressed: ()=>GlobalMethods().pushAndReplacement(context, Register()),child: Text('Registrarse',style: TextStyle(
                              color: Color.fromRGBO(0, 189, 195, 1),
                              fontWeight: FontWeight.bold
                          ),),style: ButtonStyle(
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // <-- Radius
                              ),),
                              minimumSize: MaterialStateProperty.all(Size.fromHeight(46)),
                              backgroundColor: MaterialStateProperty.all(Colors.white))),
                        ),
                        TextButton(
                            onPressed: ()=>GlobalMethods().pushAndReplacement(context, SplashScreen())
                        , child: Text('Omitir',style: TextStyle(color: Colors.white,decoration: TextDecoration.underline),))
                      ],
                    ),
                  ),
                ),

              ],
            )
          ],
        ),
      ),
    );
  }
}
