"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultandoProvider = MultandoProvider;
const react_1 = __importStar(require("react"));
const MultandoClient_1 = require("../core/MultandoClient");
const useMultando_1 = require("../hooks/useMultando");
const enums_1 = require("../models/enums");
function MultandoProvider({ config, children, onInitialized, onError, }) {
    const clientRef = (0, react_1.useRef)(null);
    const [isReady, setIsReady] = (0, react_1.useState)(false);
    // Create client only once (or when config identity changes)
    if (!clientRef.current) {
        clientRef.current = new MultandoClient_1.MultandoClient(config);
    }
    (0, react_1.useEffect)(() => {
        const client = clientRef.current;
        if (!client)
            return;
        let disposed = false;
        client
            .initialize()
            .then(() => {
            if (!disposed) {
                setIsReady(true);
                onInitialized?.();
            }
        })
            .catch((error) => {
            if (!disposed) {
                const err = error instanceof Error ? error : new Error(String(error));
                onError?.(err);
            }
        });
        return () => {
            disposed = true;
            client.dispose();
            clientRef.current = null;
        };
        // We intentionally only run this once on mount.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);
    const locale = config.locale ?? enums_1.Locale.En;
    const t = (0, react_1.useMemo)(() => (0, useMultando_1.getTranslation)(locale), [locale]);
    const contextValue = (0, react_1.useMemo)(() => {
        if (!clientRef.current)
            return null;
        return {
            client: clientRef.current,
            locale,
            t,
        };
    }, [locale, t, isReady]); // isReady is included to trigger re-render after init
    if (!contextValue)
        return null;
    return (react_1.default.createElement(useMultando_1.MultandoContext.Provider, { value: contextValue }, isReady ? children : null));
}
//# sourceMappingURL=MultandoProvider.js.map