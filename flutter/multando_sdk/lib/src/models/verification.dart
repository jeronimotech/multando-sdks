class RejectRequest {
  const RejectRequest({
    required this.reason,
  });

  factory RejectRequest.fromJson(Map<String, dynamic> json) {
    return RejectRequest(
      reason: json['reason'] as String,
    );
  }

  final String reason;

  Map<String, dynamic> toJson() => {
        'reason': reason,
      };
}
