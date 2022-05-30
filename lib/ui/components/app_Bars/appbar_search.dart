import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';

class AppBarSearch {
  String _value;
  var numero = 1;
  List<ModelCategory> categories;
  List<Municipality> municipality;

  AppBarSearch(this.categories, this.municipality);

  String get value => _value;

  AppBar createWidget(BuildContext context) {
    return AppBar(
      actions: [
        Container(
          height: 40,
          padding: EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () => _openBottomSheetWithInfo(context),
            child: Container(
              width: 100,
              height: 30,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 133, 196, 1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  "Filtros - " + numero.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12.0),
                ),
              ),
            ),
          ),
        ),
      ],
      titleSpacing: 1,
      leadingWidth: 0,
      title: Container(
          height: 60,
          padding: EdgeInsets.all(10.0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintStyle: TextStyle(color: Color.fromRGBO(0, 133, 196, 1)),
              filled: true,
              fillColor: Color.fromRGBO(237, 230, 215, 0.42),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.transparent, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                borderSide: BorderSide(color: Colors.transparent, width: 2),
              ),
            ),
          )),
      bottom: TabBar(
        labelColor: Colors.black,
        labelStyle: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(text: "Destacado"),
          Tab(text: "Restaurantes"),
          Tab(text: "Cupones"),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }

  setNumberWidget(number){
    numero = number;
  }

  void _openBottomSheetWithInfo(BuildContext context) {
    showFlexibleBottomSheet<void>(
      bottomSheetColor: Colors.white,
      isExpand: false,
      initHeight: 0.8,
      maxHeight: 0.8,
      context: context,
      builder: (context, controller, offset) {
        return _BottomSheet(controller, categories, municipality, setNumberWidget);
      },
    );
  }
}

class _BottomSheet extends StatefulWidget {
  final ScrollController controller;
  List<ModelCategory> categories;
  List<Municipality> municipality;
  var setNumberWidget;

  _BottomSheet(this.controller, this.categories, this.municipality, this.setNumberWidget);

  @override
  State<_BottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<_BottomSheet> {
  List<String> municipalitiesId = [];
  List<String> categoriesId = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        controller: widget.controller,
        shrinkWrap: true,
        children: createWidgetList(),
      ),
    );
  }

  createWidgetList() {
    List<Widget> widgets = [];
    widgets.add(Container(
      child: Column(
        children: [
          Text(
            "Categorias",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            child: Wrap(
              children: widget.categories
                  .map(
                    (element) => GestureDetector(
                      onTap: () => updateCategoriesId(element.id),
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 10.0),
                        height: 120,
                        width: 110.0,
                        decoration: BoxDecoration(
                          color: categoriesId.contains(element.id)
                              ? Color.fromRGBO(0, 133, 196, 1)
                              : Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black54,
                                blurRadius: 2.0,
                                spreadRadius: 1.0,
                                offset: Offset(2.0, 3.0))
                          ],
                          borderRadius: BorderRadius.circular(17.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.network(
                              element.iconUrl,
                              height: 60.0,
                              width: 60.0,
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 1.0),
                              child: Text(
                                element.nombre != null ? element.nombre : "",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          SizedBox(
            height: 10.0,
          ),
        ],
      ),
    ));
    widgets.add(Container(
      child: Column(
        children: [
          Divider(
            height: 2,
            color: Colors.black,
            endIndent: 2,
            indent: 2,
          ),
          SizedBox(
            height: 10.0,
          ),
          Text(
            "Localización",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            child: Column(
              children: widget.municipality
                  .map((e) => Container(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 10.0,
                            ),
                            GestureDetector(
                              onTap: () => updateMunicipaliesId(e.id),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                height: 40,
                                alignment: Alignment.center,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10),
                                decoration: BoxDecoration(
                                    color: municipalitiesId.contains(e.id)
                                        ? Color.fromRGBO(0, 133, 196, 1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                        color: municipalitiesId.contains(e.id)
                                            ? Colors.black
                                            : Color.fromRGBO(0, 133, 196, 1),
                                        width: 2)),
                                child: Text(
                                  e.nombre,
                                  style: TextStyle(
                                    color: municipalitiesId.contains(e.id)
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            Wrap(
                              children: e.municipalities
                                  .map(
                                    (seconElement) => GestureDetector(
                                      onTap: () => updateMunicipaliesId(e.id),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        height: 40,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 5.0, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: municipalitiesId
                                                    .contains(seconElement.id)
                                                ? Color.fromRGBO(0, 133, 196, 1)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                                color:
                                                    municipalitiesId.contains(
                                                            seconElement.id)
                                                        ? Colors.black
                                                        : Color.fromRGBO(
                                                            0, 133, 196, 1),
                                                width: 2)),
                                        child: Text(
                                          seconElement.nombre,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: municipalitiesId
                                                    .contains(seconElement.id)
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            )
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    ));
    return widgets;
  }

  updateMunicipaliesId(String id) {
    List<String> aux = municipalitiesId;
    if (aux.contains(id))
      aux.remove(id);
    else
      aux.add(id);
    if (mounted) {
      setState(() {
        municipalitiesId = aux;
      });
    }
    widget.setNumberWidget(municipalitiesId.length + categoriesId.length);
  }

  updateCategoriesId(String id) {
    List<String> aux = categoriesId;
    if (aux.contains(id))
      aux.remove(id);
    else
      aux.add(id);
    if (mounted) {
      setState(() {
        categoriesId = aux;
      });
    }
    widget.setNumberWidget(municipalitiesId.length + categoriesId.length);
  }
}
