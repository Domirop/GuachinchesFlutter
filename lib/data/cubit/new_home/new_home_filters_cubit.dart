import 'package:flutter_bloc/flutter_bloc.dart';
import 'new_home_filters_state.dart';

class NewHomeFiltersCubit extends Cubit<NewHomeFiltersState> {
  NewHomeFiltersCubit() : super(NewHomeFiltersState.initial);

  void selectIsland({
    required String id,
    required String key,
    required String label,
  }) {
    emit(state.copyWith(
      islandId: id,
      islandKey: key,
      islandLabel: label,
      clearZone: true,
      clearMunicipality: true,
    ));
  }

  void selectZone({required String key, required String label}) {
    emit(state.copyWith(
      zoneKey: key,
      zoneLabel: label,
      clearMunicipality: true,
    ));
  }

  void clearZone() {
    emit(state.copyWith(clearZone: true, clearMunicipality: true));
  }

  void selectMunicipality({required String id, required String label}) {
    emit(state.copyWith(municipalityId: id, municipalityLabel: label));
  }

  void clearMunicipality() {
    emit(state.copyWith(clearMunicipality: true));
  }

  void selectCategory({required String id, required String label}) {
    emit(state.copyWith(categoryId: id, categoryLabel: label));
  }

  void clearCategory() {
    emit(state.copyWith(clearCategory: true));
  }
}
