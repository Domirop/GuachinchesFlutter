import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';

import '../../components/cards/restaurantMainCard.dart';

class RestaurantList extends StatefulWidget {
  final List<Restaurant> restaurants;

  const RestaurantList({required this.restaurants});

  @override
  State<RestaurantList> createState() => _RestaurantListState();
}

class _RestaurantListState extends State<RestaurantList> {
  @override
  Widget build(BuildContext context) {
    return  Material(
      type: MaterialType.transparency,

      child: CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Los favoritos'),
            ),
            SliverFillRemaining(
              hasScrollBody: false,

              child:Container(

                // Assuming 264 is the height of each item
                child: Column(
                  children: widget.restaurants
                      .map((restaurant) {
                    return Padding(
                      padding: const EdgeInsets
                          .only(
                          bottom: 8.0),
                      child: RestaurantMainCard(
                        restaurant:restaurant,
                        size: 'big',
                      ),
                    );
                  }).toList(),
                ),
              ) ,
            )
          ],
        ),
      ),
    );
  }
}
