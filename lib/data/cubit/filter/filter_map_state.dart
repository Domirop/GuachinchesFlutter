import 'package:flutter/foundation.dart';

@immutable
abstract class FilterMapStateCubit {
  const FilterMapStateCubit();
}

class FilterInitialMap extends FilterMapStateCubit {
  const FilterInitialMap();
}

class FilterCategoryMap extends FilterMapStateCubit {
  final List<String> categorySelected;
  final List<String> municipalitesSelected;
  final List<String> typesSelected;
  final String text;
  const FilterCategoryMap(this.categorySelected,this.municipalitesSelected, this.typesSelected,this.text);

  @override
  bool operator == (Object o) {
    if (identical(this, o)) return true;
    return o is FilterCategoryMap && o.text == text&& o.categorySelected ==categorySelected&&o.typesSelected == typesSelected &&o.municipalitesSelected==municipalitesSelected;
  }

}
