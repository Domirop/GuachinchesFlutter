import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/Categorias/categorias_presenter.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/categories_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/splash_screen/splash_screen.dart';
import 'package:http/http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/Category.dart';

class Categorias extends StatefulWidget {
  @override
  _CategoriasState createState() => _CategoriasState();
}

class _CategoriasState extends State<Categorias> implements CategoriasView {
  TextEditingController textFieldBuscar = new TextEditingController();
  List<ModelCategory> categories = [];
  CategoriasPresenter presenter;
  RemoteRepository remoteRepository;
  String filterCategory = "";

  @override
  void initState() {
    final categoriesCubit = context.read<CategoriesCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = CategoriasPresenter(this, categoriesCubit);
    if (categoriesCubit.state is CategoriesInitial) {
      presenter.getAllCategories();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 40.0,
              ),
              Material(
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                shadowColor: Colors.black,
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  controller: textFieldBuscar,
                  decoration: InputDecoration(
                    hintText: "Buscar",
                    hintStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.black,
                    ),
                  ),
                  onChanged: searchCategory,
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Categorías",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Container(
                child: BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                  if (state is CategoriesLoaded) {
                    List<ModelCategory> aux = [];
                    if(filterCategory.isEmpty){
                      aux = state.categories;
                    }else{
                      aux.addAll(state.categories.where((element) => element.nombre.toLowerCase().contains(filterCategory.toLowerCase())));
                    }
                    return Wrap(
                      children: aux.map((e) {
                        return GestureDetector(
                          onTap: () => presenter.setCategoryToSelect(e.id),
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2 - 60,
                            height: 160,
                            margin: EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 5.0,
                                    spreadRadius: 1.0,
                                    offset: Offset(2.0, 4.0))
                              ],
                              borderRadius: BorderRadius.circular(17.0),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  child: SvgPicture.network(
                                    e.iconUrl,
                                    height: 100.0,
                                    width: 100.0,
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(
                                        top: 10.0, left: 5.0, right: 5.0),
                                    child: Text(
                                      e.nombre,
                                      textAlign: TextAlign.center,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return Container();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  searchCategory(e) {
    setState(() {
      filterCategory = e;
    });
  }

  @override
  setAllCategories(List<ModelCategory> categories) {
    setState(() {
      this.categories = categories;
    });
  }

  @override
  categorySelected() {
    GlobalMethods().removePagesAndGoToNewScreen(context, SplashScreen());
  }
}
