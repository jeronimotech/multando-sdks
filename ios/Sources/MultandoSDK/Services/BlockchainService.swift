import Foundation

/// Blockchain token and staking operations.
public final class BlockchainService: Sendable {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Get the token balance for the authenticated user.
    public func balance() async throws -> TokenBalance {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/blockchain/balance"
        )
    }

    /// Stake tokens.
    public func stake(amount: Double) async throws -> StakingInfo {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/blockchain/stake",
            body: StakeRequest(amount: amount)
        )
    }

    /// Unstake tokens.
    public func unstake(amount: Double) async throws -> StakingInfo {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/blockchain/unstake",
            body: StakeRequest(amount: amount)
        )
    }

    /// Get current staking information.
    public func stakingInfo() async throws -> StakingInfo {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/blockchain/staking-info"
        )
    }

    /// List token transactions.
    public func transactions(page: Int = 1, pageSize: Int = 20) async throws -> [TokenTransaction] {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/blockchain/transactions",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize))
            ]
        )
    }

    /// Claim accumulated staking rewards.
    public func claimRewards() async throws -> ClaimRewardsResponse {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/blockchain/claim-rewards"
        )
    }
}
