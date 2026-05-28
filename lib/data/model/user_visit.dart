class UserVisit {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantPhotoUrl;
  final DateTime visitedAt;
  final int? rating;
  final String? note;

  const UserVisit({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantPhotoUrl,
    required this.visitedAt,
    this.rating,
    this.note,
  });

  factory UserVisit.fromJson(Map<String, dynamic> json) {
    return UserVisit(
      id: (json['id'] as String?) ?? '',
      restaurantId:
          (json['restaurantId'] as String?) ?? (json['restaurant_id'] as String?) ?? '',
      restaurantName:
          (json['restaurantName'] as String?) ?? (json['restaurant_name'] as String?) ?? '',
      restaurantPhotoUrl:
          (json['restaurantPhotoUrl'] as String?) ?? (json['restaurant_photo_url'] as String?),
      visitedAt: DateTime.parse(
          (json['visitedAt'] as String?) ?? (json['visited_at'] as String?) ?? '1970-01-01T00:00:00Z'),
      rating: json['rating'] as int?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantPhotoUrl': restaurantPhotoUrl,
      'visitedAt': visitedAt.toIso8601String(),
      'rating': rating,
      'note': note,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserVisit &&
        other.id == id &&
        other.restaurantId == restaurantId &&
        other.restaurantName == restaurantName &&
        other.restaurantPhotoUrl == restaurantPhotoUrl &&
        other.visitedAt == visitedAt &&
        other.rating == rating &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
        id,
        restaurantId,
        restaurantName,
        restaurantPhotoUrl,
        visitedAt,
        rating,
        note,
      );
}
