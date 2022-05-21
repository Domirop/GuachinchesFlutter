import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/fotoBanner.dart';

class HeroSliderComponent extends StatefulWidget {
  List<FotoBanner> banners;

  HeroSliderComponent(this.banners);

  @override
  _HeroSliderComponentState createState() => _HeroSliderComponentState(this.banners);
}

class _HeroSliderComponentState extends State<HeroSliderComponent> {
  List<FotoBanner> banners;
  List<Widget> imageSliders = [];
  int _current = 0;

  _HeroSliderComponentState(this.banners);

  @override
  void initState() {
    imageSliders = banners
        .map((item) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                image: DecorationImage(
                  repeat: ImageRepeat.noRepeat,
                  alignment: Alignment.center,
                  fit: BoxFit.fill,
                  image: NetworkImage(item.fotoUrl),
                ),
              ),
            ))
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: imageSliders,
          options: CarouselOptions(
              autoPlay: true,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              aspectRatio: 12 / 6,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imageSliders.map((url) {
            int index = imageSliders.indexOf(url);
            return Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == index
                    ? Colors.black
                    : Color.fromRGBO(196, 196, 196, 1),
              ),
            );
          }).toList(),
        ),
      ],
    );;
  }
}
