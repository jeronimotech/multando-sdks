"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BlockchainService = void 0;
class BlockchainService {
    constructor(http, logger) {
        this.http = http;
        this.logger = logger;
    }
    async getBalance() {
        const response = await this.http.get('/blockchain/balance');
        return response.data;
    }
    async stake(request) {
        this.logger.info('Staking tokens', { amount: request.amount });
        const response = await this.http.post('/blockchain/stake', request);
        return response.data;
    }
    async unstake(request) {
        this.logger.info('Unstaking tokens', { amount: request.amount });
        const response = await this.http.post('/blockchain/unstake', request);
        return response.data;
    }
    async getStakingInfo() {
        const response = await this.http.get('/blockchain/staking-info');
        return response.data;
    }
    async getTransactions() {
        const response = await this.http.get('/blockchain/transactions');
        return response.data;
    }
    async claimRewards() {
        this.logger.info('Claiming rewards');
        const response = await this.http.post('/blockchain/claim-rewards');
        return response.data;
    }
}
exports.BlockchainService = BlockchainService;
//# sourceMappingURL=blockchainService.js.map