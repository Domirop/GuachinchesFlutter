import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/main/menu/menu.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';

class AppBarBasic {
  Home home;
  List<Widget> screens;

  AppBarBasic(this.home, this.screens);

  AppBar createWidget(BuildContext context) {
    return AppBar(
      leadingWidth: 50.0,
      leading: Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Image(
          image: AssetImage('assets/images/logo.png'),
        ),
      ),
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
                    color: Colors.black,
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
                  color: Colors.black,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }

}
