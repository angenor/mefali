import 'package:json_annotation/json_annotation.dart';

part 'exceptional_closure.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ExceptionalClosure {
  const ExceptionalClosure({
    required this.id,
    required this.merchantId,
    required this.closureDate,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExceptionalClosure.fromJson(Map<String, dynamic> json) =>
      _$ExceptionalClosureFromJson(json);

  final String id;
  final String merchantId;
  final DateTime closureDate;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ExceptionalClosureToJson(this);
}
