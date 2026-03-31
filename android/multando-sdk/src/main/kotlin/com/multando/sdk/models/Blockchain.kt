package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TokenBalance(
    @SerialName("wallet_address") val walletAddress: String,
    val balance: Double,
    @SerialName("staked_balance") val stakedBalance: Double,
    @SerialName("pending_rewards") val pendingRewards: Double
)

@Serializable
data class StakeRequest(
    val amount: Double
)

@Serializable
data class StakingInfo(
    @SerialName("staked_amount") val stakedAmount: Double,
    @SerialName("reward_rate") val rewardRate: Double,
    @SerialName("pending_rewards") val pendingRewards: Double,
    @SerialName("staking_since") val stakingSince: String? = null,
    @SerialName("lock_end_date") val lockEndDate: String? = null
)

@Serializable
data class TokenTransaction(
    val id: String,
    @SerialName("tx_hash") val txHash: String? = null,
    @SerialName("from_address") val fromAddress: String? = null,
    @SerialName("to_address") val toAddress: String? = null,
    val amount: Double,
    @SerialName("transaction_type") val transactionType: String,
    val status: String,
    @SerialName("created_at") val createdAt: String
)

@Serializable
data class ClaimRewardsResponse(
    @SerialName("amount_claimed") val amountClaimed: Double,
    @SerialName("tx_hash") val txHash: String? = null,
    @SerialName("new_balance") val newBalance: Double
)
