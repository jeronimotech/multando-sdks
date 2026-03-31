import '../core/http_client.dart';
import '../models/blockchain.dart';

/// Service for blockchain token operations: balance, staking, transactions.
class BlockchainService {
  BlockchainService({required MultandoHttpClient httpClient})
      : _http = httpClient;

  final MultandoHttpClient _http;

  /// Get the current user's token balance.
  Future<TokenBalance> getBalance() async {
    try {
      final response =
          await _http.get<Map<String, dynamic>>('/blockchain/balance');
      return TokenBalance.fromJson(response.data!);
    } catch (_) {
      // Endpoint may not exist yet — return zero balance
      return const TokenBalance(
        available: 0,
        staked: 0,
        pendingRewards: 0,
        total: 0,
      );
    }
  }

  /// Stake tokens.
  Future<StakingInfo> stake(StakeRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/blockchain/stake',
      data: request.toJson(),
    );
    return StakingInfo.fromJson(response.data!);
  }

  /// Unstake tokens.
  Future<StakingInfo> unstake(UnstakeRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/blockchain/unstake',
      data: request.toJson(),
    );
    return StakingInfo.fromJson(response.data!);
  }

  /// Get current staking information.
  Future<StakingInfo> stakingInfo() async {
    try {
      final response =
          await _http.get<Map<String, dynamic>>('/blockchain/staking-info');
      return StakingInfo.fromJson(response.data!);
    } catch (_) {
      return const StakingInfo(
        stakedAmount: 0,
        pendingRewards: 0,
        apy: 5.0,
        isLocked: false,
      );
    }
  }

  /// List token transactions with pagination.
  Future<List<TokenTransaction>> transactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _http.get<dynamic>(
        '/blockchain/transactions',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data;
      if (data is List) {
        return data
            .cast<Map<String, dynamic>>()
            .map(TokenTransaction.fromJson)
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final items = data['items'] as List? ?? [];
        return items
            .cast<Map<String, dynamic>>()
            .map(TokenTransaction.fromJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Claim pending staking rewards.
  Future<ClaimRewardsResponse> claimRewards() async {
    final response = await _http.post<Map<String, dynamic>>(
      '/blockchain/claim-rewards',
    );
    return ClaimRewardsResponse.fromJson(response.data!);
  }
}
