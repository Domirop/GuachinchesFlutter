import 'package:flutter/material.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home_presenter.dart';

class AppBarSearch {
  String _value;
  HomePresenter _presenter;
  Home home;

  AppBarSearch(this._presenter, this.home);

  String get value => _value;

  AppBar createWidget(BuildContext context) {
    return AppBar(
      title: TextFormField(
        scrollPadding:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 200.0),
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: "Buscar",
          hintStyle: TextStyle(
            color: Colors.black,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
        ),
        onChanged: !home.isChargingInitalRestaurants
            ? () {}
            : (e) => _value = e.toLowerCase(),
      ),
      leading: GestureDetector(
          onTap: !home.isChargingInitalRestaurants ? () {} : changeAppBarState,
          child: Icon(
            Icons.close,
            color: Colors.black,
          )),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: !home.isChargingInitalRestaurants
                ? () {}
                : searchRestaurantsByName,
            child: Icon(
              Icons.search,
              color: Colors.black,
              size: 40.0,
            ),
          ),
        )
      ],
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }

  searchRestaurantsByName() {
    _presenter.getRestaurantsFilter(home.restaurants, _value);
    _presenter.callCreateNewRestaurantsList();
  }

  changeAppBarState() async {
    _presenter.changeCharginInitial();
    _presenter.changeStateAppBar(false);
    await _presenter.getAllRestaurants();
    _presenter.callCreateNewRestaurantsList();
  }
}
