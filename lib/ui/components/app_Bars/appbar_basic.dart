import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page.dart';

class AppBarBasic {
  Home home;

  AppBarBasic(this.home);

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
                    GlobalMethods().pushPage(context, SearchPage());
                  },
                  child: Icon(
                    Icons.search,
                    color: Colors.black,
                    size: 30.0,
                  ),
                ),
              ),
              // Container(
              //   margin: EdgeInsets.only(right: 10.0),
              //   child: GestureDetector(
              //     onTap: () {},
              //     child: Icon(
              //       Icons.notifications_none,
              //       color: Colors.black,
              //       size: 30.0,
              //     ),
              //   ),
              // ),
              GestureDetector(
                onTap: () {
                  GlobalMethods().pushPage(context, SearchPage());
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
