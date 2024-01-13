import 'package:bloc/bloc.dart';
import 'package:guachinches/data/cubit/filter/filter_state.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/restaurant.dart';

class FilterCubit extends Cubit<FilterState> {
  late Restaurant restaurant;

  FilterCubit() : super(FilterInitial());

  Future<void> handleFilterChange(List<String> filterCategoryIds,List<String> municipalities, List<String> selectedTypes) async {
    if(filterCategoryIds.isEmpty&&municipalities.isEmpty&& selectedTypes.isEmpty){
      emit(FilterInitial());
    }else {
      emit(FilterCategory(filterCategoryIds, municipalities, selectedTypes));
    }
  }
}
