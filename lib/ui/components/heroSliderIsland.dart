import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/defaultData/allIsland.dart';
import 'package:guachinches/data/model/Island.dart';

class HeroSliderIsland extends StatefulWidget {

  HeroSliderIsland();

  @override
  _HeroSliderIslandState createState() => _HeroSliderIslandState();
}
class IslandSlider {
  String photo;
  String name;

  IslandSlider(this.photo, this.name);

}
class _HeroSliderIslandState extends State<HeroSliderIsland> {
  List<Widget> imageSliders = [];
  int _current = 0;


  @override
  void initState() {
    List<Island> imageSlidersImg = AllIsland().allIsland;

    imageSliders = imageSlidersImg
        .map((item) => Container(
          height: 200,
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent)
          ),
          child:Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(height:180,child: Image(image: AssetImage("assets/images/"+item.photo),)),
                Text(item.name,style: TextStyle(fontWeight: FontWeight.w600,fontSize: 20),),
              ],
            ),
          ),
        ))
        .toList();
    super.initState();
  }
  CarouselController buttonCarouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
                onTap: ()=>buttonCarouselController.previousPage(duration: Duration(milliseconds: 400), curve: Curves.linear),
                child: Icon(Icons.arrow_back_ios,size: 28,)),
          ),
          Expanded(
            child: CarouselSlider(
              items: imageSliders,
              options: CarouselOptions(
                  autoPlay: false,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                  aspectRatio: 12 / 10,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
              carouselController: buttonCarouselController,
            ),

          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
                onTap: ()=>buttonCarouselController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.linear),
                child: Icon(Icons.arrow_forward_ios,size: 28,)),
          ),
        ],
      ),
    );;
  }
}
