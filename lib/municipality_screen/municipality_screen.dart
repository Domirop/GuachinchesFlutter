import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/model/Municipality.dart';
import 'package:guachinches/municipality_screen/municipality_presenter.dart';
import 'package:guachinches/valoraciones/valoraciones.dart';
import 'package:http/http.dart';

import '../menu/menu.dart';
import '../profile/profile.dart';

class MunicipalityScreen extends StatefulWidget {
  @override
  _MunicipalityScreenState createState() => _MunicipalityScreenState();
}

class _MunicipalityScreenState extends State<MunicipalityScreen>
    implements MunicipalityView {
  List<Municipality> municipalities = [];
  MunicipalityPresenter presenter;
  String selectedMunicipalityId = "";
  RemoteRepository remoteRepository;
  int index = -1;

  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    presenter = MunicipalityPresenter(remoteRepository, this);
    presenter.getAllMunicipalities();
    presenter.defaultSelection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
          onPressed: () => GlobalMethods().pushAndReplacement(
              context, Menu([Home(), Valoraciones(), Profile()])),
        ),
        title:
            Text("Lista de Municipios", style: TextStyle(color: Colors.black)),
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
              ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: municipalities.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 45.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => {
                                  presenter.storeMunicipality(
                                      null, null, municipalities[index].id, municipalities[index].nombre),
                                  GlobalMethods().pushAndReplacement(
                                      context,
                                      Menu(
                                          [Home(), Valoraciones(), Profile()])),
                                },
                                child: Text(
                                  municipalities[index].nombre,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              municipalities[index].municipalities.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () => {
                                        if (this.index == index)
                                          {
                                            setState(() {
                                              this.index = -1;
                                            })
                                          }
                                        else
                                          {
                                            setState(() {
                                              this.index = index;
                                            })
                                          }
                                      },
                                      child: Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(222, 99, 44, 1),
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                        child: Icon(
                                          this.index == index
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                  .keyboard_arrow_down_rounded,
                                          size: 30.0,
                                        ),
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                        this.index == index
                            ? Column(
                                children: municipalities[index]
                                    .municipalities
                                    .map((a) => GestureDetector(
                                          onTap: () => {
                                            presenter.storeMunicipality(
                                                a.nombre, a.id, municipalities[index].id, municipalities[index].nombre),
                                            GlobalMethods().pushAndReplacement(
                                                context,
                                                Menu([
                                                  Home(),
                                                  Valoraciones(),
                                                  Profile()
                                                ])),
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black54,
                                                    blurRadius: 6.0,
                                                    spreadRadius: 1.0,
                                                    offset: Offset(1.0, 2.0))
                                              ],
                                              borderRadius:
                                                  BorderRadius.circular(7.0),
                                            ),
                                            child: Center(
                                              child: Text(
                                                a.nombre,
                                                style: TextStyle(
                                                    color:
                                                        selectedMunicipalityId ==
                                                                a.id
                                                            ? Colors.black
                                                            : Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              )
                            : Container(),
                        SizedBox(height: 25.0),
                      ],
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  setAllMunicipalities(List<Municipality> municipalities) {
    setState(() {
      Municipality municipality =
          Municipality.fromJson({"Id": "Todos", "Nombre": "Todos"});
      municipalities.insert(0, municipality);
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
