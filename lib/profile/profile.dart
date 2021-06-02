import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/profile/profile_presenter.dart';
import 'package:guachinches/splash_screen/splash_screen.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> implements ProfileView {
  final favKey = new GlobalKey();
  final levelKey = new GlobalKey();
  int indexSection = 0;

  List usersLevels = [
    {
      "nombre": "Pivito/Pivita",
      "descripcion":
          "Estas empezado, añade valoraciones para aumertar el nivel",
      "requisitos": "0",
    },
    {
      "nombre": "Muchacho/Muchacha",
      "descripcion": "A por el siguiente tu puedes, ya controlas del tema.",
      "requisitos": "2",
    },
    {
      "nombre": "Puntal",
      "descripcion":
          "Tu experiencia ayuda a los demas, eres uno/a de los grandes.",
      "requisitos": "4",
    },
    {
      "nombre": "Mago/Maga",
      "descripcion":
          "Tu experiencia ayuda a los demas, eres uno/a de los grandes.",
      "requisitos": "6"
    }
  ];

  List favs = [
    {
      "nombre": "Bodegón Mojo Picón",
      "especialidad": "Carnes de cerdo y ternera.",
      "direccion": "Calle Cecilio Marrero, 5A, Agua García.",
      "oferta": "Oferta en carne de cabra",
      "imagen": "assets/images/mojoPicon.png",
      "Valoracion": "4,6"
    },
    {
      "nombre": "Bodegón Mojo Picón",
      "especialidad": "Carnes de cerdo y ternera.",
      "direccion": "Calle Cecilio Marrero, 5A, Agua García.",
      "oferta": "Oferta en carne de cabra",
      "imagen": "assets/images/mojoPicon.png",
      "Valoracion": "4,6"
    }
  ];

  int userValorations = 3;
  ProfilePresenter _presenter;

@override
  void initState() {
    _presenter  = ProfilePresenter(this);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    double height = 0.0;
    double width = 0.0;
    if(MediaQuery.of(context).size.width < 330){
      width = 83.11;
    }else if(MediaQuery.of(context).size.width > 380){
      width = 102.0;
    }else{
      width = 90.9;
    }
    if(MediaQuery.of(context).size.height < 600){
      height = 69.11;
    }else if(MediaQuery.of(context).size.height > 700){
      height = 102.0;
    }else{
      height = 84.75;
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40.0,
              ),
              Text(
                "Mi perfil",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: height,
                    width: width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(49.5),
                      image: DecorationImage(
                        repeat: ImageRepeat.noRepeat,
                        alignment: Alignment.center,
                        fit: BoxFit.cover,
                        image: AssetImage('assets/images/logo.png'),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Canarygo1",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        Text(
                          "Alejandro Cruz Fernández",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                        Text(
                          "Puntal (4 Valoraciones)",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black,
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 45.0),
                width: double.infinity,
                child: RaisedButton(
                  onPressed: () => _presenter.logOut(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  color: Color.fromRGBO(222, 99, 44, 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10.0),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 25.0,
                        ),
                      ),
                      Text(
                        "Cerrar sesión",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => {
                      Scrollable.ensureVisible(levelKey.currentContext),
                      changeSectionIndex(0),
                    },
                    child: Container(
                      padding: EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.0),
                        color: indexSection == 0
                            ? Color.fromRGBO(254, 192, 75, 1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        "Nivel",
                        style: TextStyle(
                          color:
                              indexSection == 0 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => {
                      Scrollable.ensureVisible(favKey.currentContext),
                      changeSectionIndex(1),
                    },
                    child: Container(
                      padding: EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.0),
                        color: indexSection == 1
                            ? Color.fromRGBO(254, 192, 75, 1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        "Favoritos",
                        style: TextStyle(
                          color:
                          indexSection == 1 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
              SizedBox(
                height: 30.0,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      margin: EdgeInsets.only(top: 3.0),
                      child: Image.asset("assets/images/trophy.png")),
                  SizedBox(
                    width: 10.0,
                  ),
                  Expanded(
                    child: Column(
                      key: levelKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nivel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                        Text(
                          "El nivel se determina en base a las valoraciones realizadas en los ultimos 6 meses.",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: usersLevels.length,
                  itemBuilder: (context, index) {
                    return getCardLevel(index);
                  }),
              Row(
                key: favKey,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 15.0,
                    color: Colors.black,
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text(
                    "Guachinches favoritos",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
              ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: favs.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80.0,
                            height: 80.0,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                repeat: ImageRepeat.noRepeat,
                                alignment: Alignment.center,
                                fit: BoxFit.cover,
                                image: AssetImage(favs[index]["imagen"]),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  favs[index]["nombre"],
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  favs[index]["especialidad"],
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12.0),
                                ),
                                SizedBox(
                                  height: 2.0,
                                ),
                                Text(
                                  favs[index]["direccion"],
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12.0),
                                ),
                                SizedBox(
                                  height: 2.0,
                                ),
                                Text(
                                  favs[index]["oferta"],
                                  style: TextStyle(
                                      color: Color.fromRGBO(226, 120, 120, 1),
                                      fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(149, 194, 55, 1),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              favs[index]["Valoracion"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  getCardLevel(index) {
    Color textColor;
    Color background;
    if (usersLevels.length - 1 > index) {
      textColor =
          int.parse(usersLevels[index + 1]["requisitos"]) <= userValorations
              ? Colors.black
              : int.parse(usersLevels[index]["requisitos"]) > userValorations
                  ? Colors.black
                  : Colors.white;
      background =
          int.parse(usersLevels[index + 1]["requisitos"]) <= userValorations
              ? Colors.white
              : int.parse(usersLevels[index]["requisitos"]) > userValorations
                  ? Colors.white
                  : Color.fromRGBO(254, 192, 75, 1);
    } else {
      textColor = int.parse(usersLevels[index]["requisitos"]) <= userValorations
          ? Colors.white
          : Colors.black;
      background =
          int.parse(usersLevels[index]["requisitos"]) <= userValorations
              ? Color.fromRGBO(254, 192, 75, 1)
              : Colors.white;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
      margin: EdgeInsets.only(bottom: 15.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(1, 4), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usersLevels[index]["nombre"],
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Text(
                  usersLevels[index]["descripcion"],
                  style: TextStyle(color: textColor, fontSize: 12.0),
                ),
              ],
            ),
          ),
          Text(
            "+" + usersLevels[index]["requisitos"] + " Valoraciones",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  changeSectionIndex(index) {
    setState(() {
      indexSection = index;
    });
  }
  goSplashScreen(){
    print("TU PRIMO");
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }
}
