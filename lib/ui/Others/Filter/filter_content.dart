import 'package:flutter/material.dart';

class FilterContent extends StatefulWidget {

  const FilterContent({
    Key key,
  }) : super(key: key);

  @override
  _FilterContentState createState() => _FilterContentState();
}

class _FilterContentState extends State<FilterContent> {
  List<String> days = ["Lunes","Martes","Miércoles","Jueves","Viernes","Sábado","Domingo"];
  _generateWeekDayList(){
    List<Widget> components = [];
    for(int i=0; i<days.length;i++){
      Widget component =  GestureDetector(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(days[i]),
          ),
        ),
      );
      components.add(component);

  }
    return components;
  }
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      height: screenHeight * 0.63,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: screenHeight * 0.02,
          ),
          Center(child: Text("Filtros")),
          SizedBox(
            height: screenHeight * 0.02,
          ),
          Text("Dias abierto*"),
          Text(
            "Se reflejan los días abiertos con un funcionamiento normal, se pueden ver afectados por festividades.",
            style: TextStyle(fontSize: 10),
          ),
          SizedBox(
            height: screenHeight * 0.01,
          ),
          Wrap(
            children: _generateWeekDayList()
            ,
          )
        ],
      ),
    );

  }

}
