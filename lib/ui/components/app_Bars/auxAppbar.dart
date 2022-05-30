import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';

class AppBarSearch extends StatefulWidget {
  List<ModelCategory> categories;
  List<Municipality> municipality;
  AppBarSearch(this.categories, this.municipality);

  @override
  State<AppBarSearch> createState() => _AppBarSearchState();
}

class _AppBarSearchState extends State<AppBarSearch> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
