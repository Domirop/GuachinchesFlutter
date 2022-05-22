import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_search.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  AppBarSearch appBarSearch;

  @override
  void initState() {
    appBarSearch = new AppBarSearch();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: appBarSearch.createWidget(context),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: generateDestacadosView(),
            ),
            Icon(Icons.directions_transit),
            Icon(Icons.directions_bike),
          ],
        ),
      ),
    );
  }

  generateDestacadosView() {
    List<Restaurant> aux = [];
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Wrap(
        children: generateCards(aux),
      ),
    );
  }

  generateCards(List<Restaurant> restaurants) {
    List<Widget> widgets = [];
    restaurants = [
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant(),
      Restaurant()
    ];
    restaurants.forEach((element) {
      widgets.add(Container(
        width: MediaQuery.of(context).size.width * 0.33,
        height: 139,
        decoration: BoxDecoration(
          image: DecorationImage(
            repeat: ImageRepeat.noRepeat,
            alignment: Alignment.center,
            fit: BoxFit.fill,
            image: NetworkImage(
                "https://i.pinimg.com/550x/a6/51/1e/a6511e138352d38726e03b69d18bccdf.jpg"),
          ),
        ),
        child: Center(
          child: Text(
            "El Cordero de pepe y de juan",
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ));
    });
    return widgets;
  }
}
