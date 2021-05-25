import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/edit_reviews/edit_reviews_presenter.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/model/user_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class EditReview extends StatefulWidget {
  final Valoraciones review;
  final String userId;
  EditReview(this.userId, this.review);

  @override
  _EditReviewState createState() => _EditReviewState();
}

class _EditReviewState extends State<EditReview> implements EditReviewView{
  var reviewController;
  var tittleController;
  String rating;
  EditReviewPresenter _presenter;

@override
  void initState() {
    final restaurantCubit = context.read<UserCubit>();
    _presenter = EditReviewPresenter(this, restaurantCubit);
    reviewController = TextEditingController(text: widget.review.review);
    tittleController = TextEditingController(text: widget.review.title);
    rating = widget.review.rating;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    double bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        appBar: AppBar(
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
            onPressed: () => {GlobalMethods().popPage(context)}
            ,
          ),
          title:Text("Editar Valoracion",
              style: TextStyle(color: Colors.black)),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text("Puntuacion",style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            Center(
            child: RatingBar.builder(
            initialRating: double.parse(widget.review.rating),
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
            Text("Titulo",style: TextStyle(fontWeight: FontWeight.bold),),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: tittleController,
                scrollPadding: EdgeInsets.only(bottom:bottomInsets + 50),
                decoration: new InputDecoration(
                  hintText: "Dale titulo a tu experiencia",
                  border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.teal)
                  ),),
                keyboardType: TextInputType.multiline,
                maxLines: 1,
              ),
            ),
            Text("Tu experiencia",style: TextStyle(fontWeight: FontWeight.bold),),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: reviewController,
                scrollPadding: EdgeInsets.only(bottom:bottomInsets + 50),
                decoration: new InputDecoration(
                  hintText: "Describe tu experiencia",
                  border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.teal)
                  ),),
                keyboardType: TextInputType.multiline,
                maxLines: 4,
              ),
            ),
            RaisedButton(
              onPressed: () =>
              {
                _presenter.updateReview(widget.userId, widget.review.id,
                    tittleController.text, rating, reviewController.text)
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7.0),
              ),
              color: Color.fromRGBO(222, 99, 44, 1),
              child: Text(
                "Guardar cambios",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ));
  }

  @override
  reviewUpdated() {

  }
}
