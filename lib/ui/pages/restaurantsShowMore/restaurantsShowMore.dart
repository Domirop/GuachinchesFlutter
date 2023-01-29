import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/ui/components/cards/topRestaurantCard.dart';
import 'package:guachinches/ui/components/cards/TopRestaurantListCard.dart';

class RestaurantShowMore extends StatefulWidget {
  String type;
  RestaurantShowMore(this.type);

  @override
  _RestaurantShowMoreState createState() => _RestaurantShowMoreState();
}

class _RestaurantShowMoreState extends State<RestaurantShowMore> {
  _RestaurantShowMoreText top = new _RestaurantShowMoreText('Top restaurantes','Te '
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
            BlocBuilder<TopRestaurantCubit, TopRestaurantState>(
            builder: (context, state) {
              if (state is TopRestaurantLoaded){
              return Container(
                width: double.infinity,
                child: ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: state.restaurants.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      return TopRestaurantListCard(state.restaurants[index]);
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