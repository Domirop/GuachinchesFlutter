import 'package:flutter/material.dart';
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
class GlobalMethods {
  BuildContext context;




  void pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
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