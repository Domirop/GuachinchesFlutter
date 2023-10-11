import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
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
  _RestaurantShowMoreText top = new _RestaurantShowMoreText('Guachinches norte TF',
      'Un guachinche es un establecimiento de comida típica canaria, que se caracteriza por ser un lugar familiar, con comida casera y vino de cosecha propia. Te mostramos los guachinches locales del norte tenerife desde los más tradicionales a los más modernos, para que puedas disfrutar de la gastronomía canaria en su máxima expresión. ');

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
            Text('¿Qué es un guachinche?',style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20
            ),),
            SizedBox(
              height: 16.0,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(top.subtitle,
               textAlign: TextAlign.justify,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 16
              ),),
            ),
            SizedBox(
              height: 16.0,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Divider(
                color: Colors.black,
                thickness: 0.1,),
            ),
            SizedBox(
              height: 8.0,
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
                      TopRestaurants topRestaurant = new TopRestaurants(
                          nombre: restaurants[index].nombre,
                          open: restaurants[index].open,
                          id:restaurants[index].id,horarios: restaurants[index].horarios,direccion: restaurants[index].direccion,counter: restaurants[index].avgRating.toString(),imagen: restaurants[index].mainFoto,cerrado: restaurants[index].open.toString(),municipio: restaurants[index].municipio,avg: restaurants[index].avgRating);
                      return TopRestaurantListCard(topRestaurant);
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