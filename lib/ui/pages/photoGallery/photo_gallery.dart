import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/photo_full_screen/photo_full_screen.dart';
import 'package:guachinches/ui/pages/photoGallery/photo_gallery_presenter.dart';
import 'package:http/http.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class PhotoGallery extends StatefulWidget {
//necesito el restaurant Id
   List<Fotos> photos;
  final String name;
  final String id;

   PhotoGallery(this.photos, this.name,this.id);


  @override
  State<PhotoGallery> createState() => _PhotoGalleryState(this.photos, this.name,this.id);
}

class _PhotoGalleryState extends State<PhotoGallery> implements PhotoGalleryView{
  //presenter
  late PhotoGalleryPresenter presenter;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    presenter = PhotoGalleryPresenter(this, HttpRemoteRepository(Client()));
  }

   List<Fotos> photos;
  final ImagePicker _picker = ImagePicker();
  final String name;
  final String id;
  _PhotoGalleryState(this.photos, this.name,this.id);
  Future<void> _openCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Convert to JPG
      img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image != null) {
        List<int> jpgBytes = img.encodeJpg(image, quality: 80);
        // Convert to base64
        String base64String = base64Encode(jpgBytes);
      //call presenter
        setState(() {
          isLoading = true;

        });
        presenter.insertPhoto(id,base64String );
      }
    }
  }



  @override
  Widget build(BuildContext context) {


    return  Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder(
            bloc: BlocProvider.of<UserCubit>(context),
            builder: (context, UserState state) {
              if (state is UserLoaded && (state.user.id == 'b5f2687e-20e3-4949-ab43-4ef9d1b8c26b' || state.user.id == '584bc428-0f77-4406-9a81-486e83ad8526')
              ) {
                return IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => {
                    _openCamera()
                  },
                );
              } else {
                return Container();
              }
            },

          ),],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white,size: 20,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: GlobalMethods.bgColor,
        title: Text(name, style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'SF Pro Display')),
      ),
      body: Center(
        //Create a gridview with the photos
        child:
        isLoading? Container(
          child:
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                Text("Subiendo foto..."),
              ],
            ),
          ),
       ):GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return GestureDetector(
                onTap: ()=>GlobalMethods().pushPage(context, PhotoFullScreen(name, index, photos)),
                child: Image.network(photos[index].photoUrl!, fit: BoxFit.cover));
          },
        ),
      ),
    );
  }

  @override
  void onInsertPhotoError() {

    // TODO: implement onInsertPhotoError
  }

  @override
  void onInsertPhotoSuccess() {

    presenter.getPhotos(id);

    // TODO: implement onInsertPhotoSuccess
  }

  @override
  void onGetPhotosSuccess(List<Fotos> photosUpdate) {

      setState(() {
        isLoading = false;
        photos = photosUpdate;
      });
  }
}
