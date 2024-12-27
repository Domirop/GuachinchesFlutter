import 'package:flutter/material.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';

class RestaurantMainCard extends StatefulWidget {
  final Restaurant restaurant;
  final String size;

  const RestaurantMainCard({required this.restaurant,required this.size});

  @override
  State<RestaurantMainCard> createState() => _RestaurantMainCardState();
}

class _RestaurantMainCardState extends State<RestaurantMainCard> {
  @override
  Widget build(BuildContext context) {
    double width= 300;
    double height = 200;

    if(widget.size == 'big'){
      width = MediaQuery.of(context).size.width * 0.92;
    }

    return GestureDetector(
      onTap: () => GlobalMethods().pushPage(
          context, Details(widget.restaurant.id)),
      child: Container(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: height,
              width: width ,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  widget.restaurant.mainFoto,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(widget.restaurant.nombre,style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display'
              ),),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(widget.restaurant.avgRating.toStringAsFixed(2), style: Theme.of(context).textTheme.bodySmall),
                Icon(Icons.star,size: 16,color: Colors.white),
                // Text('(120)',style: TextStyle(color: Color.fromRGBO(97, 97, 97, 1),fontSize: 14,fontWeight: FontWeight.w500)),
                Text(' · Abierto', style: Theme.of(context).textTheme.bodySmall)
              ],
            ),
            SizedBox(height: 4),
            Text(
                widget.restaurant.municipio,
                style: Theme.of(context).textTheme.bodySmall
            )
          ],
        ),
      ),
    );
  }
}