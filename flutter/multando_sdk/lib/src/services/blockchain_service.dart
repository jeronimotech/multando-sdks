import '../core/http_client.dart';
import '../models/blockchain.dart';

/// Service for blockchain token operations: balance, staking, transactions.
class BlockchainService {
  BlockchainService({required MultandoHttpClient httpClient})
      : _http = httpClient;

  final MultandoHttpClient _http;

  /// Get the current user's token balance.
  Future<TokenBalance> getBalance() async {
    final response =
        await _http.get<Map<String, dynamic>>('/blockchain/balance');
    return TokenBalance.fromJson(response.data!);
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
    final response =
        await _http.get<Map<String, dynamic>>('/blockchain/staking-info');
    return StakingInfo.fromJson(response.data!);
  }

  /// List token transactions with pagination.
  Future<List<TokenTransaction>> transactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _http.get<List<dynamic>>(
      '/blockchain/transactions',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TokenTransaction.fromJson)
        .toList();
  }

  /// Claim pending staking rewards.
  Future<ClaimRewardsResponse> claimRewards() async {
    final response = await _http.post<Map<String, dynamic>>(
      '/blockchain/claim-rewards',
    );
    return ClaimRewardsResponse.fromJson(response.data!);
  }
}
