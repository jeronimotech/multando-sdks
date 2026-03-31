import Foundation

/// Token balance information for the authenticated user.
public struct TokenBalance: Codable, Sendable {
    public let walletAddress: String
    public let balance: Double
    public let stakedBalance: Double
    public let pendingRewards: Double

    enum CodingKeys: String, CodingKey {
        case walletAddress = "wallet_address"
        case balance
        case stakedBalance = "staked_balance"
        case pendingRewards = "pending_rewards"
    }
}

/// Payload for staking or unstaking tokens.
public struct StakeRequest: Codable, Sendable {
    public let amount: Double

    public init(amount: Double) {
        self.amount = amount
    }
}

/// Current staking details for the user.
public struct StakingInfo: Codable, Sendable {
    public let stakedAmount: Double
    public let rewardRate: Double
    public let pendingRewards: Double
    public let stakingSince: String?
    public let lockEndDate: String?

    enum CodingKeys: String, CodingKey {
        case stakedAmount = "staked_amount"
        case rewardRate = "reward_rate"
        case pendingRewards = "pending_rewards"
        case stakingSince = "staking_since"
        case lockEndDate = "lock_end_date"
    }
}

/// A single blockchain token transaction.
public struct TokenTransaction: Codable, Sendable {
    public let id: String
    public let txHash: String?
    public let fromAddress: String?
    public let toAddress: String?
    public let amount: Double
    public let transactionType: String
    public let status: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case txHash = "tx_hash"
        case fromAddress = "from_address"
        case toAddress = "to_address"
        case amount
        case transactionType = "transaction_type"
        case status
        case createdAt = "created_at"
    }
}

/// Response after claiming staking rewards.
public struct ClaimRewardsResponse: Codable, Sendable {
    public let amountClaimed: Double
    public let txHash: String?
    public let newBalance: Double

    enum CodingKeys: String, CodingKey {
        case amountClaimed = "amount_claimed"
        case txHash = "tx_hash"
        case newBalance = "new_balance"
    }
}
