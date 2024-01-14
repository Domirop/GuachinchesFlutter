import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/Categorias/categorias.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/filter/filter_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_state.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/cards/restaurantListCard.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/map/search_text_presenter.dart';
import 'package:http/http.dart';

class SearchText extends StatefulWidget {
  const SearchText();

  @override
  State<SearchText> createState() => _SearchTextState();
}

class _SearchTextState extends State<SearchText> implements SearchTextView{
  late FocusNode _focusNode;
  TextEditingController _textEditingController = TextEditingController();
  late RemoteRepository remoteRepository;
  late SearchTextPresenter presenter;
  late RestaurantCubit restaurantsCubit;
  List<Restaurant> restaurants = [];
  late FilterCubit filterCubit;

  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    restaurantsCubit = context.read<RestaurantCubit>();
    presenter = SearchTextPresenter(this, remoteRepository, restaurantsCubit);
    super.initState();
    _focusNode = FocusNode();
    filterCubit = context.read<FilterCubit>();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _clearText() {
    setState(() {
      _textEditingController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Busqueda en mapa',
          style: TextStyle(color: Color.fromRGBO(23, 23, 23, 1)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child:  BlocBuilder<FilterCubit, FilterState>(
              builder: (context, state) {
                List<String> municipalities = [];
                List<String> categories = [];
                List<String> types = [];
                  if (state is FilterCategory) {
                    municipalities = state.municipalitesSelected;
                    categories = state.categorySelected;
                    types = state.typesSelected;

                }
              return TextField(
                onChanged: (value){

                  presenter.getAllRestaurantsFilterByText(value);

                },
                onEditingComplete: (){
                  restaurantsCubit.getFilterRestaurants(
                      categories: categories,
                      municipalities:municipalities,
                      isOpen:true,
                      islandId:
                      '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d',
                      types: types,
                      text: _textEditingController.text
                  );
                  filterCubit.handleFilterChange(categories, municipalities, types, _textEditingController.text);
                  Navigator.pop(context);
                },
                controller: _textEditingController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                  hintText: 'Buscar',
                  hintStyle: TextStyle(color: Color.fromRGBO(97, 97, 97, 1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color.fromRGBO(97, 97, 97, 1),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Color.fromRGBO(97, 97, 97, 1),
                    ),
                    onPressed: _clearText,
                  ),
                ),
              );
              }

              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0,right: 8),
              child: ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: restaurants.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    return RestaurantListCard(restaurants[index]);
                  }),
            )
          ],
        ),
      ),
    );
  }

  @override
  setRestaurantsFilter(List<Restaurant> restaurants) {
    print('restaurants: '+restaurants.length.toString());
    setState(() {
      this.restaurants = restaurants;
    });
  }
}
