import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/ui/Others/new_review/new_review_presenter.dart';
import 'package:http/http.dart';

class NewReview extends StatefulWidget {
  final Restaurant _restaurant;
  final String _userId;
  final String _mainPhoto;

  NewReview(this._restaurant, this._userId, this._mainPhoto);

  @override
  _NewReviewState createState() => _NewReviewState();
}

class _NewReviewState extends State<NewReview> implements NewReviewView {
  String rating = "5";
  var reviewController;
  bool error = false;
  var tittleController;
  late NewReviewPresenter _presenter;
  late RemoteRepository remoteRepository;
  bool reviewLoading = false;

  @override
  void initState() {
    final restaurantCubit = context.read<RestaurantCubit>();
    reviewController = TextEditingController();
    tittleController = TextEditingController();
    remoteRepository = HttpRemoteRepository(Client());
    _presenter = NewReviewPresenter(remoteRepository, this, restaurantCubit);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_sharp, color: Colors.white),
            onPressed: () => {GlobalMethods().popPage(context)},
          ),
          title: Text(
            "Crear nueva valoración",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontFamily: 'SF Pro Display',
            ),
          ),
          elevation: 0,
          backgroundColor: GlobalMethods.bgColor,
        ),
        body: ListView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80.0,
                        height: 80.0,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12.0),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: widget._mainPhoto != null
                                ? NetworkImage(widget._mainPhoto)
                                : AssetImage("assets/images/notImage.png")
                            as ImageProvider,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget._restaurant.nombre,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontFamily: 'SF Pro Display',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget._restaurant.direccion,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Display',
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "Puntuación",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Center(
                  child: RatingBar.builder(
                    initialRating: double.parse("5"),
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    glowColor: Colors.white,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: GlobalMethods.blueColor,
                    ),
                    onRatingUpdate: (rating) {
                      this.rating = rating.toString();
                    },
                  ),
                ),
                Text(
                  "Título",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TextField(
                    controller: tittleController,
                    scrollPadding: EdgeInsets.only(bottom: bottomInsets + 50),
                    decoration: InputDecoration(
                      hintText: "Dale título a tu experiencia",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.multiline,
                    maxLines: 1,
                  ),
                ),
                Text(
                  "Tu experiencia",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TextField(
                    controller: reviewController,
                    scrollPadding: EdgeInsets.only(bottom: bottomInsets + 50),
                    decoration: InputDecoration(
                      hintText: "Describe tu experiencia",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                  ),
                ),
                error
                    ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Lo sentimos no hemos podido agregar su valoración.",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                  ],
                )
                    : Container(),
                reviewLoading
                    ? Column(
                  children: [
                    SpinKitPumpingHeart(
                      color: GlobalMethods.blueColor,
                      size: 50.0,
                    ),
                    Text(
                        "Estamos publicando tu valoración. ¡Muchas gracias!")
                  ],
                )
                    : ElevatedButton(
                  onPressed: () => {
                    setState(() {
                      reviewLoading = true;
                    }),
                    _presenter.saveReview(
                      widget._userId,
                      widget._restaurant,
                      tittleController.text,
                      reviewController.text,
                      rating,
                    )
                  },
                  style: ElevatedButton.styleFrom(
                    primary: GlobalMethods.blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Publicar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  reviewSaved() {
    GlobalMethods().removePages(context);
  }

  @override
  reviewNotSaved() {
    setState(() {
      error = true;
    });
    Timer(
      Duration(seconds: 3),
          () => {
        GlobalMethods().popPage(context),
      },
    );
  }
}
