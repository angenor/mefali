import 'package:json_annotation/json_annotation.dart';

part 'share_data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShareMetadata {
  final String merchantName;
  final String merchantDescription;
  final String shareUrl;
  final String whatsappMessage;

  const ShareMetadata({
    required this.merchantName,
    required this.merchantDescription,
    required this.shareUrl,
    required this.whatsappMessage,
  });

  factory ShareMetadata.fromJson(Map<String, dynamic> json) =>
      _$ShareMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ShareMetadataToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ReferralCodeResponse {
  final String referralCode;

  const ReferralCodeResponse({required this.referralCode});

  factory ReferralCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$ReferralCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralCodeResponseToJson(this);
}
