import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/model/Municipality.dart';
import 'package:guachinches/municipality_screen/municipality_presenter.dart';
import 'package:http/http.dart';

import '../menu.dart';

class MunicipalityScreen extends StatefulWidget {
  @override
  _MunicipalityScreenState createState() => _MunicipalityScreenState();
}

class _MunicipalityScreenState extends State<MunicipalityScreen> implements MunicipalityView{
  List<Municipality> municipalities = [];
  MunicipalityPresenter presenter;
  String selectedMunicipalityId = "";
  RemoteRepository remoteRepository;
  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    presenter = MunicipalityPresenter(remoteRepository,this );
    presenter.getAllMunicipalities();
    presenter.defaultSelection();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
          onPressed: () =>GlobalMethods().pushAndReplacement(context, Menu()),
        ),
        title:Text("Lista de Municipios",
            style: TextStyle(color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: WillPopScope(
        onWillPop: () async {
          GlobalMethods().pushAndReplacement(context, Home());
          return false;
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: municipalities.map((e) => GestureDetector(
                  onTap: ()=> presenter.storeMunicipality(e.nombre, e.id),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey))
                    ),
                    child: Center(
                      child: Text(e.nombre,
                      style: TextStyle(color: selectedMunicipalityId == e.id ? Colors.black:Colors.grey),),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  setAllMunicipalities(List<Municipality> municipalities) {
    setState(() {
      Municipality municipality = Municipality.fromJson({"Id":"","Nombre":"Todos"});
      municipalities.insert(0,municipality);
      this.municipalities = municipalities;
    });
  }

  @override
  selectedMunicipality(String municipalityId) {
    setState(() {
      selectedMunicipalityId = municipalityId;
    });
  }

}

