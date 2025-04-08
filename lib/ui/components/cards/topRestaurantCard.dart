import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';

class TopRestaurantCard extends StatelessWidget {
  TopRestaurants restaurant;

  TopRestaurantCard(this.restaurant);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>GlobalMethods().pushPage(context, Details(restaurant.id)),
      child: Container(
        height: 232,
        width: MediaQuery.of(context).size.width *0.90,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  repeat: ImageRepeat.noRepeat,
                  alignment: Alignment.center,
                  fit: BoxFit.fill,
                  image: NetworkImage(restaurant.imagen),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Textos centrados en la parte inferior
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                restaurant.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 46,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    restaurant.avg.toStringAsFixed(2).replaceAll(".", ",") ,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/star.fill.svg', // Ruta de tu archivo SVG
                    width: 24,
                    height: 24,
                    color: Colors.white, // Aplica color si el SVG es un ícono
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                restaurant.municipio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
