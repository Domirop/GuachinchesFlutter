
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/fotos.dart';

class PhotoGalleryPresenter  {

  //view
  PhotoGalleryView? view;
  //remote repository
  final RemoteRepository repository;


  PhotoGalleryPresenter(this.view, this.repository);

//insert photo
  void insertPhoto(String restaurantId, String base64Image) async {
    try {
      await repository.insertPhotoRestaurant(restaurantId, base64Image);
      view?.onInsertPhotoSuccess();
    } catch (e) {
      view?.onInsertPhotoError();
    }
  }
  //get photos
  void getPhotos(String restaurantId) async {
    try {
      List<Fotos> photos = await repository.getPhotosRestaurant(restaurantId);
      view?.onGetPhotosSuccess(photos);
    } catch (e) {
      view?.onInsertPhotoError();
    }
  }

}
//View
abstract class PhotoGalleryView {
  void onInsertPhotoSuccess();
  void onInsertPhotoError();
  void onGetPhotosSuccess(List<Fotos> photosUpdate);
}
