import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/Categorias/categorias_presenter.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/categories_state.dart';
import 'package:http/http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/Category.dart';

class Categorias extends StatefulWidget {
  @override
  _CategoriasState createState() => _CategoriasState();
}

class _CategoriasState extends State<Categorias> implements CategoriasView{
  TextEditingController textFieldBuscar = new TextEditingController();
  List<ModelCategory> categories = [];
  CategoriasPresenter presenter;
  RemoteRepository remoteRepository;

  @override
  void initState() {
    final categoriesCubit = context.read<CategoriesCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter =
        CategoriasPresenter(remoteRepository, this, categoriesCubit);
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
                        int rows = (state.categories.length / 2).round();
                        return Wrap(
                          children: state.categories.map((e) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 30.0),
                                color: Colors.red,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      child: Image.network(
                                        e.iconUrl,
                                        height: 100.0,
                                        width: 100.0,
                                      ),
                                    ),
                                    Text(e.nombre),
                                  ],
                                ),
                              );}
                        ).toList(),
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
    List<ModelCategory> aux = categories.where((element) => element.nombre.contains(e)).toList();
    setState(() {
      categories = aux;
    });
  }

  @override
  setAllCategories(List<ModelCategory> categories) {
    setState(() {
      this.categories = categories;
    });
  }

}
