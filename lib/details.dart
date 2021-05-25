import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Valoraciones.dart';

class Details extends StatefulWidget {
  final Restaurant _restaurant;

  Details(this._restaurant);

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  List images = [
    "assets/images/Morenita.png",
    "assets/images/Morenita.png",
    "assets/images/Morenita.png",
    "assets/images/Morenita.png",
    "assets/images/Morenita.png"
  ];
  String url = "https://www.google.com";
  String phone = "+34111222333";
  int indexSection = 0;

  final cardKey = GlobalKey();
  final detailsKey = GlobalKey();
  final reviewsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
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
                      image: AssetImage('assets/images/fondoDetails.png'),
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
                      color: Colors.black,
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
                          children: [
                            Text(
                              widget._restaurant.nombre,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => openPhone(phone),
                              child: Container(
                                margin: EdgeInsets.only(right: 5.0, left: 10.0),
                                child: Image(
                                  image: AssetImage('assets/images/phone.png'),
                                  width: 23.0,
                                  height: 24.0,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => launch(url),
                              child: Container(
                                margin: EdgeInsets.only(left: 5.0),
                                child: Image(
                                  image: AssetImage('assets/images/google.png'),
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
                        widget._restaurant.avg == "NaN" ? Container() : Row(
                          children: [
                            Text(
                              widget._restaurant.avg,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            RatingBar.builder(
                              ignoreGestures: true,
                              initialRating: double.parse(widget._restaurant.avg),
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 30,
                              glowColor: Colors.white,
                              onRatingUpdate: (rating)=>{},
                              itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                            ),

                            Text(
                              widget._restaurant.valoraciones.length.toString()+' valoraciones',
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
                          'De lunes a viernes de 12:00 a 15:00',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          'Carnes de cerdo y ternera.',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          widget._restaurant.direccion,
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
                      onTap: () => openMap(),
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
            Divider(
              color: Colors.grey,
              indent: 10.0,
              endIndent: 10.0,
            ),
            SizedBox(
              height: 15.0,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  Container(
                    height: 80.0,
                    child: ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        itemExtent: MediaQuery.of(context).size.width / 4,
                        itemCount: images.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 73.0,
                            margin: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7.0),
                              image: DecorationImage(
                                repeat: ImageRepeat.noRepeat,
                                alignment: Alignment.center,
                                fit: BoxFit.cover,
                                image: AssetImage(images[index]),
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
            Divider(
              color: Colors.grey,
              indent: 10.0,
              endIndent: 10.0,
            ),
            SizedBox(
              height: 15.0,
            ),
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
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     Container(
            //       padding:
            //           EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(7.0),
            //         color: Color.fromRGBO(222, 99, 44, 1),
            //       ),
            //       child: Text(
            //         'Entrantes',
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontSize: 12.0,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //     Container(
            //       padding:
            //           EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(7.0),
            //         color: Color.fromRGBO(245, 245, 245, 1),
            //       ),
            //       child: Text(
            //         'Carnes',
            //         style: TextStyle(
            //           fontSize: 12.0,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.black,
            //         ),
            //       ),
            //     ),
            //     Container(
            //       padding:
            //           EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(7.0),
            //         color: Color.fromRGBO(245, 245, 245, 1),
            //       ),
            //       child: Text(
            //         'Valoraciones',
            //         style: TextStyle(
            //           fontSize: 12.0,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.black,
            //         ),
            //       ),
            //     ),
            //     Container(
            //       padding:
            //           EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(7.0),
            //         color: Color.fromRGBO(245, 245, 245, 1),
            //       ),
            //       child: Text(
            //         'Valoraciones',
            //         style: TextStyle(
            //           fontSize: 12.0,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.black,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            SizedBox(
              height: 30.0,
            ),
            Container(
              padding: EdgeInsets.all(15.0),
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
                        image: AssetImage('assets/images/carne.png'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carne Cabra',
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
                          'La mejor carne de cabra de la zona',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          'Sin alergenos(preguntar dudas)',
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
                    '5,20€',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Container(
              padding: EdgeInsets.all(15.0),
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
                        image: AssetImage('assets/images/escaldon.png'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escaldon',
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
                          'Un clasico de canarias que podrás saborear.',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Gluten, huevo (preguntar dudas)',
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
                    '5,20€',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
            Divider(
              color: Colors.grey,
              indent: 10.0,
              endIndent: 10.0,
            ),
            Container(
                key: reviewsKey, child: ValoracionesComponent("Valoraciones",widget._restaurant.id)),
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

  openMap() {
    MapsLauncher.launchQuery(
        'Calle Carr. San Antonio, 35, La Matanza de Acentejo.');
  }
}
