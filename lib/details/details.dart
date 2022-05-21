import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/details/details_presenter.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/new_review/new_review.dart';
import 'package:guachinches/photo_full_screen/photo_full_screen.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/HttpRemoteRepository.dart';
import '../data/RemoteRepository.dart';
import '../login/login.dart';
import '../model/fotos.dart';

class Details extends StatefulWidget {
  final Restaurant restaurant;

  Details(this.restaurant);

  @override
  _DetailsState createState() => _DetailsState(restaurant);
}

class _DetailsState extends State<Details> implements DetailView {
  String userId;

  _DetailsState(this.restaurant);

  bool isFav = false;
  Restaurant restaurant;
  int indexCarta = 0;
  int indexValoraciones = 0;
  int indexSection = 0;
  DetailPresenter presenter;
  RemoteRepository remoteRepository;
  final cardKey = GlobalKey();
  final detailsKey = GlobalKey();
  final reviewsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = DetailPresenter(remoteRepository, this);
    presenter.isUserLogged();
    presenter.getIsFav(restaurant.id);
  }

  @override
  Widget build(BuildContext context) {
    Fotos foto = restaurant.fotos.firstWhere(
        (element) => element.type == "principal",
        orElse: () => null);
    String mainFoto = foto != null ? foto.photoUrl : null;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 350.0,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                    image: DecorationImage(
                      repeat: ImageRepeat.noRepeat,
                      alignment: Alignment.center,
                      fit: BoxFit.cover,
                      image: mainFoto == null
                          ? AssetImage('assets/images/bigNotImage.png')
                          : NetworkImage(mainFoto),
                    ),
                  ),
                ),
                Positioned(
                  top: 40.0,
                  left: 15.0,
                  child: GestureDetector(
                    onTap: () => GlobalMethods().popPage(context),
                    child: Container(
                      width: 40.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 40.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40.0,
                  right: 15.0,
                  child: GestureDetector(
                    onTap: saveFav,
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 25.0,
                        color: isFav ? Colors.red : Colors.black,
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => {
                    Scrollable.ensureVisible(detailsKey.currentContext),
                    changeSectionIndex(0),
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: indexSection == 0
                          ? Color.fromRGBO(254, 192, 75, 1)
                          : Colors.white,
                    ),
                    child: Text(
                      'Detalles',
                      style: TextStyle(
                        color: indexSection == 0 ? Colors.white : Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => {
                    Scrollable.ensureVisible(cardKey.currentContext),
                    changeSectionIndex(1),
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: indexSection == 1
                          ? Color.fromRGBO(254, 192, 75, 1)
                          : Colors.white,
                    ),
                    child: Text(
                      'Carta',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: indexSection == 1 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => {
                    Scrollable.ensureVisible(reviewsKey.currentContext),
                    changeSectionIndex(2),
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: indexSection == 2
                          ? Color.fromRGBO(254, 192, 75, 1)
                          : Colors.white,
                    ),
                    child: Text(
                      'Valoraciones',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: indexSection == 2 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              margin: EdgeInsets.only(left: 10.0, right: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      key: detailsKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                restaurant.nombre,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => openPhone("+34" +
                                  restaurant.telefono.replaceAll(" ", "")),
                              child: Container(
                                margin: EdgeInsets.only(right: 20.0),
                                child: SvgPicture.asset(
                                  'assets/images/phone.svg',
                                  width: 23.0,
                                  height: 24.0,
                                ),
                              ),
                            ),
                            restaurant.googleUrl == null ||
                                    restaurant.googleUrl == ''
                                ? Container()
                                : GestureDetector(
                                    onTap: () => launch(restaurant.googleUrl),
                                    child: Container(
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/google.png'),
                                        width: 23.0,
                                        height: 24.0,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        restaurant.avg == "NaN"
                            ? Container()
                            : Row(
                                children: [
                                  Text(
                                    restaurant.avg,
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  RatingBar.builder(
                                    ignoreGestures: true,
                                    initialRating: double.parse(restaurant.avg),
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize: 30,
                                    glowColor: Colors.white,
                                    onRatingUpdate: (rating) => {},
                                    itemPadding:
                                        EdgeInsets.symmetric(horizontal: 2.0),
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  Text(
                                    restaurant.valoraciones.length.toString() +
                                        ' valoraciones',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          restaurant.horarios == null
                              ? ""
                              : restaurant.horarios,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          restaurant.destacado == null
                              ? ""
                              : restaurant.destacado,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          restaurant.direccion,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 55.0,
                    height: 55.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 5.0,
                            spreadRadius: 1.0,
                            offset: Offset(2.0, 4.0))
                      ],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: GestureDetector(
                      onTap: () => openMap(restaurant.direccion),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/map.png'),
                            height: 40.0,
                            width: 40.0,
                          ),
                          Text(
                            'Abrir mapa',
                            style: TextStyle(
                              fontSize: 8.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
            restaurant.fotos.isNotEmpty
                ? Divider(
                    color: Colors.grey,
                    indent: 10.0,
                    endIndent: 10.0,
                  )
                : Container(),
            restaurant.fotos.isNotEmpty
                ? SizedBox(
                    height: 15.0,
                  )
                : Container(),
            restaurant.fotos.isNotEmpty
                ? Container(
                    height: 80.0,
                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                    child: ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        itemExtent: MediaQuery.of(context).size.width / 4,
                        itemCount: restaurant.fotos.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return restaurant.fotos[index].photoUrl == null
                              ? Container()
                              : GestureDetector(
                            onTap: ()=>{
                              GlobalMethods().pushPage(context, PhotoFullScreen(restaurant, index))
                            },
                                child: Container(
                                    height: 73.0,
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7.0),
                                      image: DecorationImage(
                                        repeat: ImageRepeat.noRepeat,
                                        alignment: Alignment.center,
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                            restaurant.fotos[index].photoUrl),
                                      ),
                                    ),
                                  ),
                              );
                        }),
                  )
                : Container(),
            SizedBox(
              height: 15.0,
            ),
            restaurant.menus.isNotEmpty
                ? Divider(
                    color: Colors.grey,
                    indent: 10.0,
                    endIndent: 10.0,
                  )
                : Container(),
            restaurant.menus.isNotEmpty
                ? SizedBox(
                    height: 15.0,
                  )
                : Container(),
            restaurant.menus.isNotEmpty
                ? GestureDetector(
                    onTap: () => {
                      if (this.indexCarta == 0)
                        {
                          setState(() {
                            this.indexCarta = -1;
                          })
                        }
                      else
                        {
                          setState(() {
                            this.indexCarta = 0;
                          })
                        }
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Carta",
                              key: cardKey,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                          Container(
                            width: 30.0,
                            height: 30.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7.0),
                            ),
                            child: Icon(
                              this.indexCarta == 0
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 30.0,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
            SizedBox(
              height: 10.0,
            ),
            indexCarta == 0
                ? Container(
                    child: ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        itemCount: restaurant.menus.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          return Container(
                            padding: EdgeInsets.all(15.0),
                            margin: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 10.0),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 81.0,
                                  width: 81.0,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      repeat: ImageRepeat.noRepeat,
                                      alignment: Alignment.center,
                                      fit: BoxFit.cover,
                                      image: restaurant.menus[index].fotoUrl ==
                                                  null ||
                                              restaurant
                                                  .menus[index].fotoUrl.isEmpty
                                          ? AssetImage(
                                              'assets/images/notImage.png')
                                          : NetworkImage(
                                              restaurant.menus[index].fotoUrl),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20.0,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.menus[index].plato == null
                                            ? ""
                                            : restaurant.menus[index].plato,
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 7.0,
                                      ),
                                      Text(
                                        restaurant.menus[index].descripcion ==
                                                null
                                            ? ""
                                            : restaurant
                                                .menus[index].descripcion,
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10.0,
                                      ),
                                      Text(
                                        restaurant.menus[index].alergenos ==
                                                null
                                            ? ""
                                            : restaurant.menus[index].alergenos,
                                        style: TextStyle(
                                          fontSize: 8.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 20.0,
                                ),
                                Text(
                                  restaurant.menus[index].precio == null
                                      ? ""
                                      : restaurant.menus[index].precio + "€",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                  )
                : Container(),
            restaurant.valoraciones.isNotEmpty
                ? SizedBox(
                    height: 15.0,
                  )
                : Container(),
            restaurant.valoraciones.isNotEmpty
                ? Divider(
                    color: Colors.grey,
                    indent: 10.0,
                    endIndent: 10.0,
                  )
                : Container(),
            restaurant.valoraciones.isNotEmpty
                ? SizedBox(
                    height: 15.0,
                  )
                : Container(),
            userId != null
                ? GestureDetector(
                    onTap: () => {
                      GlobalMethods()
                          .pushPage(context, NewReview(restaurant, userId,mainFoto))
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 210.0, right: 20.0),
                      padding:
                          EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.0),
                        color: Color.fromRGBO(222, 99, 44, 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          Text(
                            "Añadir Valoración",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(),
            SizedBox(
              height: 20.0,
            ),
            restaurant.valoraciones.isNotEmpty
                ? GestureDetector(
                    onTap: () => {
                      if (this.indexValoraciones == 0)
                        {
                          setState(() {
                            this.indexValoraciones = -1;
                          })
                        }
                      else
                        {
                          setState(() {
                            this.indexValoraciones = 0;
                          })
                        }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      color: Colors.transparent,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Valoraciones",
                              key: reviewsKey,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                          Container(
                            width: 30.0,
                            height: 30.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7.0),
                            ),
                            child: Icon(
                              this.indexValoraciones == 0
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 30.0,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),
            indexValoraciones == 0
                ? Container(
                    child: Column(
                      children: restaurant.valoraciones.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Container(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          e.title == null || e.title == ''
                                              ? "Valoración"
                                              : e.title,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              e.rating,
                                              style: TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            RatingBar.builder(
                                              ignoreGestures: true,
                                              initialRating:
                                                  double.parse(e.rating),
                                              minRating: 1,
                                              direction: Axis.horizontal,
                                              allowHalfRating: true,
                                              itemCount: 5,
                                              itemSize: 20,
                                              glowColor: Colors.white,
                                              onRatingUpdate: (rating) => {},
                                              itemPadding: EdgeInsets.symmetric(
                                                  horizontal: 2.0),
                                              itemBuilder: (context, _) => Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 5.0,
                                        ),
                                        Text(
                                          e.usuario.nombre,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        Text(
                                          "",
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
                                Text(
                                  e.review != null ? e.review : "",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14.0,
                                  ),
                                ),
                                SizedBox(
                                  height: 20.0,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Container(),
            SizedBox(
              height: 30.0,
            ),
          ],
        ),
      ),
    );
  }

  changeSectionIndex(index) {
    setState(() {
      indexSection = index;
    });
  }

  openPhone(phone) {
    launch("tel://" + phone);
  }

  openMap(String address) {
    MapsLauncher.launchQuery(
        address);
  }

  saveFav() {
    if (this.userId != null) {
      presenter.saveFavRestaurant(restaurant.id);
    }
  }

  @override
  goToLogin() {
    GlobalMethods().removePagesAndGoToNewScreen(
        context, Login("Para guardar un restaurante debes iniciar sesión."));
  }

  @override
  setUserId(String id) {
    setState(() {
      this.userId = id;
    });
  }

  @override
  setFav(bool correct) {
    setState(() {
      this.isFav = correct;
    });
  }
}
