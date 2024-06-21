import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoFullScreen extends StatefulWidget {
  final String name;
  final int index;
  final List<Fotos> fotos;

  PhotoFullScreen(this.name, this.index, this.fotos);

  @override
  _PhotoFullScreenState createState() => _PhotoFullScreenState(name, index, fotos);
}

class _PhotoFullScreenState extends State<PhotoFullScreen> {
  final String name;
  late final int selectedIndex;
  final List<Fotos> fotos;
  bool _showAppBar = true;

  _PhotoFullScreenState(this.name, this.selectedIndex, this.fotos);

  void enableAppBar(bool enable) {
    setState(() {
      _showAppBar = enable;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar
          ? AppBar(
        backgroundColor: GlobalMethods.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => GlobalMethods().popPage(context),
        ),
        title: Text(
          name,
          style: TextStyle(color: Colors.white, fontFamily: 'SF Pro Display'),
        ),
      )
          : null,
      body: GestureDetector(
        child: Container(
          child: PhotoViewGallery.builder(
            itemCount: fotos.length,
            pageController: PageController(initialPage: selectedIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: fotos[index].photoUrl != null
                    ? NetworkImage(fotos[index].photoUrl!)
                    : AssetImage("assets/images/notImage.png") as ImageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                heroAttributes: PhotoViewHeroAttributes(tag: fotos[index].photoUrl!),
              );
            },
            scaleStateChangedCallback: (scaleState) {
              if (scaleState == PhotoViewScaleState.initial) {
                enableAppBar(true);
                HapticFeedback.vibrate();
              }
              else{
                enableAppBar(false);
              }
              if (scaleState == PhotoViewScaleState.covering) {
                HapticFeedback.vibrate();
              }
            },
            scrollPhysics: BouncingScrollPhysics(),
            backgroundDecoration: BoxDecoration(color: GlobalMethods.bgColor),
            onPageChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
