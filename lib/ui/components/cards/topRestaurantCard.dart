import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';

class TopRestaurantCard extends StatelessWidget {
  TopRestaurants restaurant;

  TopRestaurantCard(this.restaurant);

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
                  color: Colors.grey[100]!,
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
                        restaurant.imagen != null
                            ? NetworkImage(
                            restaurant.imagen)
                            : AssetImage(
                            "assets/images/notImage.png") as ImageProvider
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
                      RatingBar.builder(
                        ignoreGestures: true,
                        initialRating: restaurant.avg,
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
