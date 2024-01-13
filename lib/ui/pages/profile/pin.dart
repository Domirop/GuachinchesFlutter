import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';

class PinDetail extends StatefulWidget {
  final String title;
  final String asset;
  final String description;
  const PinDetail({Key? key, required this.title, required this.asset, required this.description})
      : super(key: key);

  @override
  State<PinDetail> createState() => _PinDetailState();
}

class _PinDetailState extends State<PinDetail> {
  final ConfettiController confettiController;
  _PinDetailState() : confettiController = ConfettiController(duration: const Duration(seconds: 2),);

  @override
  void initState() {
    confettiController.play();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color.fromRGBO(22, 22, 22, 1),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                  // Icono de cierre (X)
                  onPressed: () {
                    // Agrega aquí la lógica para cerrar la página
                    GlobalMethods().popPage(context);
                  },
                ),
              ),
            ],
            title: Text(
              'Pin Exclusivo',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    widget
                        .asset, // Reemplaza 'assets/icono.svg' con la ubicación de tu archivo SVG
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    widget.title,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 72.0),
                    child: Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color.fromRGBO(168, 168, 168, 1), fontSize: 16,),
                    ),
                  ),
                ),
                SizedBox(height: 16,),
                Text("Conseguido el:",style: TextStyle(color: Colors.white),),
                Text("22 Sep 23",style: TextStyle(color: Colors.white),),
                SizedBox(height: 32,),
                Container(
                  width: MediaQuery.of(context).size.width*0.72,
                  child: ElevatedButton(
                    onPressed: () => {},
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // <-- Radius
                        ),),
                        minimumSize: MaterialStateProperty.all(Size.fromHeight(48)),
                        backgroundColor: MaterialStateProperty.all(Color.fromRGBO(0, 189, 195, 1))),

                    child:Text(
                      "Compartir",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16.0),
                    ),
                  ),
                ),
              ],
            ),
          )),

        Align(
          alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: confettiController,
              blastDirection: pi/2,
             shouldLoop: false,
             )),
      ]
    );
  }
}
