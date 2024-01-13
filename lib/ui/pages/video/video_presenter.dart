import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Video.dart';

class VideoPresenter{
    final VideoPresenterView _view;
    final RemoteRepository _repository;

    VideoPresenter(this._view, this._repository);

    getAllVideos() async {
      List<Video> videos = await _repository.getAllVideos();
      _view.setVideos(videos);
    }

}

abstract class VideoPresenterView {
  setVideos(List<Video> videos);
}
