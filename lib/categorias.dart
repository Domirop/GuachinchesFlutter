import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'model/Category.dart';

class Categorias extends StatefulWidget {
  @override
  _CategoriasState createState() => _CategoriasState();
}

class _CategoriasState extends State<Categorias> {
  TextEditingController textFieldBuscar = new TextEditingController();

  List<Category> categories = [
    Category.fromJson({
      "id": "76e52d7a-8c9b-4b2e-a74a-bcd74af4d4f5",
      "nombre": "Ternera",
      "iconUrl": "https://louvre.s3.fr-par.scw.cloud/Guachinches/cow.png"
    }),
    Category.fromJson({
      "id": "16bd1169-9b0c-43d8-985b-42699dab2527",
      "nombre": "Cerdo",
      "iconUrl": "https://louvre.s3.fr-par.scw.cloud/Guachinches/pig.png"
    })
  ];

  @override
  Widget build(BuildContext context) {
    int rows = (categories.length / 2).round();
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
              ListView.builder(
                shrinkWrap: true,
                primary: false,
                itemCount: rows,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 30.0),
                            color: Colors.red,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  child: Image.network(
                                    categories[index].iconUrl,
                                    height: 100.0,
                                    width: 100.0,
                                  ),
                                ),
                                Text(categories[index].nombre),
                              ],
                            ),
                          ),
                          categories.length >= index + rows + 1 ? Container(
                            margin: EdgeInsets.symmetric(horizontal: 30.0),
                            color: Colors.red,
                            child: Column(
                              children: [
                                Container(
                                  child: Image.network(
                                    categories[index + 1].iconUrl,
                                    height: 100.0,
                                    width: 100.0,
                                  ),
                                ),
                                Text(categories[index + 1].nombre),
                              ],

                            ),
                          ) : Container()
                        ],
                      ),
                      SizedBox(height: 15,),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  searchCategory(e) {
    List<Category> aux = categories.where((element) => element.nombre.contains(e)).toList();
    setState(() {
      categories = aux;
    });
  }
}
