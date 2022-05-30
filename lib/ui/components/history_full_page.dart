import 'package:flutter/material.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:story_view/story_view.dart';

class HistoryFullPage extends StatefulWidget {
  CuponesAgrupados cuponesAgrupados;
  Function saveCupon;
  String userId;

  HistoryFullPage(this.cuponesAgrupados, this.saveCupon, this.userId);

  @override
  _HistoryFullPageState createState() => _HistoryFullPageState();
}

class _HistoryFullPageState extends State<HistoryFullPage> {
  StoryController controller;
  List<StoryItem> storyItems = [];
  String date = '';
  int index = 0;

  @override
  void initState() {
    super.initState();
    widget.userId = "16edc7a0-d101-41d8-8fba-5c687d074d52";
    controller = StoryController();
    addStoryItems();
    date = widget.cuponesAgrupados.cupones[0].date;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void addStoryItems() {
    for (final story in widget.cuponesAgrupados.cupones) {
      storyItems.add(StoryItem.pageImage(
        url:
            "https://image.ibb.co/cU4WGx/Omotuo-Groundnut-Soup-braperucci-com-1.jpg",
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
                if (index > 0) {
                  setState(() {
                    date = widget.cuponesAgrupados.cupones[index].date;
                  });
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
          widget.userId != null && widget.userId.length > 0
              ? Positioned(
                  bottom: 50,
                  left: (MediaQuery.of(context).size.width / 2) - 100,
                  child: Material(
                    type: MaterialType.transparency,
                    child: GestureDetector(
                      onTap: () {
                        widget.saveCupon(widget.cuponesAgrupados.cupones[index].id, widget.userId);
                      },
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
        ],
      );
}
