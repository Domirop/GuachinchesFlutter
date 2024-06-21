import 'dart:io';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';

class VideoInputPresenter {
  RemoteRepository _remoteRepository;
  VideoInputView _view;

  VideoInputPresenter(this._remoteRepository,this._view);

  Future<void> saveVideo(MediaInfo video, String title, String restaurantId,String thumbnailUrl) async {
  bool response  = await _remoteRepository.uploadVideo(video, title, restaurantId,thumbnailUrl);


  if(response){
    _view.uploadConfirm();
  }else{
    print('Error uploading video');
  }
  }
}
abstract class VideoInputView{
  uploadConfirm();
}
