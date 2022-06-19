import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/history_full_page/history_full_page_presenter.dart';
import 'package:http/http.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';

class PreSaveCupon extends StatefulWidget {
  CuponesAgrupados cuponesAgrupados;
  HistoryFullPageView view;
  String userId;

  PreSaveCupon(this.cuponesAgrupados, this.view, this.userId);

  @override
  State<PreSaveCupon> createState() => _PreSaveCuponState();
}

class _PreSaveCuponState extends State<PreSaveCupon> {
  HistoryFullPagePresenter presenter;
  RemoteRepository remoteRepository;
  String id = "";

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HistoryFullPagePresenter(widget.view, remoteRepository);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                height: 300,
                child: Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 161,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          repeat: ImageRepeat.noRepeat,
                          alignment: Alignment.center,
                          fit: BoxFit.cover,
                          image: AssetImage('assets/images/fotocupones.png'),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/logoGrande.png'),
                            width: 79,
                            height: 71,
                          ),
                          Text(
                            "Cupón -" +
                                widget.cuponesAgrupados.cupones[0].descuento
                                    .toString() +
                                "%",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      top: 140,
                      child: Container(
                        height: 150,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        width: MediaQuery.of(context).size.width - 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  repeat: ImageRepeat.noRepeat,
                                  alignment: Alignment.center,
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                      widget.cuponesAgrupados.foto),
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              width: MediaQuery.of(context).size.width / 3.5,
                              height: 105,
                            ),
                            Flexible(
                              child: Container(
                                margin: EdgeInsets.only(left: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.cuponesAgrupados.nombre,
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    widget.cuponesAgrupados.avgRating != null
                                        ? Column(
                                            children: [
                                              RatingBar.builder(
                                                ignoreGestures: true,
                                                initialRating: widget
                                                    .cuponesAgrupados.avgRating,
                                                minRating: 1,
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemSize: 10,
                                                glowColor: Colors.white,
                                                onRatingUpdate: (rating) => {},
                                                itemPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                itemBuilder: (context, _) =>
                                                    Icon(
                                                  Icons.star,
                                                  color: Color.fromRGBO(
                                                      0, 189, 195, 1),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 8.0,
                                              ),
                                            ],
                                          )
                                        : Container(),
                                    Text(
                                      widget.cuponesAgrupados.open
                                          ? "Abierto"
                                          : "Cerrado",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: widget.cuponesAgrupados.open
                                            ? Color.fromRGBO(149, 220, 0, 1)
                                            : Color.fromRGBO(226, 120, 120, 1),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    Text(
                                      widget.cuponesAgrupados.direccion,
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                width: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Selecciona un dia",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Wrap(
                      direction: Axis.horizontal,
                      children: generateButtonDate(),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Selecciona un turno",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              GestureDetector(
                onTap: () => {
                  GlobalMethods().popPage(context),
                  presenter.saveCupon(id, widget.userId)
                },
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  margin: EdgeInsets.symmetric(horizontal: 40.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(28, 195, 137, 1),
                    borderRadius: BorderRadius.circular(11.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Text(
                    "Confirmar",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0),
                  ),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              GestureDetector(
                onTap: () => {
                  GlobalMethods().popPage(context),
                },
                child: Text(
                  "Cancelar",
                  style: TextStyle(
                    color: Color.fromRGBO(242, 62, 74, 1),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  generateButtonDate() {
    List<Widget> widgets = [];
    widget.cuponesAgrupados.cupones.forEach((element) {
      widgets.add(GestureDetector(
        onTap: () => {
          if (mounted)
            {
              setState(() {
                this.id = element.id;
              })
            }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: MediaQuery.of(context).size.width / 4,
          padding: EdgeInsets.symmetric(
            vertical: 10,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: Color.fromRGBO(0, 133, 196, 1),
            ),
            color: element.id == id
                ? Color.fromRGBO(0, 133, 196, 1)
                : Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              element.minDate,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: element.id == id ? Colors.white : Colors.black,
                  fontSize: 14.0),
            ),
          ),
        ),
      ));
    });
    return widgets;
  }
}
