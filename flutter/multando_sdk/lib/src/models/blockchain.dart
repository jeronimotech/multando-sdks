import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'blockchain.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenBalance {
  const TokenBalance({
    required this.available,
    required this.staked,
    required this.pendingRewards,
    required this.total,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) =>
      _$TokenBalanceFromJson(json);

  final double available;
  final double staked;
  @JsonKey(name: 'pending_rewards')
  final double pendingRewards;
  final double total;

  Map<String, dynamic> toJson() => _$TokenBalanceToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StakeRequest {
  const StakeRequest({
    required this.amount,
  });

  factory StakeRequest.fromJson(Map<String, dynamic> json) =>
      _$StakeRequestFromJson(json);

  final double amount;

  Map<String, dynamic> toJson() => _$StakeRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UnstakeRequest {
  const UnstakeRequest({
    required this.amount,
  });

  factory UnstakeRequest.fromJson(Map<String, dynamic> json) =>
      _$UnstakeRequestFromJson(json);

  final double amount;

  Map<String, dynamic> toJson() => _$UnstakeRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StakingInfo {
  const StakingInfo({
    required this.stakedAmount,
    required this.pendingRewards,
    required this.apy,
    this.stakedAt,
    this.lockEndAt,
    required this.isLocked,
  });

  factory StakingInfo.fromJson(Map<String, dynamic> json) =>
      _$StakingInfoFromJson(json);

  @JsonKey(name: 'staked_amount')
  final double stakedAmount;
  @JsonKey(name: 'pending_rewards')
  final double pendingRewards;
  final double apy;
  @JsonKey(name: 'staked_at')
  final DateTime? stakedAt;
  @JsonKey(name: 'lock_end_at')
  final DateTime? lockEndAt;
  @JsonKey(name: 'is_locked')
  final bool isLocked;

  Map<String, dynamic> toJson() => _$StakingInfoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenTransaction {
  const TokenTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.description,
    this.txHash,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) =>
      _$TokenTransactionFromJson(json);

  final String id;
  final TokenTxType type;
  final double amount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String? description;
  @JsonKey(name: 'tx_hash')
  final String? txHash;

  Map<String, dynamic> toJson() => _$TokenTransactionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ClaimRewardsResponse {
  const ClaimRewardsResponse({
    required this.amountClaimed,
    required this.txHash,
    required this.newBalance,
  });

  factory ClaimRewardsResponse.fromJson(Map<String, dynamic> json) =>
      _$ClaimRewardsResponseFromJson(json);

  @JsonKey(name: 'amount_claimed')
  final double amountClaimed;
  @JsonKey(name: 'tx_hash')
  final String txHash;
  @JsonKey(name: 'new_balance')
  final double newBalance;

  Map<String, dynamic> toJson() => _$ClaimRewardsResponseToJson(this);
}
