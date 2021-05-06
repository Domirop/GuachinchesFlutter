import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/model/Review.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/new_review/new_review_presenter.dart';
import 'package:http/http.dart';

class NewReview extends StatefulWidget {
  final Restaurant _restaurant;
  final String _userId;

  NewReview(this._restaurant, this._userId);

  @override
  _NewReviewState createState() => _NewReviewState();
}

class _NewReviewState extends State<NewReview> implements NewReviewView {
  String rating = "5";
  var reviewController;
  var tittleController;
  NewReviewPresenter _presenter;
  RemoteRepository remoteRepository;

  @override
  void initState() {
    reviewController = TextEditingController();
    tittleController = TextEditingController();
    remoteRepository = HttpRemoteRepository(Client());
    _presenter = NewReviewPresenter(remoteRepository, this);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
        appBar: AppBar(
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
            onPressed: () => {GlobalMethods().popPage(context)},
          ),
          title: Text("Crear nueva valoracion",
              style: TextStyle(color: Colors.black)),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: ListView(children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Restaurante",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80.0,
                    height: 80.0,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        image: DecorationImage(
                          image: AssetImage('assets/images/Morenita.png'),
                        )),
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
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Carne fiesta",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                            ),
                          ),
                          Text(
                            widget._restaurant.direccion,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.0,
                            ),
                          ),
                          Text(
                            widget._restaurant.destacado != null
                                ? widget._restaurant.destacado
                                : "",
                            style: TextStyle(
                              color: Color.fromRGBO(226, 120, 120, 1),
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Puntuacion",
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
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    this.rating = rating.toString();
                  },
                ),
              ),
              Text(
                "Titulo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: tittleController,
                  scrollPadding: EdgeInsets.only(bottom: bottomInsets + 50),
                  decoration: new InputDecoration(
                    hintText: "Dale titulo a tu experiencia",
                    border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.teal)),
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 1,
                ),
              ),
              Text(
                "Tu experiencia",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: reviewController,
                  scrollPadding: EdgeInsets.only(bottom: bottomInsets + 50),
                  decoration: new InputDecoration(
                    hintText: "Describe tu experiencia",
                    border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.teal)),
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                ),
              ),
              RaisedButton(
                onPressed: () => {
                  _presenter.saveReview(widget._userId, widget._restaurant,
                      tittleController.text, reviewController.text, rating)
                  // _presenter.updateReview(widget.userId, widget.review.id,
                  //     tittleController.text, rating, reviewController.text)
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.0),
                ),
                color: Color.fromRGBO(222, 99, 44, 1),
                child: Text(
                  "Publicar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ]));
  }

  @override
  reviewSaved() {
    // TODO: implement reviewSaved
    throw UnimplementedError();
  }
}
