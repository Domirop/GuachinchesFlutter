import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/cards/topRestaurantCard.dart';
import 'package:guachinches/ui/components/cards/TopRestaurantListCard.dart';
import 'package:guachinches/ui/components/cards/restaurantOpenCard.dart';

class RestaurantShowMoreGuachinches extends StatefulWidget {
  String type;
  RestaurantShowMoreGuachinches(this.type);

  @override
  _RestaurantShowMoreGuachinchesState createState() => _RestaurantShowMoreGuachinchesState();
}

class _RestaurantShowMoreGuachinchesState extends State<RestaurantShowMoreGuachinches> {
  _RestaurantShowMoreText top = new _RestaurantShowMoreText('Guachinches norte TF','Te '
      'mostramos la selección de mejores restaurantes de nuestra app, mediante nuestro algoritmo que tiene encuenta visitas, puntuaciones y número de valoraciones');

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:  Text(top.title,style: TextStyle(
            fontWeight: FontWeight.bold,
            foreground: Paint()..shader = linearGradient

        ),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20,20,0,0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(top.title,style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20
            ),),
            SizedBox(
              height: 10.0,
            ),
            BlocBuilder<RestaurantCubit, RestaurantState>(
            builder: (context, state) {
              if (state is AllRestaurantLoaded){
                List<Restaurant> restaurants = [];
                if(widget.type == 'open'){
                  state.restaurantResponse.restaurants.forEach((element) {
                    if (element.open) {
                      restaurants.add(element);
                    };
                  });
                }
                if(widget.type == 'GuachinchesNorteTF'){
                  String norte = '2563c6c7-33eb-43da-8d0a-f21f999a1068';
                  String guachinchesModernosType = '82054a45-6db3-4931-bb17-4aba588445e4';
                  String guachinchesTradicionalesType = '8ea45515-8a14-4638-9560-80a6446c129f';
                  state.restaurantResponse.restaurants.forEach((element) {
                    if (element.area == norte && (element.type == guachinchesModernosType || element.type == guachinchesTradicionalesType)) {
                      restaurants.add(element);
                    };
                  });
                }
                return Container(
                width: double.infinity,
                child: ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: restaurants.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      return RestaurantOpenCard(restaurants[index]);
                    }),
              );
              }
              return Container();

            })
          ],
        ),
      ),
    );
  }
}

class _RestaurantShowMoreText {
  String title;
  String subtitle;

  _RestaurantShowMoreText(this.title, this.subtitle);
}
final Shader linearGradient = LinearGradient(
  colors: <Color>[Color(0xff0189C4), Color(0xff01BCC4)],
).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));