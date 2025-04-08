import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/surveyDetails/surveyDetails.dart';

class SurveyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: ()=>GlobalMethods().pushPage(context, SurveyDetails()),
        child: Stack(
          children: [
            // Imagen de fondo
            Positioned.fill(
              child: Image.asset(
                'assets/images/images-beach.png', // Reemplaza con la URL de tu imagen
                fit: BoxFit.cover,
              ),
            ),
            // Capa oscura para el texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Contenido
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono del trofeo
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  // Texto principal
                  Text(
                    'Premios Donde Comer Canarias',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "SF Display Pro",
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Texto secundario
                  Text(
                    'Vota aquí!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: "SF Display Pro",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SurveyCard(),
  ));
}
