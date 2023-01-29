import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/qr_scanner/qr_full_screen.dart';
import 'package:guachinches/ui/pages/details/details.dart';
import 'package:guachinches/ui/pages/profile/profile_presenter.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:http/http.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> implements ProfileView {
  final favKey = new GlobalKey();
  final levelKey = new GlobalKey();
  final cuponesKey = new GlobalKey();
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

  List<Restaurant> favs = [];
  List<Cupones> cupones = [];

  List<RestaurantSQLLite> restaurantSql = [];

  RemoteRepository remoteRepository;
  ProfilePresenter _presenter;

  @override
  void initState() {
    final userCubit = context.read<UserCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    _presenter = ProfilePresenter(this, userCubit, remoteRepository);
    _presenter.getUserInfo();
    _presenter.getRestaurantsFavs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = 0.0;
    double width = 0.0;
    if (MediaQuery.of(context).size.width < 330) {
      width = 83.11;
    } else if (MediaQuery.of(context).size.width > 380) {
      width = 102.0;
    } else {
      width = 90.9;
    }
    if (MediaQuery.of(context).size.height < 600) {
      height = 69.11;
    } else if (MediaQuery.of(context).size.height > 700) {
      height = 102.0;
    } else {
      height = 84.75;
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: BlocBuilder<UserCubit, UserState>(builder: (context, state) {
            if (state is UserLoaded) {
              return Column(
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
                              state.user.nombre,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            Text(
                              state.user.email,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                              ),
                            ),
                            Text(
                              state.user.valoraciones.length.toString() +
                                  " Valoracion/es",
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
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 45.0),
                    width: double.infinity,
                    child: RaisedButton(
                      onPressed: () => _presenter.deleteAccount(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      color: Color.fromRGBO(242, 62, 74, 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 10.0),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 25.0,
                            ),
                          ),
                          Text(
                            "Eliminar usuario",
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
                      cupones.isNotEmpty ? GestureDetector(
                        onTap: () => {
                          Scrollable.ensureVisible(context),
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
                            "Cupones",
                            style: TextStyle(
                              color: indexSection == 0
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ) : Container(),
                      GestureDetector(
                        onTap: () => {
                          Scrollable.ensureVisible(levelKey.currentContext),
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
                            "Nivel",
                            style: TextStyle(
                              color: indexSection == 1
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => {
                          Scrollable.ensureVisible(favKey.currentContext),
                          changeSectionIndex(2),
                        },
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7.0),
                            color: indexSection == 2
                                ? Color.fromRGBO(254, 192, 75, 1)
                                : Colors.transparent,
                          ),
                          child: Text(
                            "Favoritos",
                            style: TextStyle(
                              color: indexSection == 2
                                  ? Colors.white
                                  : Colors.black,
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
                  Text("Tus Cupones", key: cuponesKey, style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),),
                  ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: cupones.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => GlobalMethods().pushPage(context, QrFullScreen(cupones[index], state.user)),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            width: MediaQuery.of(context).size.width * 0.95,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 110,
                                      margin: EdgeInsets.only(right: 10),
                                      width: MediaQuery.of(context).size.width * 0.30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        image: DecorationImage(
                                          repeat: ImageRepeat.noRepeat,
                                          alignment: Alignment.center,
                                          fit: BoxFit.fill,
                                          image: cupones[index].fotoUrl != null
                                              ? NetworkImage(cupones[index].fotoUrl)
                                              : AssetImage("assets/images/notImage.png"),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.6,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cupones[index].restaurantName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              cupones[index].date,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Obtén un descuento del " +
                                                  cupones[index].descuento.toString() +
                                                  "%",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Color.fromRGBO(149, 220, 0, 1),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _presenter.removeCupon(cupones[index].cuponesUsuarioId);
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        color: Color.fromRGBO(226, 120, 120, 1),
                                        size: 30.0,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 10,
                                )
                              ],
                            ),
                          ),
                        );
                      }),
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
                        return getCardLevel(
                            index, state.user.valoraciones.length);
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
                  SizedBox(
                    height: 10.0,
                  ),
                  favs.isNotEmpty
                      ? Column(
                          children: favs.map((e) {
                            Fotos foto = e.fotos.firstWhere(
                                (element) => element.type == "principal",
                                orElse: () => null);
                            return GestureDetector(
                              onTap: () => GlobalMethods().pushPage(context, Details(e.id)),
                              child: Container(
                                margin: EdgeInsets.only(bottom: 15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 80.0,
                                      height: 80.0,
                                      margin: EdgeInsets.only(right: 10.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12.0),
                                        image: DecorationImage(
                                          repeat: ImageRepeat.noRepeat,
                                          alignment: Alignment.center,
                                          fit: BoxFit.contain,
                                          image: foto.photoUrl != null
                                              ? NetworkImage(foto.photoUrl)
                                              : AssetImage(
                                                  "assets/images/notImage.png"),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.only(right: 10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.nombre == null ? "" : e.nombre,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(
                                              height: 5.0,
                                            ),
                                            Text(
                                              e.telefono != null
                                                  ? e.telefono
                                                  : "",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0),
                                            ),
                                            SizedBox(
                                              height: 2.0,
                                            ),
                                            Text(
                                              e.direccion != null
                                                  ? e.direccion
                                                  : "",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12.0),
                                            ),
                                            Text(
                                              e.destacado != null
                                                  ? e.destacado
                                                  : "",
                                              style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      226, 120, 120, 1),
                                                  fontSize: 12.0),
                                            ),
                                            SizedBox(
                                              height: 2.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    e.avgRating == null
                                        ? Container()
                                        : Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.0, vertical: 2.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  Color.fromRGBO(149, 194, 55, 1),
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            child: Text(
                                              e.avgRating.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Center(
                          child: Text(
                            "Añade nuevos guachinches a favoritos",
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              );
            } else {
              return Container();
            }
          }),
        ),
      ),
    );
  }

  getCardLevel(index, userValorations) {
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

  setFavsFilter(List<Restaurant> restaurants) {
    List<Restaurant> aux = [];
    restaurantSql.forEach((element) {
      Restaurant restaurant = restaurants.firstWhere(
          (rest) => rest.id == element.restaurantId,
          orElse: () => null);
      if (restaurant != null) {
        aux.add(restaurant);
      }
    });
    return aux;
  }

  changeSectionIndex(index) {
    setState(() {
      indexSection = index;
    });
  }

  goSplashScreen() {
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }

  @override
  updateListSql(List<Restaurant> restaurants) {
    this.setState(() {
      favs = restaurants;
    });
  }

  @override
  updateCupones(List<Cupones> cupones) {
    if(mounted){
      setState(() {
        this.cupones = cupones;
      });
    }
  }
}
