import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/history_full_page/history_full_page_presenter.dart';
import 'package:guachinches/ui/components/history_full_page/pre_save_cupon.dart';
import 'package:story_view/story_view.dart';

class HistoryFullPage extends StatefulWidget {
  CuponesAgrupados cuponesAgrupados;
  String userId;

  HistoryFullPage(this.cuponesAgrupados, this.userId);

  @override
  _HistoryFullPageState createState() => _HistoryFullPageState();
}

class _HistoryFullPageState extends State<HistoryFullPage>
    implements HistoryFullPageView {
  StoryController controller;
  List<StoryItem> storyItems = [];
  String date = '';
  int index = 0;
  String id = "";
  int descuento = 0;
  bool isCorrectSaveCupon;


  @override
  void initState() {
    super.initState();
    controller = StoryController();
    addStoryItems();
    date = widget.cuponesAgrupados.cupones[0].date;
    descuento = widget.cuponesAgrupados.cupones[0].descuento;
    id = widget.cuponesAgrupados.cupones[0].id;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void addStoryItems() {
    storyItems.add(StoryItem.pageImage(
      url: widget.cuponesAgrupados.cupones[0].fotoUrl,
      controller: controller,
    ));
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Material(
            type: MaterialType.transparency,
            child: StoryView(
              storyItems: storyItems,
              controller: controller,
              onComplete: () => GlobalMethods().popPage(context),
              onVerticalSwipeComplete: (direction) {
                if (direction == Direction.down) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              widget.cuponesAgrupados.foto != null ? NetworkImage(widget.cuponesAgrupados.foto) : AssetImage(
                                  "assets/images/notImage.png"),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.cuponesAgrupados.nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                date,
                                style: TextStyle(color: Colors.white38),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => GlobalMethods().popPage(context),
                    child: Container(
                      margin: EdgeInsets.only(top: 5),
                      width: MediaQuery.of(context).size.width * 0.1,
                      child: Icon(
                        Icons.close,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 1.9,
            left: (MediaQuery.of(context).size.width / 2) -
                ((MediaQuery.of(context).size.width * 0.8) / 2),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "Obtén un descuento del " + descuento.toString() + "%",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 30.0),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2.6,
            left: (MediaQuery.of(context).size.width / 2) -
                ((MediaQuery.of(context).size.width * 0.8) / 2),
            child: Material(
              type: MaterialType.transparency,
            ),
          ),
          widget.userId != null &&
                  widget.userId.length > 0 &&
                  isCorrectSaveCupon == null
              ? Positioned(
                  bottom: 50,
                  left: (MediaQuery.of(context).size.width / 2) - 100,
                  child: Material(
                    type: MaterialType.transparency,
                    child: GestureDetector(
                      onTap: () => GlobalMethods().pushPage(context, PreSaveCupon(widget.cuponesAgrupados, this, widget.userId)),
                      child: Container(
                        width: 200,
                        padding: EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.4),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            "Guardar cupón",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
          isCorrectSaveCupon != null
              ? Positioned(
                  bottom: 50,
                  left: (MediaQuery.of(context).size.width / 2) - 100,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                          child: isCorrectSaveCupon
                              ? Icon(
                                  Icons.check_circle_outlined,
                                  color: Color.fromRGBO(149, 220, 0, 1),
                                  size: 40,
                                )
                              : Icon(
                                  Icons.error_outline,
                                  color: Color.fromRGBO(226, 120, 120, 1),
                                  size: 40,
                                )),
                    ),
                  ),
                )
              : Container(),
        ],
      );

  @override
  saveCuponState(bool isCorrect) {
    if (mounted) {
      setState(() {
        this.isCorrectSaveCupon = isCorrect;
      });
    }
    Timer(Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() {
          this.isCorrectSaveCupon = null;
        });
      }
    });
  }
}
