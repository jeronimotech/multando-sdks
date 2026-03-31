"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useAuth = useAuth;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useAuth() {
    const { client } = (0, useMultando_1.useMultando)();
    const [isAuthenticated, setIsAuthenticated] = (0, react_1.useState)(client.isAuthenticated);
    const [isLoading, setIsLoading] = (0, react_1.useState)(false);
    const [user, setUser] = (0, react_1.useState)(client.currentUser);
    const [error, setError] = (0, react_1.useState)(null);
    (0, react_1.useEffect)(() => {
        const unsubscribe = client.auth.onAuthStateChange((state) => {
            setIsAuthenticated(state.isAuthenticated);
            setUser(state.user);
        });
        return unsubscribe;
    }, [client]);
    const login = (0, react_1.useCallback)(async (request) => {
        setIsLoading(true);
        setError(null);
        try {
            const profile = await client.auth.login(request);
            return profile;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const register = (0, react_1.useCallback)(async (request) => {
        setIsLoading(true);
        setError(null);
        try {
            const profile = await client.auth.register(request);
            return profile;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const logout = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            await client.auth.logout();
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const linkWallet = (0, react_1.useCallback)(async (request) => {
        setIsLoading(true);
        setError(null);
        try {
            const profile = await client.auth.linkWallet(request);
            return profile;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const refreshProfile = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const profile = await client.auth.getMe();
            return profile;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    return {
        isAuthenticated,
        isLoading,
        user,
        error,
        login,
        register,
        logout,
        linkWallet,
        refreshProfile,
    };
}
//# sourceMappingURL=useAuth.js.map