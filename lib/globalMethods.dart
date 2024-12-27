import 'package:flutter/material.dart';
import 'package:guachinches/data/model/CuponesUser.dart';
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
class GlobalMethods {
  late BuildContext context;


  static Color bgColor = Color.fromRGBO(25, 27, 32, 1);

  static Color blueColor = Color.fromRGBO(0, 133, 196, 1);

  void pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),

    );

  }
  //return island name from island id
  String getIslandName(String id){
    switch(id){
      case '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d':
        return "Tenerife";
      case '6f91d60f-0996-4dde-9088-167aab83a21a':
        return "Gran Canaria";
      default:
        return "Tenerife";
    }
  }
  void pushPageWithFocus(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration(milliseconds: 180),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),


    )
    ;

  }
  List<CuponesUser> getOnlyValidCouponUser(List<CuponesUser> cupones){
    List<CuponesUser> validCupones =[];
    for(int i = 0 ;i<cupones.length;i++){
      DateTime couponDate = DateTime.parse( cupones[i].cupon!.date);
      couponDate.add(Duration( hours: 23,minutes: 59));
      DateTime today = DateTime.now();
      if(couponDate.isAfter(today)){
        validCupones.add(cupones[i]);
      }
    }
    return validCupones;

  }

  void pushAndReplacement(BuildContext context, Widget widget) {
    Navigator.pushReplacement(
        context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget,
        transitionDuration: Duration(milliseconds: 180),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    )
    ;
  }

  void pushAndRemoveAll(BuildContext context, Widget widget) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget,
        transitionDuration: Duration(milliseconds: 180),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
          (Route<dynamic> route) => false, // Esta condición asegura que todas las rutas anteriores sean eliminadas.
    );
  }

  void popPage(BuildContext page) {
    Navigator.pop(page);
  }
  void refreshPage(BuildContext context,Widget widget) {
    Navigator.pop(context);
    pushAndReplacement(context, widget);
  }

  removePages(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  removePagesAndGoToNewScreen(BuildContext context, Widget widget) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => widget), (route) => false);
  }
}