part of '../main.dart';

class PropertyReview {
  const PropertyReview({
    required this.id,
    required this.listingId,
    required this.boarderId,
    required this.boarderName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id, listingId, boarderId, boarderName, comment;
  final int rating;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'listingId': listingId,
    'boarderId': boarderId,
    'boarderName': boarderName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory PropertyReview.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as int;
    if (rating < 1 || rating > 5) throw const FormatException('Invalid rating');
    return PropertyReview(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      boarderId: json['boarderId'] as String,
      boarderName: json['boarderName'] as String,
      rating: rating,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ReviewSummary {
  ReviewSummary(Iterable<PropertyReview> reviews) {
    for (final review in reviews) {
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
      total++;
      _sum += review.rating;
    }
  }
  final Map<int, int> counts = {for (var star = 1; star <= 5; star++) star: 0};
  int total = 0;
  int _sum = 0;
  double get average => total == 0 ? 0 : _sum / total;
}

abstract class ReviewStorage {
  Future<List<PropertyReview>> read();
  Future<void> write(List<PropertyReview> reviews);
}

/// Device persistence for the existing session-based app; no remote backend exists.
class PreferencesReviewStorage implements ReviewStorage {
  static const _key = 'staynear.propertyReviews.v1';
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<List<PropertyReview>> read() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) => PropertyReview.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> write(List<PropertyReview> reviews) => _preferences.setString(
    _key,
    jsonEncode(reviews.map((review) => review.toJson()).toList()),
  );
}
