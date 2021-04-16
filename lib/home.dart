import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';

import 'details.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _current = 0;
  final List<String> imgList = [
    'assets/images/car.png',
    'assets/images/car.png',
    'assets/images/car.png',
    'assets/images/car.png'
  ];
  final List<String> iconsList = [
    'assets/images/playtime.png',
    'assets/images/parking.png',
    'assets/images/schedule.png',
    'assets/images/pig.png',
    'assets/images/cow.png',
    'assets/images/fish.png'
  ];
  final List guachinches = [
    {
      'nombre': 'Bodegón Mojo Picón',
      'tipo': 'Carnes de cerdo y ternera.',
      'dirección': 'Calle Cecilio Marrero, 5A, Agua García.',
      'oferta': 'Oferta en carne cabra',
      'imagen': 'assets/images/mojoPicon.png',
      'valoracion': '4,6'
    },
    {
      'nombre': 'Guachinche el parralito',
      'tipo': 'Carnes de cerdo y ternera.',
      'dirección': 'Calle San Cristobal, 66, La Matanza de Acentejo.',
      'oferta': 'Oferta en carne cabra',
      'imagen': 'assets/images/parralito.png',
      'valoracion': '4,5'
    },
    {
      'nombre': 'Martes trancao',
      'tipo': 'Carnes de cerdo y ternera.',
      'dirección': 'Calle Carr. San Antonio, 35, La Matanza de Acentejo.',
      'oferta': 'Menu especial',
      'imagen': 'assets/images/trancao.png',
      'valoracion': '4,2'
    },
    {
      'nombre': 'Guachinche la Morenita',
      'tipo': 'Carnes de cerdo y ternera.',
      'dirección': 'Calle San Francisco de Paula, 137, La Laguna',
      'oferta': 'Oferta en carne cabra',
      'imagen': 'assets/images/Morenita.png',
      'valoracion': '4,2'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders = imgList
        .map((item) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                image: DecorationImage(
                  repeat: ImageRepeat.noRepeat,
                  alignment: Alignment.center,
                  fit: BoxFit.cover,
                  image: AssetImage(item),
                ),
              ),
            ))
        .toList();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image(
                  image: AssetImage('assets/images/logo.png'),
                  height: 40.0,
                  width: 40.0,
                ),
                Row(
                  children: [
                    Text(
                      'Agua García, Tenerife',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black,
                      size: 20.0,
                    ),
                  ],
                ),
                Icon(
                  Icons.search,
                  color: Colors.black,
                  size: 40.0,
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            CarouselSlider(
              items: imageSliders,
              options: CarouselOptions(
                  autoPlay: true,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                  aspectRatio: 2.0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imgList.map((url) {
                int index = imgList.indexOf(url);
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index
                        ? Colors.black
                        : Color.fromRGBO(196, 196, 196, 1),
                  ),
                );
              }).toList(),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categorias',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: iconsList
                    .map((e) => new Container(
                          height: 72.0,
                          width: MediaQuery.of(context).size.width * 0.143,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            overflow: Overflow.visible,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                top: -15.0,
                                child: Image(
                                  image: AssetImage(e),
                                  height: 40.0,
                                  width: 40.0,
                                ),
                              ),
                              Text(
                                'Zona niños',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList()),
            SizedBox(
              height: 20.0,
            ),
            Container(
              margin: EdgeInsets.only(left: 10.0),
              width: 100.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: Colors.black,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_down),
                  Text(
                    'Valoración',
                    style: TextStyle(fontSize: 12.0, color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              child: Column(
                children: guachinches
                    .map((e) => new Container(margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: GestureDetector(
                        onTap: ()=>gotoDetail(),
                        child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 80.0,
                                      height: 80.0,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12.0),
                                          image: DecorationImage(
                                            image: AssetImage(e['imagen']),
                                          )),
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(left: 20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e['nombre'],
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              e['tipo'],
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            Text(
                                              e['dirección'],
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            Text(
                                              e['oferta'],
                                              style: TextStyle(
                                                color: Color.fromRGBO(226, 120, 120, 1),
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 48.0,
                                      height: 24.0,
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(149, 194, 55, 1),
                                          borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      child: Text(
                                        e['valoracion'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20.0,
                                ),
                              ],
                            ),
                      ),
                    ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  gotoDetail(){
    GlobalMethods().pushPage(context, Details());
  }
}
