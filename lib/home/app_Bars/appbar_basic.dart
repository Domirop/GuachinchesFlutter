import 'package:flutter/material.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/home/home_presenter.dart';
import 'package:guachinches/municipality_screen/municipality_screen.dart';

class AppBarBasic {
  String _title;
  String _useMunicipality = "";
  String _municipalityNameArea = "";
  String _municipalityName = "";
  HomePresenter _presenter;
  Home home;

  AppBarBasic(this._presenter, this.home);

  AppBar createWidget(BuildContext context) {
    setLocationData();
    _title = "";
    if (_useMunicipality == "Todos") {
      _title = "Todos";
    } else if (_useMunicipality == "true") {
      _title = _municipalityName;
    } else {
      _title = _municipalityNameArea;
    }
    return AppBar(
      title: GestureDetector(
        onTap: !home.isChargingInitalRestaurants ? () {} : goToSelectMunicipality,
        child: Container(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _title,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
      centerTitle: true,
      leadingWidth: 50.0,
      titleSpacing: 20.0,
      leading: Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Image(
          image: AssetImage('assets/images/logo.png'),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: !home.isChargingInitalRestaurants ? () {} : changeAppBarState,
            child: Icon(
              Icons.search,
              color: Colors.black,
              size: 40.0,
            ),
          ),
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }

  changeAppBarState(){
    _presenter.changeStateAppBar(true);
  }

  goToSelectMunicipality() {
    _presenter.changeScreen(MunicipalityScreen());
  }

  setLocationData() async {
    var data  = await _presenter.getSelectedMunicipality();
    _useMunicipality = data["useMunicipality"];
    _municipalityNameArea = data["municipalityNameArea"];
    _municipalityName = data["municipalityName"];
  }
}
