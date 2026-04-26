import 'dart:math';
import 'package:guachinches/data/model/restaurant.dart';

class NearbyRestaurant {
  final Restaurant restaurant;
  final String distanceLabel;
  final String typeName;

  NearbyRestaurant({
    required this.restaurant,
    required this.distanceLabel,
    this.typeName = '',
  });
}

double haversineDistanceMeters(
    double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRad(double deg) => deg * pi / 180;

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
