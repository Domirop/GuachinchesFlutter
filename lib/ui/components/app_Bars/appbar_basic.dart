import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/menu/menu.dart';
import 'package:guachinches/ui/pages/home/home.dart';


class AppBarBasic {
  Home home;
  List<Widget> screens;

  AppBarBasic(this.home, this.screens);

  AppBar createWidget(BuildContext context) {
    return AppBar(
      title: Image.asset('assets/images/logo3.png', fit: BoxFit.cover),

      actions: [
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    GlobalMethods().pushAndReplacement(context, Menu(screens, selectedItem: 1));
                  },
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  GlobalMethods().pushAndReplacement(context, Menu(screens, selectedItem: 3));
                },
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),
      ],
      backgroundColor: Color.fromRGBO(5, 7, 20, 1),
      elevation: 5.0,
    );
  }

}
