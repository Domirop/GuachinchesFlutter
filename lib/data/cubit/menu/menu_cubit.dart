import 'package:bloc/bloc.dart';

class MenuState {
   final int selectedIndex;

  MenuState({required this.selectedIndex});
}

class MenuCubit extends Cubit<MenuState> {
  MenuCubit() : super(MenuState(selectedIndex: 0));

  void updateSelectedIndex(int newIndex) {
    emit(MenuState(selectedIndex: newIndex));
  }
}