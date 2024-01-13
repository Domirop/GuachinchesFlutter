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
      title: Row(
        children: [
          Icon(Icons.location_on,color: Color.fromRGBO(23, 23, 23, 1),size: 22),
          SizedBox(width: 8,),
          Text('Nueva york, 40',style: TextStyle(
            fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(23, 23, 23, 1),)
          ),
          SizedBox(width: 4,),
          Icon(Icons.keyboard_arrow_down,color: Color.fromRGBO(23, 23, 23, 1),size: 22),
        ],
      ),

      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

}
