import 'package:bloc/bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/filter/filter_state.dart';

class FilterCubit extends Cubit<FilterState> {

  FilterCubit() : super(FilterInitial());

  Future<void> handleFilterChange(List<String> filterCategoryIds,List<String> municipalities, List<String> selectedTypes,String text) async {
    if(filterCategoryIds.isEmpty&&municipalities.isEmpty&& selectedTypes.isEmpty && text.isEmpty){
      AppLogger.info('filter-cubit', 'Todo vacio');
      emit(FilterInitial());
    }else {
      emit(FilterCategory(filterCategoryIds, municipalities, selectedTypes,text));
    }
  }

}
