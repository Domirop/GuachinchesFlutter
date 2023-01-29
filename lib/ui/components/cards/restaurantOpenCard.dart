import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';

class RestaurantOpenCard extends StatelessWidget {
  Restaurant restaurant;

  RestaurantOpenCard(this.restaurant);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      children: [
        GestureDetector(
          onTap: () => GlobalMethods().pushPage(
              context, Details(restaurant.id)),
          child: Container(
            height: 145,
            margin: EdgeInsets.fromLTRB(10,16,0,0),
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color(0xffffffff),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(0.0, 1.0),
                  blurRadius: 0.8,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        repeat: ImageRepeat.noRepeat,
                        alignment: Alignment.center,
                        fit: BoxFit.fill,
                        image:
                        restaurant.mainFoto != null
                            ? NetworkImage(
                            restaurant.mainFoto)
                            : AssetImage(
                            "assets/images/notImage.png"),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12), // give it width

                Container(
                  width: 140,
                  height: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(child: Text( restaurant.nombre,)),
                      restaurant.avgRating!=null?RatingBar.builder(
                        ignoreGestures: true,
                        initialRating: restaurant.avgRating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 12,
                        glowColor: Colors.white,
                        onRatingUpdate: (rating) => {},
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Color.fromRGBO(0, 189, 195, 1),
                        ),
                      ):Container(child: Text('Sin valoraciones'),),
                      SizedBox(height: 6), // give it width
                      Text(restaurant.open
                          ? "Abierto"
                          : "Cerrado",style: TextStyle(
                          fontSize: 12,
                          color:
                          restaurant.open
                              ? Color.fromRGBO(
                              149, 220, 0, 1)
                              : Color.fromRGBO(
                              226, 120, 120, 1)),
                      )      ,
                      SizedBox(height: 6), // give it width
                      Text(restaurant.municipio
                        ,style: TextStyle(
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          width: 30.0,
        ),
      ],
    );  }
}
