import 'package:json_annotation/json_annotation.dart';

part 'verification.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RejectRequest {
  const RejectRequest({
    required this.reason,
  });

  factory RejectRequest.fromJson(Map<String, dynamic> json) =>
      _$RejectRequestFromJson(json);

  final String reason;

  Map<String, dynamic> toJson() => _$RejectRequestToJson(this);
}
