import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Valoraciones extends StatefulWidget {
  @override
  _ValoracionesState createState() => _ValoracionesState();
}

class _ValoracionesState extends State<Valoraciones> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 50.0,
            ),
            ValoracionesComponent("Mis Valoraciones"),
          ],
        ),
      ),
    );
  }
}

class ValoracionesComponent extends StatelessWidget {
  String title;

  ValoracionesComponent(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 15.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              RaisedButton(
                onPressed: () => {},
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.0),
                ),
                color: Color.fromRGBO(222, 99, 44, 1),
                child: Text(
                  "+ Añadir valoración",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
          Container(
            height: 20,
            margin: EdgeInsets.only(left: 30.0),
            width: 90.0,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_outlined,
                  size: 10.0,
                ),
                Text(
                  "Mas Recientes",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            margin: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black54,
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    offset: Offset(2.0, 4.0))
              ],
              borderRadius: BorderRadius.circular(17.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "\"Espectacular\"",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '5.0',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Icon(
                              Icons.star,
                              color: Color.fromRGBO(254, 192, 75, 1),
                              size: 30.0,
                            ),
                            Icon(
                              Icons.star,
                              color: Color.fromRGBO(254, 192, 75, 1),
                              size: 30.0,
                            ),
                            Icon(
                              Icons.star,
                              color: Color.fromRGBO(254, 192, 75, 1),
                              size: 30.0,
                            ),
                            Icon(
                              Icons.star,
                              color: Color.fromRGBO(254, 192, 75, 1),
                              size: 30.0,
                            ),
                            Icon(
                              Icons.star_half,
                              color: Color.fromRGBO(254, 192, 75, 1),
                              size: 30.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Editar valoración",
                          style: TextStyle(
                            color: Color.fromRGBO(254, 192, 75, 1),
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          "Bodegón mojo picón",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                          ),
                        ),
                        Text(
                          "20/02/2021",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  children: [
                    Container(
                      height: 56.0,
                      width: 56.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          repeat: ImageRepeat.noRepeat,
                          alignment: Alignment.center,
                          fit: BoxFit.cover,
                          image: AssetImage('assets/images/escaldon.png'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Container(
                      height: 56.0,
                      width: 56.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          repeat: ImageRepeat.noRepeat,
                          alignment: Alignment.center,
                          fit: BoxFit.cover,
                          image: AssetImage('assets/images/escaldon.png'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  "La comida es una pasada, trato cuidado y mucha limpieza vale la pena probarlo es uno de los mejores guachinches de la isla.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.0,
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  "Ver más",
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Color.fromRGBO(222, 99, 44, 1),
                    decoration: TextDecoration.underline,
                    decorationColor: Color.fromRGBO(222, 99, 44, 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
