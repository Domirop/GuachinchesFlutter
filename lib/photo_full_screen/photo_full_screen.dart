import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/model/fotos.dart';
import 'package:guachinches/model/restaurant.dart';

import '../globalMethods.dart';

class PhotoFullScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int index;

  PhotoFullScreen(this.restaurant,  this.index);

  @override
  _PhotoFullScreenState createState() => _PhotoFullScreenState(restaurant,index);
}

class _PhotoFullScreenState extends State<PhotoFullScreen> {
  Restaurant restaurant;
  int selectedIndex;
  _PhotoFullScreenState(this.restaurant,this.selectedIndex);

  List<Widget> imageSlider = [];

  @override
  void initState() {
    imageSlider = restaurant.fotos
        .map((item) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                image: DecorationImage(
                  repeat: ImageRepeat.noRepeat,
                  alignment: Alignment.center,
                  fit: BoxFit.fill,
                  image: NetworkImage(item.photoUrl),
                ),
              ),
            ))
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 279,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      child: GestureDetector(
                        onTap: () => GlobalMethods().popPage(context),
                        child: Container(
                          width: 40.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: 40.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Center(child: Text("Fotos\n"+restaurant.nombre,textAlign: TextAlign.center, style: TextStyle(
                        color: Colors.white
                    ),))
                  ],
                ),
              ),
              CarouselSlider(
                  items: imageSlider,
                  options: CarouselOptions(
                    autoPlay: false,
                    initialPage: selectedIndex,
                    viewportFraction: 1,
                    enlargeCenterPage: true,
                    aspectRatio: 4 / 4,
                  )),

            ],
          ),
        ));
  }
}
