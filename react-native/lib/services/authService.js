"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
class AuthService {
    constructor(http, authManager, logger) {
        this.http = http;
        this.authManager = authManager;
        this.logger = logger;
    }
    async register(request) {
        this.logger.info('Registering new user');
        const response = await this.http.post('/auth/register', request);
        await this.authManager.setTokens(response.data);
        const profile = await this.getMe();
        return profile;
    }
    async login(request) {
        this.logger.info('Logging in user');
        const response = await this.http.post('/auth/login', request);
        await this.authManager.setTokens(response.data);
        const profile = await this.getMe();
        return profile;
    }
    async refresh() {
        const refreshToken = this.authManager.getRefreshTokenValue();
        if (!refreshToken) {
            throw new Error('No refresh token available');
        }
        const response = await this.http.post('/auth/refresh', {
            refreshToken,
        });
        await this.authManager.setTokens(response.data);
        return response.data;
    }
    async getMe() {
        const response = await this.http.get('/auth/me');
        await this.authManager.setUser(response.data);
        return response.data;
    }
    async linkWallet(request) {
        this.logger.info('Linking wallet');
        const response = await this.http.post('/auth/link-wallet', request);
        await this.authManager.setUser(response.data);
        return response.data;
    }
    async logout() {
        this.logger.info('Logging out user');
        await this.authManager.clearTokens();
    }
    get isAuthenticated() {
        return this.authManager.isAuthenticated;
    }
    get currentUser() {
        return this.authManager.currentUser;
    }
    onAuthStateChange(listener) {
        return this.authManager.onAuthStateChange(listener);
    }
}
exports.AuthService = AuthService;
//# sourceMappingURL=authService.js.map