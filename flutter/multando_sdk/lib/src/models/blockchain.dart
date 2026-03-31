import 'enums.dart';

class TokenBalance {
  const TokenBalance({
    required this.available,
    required this.staked,
    required this.pendingRewards,
    required this.total,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    return TokenBalance(
      available: (json['available'] as num).toDouble(),
      staked: (json['staked'] as num).toDouble(),
      pendingRewards: (json['pending_rewards'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  final double available;
  final double staked;
  final double pendingRewards;
  final double total;

  Map<String, dynamic> toJson() => {
        'available': available,
        'staked': staked,
        'pending_rewards': pendingRewards,
        'total': total,
      };
}

class StakeRequest {
  const StakeRequest({
    required this.amount,
  });

  factory StakeRequest.fromJson(Map<String, dynamic> json) {
    return StakeRequest(
      amount: (json['amount'] as num).toDouble(),
    );
  }

  final double amount;

  Map<String, dynamic> toJson() => {
        'amount': amount,
      };
}

class UnstakeRequest {
  const UnstakeRequest({
    required this.amount,
  });

  factory UnstakeRequest.fromJson(Map<String, dynamic> json) {
    return UnstakeRequest(
      amount: (json['amount'] as num).toDouble(),
    );
  }

  final double amount;

  Map<String, dynamic> toJson() => {
        'amount': amount,
      };
}

class StakingInfo {
  const StakingInfo({
    required this.stakedAmount,
    required this.pendingRewards,
    required this.apy,
    this.stakedAt,
    this.lockEndAt,
    required this.isLocked,
  });

  factory StakingInfo.fromJson(Map<String, dynamic> json) {
    return StakingInfo(
      stakedAmount: (json['staked_amount'] as num).toDouble(),
      pendingRewards: (json['pending_rewards'] as num).toDouble(),
      apy: (json['apy'] as num).toDouble(),
      stakedAt: json['staked_at'] != null
          ? DateTime.parse(json['staked_at'] as String)
          : null,
      lockEndAt: json['lock_end_at'] != null
          ? DateTime.parse(json['lock_end_at'] as String)
          : null,
      isLocked: json['is_locked'] as bool,
    );
  }

  final double stakedAmount;
  final double pendingRewards;
  final double apy;
  final DateTime? stakedAt;
  final DateTime? lockEndAt;
  final bool isLocked;

  Map<String, dynamic> toJson() => {
        'staked_amount': stakedAmount,
        'pending_rewards': pendingRewards,
        'apy': apy,
        if (stakedAt != null) 'staked_at': stakedAt!.toIso8601String(),
        if (lockEndAt != null) 'lock_end_at': lockEndAt!.toIso8601String(),
        'is_locked': isLocked,
      };
}

class TokenTransaction {
  const TokenTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.description,
    this.txHash,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) {
    return TokenTransaction(
      id: json['id'] as String,
      type: TokenTxType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => TokenTxType.reward,
      ),
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      txHash: json['tx_hash'] as String?,
    );
  }

  final String id;
  final TokenTxType type;
  final double amount;
  final DateTime createdAt;
  final String? description;
  final String? txHash;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'amount': amount,
        'created_at': createdAt.toIso8601String(),
        if (description != null) 'description': description,
        if (txHash != null) 'tx_hash': txHash,
      };
}

class ClaimRewardsResponse {
  const ClaimRewardsResponse({
    required this.amountClaimed,
    required this.txHash,
    required this.newBalance,
  });

  factory ClaimRewardsResponse.fromJson(Map<String, dynamic> json) {
    return ClaimRewardsResponse(
      amountClaimed: (json['amount_claimed'] as num).toDouble(),
      txHash: json['tx_hash'] as String,
      newBalance: (json['new_balance'] as num).toDouble(),
    );
  }

  final double amountClaimed;
  final String txHash;
  final double newBalance;

  Map<String, dynamic> toJson() => {
        'amount_claimed': amountClaimed,
        'tx_hash': txHash,
        'new_balance': newBalance,
      };
}
