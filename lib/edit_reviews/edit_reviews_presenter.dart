import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/model/user_info.dart';

class EditReviewPresenter{
  final EditReviewView _view;
  final UserCubit _userCubit;

  EditReviewPresenter(this._view, this._userCubit);

  updateReview(String userId, String reviewId,String title, String rating, String review)async{
    await _userCubit.updateUserReview(userId, reviewId, title, rating, review);
  }

}
abstract class EditReviewView{
  reviewUpdated();

}