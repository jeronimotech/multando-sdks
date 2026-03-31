package com.multando.sdk.services

import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.*

/**
 * Blockchain token and staking operations.
 */
class BlockchainService internal constructor(
    private val httpClient: HttpClient
) {

    /** Get the token balance for the authenticated user. */
    suspend fun balance(): TokenBalance =
        httpClient.request(method = "GET", path = "/api/v1/blockchain/balance")

    /** Stake tokens. */
    suspend fun stake(amount: Double): StakingInfo =
        httpClient.request(
            method = "POST",
            path = "/api/v1/blockchain/stake",
            body = StakeRequest(amount)
        )

    /** Unstake tokens. */
    suspend fun unstake(amount: Double): StakingInfo =
        httpClient.request(
            method = "POST",
            path = "/api/v1/blockchain/unstake",
            body = StakeRequest(amount)
        )

    /** Get current staking information. */
    suspend fun stakingInfo(): StakingInfo =
        httpClient.request(method = "GET", path = "/api/v1/blockchain/staking-info")

    /** List token transactions. */
    suspend fun transactions(page: Int = 1, pageSize: Int = 20): List<TokenTransaction> =
        httpClient.request(
            method = "GET",
            path = "/api/v1/blockchain/transactions",
            queryParams = mapOf(
                "page" to page.toString(),
                "page_size" to pageSize.toString()
            )
        )

    /** Claim accumulated staking rewards. */
    suspend fun claimRewards(): ClaimRewardsResponse =
        httpClient.request(method = "POST", path = "/api/v1/blockchain/claim-rewards")
}
