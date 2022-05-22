import 'package:flutter/material.dart';

class AppBarSearch {
  String _value;
  var numero = 1;

  AppBarSearch();

  String get value => _value;

  AppBar createWidget(BuildContext context) {
    return AppBar(
      actions: [
        Container(
          height: 40,
          padding: EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () => {},
            child: Container(
              width: 100,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 133, 196, 1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  "Filtros - " + numero.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12.0),
                ),
              ),
            ),
          ),
        ),
      ],
      titleSpacing: 1,
      leadingWidth: 0,
      title: Container(
          height: 60,
          padding: EdgeInsets.all(10.0),
          child: TextField(

            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintStyle: TextStyle(color: Color.fromRGBO(0, 133, 196, 1)),
              filled: true,
              fillColor: Color.fromRGBO(237, 230, 215, 0.42),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.transparent, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                borderSide: BorderSide(color: Colors.transparent, width: 2),
              ),
            ),
          )),
      bottom: TabBar(
        labelColor: Colors.black,
        labelStyle: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(text: "Destacado"),
          Tab(text: "Restaurantes"),
          Tab(text: "Cupones"),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }
}
