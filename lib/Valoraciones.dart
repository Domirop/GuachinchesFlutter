import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/new_review/new_review.dart';

import 'data/cubit/restaurant_state.dart';
import 'login.dart';


class Valoraciones extends StatefulWidget {
  final String restaurantId;

  Valoraciones(this.restaurantId);

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
  String restaurantId = "31db2882-293d-4d2d-98ba-4939578de349";
  ValoracionesComponent(this.title);
  Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal:10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                //Llamar al presenter para que se encarge de coger el usuario
                onPressed: () =>GlobalMethods().pushPage(context, Login()),
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
        ),
        SizedBox(
          height: 15.0,
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
        Container(
          child: BlocBuilder<RestaurantCubit,RestaurantState>(
            builder: (context, state){
              if(state is RestaurantLoaded) {
                restaurant = state.restaurants.where((element) => element.id == restaurantId).first;
                return Column(
                  children: restaurant.valoraciones.map((e)
                  {
                    return Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [

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
                                                  e.rating,
                                                  style: TextStyle(
                                                    fontSize: 18.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                RatingBar.builder(
                                                  ignoreGestures: true,
                                                  initialRating: double.parse(e.rating),
                                                  minRating: 1,
                                                  direction: Axis.horizontal,
                                                  allowHalfRating: true,
                                                  itemCount: 5,
                                                  itemSize: 20,
                                                  glowColor: Colors.white,
                                                  onRatingUpdate: (rating)=>{},
                                                  itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
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
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20.0,
                                    ),
                                    // Row(
                                    //   children: [
                                    //     Container(
                                    //       height: 56.0,
                                    //       width: 56.0,
                                    //       decoration: BoxDecoration(
                                    //         image: DecorationImage(
                                    //           repeat: ImageRepeat.noRepeat,
                                    //           alignment: Alignment.center,
                                    //           fit: BoxFit.cover,
                                    //           image: AssetImage('assets/images/escaldon.png'),
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     SizedBox(
                                    //       width: 10.0,
                                    //     ),
                                    //     Container(
                                    //       height: 56.0,
                                    //       width: 56.0,
                                    //       decoration: BoxDecoration(
                                    //         image: DecorationImage(
                                    //           repeat: ImageRepeat.noRepeat,
                                    //           alignment: Alignment.center,
                                    //           fit: BoxFit.cover,
                                    //           image: AssetImage('assets/images/escaldon.png'),
                                    //         ),
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    SizedBox(
                                      height: 20.0,
                                    ),
                                    Text(
                                      e.review,
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
                          ),);
                  }).toList(),
                );
              }
              return Container();
            },
          ),
        ),
      ],
    );
  }
}