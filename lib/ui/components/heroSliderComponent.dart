import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/fotoBanner.dart';

class HeroSliderComponent extends StatefulWidget {
  final List<FotoBanner> banners;

  HeroSliderComponent(this.banners);

  @override
  _HeroSliderComponentState createState() =>
      _HeroSliderComponentState(this.banners);
}

class _HeroSliderComponentState extends State<HeroSliderComponent> {
  List<FotoBanner> banners;
  List<Widget> imageSliders = [];
  int _current = 0;

  _HeroSliderComponentState(this.banners);

  @override
  void initState() {
    imageSliders = banners
        .map((item) => Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              repeat: ImageRepeat.noRepeat,
              alignment: Alignment.center,
              fit: BoxFit.fill,
              image: item.fotoUrl != null
                  ? CachedNetworkImageProvider(item.fotoUrl!)
                  : AssetImage("assets/images/notImage.png")
              as ImageProvider,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ],
    ))
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.topCenter, children: [
      CarouselSlider(
        items: imageSliders,
        options: CarouselOptions(
            autoPlay: true,
            viewportFraction: 1,
            animateToClosest: true,
            aspectRatio: 12 / 6,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            }),
      ),
      Positioned(
        top: 182,
        child: Row(
          children: imageSliders.map((url) {
            int index = imageSliders.indexOf(url);
            return Container(
              height: 4,
              width: _current == index ? 48 : 18,
              margin: EdgeInsets.symmetric(horizontal: 2.0),
              color: _current == index ? Colors.white : Colors.white.withOpacity(0.6),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}