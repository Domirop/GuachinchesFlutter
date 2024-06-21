import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/fotoBanner.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/photoGallery/photo_gallery.dart';

class DetailPhotosSlider extends StatefulWidget {
  final List<Fotos> photos;
  final String name;
  final String id;
  DetailPhotosSlider(this.photos, this.name,this.id);

  @override
  _DetailPhotosSliderComponentState createState() => _DetailPhotosSliderComponentState(this.photos, this.name,this.id);
}

class _DetailPhotosSliderComponentState extends State<DetailPhotosSlider> {
  final List<Fotos> photos;
  final String name;
  List<Widget> imageSliders = [];
  int _current = 0;

  final String id;
  _DetailPhotosSliderComponentState(this.photos, this.name,this.id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    imageSliders = photos.map((item) {
      return Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: item.photoUrl != null
                ? CachedNetworkImageProvider(item.photoUrl!)
                : AssetImage("assets/images/notImage.png") as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GlobalMethods().pushPage(context, PhotoGallery(photos, name,id));
      },
      child: Stack(
        fit: StackFit.expand,
        children:[ CarouselSlider(
          items: imageSliders,
          options: CarouselOptions(
            autoPlay: true,
            viewportFraction: 1.0, // Para que ocupe todo el ancho
            aspectRatio: 0.3, // Ajusta el aspecto de la imagen para hacerla más alta
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),

        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.8),
            ),
            child: Row(
              children: [
                Text(
                  "${_current + 1}",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  " / ${photos.length}",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),]
      ),
    );
  }

}
