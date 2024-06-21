import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/Municipality.dart';

@immutable
abstract class FilterState {
  const FilterState();
}

class FilterInitial extends FilterState {
  const FilterInitial();
}

class FilterCategory extends FilterState {
  final List<String> categorySelected;
  final List<String> municipalitesSelected;
  final List<String> typesSelected;
  final String text;
  const FilterCategory(this.categorySelected,this.municipalitesSelected, this.typesSelected,this.text);

  @override
  bool operator == (Object o) {
    if (identical(this, o)) return true;
    return o is FilterCategory && o.text == text&& o.categorySelected ==categorySelected&&o.typesSelected == typesSelected &&o.municipalitesSelected==municipalitesSelected;
  }

}
