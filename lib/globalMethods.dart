import 'package:flutter/material.dart';

class GlobalMethods {
  BuildContext context;

  void pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void pushAndReplacement(BuildContext context, Widget widget) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (BuildContext context) => widget));
  }

  void popPage(BuildContext page) {
    Navigator.pop(page);
  }

  removePages(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  removePagesAndGoToNewScreen(BuildContext context, Widget widget) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => widget), (route) => false);
  }
}