import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';

class Menu extends StatefulWidget {
  List<Widget> screens;
  late int selectedItem;

  Menu(this.screens, {required this.selectedItem});

  @override
  _ProfileState createState() => _ProfileState(screens);
}

class _ProfileState extends State<Menu> {
  int selectedItem = 0;
  late int aux;
  List<Widget> screens = [];

  _ProfileState(this.screens);

  @override
  void initState() {
    if (widget.selectedItem != null) selectedItem = widget.selectedItem;
    final userCubit = context.read<UserCubit>();
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    Color bgColor = Color.fromRGBO(25, 27, 32, 1);

    return screens.length == 0
        ? SpinKitPulse(
            color: Colors.black,
          )
        : BlocBuilder<MenuCubit, MenuState>(builder: (context, menuState) {
            return Scaffold(
                body: IndexedStack(
                  children: screens,
                  index: menuState.selectedIndex,
                ),
                bottomNavigationBar: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: bgColor,

                    textTheme: Theme.of(context).textTheme.copyWith(

                          caption: TextStyle(color: Colors.white),
                        ),
                  ),
                  child: BottomNavigationBar(
                    selectedItemColor: Colors.white,  // Color del ítem seleccionado
                      unselectedItemColor: Colors.white70,  // Color del ítem no seleccionado
                      backgroundColor: bgColor,
                      type: BottomNavigationBarType.fixed,
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.home,
                            color: Colors.white,
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
                          label: "Videos",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.account_circle_outlined,
                          ),
                          label: "Mi perfil",
                        ),
                      ],
                      currentIndex: menuState.selectedIndex,
                      onTap: showScreen),
                ),
              );
          }
        );
  }

  showScreen(int index) {
    context.read<MenuCubit>().updateSelectedIndex(index);
    setState(() {
      selectedItem = index;
    });
  }
}
