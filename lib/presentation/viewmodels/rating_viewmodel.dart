import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/i_ratings_repository.dart';

class RatingViewModel extends ChangeNotifier with ViewStateMixin {
  final IRatingsRepository ratingsRepo;

  int _score = 5;
  String? _review;
  final Set<String> _selectedTags = {};
  RideRating? _submittedRating;

  RatingViewModel({required this.ratingsRepo});

  int get score => _score;
  String? get review => _review;
  Set<String> get selectedTags => _selectedTags;
  RideRating? get submittedRating => _submittedRating;

  void setScore(int score) {
    _score = score.clamp(1, 5);
    notifyListeners();
  }

  void setReview(String? review) {
    _review = review;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  Future<bool> submitRating(String rideId) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _submittedRating = await ratingsRepo.submitRating(
        rideId: rideId,
        rating: _score,
        review: _review,
        tags: _selectedTags.toList(),
      );
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _score = 5;
    _review = null;
    _selectedTags.clear();
    _submittedRating = null;
    setState(ViewState.initial);
    notifyListeners();
  }
}
