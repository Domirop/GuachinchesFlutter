import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Menu extends StatefulWidget {
  List<Widget> screens;
  int selectedItem;

  Menu(this.screens, {this.selectedItem});

  @override
  _ProfileState createState() => _ProfileState(screens);
}

class _ProfileState extends State<Menu>{
  int selectedItem = 0;
  int aux;
  List<Widget> screens;

  _ProfileState(this.screens);

  @override
  void initState() {
    if(widget.selectedItem != null) selectedItem = widget.selectedItem;
    final userCubit = context.read<UserCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;


    return screens.length == 0
        ? SpinKitPulse(
            color: Colors.black,
          )
        : Scaffold(
            body: IndexedStack(
              children: screens,
              index: selectedItem,
            ),
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
                textTheme: Theme.of(context).textTheme.copyWith(
                      caption: TextStyle(color: Colors.white),
                    ),
              ),
              child: BottomNavigationBar(
                selectedItemColor: Colors.blue,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.home,
                      ),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.search,
                      ),
                      label: "Buscar",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.star_half,
                      ),
                      label: "Valoraciones",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.account_circle_outlined,
                      ),
                      label: "Mi perfil",
                    ),
                  ],
                  currentIndex: selectedItem,
                  onTap: showScreen),
            ),
          );
  }

  showScreen(int index) {
    setState(() {
      selectedItem = index;
    });
  }
}
