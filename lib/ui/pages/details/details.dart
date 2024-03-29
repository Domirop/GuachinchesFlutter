import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/new_review/new_review.dart';
import 'package:guachinches/ui/Others/photo_full_screen/photo_full_screen.dart';
import 'package:guachinches/ui/pages/details/details_presenter.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';


class Details extends StatefulWidget {
  final String id;

  Details(this.id);

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> implements DetailView {
  late String userId;
  String id ='';
  bool isFav = false;
  late Restaurant restaurant;
  int indexCarta = 0;
  int indexValoraciones = 0;
  int indexSection = 0;
  late DetailPresenter presenter;
  late RemoteRepository remoteRepository;
  final cardKey = GlobalKey();
  final detailsKey = GlobalKey();
  final reviewsKey = GlobalKey();
  late Fotos mainFoto;
  bool isChargin = true;

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    id = widget.id;

    presenter = DetailPresenter(remoteRepository, this);
    presenter.getRestaurantById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isChargin
          ? Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      )
          : SingleChildScrollView(
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
                        offset:
                        Offset(0, 3), // changes position of shadow
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
                          : NetworkImage(mainFoto.photoUrl!) as ImageProvider,
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
                  onTap: () =>
                  {
                    Scrollable.ensureVisible(detailsKey.currentContext!),
                    changeSectionIndex(0),
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: indexSection == 0
                          ?  Color.fromRGBO(0, 133, 196, 1)
                          : Colors.white,
                    ),
                    child: Text(
                      'Detalles',
                      style: TextStyle(
                        color: indexSection == 0
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                  {
                    Scrollable.ensureVisible(cardKey.currentContext!),
                    changeSectionIndex(1),
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: indexSection == 1
                          ? Color.fromRGBO(0, 133, 196, 1)
                          : Colors.white,
                    ),
                    child: Text(
                      'Carta',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: indexSection == 1
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                  {
                    Scrollable.ensureVisible(reviewsKey.currentContext!),
                    changeSectionIndex(2),
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: indexSection == 2
                          ?  Color.fromRGBO(0, 133, 196, 1)
                          : Colors.white,
                    ),
                    child: Text(
                      'Valoraciones',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: indexSection == 2
                            ? Colors.white
                            : Colors.black,
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
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
                              onTap: () =>
                                  openPhone("+34" +
                                      restaurant.telefono
                                          .replaceAll(" ", "")),
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
                              onTap: () =>
                                  launch(restaurant.googleUrl),
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
                        restaurant.avg == "NaN" || restaurant.avgRating == null
                            ? Container(
                          child: Text(
                            'Sin Valoraciones',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        )
                            : Row(
                          children: [
                            Text(
                              restaurant.avgRating.toString(),
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            RatingBar.builder(
                              ignoreGestures: true,
                              initialRating: restaurant.avgRating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 30,
                              glowColor: Colors.white,
                              onRatingUpdate: (rating) => {},
                              itemPadding: EdgeInsets.symmetric(
                                  horizontal: 2.0),
                              itemBuilder: (context, _) =>
                                  Icon(
                                    Icons.star,
                                    color: Color.fromRGBO(0, 133, 196, 1),
                                  ),
                            ),
                            Text(
                              restaurant.valoraciones.length
                                  .toString() +
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
                        Text( ""
,
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
                          height: 12.0,
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
                            color: Colors.grey[100]!,
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
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text('Servicios'),
            ),
            Container(
              height: 60.0,
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: restaurant.categoriaRestaurantes.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.all(8.0),
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SvgPicture.network(
                        restaurant.categoriaRestaurantes[index].categorias.iconUrl,
                        width: 20.0,
                        height: 20.0,
                      ),
                    );
                  }),
            ),

            restaurant.fotos.isNotEmpty
                ? Column(
              children: [
                Divider(
                  color: Colors.grey,
                  indent: 10.0,
                  endIndent: 10.0,
                ),
                SizedBox(
                  height: 15.0,
                ),
                Container(
                  height: 80.0,
                  margin: EdgeInsets.symmetric(horizontal: 10.0),
                  child: ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      itemExtent:
                      MediaQuery
                          .of(context)
                          .size
                          .width / 4,
                      itemCount: restaurant.fotos.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return restaurant.fotos[index].photoUrl ==
                            null
                            ? Container()
                            : GestureDetector(
                          onTap: () =>
                          {
                            GlobalMethods().pushPage(
                                context,
                                PhotoFullScreen(
                                    restaurant, index))
                          },
                          child: Container(
                            height: 73.0,
                            margin: EdgeInsets.symmetric(
                                horizontal: 10.0),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(7.0),
                              image: DecorationImage(
                                repeat: ImageRepeat.noRepeat,
                                alignment: Alignment.center,
                                fit: BoxFit.cover,
                                image: restaurant.fotos[index].photoUrl != null
                                    ? NetworkImage(restaurant
                                    .fotos[index].photoUrl!)
                                    : AssetImage(
                                    "assets/images/notImage.png") as ImageProvider,
                              ),
                            ),
                          ),
                        );
                      }),
                ),

              ],
            )
                : Container(),
            restaurant.menus.isNotEmpty
                ? Column(
              children: [
                Divider(
                  color: Colors.grey,
                  indent: 10.0,
                  endIndent: 10.0,
                ),
                SizedBox(
                  height: 15.0,
                ),
                GestureDetector(
                  onTap: () =>
                  {
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
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
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
                            borderRadius:
                            BorderRadius.circular(7.0),
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
                ),
                SizedBox(
                  height: 10.0,
                ),
              ],
            )
                : Container(),
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
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 81.0,
                            width: 81.0,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                repeat: ImageRepeat.noRepeat,
                                alignment: Alignment.center,
                                fit: BoxFit.cover,
                                image: restaurant.menus[index]
                                    .fotoUrl ==
                                    null ||
                                    restaurant.menus[index]
                                        .fotoUrl!.isEmpty
                                    ? AssetImage(
                                    'assets/images/notImage.png')
                                    : NetworkImage(restaurant
                                    .menus[index].fotoUrl!) as ImageProvider,
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
                                  restaurant.menus[index].plato! ==
                                      null
                                      ? ""
                                      : restaurant
                                      .menus[index].plato!,
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
                                  restaurant.menus[index]
                                      .descripcion! ==
                                      null
                                      ? ""
                                      : restaurant
                                      .menus[index].descripcion!,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Text(
                                  restaurant.menus[index]
                                      .alergenos! ==
                                      null
                                      ? ""
                                      : restaurant
                                      .menus[index].alergenos!,
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
                                : restaurant.menus[index].precio! +
                                "€",
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
                ? Column(
              children: [
                Divider(
                  color: Colors.grey,
                  indent: 10.0,
                  endIndent: 10.0,
                ),
              ],
            )
                : Container(),
            userId != null
                ? GestureDetector(
              onTap: () =>
              {
                GlobalMethods().pushPage(
                    context,
                    NewReview(
                        restaurant, userId, mainFoto.photoUrl!))
              },
              child: Container(
                margin: EdgeInsets.only(left: 210.0, right: 20.0),
                padding: EdgeInsets.symmetric(
                    vertical: 5.0, horizontal: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.0),
                  color: Color.fromRGBO(0, 133, 196, 1),
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
            restaurant.valoraciones.isNotEmpty
                ? Column(
              children: [
                SizedBox(
                  height: 20.0,
                ),
                GestureDetector(
                  onTap: () =>
                  {
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
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
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
                            borderRadius:
                            BorderRadius.circular(7.0),
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
                ),
              ],
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
                      margin:
                      EdgeInsets.symmetric(horizontal: 10.0),
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
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                                          fontWeight:
                                          FontWeight.bold,
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
                                        onRatingUpdate: (rating) =>
                                        {},
                                        itemPadding:
                                        EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        itemBuilder: (context, _) =>
                                            Icon(
                                              Icons.star,
                                              color: Color.fromRGBO(
                                                  0, 133, 196, 1),
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
                                  Row(
                                    children: [
                                      Text(
                                        e.usuario == null
                                            ? ''
                                            : e.usuario!.nombre,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      PopupMenuButton(
                                        child: Icon(Icons.more_vert,),
                                        onSelected: (value) {
                                           showDialog(context: context,
                                              builder: (context) =>
                                              value == 'block user'?
                                              AlertDialog(
                                                title: Text('¿Quieres bloquear a '+ e.usuario!.nombre+'?'),
                                                content: Text('No se te mostrarán los comentarios de este usuario'),
                                                actions: [
                                                  OutlinedButton(
                                                      onPressed: ()=>GlobalMethods().popPage(context),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(width: 1.0, color: Colors.red),
                                                      ),
                                                      child: Text("No, cancelar",style: TextStyle(color: Colors.red),)),
                                                  ElevatedButton(
                                                      onPressed: ()=>presenter.blockUser(userId,e.usuario!.id), child: Text("Si, bloquear"))
                                                ],
                                              ):AlertDialog(
                                                title: Text('¿Quieres reportar este comentario ?'),
                                                content: Text('Nuestro equipo investigará tu denuncia, y no se te mostrará este comentario'),

                                                actions: [
                                                  OutlinedButton(
                                                      onPressed: ()=>GlobalMethods().popPage(context),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(width: 1.0, color: Colors.red),
                                                      ),
                                                      child: Text("No, cancelar",style: TextStyle(color: Colors.red),)),
                                                  ElevatedButton(
                                                      onPressed: ()=>presenter.reportReview(userId, e.id)
                                                  , child: Text("Si, reportar"))
                                                ],
                                              )
                                          );
                                           },
                                        itemBuilder: (BuildContext bc) {
                                          return const [
                                            PopupMenuItem(
                                              child: Text("Bloquear usuario"),
                                              value: 'block user',
                                            ),
                                            PopupMenuItem(
                                              child: Text(
                                                  "Reportar Valoración"),
                                              value: 'report review',
                                            ),
                                          ];
                                        },
                                      )
                                    ],
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
    MapsLauncher.launchQuery(address);
  }

  saveFav() {
    if (this.userId != null) {
      presenter.saveFavRestaurant(widget.id);
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

  @override
  setRestaurant(Restaurant restaurant) {
      if (mounted) {
      Fotos foto = restaurant.fotos.firstWhere(
              (element) => element.type == "principal",);

      setState(() {
        this.mainFoto = foto;
        this.restaurant = restaurant;
        this.isChargin = false;
      });
    }
  }

  @override
  refreshScreen() {
    GlobalMethods().refreshPage(context,Details(id));
    throw UnimplementedError();
  }
}
