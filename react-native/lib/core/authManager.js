"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthManager = void 0;
const async_storage_1 = __importDefault(require("@react-native-async-storage/async-storage"));
const axios_1 = __importDefault(require("axios"));
const STORAGE_KEYS = {
    ACCESS_TOKEN: '@multando/access_token',
    REFRESH_TOKEN: '@multando/refresh_token',
    TOKEN_EXPIRY: '@multando/token_expiry',
    USER_PROFILE: '@multando/user_profile',
};
class AuthManager {
    constructor(baseUrl, apiKey, logger) {
        this.accessToken = null;
        this.refreshToken = null;
        this.tokenExpiry = null;
        this.user = null;
        this.listeners = new Set();
        this.initialized = false;
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.logger = logger;
    }
    async initialize() {
        if (this.initialized)
            return;
        try {
            const [accessToken, refreshToken, expiryStr, userStr] = await Promise.all([
                async_storage_1.default.getItem(STORAGE_KEYS.ACCESS_TOKEN),
                async_storage_1.default.getItem(STORAGE_KEYS.REFRESH_TOKEN),
                async_storage_1.default.getItem(STORAGE_KEYS.TOKEN_EXPIRY),
                async_storage_1.default.getItem(STORAGE_KEYS.USER_PROFILE),
            ]);
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
            this.tokenExpiry = expiryStr ? parseInt(expiryStr, 10) : null;
            this.user = userStr ? JSON.parse(userStr) : null;
            if (this.accessToken && this.isTokenExpired()) {
                try {
                    await this.refreshAccessToken();
                }
                catch {
                    this.logger.warn('Failed to refresh token on init, clearing tokens');
                    await this.clearTokens();
                }
            }
            this.initialized = true;
            this.notifyListeners();
        }
        catch (error) {
            this.logger.error('Failed to initialize auth manager', error);
            this.initialized = true;
            this.notifyListeners();
        }
    }
    async getAccessToken() {
        if (this.accessToken && this.isTokenExpired()) {
            try {
                await this.refreshAccessToken();
            }
            catch {
                return null;
            }
        }
        return this.accessToken;
    }
    getRefreshTokenValue() {
        return this.refreshToken;
    }
    isTokenExpired() {
        if (!this.tokenExpiry)
            return true;
        return Date.now() >= this.tokenExpiry - 60000; // 1 minute buffer
    }
    get isAuthenticated() {
        return this.accessToken !== null && !this.isTokenExpired();
    }
    get currentUser() {
        return this.user;
    }
    async setTokens(response) {
        this.accessToken = response.accessToken;
        this.refreshToken = response.refreshToken;
        this.tokenExpiry = Date.now() + response.expiresIn * 1000;
        await Promise.all([
            async_storage_1.default.setItem(STORAGE_KEYS.ACCESS_TOKEN, this.accessToken),
            async_storage_1.default.setItem(STORAGE_KEYS.REFRESH_TOKEN, this.refreshToken),
            async_storage_1.default.setItem(STORAGE_KEYS.TOKEN_EXPIRY, this.tokenExpiry.toString()),
        ]);
        this.notifyListeners();
    }
    async setUser(user) {
        this.user = user;
        await async_storage_1.default.setItem(STORAGE_KEYS.USER_PROFILE, JSON.stringify(user));
        this.notifyListeners();
    }
    async refreshAccessToken() {
        if (!this.refreshToken) {
            throw new Error('No refresh token available');
        }
        this.logger.debug('Refreshing access token');
        const client = axios_1.default.create({
            baseURL: `${this.baseUrl}/api/v1`,
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': this.apiKey,
            },
        });
        const response = await client.post('/auth/refresh', {
            refresh_token: this.refreshToken,
        });
        const tokenResponse = {
            accessToken: response.data.access_token,
            refreshToken: response.data.refresh_token,
            tokenType: response.data.token_type,
            expiresIn: response.data.expires_in,
        };
        await this.setTokens(tokenResponse);
        this.logger.info('Access token refreshed successfully');
    }
    async clearTokens() {
        this.accessToken = null;
        this.refreshToken = null;
        this.tokenExpiry = null;
        this.user = null;
        await Promise.all([
            async_storage_1.default.removeItem(STORAGE_KEYS.ACCESS_TOKEN),
            async_storage_1.default.removeItem(STORAGE_KEYS.REFRESH_TOKEN),
            async_storage_1.default.removeItem(STORAGE_KEYS.TOKEN_EXPIRY),
            async_storage_1.default.removeItem(STORAGE_KEYS.USER_PROFILE),
        ]);
        this.notifyListeners();
    }
    onAuthStateChange(listener) {
        this.listeners.add(listener);
        // Immediately emit current state
        listener(this.getState());
        return () => {
            this.listeners.delete(listener);
        };
    }
    getState() {
        return {
            isAuthenticated: this.isAuthenticated,
            isLoading: !this.initialized,
            user: this.user,
        };
    }
    notifyListeners() {
        const state = this.getState();
        this.listeners.forEach((listener) => listener(state));
    }
    /** Expose a raw axios instance for the auth service (bypasses main interceptors). */
    createRawClient() {
        return axios_1.default.create({
            baseURL: `${this.baseUrl}/api/v1`,
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': this.apiKey,
            },
        });
    }
}
exports.AuthManager = AuthManager;
//# sourceMappingURL=authManager.js.map