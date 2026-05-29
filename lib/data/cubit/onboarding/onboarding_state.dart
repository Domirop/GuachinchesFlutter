import 'package:flutter/foundation.dart' show listEquals;

sealed class OnboardingState {
  const OnboardingState();
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingLoaded extends OnboardingState {
  final OnboardingData data;
  const OnboardingLoaded(this.data);
}

class OnboardingData {
  final bool finished;
  final String? name;
  final String? islandId;
  final List<String> tastes;
  final bool locationAsked;
  final bool surveyShown;

  const OnboardingData({
    required this.finished,
    this.name,
    this.islandId,
    required this.tastes,
    required this.locationAsked,
    required this.surveyShown,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingData &&
        other.finished == finished &&
        other.name == name &&
        other.islandId == islandId &&
        listEquals(other.tastes, tastes) &&
        other.locationAsked == locationAsked &&
        other.surveyShown == surveyShown;
  }

  @override
  int get hashCode => Object.hash(
        finished,
        name,
        islandId,
        Object.hashAll(tastes),
        locationAsked,
        surveyShown,
      );
}
