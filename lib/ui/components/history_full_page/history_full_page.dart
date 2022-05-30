import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/history_full_page/history_full_page_presenter.dart';
import 'package:http/http.dart';
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
  bool firstTime = true;
  HistoryFullPagePresenter presenter;
  RemoteRepository remoteRepository;

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HistoryFullPagePresenter(this, remoteRepository);
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
    for (final story in widget.cuponesAgrupados.cupones) {
      storyItems.add(StoryItem.pageImage(
        url: story.fotoUrl,
        controller: controller,
      ));
    }
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
              onStoryShow: (storyItem) {
                index = storyItems.indexOf(storyItem);
                if(index == 1){
                  if (mounted) {
                    setState(() {
                      firstTime = false;
                    });
                  }
                }
                if (!firstTime) {
                  if (mounted) {
                    setState(() {
                      date = widget.cuponesAgrupados.cupones[index].date;
                      descuento =
                          widget.cuponesAgrupados.cupones[index].descuento;
                      id = widget.cuponesAgrupados.cupones[index].id;
                    });
                  }
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
                              NetworkImage(widget.cuponesAgrupados.foto),
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
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "Válido para el día " + date,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 30.0),
                ),
              ),
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
                      onTap: () => presenter.saveCupon(id, widget.userId),
                      child: Container(
                        width: 200,
                        padding: EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 133, 196, 0.3),
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
                    child: GestureDetector(
                      onTap: () {
                        presenter.saveCupon(
                            widget.cuponesAgrupados.cupones[index].id,
                            widget.userId);
                      },
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
    Timer(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          this.isCorrectSaveCupon = null;
        });
      }
    });
  }
}
