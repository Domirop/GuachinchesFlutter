import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:guachinches/profile.dart';
import 'package:guachinches/reviews.dart';
import 'Valoraciones.dart';
import 'home/home.dart';

class Menu extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Menu> {
  int selectedItem = 0;
  int aux;
  List<Widget> screens = [Home(), Reviews(), Profile()];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return screens.length == 0
        ? SpinKitPulse(
            color: Colors.black,
          )
        : Scaffold(
            body: screens[selectedItem],
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
                textTheme: Theme.of(context).textTheme.copyWith(
                      caption: TextStyle(color: Colors.white),
                    ),
              ),
              child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.home,
                        color: Colors.black,
                      ),
                      label: "",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.star_half,
                        color: Colors.black,
                      ),
                      label: "",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: Colors.black,
                      ),
                      label: "",
                    ),
                  ],
                  currentIndex: selectedItem,
                  onTap: showScreen),
            ),
          );
  }

  @override
  showScreen(int index) {
    setState(() {
      selectedItem = index;
    });
  }
}
