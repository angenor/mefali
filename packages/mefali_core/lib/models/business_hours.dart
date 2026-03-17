import 'package:json_annotation/json_annotation.dart';

part 'business_hours.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BusinessHours {
  const BusinessHours({
    required this.id,
    required this.merchantId,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursFromJson(json);

  final String id;
  final String merchantId;
  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$BusinessHoursToJson(this);

  static const dayNames = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  String get dayName => dayNames[dayOfWeek];
}
