import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';


class RestaurantListCard extends StatelessWidget {
  Restaurant restaurant;

  RestaurantListCard(this.restaurant);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      children: [
        GestureDetector(
          onTap: () => GlobalMethods().pushPage(
              context, Details(restaurant.id)),
          child: Container(
            height: 120,
            margin: EdgeInsets.fromLTRB(0,8,0,0),
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      image: DecorationImage(
                        repeat: ImageRepeat.noRepeat,
                        alignment: Alignment.center,
                        fit: BoxFit.fill,
                        image: restaurant.mainFoto.isNotEmpty
                            ? NetworkImage(restaurant.mainFoto)
                            : AssetImage("assets/images/notImage.png") as ImageProvider,
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
                      restaurant.avgRating ==null?
                          Text('Sin valoraciones')
                          :RatingBar.builder(
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
                      ),
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
                      Text(restaurant.municipio==null?'':restaurant.municipio
                        ,style: TextStyle(
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: double.infinity,
                    margin: EdgeInsets.fromLTRB(0,10,10,0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            color: Color.fromRGBO(28, 195, 137, 1),

                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10,vertical: 6),
                          child: Text(restaurant.avgRating==null?'n/d' :restaurant.avgRating.toStringAsFixed(2),style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),),
                        ),
                      ],
                    ),
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



