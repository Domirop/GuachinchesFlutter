import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/fotoBanner.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRanking.dart';

class HeroSliderComponent extends StatefulWidget {
  final List<FotoBanner> banners;
  final SurveyRanking? surveyRanking;

  HeroSliderComponent(this.banners, {this.surveyRanking});

  @override
  _HeroSliderComponentState createState() => _HeroSliderComponentState();
}

class _HeroSliderComponentState extends State<HeroSliderComponent> {
  late List<FotoBanner> banners;
  List<Widget> imageSliders = [];
  int _current = 0;

  @override
  void initState() {
    super.initState();
    banners = List.from(widget.banners);

    // Insertar banner personalizado
    banners.insert(
      0,
      FotoBanner(
        id: "encuesta",
        fotoUrl:
        'https://louvre.s3.fr-par.scw.cloud/Guachinches/banners/logo4.png',
      ),
    );

    imageSliders = banners.map((item) {
      return Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          return GestureDetector(
            onTap: () {
              if (item.id == "encuesta" && widget.surveyRanking != null) {
                GlobalMethods().pushPage(context, widget.surveyRanking!);
              }
            },
            child: Stack(
              children: [
                SizedBox(
                  width: screenWidth,
                  height: screenHeight * 0.55,
                  child: CachedNetworkImage(
                    imageUrl: item.fotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.black12,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black12,
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),

                Container(
                  width: screenWidth,
                  height: screenHeight * 0.55,
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
                Positioned(
                  bottom: screenHeight * 0.12,
                  left: 0,
                  right: 0,
                  child: Text(
                    item.id == "encuesta"
                        ? "Premios Donde Comer Canarias"
                        : "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item.id == "encuesta") ...[
                  Positioned(
                    bottom: screenHeight * 0.07,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: GlobalMethods.blueColor,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          "Vota aquí!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(alignment: Alignment.topCenter, children: [
      CarouselSlider(
        items: imageSliders,
        options: CarouselOptions(
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 8),
          autoPlayAnimationDuration: Duration(milliseconds: 1200),
          viewportFraction: 1,
          aspectRatio: 4 / 5,
          onPageChanged: (index, reason) {
            setState(() {
              _current = index;
            });
          },
        ),
      ),
      Positioned(
        top: screenWidth * 1.12, // Adaptable
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imageSliders.asMap().entries.map((entry) {
            int index = entry.key;
            return Container(
              height: 4,
              width: _current == index ? 48 : 18,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                color: _current == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}
