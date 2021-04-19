import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Categorias extends StatefulWidget {
  @override
  _CategoriasState createState() => _CategoriasState();
}

class _CategoriasState extends State<Categorias> {
  TextEditingController textFieldBuscar = new TextEditingController();

  List<String> categories = ["primero", "segundo", "tercero"];
  String value = "primero";
  int aux;

  @override
  Widget build(BuildContext context) {
    aux = -1;
    double listIndexs = categories.length / 2.0;
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
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Material(
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                shadowColor: Colors.black,
                child: DropdownButtonFormField(
                  items: categories.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                  value: value,
                  iconSize: 0.0,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: Colors.black,
                      size: 35.0,
                    ),
                    disabledBorder: InputBorder.none,
                  ),
                  isExpanded: true,
                ),
              ),
              SizedBox(
                height: 30.0,
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
                itemCount: listIndexs.round(),
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  aux++;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            color: Colors.red,
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/images/logo.png",
                                  height: 100.0,
                                  width: 100.0,
                                ),
                                Text(categories[index + aux]),
                              ],
                            ),
                          ),
                          (aux + 1) >= listIndexs.round()
                              ? Container(
                                  width: 100.0,
                                )
                              : Container(
                                  color: Colors.red,
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/images/logo.png",
                                        height: 100.0,
                                      ),
                                      Text(categories[index + aux + 1]),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                      SizedBox(
                        height: 30.0,
                      ),
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
}
