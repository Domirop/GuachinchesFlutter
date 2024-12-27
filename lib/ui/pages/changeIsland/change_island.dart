import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/defaultData/allIsland.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';

class ChangeIsland extends StatefulWidget {
  const ChangeIsland() : super();

  @override
  _ChangeIslandState createState() => _ChangeIslandState();
}

class _ChangeIslandState extends State<ChangeIsland> {
  List<Island> islandSlider = AllIsland().allIsland;
  List<Widget> imageSliders = [];
  final storage = new FlutterSecureStorage();

  int _current = 0;
  CarouselController buttonCarouselController = CarouselController();

  @override
  void initState() {
    imageSliders = islandSlider
        .map((item) => Container(
      height: 200,
      width: 300,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white)
      ),
      child:Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(height:180,child: Image(image: AssetImage("assets/images/"+item.photo),)),
            Text(item.name,style: TextStyle(
              color: Colors.white,
                fontWeight: FontWeight.w600,fontSize: 20),),
          ],
        ),
      ),
    ))
        .toList();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    List<String> test = ["assets/images/TF_bg.jpg","assets/images/GC_bg.jpg"];
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Stack(
            children: [
               Container(
                decoration: new BoxDecoration(
                  image: new DecorationImage(
                    image: new AssetImage(test[_current]), fit: BoxFit.cover,),
                ),
              ),
              Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Selecciona tu isla',style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20
                ),),
                Container(
                  height: MediaQuery.of(context).size.height*0.4,
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                              onTap: ()=>buttonCarouselController.previousPage(duration: Duration(milliseconds: 400), curve: Curves.linear),
                              child: Icon(Icons.arrow_back_ios,size: 28,color: Colors.white,)),
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
                              child: Icon(Icons.arrow_forward_ios,size: 28,color: Colors.white,)),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 80),
                  child: Container(
                    height: MediaQuery.of(context).size.height*0.07,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async =>{
                        await storage.write(key: 'islandId', value:  AllIsland().getIslandById(islandSlider[_current].id).id),
                        GlobalMethods().pushAndRemoveAll(context,SplashScreen())
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(GlobalMethods.blueColor),
                        shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0))),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text('Confirmar',style: TextStyle(
                            fontSize: 18,
                          fontFamily: 'Sf Pro Display',
                          color: Colors.white
                        ),),
                      ),),
                  ),
                )
              ],
            )],
          ),
        )
    );
  }
}

final Shader linearGradient = LinearGradient(
  colors: <Color>[Color(0xff0189C4), Color(0xff01BCC4)],
).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));