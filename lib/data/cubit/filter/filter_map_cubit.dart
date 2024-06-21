import 'package:bloc/bloc.dart';

import 'filter_map_state.dart';

class FilterCubitMap extends Cubit<FilterMapStateCubit> {

  FilterCubitMap() : super(FilterInitialMap());

  Future<void> handleFilterChange(List<String> filterCategoryIds,List<String> municipalities, List<String> selectedTypes,String text) async {
    if(filterCategoryIds.isEmpty&&municipalities.isEmpty&& selectedTypes.isEmpty && text.isEmpty){
      emit(FilterInitialMap());
    }else {
      emit(FilterCategoryMap(filterCategoryIds, municipalities, selectedTypes,text));
    }
  }

}
