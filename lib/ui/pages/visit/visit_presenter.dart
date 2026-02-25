import 'package:guachinches/data/RemoteRepository.dart';

import '../../../data/model/Visit.dart';

abstract class VisitDetailView {
  void showLoading();
  void showVisit(Visit visit);
  void showError(String message);
}

class VisitDetailPresenter {
  final RemoteRepository _repo;
  final VisitDetailView _view;

  VisitDetailPresenter(this._repo, this._view);

  Future<void> loadVisit(String visitId) async {
    try {
      _view.showLoading();
      Visit visit = await _repo.getVisitById(visitId);
      _view.showVisit(visit);
    } catch (e) {
      _view.showError('No se pudo cargar la visita');
    }
  }

}
