import 'package:json_annotation/json_annotation.dart';

part 'rating.g.dart';

/// A single rating record (merchant or driver).
@JsonSerializable(fieldRename: FieldRename.snake)
class Rating {
  const Rating({
    required this.id,
    required this.orderId,
    required this.raterId,
    required this.ratedType,
    required this.ratedId,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

  final String id;
  final String orderId;
  final String raterId;
  final String ratedType;
  final String ratedId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$RatingToJson(this);
}

/// Response containing both merchant and driver ratings.
@JsonSerializable(fieldRename: FieldRename.snake)
class RatingPair {
  const RatingPair({
    required this.merchantRating,
    required this.driverRating,
  });

  factory RatingPair.fromJson(Map<String, dynamic> json) =>
      _$RatingPairFromJson(json);

  final Rating merchantRating;
  final Rating driverRating;

  Map<String, dynamic> toJson() => _$RatingPairToJson(this);
}

/// Request body for submitting a double rating.
@JsonSerializable(fieldRename: FieldRename.snake)
class SubmitRatingRequest {
  const SubmitRatingRequest({
    required this.merchantScore,
    required this.driverScore,
    this.merchantComment,
    this.driverComment,
  });

  factory SubmitRatingRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitRatingRequestFromJson(json);

  final int merchantScore;
  final int driverScore;
  final String? merchantComment;
  final String? driverComment;

  Map<String, dynamic> toJson() => _$SubmitRatingRequestToJson(this);
}
